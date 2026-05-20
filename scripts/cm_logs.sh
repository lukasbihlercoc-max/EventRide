#!/usr/bin/env bash
# Holt Build-Details und filtert Fehler heraus -> /tmp/cm_last_errors.txt
set -euo pipefail

ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN fehlt in .env}"
: "${CODEMAGIC_APP_ID:?CODEMAGIC_APP_ID fehlt in .env}"

BUILD_ID="${1:-$(cat /tmp/cm_last_build_id 2>/dev/null || true)}"
if [ -z "$BUILD_ID" ]; then
  echo "ERROR: Keine Build-ID gefunden." >&2
  exit 1
fi

BUILD_URL="https://codemagic.io/app/$CODEMAGIC_APP_ID/build/$BUILD_ID"
echo "Build-URL: $BUILD_URL" >&2

# Build-Details holen (enthaelt fehlgeschlagene Steps)
RESPONSE=$(curl -s "https://api.codemagic.io/builds/$BUILD_ID" \
  -H "x-auth-token: $CODEMAGIC_API_TOKEN")

# Schreibe strukturierten Fehlerbericht
{
  echo "=== Codemagic Build $BUILD_ID ==="
  echo "URL: $BUILD_URL"
  echo ""

  # Fehlgeschlagene Steps extrahieren
  FAILED_STEP=$(echo "$RESPONSE" | \
    python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    build = d.get('build', d)
    steps = build.get('steps', [])
    for s in steps:
        if s.get('status') in ('failed', 'error'):
            print('Fehlgeschlagener Step:', s.get('name','?'))
            print('Exit-Code:', s.get('exitCode','?'))
            output = s.get('output', '')
            if output:
                lines = output.splitlines()
                # Letzte 80 Zeilen + Fehlerfilter
                relevant = [l for l in lines if any(k in l for k in ['error:', 'ERROR', 'FAILED', 'Exception', 'warning:', 'note:'])]
                print()
                print('--- Relevante Ausgabe ---')
                for l in (relevant or lines[-80:]):
                    print(l)
except Exception as e:
    print('(Python-Parsing fehlgeschlagen:', e, ')')
" 2>/dev/null || echo "(Step-Details nicht verfuegbar)")

  echo "$FAILED_STEP"
  echo ""

  # Logs-Endpoint versuchen (Codemagic gibt ggf. keinen direkten Log-Stream)
  LOG_RESPONSE=$(curl -s "https://api.codemagic.io/builds/$BUILD_ID/logs" \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN" 2>/dev/null || true)

  if echo "$LOG_RESPONSE" | grep -qiE "(error:|ERROR|FAILED|Exception)" 2>/dev/null; then
    echo "--- Gefilterte Log-Zeilen ---"
    echo "$LOG_RESPONSE" | grep -iE "(error:|ERROR|FAILED|Exception|failed:)" \
      | grep -v "^--" \
      | head -100
  fi

  echo ""
  echo "=== Manuelle Analyse: $BUILD_URL ==="
} > /tmp/cm_last_errors.txt

echo "=== Gefilterte Fehler ==="
cat /tmp/cm_last_errors.txt
echo "========================="
echo "Gespeichert in: /tmp/cm_last_errors.txt"
