# 將 pos_doc 說明頁同步到 apps/admin/public/readme（Vite build 會複製到 dist/readme）
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root "pos_doc"
$dst = Join-Path $root "apps\admin\public\readme"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
$srcHtml = Join-Path $src "系統三大模組.html"
if (-not (Test-Path -LiteralPath $srcHtml)) {
  $srcHtml = (Get-ChildItem -Path $src -Filter "*.html" | Select-Object -First 1).FullName
}
if (-not $srcHtml -or -not (Test-Path -LiteralPath $srcHtml)) { throw "pos_doc HTML not found" }
Copy-Item -LiteralPath $srcHtml -Destination (Join-Path $dst "index.html") -Force
Copy-Item -Force (Join-Path $src "*.png") $dst
$apk = Join-Path $root "apps\pos_app\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path -LiteralPath $apk) {
  Copy-Item -LiteralPath $apk -Destination (Join-Path $dst "pos-release.apk") -Force
  Write-Host "Copied APK -> pos-release.apk"
} else {
  Write-Host "WARN: app-release.apk not found; run flutter build apk first"
}
Write-Host "Synced readme -> $dst"
