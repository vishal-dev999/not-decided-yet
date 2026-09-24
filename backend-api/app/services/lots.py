from __future__ import annotations

import base64
import json
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.core.exceptions import AppError
from app.core.security import hmac_token, sha256_hex
from app.core.ws_manager import manager
from app.ml.fraud import assess as assess_fraud
from app.ml.ranker import rank_recyclers
from app.models.entities import (
    Collector,
    FraudAlert,
    LedgerEntry,
    Lot,
    MatchOffer,
    Recycler,
    TraceabilitySeal,
    Transaction,
)
from app.services import pricing
from app.utils.i18n import (
    consent_prompt,
    match_spoken,
    money_spoken,
    spoken,
    success_spoken,
)
from app.utils.seed import next_pickup


VALID_TRANSITIONS = {
    "SYNCED": {"BROADCASTED", "CANCELLED"},
    "BROADCASTED": {"LOCKED", "CANCELLED", "EXPIRED"},
    "LOCKED": {"SESSION_OPEN", "CANCELLED"},
    "SESSION_OPEN": {"WEIGHED", "CANCELLED"},
    "WEIGHED": {"CONSENTED", "CANCELLED"},
    "CONSENTED": {"VERIFIED_COMPLETED", "CANCELLED"},
    "VERIFIED_COMPLETED": set(),
    "CANCELLED": set(),
    "EXPIRED": set(),
}


def _require_status(lot: Lot, allowed: set[str]) -> None:
    if lot.status not in allowed:
        raise AppError(
            409,
            "INVALID_LOT_STATE",
            f"Lot is in status {lot.status}; expected one of {sorted(allowed)}.",
            details={"status": lot.status, "allowed": sorted(allowed)},
            spoken=spoken(
                "This step is not available for the lot right now.",
                "इस लॉट के लिए यह चरण अभी उपलब्ध नहीं है।",
                "या लॉटसाठी ही पायरी सध्या उपलब्ध नाही.",
            ),
        )


def _save_photo(lot_id: str, b64: str) -> str:
    raw = base64.b64decode(b64)
    folder = Path(settings.upload_dir) / lot_id
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "lot.jpg"
    path.write_bytes(raw)
    return str(path)


def _receipt_no() -> str:
    return "KBL-" + datetime.now(timezone.utc).strftime("%Y%m%d") + "-" + uuid.uuid4().hex[:8].upper()


def _manifest_no() -> str:
    return "F6-" + datetime.now(timezone.utc).strftime("%Y%m%d") + "-" + uuid.uuid4().hex[:6].upper()


def get_lot(db: Session, lot_id: str) -> Lot:
    lot = db.get(Lot, lot_id)
    if not lot:
        raise AppError(404, "LOT_NOT_FOUND", "Lot not found.", details={"lot_id": lot_id})
    return lot


def sync_lots(db: Session, collector: Collector, items: list) -> list[Lot]:
    """Step 1 — Sync Ingestion. Idempotent on (collector_id, client_lot_id)."""
    out: list[Lot] = []
    for item in items:
        existing = (
            db.query(Lot)
            .filter(Lot.collector_id == collector.id, Lot.client_lot_id == item.client_lot_id)
            .first()
        )
        if existing:
            out.append(existing)
            continue

        lot_id = str(uuid.uuid4())
        token = item.qr_token or hmac_token(collector.id, item.client_lot_id, lot_id)
        photo_path = None
        if item.photo_base64:
            try:
                photo_path = _save_photo(lot_id, item.photo_base64)
            except Exception:
                photo_path = None

        clf = item.classification
        lot = Lot(
            id=lot_id,
            collector_id=collector.id,
            client_lot_id=item.client_lot_id,
            material_category=item.material_category,
            estimated_weight_kg=item.estimated_weight_kg,
            classification_label=clf.label if clf else item.material_category,
            classification_confidence=clf.confidence if clf else None,
            model_version=clf.model_version if clf else None,
            photo_path=photo_path,
            latitude=item.latitude if item.latitude is not None else collector.latitude,
            longitude=item.longitude if item.longitude is not None else collector.longitude,
            city=item.city or collector.city,
            notes=item.notes,
            qr_token=token,
            status="SYNCED",
            created_at_local=item.created_at_local,
        )
        db.add(lot)
        db.flush()
        out.append(lot)
        
    db.commit()
    
    # 🚀 Automatically trigger broadcast for each newly synced lot in a separate try/except block
    for lot in out:
        db.refresh(lot)
        if lot.status == "SYNCED":
            try:
                broadcast_lot(db, lot)
            except Exception as e:
                # Log the error so it's not silent, but don't crash the sync response
                print(f"[Broadcast Error] Failed to broadcast lot {lot.id}: {e}")
                
    return out


