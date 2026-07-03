import type { APIRequestContext } from '@playwright/test'
import { env } from '../config/env.js'
import { apiUrl } from './api-url.js'

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

let cachedAdminToken: string | null = null

export function getCachedAdminToken(): string | null {
  return process.env.E2E_ADMIN_TOKEN?.trim() || cachedAdminToken
}

export function setCachedAdminToken(token: string) {
  cachedAdminToken = token
  process.env.E2E_ADMIN_TOKEN = token
}

export interface PosSession {
  access_token: string
  refresh_token: string
  user_id: string
  store_id: string
  terminal_id: string
  username: string
  display_name: string
}

export async function apiPosLogin(
  request: APIRequestContext,
  apiKey: string,
  username = env.cashierUser,
  password = env.cashierPassword,
): Promise<PosSession> {
  const res = await request.post(apiUrl('/auth/login'), {
    data: {
      tenant_code: env.tenantCode,
      store_code: env.storeCode,
      terminal_code: env.terminalCode,
      terminal_api_key: apiKey,
      username,
      password,
    },
  })
  if (!res.ok()) {
    throw new Error(`POS API login failed: ${res.status()} ${await res.text()}`)
  }
  return res.json()
}

export async function apiAdminLogin(
  request: APIRequestContext,
  username = env.adminUser,
  password = env.adminPassword,
): Promise<PosSession> {
  const cached = getCachedAdminToken()
  if (cached) {
    return {
      access_token: cached,
      refresh_token: '',
      user_id: '',
      store_id: '',
      terminal_id: '',
      username,
      display_name: '',
    }
  }

  let lastError = 'unknown'
  for (let attempt = 0; attempt < 4; attempt++) {
    const res = await request.post(apiUrl('/auth/admin-login'), {
      data: {
        tenant_code: env.tenantCode,
        username,
        password,
      },
    })
    if (res.ok()) {
      const session = (await res.json()) as PosSession
      setCachedAdminToken(session.access_token)
      return session
    }
    lastError = `${res.status()} ${await res.text()}`
    if (res.status() === 429 && attempt < 3) {
      await sleep(1500 * (attempt + 1))
      continue
    }
    break
  }
  throw new Error(`Admin API login failed: ${lastError}`)
}

export async function fetchCurrentShift(request: APIRequestContext, token: string) {
  const res = await request.get(apiUrl('/shifts/current'), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok()) return null
  const data = await res.json()
  return data as Record<string, unknown> | null
}

export async function openShift(request: APIRequestContext, token: string) {
  const res = await request.post(apiUrl('/shifts/open'), {
    headers: { Authorization: `Bearer ${token}` },
    data: { opening_cash_cents: 0 },
  })
  if (!res.ok()) {
    throw new Error(`Open shift failed: ${res.status()} ${await res.text()}`)
  }
  return res.json()
}

export async function ensureShiftOpen(request: APIRequestContext, token: string) {
  const current = await fetchCurrentShift(request, token)
  if (current?.id) return current
  return openShift(request, token)
}

export async function listTables(request: APIRequestContext, token: string, storeId: string) {
  const res = await request.get(apiUrl(`/dining-tables?store_id=${storeId}`), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok()) {
    throw new Error(`List tables failed: ${res.status()} ${await res.text()}`)
  }
  return res.json() as Promise<Array<{ id: string; label: string; is_active: boolean }>>
}

export async function openTableSession(request: APIRequestContext, token: string, tableId: string) {
  const res = await request.post(apiUrl(`/dining-tables/${tableId}/sessions`), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok()) {
    throw new Error(`Open table session failed: ${res.status()} ${await res.text()}`)
  }
  return res.json() as Promise<{
    customer_order_url: string
    table_label: string
    session: { session_token: string }
  }>
}

export function onlineOrderingEnabled(): boolean {
  return process.env.E2E_ONLINE_ORDERING !== 'false'
}

export interface ProductRead {
  id: string
  name: string
  sku: string
  price_cents: number
  is_active: boolean
  barcodes: string[]
  hide_from_pos_browse?: boolean
  description?: string | null
  category_id?: string | null
}

export async function apiListProducts(
  request: APIRequestContext,
  token: string,
  params?: { q?: string; is_active?: boolean },
): Promise<ProductRead[]> {
  const search = new URLSearchParams()
  if (params?.q) search.set('q', params.q)
  if (params?.is_active !== undefined) search.set('is_active', String(params.is_active))
  search.set('limit', '200')
  const qs = search.toString()
  const res = await request.get(apiUrl(`/products${qs ? `?${qs}` : ''}`), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok()) {
    throw new Error(`List products failed: ${res.status()} ${await res.text()}`)
  }
  return res.json()
}

export async function apiGetProduct(request: APIRequestContext, token: string, id: string) {
  const res = await request.get(apiUrl(`/products/${id}`), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok()) return null
  return res.json() as Promise<ProductRead>
}

export async function apiDeleteProduct(request: APIRequestContext, token: string, id: string) {
  const res = await request.delete(apiUrl(`/products/${id}`), {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!res.ok() && res.status() !== 404) {
    throw new Error(`Delete product failed: ${res.status()} ${await res.text()}`)
  }
}

/** Remove leftover e2e products (best-effort cleanup). */
export async function apiCleanupProductsBySkuPrefix(
  request: APIRequestContext,
  token: string,
  skuPrefix: string,
) {
  const products = await apiListProducts(request, token, { q: skuPrefix })
  for (const p of products.filter((x) => x.sku.startsWith(skuPrefix))) {
    await apiDeleteProduct(request, token, p.id)
  }
}
