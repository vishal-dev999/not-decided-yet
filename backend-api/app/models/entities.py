from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def new_id() -> str:
    return str(uuid.uuid4())


class Collector(Base):
    __tablename__ = "collectors"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    phone: Mapped[str] = mapped_column(String(15), unique=True, index=True)
    pin_hash: Mapped[str] = mapped_column(String(128))
    full_name: Mapped[str] = mapped_column(String(120))
    language: Mapped[str] = mapped_column(String(8), default="hi")  # hi | mr | en
    city: Mapped[str] = mapped_column(String(80), default="Cuttack")
    state: Mapped[str] = mapped_column(String(80), default="Odisha")
    pincode: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    upi_id: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    aadhaar_last4: Mapped[Optional[str]] = mapped_column(String(4), nullable=True)
    earnings_balance: Mapped[float] = mapped_column(Float, default=0.0)
    pending_dues: Mapped[float] = mapped_column(Float, default=0.0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )

    lots: Mapped[list["Lot"]] = relationship(back_populates="collector")
    ledger_entries: Mapped[list["LedgerEntry"]] = relationship(back_populates="collector")


class Recycler(Base):
    __tablename__ = "recyclers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    recycler_code: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    company_name: Mapped[str] = mapped_column(String(200))
    authorization_no: Mapped[str] = mapped_column(String(80))
    email: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    phone: Mapped[str] = mapped_column(String(15))
    password_hash: Mapped[str] = mapped_column(String(128))
    address: Mapped[str] = mapped_column(Text, default="")
    city: Mapped[str] = mapped_column(String(80))
    state: Mapped[str] = mapped_column(String(80))
    pincode: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    pickup_available: Mapped[bool] = mapped_column(Boolean, default=True)
    karma_points: Mapped[float] = mapped_column(Float, default=50.0)
    price_multiplier: Mapped[float] = mapped_column(Float, default=1.0)
    accepted_categories: Mapped[str] = mapped_column(Text, default="*")  # csv or *
    verified: Mapped[bool] = mapped_column(Boolean, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    offers: Mapped[list["MatchOffer"]] = relationship(back_populates="recycler")


class Material(Base):
    __tablename__ = "materials"

    code: Mapped[str] = mapped_column(String(40), primary_key=True)
    name_en: Mapped[str] = mapped_column(String(80))
    name_hi: Mapped[str] = mapped_column(String(80))
    name_mr: Mapped[str] = mapped_column(String(80))
    e_waste_code: Mapped[str] = mapped_column(String(20), default="ITEW")
    unit: Mapped[str] = mapped_column(String(10), default="kg")
    hazardous: Mapped[bool] = mapped_column(Boolean, default=False)
    icon: Mapped[str] = mapped_column(String(40), default="recycle")


class PriceQuote(Base):
    """Current buying rate snapshot per material × city."""

    __tablename__ = "price_quotes"
    __table_args__ = (UniqueConstraint("material_code", "city", name="uq_price_material_city"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    material_code: Mapped[str] = mapped_column(ForeignKey("materials.code"), index=True)
    city: Mapped[str] = mapped_column(String(80), index=True)
    state: Mapped[str] = mapped_column(String(80), default="Odisha")
    buy_rate_per_kg: Mapped[float] = mapped_column(Float)
    min_rate: Mapped[float] = mapped_column(Float)
    max_rate: Mapped[float] = mapped_column(Float)
    source: Mapped[str] = mapped_column(String(80), default="seed")
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class PriceHistory(Base):
    __tablename__ = "price_history"
    __table_args__ = (Index("ix_ph_mat_city_date", "material_code", "city", "as_of"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    material_code: Mapped[str] = mapped_column(ForeignKey("materials.code"), index=True)
    city: Mapped[str] = mapped_column(String(80), index=True)
    as_of: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    buy_rate_per_kg: Mapped[float] = mapped_column(Float)


class Lot(Base):
    __tablename__ = "lots"
    __table_args__ = (
        UniqueConstraint("collector_id", "client_lot_id", name="uq_lot_client"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    collector_id: Mapped[str] = mapped_column(ForeignKey("collectors.id"), index=True)
    client_lot_id: Mapped[str] = mapped_column(String(64), index=True)
    material_category: Mapped[str] = mapped_column(String(40), index=True)
    estimated_weight_kg: Mapped[float] = mapped_column(Float)
    classification_label: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    classification_confidence: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    model_version: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    photo_path: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    qr_token: Mapped[str] = mapped_column(String(128), index=True)
    status: Mapped[str] = mapped_column(String(32), default="SYNCED", index=True)
    claimed_by: Mapped[Optional[str]] = mapped_column(
        ForeignKey("recyclers.id"), nullable=True, index=True
    )
    pickup_scheduled_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at_local: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    synced_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )

    collector: Mapped[Collector] = relationship(back_populates="lots")
    offers: Mapped[list["MatchOffer"]] = relationship(back_populates="lot")
    transaction: Mapped[Optional["Transaction"]] = relationship(
        back_populates="lot", uselist=False
    )


class MatchOffer(Base):
    __tablename__ = "match_offers"
    __table_args__ = (UniqueConstraint("lot_id", "recycler_id", name="uq_offer_lot_recycler"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    lot_id: Mapped[str] = mapped_column(ForeignKey("lots.id"), index=True)
    recycler_id: Mapped[str] = mapped_column(ForeignKey("recyclers.id"), index=True)
    rank: Mapped[int] = mapped_column(Integer)
    score: Mapped[float] = mapped_column(Float)
    distance_km: Mapped[float] = mapped_column(Float)
    offered_price_per_kg: Mapped[float] = mapped_column(Float)
    availability: Mapped[bool] = mapped_column(Boolean)
    karma_points: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(20), default="OFFERED")  # OFFERED|WITHDRAWN|CLAIMED|EXPIRED
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    lot: Mapped[Lot] = relationship(back_populates="offers")
    recycler: Mapped[Recycler] = relationship(back_populates="offers")


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    lot_id: Mapped[str] = mapped_column(ForeignKey("lots.id"), unique=True, index=True)
    collector_id: Mapped[str] = mapped_column(ForeignKey("collectors.id"), index=True)
    recycler_id: Mapped[str] = mapped_column(ForeignKey("recyclers.id"), index=True)
    certified_weight_kg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    offered_rate_per_kg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    total_amount: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    collector_consent: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    recycler_consent: Mapped[bool] = mapped_column(Boolean, default=True)
    payment_mode: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    upi_reference: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    receipt_number: Mapped[Optional[str]] = mapped_column(String(40), unique=True, nullable=True)
    fraud_score: Mapped[float] = mapped_column(Float, default=0.0)
    fraud_flags: Mapped[str] = mapped_column(Text, default="[]")
    status: Mapped[str] = mapped_column(String(24), default="OPEN")
    consented_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    lot: Mapped[Lot] = relationship(back_populates="transaction")
    seal: Mapped[Optional["TraceabilitySeal"]] = relationship(
        back_populates="transaction", uselist=False
    )


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    collector_id: Mapped[str] = mapped_column(ForeignKey("collectors.id"), index=True)
    transaction_id: Mapped[Optional[str]] = mapped_column(
        ForeignKey("transactions.id"), nullable=True
    )
    entry_type: Mapped[str] = mapped_column(String(16))  # CREDIT | DEBIT | DUE
    amount: Mapped[float] = mapped_column(Float)
    balance_after: Mapped[float] = mapped_column(Float)
    description: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    collector: Mapped[Collector] = relationship(back_populates="ledger_entries")


class TraceabilitySeal(Base):
    """Immutable CPCB audit seal + Form-6 snapshot."""

    __tablename__ = "traceability_seals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    lot_id: Mapped[str] = mapped_column(ForeignKey("lots.id"), unique=True, index=True)
    transaction_id: Mapped[str] = mapped_column(ForeignKey("transactions.id"), unique=True)
    manifest_no: Mapped[str] = mapped_column(String(40), unique=True)
    record_hash: Mapped[str] = mapped_column(String(64), unique=True)
    form6_json: Mapped[str] = mapped_column(Text)
    sealed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    transaction: Mapped[Transaction] = relationship(back_populates="seal")


class FraudAlert(Base):
    __tablename__ = "fraud_alerts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    lot_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    actor_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    severity: Mapped[str] = mapped_column(String(16), default="LOW")
    flag: Mapped[str] = mapped_column(String(64))
    message: Mapped[str] = mapped_column(Text)
    score: Mapped[float] = mapped_column(Float, default=0.0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class SafetyCard(Base):
    __tablename__ = "safety_cards"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    code: Mapped[str] = mapped_column(String(40), unique=True)
    title_en: Mapped[str] = mapped_column(String(160))
    title_hi: Mapped[str] = mapped_column(String(160))
    title_mr: Mapped[str] = mapped_column(String(160))
    body_en: Mapped[str] = mapped_column(Text)
    body_hi: Mapped[str] = mapped_column(Text)
    body_mr: Mapped[str] = mapped_column(Text)
    pictogram: Mapped[str] = mapped_column(String(40), default="warning")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)


class OTPChallenge(Base):
    """Prototype OTP store (fixed demo OTP 123456)."""

    __tablename__ = "otp_challenges"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    phone: Mapped[str] = mapped_column(String(15), index=True)
    code: Mapped[str] = mapped_column(String(8))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    consumed: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
