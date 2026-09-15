"""
Deterministic recycler logistics matcher.

Contract (locked):
  * Dataset `data/recyclers.csv` with EXACT columns:
        recycler_id, company_name, state, latitude, longitude,
        service_radius_km, materials_accepted, authorization_status,
        fulfillment_score, permitted_capacity_mta
  * Distance: Haversine on WGS84, Earth radius = 6371.0 km.
  * Hard filters:
        authorization_status.strip().upper() == "ACTIVE"
        materials_accepted contains the material category (case-insensitive)
  * Radius:  distance_km <= max(service_radius_km, 150.0)
    If the filtered list is empty -> fallback: closest 5 ACTIVE recyclers
    that accept the category (radius relaxed).
  * Score:
        match_score = (0.60 * exp(-distance_km / 75.0))
                    + (0.30 * fulfillment_score)
                    + (0.10 * min(permitted_capacity_mta / 5000.0, 1.0))
  * Sort: match_score DESC, then distance_km ASC, then recycler_id ASC.
"""

from __future__ import annotations

import csv
import logging
import math
import re
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

from backend.config import (
    CAPACITY_NORM_MTA,
    DISTANCE_DECAY_KM,
    EARTH_RADIUS_KM,
    FALLBACK_RECYCLER_COUNT,
    MIN_SERVICE_RADIUS_KM,
    W_CAPACITY,
    W_DISTANCE,
    W_FULFILLMENT,
    Settings,
    get_settings,
)

logger = logging.getLogger("backend.matcher")

CSV_COLUMNS = [
    "recycler_id", "company_name", "state", "latitude", "longitude",
    "service_radius_km", "materials_accepted", "authorization_status",
    "fulfillment_score", "permitted_capacity_mta",
]

_SPLIT_RE = re.compile(r"[|,;/]+")


@dataclass
class Recycler:
    recycler_id: str
    company_name: str
    state: str
    latitude: float
    longitude: float
    service_radius_km: float
    materials_accepted: str
    authorization_status: str
    fulfillment_score: float
    permitted_capacity_mta: float

    def accepts(self, category: str) -> bool:
        """Case-insensitive acceptance check (token match, substring fallback)."""
        field_upper = self.materials_accepted.upper()
        cat_upper = category.strip().upper()
        tokens = {t.strip().upper() for t in _SPLIT_RE.split(field_upper) if t.strip()}
        return cat_upper in tokens or cat_upper in field_upper

    @property
    def is_active(self) -> bool:
        return self.authorization_status.strip().upper() == "ACTIVE"


