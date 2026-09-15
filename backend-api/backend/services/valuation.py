"""
Valuation service.

Contract (locked):
  * `models/valuation_model.pkl` : fitted sklearn RandomForestRegressor,
    trained on exactly 3 features, feature order:
        [material_category_enc, sub_category_enc, location_cluster_enc]
    i.e. predict input shape is [[cat_enc, subcat_enc, loc_enc]].
  * `models/encoders.pkl` : joblib tuple (le_cat, le_subcat, le_loc) of three
    sklearn LabelEncoders; unpacked as:
        le_cat, le_subcat, le_loc = joblib.load(path)
        le_cat    encodes material_category   ('PCB', 'BATTERY', 'METAL', 'RESIDUAL')
        le_subcat encodes sub_category        ('HIGH_GRADE', 'LOW_GRADE', ...)
        le_loc    encodes location_cluster    ('Bhubaneswar', ...)

The service NEVER raises on unknown classes/cities or missing/corrupt
artifacts — it degrades to baseline pricing and reports why.
"""

from __future__ import annotations

import logging
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional

import joblib

from backend.config import Settings, get_settings

logger = logging.getLogger("backend.valuation")

# ---------------------------------------------------------------------------
# TFLite class -> (material_category, sub_category, baseline_inr_per_kg)
# Locked class-mapping bridge. Single source of truth for Phase 1.
# ---------------------------------------------------------------------------
CLASS_BRIDGE: dict[str, tuple[str, str, float]] = {
    "MOTHERBOARD_HIGH_GRADE": ("PCB", "HIGH_GRADE", 450.0),
    "POWER_SUPPLY_LOW_GRADE": ("PCB", "LOW_GRADE", 45.0),
    "BATTERY_LITHIUM_PORTABLE": ("BATTERY", "LITHIUM_ION", 220.0),
    "LEAD_ACID": ("BATTERY", "LEAD_ACID", 95.0),
    "COPPER_HEAVY_INSULATED": ("METAL", "COPPER_INSULATED", 420.0),
    "NON_RECYCLABLE": ("RESIDUAL", "NON_RECYCLABLE", 0.0),
}

# Sub-category -> baseline (used when a request supplies category/subcategory
# directly instead of a TFLite label).
SUBCATEGORY_BASELINES: dict[str, float] = {
    sub: baseline for (_, sub, baseline) in CLASS_BRIDGE.values()
}

# Valuation modes reported to clients.
MODE_MODEL = "MODEL"
MODE_BASELINE_FALLBACK = "BASELINE_FALLBACK"
MODE_BASELINE_FLOOR = "BASELINE_FLOOR"  # fixed 0.0 for NON_RECYCLABLE


@dataclass
class ArtifactStatus:
    model_loaded: bool = False
    encoders_loaded: bool = False
    model_n_features: Optional[int] = None
    known_cities: list[str] = field(default_factory=list)
    detail: str = ""


