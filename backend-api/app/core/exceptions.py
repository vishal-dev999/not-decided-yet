from typing import Any, Optional

from fastapi import HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


class AppError(HTTPException):
    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: Optional[dict[str, Any]] = None,
        spoken: Optional[dict[str, str]] = None,
    ):
        self.code = code
        self.spoken = spoken or {}
        super().__init__(
            status_code=status_code,
            detail={
                "error": True,
                "code": code,
                "message": message,
                "message_spoken": self.spoken,
                "details": details or {},
            },
        )


def error_body(
    code: str,
    message: str,
    details: Optional[dict[str, Any]] = None,
    spoken: Optional[dict[str, str]] = None,
) -> dict[str, Any]:
    return {
        "error": True,
        "code": code,
        "message": message,
        "message_spoken": spoken or {},
        "details": details or {},
    }


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:  # noqa: ARG001
    if isinstance(exc.detail, dict) and exc.detail.get("error") is True:
        return JSONResponse(status_code=exc.status_code, content=exc.detail)
    return JSONResponse(
        status_code=exc.status_code,
        content=error_body("HTTP_ERROR", str(exc.detail)),
    )


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:  # noqa: ARG001
    return JSONResponse(
        status_code=422,
        content=error_body(
            "VALIDATION_ERROR",
            "Request validation failed. Check required fields and types.",
            details={"errors": exc.errors()},
            spoken={
                "en": "Some information is missing or incorrect.",
                "hi": "कुछ जानकारी गलत या अधूरी है।",
                "mr": "काही माहिती चुकीची किंवा अपूर्ण आहे.",
            },
        ),
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:  # noqa: ARG001
    return JSONResponse(
        status_code=500,
        content=error_body(
            "INTERNAL_ERROR",
            "An unexpected error occurred.",
            details={"type": type(exc).__name__},
        ),
    )
