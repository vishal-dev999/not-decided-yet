"""Recycler ranking — statistical model used at Step 2 (Targeted Broadcast)."""

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
    
    norm_mat = (material_code or "").strip().upper()

    for r in recyclers:
        if not getattr(r, "verified", False) or not getattr(r, "is_active", False):
            continue

        raw_accepted = getattr(r, "accepted_categories", "*") or "*"
        accepted_set = {c.strip().upper() for c in raw_accepted.split(",") if c.strip()}

        # Match wildcard '*' or exact code or wire aliases
        matches = "*" in accepted_set or norm_mat in accepted_set
        if not matches and ("WIRE" in norm_mat or "CABLE" in norm_mat):
            # Compatibility alias between wire sub-categories
            matches = any(w in accepted_set for w in ("CABLES_AND_WIRING", "COPPER_HEAVY_INSULATED", "ALUMINIUM_WIRE"))

        if not matches:
            continue

        # If coordinates are missing on the lot, fallback to recycler city defaults (dist = 5.0 km)
        if lot_lat is None or lot_lon is None or r.latitude is None or r.longitude is None:
            dist = 5.0
        else:
            dist = haversine_km(lot_lat, lot_lon, r.latitude, r.longitude)

        if dist > settings.match_max_distance_km:
            continue

        multiplier = float(getattr(r, "price_multiplier", 1.0) or 1.0)
        offered = round(market_rate * multiplier, 2)
        rows.append((r, dist, offered))

    if not rows:
        return []

    prices = [offered for _, _, offered in rows]
    ranked: list[RankedRecycler] = []

    for r, dist, offered in rows:
        d_s = _distance_score(dist)
        p_s = _price_score(offered, prices)
        a_s = 1.0 if getattr(r, "pickup_available", False) else 0.30
        k_s = _karma_score(float(getattr(r, "karma_points", 0.0)))
        
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
                latitude=r.latitude or 20.2961,
                longitude=r.longitude or 85.8245,
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
