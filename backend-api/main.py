"""
FastAPI application — E-Waste Valuation & Recycler Matching API (Phase 1).

Run:
    uvicorn backend.main:app --reload

Endpoints (all under /v1):
    GET  /v1/health           -> service + artifact status
    POST /v1/valuation/estimate  -> price estimate (model, baseline fallback)
    POST /v1/recyclers/match     -> deterministic logistics ranking
    POST /v1/evaluate-lot        -> valuation + matching combined
    POST /v1/sync/lots           -> idempotent offline outbox batch ingest
                                    + latest rate cache refresh
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend import schemas
from backend.config import APP_NAME, API_PREFIX, API_VERSION, get_settings
from backend.services.matcher import RecyclerMatcher
from backend.services.sync_store import SyncStore
from backend.services.valuation import CLASS_BRIDGE, ValuationService

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-7s %(name)s | %(message)s",
)
logger = logging.getLogger("backend.main")

settings = get_settings()
valuation_service = ValuationService(settings)
recycler_matcher = RecyclerMatcher(settings)
sync_store = SyncStore(settings)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings.ensure_dirs()
    valuation_service.load()
    recycler_matcher.load()
    sync_store.initialize()
    logger.info(
        "startup ok | model=%s encoders=%s recyclers=%d sync_store=%s",
        valuation_service.status.model_loaded,
        valuation_service.status.encoders_loaded,
        recycler_matcher.status.recycler_count,
        "up" if sync_store.available else "degraded",
    )
    yield


app = FastAPI(
    title=APP_NAME,
    version=API_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Last-resort guard: field tools must never see an opaque 500 body."""
    logger.exception("unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "internal error", "hint": "service degraded to safe defaults"},
    )


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
@app.get(f"{API_PREFIX}/health", response_model=schemas.HealthResponse, tags=["health"])
def health() -> schemas.HealthResponse:
    valuation_service.ensure_loaded()
    recycler_matcher.ensure_loaded()
    return schemas.HealthResponse(
        status="ok",
        app_name=APP_NAME,
        api_version=API_VERSION,
        server_time=datetime.now(timezone.utc),
        default_city=settings.default_city,
        artifacts={
            "valuation_model_loaded": valuation_service.status.model_loaded,
            "valuation_model_n_features": valuation_service.status.model_n_features,
            "encoders_loaded": valuation_service.status.encoders_loaded,
            "known_cities": valuation_service.status.known_cities,
            "recyclers_loaded": recycler_matcher.status.recycler_count,
            "recyclers_skipped_rows": recycler_matcher.status.skipped_rows,
            "artifact_detail": (valuation_service.status.detail
                                + recycler_matcher.status.detail).strip() or "ok",
        },
        synced_lots_on_server=sync_store.count(),
    )


# ---------------------------------------------------------------------------
# Valuation
# ---------------------------------------------------------------------------
@app.post(
    f"{API_PREFIX}/valuation/estimate",
    response_model=schemas.ValuationResponse,
    tags=["valuation"],
)
def estimate_valuation(req: schemas.ValuationRequest) -> schemas.ValuationResponse:
    result = valuation_service.estimate(
        tflite_class=req.tflite_class,
        material_category=req.material_category,
        sub_category=req.sub_category,
        weight_kg=req.weight_kg,
        location_cluster=req.location_cluster,
    )
    return schemas.ValuationResponse(**result)


# ---------------------------------------------------------------------------
# Recycler matching
# ---------------------------------------------------------------------------
@app.post(
    f"{API_PREFIX}/recyclers/match",
    response_model=schemas.RecyclerMatchResponse,
    tags=["logistics"],
)
def match_recyclers(req: schemas.RecyclerMatchRequest) -> schemas.RecyclerMatchResponse:
    result = recycler_matcher.match(
        material_category=req.material_category,
        latitude=req.latitude,
        longitude=req.longitude,
        limit=req.limit,
    )
    return schemas.RecyclerMatchResponse(**result)


