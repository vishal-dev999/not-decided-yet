import csv
import io
import json
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.database import get_db
from app.deps import get_any_user, get_current_recycler
from app.models.entities import Collector, Lot, Recycler, TraceabilitySeal, Transaction
from app.schemas.finance import Form6Out, ReceiptOut
from app.utils.i18n import money_spoken, spoken

router = APIRouter(prefix="/compliance", tags=["Compliance & Ledger"])


def _seal_for_lot(db: Session, lot_id: str) -> TraceabilitySeal:
    seal = db.query(TraceabilitySeal).filter(TraceabilitySeal.lot_id == lot_id).first()
    if not seal:
        raise AppError(404, "NOT_SEALED", "Lot is not yet VERIFIED_COMPLETED / sealed.")
    return seal


@router.get("/form6/{lot_id}")
def form6_json(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    seal = _seal_for_lot(db, lot_id)
    form = json.loads(seal.form6_json)
    return {
        "ok": True,
        "data": Form6Out(
            manifest_no=seal.manifest_no,
            lot_id=lot_id,
            sealed_at=seal.sealed_at,
            record_hash=seal.record_hash,
            form=form,
        ).model_dump(),
    }


@router.get("/form6/{lot_id}/csv")
def form6_csv(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    seal = _seal_for_lot(db, lot_id)
    form = json.loads(seal.form6_json)
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(["field", "value"])
    writer.writerow(["form", "FORM-6 E-Waste Manifest"])
    writer.writerow(["manifest_no", seal.manifest_no])
    writer.writerow(["record_hash", seal.record_hash])
    writer.writerow(["sealed_at", seal.sealed_at.isoformat()])
    writer.writerow(["sender_name", form["sender"]["name"]])
    writer.writerow(["sender_phone", form["sender"]["phone"]])
    writer.writerow(["sender_address", form["sender"]["address"]])
    writer.writerow(["receiver_name", form["receiver"]["name"]])
    writer.writerow(["receiver_auth", form["receiver"]["authorization_no"]])
    writer.writerow(["receiver_address", form["receiver"]["address"]])
    writer.writerow(["category", form["waste"]["category"]])
    writer.writerow(["quantity_kg", form["waste"]["quantity_kg"]])
    writer.writerow(["quantity_mt", form["waste"]["quantity_mt"]])
    writer.writerow(["rate_per_kg", form["financials"]["rate_per_kg"]])
    writer.writerow(["total_inr", form["financials"]["total_inr"]])
    writer.writerow(["payment_mode", form["financials"]["payment_mode"]])
    writer.writerow(["receipt_number", form["financials"]["receipt_number"]])
    writer.writerow(["lot_id", lot_id])
    buf.seek(0)
    filename = f"{seal.manifest_no}.csv"
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/receipt/{lot_id}")
def receipt(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    lot = db.get(Lot, lot_id)
    if not lot or not lot.transaction or not lot.transaction.receipt_number:
        raise AppError(404, "NO_RECEIPT", "Receipt is not available yet.")
    txn = lot.transaction
    collector = db.get(Collector, lot.collector_id)
    recycler = db.get(Recycler, lot.claimed_by)
    seal = db.query(TraceabilitySeal).filter(TraceabilitySeal.lot_id == lot_id).first()
    amount = txn.total_amount or 0
    spoken_amt = money_spoken(amount)
    data = ReceiptOut(
        receipt_number=txn.receipt_number,
        lot_id=lot.id,
        transaction_id=txn.id,
        collector={"name": collector.full_name, "phone": collector.phone, "city": collector.city},
        recycler={
            "name": recycler.company_name,
            "authorization_no": recycler.authorization_no,
            "city": recycler.city,
        },
        material_category=lot.material_category,
        certified_weight_kg=txn.certified_weight_kg or 0,
        rate_per_kg=txn.offered_rate_per_kg or 0,
        total_amount=amount,
        payment_mode=txn.payment_mode or "",
        completed_at=txn.completed_at or txn.created_at,
        record_hash=seal.record_hash if seal else None,
        spoken=spoken(
            f"Receipt {txn.receipt_number}. {spoken_amt['en']} paid.",
            f"रसीद {txn.receipt_number}। {spoken_amt['hi']} दिए गए।",
            f"पावती {txn.receipt_number}. {spoken_amt['mr']} दिले.",
        ),
    )
    return {"ok": True, "data": data.model_dump()}


@router.get("/traceability")
def traceability(
    recycler=Depends(get_current_recycler),
    db: Session = Depends(get_db),
    from_date: Optional[str] = Query(None, description="YYYY-MM-DD"),
    to_date: Optional[str] = Query(None, description="YYYY-MM-DD"),
):
    q = (
        db.query(TraceabilitySeal, Transaction, Lot)
        .join(Transaction, TraceabilitySeal.transaction_id == Transaction.id)
        .join(Lot, TraceabilitySeal.lot_id == Lot.id)
        .filter(Transaction.recycler_id == recycler.id)
    )
    rows = q.order_by(TraceabilitySeal.sealed_at.desc()).all()
    data = []
    for seal, txn, lot in rows:
        if from_date and seal.sealed_at.date().isoformat() < from_date:
            continue
        if to_date and seal.sealed_at.date().isoformat() > to_date:
            continue
        data.append(
            {
                "manifest_no": seal.manifest_no,
                "lot_id": lot.id,
                "material_category": lot.material_category,
                "quantity_kg": txn.certified_weight_kg,
                "total_inr": txn.total_amount,
                "record_hash": seal.record_hash,
                "sealed_at": seal.sealed_at.isoformat(),
                "receipt_number": txn.receipt_number,
            }
        )
    return {"ok": True, "count": len(data), "data": data}


@router.get("/traceability/export")
def traceability_export(
    recycler=Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    q = (
        db.query(TraceabilitySeal, Transaction, Lot, Collector)
        .join(Transaction, TraceabilitySeal.transaction_id == Transaction.id)
        .join(Lot, TraceabilitySeal.lot_id == Lot.id)
        .join(Collector, Lot.collector_id == Collector.id)
        .filter(Transaction.recycler_id == recycler.id)
        .order_by(TraceabilitySeal.sealed_at.asc())
    )
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(
        [
            "manifest_no",
            "sealed_at",
            "record_hash",
            "sender_name",
            "sender_phone",
            "receiver_auth",
            "category",
            "quantity_kg",
            "rate_per_kg",
            "total_inr",
            "payment_mode",
            "receipt_number",
            "lot_id",
        ]
    )
    for seal, txn, lot, collector in q.all():
        writer.writerow(
            [
                seal.manifest_no,
                seal.sealed_at.isoformat(),
                seal.record_hash,
                collector.full_name,
                collector.phone,
                recycler.authorization_no,
                lot.material_category,
                txn.certified_weight_kg,
                txn.offered_rate_per_kg,
                txn.total_amount,
                txn.payment_mode,
                txn.receipt_number,
                lot.id,
            ]
        )
    buf.seek(0)
    filename = f"cpcb_traceability_{recycler.recycler_code}_{datetime.utcnow().date()}.csv"
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
