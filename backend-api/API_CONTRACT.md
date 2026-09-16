# Kabadiwala API Contract (frontend integration)

Base URL (local): `http://localhost:8000`  
API prefix: `/api/v1`  
Swagger: `http://localhost:8000/docs`  
ReDoc: `http://localhost:8000/redoc`

Every JSON response is either:

```json
{ "ok": true, "data": { }, "message": "...", "message_spoken": { "en": "", "hi": "", "mr": "" } }
```

or an error:

```json
{
  "error": true,
  "code": "LOT_ALREADY_LOCKED",
  "message": "human readable",
  "message_spoken": { "en": "...", "hi": "...", "mr": "..." },
  "details": {}
}
```

`message_spoken` is meant to be fed **directly** into on-device TTS (Hindi / Marathi / English). Do not rephrase.

---

## Headers

| Header | Required | Value |
| --- | --- | --- |
| `Authorization` | Yes, except `/auth/*`, `/health`, `/`, `/prices/*` public GETs, `/safety/cards` | `Bearer <access_token>` |
| `Content-Type` | Yes on POST/PUT with JSON | `application/json` |
| `X-Language` | Optional | `hi` (default), `mr`, or `en` |

WebSocket auth is a **query param**, not a header:  
`ws://localhost:8000/api/v1/ws/collector?token=<access_token>`

---

## Auth

Demo collector: phone `9876543210` PIN `1234` (Ramesh Sahu, Cuttack, Hindi)  
Demo collector: phone `9123456780` PIN `1234` (Savitri Patil, Mumbai, Marathi)  
Demo recycler: `mahanadi@demo.kabadiwala` / `recycle123` (Cuttack)  
All seeded recyclers share password `recycle123`. Prototype OTP is always `123456`.

### Collector register — `POST /api/v1/auth/collector/register`

```json
{
  "phone": "9000000001",
  "pin": "4321",
  "full_name": "Hari Behera",
  "language": "hi",
  "city": "Cuttack",
  "state": "Odisha",
  "pincode": "753001",
  "latitude": 20.4625,
  "longitude": 85.8828,
  "upi_id": "hari@upi",
  "aadhaar_last4": "9988"
}
```

**201**

```json
{
  "ok": true,
  "tokens": {
    "access_token": "<jwt>",
    "refresh_token": "<jwt>",
    "token_type": "bearer",
    "role": "collector",
    "user_id": "<uuid>",
    "expires_in_minutes": 10080
  },
  "collector": { "id": "...", "phone": "9000000001", "full_name": "Hari Behera", "language": "hi" }
}
```

### Collector login — `POST /api/v1/auth/collector/login`

```json
{ "phone": "9876543210", "pin": "1234" }
```

**200** — same token envelope as register. **401** `BAD_CREDENTIALS`.

### OTP (prototype) — `POST /api/v1/auth/collector/otp/request` then `/otp/verify`

Request: `{ "phone": "9876543210" }` → `{ "demo_otp": "123456" }`  
Verify: `{ "phone": "9876543210", "code": "123456", "full_name": "Ramesh", "language": "hi", "pin": "1234" }`

### Recycler login — `POST /api/v1/auth/recycler/login`

```json
{ "email": "mahanadi@demo.kabadiwala", "password": "recycle123" }
```

### Who am I — `GET /api/v1/auth/me`  
Header: Bearer token. Returns `{ ok, role, user }`.

---

## API specification table

