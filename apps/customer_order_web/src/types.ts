export interface PublicCategory {
  id: string
  name: string
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
}

export interface PublicMeta {
  table_id: string
  table_label: string
  store_id: string
  store_name: string
  store_address: string | null
}

export interface PublicMenu {
  meta: PublicMeta
  categories: PublicCategory[]
  products: PublicProduct[]
}

export interface GuestOrderLineRead {
  id: string
  product_id: string
  product_name: string
  sku: string
  qty: number
  unit_price_cents: number
  line_total_cents: number
  note: string | null
  created_at: string
}

export interface GuestOrderRead {
  id: string
  store_id: string
  table_id: string
  table_label: string | null
  status: 'submitted' | 'accepted' | 'ready' | 'merged' | 'cancelled'
  customer_note: string | null
  party_size: number | null
  estimated_subtotal_cents: number
  accepted_at: string | null
  ready_at: string | null
  merged_at: string | null
  cancelled_at: string | null
  cancel_reason: string | null
  created_at: string
  updated_at: string
  lines: GuestOrderLineRead[]
}
