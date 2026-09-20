# Kabadiwala Backend API

FastAPI backend for the **Kabadiwala** prototype: informal e-waste collectors (mobile app) ↔ CPCB-authorized recyclers (web) with an offline-first lot lifecycle, statistical recycler matching, dual-consent settlement, earnings ledger, and Form-6 traceability.

> Based on the problem statement in the PDF, I have planned the following backend features for the prototype...

This service is the **backend-api/** box in the technical blueprint (page 2) and implements the 10-step working process (page 5) plus the five explicit backend tasks (page 9).

---

## Planned backend features

### Required features (directly from the PDF)

From **page 9 (BACKEND tasks)** and **page 5 (working process)**:

1. **Datasets throughout the bridging process**
   - Kabadiwala (collector) profiles
   - Transaction ledger / earnings & dues
   - CPCB traceability CSV (sealed, hash-chained per lot)
2. **Statistical price engine** — estimated price, current buying rates, spoken price, basic trends
3. **Top-N recycler ranking + broadcast** — distance, offered price, pickup availability, karma points; WebSocket push to the top 3
4. **Consent-based agreement** before money moves (dual consent: recycler weigh-in → collector green tick)
5. **Transaction receipts + CPCB-compliant Form-6 Manifest CSVs**

From **pages 5–7** the backend also owns or co-owns:

| Blueprint feature | Backend role |
| --- | --- |
| Sync ingestion of offline lots | Primary |
| Targeted broadcast (WS) | Primary |
| Claim & lock (first Accept wins) | Primary |
| Match confirmation to collector | Primary |
| WeightBridge QR verification | Secondary (verify token, open session) |
| Dual consent prompt (audio/visual payload) | Primary |
| Audit sealing `VERIFIED_COMPLETED` | Primary |
| Earnings credit | Primary |
| Audio-first (hi / mr / en strings) | Secondary — TTS text, on-device speech |
| Recycler matching | Secondary to AI/ML — statistical ranker ships here |
| Anomaly & fraud flags | Secondary — rule/z-score at weighbridge |
| Price forecasting / price board | Secondary to AI/ML |
| Materials & pricing dataset | Secondary |
| Minimal collector profile | Primary |
| Recycler registry (CPCB-style seed) | Served by backend |

**Intentionally NOT on the backend**

- Visual lot capture, vernacular UI, offline cache, local QR generation, on-device image classification (`FULLY OFFLINE` on page 6). The backend only **stores** the classification label/confidence the phone already computed.

### Prototype enhancements (make the demo convincing)

- JWT auth for both apps (PIN for collectors, email/password for recyclers, mock OTP `123456`)
- Idempotent batch `/lots/sync` so flaky networks cannot duplicate lots
- In-memory WebSocket rooms (`collector:{id}`, `recycler:{id}`)
- Spoken number-to-words in Hindi, Marathi, English on every money/weight prompt
- Safety cards API for the audio/pictorial cards the mobile app renders
- Fraud score annotated on the ledger without blocking informal trade
- Seeded Odisha-centric recyclers + 45-day synthetic price history so the demo runs with zero external APIs
- Swagger (`/docs`) as the live contract

### Future improvements (not in this prototype)

- Real SMS OTP / Aadhaar eKYC
- PostgreSQL + Alembic migrations + Redis pub/sub for multi-instance WS
- Learned matching weights (LambdaMART / logistic regression on accept/complete labels)
- Isolation-forest / autoencoder fraud once volume exists
- True CPCB portal submission (today we **export** Form-6 CSV; we do not file it)
- UPI collect / payout rails (today payment_mode is recorded, cash is physical)
- Object storage for lot photos; signed URLs
- On-device model OTA from backend (`/ml/models/latest` not shipped)

---

## 10-step mapping (page 5)

| Step | Name | Endpoint / event |
| --- | --- | --- |
| Pre | Local AI + local DB | mobile only |
| 1 | Sync ingestion | `POST /api/v1/lots/sync` |
| 2 | Targeted broadcast | auto after sync; WS `lot.opportunity` to top 3 |
| 3 | Claim & lock | `POST /api/v1/lots/{id}/claim` |
| 4 | Match confirmation | WS `match.confirmed` + `GET /lots/{id}/status` |
| 5 | Physical QR scan | `POST /api/v1/lots/{id}/qr/verify` |
| 6 | Weighbridge entry | `POST /api/v1/lots/{id}/weighbridge` |
| 7 | Dual consent request | WS `consent.requested` (spoken amount) |
| 8 | Collector confirmation | `POST /api/v1/lots/{id}/consent` |
| 9 | Audit sealing & receipt | Form-6 + SHA-256 seal |
| 10 | Earnings credit | ledger CREDIT + WS `lot.completed` |

Frontend contract (headers, payloads, WS events, error codes): **[API_CONTRACT.md](API_CONTRACT.md)**.

---

## Project structure

```
backend-api/
├── app/
│   ├── main.py                 # FastAPI app, CORS, lifespan, /docs
│   ├── config.py               # pydantic-settings / .env
│   ├── database.py             # SQLAlchemy engine + session
│   ├── deps.py                 # JWT dependencies
│   ├── core/                   # security, errors, websocket manager
│   ├── models/entities.py      # ORM
│   ├── schemas/                # Pydantic request/response
│   ├── api/v1/endpoints/       # routes
│   ├── services/lots.py        # 10-step state machine
│   ├── services/pricing.py
│   ├── ml/                     # ranker, price engine, fraud
│   └── utils/                  # i18n, geo, seed
├── data/                       # sqlite file (gitignored)
├── storage/uploads|exports/
├── tests/
├── examples/                   # curl + python client
├── requirements.txt
├── .env.example
├── .gitignore
├── API_CONTRACT.md
└── run.py
```

Swap SQLite → Postgres by setting `DATABASE_URL=postgresql+psycopg2://...` (no code change).

---

## Run locally

```bash
cd backend-api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # optional; defaults work
python run.py                 # http://0.0.0.0:8000
```

Open **http://localhost:8000/docs**.

Demo logins (seeded on first boot):

| Role | Identifier | Secret |
| --- | --- | --- |
| Collector | `9876543210` | PIN `1234` |
| Collector (Marathi) | `9123456780` | PIN `1234` |
| Recycler A (Cuttack) | `mahanadi@demo.kabadiwala` | `recycle123` |
| Recycler B (Bhubaneswar) | `kalinga@demo.kabadiwala` | `recycle123` |
| Recycler C (Cuttack) | `utkal@demo.kabadiwala` | `recycle123` |

Walk the full flow:

```bash
chmod +x examples/curl_walkthrough.sh
./examples/curl_walkthrough.sh
```

Tests:

```bash
pytest -q
```

---

## Frontend integration (do not guess)

1. Login → store `tokens.access_token`.
2. Send `Authorization: Bearer <token>` on every protected call.
3. After login open the role WebSocket; treat REST as source of truth.
4. Collector offline engine: persist lots locally, POST `/lots/sync` when online, key by `client_lot_id`.
5. Generate QR on device from the **same** `qr_token` you synced.
6. On `consent.requested`, play `data.spoken[user.language]` then show the green tick.
7. After `VERIFIED_COMPLETED`, replace local earnings with `GET /collectors/me/earnings` (do not add locally — server is canonical).
8. Recycler-web: poll `/recyclers/me/opportunities` **and** listen for `lot.opportunity` / `lot.withdrawn`.
9. CSV downloads (`/compliance/form6/{id}/csv`, `/compliance/traceability/export`) are files, not JSON.

Full table, payloads, and error codes: [API_CONTRACT.md](API_CONTRACT.md).

---

## How the current “ML” works (do not blindly replace)

The blueprint (page 8) lists three models. Only **#1 ranking** and **#3 price stats** belong on this backend. **#2 image recognition is on-device.**

### 1. Recycler ranker (`app/ml/ranker.py`)

Interpretable weighted score:

```
score = 0.40·distance + 0.30·price + 0.15·availability + 0.15·karma
distance = 1 / (1 + km/20)
hard filter: recyclers farther than MATCH_MAX_DISTANCE_KM (default 150 km) are excluded
price    = min-max of offered ₹/kg in the candidate pool
availability = 1.0 if pickup_available else 0.30
karma    = clip(karma_points / 100)
```

Top 3 are broadcast. Weights are env-configurable.

**Why not a neural net today:** N is tiny, CPCB-facing systems need an explainable “why this recycler”, and there are no labelled accept/complete outcomes yet.

**Improvements when data exists**

- Learn weights with logistic regression / Gradient Boosted ranking (LambdaMART) on `{accepted, completed, time-to-accept, collector-repeat}` 
- Extra features: material specialisation match, remaining daily capacity, historical weight-discrepancy rate, spoken-language overlap, time-of-day pickup windows
- Fairness constraint so new recyclers are not starved (explore/exploit)
- Metrics to track: accept@3, lock latency, completion rate, collector surplus (₹ vs market)

### 2. On-device vision (NOT this repo)

Mobile classifies PCB / wires / hard plastics / etc. fully offline.

**Recommendations for the ML owner**

- Start with MobileNetV3-small or EfficientNet-lite0, INT8 TFLite, 224², <8 MB
- Classes must match backend material codes exactly
- Hardest errors: cables vs copper wires, PCB vs mixed boards — collect **Indian** yard photos (lighting, dirt, hands, tarps), not clean lab images
- Always return `{label, confidence, model_version}`; backend stores them for later server-side QA
- If confidence < 0.55, UI should fall back to pictogram picker (low-literacy) rather than guessing
- Improve recall on hazardous classes (batteries, CRT glass) even if precision on plastics drops — safety > tidy labels
- Latency target: <200 ms on a low-end Android; use NNAPI delegates
- Do **not** send raw images to the backend by default (bandwidth + trust). Optional upload only when the collector is on Wi-Fi and opts in for model improvement.

### 3. Price engine (`app/ml/price_engine.py`)

SMA-7 / SMA-30, OLS slope ₹/day, residual volatility, naive 7-day linear forecast. Seeded with synthetic series around realistic informal-market bands (field research is still marked **needed** on page 8).

**Improvements**

- Replace synthetic history with weekly yard quotes + metal-exchange copper/aluminum as exogenous regressors
- Hierarchical model: India → state → city, so Cuttack can borrow strength from Bhubaneswar
- Quantile regression for the low/high band shown to collectors (they need a range, not a false-precise point)
- Spoken price should round to the nearest ₹5/₹10 — kabadiwalas do not negotiate paise
- Track MAPE / sMAPE against actual `offered_rate_per_kg` after consent

### 4. Fraud / anomaly (`app/ml/fraud.py`)

Rule scores at weighbridge (weight ratio, rate vs market, claim bursts). **Does not block** the trade — informal sector must not freeze; it annotates the seal and can speak a warning.

**Improvements**

- Isolation Forest / copula on `{weight_ratio, rate_z, hour, recycler_id}` after ~5k transactions
- Photo perceptual hash to catch duplicate lots
- GPS jump vs claimed meetup
- Precision is the metric that matters (false accusations destroy trust). Target precision ≥ 0.9 at recall 0.4 for HIGH alerts.

### Integrating models with FastAPI

- Keep inference **in-process and CPU** for this scale (ranking 7 recyclers is microseconds).
- Do not put TFLite in the API process; vision stays on device.
- Version every score (`ranker_v1`, `price_sma_v1`, `fraud_rules_v1`) inside MatchOffer / Transaction so we can A/B later.
- If a heavier model appears, wrap it in `app/ml/` with a stable function signature and call it from `services/` — routes never import numpy models directly beyond today.

---

## Environment

See `.env.example`. Important knobs:

```
SECRET_KEY=...
DATABASE_URL=sqlite:///./data/kabadiwala.db
CORS_ORIGINS=*
MATCH_W_DISTANCE=0.40
MATCH_W_PRICE=0.30
MATCH_W_AVAILABILITY=0.15
MATCH_W_KARMA=0.15
MATCH_TOP_N=3
MATCH_MAX_DISTANCE_KM=150
```

---

## Status codes (summary)

| HTTP | Meaning |
| --- | --- |
| 200 / 201 | Success |
| 400 | Bad QR / OTP |
| 401 | Missing or bad token |
| 403 | Wrong role or not in top-3 |
| 404 | Unknown lot / unsealed Form-6 |
| 409 | Illegal lot state (first-accept already won, etc.) |
| 422 | Pydantic validation |
| 500 | Unhandled (body still JSON `{error:true, code:INTERNAL_ERROR}`) |
