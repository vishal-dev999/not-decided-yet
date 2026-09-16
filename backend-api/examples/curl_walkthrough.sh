#!/usr/bin/env bash
# Full 10-step prototype walkthrough (page 5 of the blueprint).
# Usage: BASE=http://localhost:8000 ./examples/curl_walkthrough.sh
set -euo pipefail
BASE="${BASE:-http://localhost:8000}"

echo "== Health =="
curl -s "$BASE/health" | python -m json.tool

echo "== Collector login =="
COL=$(curl -s -X POST "$BASE/api/v1/auth/collector/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"9876543210","pin":"1234"}')
CT=$(echo "$COL" | python -c "import sys,json; print(json.load(sys.stdin)['tokens']['access_token'])")

echo "== Recycler login (Mahanadi, Cuttack) =="
REC=$(curl -s -X POST "$BASE/api/v1/auth/recycler/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"mahanadi@demo.kabadiwala","password":"recycle123"}')
RT=$(echo "$REC" | python -c "import sys,json; print(json.load(sys.stdin)['tokens']['access_token'])")

LOT_CLIENT="lot-$(date +%s)"
echo "== Step 1+2: sync lot $LOT_CLIENT (auto-broadcast) =="
SYNC=$(curl -s -X POST "$BASE/api/v1/lots/sync" \
  -H "Authorization: Bearer $CT" -H "Content-Type: application/json" \
  -d "{\"lots\":[{\"client_lot_id\":\"$LOT_CLIENT\",\"material_category\":\"pcb\",\"estimated_weight_kg\":12,\"classification\":{\"label\":\"pcb\",\"confidence\":0.91,\"model_version\":\"mobile-v1\"},\"latitude\":20.4625,\"longitude\":85.8828,\"city\":\"Cuttack\",\"qr_token\":\"qr-$LOT_CLIENT\"}]}")
LOT_ID=$(echo "$SYNC" | python -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])")
echo "lot_id=$LOT_ID"

echo "== Recycler opportunities =="
curl -s "$BASE/api/v1/recyclers/me/opportunities" -H "Authorization: Bearer $RT" | python -m json.tool | head

echo "== Step 3+4: claim =="
curl -s -X POST "$BASE/api/v1/lots/$LOT_ID/claim" \
  -H "Authorization: Bearer $RT" -H "Content-Type: application/json" \
  -d '{"pickup_minutes_from_now":45}' | python -m json.tool | head

echo "== Step 5: QR verify =="
curl -s -X POST "$BASE/api/v1/lots/$LOT_ID/qr/verify" \
  -H "Authorization: Bearer $RT" -H "Content-Type: application/json" \
  -d "{\"qr_token\":\"qr-$LOT_CLIENT\"}" | python -m json.tool | head

echo "== Step 6+7: weighbridge 14kg @ 220 = 3080 =="
curl -s -X POST "$BASE/api/v1/lots/$LOT_ID/weighbridge" \
  -H "Authorization: Bearer $RT" -H "Content-Type: application/json" \
  -d '{"certified_weight_kg":14,"offered_rate_per_kg":220}' | python -m json.tool | head

echo "== Step 8+9+10: collector consent + cash =="
curl -s -X POST "$BASE/api/v1/lots/$LOT_ID/consent" \
  -H "Authorization: Bearer $CT" -H "Content-Type: application/json" \
  -d '{"accepted":true,"payment_mode":"CASH"}' | python -m json.tool | head

echo "== Earnings =="
curl -s "$BASE/api/v1/collectors/me/earnings" -H "Authorization: Bearer $CT" | python -m json.tool

echo "== Form-6 JSON =="
curl -s "$BASE/api/v1/compliance/form6/$LOT_ID" -H "Authorization: Bearer $RT" | python -m json.tool | head

echo "Done. Download CSV: curl -H 'Authorization: Bearer $RT' $BASE/api/v1/compliance/form6/$LOT_ID/csv -o form6.csv"
