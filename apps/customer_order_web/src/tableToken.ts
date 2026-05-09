import type { RouteLocationNormalizedLoaded } from 'vue-router'

/** 從 QR／網址上的 `?t=` 讀取桌位 public_token（兼顧 Vue Router 將重複鍵回傳為 string[] 的情況）。 */
export function tableTokenFromRoute(route: RouteLocationNormalizedLoaded): string {
  const q = route.query.t
  if (Array.isArray(q)) {
    const first = q[0]
    return first != null && first !== '' ? String(first) : ''
  }
  if (q == null || q === '') return ''
  return String(q)
}
