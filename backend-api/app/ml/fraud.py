"""Rule + z-score fraud / anomaly detector (page 7, secondary owner: backend).

Signals evaluated at weighbridge time:
  - Weight vs collector estimate (ratio)
  - Offered rate vs city market (z-ish deviation)
  - Implausible zero/huge totals
  - Repeat rapid claims by the same recycler (passed in as context)

Returns a 0–100 score plus machine-readable flags. High score does NOT block
the trade in the prototype (informal sector must not be frozen) — it annotates
the ledger and can surface a spoken warning to the collector.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class FraudResult:
    score: float
    flags: list[str] = field(default_factory=list)
    warnings: dict[str, str] = field(default_factory=dict)
    severity: str = "NONE"


def assess(
    estimated_weight: float,
    certified_weight: float,
    offered_rate: float,
    market_rate: float,
    market_min: float,
    market_max: float,
    recycler_claims_last_hour: int = 0,
) -> FraudResult:
    flags: list[str] = []
    score = 0.0

    if estimated_weight > 0:
        ratio = certified_weight / estimated_weight
        if ratio >= 2.5:
            flags.append("WEIGHT_INFLATED")
            score += 35
        elif ratio <= 0.35:
            flags.append("WEIGHT_DEFLATED")
            score += 25
        elif ratio >= 1.6 or ratio <= 0.55:
            flags.append("WEIGHT_DEVIATION")
            score += 12

    if market_rate > 0:
        rel = offered_rate / market_rate
        if rel <= 0.50:
            flags.append("RATE_FAR_BELOW_MARKET")
            score += 30
        elif rel >= 2.0:
            flags.append("RATE_FAR_ABOVE_MARKET")
            score += 20
        elif offered_rate < market_min * 0.8 or offered_rate > market_max * 1.25:
            flags.append("RATE_OUT_OF_BAND")
            score += 10

    if certified_weight <= 0 or offered_rate <= 0:
        flags.append("NON_POSITIVE_VALUES")
        score += 40

    if recycler_claims_last_hour >= 8:
        flags.append("RAPID_CLAIM_BURST")
        score += 15

    score = min(score, 100.0)
    if score >= 60:
        severity = "HIGH"
        spoken = {
            "en": "Warning. This weigh-in looks unusual. Please check the weight and rate before agreeing.",
            "hi": "चेतावनी। यह तौल असामान्य लग रहा है। सहमति से पहले तौल और भाव जाँचें।",
            "mr": "इशारा. हे वजन असामान्य वाटते. सहमती देण्यापूर्वी वजन आणि भाव तपासा.",
        }
    elif score >= 25:
        severity = "MEDIUM"
        spoken = {
            "en": "Please double-check the weight and rate.",
            "hi": "कृपया तौल और भाव दोबारा जाँचें।",
            "mr": "कृपया वजन आणि भाव पुन्हा तपासा.",
        }
    else:
        severity = "NONE"
        spoken = {}

    return FraudResult(score=round(score, 1), flags=flags, warnings=spoken, severity=severity)