def broadcast_lot(db: Session, lot: Lot) -> list[MatchOffer]:
    """Step 2 — Targeted Broadcast to top 3 recyclers via ranking + WebSocket."""
    _require_status(lot, {"SYNCED", "BROADCASTED"})
    if lot.status == "BROADCASTED" and lot.offers:
        return list(lot.offers)

    market, _, _ = pricing.market_band(db, lot.material_category, lot.city or "Cuttack")
    recyclers = db.query(Recycler).filter(Recycler.verified.is_(True), Recycler.is_active.is_(True)).all()
    ranked = rank_recyclers(
        lot.latitude, lot.longitude, market, recyclers, lot.material_category
    )
    if not ranked:
        raise AppError(
            409,
            "NO_RECYCLERS",
            "No verified recyclers available for this material/location.",
        )

    db.query(MatchOffer).filter(MatchOffer.lot_id == lot.id).delete()
    offers: list[MatchOffer] = []
    for i, r in enumerate(ranked, start=1):
        offer = MatchOffer(
            lot_id=lot.id,
            recycler_id=r.recycler_id,
            rank=i,
            score=r.score,
            distance_km=r.distance_km,
            offered_price_per_kg=r.offered_price_per_kg,
            availability=r.pickup_available,
            karma_points=r.karma_points,
            status="OFFERED",
        )
        db.add(offer)
        offers.append(offer)

    lot.status = "BROADCASTED"
    db.commit()
    for o in offers:
        db.refresh(o)

    payload = {
        "lot_id": lot.id,
        "client_lot_id": lot.client_lot_id,
        "material_category": lot.material_category,
        "estimated_weight_kg": lot.estimated_weight_kg,
        "city": lot.city,
        "latitude": lot.latitude,
        "longitude": lot.longitude,
        "classification_label": lot.classification_label,
        "classification_confidence": lot.classification_confidence,
    }
    for o in offers:
        rec = db.get(Recycler, o.recycler_id)
        data = {
            **payload,
            "offer_id": o.id,
            "rank": o.rank,
            "score": o.score,
            "distance_km": o.distance_km,
            "indicative_rate_per_kg": o.offered_price_per_kg,
            "indicative_total": round(o.offered_price_per_kg * lot.estimated_weight_kg, 2),
            "spoken": spoken(
                f"New lot: {lot.estimated_weight_kg} kg {lot.material_category} near {lot.city}.",
                f"नया लॉट: {lot.city} के पास {lot.estimated_weight_kg} किलो {lot.material_category}.",
                f"नवा लॉट: {lot.city} जवळ {lot.estimated_weight_kg} किलो {lot.material_category}.",
            ),
        }
        # fire-and-forget style: caller is sync, so we schedule via helper
        _sync_broadcast(f"recycler:{o.recycler_id}", "lot.opportunity", data)

    _sync_broadcast(
        f"collector:{lot.collector_id}",
        "lot.broadcasted",
        {
            "lot_id": lot.id,
            "top_n": len(offers),
            "spoken": spoken(
                "Your lot was sent to nearby recyclers.",
                "आपका लॉट पास के रीसाइक्लरों को भेज दिया गया है।",
                "तुमचा लॉट जवळच्या रीसायक्लरांना पाठवला आहे.",
            ),
        },
    )
    return offers


def _sync_broadcast(room: str, event: str, data: dict) -> None:
    """Bridge sync SQLAlchemy code to the async WebSocket manager."""
    manager.broadcast_threadsafe(room, event, data)


