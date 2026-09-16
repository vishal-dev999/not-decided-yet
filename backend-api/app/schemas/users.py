from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class CollectorOut(ORMModel):
    id: str
    phone: str
    full_name: str
    language: str
    city: str
    state: str
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    upi_id: Optional[str] = None
    aadhaar_last4: Optional[str] = None
    earnings_balance: float
    pending_dues: float
    is_active: bool
    created_at: datetime


class CollectorUpdateIn(BaseModel):
    full_name: Optional[str] = None
    language: Optional[str] = Field(None, pattern="^(hi|mr|en)$")
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    upi_id: Optional[str] = None


class RecyclerOut(ORMModel):
    id: str
    recycler_code: str
    company_name: str
    authorization_no: str
    email: str
    phone: str
    address: str
    city: str
    state: str
    pincode: Optional[str] = None
    latitude: float
    longitude: float
    pickup_available: bool
    karma_points: float
    price_multiplier: float
    accepted_categories: str
    verified: bool
    is_active: bool


class RecyclerPublicOut(ORMModel):
    id: str
    recycler_code: str
    company_name: str
    authorization_no: str
    city: str
    state: str
    pickup_available: bool
    karma_points: float
    verified: bool


class RecyclerUpdateIn(BaseModel):
    pickup_available: Optional[bool] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    price_multiplier: Optional[float] = Field(None, ge=0.5, le=1.5)
    accepted_categories: Optional[str] = None
