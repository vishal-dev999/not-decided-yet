from typing import Literal, Optional

from pydantic import BaseModel, EmailStr, Field


class CollectorRegisterIn(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15, examples=["9876543210"])
    pin: str = Field(..., min_length=4, max_length=8, examples=["1234"])
    full_name: str = Field(..., min_length=2, max_length=120)
    language: Literal["hi", "mr", "en"] = "hi"
    city: str = "Cuttack"
    state: str = "Odisha"
    pincode: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    upi_id: Optional[str] = None
    aadhaar_last4: Optional[str] = Field(None, min_length=4, max_length=4)


class CollectorLoginIn(BaseModel):
    phone: str
    pin: str


class OTPRequestIn(BaseModel):
    phone: str


class OTPVerifyIn(BaseModel):
    phone: str
    code: str = Field(..., min_length=4, max_length=8)
    full_name: Optional[str] = None
    language: Literal["hi", "mr", "en"] = "hi"
    pin: Optional[str] = Field(None, min_length=4, max_length=8)


class RecyclerRegisterIn(BaseModel):
    recycler_code: str
    company_name: str
    authorization_no: str
    email: EmailStr
    phone: str
    password: str = Field(..., min_length=6)
    address: str = ""
    city: str
    state: str
    pincode: Optional[str] = None
    latitude: float
    longitude: float
    pickup_available: bool = True
    accepted_categories: str = "*"


class RecyclerLoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    expires_in_minutes: int


class MeOut(BaseModel):
    role: str
    user: dict
