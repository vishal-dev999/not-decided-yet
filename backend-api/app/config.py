from functools import lru_cache
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "Kabadiwala API"
    app_env: str = "development"
    app_debug: bool = True
    secret_key: str = "dev-secret-change-in-production-kabadiwala-2026"
    access_token_expire_minutes: int = 60 * 24 * 7
    refresh_token_expire_minutes: int = 60 * 24 * 30
    algorithm: str = "HS256"

    database_url: str = "sqlite:///./data/kabadiwala.db"
    cors_origins: str = "*"
    api_prefix: str = "/api/v1"
    host: str = "0.0.0.0"
    port: int = 8000
    seed_on_startup: bool = True

    match_w_distance: float = 0.40
    match_w_price: float = 0.30
    match_w_availability: float = 0.15
    match_w_karma: float = 0.15
    match_top_n: int = 3
    match_max_distance_km: float = 150.0

    upload_dir: str = "storage/uploads"
    export_dir: str = "storage/exports"

    @property
    def cors_origin_list(self) -> List[str]:
        raw = (self.cors_origins or "*").strip()
        if raw == "*":
            return ["*"]
        return [o.strip() for o in raw.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
