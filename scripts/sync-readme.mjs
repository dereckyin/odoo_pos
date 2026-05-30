#!/usr/bin/env node
/**
 * Sync pos_doc → apps/admin/public/readme (Vite copies public/ into dist/ on build).
 * Run automatically via apps/admin `prebuild`, or: node scripts/sync-readme.mjs
 */
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const srcDir = path.join(root, 'pos_doc')
const dstDir = path.join(root, 'apps/admin/public/readme')

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

fs.copyFileSync(htmlSrc, path.join(dstDir, 'index.html'))

for (const name of fs.readdirSync(srcDir)) {
  if (name.endsWith('.png')) {
    fs.copyFileSync(path.join(srcDir, name), path.join(dstDir, name))
  }
}

const apk = path.join(root, 'apps/pos_app/build/app/outputs/flutter-apk/app-release.apk')
if (fs.existsSync(apk)) {
  fs.copyFileSync(apk, path.join(dstDir, 'pos-release.apk'))
  console.log('Included pos-release.apk in readme bundle')
} else {
  console.warn('WARN: app-release.apk not found — run `flutter build apk` to refresh download link')
}

console.log('Synced readme → apps/admin/public/readme')
