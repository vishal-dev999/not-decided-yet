from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.database import get_db
from app.deps import get_any_user, get_current_recycler
from app.ml.fraud import assess
from app.models.entities import FraudAlert, Lot
from app.services import pricing

router = APIRouter(tags=["Fraud"])


@router.get("/lots/{lot_id}/fraud-check")
def fraud_check(lot_id: str, pair=Depends(get_any_user), db: Session = Depends(get_db)):
    lot = db.get(Lot, lot_id)
    if not lot:
        raise AppError(404, "LOT_NOT_FOUND", "Lot not found.")
    txn = lot.transaction
    if not txn or txn.certified_weight_kg is None:
        return {"ok": True, "data": {"score": 0, "flags": [], "note": "No weighbridge data yet."}}
    market, lo, hi = pricing.market_band(db, lot.material_category, lot.city or "Cuttack")
    result = assess(
        lot.estimated_weight_kg,
        txn.certified_weight_kg,
        txn.offered_rate_per_kg or 0,
        market,
        lo,
        hi,
    )
    return {
        "ok": True,
        "data": {
            "score": result.score,
            "severity": result.severity,
            "flags": result.flags,
            "warnings": result.warnings,
        },
    }


@router.get("/admin/fraud-alerts")
def alerts(
    recycler=Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    """Recycler-web can list alerts on lots they touched. Prototype: last 100."""
    rows = db.query(FraudAlert).order_by(FraudAlert.created_at.desc()).limit(100).all()
    return {
        "ok": True,
        "data": [
            {
                "id": r.id,
                "lot_id": r.lot_id,
                "severity": r.severity,
                "flag": r.flag,
                "message": r.message,
                "score": r.score,
                "created_at": r.created_at.isoformat(),
            }
            for r in rows
        ],
    }
