# 相容舊用法；實際邏輯在 sync-readme.mjs（admin prebuild 也會自動執行）
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
node (Join-Path $root "scripts/sync-readme.mjs")
