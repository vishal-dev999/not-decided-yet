from __future__ import annotations

import asyncio
import json
from collections import defaultdict
from datetime import datetime, timezone
from typing import Any, DefaultDict, Optional, Set

from fastapi import WebSocket


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class ConnectionManager:
    """In-memory WebSocket fan-out.

    Rooms:
      collector:{id}
      recycler:{id}
      lot:{id}
    """

    def __init__(self) -> None:
        self.rooms: DefaultDict[str, Set[WebSocket]] = defaultdict(set)
        self.loop: Optional[asyncio.AbstractEventLoop] = None

    def bind_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        self.loop = loop

    async def connect(self, room: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self.rooms[room].add(websocket)

    def disconnect(self, room: str, websocket: WebSocket) -> None:
        self.rooms[room].discard(websocket)
        if not self.rooms[room]:
            self.rooms.pop(room, None)

    async def send_personal(self, websocket: WebSocket, event: str, data: Any) -> None:
        payload = {"event": event, "ts": _now(), "data": data}
        await websocket.send_text(json.dumps(payload, default=str))

    async def broadcast(self, room: str, event: str, data: Any) -> None:
        payload = json.dumps({"event": event, "ts": _now(), "data": data}, default=str)
        dead: list[WebSocket] = []
        for ws in list(self.rooms.get(room, set())):
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(room, ws)

    def broadcast_threadsafe(self, room: str, event: str, data: Any) -> None:
        """Safe to call from sync SQLAlchemy services / threadpool."""
        loop = self.loop
        if loop is None or not loop.is_running():
            try:
                loop = asyncio.get_running_loop()
            except RuntimeError:
                return
        asyncio.run_coroutine_threadsafe(self.broadcast(room, event, data), loop)

    async def notify_collector(self, collector_id: str, event: str, data: Any) -> None:
        await self.broadcast(f"collector:{collector_id}", event, data)

    async def notify_recycler(self, recycler_id: str, event: str, data: Any) -> None:
        await self.broadcast(f"recycler:{recycler_id}", event, data)


manager = ConnectionManager()
