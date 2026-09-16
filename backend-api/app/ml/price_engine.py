"""Price estimation & trend engine (page 9 task 2).

Uses statistical functions on historical buy-rates:
  - SMA 7 / SMA 30
  - Ordinary-least-squares slope (₹ / day)
  - Residual standard deviation (volatility)
  - Naive 7-day linear forecast

No neural net is used here — the blueprint explicitly calls for statistical
functions so the price board stays explainable and cheap to run on CPU.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Iterable, Optional

import numpy as np


@dataclass
class TrendStats:
    sma_7: Optional[float]
    sma_30: Optional[float]
    slope_per_day: Optional[float]
    forecast_7d: Optional[float]
    volatility: Optional[float]
    trend: str  # up | down | flat
    change_7d_pct: float


def _as_float_series(points: Iterable[tuple[datetime, float]]) -> tuple[np.ndarray, np.ndarray]:
    ordered = sorted(points, key=lambda p: p[0])
    if not ordered:
        return np.array([]), np.array([])
    t0 = ordered[0][0]
    xs = np.array([(p[0] - t0).total_seconds() / 86400.0 for p in ordered], dtype=float)
    ys = np.array([p[1] for p in ordered], dtype=float)
    return xs, ys


def summarize(points: Iterable[tuple[datetime, float]]) -> TrendStats:
    ordered = sorted(points, key=lambda p: p[0])
    if not ordered:
        return TrendStats(None, None, None, None, None, "flat", 0.0)

    ys = np.array([p[1] for p in ordered], dtype=float)
    sma_7 = float(np.mean(ys[-7:])) if len(ys) else None
    sma_30 = float(np.mean(ys[-30:])) if len(ys) else None

    xs, yv = _as_float_series(ordered)
    slope = None
    forecast = None
    vol = None
    if len(yv) >= 3:
        slope = float(np.polyfit(xs, yv, 1)[0])
        forecast = float(yv[-1] + slope * 7.0)
        pred = np.polyval(np.polyfit(xs, yv, 1), xs)
        vol = float(np.std(yv - pred))

    change = 0.0
    if len(ys) >= 2:
        baseline = float(ys[-8]) if len(ys) >= 8 else float(ys[0])
        if baseline:
            change = float((ys[-1] - baseline) / baseline * 100.0)

    if change > 1.5:
        trend = "up"
    elif change < -1.5:
        trend = "down"
    else:
        trend = "flat"

    return TrendStats(
        sma_7=round(sma_7, 2) if sma_7 is not None else None,
        sma_30=round(sma_30, 2) if sma_30 is not None else None,
        slope_per_day=round(slope, 4) if slope is not None else None,
        forecast_7d=round(forecast, 2) if forecast is not None else None,
        volatility=round(vol, 2) if vol is not None else None,
        trend=trend,
        change_7d_pct=round(change, 2),
    )


def estimate_total(rate: float, weight_kg: float, min_rate: float, max_rate: float) -> dict:
    return {
        "rate_per_kg": round(rate, 2),
        "estimated_total": round(rate * weight_kg, 2),
        "low_total": round(min_rate * weight_kg, 2),
        "high_total": round(max_rate * weight_kg, 2),
    }


def generate_synthetic_history(
    base: float, days: int = 45, seed: int = 7
) -> list[tuple[datetime, float]]:
    """Used only to seed the prototype when field-research prices are missing."""
    rng = np.random.default_rng(seed)
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    drift = rng.normal(0, base * 0.002, size=days).cumsum()
    noise = rng.normal(0, base * 0.015, size=days)
    out = []
    for i in range(days):
        price = max(base * 0.6, base + drift[i] + noise[i])
        out.append((today - timedelta(days=days - 1 - i), round(float(price), 2)))
    return out
