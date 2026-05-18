#Requires -Version 5.1
<#
.SYNOPSIS
  不透過 Android Studio，直接啟動 Android 模擬器並確保 adb 在跑。

.DESCRIPTION
  - 使用 ANDROID_SDK_ROOT / ANDROID_HOME；若未設定則使用預設本機 SDK 路徑。
  - 若指定的 AVD 已在線上，會略過重複啟動。
  - 預設用快照快速開機；若常卡住成 offline，可加 -ColdBoot。

.EXAMPLE
  .\start_android_emulator.ps1
  .\start_android_emulator.ps1 -Avd Pixel_8
  .\start_android_emulator.ps1 -ColdBoot
  .\start_android_emulator.ps1 -NoWait
#>
param(
  [string] $Avd = "Medium_Tablet",
  [switch] $ColdBoot,
  [switch] $NoWait,
  [string] $SdkRoot = $(if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "" })
)

$ErrorActionPreference = "Stop"

if (-not $SdkRoot) {
  $SdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
}

$adb = Join-Path $SdkRoot "platform-tools\adb.exe"
$emulator = Join-Path $SdkRoot "emulator\emulator.exe"

if (-not (Test-Path $adb)) {
  Write-Error "找不到 adb：$adb`n請設定 ANDROID_SDK_ROOT 或安裝 Android SDK platform-tools。"
  exit 1
}
if (-not (Test-Path $emulator)) {
  Write-Error "找不到 emulator.exe：$emulator`n請在 SDK Manager 安裝 Android Emulator。"
  exit 1
}

function Get-EmulatorSerialsOnline {
  $out = & $adb devices 2>&1
  foreach ($line in $out) {
    if ($line -match "^(emulator-\d+)\s+device\s*$") {
      $Matches[1]
    }
  }
}

function Get-RunningAvdName {
  param([string] $Serial)
  $n = (& $adb -s $Serial emu avd name 2>$null | Out-String).Trim()
  if ($n) { return $n }
  foreach ($key in @("ro.boot.qemu.avd_name", "ro.kernel.qemu.avd_name")) {
    $n = (& $adb -s $Serial shell "getprop $key" 2>$null | Out-String).Trim()
    if ($n) { return $n }
  }
  return ""
}

function Test-AvdAlreadyRunning {
  param([string] $TargetAvd)
  foreach ($serial in (Get-EmulatorSerialsOnline)) {
    if ((Get-RunningAvdName -Serial $serial) -eq $TargetAvd) {
      return $serial
    }
  }
  return $null
}

Write-Host "SDK：$SdkRoot"
& $adb start-server | Out-Null
Write-Host "adb 伺服器已啟動。"

$existing = Test-AvdAlreadyRunning -TargetAvd $Avd
if ($existing) {
  Write-Host "AVD「$Avd」已在執行（$existing），無需再開。"
  & $adb devices -l
  exit 0
}

$emuArgs = @("-avd", $Avd, "-no-boot-anim")
if ($ColdBoot) {
  $emuArgs += "-no-snapshot-load"
  Write-Host "冷啟動模式（略過快照，較慢但較不易卡 offline）。"
}

Write-Host "正在啟動模擬器：$Avd …"
Start-Process -FilePath $emulator -ArgumentList $emuArgs -WindowStyle Normal

if ($NoWait) {
  Write-Host "已送出啟動指令（-NoWait：不等待 adb 顯示 device）。"
  exit 0
}

Write-Host "等待 adb 狀態變為 device（最多約 4 分鐘）…"
$deadline = (Get-Date).AddMinutes(4)
$seenSerial = $null
do {
  Start-Sleep -Seconds 3
  foreach ($serial in (Get-EmulatorSerialsOnline)) {
    if ((Get-RunningAvdName -Serial $serial) -eq $Avd) {
      $seenSerial = $serial
      break
    }
  }
  if ($seenSerial) { break }
  $devs = (& $adb devices 2>&1 | Out-String).Trim()
  Write-Host ("  … " + ($devs -replace "`r`n", " | "))
} while ((Get-Date) -lt $deadline)

if (-not $seenSerial) {
  Write-Warning "逾時仍未偵測到「$Avd」為 device。請看模擬器視窗是否報錯，或改試 -ColdBoot。"
  & $adb devices -l
  exit 2
}

Write-Host "已上線：$seenSerial（$Avd）"
& $adb devices -l
exit 0
