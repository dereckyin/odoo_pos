import axios from 'axios'
import type {
  MarketplaceBanner,
  MarketplaceFeedCategory,
  MarketplaceMenu,
  MarketplaceOrderCreated,
  MarketplaceOrderRead,
  MarketplaceProductCard,
  MarketplaceProductFeed,
  MarketplaceProductSearchHit,
  MarketplaceStoreDetail,
  MarketplaceStoreReviews,
  MarketplaceStoreSummary,
  MemberCoupon,
  MemberProfile,
  PointsSummary,
  PublicMember,
  ReferralInfo,
  WalletRead,
} from './types'

const baseURL = import.meta.env.VITE_API_BASE || '/api'

export const client = axios.create({ baseURL, timeout: 30000 })

// Attach the unified marketplace member token when present. Read lazily to
// avoid a circular import with the Pinia store.
let memberTokenGetter: () => string | null = () => null
export function registerMemberTokenGetter(fn: () => string | null) {
  memberTokenGetter = fn
}
client.interceptors.request.use((config) => {
  const token = memberTokenGetter()
  if (token) {
    config.headers = config.headers ?? {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

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
  sort?: string
  price_level?: string
  open_now?: boolean
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

export function fetchBanners() {
  return client.get<MarketplaceBanner[]>('/public/marketplace/banners')
}

export function fetchPopularProducts(params?: { fulfillment?: string; limit?: number }) {
  return client.get<MarketplaceProductCard[]>('/public/marketplace/popular-products', { params })
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
    store_slug: storeSlug || null,
    phone,
  })
}

export function verifyMemberOtp(storeSlug: string, phone: string, code: string, name?: string) {
  return client.post<PublicMember>('/public/members/otp/verify', {
    store_slug: storeSlug || null,
    phone,
    code,
    name: name || null,
  })
}

// --- Multi-store checkout ---
export interface BatchStoreCart {
  store_slug: string
  fulfillment_type: string
  payment_method: string
  delivery_address?: string | null
  delivery_lat?: number | null
  delivery_lng?: number | null
  delivery_note?: string | null
  table_label?: string | null
  party_size?: number | null
  store_note?: string | null
  points_redeemed?: number
  coupon_code?: string | null
  lines: SubmitOrderPayload['lines']
}
export interface BatchOrderItem {
  order_id: string
  access_token: string
  store_slug: string
  store_name: string
  payment_method: string
  payment_status: string | null
  estimated_subtotal_cents: number
}
export interface BatchOrderCreated {
  order_group_id: string
  orders: BatchOrderItem[]
  total_cents: number
}
export function submitBatchOrder(payload: {
  customer_name: string
  customer_phone: string
  carts: BatchStoreCart[]
}) {
  return client.post<BatchOrderCreated>('/public/marketplace/orders/batch', payload)
}

export function fetchOrderGroup(groupId: string) {
  return client.get<MarketplaceOrderRead[]>(`/public/marketplace/order-groups/${groupId}`)
}

// --- Reviews ---
export function fetchStoreReviews(slug: string) {
  return client.get<MarketplaceStoreReviews>(`/public/marketplace/stores/${slug}/reviews`)
}
export function submitReview(payload: {
  order_id: string
  access_token: string
  rating: number
  comment?: string | null
}) {
  return client.post('/public/marketplace/reviews', payload)
}

// --- Member center (requires member token) ---
export function fetchMyProfile() {
  return client.get<MemberProfile>('/public/members/me')
}
export function fetchMyOrders() {
  return client.get<MarketplaceOrderRead[]>('/public/members/me/orders')
}
export function fetchMyPoints() {
  return client.get<PointsSummary>('/public/members/me/points')
}
export function fetchMyCoupons() {
  return client.get<MemberCoupon[]>('/public/members/me/coupons')
}
export function fetchMyFavorites() {
  return client.get<MarketplaceStoreSummary[]>('/public/members/me/favorites')
}
export function toggleFavorite(slug: string, on: boolean) {
  if (on) return client.post('/public/members/me/favorites', { store_slug: slug })
  return client.delete(`/public/members/me/favorites/${slug}`)
}
export function fetchMyWallet() {
  return client.get<WalletRead>('/public/members/me/wallet')
}
export function topupWallet(amountCents: number) {
  return client.post<WalletRead>('/public/members/me/wallet/topup', { amount_cents: amountCents })
}
export function fetchMyReferral() {
  return client.get<ReferralInfo>('/public/members/me/referral')
}
export function applyReferral(code: string) {
  return client.post<ReferralInfo>('/public/members/me/referral/apply', { code })
}
export function updateMyProfile(payload: { name?: string | null; birthday?: string | null }) {
  return client.patch<MemberProfile>('/public/members/me', payload)
}
