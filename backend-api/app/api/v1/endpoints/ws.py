from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from app.core.security import decode_token
from app.core.ws_manager import manager

router = APIRouter(tags=["WebSocket"])


async def _auth_ws(websocket: WebSocket, token: str, expected_role: str):
    try:
        payload = decode_token(token)
    except Exception:
        await websocket.close(code=4401)
        return None
    if payload.get("typ") != "access" or payload.get("role") != expected_role:
        await websocket.close(code=4403)
        return None
    return payload


@router.websocket("/ws/collector")
async def ws_collector(websocket: WebSocket, token: str = Query(...)):
    payload = await _auth_ws(websocket, token, "collector")
    if not payload:
        return
    room = f"collector:{payload['sub']}"
    await manager.connect(room, websocket)
    await manager.send_personal(websocket, "connected", {"room": room, "role": "collector"})
    try:
        while True:
            msg = await websocket.receive_text()
            await manager.send_personal(websocket, "pong", {"echo": msg[:200]})
    except WebSocketDisconnect:
        manager.disconnect(room, websocket)


@router.websocket("/ws/recycler")
async def ws_recycler(websocket: WebSocket, token: str = Query(...)):
    payload = await _auth_ws(websocket, token, "recycler")
    if not payload:
        return
    room = f"recycler:{payload['sub']}"
    await manager.connect(room, websocket)
    await manager.send_personal(websocket, "connected", {"room": room, "role": "recycler"})
    try:
        while True:
            msg = await websocket.receive_text()
            await manager.send_personal(websocket, "pong", {"echo": msg[:200]})
    except WebSocketDisconnect:
        manager.disconnect(room, websocket)
