<#
.SYNOPSIS
    Validiert den Dart-Code lokal vor dem Push zu Codemagic.
    Fängt Dependency- und Kompilierungsfehler ab, bevor ein 8-minütiger
    Codemagic-Build scheitert.

.EXAMPLE
    .\validate.ps1
#>

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  EventRide - Lokale Build-Validierung" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Packages auflösen
Write-Host "[1/3] flutter pub get ..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "FEHLER: Dependency-Auflösung fehlgeschlagen." -ForegroundColor Red
    Write-Host "Tipp: Versions-Konflikte in pubspec.yaml prüfen." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# 2. Dart-Analyse
Write-Host "[2/3] flutter analyze ..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "FEHLER: Dart-Analyse fehlgeschlagen." -ForegroundColor Red
    Write-Host "Tipp: Fehler oben beheben, dann erneut validieren." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK" -ForegroundColor Green
Write-Host ""

# 3. Vollständige Dart-Kompilierung (APK Debug = kein Keystore nötig)
Write-Host "[3/3] flutter build apk --debug ..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "FEHLER: Dart-Kompilierung fehlgeschlagen." -ForegroundColor Red
    Write-Host "Tipp: Fehler oben beheben. Dieser Schritt fängt was 'analyze' übersieht." -ForegroundColor DarkGray
    exit 1
}
Write-Host "OK" -ForegroundColor Green
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "  Alle Checks bestanden — Push möglich!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
