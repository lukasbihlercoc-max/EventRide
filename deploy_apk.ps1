<#
.SYNOPSIS
    Baut die EventRide APK und verteilt sie via Firebase App Distribution.

.PARAMETER ReleaseNotes
    Release-Notizen (z.B. "Bugfix: Chat-Ansicht korrigiert").

.PARAMETER SkipBuild
    Ueberspringt den Flutter-Build und verwendet die zuletzt gebaute APK.

.EXAMPLE
    .\deploy_apk.ps1 -ReleaseNotes "Erster Beta-Test"
    .\deploy_apk.ps1 -ReleaseNotes "Hotfix Login" -SkipBuild
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseNotes,
    [switch]$SkipBuild
)

$FIREBASE_APP_ID = "1:686951435694:android:3d4b36a31821b4417e4c3f"
$PROJECT_ID      = "eventride-cd0e9"
$GROUP           = "tester"
$APK_PATH        = "build/app/outputs/flutter-apk/app-release.apk"
$PUBSPEC         = "pubspec.yaml"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  EventRide - Firebase App Distribution" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 0. Build-Nummer erhoehen (ausser bei SkipBuild)
if (-not $SkipBuild) {
    $content = Get-Content $PUBSPEC -Raw
    if ($content -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        $base     = $Matches[1]
        $build    = [int]$Matches[2] + 1
        $newVer   = "version: $base+$build"
        $content  = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', $newVer
        Set-Content $PUBSPEC $content -NoNewline -Encoding utf8
        Write-Host "[0/2] Build-Nummer erhoeht: $base+$build" -ForegroundColor Green
    } else {
        Write-Host "Konnte Version in pubspec.yaml nicht lesen." -ForegroundColor Red
        exit 1
    }
}

# 1. Flutter Build
if (-not $SkipBuild) {
    Write-Host "[1/2] Flutter Release-Build wird gestartet..." -ForegroundColor Yellow
    flutter build apk --release
    $buildExit = $LASTEXITCODE
    if ($buildExit -ne 0) {
        Write-Host "Flutter-Build fehlgeschlagen. Exit-Code: $buildExit" -ForegroundColor Red
        exit 1
    }
    Write-Host "Build erfolgreich." -ForegroundColor Green
} else {
    Write-Host "[1/2] Build uebersprungen (-SkipBuild)." -ForegroundColor DarkGray
}

# 2. APK pruefen
if (-not (Test-Path $APK_PATH)) {
    Write-Host "APK nicht gefunden: $APK_PATH" -ForegroundColor Red
    exit 1
}

$apkSize = [math]::Round((Get-Item $APK_PATH).Length / 1MB, 1)
Write-Host "APK gefunden: $APK_PATH ($apkSize MB)" -ForegroundColor DarkGray

# 3. Upload
Write-Host ""
Write-Host "[2/2] APK wird hochgeladen..." -ForegroundColor Yellow
Write-Host "  App-ID  : $FIREBASE_APP_ID" -ForegroundColor DarkGray
Write-Host "  Gruppe  : $GROUP" -ForegroundColor DarkGray
Write-Host "  Notizen : $ReleaseNotes" -ForegroundColor DarkGray
Write-Host ""

npx firebase-tools appdistribution:distribute "$APK_PATH" --app "$FIREBASE_APP_ID" --project "$PROJECT_ID" --groups "$GROUP" --release-notes "$ReleaseNotes"

$uploadExit = $LASTEXITCODE
if ($uploadExit -ne 0) {
    Write-Host "Upload fehlgeschlagen. Exit-Code: $uploadExit" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Fertig! APK erfolgreich verteilt." -ForegroundColor Green
Write-Host ""
