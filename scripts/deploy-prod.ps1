# 一鍵部署 pos.myvnc.com（後台 + API + 顧客端 + /readme 說明頁）
# 用法：
#   .\scripts\deploy-prod.ps1
#   .\scripts\deploy-prod.ps1 -SkipApk
#   .\scripts\deploy-prod.ps1 -SkipCustomer
param(
  [string]$Server = "ubuntu@pos.myvnc.com",
  [string]$Key = "$env:USERPROFILE\Documents\gcserver\talktothebooks_test.pem",
  [string]$CustomerBaseUrl = "https://pos.myvnc.com/customer",
  [switch]$SkipApk,
  [switch]$SkipWindows,
  [switch]$SkipCustomer,
  [switch]$SkipCashier,
  [switch]$SkipMarketplace,
  [switch]$SkipShopping,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent

function Invoke-Step([string]$Label, [scriptblock]$Action) {
  Write-Host "`n==> $Label" -ForegroundColor Cyan
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & $Action
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
      throw "Step failed with exit code $LASTEXITCODE"
    }
  } finally {
    $ErrorActionPreference = $prev
  }
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
      flutter build apk --release --dart-define=CUSTOMER_BASE_URL=$CustomerBaseUrl
      Pop-Location
      node (Join-Path $root "scripts/sync-readme.mjs")
    }
  }

  if (-not $SkipWindows) {
    Invoke-Step "Build POS Windows release (for /readme download)" {
      Push-Location (Join-Path $root "apps/pos_app")
      flutter build windows --release --dart-define=CUSTOMER_BASE_URL=$CustomerBaseUrl
      Pop-Location
      node (Join-Path $root "scripts/sync-readme.mjs")
    }
  }

  Invoke-Step "Build admin (includes /readme in dist/)" {
    Push-Location (Join-Path $root "apps/admin")
    $env:VITE_CUSTOMER_BASE_URL = $CustomerBaseUrl
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

  if (-not $SkipCashier) {
    Invoke-Step "Build web POS cashier (/pos/)" {
      Push-Location (Join-Path $root "apps/pos_web")
      $env:VITE_API_BASE = "https://pos.myvnc.com/api"
      npm ci
      npm run build
      Pop-Location
    }
  }

  if (-not $SkipMarketplace) {
    Invoke-Step "Build marketplace web (/market/)" {
      Push-Location (Join-Path $root "apps/marketplace_web")
      $env:VITE_API_BASE = "https://pos.myvnc.com/api"
      npm ci
      npm run build
      Pop-Location
    }
  }

  if (-not $SkipShopping) {
    Invoke-Step "Build shopping web (/shopping/)" {
      Push-Location (Join-Path $root "apps/shopping_web")
      $env:VITE_API_BASE = "https://pos.myvnc.com/api"
      $env:VITE_SHOW_ENTRY_SIMULATOR = "0"
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
    "deploy/nginx.pos.conf", "deploy/nginx.marketplace.conf", "deploy/nginx.shopping.conf",
    "docker-compose.prod.yml"
  )
  if (-not $SkipCustomer) {
    $tarArgs += "apps/customer_order_web/dist"
  }
  if (-not $SkipCashier) {
    $tarArgs += "apps/pos_web/dist"
  }
  if (-not $SkipMarketplace) {
    $tarArgs += "apps/marketplace_web/dist"
  }
  if (-not $SkipShopping) {
    $tarArgs += "apps/shopping_web/dist"
  }
  & tar @tarArgs
  Pop-Location
}

Invoke-Step "Upload to server" {
  & scp @scp (Join-Path $root "deploy-pack.tar.gz") "${Server}:/tmp/deploy-pack.tar.gz"
}

Invoke-Step "Extract & rebuild Docker on server" {
  $remote = @"
set -e
cd ~/odoo_pos
tar -xzf /tmp/deploy-pack.tar.gz
if grep -q '^CUSTOMER_BASE_URL=' deploy/.env.api 2>/dev/null; then
  sed -i 's|^CUSTOMER_BASE_URL=.*|CUSTOMER_BASE_URL=$CustomerBaseUrl|' deploy/.env.api
else
  printf '\nCUSTOMER_BASE_URL=%s\n' '$CustomerBaseUrl' >> deploy/.env.api
fi
docker compose -f docker-compose.prod.yml up -d --build
for i in `$(seq 1 60); do
  if docker exec pos_api_prod curl -sf http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "API healthy"
    break
  fi
  sleep 2
done
docker compose -f docker-compose.prod.yml ps
rm -f /tmp/deploy-pack.tar.gz
"@
  & ssh @ssh $remote
}

Remove-Item (Join-Path $root "deploy-pack.tar.gz") -ErrorAction SilentlyContinue

Write-Host "`nDeploy complete." -ForegroundColor Green
Write-Host "  Admin:       https://pos.myvnc.com/"
Write-Host "  Marketplace: https://pos.myvnc.com/market/"
Write-Host "  Shopping:    https://pos.myvnc.com/shopping/"
Write-Host "  Readme:      https://pos.myvnc.com/readme/"
Write-Host "  Customer:    https://pos.myvnc.com/customer/"
Write-Host "  Web POS:     https://pos.myvnc.com/pos/"
Write-Host "  APK:      https://pos.myvnc.com/readme/pos-release.apk"
Write-Host "  Windows:  https://pos.myvnc.com/readme/pos-release-windows.zip"
