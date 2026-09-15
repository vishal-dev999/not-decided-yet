"""
Central configuration for the E-Waste Valuation & Logistics API.

All settings are overridable via environment variables (prefix: EWASTE_)
or a local `.env` file. Defaults are safe for local development.

Env var mapping (pydantic-settings, case-insensitive):
    EWASTE_DEFAULT_CITY            -> default_city          (default "Bhubaneswar")
    EWASTE_MODELS_DIR              -> models_dir            (default "models")
    EWASTE_DATA_DIR                -> data_dir              (default "data")
    EWASTE_VALUATION_MODEL_PATH    -> valuation_model_path  (default "models/valuation_model.pkl")
    EWASTE_ENCODERS_PATH           -> encoders_path         (default "models/encoders.pkl")
    EWASTE_RECYCLERS_CSV_PATH      -> recyclers_csv_path    (default "data/recyclers.csv")
    EWASTE_DEV_SQLITE_DB_PATH      -> dev_sqlite_db_path    (default "data/dev_sync.db")
    EWASTE_SYNC_BATCH_LIMIT        -> sync_batch_limit      (default 500)
    EWASTE_DEBUG                   -> debug                 (default False)
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# ---------------------------------------------------------------------------
# Business constants (fixed by contract — NOT env-tunable)
# ---------------------------------------------------------------------------
EARTH_RADIUS_KM: float = 6371.0

# match_score = 0.60*exp(-d/75) + 0.30*fulfillment + 0.10*min(cap/5000, 1)
W_DISTANCE: float = 0.60
W_FULFILLMENT: float = 0.30
W_CAPACITY: float = 0.10
DISTANCE_DECAY_KM: float = 75.0
CAPACITY_NORM_MTA: float = 5000.0
MIN_SERVICE_RADIUS_KM: float = 150.0
FALLBACK_RECYCLER_COUNT: int = 5

APP_NAME: str = "E-Waste Valuation & Recycler Matching API"
API_VERSION: str = "1.0.0"
API_PREFIX: str = "/v1"


class Settings(BaseSettings):
    """Runtime settings (paths, defaults, limits)."""

    model_config = SettingsConfigDict(
        env_prefix="EWASTE_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # --- Application -------------------------------------------------------
    debug: bool = False
    default_city: str = "Bhubaneswar"

    # --- Artifact / dataset paths -----------------------------------------
    models_dir: Path = Path("models")
    data_dir: Path = Path("data")

    valuation_model_path: Path = Path("models/valuation_model.pkl")
    encoders_path: Path = Path("models/encoders.pkl")
    recyclers_csv_path: Path = Path("data/recyclers.csv")

    # --- Sync gateway (dev idempotency store) ------------------------------
    dev_sqlite_db_path: Path = Path("data/dev_sync.db")
    sync_batch_limit: int = 500

    # --- Derived helpers ---------------------------------------------------
    def resolve_model_path(self) -> Path:
        return self.valuation_model_path

    def resolve_encoders_path(self) -> Path:
        return self.encoders_path

    def ensure_dirs(self) -> None:
        """Create runtime dirs (data dir for the dev sqlite db, etc.)."""
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.models_dir.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    """Cached settings accessor (FastAPI dependency-friendly)."""
    return Settings()
