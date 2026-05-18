/**
 * Base URL for customer QR ordering links (no trailing slash).
 *
 * Priority: `VITE_CUSTOMER_BASE_URL` → same-origin `/customer` on non-local host → dev default.
 */
export function customerOrderBaseUrl(): string {
  const fromEnv = import.meta.env.VITE_CUSTOMER_BASE_URL?.trim()
  if (fromEnv) return fromEnv.replace(/\/+$/, '')

  if (typeof window !== 'undefined') {
    const { hostname, origin } = window.location
    const isLocal =
        hostname === 'localhost' || hostname === '127.0.0.1' || hostname.endsWith('.local')
    if (!isLocal) return `${origin}/customer`
  }

  return 'http://localhost:5174'
}

export function customerOrderUrl(publicToken: string): string {
  return `${customerOrderBaseUrl()}/order?t=${publicToken}`
}
