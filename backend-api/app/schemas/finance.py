from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class LedgerEntryOut(ORMModel):
    id: str
    collector_id: str
    transaction_id: Optional[str] = None
    entry_type: str
    amount: float
    balance_after: float
    description: str
    created_at: datetime


class EarningsOut(BaseModel):
    collector_id: str
    earnings_balance: float
    pending_dues: float
    lifetime_credits: float
    lifetime_debits: float
    transaction_count: int
    spoken: dict[str, str] = Field(default_factory=dict)


class TransactionOut(ORMModel):
    id: str
    lot_id: str
    collector_id: str
    recycler_id: str
    certified_weight_kg: Optional[float] = None
    offered_rate_per_kg: Optional[float] = None
    total_amount: Optional[float] = None
    collector_consent: Optional[bool] = None
    recycler_consent: bool
    payment_mode: Optional[str] = None
    upi_reference: Optional[str] = None
    receipt_number: Optional[str] = None
    fraud_score: float
    fraud_flags: str
    status: str
    consented_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime


class ReceiptOut(BaseModel):
    receipt_number: str
    lot_id: str
    transaction_id: str
    collector: dict
    recycler: dict
    material_category: str
    certified_weight_kg: float
    rate_per_kg: float
    total_amount: float
    payment_mode: str
    completed_at: datetime
    record_hash: Optional[str] = None
    spoken: dict[str, str] = Field(default_factory=dict)


class Form6Out(BaseModel):
    manifest_no: str
    lot_id: str
    sealed_at: datetime
    record_hash: str
    form: dict


class PriceBoardRow(BaseModel):
    material_code: str
    name_en: str
    name_hi: str
    name_mr: str
    e_waste_code: str
    city: str
    buy_rate_per_kg: float
    min_rate: float
    max_rate: float
    trend: str  # up | down | flat
    change_7d_pct: float
    spoken: dict[str, str]


class PriceEstimateIn(BaseModel):
    material_category: str
    weight_kg: float = Field(..., gt=0)
    city: str = "Cuttack"


class PriceEstimateOut(BaseModel):
    material_category: str
    city: str
    weight_kg: float
    rate_per_kg: float
    estimated_total: float
    low_total: float
    high_total: float
    trend: str
    spoken: dict[str, str]


class PriceTrendPoint(BaseModel):
    as_of: datetime
    buy_rate_per_kg: float


class PriceTrendOut(BaseModel):
    material_code: str
    city: str
    points: list[PriceTrendPoint]
    sma_7: Optional[float] = None
    sma_30: Optional[float] = None
    slope_per_day: Optional[float] = None
    forecast_7d: Optional[float] = None
    volatility: Optional[float] = None
