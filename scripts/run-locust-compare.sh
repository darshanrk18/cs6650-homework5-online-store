#!/usr/bin/env bash
# Run HttpUser and FastHttpUser headless with same params for quick comparison.
# Usage: ./scripts/run-locust-compare.sh [host]
# Example: ./scripts/run-locust-compare.sh http://localhost:8080
#          ./scripts/run-locust-compare.sh http://184.32.45.110:8080
set -e
HOST="${1:-http://localhost:8080}"
USERS="${LOCUST_USERS:-50}"
SPAWN="${LOCUST_SPAWN:-10}"
DURATION="${LOCUST_DURATION:-1m}"
echo "Target: $HOST (users=$USERS spawn=$SPAWN duration=$DURATION)"
echo ""
echo "=== HttpUser ==="
locust -f locustfile.py --host="$HOST" --headless -u "$USERS" -r "$SPAWN" -t "$DURATION" 2>/dev/null | tail -25
echo ""
echo "=== FastHttpUser ==="
locust -f locustfile_fast.py --host="$HOST" --headless -u "$USERS" -r "$SPAWN" -t "$DURATION" 2>/dev/null | tail -25
echo ""
echo "Compare RPS and response times above. For screenshots, run Locust with the web UI (no --headless)."