def claim_lot(db: Session, lot: Lot, recycler: Recycler, pickup_minutes: int = 60) -> Lot:
    """Step 3 — Claim & Lock (first accept wins). Step 4 — notify collector."""
    # Lock the row (SQLite: BEGIN IMMEDIATE via session)
    db.execute(select(Lot).where(Lot.id == lot.id).with_for_update())
    db.refresh(lot)
    _require_status(lot, {"BROADCASTED"})

    offer = (
        db.query(MatchOffer)
        .filter(
            MatchOffer.lot_id == lot.id,
            MatchOffer.recycler_id == recycler.id,
            MatchOffer.status == "OFFERED",
        )
        .first()
    )
    if not offer:
        raise AppError(
            403,
            "NOT_IN_TOP_MATCHES",
            "This recycler was not in the top-3 broadcast for the lot.",
        )

    lot.status = "LOCKED"
    lot.claimed_by = recycler.id
    lot.pickup_scheduled_at = next_pickup(pickup_minutes)
    offer.status = "CLAIMED"

    others = (
        db.query(MatchOffer)
        .filter(MatchOffer.lot_id == lot.id, MatchOffer.recycler_id != recycler.id)
        .all()
    )
    for o in others:
        o.status = "WITHDRAWN"

    db.commit()
    db.refresh(lot)

    recycler_card = {
        "id": recycler.id,
        "company_name": recycler.company_name,
        "authorization_no": recycler.authorization_no,
        "phone": recycler.phone,
        "city": recycler.city,
        "address": recycler.address,
        "pickup_scheduled_at": lot.pickup_scheduled_at.isoformat() if lot.pickup_scheduled_at else None,
    }
    spoken_msg = match_spoken(recycler.company_name, recycler.city)

    _sync_broadcast(
        f"collector:{lot.collector_id}",
        "match.confirmed",
        {"lot_id": lot.id, "recycler": recycler_card, "spoken": spoken_msg},
    )
    for o in others:
        _sync_broadcast(
            f"recycler:{o.recycler_id}",
            "lot.withdrawn",
            {
                "lot_id": lot.id,
                "reason": "claimed_by_another",
                "spoken": spoken(
                    "This lot was claimed by another recycler.",
                    "यह लॉट किसी और रीसाइक्लर ने ले लिया।",
                    "हा लॉट दुसऱ्या रीसायक्लरने घेतला.",
                ),
            },
        )
    _sync_broadcast(
        f"recycler:{recycler.id}",
        "lot.locked",
        {"lot_id": lot.id, "pickup_scheduled_at": recycler_card["pickup_scheduled_at"]},
    )
    return lot


def verify_qr(db: Session, lot: Lot, recycler: Recycler, qr_token: str) -> Lot:
    """Step 5 — Physical QR handshake opens the weigh session."""
    _require_status(lot, {"LOCKED"})
    if lot.claimed_by != recycler.id:
        raise AppError(403, "NOT_CLAIMANT", "Only the recycler who claimed this lot may scan it.")
    if qr_token.strip() != lot.qr_token:
        raise AppError(
            400,
            "QR_MISMATCH",
            "QR token does not match this lot.",
            spoken=spoken(
                "This QR does not belong to the claimed lot.",
                "यह QR इस लॉट का नहीं है।",
                "हा QR या लॉटचा नाही.",
            ),
        )
    lot.status = "SESSION_OPEN"
    txn = lot.transaction
    if not txn:
        txn = Transaction(
            lot_id=lot.id,
            collector_id=lot.collector_id,
            recycler_id=recycler.id,
            status="SESSION_OPEN",
        )
        db.add(txn)
    db.commit()
    db.refresh(lot)
    _sync_broadcast(
        f"collector:{lot.collector_id}",
        "session.opened",
        {
            "lot_id": lot.id,
            "spoken": spoken(
                "Recycler scanned your QR. Weighing will start.",
                "रीसाइक्लर ने आपका QR स्कैन किया। तौल शुरू होगी।",
                "रीसायक्लरने तुमचा QR स्कॅन केला. वजन सुरू होईल.",
            ),
        },
    )
    return lot


