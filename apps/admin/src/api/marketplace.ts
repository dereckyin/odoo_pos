import client from './client'

export interface MarketplaceListing {
  id: string
  tenant_id: string
  store_id: string
  slug: string
  status: string
  display_name: string
  tagline: string | null
  logo_url: string | null
  banner_url: string | null
  cuisine_tags: string[] | null
  min_order_cents: number
  delivery_fee_cents: number
  delivery_radius_km: number | null
  supports_pickup: boolean
  supports_delivery: boolean
  supports_dine_in: boolean
  payment_counter: boolean
  payment_online: boolean
  business_hours: Record<string, { open: string; close: string }[]> | null
  prep_time_min: number
  rating_avg: number
  rating_count: number
  approved_at: string | null
  submitted_at: string | null
  created_at: string
  updated_at: string
}

export interface MarketplaceListingUpdate {
  display_name?: string
  tagline?: string | null
  logo_url?: string | null
  banner_url?: string | null
  cuisine_tags?: string[] | null
  min_order_cents?: number
  delivery_fee_cents?: number
  delivery_radius_km?: number | null
  supports_pickup?: boolean
  supports_delivery?: boolean
  supports_dine_in?: boolean
  payment_counter?: boolean
  payment_online?: boolean
  business_hours?: Record<string, { open: string; close: string }[]> | null
  prep_time_min?: number
}

export function listListings() {
  return client.get<MarketplaceListing[]>('/marketplace/listings')
}

export function getListing(storeId: string) {
  return client.get<MarketplaceListing | null>('/marketplace/listing', { params: { store_id: storeId } })
}

export function createListing(storeId: string, displayName: string) {
  return client.post<MarketplaceListing>('/marketplace/listings', {
    store_id: storeId,
    display_name: displayName,
  })
}

export function updateListing(id: string, payload: MarketplaceListingUpdate) {
  return client.patch<MarketplaceListing>(`/marketplace/listing/${id}`, payload)
}

export function submitListing(id: string) {
  return client.post<MarketplaceListing>(`/marketplace/listing/${id}/submit`)
}

export interface MarketplaceFeedCategoryOption {
  id: string
  slug: string
  name: string
  icon: string | null
}

export function listFeedCategories() {
  return client.get<MarketplaceFeedCategoryOption[]>('/marketplace/feed-categories')
}
