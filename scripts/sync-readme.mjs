#!/usr/bin/env node
/**
 * Sync pos_doc → apps/admin/public/readme (Vite copies public/ into dist/ on build).
 * Run automatically via apps/admin `prebuild`, or: node scripts/sync-readme.mjs
 */
import fs from 'fs'
import path from 'path'
import { execSync } from 'child_process'
import { fileURLToPath } from 'url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const srcDir = path.join(root, 'pos_doc')
const dstDir = path.join(root, 'apps/admin/public/readme')
const versionPath = path.join(root, 'version.json')

function loadVersion() {
  if (!fs.existsSync(versionPath)) {
    return { displayVersion: 'v?.??', version: '?.??' }
  }
  return JSON.parse(fs.readFileSync(versionPath, 'utf8'))
}

function formatMb(bytes) {
  if (!bytes || bytes <= 0) return '—'
  const mb = bytes / (1024 * 1024)
  return mb >= 10 ? String(Math.round(mb)) : mb.toFixed(1)
}

function applyVersion(html, version, extras = {}) {
  let out = html
    .replaceAll('__APP_VERSION__', version.displayVersion)
    .replaceAll('__APP_VERSION_FULL__', version.version)
  for (const [key, value] of Object.entries(extras)) {
    out = out.replaceAll(key, value)
  }
  return out
}

function zipWindowsRelease(destZip) {
  const releaseDir = path.join(root, 'apps/pos_app/build/windows/x64/runner/Release')
  if (!fs.existsSync(releaseDir)) return null
  const exe = path.join(releaseDir, 'pos_app.exe')
  if (!fs.existsSync(exe)) return null

  fs.mkdirSync(path.dirname(destZip), { recursive: true })
  if (fs.existsSync(destZip)) fs.unlinkSync(destZip)

  const q = (p) => `'${String(p).replace(/'/g, "''")}'`
  if (process.platform === 'win32') {
    execSync(
      `powershell -NoProfile -Command "Compress-Archive -Path (${q(releaseDir + '/*')}) -DestinationPath ${q(destZip)} -Force"`,
      { stdio: 'inherit' },
    )
  } else {
    execSync(`cd ${q(releaseDir)} && zip -qr ${q(destZip)} .`, { stdio: 'inherit', shell: true })
  }
  return fs.statSync(destZip).size
}

if (!fs.existsSync(srcDir)) {
  console.error('pos_doc/ not found')
  process.exit(1)
}

fs.mkdirSync(dstDir, { recursive: true })

let htmlSrc = path.join(srcDir, '系統三大模組.html')
if (!fs.existsSync(htmlSrc)) {
  const fallback = fs.readdirSync(srcDir).find((f) => f.endsWith('.html'))
  if (!fallback) {
    console.error('No HTML file in pos_doc/')
    process.exit(1)
  }
  htmlSrc = path.join(srcDir, fallback)
}

const version = loadVersion()
const extras = { __WINDOWS_ZIP_MB__: '—', __APK_MB__: '76' }

const winZip = path.join(dstDir, 'pos-release-windows.zip')
const winBytes = zipWindowsRelease(winZip)
if (winBytes) {
  extras.__WINDOWS_ZIP_MB__ = formatMb(winBytes)
  console.log(`Included pos-release-windows.zip (${extras.__WINDOWS_ZIP_MB__} MB)`)
} else {
  console.warn('WARN: Windows Release build not found — run `flutter build windows` in apps/pos_app')
}

let html = fs.readFileSync(htmlSrc, 'utf8')
html = applyVersion(html, version, extras)
fs.writeFileSync(path.join(dstDir, 'index.html'), html)

for (const name of fs.readdirSync(srcDir)) {
  if (name.endsWith('.png')) {
    fs.copyFileSync(path.join(srcDir, name), path.join(dstDir, name))
  }
}

const apk = path.join(root, 'apps/pos_app/build/app/outputs/flutter-apk/app-release.apk')
if (fs.existsSync(apk)) {
  const apkDst = path.join(dstDir, 'pos-release.apk')
  fs.copyFileSync(apk, apkDst)
  extras.__APK_MB__ = formatMb(fs.statSync(apkDst).size)
  let indexHtml = fs.readFileSync(path.join(dstDir, 'index.html'), 'utf8')
  indexHtml = applyVersion(indexHtml, version, extras)
  fs.writeFileSync(path.join(dstDir, 'index.html'), indexHtml)
  console.log(`Included pos-release.apk (${extras.__APK_MB__} MB)`)
} else {
  console.warn('WARN: app-release.apk not found — run `flutter build apk` to refresh download link')
}

console.log(`Synced readme → apps/admin/public/readme (${version.displayVersion})`)