| Feature | Method | Endpoint | Request body | Response (happy path) | Status |
| --- | --- | --- | --- | --- | --- |
| Health | GET | `/health` | — | `{ok, service, env}` | 200 |
| Collector register | POST | `/api/v1/auth/collector/register` | phone, pin, full_name, language?, city?… | tokens + collector | 201 / 409 |
| Collector login | POST | `/api/v1/auth/collector/login` | `{phone, pin}` | tokens + collector | 200 / 401 |
| OTP request | POST | `/api/v1/auth/collector/otp/request` | `{phone}` | `{demo_otp}` | 200 |
| OTP verify | POST | `/api/v1/auth/collector/otp/verify` | `{phone, code, …}` | tokens + collector | 200 / 400 |
| Recycler register | POST | `/api/v1/auth/recycler/register` | company + CPCB fields + password | tokens + recycler | 201 / 409 |
| Recycler login | POST | `/api/v1/auth/recycler/login` | `{email, password}` | tokens + recycler | 200 / 401 |
| Current user | GET | `/api/v1/auth/me` | — | `{role, user}` | 200 / 401 |
| Collector profile | GET | `/api/v1/collectors/me` | — | collector | 200 |
| Update profile | PUT | `/api/v1/collectors/me` | optional fields | collector | 200 |
| Earnings | GET | `/api/v1/collectors/me/earnings` | — | balance, dues, spoken | 200 |
| Earnings ledger | GET | `/api/v1/collectors/me/ledger?limit=50` | — | list of CREDIT/DEBIT | 200 |
| Collector lots | GET | `/api/v1/collectors/me/lots?status=` | — | lots[] | 200 |
| Recycler profile | GET/PUT | `/api/v1/recyclers/me` | pickup_available? | recycler | 200 |
| Live opportunities | GET | `/api/v1/recyclers/me/opportunities` | — | `{offer, lot}[]` | 200 |
| Claimed lots | GET | `/api/v1/recyclers/me/lots` | — | lots[] | 200 |
| Recycler registry | GET | `/api/v1/recyclers?city=Cuttack` | — | public recycler[] | 200 |
| **Step 1 Sync ingestion** | POST | `/api/v1/lots/sync` | `{lots:[LotSyncItem]}` | lots[] (idempotent) | 201 |
| Get lot | GET | `/api/v1/lots/{lot_id}` | — | lot | 200 / 403 / 404 |
| Lot status | GET | `/api/v1/lots/{lot_id}/status` | — | status + recycler + txn | 200 |
| Top-3 matches | GET | `/api/v1/lots/{lot_id}/matches` | — | ranked offers | 200 |
| Re-broadcast | POST | `/api/v1/lots/{lot_id}/broadcast` | — | lot | 200 / 409 |
| **Step 3 Claim & lock** | POST | `/api/v1/lots/{lot_id}/claim` | `{pickup_minutes_from_now}` | lot status=LOCKED | 200 / 403 / 409 |
| **Step 5 QR handshake** | POST | `/api/v1/lots/{lot_id}/qr/verify` | `{qr_token}` | lot status=SESSION_OPEN | 200 / 400 |
| **Step 6–7 Weighbridge + consent prompt** | POST | `/api/v1/lots/{lot_id}/weighbridge` | `{certified_weight_kg, offered_rate_per_kg}` | `{lot, consent_prompt}` | 200 |
| **Step 8 Collector consent** | POST | `/api/v1/lots/{lot_id}/consent` | `{accepted, payment_mode?, upi_reference?}` | lot | 200 / 409 |
| **Step 9–10 Complete + seal** | POST | `/api/v1/lots/{lot_id}/complete` | `{payment_mode, upi_reference?}` | lot VERIFIED_COMPLETED | 200 / 409 |
| Cancel lot | POST | `/api/v1/lots/{lot_id}/cancel` | — | lot CANCELLED | 200 |
| Materials catalog | GET | `/api/v1/prices/materials` | — | materials[] | 200 |
| Price board + TTS | GET | `/api/v1/prices/board?city=Cuttack` | — | rates + spoken[] | 200 |
| Price trends | GET | `/api/v1/prices/trends?material=pcb&city=Cuttack&days=30` | — | points, sma, slope | 200 |
| Price estimate | POST | `/api/v1/prices/estimate` | `{material_category, weight_kg, city}` | total + spoken | 200 |
| TTS prompt factory | POST | `/api/v1/audio/prompt` | `{template, lang, …}` | `{text, all}` | 200 |
| Spoken price board | GET | `/api/v1/audio/price-board?city=&lang=` | — | one paragraph | 200 |
| Form-6 JSON | GET | `/api/v1/compliance/form6/{lot_id}` | — | manifest + hash | 200 |
| Form-6 CSV | GET | `/api/v1/compliance/form6/{lot_id}/csv` | — | `text/csv` file | 200 |
| Receipt | GET | `/api/v1/compliance/receipt/{lot_id}` | — | receipt + spoken | 200 |
| Traceability list | GET | `/api/v1/compliance/traceability` | recycler JWT | rows[] | 200 |
| Traceability CSV export | GET | `/api/v1/compliance/traceability/export` | recycler JWT | `text/csv` | 200 |
| Safety cards | GET | `/api/v1/safety/cards?lang=hi` | — | pictorial cards | 200 |
| Fraud check | GET | `/api/v1/lots/{lot_id}/fraud-check` | — | score + flags | 200 |
| Fraud alerts | GET | `/api/v1/admin/fraud-alerts` | recycler JWT | alerts[] | 200 |
| Collector WS | WS | `/api/v1/ws/collector?token=` | — | events (see below) | 101 |
| Recycler WS | WS | `/api/v1/ws/recycler?token=` | — | events (see below) | 101 |

---

## Lot sync payload (mobile offline engine)

`POST /api/v1/lots/sync` — **collector JWT**. Send 1–50 queued lots.  
Idempotent on `(collector_id, client_lot_id)`. Safe to retry.

```json
{
  "lots": [
    {
      "client_lot_id": "8f2c0b1a-6d44-4c0e-9a11-0c0c0c0c0c0c",
      "material_category": "pcb",
      "estimated_weight_kg": 12.5,
      "classification": {
        "label": "pcb",
        "confidence": 0.92,
        "model_version": "mobile-v1"
      },
      "latitude": 20.4625,
      "longitude": 85.8828,
      "city": "Cuttack",
      "notes": null,
      "qr_token": "offline-hmac-or-uuid",
      "photo_base64": null,
      "created_at_local": "2026-09-13T10:15:00+05:30"
    }
  ]
}
```

**Required:** `client_lot_id`, `material_category`, `estimated_weight_kg`  
**Optional:** classification, GPS, city, notes, qr_token, photo_base64, created_at_local  

