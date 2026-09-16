from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.services import pricing
from app.utils.i18n import pick, spoken

router = APIRouter(prefix="/audio", tags=["Audio-first"])


class PromptIn(BaseModel):
    template: str = Field(
        ...,
        description="consent | match | success | price | earnings | warning | custom",
        examples=["consent"],
    )
    lang: str = Field("hi", pattern="^(hi|mr|en)$")
    weight_kg: float | None = None
    amount: float | None = None
    recycler_name: str | None = None
    city: str | None = None
    material: str | None = None
    custom_en: str | None = None
    custom_hi: str | None = None
    custom_mr: str | None = None


@router.post("/prompt")
def prompt(body: PromptIn):
    """Return ready-to-speak text for the mobile TTS engine (Hindi / Marathi / English)."""
    from app.utils.i18n import consent_prompt, match_spoken, success_spoken, earnings_spoken

    bundle = spoken("OK", "ठीक है", "ठीक आहे")
    if body.template == "consent":
        bundle = consent_prompt(body.weight_kg or 0, body.amount or 0, body.recycler_name or "Recycler")
    elif body.template == "match":
        bundle = match_spoken(body.recycler_name or "Recycler", body.city or "")
    elif body.template == "success":
        bundle = success_spoken(body.amount or 0)
    elif body.template == "earnings":
        bundle = earnings_spoken(body.amount or 0, 0)
    elif body.template == "custom":
        bundle = spoken(body.custom_en or "", body.custom_hi or "", body.custom_mr or "")
    return {
        "ok": True,
        "lang": body.lang,
        "text": pick(bundle, body.lang),
        "all": bundle,
    }


@router.get("/price-board")
def spoken_price_board(
    city: str = Query("Cuttack"),
    lang: str = Query("hi"),
    db: Session = Depends(get_db),
):
    rows = pricing.price_board(db, city)
    lines = [pick(r.spoken, lang) for r in rows]
    intro = {
        "en": f"Today's buying rates in {city}.",
        "hi": f"{city} के आज के ख़रीद भाव।",
        "mr": f"{city} मधील आजचे खरेदी दर.",
    }
    full = pick(intro, lang) + " " + " ".join(lines)
    return {"ok": True, "lang": lang, "text": full, "lines": lines}
