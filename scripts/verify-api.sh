#!/usr/bin/env bash
# Part II verification: run with server at http://localhost:8080
# Usage: ./scripts/verify-api.sh   or   bash scripts/verify-api.sh
set -e
BASE="${BASE_URL:-http://localhost:8080}"
PASS=0
FAIL=0

check() {
  local expected=$1
  local desc=$2
  shift 2
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "$@")
  if [[ "$code" == "$expected" ]]; then
    echo "  OK $expected — $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL expected $expected got $code — $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying Product API at $BASE"
echo ""

echo "200 OK — list products"
check 200 "GET /products" "$BASE/products"
echo ""

echo "200 OK — get product by ID (seed data)"
check 200 "GET /products/1" "$BASE/products/1"
echo ""

echo "201 Created — create product"
check 201 "POST /products" -X POST "$BASE/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","price":1.99,"quantity":10}'
echo ""

echo "400 Bad Request — missing name"
check 400 "POST without name" -X POST "$BASE/products" \
  -H "Content-Type: application/json" \
  -d '{"price":5.0}'
echo ""

echo "400 Bad Request — negative price"
check 400 "POST negative price" -X POST "$BASE/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"x","price":-1}'
echo ""

echo "400 Bad Request — invalid JSON"
check 400 "POST invalid JSON" -X POST "$BASE/products" \
  -H "Content-Type: application/json" \
  -d 'not json'
echo ""

echo "404 Not Found — product ID does not exist"
check 404 "GET /products/nonexistent-99999" "$BASE/products/nonexistent-99999"
echo ""

echo "404 Not Found — wrong path"
check 404 "GET /unknown" "$BASE/unknown"
echo ""

echo "---"
echo "Passed: $PASS  Failed: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
echo "All Part II response-code checks passed."
