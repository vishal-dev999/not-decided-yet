from fastapi import APIRouter

from app.api.v1.endpoints import (
    audio,
    auth,
    collectors,
    compliance,
    fraud,
    lots,
    prices,
    recyclers,
    safety,
    ws,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(collectors.router)
api_router.include_router(recyclers.router)
api_router.include_router(lots.router)
api_router.include_router(prices.router)
api_router.include_router(audio.router)
api_router.include_router(compliance.router)
api_router.include_router(safety.router)
api_router.include_router(fraud.router)
api_router.include_router(ws.router)