class ValuationService:
    """Loads valuation artifacts once; degrades gracefully to baselines."""

    def __init__(self, settings: Optional[Settings] = None) -> None:
        self.settings = settings or get_settings()
        self._lock = threading.Lock()
        self.model: Any = None
        self.le_cat: Any = None
        self.le_subcat: Any = None
        self.le_loc: Any = None
        self.status: ArtifactStatus = ArtifactStatus()

    # ------------------------------------------------------------------ #
    # Artifact loading                                                    #
    # ------------------------------------------------------------------ #
    def load(self) -> ArtifactStatus:
        """Load model + encoders. Any failure leaves fallback mode active."""
        with self._lock:
            st = ArtifactStatus()

            # --- encoders: joblib tuple (le_cat, le_subcat, le_loc) --------
            enc_path: Path = self.settings.resolve_encoders_path()
            try:
                if enc_path.exists():
                    loaded = joblib.load(enc_path)
                    if not (isinstance(loaded, tuple) and len(loaded) == 3):
                        raise ValueError(
                            f"encoders.pkl must be a 3-tuple of LabelEncoders, "
                            f"got {type(loaded)!r}"
                        )
                    self.le_cat, self.le_subcat, self.le_loc = loaded
                    st.encoders_loaded = True
                    st.known_cities = [str(c) for c in getattr(self.le_loc, "classes_", [])]
                else:
                    st.detail += f"encoders not found at {enc_path}; "
            except Exception as exc:  # noqa: BLE001 — degrade, never crash
                self.le_cat = self.le_subcat = self.le_loc = None
                st.detail += f"encoders load failed ({exc}); "

            # --- model: RandomForestRegressor(n_features_in_ == 3) ---------
            model_path: Path = self.settings.resolve_model_path()
            try:
                if model_path.exists():
                    model = joblib.load(model_path)
                    n_feats = int(getattr(model, "n_features_in_", -1))
                    if n_feats != 3:
                        raise ValueError(
                            f"valuation_model.pkl must expose n_features_in_=3, got {n_feats}"
                        )
                    self.model = model
                    st.model_loaded = True
                    st.model_n_features = n_feats
                else:
                    st.detail += f"model not found at {model_path}; "
            except Exception as exc:  # noqa: BLE001
                self.model = None
                st.detail += f"model load failed ({exc}); "

            self.status = st
            logger.info("Valuation artifacts: model=%s encoders=%s (%s)",
                        st.model_loaded, st.encoders_loaded, st.detail.strip() or "ok")
            return st

    def ensure_loaded(self) -> None:
        if self.status.model_loaded is False and self.status.encoders_loaded is False \
                and self.model is None and self.le_cat is None:
            self.load()

    # ------------------------------------------------------------------ #
    # Bridge resolution                                                   #
    # ------------------------------------------------------------------ #
    @staticmethod
    def resolve_material(
        tflite_class: Optional[str] = None,
        material_category: Optional[str] = None,
        sub_category: Optional[str] = None,
    ) -> Optional[tuple[str, str, float]]:
        """
        Resolve (category, subcategory, baseline_inr_per_kg).

        Priority: tflite_class (when recognized) > explicit category+subcategory.
        Returns None if nothing resolvable was supplied.
        """
        if tflite_class:
            key = tflite_class.strip().upper()
            if key in CLASS_BRIDGE:
                return CLASS_BRIDGE[key]
            # unknown label: fall through to explicit category/subcategory
        if material_category and sub_category:
            cat = material_category.strip().upper()
            sub = sub_category.strip().upper()
            baseline = SUBCATEGORY_BASELINES.get(sub)
            if baseline is not None:
                return (cat, sub, baseline)
        return None

    # ------------------------------------------------------------------ #
    # Core estimation                                                     #
    # ------------------------------------------------------------------ #
    def estimate(
        self,
        tflite_class: Optional[str] = None,
        material_category: Optional[str] = None,
        sub_category: Optional[str] = None,
        weight_kg: Optional[float] = None,
        location_cluster: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Produce a price estimate dict. Always succeeds:

          MODE_MODEL             -> RandomForest prediction from
                                    [[cat_enc, subcat_enc, loc_enc]]
          MODE_BASELINE_FALLBACK -> baseline from the class bridge (missing
                                    artifacts, unknown class/city, model error)
          MODE_BASELINE_FLOOR    -> fixed 0.0 INR/kg for NON_RECYCLABLE
        """
        self.ensure_loaded()
        city = (location_cluster or self.settings.default_city).strip()
        known_class = tflite_class and tflite_class.strip().upper() in CLASS_BRIDGE

        resolved = self.resolve_material(tflite_class, material_category, sub_category)

        # Nothing resolvable at all -> report unresolvable input, price 0.
        if resolved is None:
            return self._payload(
                category=(material_category or "").upper() or None,
                subcategory=(sub_category or "").upper() or None,
                tflite_class=(tflite_class or "").upper() or None,
                baseline=0.0,
                price_per_kg=0.0,
                weight_kg=weight_kg,
                city=city,
                mode=MODE_BASELINE_FALLBACK,
                reason=(
                    f"unresolvable material input "
                    f"(tflite_class known={bool(known_class)}, "
                    f"category/subcategory complete={bool(material_category and sub_category)})"
                ),
            )

        category, subcategory, baseline = resolved

        # NON_RECYCLABLE (and any zero-baseline material): fixed floor, no model.
        if baseline <= 0.0:
            return self._payload(
                category=category, subcategory=subcategory,
                tflite_class=(tflite_class or "").upper() or None,
                baseline=baseline, price_per_kg=0.0, weight_kg=weight_kg,
                city=city, mode=MODE_BASELINE_FLOOR,
                reason="zero-baseline material (non-recyclable) — fixed at 0.0 INR/kg",
            )

        # Try the trained model path: [[cat_enc, subcat_enc, loc_enc]].
        if self.model is not None and self.le_cat is not None \
                and self.le_subcat is not None and self.le_loc is not None:
            try:
                cat_enc = int(self.le_cat.transform([category])[0])
                sub_enc = int(self.le_subcat.transform([subcategory])[0])
                loc_enc = int(self.le_loc.transform([city])[0])
                pred = float(self.model.predict([[cat_enc, sub_enc, loc_enc]])[0])
                if pred != pred:  # NaN guard
                    raise ValueError("model produced NaN")
                price_per_kg = max(0.0, pred)
                return self._payload(
                    category=category, subcategory=subcategory,
                    tflite_class=(tflite_class or "").upper() or None,
                    baseline=baseline, price_per_kg=round(price_per_kg, 2),
                    weight_kg=weight_kg, city=city, mode=MODE_MODEL, reason=None,
                )
            except ValueError as exc:
                # Unknown category/subcategory/city label -> ValueError from
                # LabelEncoder.transform. Fall back to baseline, no 500.
                reason = f"model path unavailable: {exc}"
            except Exception as exc:  # noqa: BLE001 — model/inference failure
                logger.exception("valuation model inference failed")
                reason = f"model inference error: {exc}"
        else:
            reason = (
                self.status.detail.strip()
                or "artifacts not loaded — baseline fallback active"
            )

        # Baseline fallback (contract-mandated graceful degradation).
        return self._payload(
            category=category, subcategory=subcategory,
            tflite_class=(tflite_class or "").upper() or None,
            baseline=baseline, price_per_kg=baseline, weight_kg=weight_kg,
            city=city, mode=MODE_BASELINE_FALLBACK, reason=reason,
        )

    # ------------------------------------------------------------------ #
    # Response shaping                                                    #
    # ------------------------------------------------------------------ #
    @staticmethod
    def _payload(
        *,
        category: Optional[str],
        subcategory: Optional[str],
        tflite_class: Optional[str],
        baseline: float,
        price_per_kg: float,
        weight_kg: Optional[float],
        city: str,
        mode: str,
        reason: Optional[str],
    ) -> dict[str, Any]:
        total = round(price_per_kg * weight_kg, 2) if weight_kg is not None else None
        return {
            "tflite_class": tflite_class,
            "material_category": category,
            "sub_category": subcategory,
            "location_cluster": city,
            "baseline_inr_per_kg": baseline,
            "estimated_price_inr_per_kg": round(price_per_kg, 2),
            "weight_kg": weight_kg,
            "estimated_total_value_inr": total,
            "valuation_mode": mode,
            "fallback_reason": reason,
        }
