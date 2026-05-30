import axios from 'axios'
import type { GuestOrderRead, PublicMenu } from './types'

const apiBase = (import.meta.env.VITE_API_BASE || '/api').replace(/\/+$/, '')

export const http = axios.create({
  baseURL: apiBase,
  timeout: 20_000,
})

export function fetchMenu(token: string) {
  return http.get<PublicMenu>(`/public/menu/${encodeURIComponent(token)}`)
}

export function submitOrder(
  token: string,
  payload: {
    customer_note?: string | null
    party_size?: number | null
    member_id?: string | null
    lines: { product_id: string; qty: number; note?: string | null }[]
  },
) {
  return http.post<GuestOrderRead>(
    `/public/orders/${encodeURIComponent(token)}`,
    payload,
  )
}

export function requestMemberOtp(tableToken: string, phone: string) {
  return http.post<{ ok: boolean; dev_code?: string }>('/public/members/otp/request', {
    table_token: tableToken,
    phone,
  })
}

export function verifyMemberOtp(tableToken: string, phone: string, code: string) {
  return http.post<{ id: string; name: string; phone: string; points: number; level_id: string | null }>(
    '/public/members/otp/verify',
    { table_token: tableToken, phone, code },
  )
}

export function fetchOrderStatus(token: string, orderId: string) {
  return http.get<GuestOrderRead>(
    `/public/orders/${encodeURIComponent(token)}/${encodeURIComponent(orderId)}`,
  )
}

/** 後端若在 DB 存 `/uploads/...` 相對路徑；當 VITE_API_BASE 為絕對網址時要補上 API 站點 origin，瀏覽器才載得到圖。 */
export function resolveUploadPath(url: string): string {
  if (!url.startsWith('/uploads')) return url
  const apiBase = (import.meta.env.VITE_API_BASE || '/api').replace(/\/+$/, '')
  if (!apiBase.startsWith('http')) return url
  try {
    return new URL(apiBase).origin + url
  } catch {
    return url
  }
}

