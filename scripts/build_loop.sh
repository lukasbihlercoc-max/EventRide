#!/usr/bin/env bash
# Automatischer Build-Loop fuer Codemagic iOS.
#
# Aufruf:   ./scripts/build_loop.sh
# Reset:    rm -f /tmp/cm_iteration && ./scripts/build_loop.sh
#
# Exit-Codes:
#   0 = Build erfolgreich
#   1 = Build fehlgeschlagen (Fehler in /tmp/cm_last_errors.txt)
#       -> Claude: lese Fehler, fixe Code, committe, push, dann erneut aufrufen
#   2 = Max-Iterationen erreicht
#   3 = Lokale Checks fehlgeschlagen
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_ITERATIONS=5

# Iteration aus Datei lesen (persistiert zwischen Aufrufen)
ITERATION_FILE="/tmp/cm_iteration"
iteration=$(cat "$ITERATION_FILE" 2>/dev/null || echo "1")
iteration=$(( iteration ))  # in Zahl umwandeln

if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
  echo ""
  echo "⛔ Max Iterationen ($MAX_ITERATIONS) erreicht. Manuelle Überprüfung nötig."
  echo "Reset mit: rm -f $ITERATION_FILE"
  exit 2
fi

echo ""
echo "================================================================"
echo "  Build-Loop — Versuch $iteration / $MAX_ITERATIONS"
echo "================================================================"

# ---- 1. Lokale Dart-Checks ----------------------------------------
echo ""
echo "[Check] flutter analyze lib/ ..."
if ! flutter analyze lib/ --fatal-infos 2>&1; then
  echo ""
  echo "⛔ Lokale Analyse fehlgeschlagen. Bitte Fehler oben beheben."
  exit 3
fi
echo "[Check] OK"

# ---- 2. Git: Aenderungen committen und pushen ----------------------
echo ""
if [ -n "$(git status --porcelain)" ]; then
  echo "[Git] Aenderungen gefunden – committe und pushe..."
  git add -A
  git commit -m "fix: auto-fix Iteration $iteration [build-loop]"
  git push
  echo "[Git] Gepusht."
else
  echo "[Git] Keine ungespeicherten Aenderungen."
fi

# ---- 3. Codemagic-Build triggern ----------------------------------
echo ""
echo "[Codemagic] Build triggern..."
"$SCRIPT_DIR/cm_trigger.sh"
BUILD_ID=$(cat /tmp/cm_last_build_id)

# ---- 4. Auf Ergebnis warten ---------------------------------------
echo ""
echo "[Codemagic] Warte auf Build $BUILD_ID ..."
STATUS=$("$SCRIPT_DIR/cm_poll.sh" "$BUILD_ID" || echo "failed")

# ---- 5. Ergebnis auswerten ----------------------------------------
echo ""
if [ "$STATUS" = "finished" ]; then
  echo "✅ Build $iteration erfolgreich!"
  echo "0" > "$ITERATION_FILE"
  BUILD_URL="https://codemagic.io/app/${CODEMAGIC_APP_ID:-?}/build/$BUILD_ID"
  echo "Link: $BUILD_URL"
  exit 0
fi

echo "❌ Build fehlgeschlagen — lese Logs..."
echo ""
"$SCRIPT_DIR/cm_logs.sh" "$BUILD_ID" || true

echo ""
echo "================================================================"
echo "  Fehler gespeichert in: /tmp/cm_last_errors.txt"
echo "  Build-Link: https://codemagic.io/app/${CODEMAGIC_APP_ID:-?}/build/$BUILD_ID"
echo ""
echo "  >>> Claude Code: Lese /tmp/cm_last_errors.txt, fixe den Fehler,"
echo "  >>> committe die Aenderungen, dann rufe ./scripts/build_loop.sh"
echo "  >>> erneut auf (Versuch $((iteration+1))/$MAX_ITERATIONS folgt automatisch)."
echo "================================================================"

# Zaehler fuer naechsten Aufruf erhoehen
echo "$((iteration + 1))" > "$ITERATION_FILE"

exit 1
