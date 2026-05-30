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
  root_category_ids: string[]
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
  options_json?: SelectedOption[] | null
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
