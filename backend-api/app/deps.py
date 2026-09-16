from typing import Optional

from fastapi import Depends, Header
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.exceptions import AppError
from app.core.security import decode_token
from app.database import get_db
from app.models.entities import Collector, Recycler
from app.utils.i18n import spoken

bearer = HTTPBearer(auto_error=False)


def _token_payload(creds: Optional[HTTPAuthorizationCredentials]) -> dict:
    if creds is None or not creds.credentials:
        raise AppError(
            401,
            "NOT_AUTHENTICATED",
            "Missing Bearer token. Send Authorization: Bearer <access_token>.",
            spoken=spoken(
                "Please sign in.",
                "कृपया साइन इन करें।",
                "कृपया साइन इन करा.",
            ),
        )
    try:
        payload = decode_token(creds.credentials)
    except Exception:
        raise AppError(401, "INVALID_TOKEN", "Access token is invalid or expired.")
    if payload.get("typ") != "access":
        raise AppError(401, "WRONG_TOKEN_TYPE", "Use an access token, not a refresh token.")
    return payload


def get_current_collector(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(bearer),
    db: Session = Depends(get_db),
) -> Collector:
    payload = _token_payload(creds)
    if payload.get("role") != "collector":
        raise AppError(403, "COLLECTOR_ONLY", "This endpoint is for collectors (kabadiwalas).")
    user = db.get(Collector, payload["sub"])
    if not user or not user.is_active:
        raise AppError(401, "COLLECTOR_NOT_FOUND", "Collector account not found or inactive.")
    return user


def get_current_recycler(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(bearer),
    db: Session = Depends(get_db),
) -> Recycler:
    payload = _token_payload(creds)
    if payload.get("role") != "recycler":
        raise AppError(403, "RECYCLER_ONLY", "This endpoint is for recyclers.")
    user = db.get(Recycler, payload["sub"])
    if not user or not user.is_active:
        raise AppError(401, "RECYCLER_NOT_FOUND", "Recycler account not found or inactive.")
    return user


def get_any_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(bearer),
    db: Session = Depends(get_db),
):
    payload = _token_payload(creds)
    role = payload.get("role")
    if role == "collector":
        user = db.get(Collector, payload["sub"])
    elif role == "recycler":
        user = db.get(Recycler, payload["sub"])
    else:
        raise AppError(401, "UNKNOWN_ROLE", "Unknown token role.")
    if not user:
        raise AppError(401, "USER_NOT_FOUND", "Account not found.")
    return role, user


def optional_lang(x_language: Optional[str] = Header(default="hi", alias="X-Language")) -> str:
    lang = (x_language or "hi").lower()
    if lang not in {"hi", "mr", "en"}:
        return "hi"
    return lang
