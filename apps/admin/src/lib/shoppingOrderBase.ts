/**
 * Base URL for unified shopping SPA links (no trailing slash on the SPA root).
 *
 * Priority: `VITE_SHOPPING_BASE_URL` → same-origin `/shopping` on non-local host → `/shopping` path.
 */
export function shoppingOrderBaseUrl(): string {
  const fromEnv = import.meta.env.VITE_SHOPPING_BASE_URL?.trim()
  if (fromEnv) return fromEnv.replace(/\/+$/, '')

  if (typeof window !== 'undefined') {
    const { hostname, origin } = window.location
    const isLocal =
      hostname === 'localhost' || hostname === '127.0.0.1' || hostname.endsWith('.local')
    if (!isLocal) return `${origin}/shopping`
  }

  // Local admin → assume shopping SPA is reverse-proxied or use relative path via origin.
  if (typeof window !== 'undefined') return `${window.location.origin}/shopping`
  return '/shopping'
}

export function shoppingOrderUrl(storeId: string, mode?: string): string {
  const qs = new URLSearchParams({ store: storeId })
  if (mode) qs.set('mode', mode)
  return `${shoppingOrderBaseUrl()}/?${qs.toString()}`
}
