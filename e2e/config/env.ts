import { config as loadDotenv } from 'dotenv'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
loadDotenv({ path: resolve(__root, '.env') })

function req(name: string, fallback?: string): string {
  const v = process.env[name]?.trim() || fallback
  if (!v) throw new Error(`Missing required env: ${name}`)
  return v
}

function opt(name: string, fallback = ''): string {
  return process.env[name]?.trim() || fallback
}

const baseUrl = opt('BASE_URL', 'https://pos.myvnc.com').replace(/\/$/, '')

export const env = {
  baseUrl,
  apiUrl: `${baseUrl}/api`,

  posBaseUrl: `${baseUrl}/pos/`,
  customerBaseUrl: `${baseUrl}/customer/`,
  adminBaseUrl: `${baseUrl}/`,

  tenantCode: opt('POS_TENANT_CODE', 'demo'),
  storeCode: opt('POS_STORE_CODE', 'S001'),
  terminalCode: opt('POS_TERMINAL_CODE', 'T01'),
  terminalApiKey: opt('POS_TERMINAL_API_KEY'),

  cashierUser: opt('POS_CASHIER_USER', 'cashier'),
  cashierPassword: opt('POS_CASHIER_PASSWORD', 'cashier123'),

  adminUser: opt('ADMIN_USER', 'admin'),
  adminPassword: opt('ADMIN_PASSWORD', 'admin123'),

  kitchenUser: opt('KITCHEN_USER', 'kitchen'),
  kitchenPassword: opt('KITCHEN_PASSWORD'),
} as const

export function requireTerminalApiKey(): string {
  return req('POS_TERMINAL_API_KEY', env.terminalApiKey)
}
