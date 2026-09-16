from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config import settings
from app.core.exceptions import AppError
from app.core.security import create_token, hash_password, verify_password
from app.database import get_db
from app.models.entities import Collector, OTPChallenge, Recycler
from app.schemas.auth import (
    CollectorLoginIn,
    CollectorRegisterIn,
    OTPRequestIn,
    OTPVerifyIn,
    RecyclerLoginIn,
    RecyclerRegisterIn,
    TokenOut,
)
from app.schemas.users import CollectorOut, RecyclerOut
from app.deps import get_any_user
from app.utils.i18n import spoken

router = APIRouter(prefix="/auth", tags=["Auth"])

DEMO_OTP = "123456"


def _tokens(user_id: str, role: str) -> TokenOut:
    extra = {"role": role}
    return TokenOut(
        access_token=create_token(user_id, role, "access", extra),
        refresh_token=create_token(user_id, role, "refresh", extra),
        role=role,
        user_id=user_id,
        expires_in_minutes=settings.access_token_expire_minutes,
    )


@router.post("/collector/register", response_model=dict, status_code=201)
def register_collector(body: CollectorRegisterIn, db: Session = Depends(get_db)):
    if db.query(Collector).filter(Collector.phone == body.phone).first():
        raise AppError(409, "PHONE_TAKEN", "This phone is already registered.")
    collector = Collector(
        phone=body.phone,
        pin_hash=hash_password(body.pin),
        full_name=body.full_name,
        language=body.language,
        city=body.city,
        state=body.state,
        pincode=body.pincode,
        latitude=body.latitude,
        longitude=body.longitude,
        upi_id=body.upi_id,
        aadhaar_last4=body.aadhaar_last4,
    )
    db.add(collector)
    db.commit()
    db.refresh(collector)
    tokens = _tokens(collector.id, "collector")
    return {
        "ok": True,
        "message": "Collector registered.",
        "message_spoken": spoken(
            "Welcome. Your profile is ready.",
            "स्वागत है। आपका प्रोफ़ाइल तैयार है।",
            "स्वागत आहे. तुमची प्रोफाइल तयार आहे.",
        ),
        "tokens": tokens.model_dump(),
        "collector": CollectorOut.model_validate(collector).model_dump(),
    }


@router.post("/collector/login", response_model=dict)
def login_collector(body: CollectorLoginIn, db: Session = Depends(get_db)):
    collector = db.query(Collector).filter(Collector.phone == body.phone).first()
    if not collector or not verify_password(body.pin, collector.pin_hash):
        raise AppError(
            401,
            "BAD_CREDENTIALS",
            "Phone or PIN is incorrect.",
            spoken=spoken("Phone or PIN is wrong.", "फ़ोन या पिन गलत है।", "फोन किंवा पिन चुकीचा आहे."),
        )
    tokens = _tokens(collector.id, "collector")
    return {
        "ok": True,
        "tokens": tokens.model_dump(),
        "collector": CollectorOut.model_validate(collector).model_dump(),
        "message_spoken": spoken("Signed in.", "साइन इन हो गया।", "साइन इन झाले."),
    }


@router.post("/collector/otp/request", response_model=dict)
def request_otp(body: OTPRequestIn, db: Session = Depends(get_db)):
    """Prototype OTP — always 123456. Replace with SMS gateway later."""
    db.add(
        OTPChallenge(
            phone=body.phone,
            code=DEMO_OTP,
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
        )
    )
    db.commit()
    return {
        "ok": True,
        "message": "OTP sent (prototype). Use 123456.",
        "demo_otp": DEMO_OTP,
        "message_spoken": spoken(
            "One two three four five six is your code.",
            "आपका कोड एक दो तीन चार पाँच छह है।",
            "तुमचा कोड एक दोन तीन चार पाच सहा आहे.",
        ),
    }


@router.post("/collector/otp/verify", response_model=dict)
def verify_otp(body: OTPVerifyIn, db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    row = (
        db.query(OTPChallenge)
        .filter(
            OTPChallenge.phone == body.phone,
            OTPChallenge.code == body.code,
            OTPChallenge.consumed.is_(False),
            OTPChallenge.expires_at >= now,
        )
        .order_by(OTPChallenge.created_at.desc())
        .first()
    )
    if not row:
        raise AppError(400, "BAD_OTP", "OTP is invalid or expired.")
    row.consumed = True
    collector = db.query(Collector).filter(Collector.phone == body.phone).first()
    created = False
    if not collector:
        collector = Collector(
            phone=body.phone,
            pin_hash=hash_password(body.pin or "1234"),
            full_name=body.full_name or "Kabadiwala",
            language=body.language,
        )
        db.add(collector)
        created = True
    db.commit()
    db.refresh(collector)
    tokens = _tokens(collector.id, "collector")
    return {
        "ok": True,
        "created": created,
        "tokens": tokens.model_dump(),
        "collector": CollectorOut.model_validate(collector).model_dump(),
    }


@router.post("/recycler/register", response_model=dict, status_code=201)
def register_recycler(body: RecyclerRegisterIn, db: Session = Depends(get_db)):
    if db.query(Recycler).filter(Recycler.email == body.email).first():
        raise AppError(409, "EMAIL_TAKEN", "Email already registered.")
    if db.query(Recycler).filter(Recycler.recycler_code == body.recycler_code).first():
        raise AppError(409, "CODE_TAKEN", "Recycler code already registered.")
    rec = Recycler(
        recycler_code=body.recycler_code,
        company_name=body.company_name,
        authorization_no=body.authorization_no,
        email=body.email,
        phone=body.phone,
        password_hash=hash_password(body.password),
        address=body.address,
        city=body.city,
        state=body.state,
        pincode=body.pincode,
        latitude=body.latitude,
        longitude=body.longitude,
        pickup_available=body.pickup_available,
        accepted_categories=body.accepted_categories,
        verified=True,
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)
    tokens = _tokens(rec.id, "recycler")
    return {
        "ok": True,
        "tokens": tokens.model_dump(),
        "recycler": RecyclerOut.model_validate(rec).model_dump(),
    }


@router.post("/recycler/login", response_model=dict)
def login_recycler(body: RecyclerLoginIn, db: Session = Depends(get_db)):
    rec = db.query(Recycler).filter(Recycler.email == body.email).first()
    if not rec or not verify_password(body.password, rec.password_hash):
        raise AppError(401, "BAD_CREDENTIALS", "Email or password is incorrect.")
    tokens = _tokens(rec.id, "recycler")
    return {"ok": True, "tokens": tokens.model_dump(), "recycler": RecyclerOut.model_validate(rec).model_dump()}


@router.get("/me")
def me(pair=Depends(get_any_user)):
    role, user = pair
    if role == "collector":
        return {"ok": True, "role": role, "user": CollectorOut.model_validate(user).model_dump()}
    return {"ok": True, "role": role, "user": RecyclerOut.model_validate(user).model_dump()}
