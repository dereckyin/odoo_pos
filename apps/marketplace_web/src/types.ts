export interface PublicOptionChoice {
  id: string
  name: string
  price_delta_cents: number
  is_default: boolean
}

export interface PublicOptionGroup {
  id: string
  name: string
  selection_type: 'single' | 'multi'
  is_required: boolean
  min_selections: number
  max_selections: number | null
  sort_order: number
  choices: PublicOptionChoice[]
}

export interface PublicCategory {
  id: string
  name: string
  parent_id: string | null
  depth: number
  path_label: string
  sort_order: number
  color: string | null
  icon: string | null
}

export interface PublicProduct {
  id: string
  sku: string
  name: string
  price_cents: number
  category_id: string | null
  image_url: string | null
  unit: string
  description: string | null
  option_groups: PublicOptionGroup[]
}

export interface SelectedOption {
  group_id: string
  group_name: string
  choice_id: string
  choice_name: string
  price_delta_cents: number
}

export interface MarketplaceStoreSummary {
  slug: string
  display_name: string
  tagline: string | null
  logo_url: string | null
  banner_url: string | null
  cuisine_tags: string[]
  min_order_cents: number
  delivery_fee_cents: number
  supports_pickup: boolean
  supports_delivery: boolean
  supports_dine_in: boolean
  payment_counter: boolean
  payment_online: boolean
  store_address: string | null
  latitude: number | null
  longitude: number | null
  distance_km: number | null
  is_open: boolean
}

export interface MarketplaceStoreDetail extends MarketplaceStoreSummary {
  store_id: string
  business_hours: Record<string, { open: string; close: string }[]> | null
}

export interface MarketplaceMenuMeta {
  slug: string
  display_name: string
  tagline: string | null
  logo_url: string | null
  store_id: string
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

export interface MarketplaceMenu {
  meta: MarketplaceMenuMeta
  categories: PublicCategory[]
  root_category_ids: string[]
  products: PublicProduct[]
}

export interface MarketplaceProductCard {
  product_id: string
  product_name: string
  price_cents: number
  image_url: string | null
  description: string | null
  has_options: boolean
  feed_category_id: string
  feed_category_name: string
  store_slug: string
  store_name: string
  logo_url: string | null
  store_is_open: boolean
}

export interface MarketplaceProductSearchHit extends MarketplaceProductCard {}

export interface MarketplaceFeedCategory {
  id: string
  slug: string
  name: string
  icon: string | null
  product_count: number
}

export interface MarketplaceProductFeedSection {
  category_id: string
  category_slug: string
  category_name: string
  icon: string | null
  products: MarketplaceProductCard[]
}

export interface MarketplaceProductFeed {
  sections: MarketplaceProductFeedSection[]
}

export interface MarketplaceOrderLineRead {
  id: string
  product_id: string
  product_name: string
  sku: string
  qty: number
  unit_price_cents: number
  line_total_cents: number
  note: string | null
  options_json?: SelectedOption[] | null
}

export interface MarketplaceOrderRead {
  id: string
  status: string
  channel: string
  fulfillment_type: string | null
  payment_method: string | null
  payment_status: string | null
  delivery_status: string | null
  customer_name: string | null
  customer_phone: string | null
  delivery_address: string | null
  store_name: string
  store_slug: string
  estimated_subtotal_cents: number
  customer_note: string | null
  party_size: number | null
  created_at: string
  accepted_at: string | null
  ready_at: string | null
  merged_at: string | null
  cancelled_at: string | null
  lines: MarketplaceOrderLineRead[]
}

export interface MarketplaceOrderCreated {
  order_id: string
  access_token: string
  payment_method: string
  payment_status: string | null
  estimated_subtotal_cents: number
}

export interface PublicMember {
  id: string
  name: string
  phone: string
  points: number
  level_id: string | null
}
