import asyncio
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.v1.router import api_router
from app.config import settings
from app.core.exceptions import (
    http_exception_handler,
    unhandled_exception_handler,
    validation_exception_handler,
)
from app.core.ws_manager import manager
from app.database import Base, engine, SessionLocal
from app.utils.seed import seed_if_empty

OPENAPI_TAGS = [
    {"name": "Auth", "description": "Collector PIN/OTP and recycler email login. JWT Bearer."},
    {"name": "Collectors", "description": "Kabadiwala profile, earnings ledger, own lots."},
    {"name": "Recyclers", "description": "CPCB recycler registry, opportunities, claimed lots."},
    {"name": "Lots", "description": "10-step lot lifecycle from offline sync to VERIFIED_COMPLETED."},
    {"name": "Prices", "description": "Price board, estimate, historical trends (statistical engine)."},
    {"name": "Audio-first", "description": "Ready-to-speak Hindi/Marathi/English prompts for mobile TTS."},
    {"name": "Compliance & Ledger", "description": "Form-6 manifests, receipts, CPCB traceability CSV."},
    {"name": "Safety cards", "description": "Pictorial / audio e-waste handling cards."},
    {"name": "Fraud", "description": "Weighbridge anomaly flags."},
    {"name": "WebSocket", "description": "Live broadcast, lock, consent, completion events."},
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path("data").mkdir(parents=True, exist_ok=True)
    Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
    Path(settings.export_dir).mkdir(parents=True, exist_ok=True)
    Base.metadata.create_all(bind=engine)
    if settings.seed_on_startup:
        db = SessionLocal()
        try:
            seed_if_empty(db)
        finally:
            db.close()
    manager.bind_loop(asyncio.get_running_loop())
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description=(
        "Backend for the **Kabadiwala** prototype — connecting informal e-waste collectors "
        "with CPCB-authorized recyclers.\n\n"
        "Follows the 10-step working process (blueprint page 5) and the five backend tasks "
        "(blueprint page 9).\n\n"
        "**Auth header for every protected route:** `Authorization: Bearer <access_token>`\n\n"
        "**Optional:** `X-Language: hi|mr|en` for spoken prompts.\n\n"
        "Interactive docs: `/docs` (Swagger) and `/redoc`."
    ),
    openapi_tags=OPENAPI_TAGS,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

origins = settings.cors_origin_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if origins == ["*"] else origins,
    allow_credentials=False if origins == ["*"] else True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

app.include_router(api_router, prefix=settings.api_prefix)

Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
app.mount("/storage", StaticFiles(directory="storage"), name="storage")


@app.get("/health", tags=["Auth"])
def health():
    return {"ok": True, "service": settings.app_name, "env": settings.app_env}


@app.get("/", tags=["Auth"])
def root():
    return {
        "ok": True,
        "service": settings.app_name,
        "docs": "/docs",
        "redoc": "/redoc",
        "api": settings.api_prefix,
        "health": "/health",
        "websocket_collector": f"{settings.api_prefix}/ws/collector?token=<JWT>",
        "websocket_recycler": f"{settings.api_prefix}/ws/recycler?token=<JWT>",
        "demo_collector": {"phone": "9876543210", "pin": "1234"},
        "demo_recycler": {"email": "mahanadi@demo.kabadiwala", "password": "recycle123"},
    }