@dataclass
class MatcherStatus:
    loaded: bool = False
    recycler_count: int = 0
    skipped_rows: int = 0
    source_path: str = ""
    detail: str = ""


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance in km on a WGS84-mean sphere (R = 6371.0)."""
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlmb / 2.0) ** 2
    return 2.0 * EARTH_RADIUS_KM * math.asin(min(1.0, math.sqrt(a)))


class RecyclerMatcher:
    """Loads recyclers.csv once; executes the deterministic ranking math."""

    def __init__(self, settings: Optional[Settings] = None) -> None:
        self.settings = settings or get_settings()
        self._lock = threading.Lock()
        self._recyclers: list[Recycler] = []
        self.status: MatcherStatus = MatcherStatus()

    # ------------------------------------------------------------------ #
    # Loading                                                             #
    # ------------------------------------------------------------------ #
    def load(self) -> MatcherStatus:
        path: Path = self.settings.recyclers_csv_path
        st = MatcherStatus(source_path=str(path))
        try:
            if not path.exists():
                st.detail = f"recyclers.csv not found at {path} — matcher returns empty results"
                logger.warning(st.detail)
                self.status = st
                return st

            rows: list[Recycler] = []
            skipped = 0
            with path.open(newline="", encoding="utf-8-sig") as fh:
                reader = csv.DictReader(fh)
                missing = [c for c in CSV_COLUMNS if c not in (reader.fieldnames or [])]
                if missing:
                    raise ValueError(f"recyclers.csv missing columns: {missing}")
                for raw in reader:
                    try:
                        rows.append(Recycler(
                            recycler_id=str(raw["recycler_id"]).strip(),
                            company_name=str(raw["company_name"]).strip(),
                            state=str(raw["state"]).strip(),
                            latitude=float(raw["latitude"]),
                            longitude=float(raw["longitude"]),
                            service_radius_km=float(raw["service_radius_km"]),
                            materials_accepted=str(raw["materials_accepted"]).strip(),
                            authorization_status=str(raw["authorization_status"]).strip(),
                            fulfillment_score=float(raw["fulfillment_score"]),
                            permitted_capacity_mta=float(raw["permitted_capacity_mta"]),
                        ))
                    except (TypeError, ValueError) as exc:
                        skipped += 1
                        logger.warning("skipping malformed recycler row %r: %s",
                                       raw.get("recycler_id"), exc)

            self._recyclers = rows
            st.loaded = True
            st.recycler_count = len(rows)
            st.skipped_rows = skipped
            logger.info("Loaded %d recyclers (%d skipped) from %s",
                        len(rows), skipped, path)
        except Exception as exc:  # noqa: BLE001 — keep service up, empty registry
            st.detail = f"failed to load recyclers.csv: {exc}"
            logger.exception("recyclers.csv load failure")
        self.status = st
        return st

    def ensure_loaded(self) -> None:
        if not self.status.loaded and self.status.recycler_count == 0 and not self.status.detail:
            self.load()

    # ------------------------------------------------------------------ #
    # Ranking (deterministic — no randomness, no ML)                      #
    # ------------------------------------------------------------------ #
    def match(
        self,
        material_category: str,
        latitude: float,
        longitude: float,
        limit: int = FALLBACK_RECYCLER_COUNT,
    ) -> dict[str, Any]:
        self.ensure_loaded()
        category = material_category.strip().upper()

        scored: list[dict[str, Any]] = []
        for r in self._recyclers:
            if not r.is_active or not r.accepts(category):
                continue
            d_km = round(haversine_km(latitude, longitude, r.latitude, r.longitude), 3)
            scored.append(self._score(r, d_km))

        within = [
            m for m in scored
            if m["distance_km"] <= max(m["service_radius_km"], MIN_SERVICE_RADIUS_KM)
        ]

        if within:
            # Contract sort: match_score DESC, distance_km ASC, recycler_id ASC.
            ranked = sorted(within, key=lambda m: (-m["match_score"], m["distance_km"], m["recycler_id"]))
            return {
                "material_category": category,
                "origin": {"latitude": latitude, "longitude": longitude},
                "matches": ranked[:limit],
                "matched_count": len(ranked[:limit]),
                "radius_relaxed": False,
                "note": None,
            }

        # Fallback: closest 5 ACTIVE recyclers accepting the category,
        # radius relaxed, ordered strictly by distance ASC then recycler_id ASC.
        fallback = sorted(scored, key=lambda m: (m["distance_km"], m["recycler_id"]))[
            :FALLBACK_RECYCLER_COUNT]
        for m in fallback:
            m["within_service_radius"] = False
        if not fallback:
            return {
                "material_category": category,
                "origin": {"latitude": latitude, "longitude": longitude},
                "matches": [],
                "matched_count": 0,
                "radius_relaxed": False,
                "note": "no ACTIVE recycler accepts this category",
            }

        return {
            "material_category": category,
            "origin": {"latitude": latitude, "longitude": longitude},
            "matches": fallback,
            "matched_count": len(fallback),
            "radius_relaxed": True,
            "note": f"no recycler within service radius; returning closest "
                    f"{FALLBACK_RECYCLER_COUNT} active recyclers (radius relaxed)",
        }

    # ------------------------------------------------------------------ #
    # Scoring                                                             #
    # ------------------------------------------------------------------ #
    @staticmethod
    def _score(r: Recycler, distance_km: float) -> dict[str, Any]:
        distance_term = W_DISTANCE * math.exp(-distance_km / DISTANCE_DECAY_KM)
        fulfillment_term = W_FULFILLMENT * r.fulfillment_score
        capacity_term = W_CAPACITY * min(r.permitted_capacity_mta / CAPACITY_NORM_MTA, 1.0)
        match_score = round(distance_term + fulfillment_term + capacity_term, 6)
        effective_radius = max(r.service_radius_km, MIN_SERVICE_RADIUS_KM)
        return {
            "recycler_id": r.recycler_id,
            "company_name": r.company_name,
            "state": r.state,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "service_radius_km": r.service_radius_km,
            "materials_accepted": r.materials_accepted,
            "authorization_status": r.authorization_status.upper(),
            "fulfillment_score": r.fulfillment_score,
            "permitted_capacity_mta": r.permitted_capacity_mta,
            "distance_km": distance_km,
            "match_score": match_score,
            "score_breakdown": {
                "distance_term": round(distance_term, 6),
                "fulfillment_term": round(fulfillment_term, 6),
                "capacity_term": round(capacity_term, 6),
            },
            "within_service_radius": distance_km <= effective_radius,
        }
