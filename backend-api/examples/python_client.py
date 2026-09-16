"""Minimal Python integration example for the collector mobile team."""

from uuid import uuid4

import httpx

BASE = "http://localhost:8000/api/v1"


def main() -> None:
    with httpx.Client(timeout=20) as c:
        login = c.post(f"{BASE}/auth/collector/login", json={"phone": "9876543210", "pin": "1234"})
        login.raise_for_status()
        token = login.json()["tokens"]["access_token"]
        h = {"Authorization": f"Bearer {token}"}

        board = c.get(f"{BASE}/prices/board", params={"city": "Cuttack"}, headers=h)
        print("PCB spoken (hi):", next(r["spoken"]["hi"] for r in board.json()["data"] if r["material_code"] == "pcb"))

        client_lot_id = str(uuid4())
        synced = c.post(
            f"{BASE}/lots/sync",
            headers=h,
            json={
                "lots": [
                    {
                        "client_lot_id": client_lot_id,
                        "material_category": "pcb",
                        "estimated_weight_kg": 12,
                        "classification": {"label": "pcb", "confidence": 0.9, "model_version": "mobile-v1"},
                        "latitude": 20.4625,
                        "longitude": 85.8828,
                        "city": "Cuttack",
                        "qr_token": f"qr-{client_lot_id}",
                    }
                ]
            },
        )
        synced.raise_for_status()
        lot = synced.json()["data"][0]
        print("synced lot", lot["id"], lot["status"])

        status = c.get(f"{BASE}/lots/{lot['id']}/status", headers=h)
        print("status", status.json()["data"]["status"])


if __name__ == "__main__":
    main()