If `qr_token` is omitted the server generates one. **The collector app should generate the QR offline** (blueprint: Lot QR Handshake is a mobile-owned feature) and send the same token here so the recycler scan matches later.

**Material codes (use these exact strings):**  
`pcb` · `copper_wires` · `aluminum` · `hard_plastics` · `batteries` · `cables` · `mixed_ewaste` · `steel` · `glass` · `motors`

---

## Lot status machine (do not skip steps)

```
SYNCED → BROADCASTED → LOCKED → SESSION_OPEN → WEIGHED → CONSENTED → VERIFIED_COMPLETED
                                    ↘ CANCELLED / EXPIRED at most open states
```

| Status | Who acts next | Frontend screen |
| --- | --- | --- |
| `SYNCED` | backend auto-broadcast | “Sending to recyclers…” |
| `BROADCASTED` | recycler Accept | collector waits; recycler dashboard shows opportunity |
| `LOCKED` | physical meetup | collector sees recycler card + pickup time; show QR |
| `SESSION_OPEN` | recycler weighbridge | recycler-web weight + rate form |
| `WEIGHED` | collector consent | big green tick / red cross + spoken amount |
| `CONSENTED` | either party complete | cash/UPI confirmation |
| `VERIFIED_COMPLETED` | — | receipt + earnings update |
| `CANCELLED` | — | cancelled state |

Shortcut: send `payment_mode` (`CASH` or `UPI`) inside the consent call to jump `WEIGHED → VERIFIED_COMPLETED` in one request.

---

## Weighbridge + dual consent (blueprint example)

Recycler submits:

```http
POST /api/v1/lots/{lot_id}/weighbridge
Authorization: Bearer <recycler>
Content-Type: application/json

{ "certified_weight_kg": 14, "offered_rate_per_kg": 220 }
```

Response excerpt:

```json
{
  "ok": true,
  "consent_prompt": {
    "certified_weight_kg": 14.0,
    "offered_rate_per_kg": 220.0,
    "total_amount": 3080.0,
    "fraud_score": 0,
    "fraud_flags": [],
    "spoken": {
      "en": "Mahanadi E-Waste Recyclers entered fourteen kilograms for three thousand eighty rupees. Do you agree?",
      "hi": "Mahanadi E-Waste Recyclers ने चौदह किलो के लिए तीन हज़ार अस्सी रुपये दर्ज किए हैं। क्या आप सहमत हैं?",
      "mr": "..."
    }
  }
}
```

Collector app **must**:

1. Play `spoken[user.language]` via TTS.
2. Show weight, rate, total as large numerals + pictograms.
3. POST `/consent` with `{ "accepted": true, "payment_mode": "CASH" }` on green tick.

---

## WebSocket events

Connect after login. Reconnect with backoff. REST remains the source of truth — WS is a push accelerator.

**Collector events**

| event | when |
| --- | --- |
| `connected` | handshake |
| `lot.broadcasted` | top-3 notified |
| `match.confirmed` | recycler locked the lot (includes recycler card + pickup) |
| `session.opened` | QR scanned |
| `consent.requested` | weighbridge submitted (play `data.spoken`) |
| `lot.completed` | earnings credited (`data.spoken`) |
| `lot.cancelled` | cancelled |

**Recycler events**

| event | when |
| --- | --- |
| `connected` | handshake |
| `lot.opportunity` | you are in the top 3 — show Accept |
| `lot.locked` | you won the claim |
| `lot.withdrawn` | someone else claimed — remove from dashboard |
| `consent.accepted` / `consent.rejected` | collector decision |
| `lot.completed` | sealed |

Envelope:

```json
{ "event": "lot.opportunity", "ts": "2026-09-13T08:00:00+00:00", "data": { } }
```

---

## Error codes the UI should handle

| code | HTTP | UI |
| --- | --- | --- |
| `NOT_AUTHENTICATED` / `INVALID_TOKEN` | 401 | send to login |
| `BAD_CREDENTIALS` | 401 | shake PIN pad, speak error |
| `COLLECTOR_ONLY` / `RECYCLER_ONLY` | 403 | wrong app |
| `LOT_NOT_FOUND` | 404 | stale local row |
| `INVALID_LOT_STATE` | 409 | refresh `/lots/{id}/status` |
| `NOT_IN_TOP_MATCHES` | 403 | lot not on this recycler’s board |
| `QR_MISMATCH` | 400 | rescan |
| `CONSENT_REQUIRED` | 409 | wait for collector tick |
| `VALIDATION_ERROR` | 422 | missing/invalid fields (`details.errors`) |

---

## curl cheatsheet

```bash
# login
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/collector/login \
  -H 'Content-Type: application/json' \
  -d '{"phone":"9876543210","pin":"1234"}' | python -c "import sys,json;print(json.load(sys.stdin)['tokens']['access_token'])")

curl -s http://localhost:8000/api/v1/prices/board?city=Cuttack \
  -H "Authorization: Bearer $TOKEN"
```

Full 10-step script: `examples/curl_walkthrough.sh`.
