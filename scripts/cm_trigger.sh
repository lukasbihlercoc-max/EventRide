#!/usr/bin/env bash
# Triggert einen Codemagic-Build und speichert die Build-ID in /tmp/cm_last_build_id
set -euo pipefail

# .env laden
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

: "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN fehlt in .env}"
: "${CODEMAGIC_APP_ID:?CODEMAGIC_APP_ID fehlt in .env}"
: "${CODEMAGIC_WORKFLOW_ID:?CODEMAGIC_WORKFLOW_ID fehlt in .env}"

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"

echo "Starte Build: branch=$BRANCH workflow=$CODEMAGIC_WORKFLOW_ID"

RESPONSE=$(curl -s -X POST "https://api.codemagic.io/builds" \
  -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"appId\": \"$CODEMAGIC_APP_ID\",
    \"workflowId\": \"$CODEMAGIC_WORKFLOW_ID\",
    \"branch\": \"$BRANCH\"
  }")

BUILD_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('buildId',''))" 2>/dev/null || \
           echo "$RESPONSE" | grep -o '"buildId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUILD_ID" ]; then
  echo "ERROR: Build konnte nicht gestartet werden."
  echo "API-Antwort: $RESPONSE"
  exit 1
fi

echo "$BUILD_ID" > /tmp/cm_last_build_id
echo ""
echo "Build gestartet: $BUILD_ID"
echo "Link: https://codemagic.io/app/$CODEMAGIC_APP_ID/build/$BUILD_ID"
