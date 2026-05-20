#!/usr/bin/env bash
# Pollt den Codemagic-Build bis er fertig ist (success/failed/timeout)
# Ausgabe auf stdout: "finished" | "failed"
# Exit-Code: 0 = success, 1 = failed oder timeout
set -euo pipefail

ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN fehlt in .env}"

BUILD_ID="${1:-$(cat /tmp/cm_last_build_id 2>/dev/null || true)}"
if [ -z "$BUILD_ID" ]; then
  echo "ERROR: Keine Build-ID gefunden (Argument oder /tmp/cm_last_build_id)." >&2
  exit 1
fi

TIMEOUT=1800   # 30 Minuten
INTERVAL=30    # alle 30 Sekunden
ELAPSED=0

echo "Warte auf Build $BUILD_ID ..." >&2

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  RESPONSE=$(curl -s "https://api.codemagic.io/builds/$BUILD_ID" \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN")

  STATUS=$(echo "$RESPONSE" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('build',d).get('status','unknown'))" 2>/dev/null || \
    echo "$RESPONSE" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)

  printf "[%3ds] Status: %s\n" "$ELAPSED" "$STATUS" >&2

  case "$STATUS" in
    "finished")
      echo "finished"
      exit 0
      ;;
    "failed"|"canceled"|"skipped"|"timeout")
      echo "failed"
      exit 1
      ;;
    "queued"|"building"|"preparing"|"publishing")
      sleep "$INTERVAL"
      ELAPSED=$((ELAPSED + INTERVAL))
      ;;
    *)
      echo "Unbekannter Status: $STATUS — warte weiter" >&2
      sleep "$INTERVAL"
      ELAPSED=$((ELAPSED + INTERVAL))
      ;;
  esac
done

echo "Timeout nach ${TIMEOUT}s." >&2
echo "failed"
exit 1
