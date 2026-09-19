from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.entities import Material
from app.schemas.finance import PriceEstimateIn
from app.services import pricing

router = APIRouter(prefix="/prices", tags=["Prices"])


@router.get("/materials")
def materials(db: Session = Depends(get_db)):
    rows = db.query(Material).all()
    return {
        "ok": True,
        "data": [
            {
                "code": m.code,
                "name_en": m.name_en,
                "name_hi": m.name_hi,
                "name_mr": m.name_mr,
                "e_waste_code": m.e_waste_code,
                "hazardous": m.hazardous,
                "icon": m.icon,
                "unit": m.unit,
            }
            for m in rows
        ],
    }


@router.get("/board")
def board(
    city: str = Query("Cuttack"),
    db: Session = Depends(get_db),
):
    """Current buying rates + spoken lines for the audio-first price board."""
    rows = pricing.price_board(db, city)
    return {
        "ok": True,
        "city": city,
        "data": [r.model_dump() for r in rows],
        "spoken_intro": {
            "en": f"Today's buying rates in {city}.",
            "hi": f"{city} के आज के ख़रीद भाव।",
            "mr": f"{city} मधील आजचे खरेदी दर.",
        },
    }


@router.get("/trends")
def trends(
    material: str = Query(..., examples=["pcb"]),
    city: str = Query("Cuttack"),
    days: int = Query(30, ge=7, le=365),
    db: Session = Depends(get_db),
):
    data = pricing.trends(db, material, city, days)
    return {"ok": True, "data": data.model_dump()}


@router.post("/estimate")
def estimate(body: PriceEstimateIn, db: Session = Depends(get_db)):
    data = pricing.estimate(db, body.material_category, body.weight_kg, body.city)
    return {"ok": True, "data": data.model_dump()}
