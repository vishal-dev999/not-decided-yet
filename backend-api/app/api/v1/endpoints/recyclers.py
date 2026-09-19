from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_recycler
from app.models.entities import Lot, MatchOffer, Recycler
from app.schemas.lots import LotOut, MatchOfferOut
from app.schemas.users import RecyclerOut, RecyclerPublicOut, RecyclerUpdateIn

router = APIRouter(prefix="/recyclers", tags=["Recyclers"])


@router.get("/me", response_model=dict)
def my_profile(recycler: Recycler = Depends(get_current_recycler)):
    return {"ok": True, "data": RecyclerOut.model_validate(recycler).model_dump()}


@router.put("/me", response_model=dict)
def update_profile(
    body: RecyclerUpdateIn,
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(recycler, k, v)
    db.commit()
    db.refresh(recycler)
    return {"ok": True, "data": RecyclerOut.model_validate(recycler).model_dump()}


@router.get("/me/opportunities", response_model=dict)
def opportunities(
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
):
    """Lots currently offered to this recycler (top-3 broadcast, not yet locked)."""
    offers = (
        db.query(MatchOffer)
        .filter(MatchOffer.recycler_id == recycler.id, MatchOffer.status == "OFFERED")
        .order_by(MatchOffer.rank.asc())
        .all()
    )
    data = []
    for o in offers:
        lot = db.get(Lot, o.lot_id)
        if not lot or lot.status != "BROADCASTED":
            continue
        data.append(
            {
                "offer": MatchOfferOut.model_validate(o).model_dump(),
                "lot": LotOut.model_validate(lot).model_dump(),
            }
        )
    return {"ok": True, "data": data}


@router.get("/me/lots", response_model=dict)
def my_lots(
    recycler: Recycler = Depends(get_current_recycler),
    db: Session = Depends(get_db),
    status: str | None = None,
):
    q = db.query(Lot).filter(Lot.claimed_by == recycler.id)
    if status:
        q = q.filter(Lot.status == status)
    rows = q.order_by(Lot.updated_at.desc()).all()
    return {"ok": True, "data": [LotOut.model_validate(r).model_dump() for r in rows]}


@router.get("", response_model=dict)
def list_recyclers(
    db: Session = Depends(get_db),
    city: str | None = None,
    verified: bool = True,
    limit: int = Query(50, ge=1, le=200),
):
    q = db.query(Recycler).filter(Recycler.is_active.is_(True))
    if verified:
        q = q.filter(Recycler.verified.is_(True))
    if city:
        q = q.filter(Recycler.city == city)
    rows = q.limit(limit).all()
    return {"ok": True, "data": [RecyclerPublicOut.model_validate(r).model_dump() for r in rows]}


@router.get("/{recycler_id}", response_model=dict)
def get_recycler(recycler_id: str, db: Session = Depends(get_db)):
    r = db.get(Recycler, recycler_id)
    if not r:
        from app.core.exceptions import AppError

        raise AppError(404, "RECYCLER_NOT_FOUND", "Recycler not found.")
    return {"ok": True, "data": RecyclerPublicOut.model_validate(r).model_dump()}
