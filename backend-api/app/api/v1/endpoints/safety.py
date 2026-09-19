from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.entities import SafetyCard

router = APIRouter(prefix="/safety", tags=["Safety cards"])


@router.get("/cards")
def cards(lang: str = Query("hi"), db: Session = Depends(get_db)):
    lang = lang if lang in {"hi", "mr", "en"} else "hi"
    rows = db.query(SafetyCard).order_by(SafetyCard.sort_order.asc()).all()
    data = []
    for c in rows:
        data.append(
            {
                "code": c.code,
                "pictogram": c.pictogram,
                "title": getattr(c, f"title_{lang}"),
                "body": getattr(c, f"body_{lang}"),
                "spoken": getattr(c, f"body_{lang}"),
                "title_all": {"en": c.title_en, "hi": c.title_hi, "mr": c.title_mr},
                "body_all": {"en": c.body_en, "hi": c.body_hi, "mr": c.body_mr},
            }
        )
    return {"ok": True, "lang": lang, "data": data}