def submit_weighbridge(
    db: Session, lot: Lot, recycler: Recycler, weight: float, rate: float
) -> tuple[Lot, Transaction, dict]:
    """Step 6 + 7 — certified weight/rate, compute total, dual-consent prompt."""
    _require_status(lot, {"SESSION_OPEN", "WEIGHED"})
    if lot.claimed_by != recycler.id:
        raise AppError(403, "NOT_CLAIMANT", "Only the claiming recycler may submit weight.")

    market, lo, hi = pricing.market_band(db, lot.material_category, lot.city or "Cuttack")
    since = datetime.now(timezone.utc) - timedelta(hours=1)
    recent_claims = (
        db.query(Lot)
        .filter(Lot.claimed_by == recycler.id, Lot.updated_at >= since)
        .count()
    )
    fraud = assess_fraud(
        estimated_weight=lot.estimated_weight_kg,
        certified_weight=weight,
        offered_rate=rate,
        market_rate=market,
        market_min=lo,
        market_max=hi,
        recycler_claims_last_hour=recent_claims,
    )

    txn = lot.transaction
    if not txn:
        txn = Transaction(
            lot_id=lot.id,
            collector_id=lot.collector_id,
            recycler_id=recycler.id,
        )
        db.add(txn)
        db.flush()

    txn.certified_weight_kg = weight
    txn.offered_rate_per_kg = rate
    txn.total_amount = round(weight * rate, 2)
    txn.recycler_consent = True
    txn.collector_consent = None
    txn.fraud_score = fraud.score
    txn.fraud_flags = json.dumps(fraud.flags)
    txn.status = "CONSENT_PENDING"
    lot.status = "WEIGHED"

    if fraud.flags:
        db.add(
            FraudAlert(
                lot_id=lot.id,
                actor_id=recycler.id,
                severity=fraud.severity,
                flag=",".join(fraud.flags),
                message="Weighbridge anomaly",
                score=fraud.score,
            )
        )

    db.commit()
    db.refresh(lot)
    db.refresh(txn)

    prompt = consent_prompt(weight, txn.total_amount, recycler.company_name)
    payload = {
        "lot_id": lot.id,
        "transaction_id": txn.id,
        "certified_weight_kg": weight,
        "offered_rate_per_kg": rate,
        "total_amount": txn.total_amount,
        "fraud_score": fraud.score,
        "fraud_flags": fraud.flags,
        "fraud_severity": fraud.severity,
        "spoken": prompt,
        "fraud_spoken": fraud.warnings,
        "prompt_en": prompt["en"],
    }
    _sync_broadcast(f"collector:{lot.collector_id}", "consent.requested", payload)
    return lot, txn, payload


def collector_consent(
    db: Session,
    lot: Lot,
    collector: Collector,
    accepted: bool,
    payment_mode: Optional[str] = None,
    upi_reference: Optional[str] = None,
) -> Lot:
    """Step 8 — collector taps green check (or rejects)."""
    _require_status(lot, {"WEIGHED"})
    if lot.collector_id != collector.id:
        raise AppError(403, "NOT_OWNER", "Only the lot owner may consent.")
    txn = lot.transaction
    if not txn or txn.total_amount is None:
        raise AppError(409, "NO_WEIGHBRIDGE", "Weighbridge entry is missing.")

    txn.collector_consent = accepted
    txn.consented_at = datetime.now(timezone.utc)
    if not accepted:
        txn.status = "REJECTED"
        lot.status = "CANCELLED"
        db.commit()
        _sync_broadcast(
            f"recycler:{lot.claimed_by}",
            "consent.rejected",
            {
                "lot_id": lot.id,
                "spoken": spoken(
                    "Collector declined the weigh-in amount.",
                    "कलेक्टर ने तौल की राशि अस्वीकार की।",
                    "कलेक्टरने वजन रक्कम नाकारली.",
                ),
            },
        )
        return lot

    txn.status = "CONSENTED"
    lot.status = "CONSENTED"
    if payment_mode:
        txn.payment_mode = payment_mode
        txn.upi_reference = upi_reference
    db.commit()
    _sync_broadcast(
        f"recycler:{lot.claimed_by}",
        "consent.accepted",
        {"lot_id": lot.id, "total_amount": txn.total_amount},
    )
    if payment_mode:
        return complete_lot(db, lot, payment_mode, upi_reference)
    return lot


