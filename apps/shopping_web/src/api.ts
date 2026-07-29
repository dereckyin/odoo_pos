import axios from 'axios'
import type { MarketplaceOrderCreated, SubmitOrderPayload } from './types'

const baseURL = import.meta.env.VITE_API_BASE || '/api'

export const client = axios.create({ baseURL, timeout: 30000 })

/** Store UUID (shopping channel) vs marketplace slug. */
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

export function isStoreUuid(value: string): boolean {
  return UUID_RE.test(value.trim())
}

export function resolveUploadPath(url: string | null | undefined) {
  if (!url) return ''
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  const apiOrigin = baseURL.replace(/\/api\/?$/, '')
  if (url.startsWith('/uploads')) return `${apiOrigin}${url}`
  return url
}

export interface ApiStoreDetail {
  slug: string
  display_name: string
  store_address: string | null
  supports_pickup: boolean
  supports_delivery: boolean
  supports_dine_in: boolean
  payment_counter: boolean
  payment_online: boolean
  min_order_cents: number
  delivery_fee_cents: number
  is_open: boolean
  prep_time_min: number
}

export interface ShoppingStoreSummary {
  id: string
  name: string
  address: string | null
  phone: string | null
  supports_pickup: boolean
  supports_delivery: boolean
  supports_dine_in: boolean
  payment_counter: boolean
  payment_online: boolean
  min_order_cents: number
  delivery_fee_cents: number
  is_open: boolean
}

export interface ApiOptionChoice {
  id: string
  name: string
  price_delta_cents: number
  is_default: boolean
}

export interface ApiOptionGroup {
  id: string
  name: string
  selection_type: 'single' | 'multi'
  is_required: boolean
  min_selections: number
  max_selections: number | null
  sort_order: number
  choices: ApiOptionChoice[]
}

export interface ApiCategory {
  id: string
  name: string
  sort_order: number
}

export interface ApiProduct {
  id: string
  name: string
  price_cents: number
  category_id: string | null
  image_url: string | null
  description: string | null
  option_groups: ApiOptionGroup[]
}

export interface ApiMenu {
  meta: {
    slug: string
    display_name: string
    store_name: string
    store_address: string | null
    supports_pickup: boolean
    supports_delivery: boolean
    supports_dine_in: boolean
    payment_counter: boolean
    payment_online: boolean
    min_order_cents: number
    delivery_fee_cents: number
    is_open: boolean
  }
  categories: ApiCategory[]
  products: ApiProduct[]
}

export function fetchShoppingStores() {
  return client.get<ShoppingStoreSummary[]>('/public/shopping/stores')
}

export function fetchStore(slugOrId: string) {
  if (isStoreUuid(slugOrId)) {
    return client.get<ShoppingStoreSummary>(`/public/shopping/stores`).then((res) => {
      const hit = res.data.find((s) => s.id === slugOrId)
      if (!hit) {
        const err = new Error('store not found') as Error & { response?: { status: number } }
        err.response = { status: 404 }
        throw err
      }
      return {
        ...res,
        data: {
          slug: hit.id,
          display_name: hit.name,
          store_address: hit.address,
          supports_pickup: hit.supports_pickup,
          supports_delivery: hit.supports_delivery,
          supports_dine_in: hit.supports_dine_in,
          payment_counter: hit.payment_counter,
          payment_online: hit.payment_online,
          min_order_cents: hit.min_order_cents,
          delivery_fee_cents: hit.delivery_fee_cents,
          is_open: hit.is_open,
          prep_time_min: 15,
        } satisfies ApiStoreDetail,
      }
    })
  }
  return client.get<ApiStoreDetail>(`/public/marketplace/stores/${slugOrId}`)
}

export function fetchStoreMenu(slugOrId: string) {
  if (isStoreUuid(slugOrId)) {
    return client.get<ApiMenu>(`/public/shopping/stores/${slugOrId}/menu`)
  }
  return client.get<ApiMenu>(`/public/marketplace/stores/${slugOrId}/menu`)
}

export function submitOrder(slugOrId: string, payload: SubmitOrderPayload) {
  if (isStoreUuid(slugOrId)) {
    return client.post<MarketplaceOrderCreated>(
      `/public/shopping/stores/${slugOrId}/orders`,
      payload,
    )
  }
  return client.post<MarketplaceOrderCreated>(
    `/public/marketplace/stores/${slugOrId}/orders`,
    payload,
  )
}

export function fetchOrderStatus(orderId: string, accessToken: string, storeKey?: string) {
  const path =
    storeKey && isStoreUuid(storeKey)
      ? `/public/shopping/orders/${orderId}`
      : `/public/marketplace/orders/${orderId}`
  return client.get(path, {
    params: { access_token: accessToken },
  })
}
