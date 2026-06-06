# deploy_website.ps1
# Laed alle Dateien aus web_assets/ per FTP auf World4You hoch.
# Credentials aus .env (FTP_HOST, FTP_USER, FTP_PASS, FTP_PATH)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── .env laden ──────────────────────────────────────────────────────────────
$envFile = Join-Path $PSScriptRoot ".." ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#=\s][^=]*)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim())
        }
    }
}

$FTP_HOST = $env:FTP_HOST
$FTP_USER = $env:FTP_USER
$FTP_PASS = $env:FTP_PASS
$FTP_PATH = if ($env:FTP_PATH) { $env:FTP_PATH.TrimEnd('/') + '/' } else { '/' }

if (-not $FTP_HOST -or $FTP_HOST -eq 'fXXXX.world4you.com') {
    Write-Host "Fehler: FTP_HOST, FTP_USER und FTP_PASS in .env setzen." -ForegroundColor Red
    Write-Host "Vorlage: .env.example" -ForegroundColor Yellow
    exit 1
}

# ── Hilfsfunktionen ──────────────────────────────────────────────────────────
function Ftp-MkDir([string]$uri) {
    try {
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $req.Credentials = New-Object System.Net.NetworkCredential($FTP_USER, $FTP_PASS)
        $req.UsePassive = $true; $req.UseBinary = $true; $req.KeepAlive = $false
        $req.GetResponse().Close()
    } catch {
        # Verzeichnis existiert schon – kein Problem
    }
}

function Ftp-Upload([string]$localPath, [string]$uri) {
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $req.Credentials = New-Object System.Net.NetworkCredential($FTP_USER, $FTP_PASS)
    $req.UsePassive = $true; $req.UseBinary = $true; $req.KeepAlive = $false

    $bytes = [System.IO.File]::ReadAllBytes($localPath)
    $req.ContentLength = $bytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    $req.GetResponse().Close()
}

# ── Deploy ───────────────────────────────────────────────────────────────────
$localBase = Join-Path $PSScriptRoot ".." "web_assets"
$localBase = (Resolve-Path $localBase).Path

$baseUri = "ftp://$FTP_HOST$FTP_PATH"

Write-Host ""
Write-Host "EventRide Website Deploy → $baseUri" -ForegroundColor Cyan
Write-Host "Quelle: $localBase"
Write-Host ""

# Alle Unterordner zuerst anlegen
$dirs = Get-ChildItem -Path $localBase -Recurse -Directory | Sort-Object FullName
foreach ($dir in $dirs) {
    $rel = $dir.FullName.Substring($localBase.Length).TrimStart('\','/').Replace('\','/')
    $uri = "$baseUri$rel/"
    Ftp-MkDir $uri
    Write-Host "  Ordner: $rel" -ForegroundColor DarkGray
}

# Dateien hochladen
$files = Get-ChildItem -Path $localBase -Recurse -File | Sort-Object FullName
$total = $files.Count
$i = 0

foreach ($file in $files) {
    $i++
    $rel = $file.FullName.Substring($localBase.Length).TrimStart('\','/').Replace('\','/')
    $uri = "$baseUri$rel"

    Write-Host "  [$i/$total] $rel" -NoNewline
    Ftp-Upload $file.FullName $uri
    Write-Host " ✓" -ForegroundColor Green
}

Write-Host ""
Write-Host "Fertig! $total Dateien hochgeladen." -ForegroundColor Green
Write-Host "Website: https://eventride.at" -ForegroundColor Cyan
