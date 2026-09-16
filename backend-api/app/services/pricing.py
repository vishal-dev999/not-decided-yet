from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.ml.price_engine import estimate_total, summarize
from app.models.entities import Material, PriceHistory, PriceQuote
from app.schemas.finance import (
    PriceBoardRow,
    PriceEstimateOut,
    PriceTrendOut,
    PriceTrendPoint,
)
from app.utils.i18n import MATERIAL_NAMES, price_board_line, spoken, money_spoken, kg_spoken


def _quote(db: Session, material: str, city: str) -> Optional[PriceQuote]:
    q = (
        db.query(PriceQuote)
        .filter(PriceQuote.material_code == material, PriceQuote.city == city)
        .first()
    )
    if q:
        return q
    return (
        db.query(PriceQuote)
        .filter(PriceQuote.material_code == material, PriceQuote.city == "Cuttack")
        .first()
    )


def market_band(db: Session, material: str, city: str) -> tuple[float, float, float]:
    q = _quote(db, material, city)
    if not q:
        return 50.0, 20.0, 80.0
    return q.buy_rate_per_kg, q.min_rate, q.max_rate


def price_board(db: Session, city: str = "Cuttack") -> list[PriceBoardRow]:
    materials = db.query(Material).all()
    rows: list[PriceBoardRow] = []
    since = datetime.now(timezone.utc) - timedelta(days=40)
    for m in materials:
        q = _quote(db, m.code, city)
        if not q:
            continue
        hist = (
            db.query(PriceHistory)
            .filter(
                PriceHistory.material_code == m.code,
                PriceHistory.city == q.city,
                PriceHistory.as_of >= since,
            )
            .all()
        )
        stats = summarize([(h.as_of, h.buy_rate_per_kg) for h in hist])
        names = {"en": m.name_en, "hi": m.name_hi, "mr": m.name_mr}
        rows.append(
            PriceBoardRow(
                material_code=m.code,
                name_en=m.name_en,
                name_hi=m.name_hi,
                name_mr=m.name_mr,
                e_waste_code=m.e_waste_code,
                city=q.city,
                buy_rate_per_kg=q.buy_rate_per_kg,
                min_rate=q.min_rate,
                max_rate=q.max_rate,
                trend=stats.trend,
                change_7d_pct=stats.change_7d_pct,
                spoken=price_board_line(names, q.buy_rate_per_kg),
            )
        )
    return rows


def estimate(db: Session, material: str, weight_kg: float, city: str) -> PriceEstimateOut:
    rate, lo, hi = market_band(db, material, city)
    money = estimate_total(rate, weight_kg, lo, hi)
    hist = (
        db.query(PriceHistory)
        .filter(PriceHistory.material_code == material, PriceHistory.city == city)
        .all()
    )
    if not hist:
        hist = (
            db.query(PriceHistory)
            .filter(PriceHistory.material_code == material)
            .all()
        )
    stats = summarize([(h.as_of, h.buy_rate_per_kg) for h in hist])
    names = MATERIAL_NAMES.get(material, {"en": material, "hi": material, "mr": material})
    w = kg_spoken(weight_kg)
    tot = money_spoken(money["estimated_total"])
    return PriceEstimateOut(
        material_category=material,
        city=city,
        weight_kg=weight_kg,
        trend=stats.trend,
        spoken=spoken(
            f"About {tot['en']} for {w['en']} of {names['en']}.",
            f"{names['hi']} के {w['hi']} का अनुमान {tot['hi']} है।",
            f"{names['mr']} च्या {w['mr']} चा अंदाज {tot['mr']} आहे.",
        ),
        **money,
    )


def trends(db: Session, material: str, city: str, days: int = 30) -> PriceTrendOut:
    since = datetime.now(timezone.utc) - timedelta(days=days)
    hist = (
        db.query(PriceHistory)
        .filter(
            PriceHistory.material_code == material,
            PriceHistory.city == city,
            PriceHistory.as_of >= since,
        )
        .order_by(PriceHistory.as_of.asc())
        .all()
    )
    if not hist:
        hist = (
            db.query(PriceHistory)
            .filter(PriceHistory.material_code == material, PriceHistory.as_of >= since)
            .order_by(PriceHistory.as_of.asc())
            .all()
        )
    stats = summarize([(h.as_of, h.buy_rate_per_kg) for h in hist])
    return PriceTrendOut(
        material_code=material,
        city=city,
        points=[PriceTrendPoint(as_of=h.as_of, buy_rate_per_kg=h.buy_rate_per_kg) for h in hist],
        sma_7=stats.sma_7,
        sma_30=stats.sma_30,
        slope_per_day=stats.slope_per_day,
        forecast_7d=stats.forecast_7d,
        volatility=stats.volatility,
    )
