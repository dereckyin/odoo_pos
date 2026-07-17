import axios from 'axios'
import type { MarketplaceOrderCreated, SubmitOrderPayload } from './types'

const baseURL = import.meta.env.VITE_API_BASE || '/api'

export const client = axios.create({ baseURL, timeout: 30000 })

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

export function fetchStore(slug: string) {
  return client.get<ApiStoreDetail>(`/public/marketplace/stores/${slug}`)
}

export function fetchStoreMenu(slug: string) {
  return client.get<ApiMenu>(`/public/marketplace/stores/${slug}/menu`)
}

export function submitOrder(slug: string, payload: SubmitOrderPayload) {
  return client.post<MarketplaceOrderCreated>(`/public/marketplace/stores/${slug}/orders`, payload)
}

export function fetchOrderStatus(orderId: string, accessToken: string) {
  return client.get(`/public/marketplace/orders/${orderId}`, {
    params: { access_token: accessToken },
  })
}
