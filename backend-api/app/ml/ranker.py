"""Recycler ranking — statistical model used at Step 2 (Targeted Broadcast).

The problem statement (page 8/9) specifies ranking recyclers on:
  1. Distance
  2. Offered price
  3. Pickup availability
  4. Karma points

This prototype uses an interpretable weighted linear score, not a black-box
classifier, so the frontend and CPCB audit trail can explain *why* a recycler
was in the top 3.

Weights are configurable via environment variables.

Future (see README): learn weights from historical accept/complete outcomes
with logistic regression / LambdaMART once enough labelled matches exist.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

from app.config import settings
from app.utils.geo import haversine_km


@dataclass
class RankedRecycler:
    recycler_id: str
    company_name: str
    authorization_no: str
    city: str
    latitude: float
    longitude: float
    distance_km: float
    offered_price_per_kg: float
    pickup_available: bool
    karma_points: float
    score: float
    components: dict[str, float]


def _distance_score(km: float) -> float:
    # Smooth decay: 0 km → 1.0, 20 km → 0.5, 80 km → 0.2
    return 1.0 / (1.0 + max(km, 0.0) / 20.0)


def _price_score(price: float, pool: Sequence[float]) -> float:
    hi = max(pool) if pool else price
    lo = min(pool) if pool else price
    if hi <= lo:
        return 1.0
    return (price - lo) / (hi - lo)


def _karma_score(karma: float) -> float:
    return max(0.0, min(karma / 100.0, 1.0))


def rank_recyclers(
    lot_lat: float | None,
    lot_lon: float | None,
    market_rate: float,
    recyclers: Iterable[object],
    material_code: str,
    top_n: int | None = None,
) -> list[RankedRecycler]:
    """Score verified recyclers and return the top N (default 3)."""
    top_n = top_n or settings.match_top_n
    rows = []
    for r in recyclers:
        if not getattr(r, "verified", False) or not getattr(r, "is_active", False):
            continue
        accepted = (getattr(r, "accepted_categories", "*") or "*").strip()
        if accepted != "*" and material_code not in {c.strip() for c in accepted.split(",")}:
            continue
        dist = haversine_km(lot_lat, lot_lon, r.latitude, r.longitude)
        if dist > settings.match_max_distance_km:
            continue
        offered = round(market_rate * float(r.price_multiplier), 2)
        rows.append((r, dist, offered))

    if not rows:
        return []

    prices = [offered for _, _, offered in rows]
    ranked: list[RankedRecycler] = []
    for r, dist, offered in rows:
        d_s = _distance_score(dist)
        p_s = _price_score(offered, prices)
        a_s = 1.0 if r.pickup_available else 0.30
        k_s = _karma_score(float(r.karma_points))
        score = (
            settings.match_w_distance * d_s
            + settings.match_w_price * p_s
            + settings.match_w_availability * a_s
            + settings.match_w_karma * k_s
        )
        ranked.append(
            RankedRecycler(
                recycler_id=r.id,
                company_name=r.company_name,
                authorization_no=r.authorization_no,
                city=r.city,
                latitude=r.latitude,
                longitude=r.longitude,
                distance_km=round(dist, 2),
                offered_price_per_kg=offered,
                pickup_available=bool(r.pickup_available),
                karma_points=float(r.karma_points),
                score=round(float(score), 4),
                components={
                    "distance": round(d_s, 4),
                    "price": round(p_s, 4),
                    "availability": round(a_s, 4),
                    "karma": round(k_s, 4),
                },
            )
        )

    ranked.sort(key=lambda x: (-x.score, x.distance_km))
    return ranked[:top_n]