def complete_lot(
    db: Session,
    lot: Lot,
    payment_mode: str,
    upi_reference: Optional[str] = None,
) -> Lot:
    """Step 9 audit seal + Step 10 earnings credit."""
    _require_status(lot, {"CONSENTED", "WEIGHED"})
    txn = lot.transaction
    if not txn or txn.collector_consent is not True:
        raise AppError(409, "CONSENT_REQUIRED", "Collector consent is required before completion.")

    collector = db.get(Collector, lot.collector_id)
    recycler = db.get(Recycler, lot.claimed_by)
    assert collector and recycler and txn.total_amount is not None

    txn.payment_mode = payment_mode
    txn.upi_reference = upi_reference
    txn.receipt_number = txn.receipt_number or _receipt_no()
    txn.status = "VERIFIED_COMPLETED"
    txn.completed_at = datetime.now(timezone.utc)
    lot.status = "VERIFIED_COMPLETED"

    collector.earnings_balance = round(collector.earnings_balance + txn.total_amount, 2)
    db.add(
        LedgerEntry(
            collector_id=collector.id,
            transaction_id=txn.id,
            entry_type="CREDIT",
            amount=txn.total_amount,
            balance_after=collector.earnings_balance,
            description=f"Lot {lot.id[:8]} {lot.material_category} {txn.certified_weight_kg}kg",
        )
    )

    recycler.karma_points = min(100.0, recycler.karma_points + 1.5)

    form = build_form6(lot, collector, recycler, txn)
    raw = json.dumps(form, default=str, sort_keys=True)
    seal = TraceabilitySeal(
        lot_id=lot.id,
        transaction_id=txn.id,
        manifest_no=form["manifest_no"],
        record_hash=sha256_hex(raw),
        form6_json=raw,
    )
    db.add(seal)
    db.commit()
    db.refresh(lot)

    spoken_ok = success_spoken(txn.total_amount)
    payload = {
        "lot_id": lot.id,
        "receipt_number": txn.receipt_number,
        "total_amount": txn.total_amount,
        "earnings_balance": collector.earnings_balance,
        "manifest_no": seal.manifest_no,
        "record_hash": seal.record_hash,
        "spoken": spoken_ok,
    }
    _sync_broadcast(f"collector:{collector.id}", "lot.completed", payload)
    _sync_broadcast(f"recycler:{recycler.id}", "lot.completed", payload)
    return lot


def build_form6(lot: Lot, collector: Collector, recycler: Recycler, txn: Transaction) -> dict:
    """CPCB E-Waste Manifest (Form-6) snapshot."""
    return {
        "form": "FORM-6",
        "title": "E-Waste Manifest",
        "manifest_no": _manifest_no(),
        "date": datetime.now(timezone.utc).date().isoformat(),
        "sender": {
            "name": collector.full_name,
            "phone": collector.phone,
            "address": f"{collector.city}, {collector.state} {collector.pincode or ''}".strip(),
            "authorization_no": "INFORMAL-COLLECTOR",
            "role": "kabadiwala / collection agent",
        },
        "receiver": {
            "name": recycler.company_name,
            "phone": recycler.phone,
            "address": f"{recycler.address}, {recycler.city}, {recycler.state}",
            "authorization_no": recycler.authorization_no,
            "recycler_code": recycler.recycler_code,
        },
        "transporter": {
            "name": recycler.company_name if recycler.pickup_available else collector.full_name,
            "mode": "road pickup",
        },
        "waste": {
            "category": lot.material_category,
            "e_waste_code": lot.material_category.upper(),
            "quantity_kg": txn.certified_weight_kg,
            "quantity_mt": round((txn.certified_weight_kg or 0) / 1000.0, 6),
            "description": lot.classification_label or lot.material_category,
        },
        "financials": {
            "rate_per_kg": txn.offered_rate_per_kg,
            "total_inr": txn.total_amount,
            "payment_mode": txn.payment_mode,
            "receipt_number": txn.receipt_number,
        },
        "lot_id": lot.id,
        "transaction_id": txn.id,
        "status": "VERIFIED_COMPLETED",
    }


def cancel_lot(db: Session, lot: Lot, reason: str = "cancelled") -> Lot:
    if lot.status == "VERIFIED_COMPLETED":
        raise AppError(409, "ALREADY_COMPLETED", "Completed lots cannot be cancelled.")
    lot.status = "CANCELLED"
    for o in lot.offers:
        if o.status == "OFFERED":
            o.status = "EXPIRED"
    db.commit()
    _sync_broadcast(f"collector:{lot.collector_id}", "lot.cancelled", {"lot_id": lot.id, "reason": reason})
    if lot.claimed_by:
        _sync_broadcast(f"recycler:{lot.claimed_by}", "lot.cancelled", {"lot_id": lot.id, "reason": reason})
    return lot
