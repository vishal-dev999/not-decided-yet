"""End-to-end 10-step lot lifecycle against the FastAPI app."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def _auth(client, role: str):
    if role == "collector":
        r = client.post(
            "/api/v1/auth/collector/login",
            json={"phone": "9876543210", "pin": "1234"},
        )
    else:
        r = client.post(
            "/api/v1/auth/recycler/login",
            json={"email": "mahanadi@demo.kabadiwala", "password": "recycle123"},
        )
    assert r.status_code == 200, r.text
    token = r.json()["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_price_board_spoken(client):
    r = client.get("/api/v1/prices/board", params={"city": "Cuttack"})
    assert r.status_code == 200
    body = r.json()
    assert body["ok"]
    assert any(row["material_code"] == "pcb" for row in body["data"])
    pcb = next(row for row in body["data"] if row["material_code"] == "pcb")
    assert "hi" in pcb["spoken"]


def test_full_lot_lifecycle(client):
    ch = _auth(client, "collector")
    rh = _auth(client, "recycler")
    client_lot_id = str(uuid4())

    # Step 1 + 2 — sync + auto broadcast
    r = client.post(
        "/api/v1/lots/sync",
        headers=ch,
        json={
            "lots": [
                {
                    "client_lot_id": client_lot_id,
                    "material_category": "pcb",
                    "estimated_weight_kg": 12.0,
                    "classification": {
                        "label": "pcb",
                        "confidence": 0.91,
                        "model_version": "mobile-v1",
                    },
                    "latitude": 20.4625,
                    "longitude": 85.8828,
                    "city": "Cuttack",
                    "qr_token": "offline-qr-" + client_lot_id[:8],
                }
            ]
        },
    )
    assert r.status_code == 201, r.text
    lot = r.json()["data"][0]
    lot_id = lot["id"]
    assert lot["status"] in {"BROADCASTED", "SYNCED"}

    # Idempotent re-sync
    r2 = client.post(
        "/api/v1/lots/sync",
        headers=ch,
        json={
            "lots": [
                {
                    "client_lot_id": client_lot_id,
                    "material_category": "pcb",
                    "estimated_weight_kg": 12.0,
                }
            ]
        },
    )
    assert r2.status_code == 201
    assert r2.json()["data"][0]["id"] == lot_id

    matches = client.get(f"/api/v1/lots/{lot_id}/matches", headers=ch)
    assert matches.status_code == 200
    offers = matches.json()["data"]
    assert 1 <= len(offers) <= 3

    # Step 3+4 — claim
    claim = client.post(
        f"/api/v1/lots/{lot_id}/claim",
        headers=rh,
        json={"pickup_minutes_from_now": 45},
    )
    assert claim.status_code == 200, claim.text
    assert claim.json()["data"]["status"] == "LOCKED"

    # Second claim must fail
    other = client.post(
        "/api/v1/auth/recycler/login",
        json={"email": "kalinga@demo.kabadiwala", "password": "recycle123"},
    )
    other_h = {"Authorization": f"Bearer {other.json()['tokens']['access_token']}"}
    clash = client.post(
        f"/api/v1/lots/{lot_id}/claim",
        headers=other_h,
        json={"pickup_minutes_from_now": 45},
    )
    assert clash.status_code in {403, 409}

    # Step 5 — QR
    qr = client.post(
        f"/api/v1/lots/{lot_id}/qr/verify",
        headers=rh,
        json={"qr_token": "offline-qr-" + client_lot_id[:8]},
    )
    assert qr.status_code == 200, qr.text
    assert qr.json()["data"]["status"] == "SESSION_OPEN"

    # Step 6+7 — weighbridge (14 kg × 220 = 3080, as in the blueprint)
    wb = client.post(
        f"/api/v1/lots/{lot_id}/weighbridge",
        headers=rh,
        json={"certified_weight_kg": 14.0, "offered_rate_per_kg": 220.0},
    )
    assert wb.status_code == 200, wb.text
    prompt = wb.json()["consent_prompt"]
    assert prompt["total_amount"] == 3080.0
    assert "spoken" in prompt

    # Step 8+9+10 — consent with payment
    cons = client.post(
        f"/api/v1/lots/{lot_id}/consent",
        headers=ch,
        json={"accepted": True, "payment_mode": "CASH"},
    )
    assert cons.status_code == 200, cons.text
    assert cons.json()["data"]["status"] == "VERIFIED_COMPLETED"

    earn = client.get("/api/v1/collectors/me/earnings", headers=ch)
    assert earn.status_code == 200
    assert earn.json()["data"]["earnings_balance"] >= 3080

    rec = client.get(f"/api/v1/compliance/receipt/{lot_id}", headers=ch)
    assert rec.status_code == 200
    f6 = client.get(f"/api/v1/compliance/form6/{lot_id}", headers=rh)
    assert f6.status_code == 200
    assert f6.json()["data"]["form"]["form"] == "FORM-6"
