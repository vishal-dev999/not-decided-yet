"""
Sync gateway persistence — dev SQLite idempotency store.

The Flutter outbox (`pending_lots`) carries client-generated `lot_uuid`s.
This store guarantees batch-retry idempotency: a `lot_uuid` is recorded
exactly once; replays come back as DUPLICATE so clients can safely clear
their outbox. Uses the stdlib `sqlite3` driver against the path configured
by `EWASTE_DEV_SQLITE_DB_PATH`.
"""

from __future__ import annotations

import json
import logging
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

from backend.config import Settings, get_settings

logger = logging.getLogger("backend.sync")

_SCHEMA = """
CREATE TABLE IF NOT EXISTS synced_lots (
    lot_uuid    TEXT PRIMARY KEY,
    device_id   TEXT,
    synced_at   TEXT NOT NULL,
    payload_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_synced_lots_device ON synced_lots (device_id);
"""


class SyncStore:
    """Thread-safe, per-call-connection SQLite store. Fails soft."""

    def __init__(self, settings: Optional[Settings] = None) -> None:
        self.settings = settings or get_settings()
        self._lock = threading.Lock()
        self._initialized = False
        self.last_error: Optional[str] = None

    # ------------------------------------------------------------------ #
    def _connect(self) -> sqlite3.Connection:
        db_path: Path = self.settings.dev_sqlite_db_path
        db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(db_path), timeout=10.0)
        conn.execute("PRAGMA journal_mode=WAL;")
        return conn

    def initialize(self) -> bool:
        """Create schema. Returns False (and records the error) if unavailable."""
        try:
            with self._lock, self._connect() as conn:
                conn.executescript(_SCHEMA)
            self._initialized = True
            self.last_error = None
        except sqlite3.Error as exc:
            self._initialized = False
            self.last_error = str(exc)
            logger.warning("sync store unavailable: %s", exc)
        return self._initialized

    # ------------------------------------------------------------------ #
    @property
    def available(self) -> bool:
        if not self._initialized:
            self.initialize()
        return self._initialized

    def already_synced(self, conn: sqlite3.Connection, lot_uuid: str) -> bool:
        row = conn.execute(
            "SELECT 1 FROM synced_lots WHERE lot_uuid = ?", (lot_uuid,)
        ).fetchone()
        return row is not None

    def record_lot(
        self,
        conn: sqlite3.Connection,
        lot_uuid: str,
        device_id: Optional[str],
        payload: dict[str, Any],
    ) -> str:
        """Insert one lot. Returns 'SYNCED' or 'DUPLICATE'."""
        if self.already_synced(conn, lot_uuid):
            return "DUPLICATE"
        conn.execute(
            "INSERT INTO synced_lots (lot_uuid, device_id, synced_at, payload_json) "
            "VALUES (?, ?, ?, ?)",
            (
                lot_uuid,
                device_id,
                datetime.now(timezone.utc).isoformat(),
                json.dumps(payload, default=str),
            ),
        )
        return "SYNCED"

    def count(self) -> int:
        if not self.available:
            return 0
        try:
            with self._connect() as conn:
                return int(conn.execute("SELECT COUNT(*) FROM synced_lots").fetchone()[0])
        except sqlite3.Error:
            return 0

    def sync_batch(
        self,
        lots: list[tuple[str, Optional[str], dict[str, Any]]],
    ) -> list[tuple[str, str, Optional[str]]]:
        """
        Record a batch atomically-enough for dev: one transaction, per-lot
        isolation. Input: [(lot_uuid, device_id, payload_dict), ...].
        Returns [(lot_uuid, 'SYNCED'|'DUPLICATE'|'REJECTED', reason|None), ...].
        """
        results: list[tuple[str, str, Optional[str]]] = []
        if not self.available:
            return [(uuid, "REJECTED", f"sync store unavailable: {self.last_error}")
                    for uuid, _, _ in lots]
        with self._lock, self._connect() as conn:
            for lot_uuid, device_id, payload in lots:
                try:
                    outcome = self.record_lot(conn, lot_uuid, device_id, payload)
                    results.append((lot_uuid, outcome, None))
                except Exception as exc:  # noqa: BLE001 — per-lot isolation
                    logger.warning("lot %s failed to persist: %s", lot_uuid, exc)
                    results.append((lot_uuid, "REJECTED", str(exc)))
        return results
