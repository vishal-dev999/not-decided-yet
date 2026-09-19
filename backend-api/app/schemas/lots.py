from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, ConfigDict

from app.schemas.common import ORMModel


class ClassificationIn(BaseModel):
    label: str = Field(..., examples=["pcb"])
    confidence: float = Field(..., ge=0, le=1)
    model_version: str = "mobile-v1"


class LotSyncItem(BaseModel):
    """One queued lot from the collector's offline local database."""

    # Accepts either "lot_uid" (from Flutter) or "client_lot_id"
    client_lot_id: str = Field(
        ...,
        validation_alias="lot_uid",
        description="UUID generated on device; used for idempotent sync",
    )
    material_category: str = Field(..., examples=["MOTHERBOARD_HIGH_GRADE"])

    # Accepts either "approx_weight_kg" (from Flutter) or "estimated_weight_kg"
    estimated_weight_kg: float = Field(
        ...,
        gt=0,
        le=5000,
        validation_alias="approx_weight_kg",
    )

    classification: Optional[ClassificationIn] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    city: Optional[str] = "Bhubaneswar"
    notes: Optional[str] = None
    qr_token: Optional[str] = Field(
        None, description="Offline-generated QR payload token. Server stores and later verifies it."
    )
    photo_base64: Optional[str] = Field(None, description="Optional JPEG/PNG as base64 (no data: prefix)")

    # Accepts either "created_at" (from Flutter) or "created_at_local"
    created_at_local: Optional[datetime] = Field(
        None,
        validation_alias="created_at",
    )

    # Allow passing either field name or alias in Pydantic v2
    model_config = ConfigDict(
        populate_by_name=True,
        extra="ignore",  # safely ignores 'estimated_rate_per_kg' and 'estimated_total_payout' sent from Flutter
    )


class LotSyncIn(BaseModel):
    lots: list[LotSyncItem] = Field(..., min_length=1, max_length=50)


class LotOut(ORMModel):
    id: str
    collector_id: str
    client_lot_id: str
    material_category: str
    estimated_weight_kg: float
    classification_label: Optional[str] = None
    classification_confidence: Optional[float] = None
    model_version: Optional[str] = None
    photo_path: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None
    notes: Optional[str] = None
    qr_token: str
    status: str
    claimed_by: Optional[str] = None
    pickup_scheduled_at: Optional[datetime] = None
    synced_at: datetime
    updated_at: datetime


class LotStatusOut(BaseModel):
    lot_id: str
    status: str
    claimed_by: Optional[str] = None
    recycler: Optional[dict] = None
    transaction: Optional[dict] = None
    spoken: dict[str, str] = Field(default_factory=dict)


class ClaimIn(BaseModel):
    pickup_minutes_from_now: int = Field(60, ge=15, le=24 * 60)


class QRVerifyIn(BaseModel):
    qr_token: str = Field(..., min_length=8)
    client_lot_id: Optional[str] = None


class WeighbridgeIn(BaseModel):
    certified_weight_kg: float = Field(..., gt=0, le=5000, examples=[14.0])
    offered_rate_per_kg: float = Field(..., gt=0, le=100000, examples=[220.0])
    notes: Optional[str] = None


class ConsentIn(BaseModel):
    accepted: bool
    payment_mode: Optional[str] = Field(None, pattern="^(CASH|UPI)$")
    upi_reference: Optional[str] = None


class CompleteIn(BaseModel):
    payment_mode: str = Field(..., pattern="^(CASH|UPI)$")
    upi_reference: Optional[str] = None


class MatchOfferOut(ORMModel):
    id: str
    lot_id: str
    recycler_id: str
    rank: int
    score: float
    distance_km: float
    offered_price_per_kg: float
    availability: bool
    karma_points: float
    status: str
    recycler_name: Optional[str] = None
    recycler_city: Optional[str] = None
    authorization_no: Optional[str] = None