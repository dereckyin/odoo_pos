import axios from 'axios'
import type {
  MarketplaceFeedCategory,
  MarketplaceMenu,
  MarketplaceOrderCreated,
  MarketplaceOrderRead,
  MarketplaceProductCard,
  MarketplaceProductFeed,
  MarketplaceProductSearchHit,
  MarketplaceStoreDetail,
  MarketplaceStoreSummary,
  PublicMember,
} from './types'

const baseURL = import.meta.env.VITE_API_BASE || '/api'

export const client = axios.create({ baseURL, timeout: 30000 })

export function resolveUploadPath(url: string | null | undefined) {
  if (!url) return ''
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  const apiOrigin = baseURL.replace(/\/api\/?$/, '')
  if (url.startsWith('/uploads')) return `${apiOrigin}${url}`
  return url
}

export function fetchStores(params?: {
  q?: string
  lat?: number
  lng?: number
  cuisine?: string
  fulfillment?: string
}) {
  return client.get<MarketplaceStoreSummary[]>('/public/marketplace/stores', { params })
}

export function fetchStore(slug: string) {
  return client.get<MarketplaceStoreDetail>(`/public/marketplace/stores/${slug}`)
}

export function fetchStoreMenu(slug: string) {
  return client.get<MarketplaceMenu>(`/public/marketplace/stores/${slug}/menu`)
}

export function searchProducts(q: string) {
  return client.get<MarketplaceProductSearchHit[]>('/public/marketplace/search/products', { params: { q } })
}

export function fetchProducts(params?: {
  q?: string
  fulfillment?: string
  cuisine?: string
  category?: string
  limit?: number
  offset?: number
}) {
  return client.get<MarketplaceProductCard[]>('/public/marketplace/products', { params })
}

export function fetchProductsFeed(params?: {
  q?: string
  fulfillment?: string
  cuisine?: string
  category?: string
  limit?: number
}) {
  return client.get<MarketplaceProductFeed>('/public/marketplace/products/feed', { params })
}

export function fetchFeedCategories(params?: { fulfillment?: string; cuisine?: string }) {
  return client.get<MarketplaceFeedCategory[]>('/public/marketplace/feed-categories', { params })
}

export interface SubmitOrderPayload {
  fulfillment_type: string
  payment_method: string
  customer_name: string
  customer_phone: string
  customer_note?: string | null
  party_size?: number | null
  member_id?: string | null
  delivery_address?: string | null
  delivery_lat?: number | null
  delivery_lng?: number | null
  delivery_note?: string | null
  table_label?: string | null
  lines: {
    product_id: string
    qty: number
    note?: string | null
    options?: { group_id: string; group_name: string; choice_id: string; choice_name: string; price_delta_cents: number }[]
  }[]
}

export function submitOrder(slug: string, payload: SubmitOrderPayload) {
  return client.post<MarketplaceOrderCreated>(`/public/marketplace/stores/${slug}/orders`, payload)
}

export function fetchOrderStatus(orderId: string, accessToken: string) {
  return client.get<MarketplaceOrderRead>(`/public/marketplace/orders/${orderId}`, {
    params: { access_token: accessToken },
  })
}

export function initiatePayment(orderId: string, accessToken: string, returnUrl: string) {
  return client.post<{ payment_form_html?: string; payment_url?: string; message?: string }>(
    `/public/marketplace/payments/${orderId}/initiate`,
    null,
    { params: { access_token: accessToken, return_url: returnUrl } },
  )
}

export function requestMemberOtp(storeSlug: string, phone: string) {
  return client.post<{ ok: boolean; dev_code?: string }>('/public/members/otp/request', {
    store_slug: storeSlug,
    phone,
  })
}

export function verifyMemberOtp(storeSlug: string, phone: string, code: string) {
  return client.post<PublicMember>('/public/members/otp/verify', {
    store_slug: storeSlug,
    phone,
    code,
  })
}
