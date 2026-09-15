"""
Pydantic v2 request/response schemas for the E-Waste Valuation API.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field, model_validator

# ---------------------------------------------------------------------------
# Valuation
# ---------------------------------------------------------------------------
class ValuationRequest(BaseModel):
    """Either `tflite_class` (preferred, from on-device grading) or an explicit
    `material_category` + `sub_category` pair must be provided."""

    tflite_class: Optional[str] = Field(
        default=None,
        description="TFLite classifier label, e.g. MOTHERBOARD_HIGH_GRADE",
        examples=["MOTHERBOARD_HIGH_GRADE"],
    )
    material_category: Optional[str] = Field(default=None, examples=["PCB"])
    sub_category: Optional[str] = Field(default=None, examples=["HIGH_GRADE"])
    weight_kg: Optional[float] = Field(default=None, gt=0, le=100_000)
    location_cluster: Optional[str] = Field(
        default=None,
        description="City/cluster for regional pricing. Defaults to server default city.",
        examples=["Bhubaneswar"],
    )

    @model_validator(mode="after")
    def _require_material_input(self) -> "ValuationRequest":
        if not self.tflite_class and not (self.material_category and self.sub_category):
            raise ValueError(
                "provide either 'tflite_class' or both 'material_category' and 'sub_category'"
            )
        return self


class ValuationResponse(BaseModel):
    tflite_class: Optional[str] = None
    material_category: Optional[str] = None
    sub_category: Optional[str] = None
    location_cluster: str
    baseline_inr_per_kg: float
    estimated_price_inr_per_kg: float
    weight_kg: Optional[float] = None
    estimated_total_value_inr: Optional[float] = None
    valuation_mode: str = Field(
        description="MODEL | BASELINE_FALLBACK | BASELINE_FLOOR",
    )
    fallback_reason: Optional[str] = None


# ---------------------------------------------------------------------------
# Recycler matching
# ---------------------------------------------------------------------------
class RecyclerMatchRequest(BaseModel):
    material_category: str = Field(examples=["PCB"])
    latitude: float = Field(ge=-90, le=90, examples=[20.2961])
    longitude: float = Field(ge=-180, le=180, examples=[85.8245])
    limit: int = Field(default=5, ge=1, le=50)


class RecyclerMatch(BaseModel):
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
    distance_km: float
    match_score: float
    score_breakdown: dict[str, float]
    within_service_radius: bool


class RecyclerMatchResponse(BaseModel):
    material_category: str
    origin: dict[str, float]
    matches: list[RecyclerMatch]
    matched_count: int
    radius_relaxed: bool
    note: Optional[str] = None


# ---------------------------------------------------------------------------
# Combined lot evaluation (valuation + logistics in one call)
# ---------------------------------------------------------------------------
class LotEvaluationRequest(BaseModel):
    tflite_class: Optional[str] = None
    material_category: Optional[str] = None
    sub_category: Optional[str] = None
    weight_kg: Optional[float] = Field(default=None, gt=0, le=100_000)
    location_cluster: Optional[str] = None
    pickup_latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    pickup_longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    match_limit: int = Field(default=5, ge=1, le=50)

    @model_validator(mode="after")
    def _require_material_input(self) -> "LotEvaluationRequest":
        if not self.tflite_class and not (self.material_category and self.sub_category):
            raise ValueError(
                "provide either 'tflite_class' or both 'material_category' and 'sub_category'"
            )
        return self

    @model_validator(mode="after")
    def _require_pairwise_coords(self) -> "LotEvaluationRequest":
        if (self.pickup_latitude is None) != (self.pickup_longitude is None):
            raise ValueError("provide both pickup_latitude and pickup_longitude (or neither)")
        return self


class LotEvaluationResponse(BaseModel):
    valuation: ValuationResponse
    logistics: Optional[RecyclerMatchResponse] = None
    logistics_note: Optional[str] = None


# ---------------------------------------------------------------------------
# Batch sync (offline outbox ingest + rate cache refresh)
# ---------------------------------------------------------------------------
class PendingLot(BaseModel):
    """One queued offline lot from the Flutter outbox (`pending_lots`)."""

    lot_uuid: str = Field(
        min_length=8, max_length=64,
        description="Client-generated UUID — the idempotency key",
        examples=["3f2b8c4e-9d71-4f3a-b5c2-1e6a9d0f7a12"],
    )
    tflite_class: Optional[str] = None
    material_category: Optional[str] = None
    sub_category: Optional[str] = None
    weight_kg: Optional[float] = Field(default=None, gt=0, le=100_000)
    location_cluster: Optional[str] = None
    device_id: Optional[str] = None
    captured_at: Optional[datetime] = None
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    offline_estimated_value_inr: Optional[float] = Field(default=None, ge=0)
    image_ref: Optional[str] = Field(
        default=None,
        description="Client-side image reference for later field-image upload",
    )
    extra: dict[str, Any] = Field(default_factory=dict)


class BatchSyncManifest(BaseModel):
    """`POST /v1/sync/lots` request body: outbox batch + optional client rate-cache version."""

    device_id: str = Field(min_length=1, examples=["flutter-device-001"])
    pending_lots: list[PendingLot] = Field(default_factory=list)
    client_rate_cache_version: Optional[str] = None


class LotSyncStatus(BaseModel):
    lot_uuid: str
    status: str = Field(description="SYNCED | DUPLICATE | REJECTED")
    reason: Optional[str] = None


class RateCacheEntry(BaseModel):
    tflite_class: str
    material_category: str
    sub_category: str
    inr_per_kg: float
    source: str = "BASELINE_V1"


class BatchSyncResponse(BaseModel):
    device_id: str
    server_time: datetime
    received_count: int
    synced_lot_uuids: list[str]
    duplicate_lot_uuids: list[str]
    lot_statuses: list[LotSyncStatus]
    total_synced_lots_on_server: int
    rate_cache: list[RateCacheEntry]
    rate_cache_version: str
    store_available: bool


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
class HealthResponse(BaseModel):
    status: str
    app_name: str
    api_version: str
    server_time: datetime
    default_city: str
    artifacts: dict[str, Any]
    synced_lots_on_server: int