# ---------------------------------------------------------------------------
# Combined lot evaluation
# ---------------------------------------------------------------------------
@app.post(
    f"{API_PREFIX}/evaluate-lot",
    response_model=schemas.LotEvaluationResponse,
    tags=["valuation", "logistics"],
)
def evaluate_lot(req: schemas.LotEvaluationRequest) -> schemas.LotEvaluationResponse:
    valuation = valuation_service.estimate(
        tflite_class=req.tflite_class,
        material_category=req.material_category,
        sub_category=req.sub_category,
        weight_kg=req.weight_kg,
        location_cluster=req.location_cluster,
    )

    logistics: schemas.RecyclerMatchResponse | None = None
    logistics_note: str | None = None
    if req.pickup_latitude is not None and req.pickup_longitude is not None:
        category = valuation.get("material_category")
        if category:
            logistics = schemas.RecyclerMatchResponse(**recycler_matcher.match(
                material_category=category,
                latitude=req.pickup_latitude,
                longitude=req.pickup_longitude,
                limit=req.match_limit,
            ))
            if logistics.radius_relaxed:
                logistics_note = logistics.note
        else:
            logistics_note = "unresolvable material category — logistics matching skipped"
    else:
        logistics_note = "no pickup coordinates supplied — logistics matching skipped"

    return schemas.LotEvaluationResponse(
        valuation=schemas.ValuationResponse(**valuation),
        logistics=logistics,
        logistics_note=logistics_note,
    )


# ---------------------------------------------------------------------------
# Batch sync (idempotent) + rate cache refresh
# ---------------------------------------------------------------------------
def _build_rate_cache() -> tuple[list[schemas.RateCacheEntry], str]:
    """Latest rate cache payload for device cache refresh.

    Phase 1 source of truth: the locked class-bridge baselines. When a live
    market feed lands, replace `source`/`inr_per_kg` here — the payload shape
    stays stable for the Flutter cache.
    """
    entries = [
        schemas.RateCacheEntry(
            tflite_class=cls,
            material_category=cat,
            sub_category=sub,
            inr_per_kg=baseline,
        )
        for cls, (cat, sub, baseline) in CLASS_BRIDGE.items()
    ]
    stamp = datetime.now(timezone.utc)
    version = f"RATES-{stamp.strftime('%Y%m%d%H%M%S')}"
    return entries, version


@app.post(
    f"{API_PREFIX}/sync/lots",
    response_model=schemas.BatchSyncResponse,
    tags=["sync"],
)
def sync_lots(manifest: schemas.BatchSyncManifest) -> schemas.BatchSyncResponse:
    received = len(manifest.pending_lots)
    if received > settings.sync_batch_limit:
        return JSONResponse(
            status_code=413,
            content={"detail": f"batch exceeds sync_batch_limit ({settings.sync_batch_limit})"},
        )

    lot_statuses: list[schemas.LotSyncStatus] = []
    synced_uuids: list[str] = []
    duplicate_uuids: list[str] = []

    batch = [
        (lot.lot_uuid, manifest.device_id, lot.model_dump(mode="json"))
        for lot in manifest.pending_lots
    ]
    results = sync_store.sync_batch(batch)

    for lot_uuid, outcome, reason in results:
        lot_statuses.append(schemas.LotSyncStatus(
            lot_uuid=lot_uuid, status=outcome, reason=reason,
        ))
        if outcome == "SYNCED":
            synced_uuids.append(lot_uuid)
        elif outcome == "DUPLICATE":
            duplicate_uuids.append(lot_uuid)
    total_on_server = sync_store.count()

    rate_cache, rate_version = _build_rate_cache()
    return schemas.BatchSyncResponse(
        device_id=manifest.device_id,
        server_time=datetime.now(timezone.utc),
        received_count=received,
        synced_lot_uuids=synced_uuids,
        duplicate_lot_uuids=duplicate_uuids,
        lot_statuses=lot_statuses,
        total_synced_lots_on_server=total_on_server,
        rate_cache=rate_cache,
        rate_cache_version=rate_version,
        store_available=sync_store.available,
    )
