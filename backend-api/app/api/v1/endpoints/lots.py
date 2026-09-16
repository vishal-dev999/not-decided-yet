from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.database import get_db
from app.deps import get_any_user, get_current_collector, get_current_recycler
from app.models.entities import Collector, Lot, MatchOffer, Recycler
from app.schemas.lots import (
    ClaimIn,
    CompleteIn,
    ConsentIn,
    LotOut,
    LotSyncIn,
    MatchOfferOut,
    QRVerifyIn,
    WeighbridgeIn,
)
from app.schemas.users import RecyclerPublicOut
from app.services import lots as lot_svc

router = APIRouter(prefix="/lots", tags=["Lots"])


def _lot_out(lot: Lot) -> dict:
    return LotOut.model_validate(lot).model_dump()


@router.post("/sync", status_code=201)
def sync_lots(
    body: LotSyncIn,
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
):
    """Step 1 — push queued offline lots. Idempotent. Auto-broadcasts top 3 recyclers."""
    synced = lot_svc.sync_lots(db, collector, body.lots)
    return {
        "ok": True,
        "count": len(synced),
        "data": [_lot_out(l) for l in synced],
        "message": "Lots synced. Matching broadcast has been triggered for new lots.",
    }


@router.get("/{lot_id}")
def get_lot(
    lot_id: str,
    pair=Depends(get_any_user),
    db: Session = Depends(get_db),
):
    lot = lot_svc.get_lot(db, lot_id)
    role, user = pair
    if role == "collector" and lot.collector_id != user.id:
        raise AppError(403, "FORBIDDEN", "You do not own this lot.")
    if role == "recycler" and lot.claimed_by not in {None, user.id}:
        offer = (
            db.query(MatchOffer)
            .filter(MatchOffer.lot_id == lot.id, MatchOffer.recycler_id == user.id)
            .first()
        )
        if not offer:
            raise AppError(403, "FORBIDDEN", "Lot is not offered to you.")
    return {"ok": True, "data": _lot_out(lot)}


@router.get("/{lot_id}/status")
def lot_status(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    lot = lot_svc.get_lot(db, lot_id)
    recycler = db.get(Recycler, lot.claimed_by) if lot.claimed_by else None
    txn = lot.transaction
    return {
        "ok": True,
        "data": {
            "lot_id": lot.id,
            "client_lot_id": lot.client_lot_id,
            "status": lot.status,
            "claimed_by": lot.claimed_by,
            "pickup_scheduled_at": lot.pickup_scheduled_at,
            "qr_token": lot.qr_token if pair[0] == "collector" else None,
            "recycler": RecyclerPublicOut.model_validate(recycler).model_dump() if recycler else None,
            "transaction": {
                "id": txn.id,
                "certified_weight_kg": txn.certified_weight_kg,
                "offered_rate_per_kg": txn.offered_rate_per_kg,
                "total_amount": txn.total_amount,
                "collector_consent": txn.collector_consent,
                "payment_mode": txn.payment_mode,
                "receipt_number": txn.receipt_number,
                "fraud_score": txn.fraud_score,
                "status": txn.status,
            }
            if txn
            else None,
        },
    }


@router.get("/{lot_id}/matches")
def lot_matches(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    lot = lot_svc.get_lot(db, lot_id)
    offers = db.query(MatchOffer).filter(MatchOffer.lot_id == lot.id).order_by(MatchOffer.rank).all()
    data = []
    for o in offers:
        rec = db.get(Recycler, o.recycler_id)
        item = MatchOfferOut.model_validate(o)
        if rec:
            item.recycler_name = rec.company_name
            item.recycler_city = rec.city
            item.authorization_no = rec.authorization_no
        data.append(item.model_dump())
    return {"ok": True, "data": data}


@router.post("/{lot_id}/broadcast")
def rebroadcast(
    lot_id: str,
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
):
    lot = lot_svc.get_lot(db, lot_id)
    if lot.collector_id != collector.id:
        raise AppError(403, "FORBIDDEN", "You do not own this lot.")
    if lot.status not in {"SYNCED"}:
        raise AppError(409, "ALREADY_BROADCAST", "Lot has already moved past sync.")
    offers = lot_svc.broadcast_lot(db, lot)
    return {"ok": True, "count": len(offers), "lot": _lot_out(lot)}


@router.post("/{lot_id}/claim")
def claim(
    lot_id: str,
    body: ClaimIn,
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    """Step 3 — first recycler to Accept locks the lot."""
    lot = lot_svc.get_lot(db, lot_id)
    lot = lot_svc.claim_lot(db, lot, recycler, body.pickup_minutes_from_now)
    return {
        "ok": True,
        "data": _lot_out(lot),
        "message": "Lot locked. Other recyclers have been withdrawn.",
    }


@router.post("/{lot_id}/qr/verify")
def qr_verify(
    lot_id: str,
    body: QRVerifyIn,
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    """Step 5 — recycler scans collector QR to open weigh session."""
    lot = lot_svc.get_lot(db, lot_id)
    lot = lot_svc.verify_qr(db, lot, recycler, body.qr_token)
    return {"ok": True, "data": _lot_out(lot), "message": "Session opened. Enter certified weight."}


@router.post("/{lot_id}/weighbridge")
def weighbridge(
    lot_id: str,
    body: WeighbridgeIn,
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    """Step 6+7 — certified weight & rate; collector receives dual-consent prompt."""
    lot = lot_svc.get_lot(db, lot_id)
    lot, txn, payload = lot_svc.submit_weighbridge(
        db, lot, recycler, body.certified_weight_kg, body.offered_rate_per_kg
    )
    return {"ok": True, "lot": _lot_out(lot), "consent_prompt": payload}


@router.post("/{lot_id}/consent")
def consent(
    lot_id: str,
    body: ConsentIn,
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
):
    """Step 8 — collector taps green check. Optionally include payment_mode to also complete."""
    lot = lot_svc.get_lot(db, lot_id)
    lot = lot_svc.collector_consent(
        db, lot, collector, body.accepted, body.payment_mode, body.upi_reference
    )
    return {"ok": True, "data": _lot_out(lot)}


@router.post("/{lot_id}/complete")
def complete(
    lot_id: str,
    body: CompleteIn,
    pair=Depends(get_any_user),
    db: Session = Depends(get_db),
):
    """Step 9+10 — seal Form-6, credit earnings. Either party may call after consent."""
    lot = lot_svc.get_lot(db, lot_id)
    role, user = pair
    if role == "collector" and lot.collector_id != user.id:
        raise AppError(403, "FORBIDDEN", "Not your lot.")
    if role == "recycler" and lot.claimed_by != user.id:
        raise AppError(403, "FORBIDDEN", "Not your claimed lot.")
    lot = lot_svc.complete_lot(db, lot, body.payment_mode, body.upi_reference)
    return {"ok": True, "data": _lot_out(lot)}


@router.post("/{lot_id}/cancel")
def cancel(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    lot = lot_svc.get_lot(db, lot_id)
    role, user = pair
    if role == "collector" and lot.collector_id != user.id:
        raise AppError(403, "FORBIDDEN", "Not your lot.")
    if role == "recycler" and lot.claimed_by != user.id:
        raise AppError(403, "FORBIDDEN", "Not your claimed lot.")
    lot = lot_svc.cancel_lot(db, lot)
    return {"ok": True, "data": _lot_out(lot)}
