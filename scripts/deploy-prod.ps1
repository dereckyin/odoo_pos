# 一鍵部署 pos.myvnc.com（後台 + API + 顧客端 + /readme 說明頁）
# 用法：
#   .\scripts\deploy-prod.ps1
#   .\scripts\deploy-prod.ps1 -SkipApk
#   .\scripts\deploy-prod.ps1 -SkipCustomer
param(
  [string]$Server = "ubuntu@pos.myvnc.com",
  [string]$Key = "$env:USERPROFILE\Documents\gcserver\talktothebooks_test.pem",
  [switch]$SkipApk,
  [switch]$SkipCustomer,
  [switch]$SkipMarketplace,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

function Invoke-Step([string]$Label, [scriptblock]$Action) {
  Write-Host "`n==> $Label" -ForegroundColor Cyan
  & $Action
}

if (-not (Test-Path -LiteralPath $Key)) {
  throw "SSH key not found: $Key (pass -Key path)"
}

$ssh = @("-i", $Key, "-o", "StrictHostKeyChecking=accept-new", $Server)
$scp = @("-i", $Key, "-o", "StrictHostKeyChecking=accept-new")

if (-not $SkipBuild) {
  Invoke-Step "Sync readme (pos_doc → admin/public/readme)" {
    node (Join-Path $root "scripts/sync-readme.mjs")
  }

  if (-not $SkipApk) {
    Invoke-Step "Build POS Android APK (optional, for /readme download)" {
      Push-Location (Join-Path $root "apps/pos_app")
      flutter build apk --release
      Pop-Location
      node (Join-Path $root "scripts/sync-readme.mjs")
    }
  }

  Invoke-Step "Build admin (includes /readme in dist/)" {
    Push-Location (Join-Path $root "apps/admin")
    npm ci
    npm run build
    Pop-Location
  }

  if (-not $SkipCustomer) {
    Invoke-Step "Build customer order web (/customer/)" {
      Push-Location (Join-Path $root "apps/customer_order_web")
      $env:VITE_API_BASE = "https://pos.myvnc.com/api"
      npm ci
      npm run build
      Pop-Location
    }
  }

  if (-not $SkipMarketplace) {
    Invoke-Step "Build marketplace web (/) " {
      Push-Location (Join-Path $root "apps/marketplace_web")
      $env:VITE_API_BASE = "https://pos.myvnc.com/api"
      npm ci
      npm run build
      Pop-Location
    }
  }
}

Invoke-Step "Pack deployment archive" {
  Push-Location $root
  $tarArgs = @(
    "-czf", "deploy-pack.tar.gz",
    "--exclude=__pycache__", "--exclude=.pytest_cache", "--exclude=.venv", "--exclude=uploads",
    "apps/api", "apps/admin/dist", "deploy/nginx.conf", "deploy/nginx.customer.conf",
    "deploy/nginx.marketplace.conf", "docker-compose.prod.yml"
  )
  if (-not $SkipCustomer) {
    $tarArgs += "apps/customer_order_web/dist"
  }
  if (-not $SkipMarketplace) {
    $tarArgs += "apps/marketplace_web/dist"
  }
  & tar @tarArgs
  Pop-Location
}

Invoke-Step "Upload to server" {
  & scp @scp (Join-Path $root "deploy-pack.tar.gz") "${Server}:/tmp/deploy-pack.tar.gz"
}

Invoke-Step "Extract & rebuild Docker on server" {
  $remote = @'
set -e
cd ~/odoo_pos
tar -xzf /tmp/deploy-pack.tar.gz
docker compose -f docker-compose.prod.yml up -d --build
for i in $(seq 1 60); do
  if docker exec pos_api_prod curl -sf http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "API healthy"
    break
  fi
  sleep 2
done
docker compose -f docker-compose.prod.yml ps
rm -f /tmp/deploy-pack.tar.gz
'@
  & ssh @ssh $remote
}

Remove-Item (Join-Path $root "deploy-pack.tar.gz") -ErrorAction SilentlyContinue

Write-Host "`nDeploy complete." -ForegroundColor Green
Write-Host "  Admin:       https://pos.myvnc.com/"
Write-Host "  Marketplace: https://pos.myvnc.com/market/"
Write-Host "  Readme:      https://pos.myvnc.com/readme/"
Write-Host "  Customer:    https://pos.myvnc.com/customer/"
Write-Host "  APK:      https://pos.myvnc.com/readme/pos-release.apk"
