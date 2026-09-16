from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_collector
from app.models.entities import Collector, LedgerEntry, Lot, Transaction
from app.schemas.finance import EarningsOut, LedgerEntryOut
from app.schemas.lots import LotOut
from app.schemas.users import CollectorOut, CollectorUpdateIn
from app.utils.i18n import earnings_spoken

router = APIRouter(prefix="/collectors", tags=["Collectors"])


@router.get("/me", response_model=dict)
def my_profile(collector: Collector = Depends(get_current_collector)):
    return {"ok": True, "data": CollectorOut.model_validate(collector).model_dump()}


@router.put("/me", response_model=dict)
def update_profile(
    body: CollectorUpdateIn,
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
):
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(collector, k, v)
    db.commit()
    db.refresh(collector)
    return {"ok": True, "data": CollectorOut.model_validate(collector).model_dump()}


@router.get("/me/earnings", response_model=dict)
def earnings(collector: Collector = Depends(get_current_collector), db: Session = Depends(get_db)):
    entries = db.query(LedgerEntry).filter(LedgerEntry.collector_id == collector.id).all()
    credits = sum(e.amount for e in entries if e.entry_type == "CREDIT")
    debits = sum(e.amount for e in entries if e.entry_type == "DEBIT")
    txn_count = (
        db.query(Transaction)
        .filter(
            Transaction.collector_id == collector.id,
            Transaction.status == "VERIFIED_COMPLETED",
        )
        .count()
    )
    data = EarningsOut(
        collector_id=collector.id,
        earnings_balance=collector.earnings_balance,
        pending_dues=collector.pending_dues,
        lifetime_credits=round(credits, 2),
        lifetime_debits=round(debits, 2),
        transaction_count=txn_count,
        spoken=earnings_spoken(collector.earnings_balance, collector.pending_dues),
    )
    return {"ok": True, "data": data.model_dump()}


@router.get("/me/ledger", response_model=dict)
def ledger(
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
    limit: int = Query(50, ge=1, le=200),
):
    rows = (
        db.query(LedgerEntry)
        .filter(LedgerEntry.collector_id == collector.id)
        .order_by(LedgerEntry.created_at.desc())
        .limit(limit)
        .all()
    )
    return {
        "ok": True,
        "data": [LedgerEntryOut.model_validate(r).model_dump() for r in rows],
        "balance": collector.earnings_balance,
        "pending_dues": collector.pending_dues,
    }


@router.get("/me/lots", response_model=dict)
def my_lots(
    collector: Collector = Depends(get_current_collector),
    db: Session = Depends(get_db),
    status: str | None = None,
):
    q = db.query(Lot).filter(Lot.collector_id == collector.id)
    if status:
        q = q.filter(Lot.status == status)
    rows = q.order_by(Lot.synced_at.desc()).all()
    return {"ok": True, "data": [LotOut.model_validate(r).model_dump() for r in rows]}
