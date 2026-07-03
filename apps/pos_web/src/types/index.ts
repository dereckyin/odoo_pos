export interface SessionRead {
  user_id: string
  username: string
  display_name: string
  role: string
  tenant_id: string | null
  tenant_code: string | null
  store_id: string | null
  terminal_id: string | null
  access_token: string
  refresh_token: string
  expires_at: number
  must_change_password?: boolean
}

export interface Category {
  id: string
  name: string
  parent_id: string | null
  sort_order: number
  color: string | null
  hide_from_pos_browse: boolean
}

export interface Product {
  id: string
  sku: string
  name: string
  price_cents: number
  category_id: string | null
  image_url: string | null
  tax_rate: number
  is_active: boolean
  hide_from_pos_browse: boolean
  print_label: boolean
  barcodes: string[]
}

export interface OptionChoice {
  id: string
  name: string
  price_delta_cents: number
  is_default: boolean
  sort_order: number
  is_active: boolean
}

export interface OptionGroup {
  id: string
  name: string
  selection_type: string
  is_required: boolean
  min_selections: number
  max_selections: number | null
  sort_order: number
  choices: OptionChoice[]
}

export interface ProductOptionLink {
  option_group_id: string
  sort_order: number
  is_required: boolean | null
}

export interface ProductOptionOverride {
  option_choice_id: string
  price_delta_cents: number | null
  is_hidden: boolean
}

export interface ProductWithOptions extends Product {
  option_groups: OptionGroup[]
}

export interface SelectedOption {
  group_id: string
  group_name: string
  choice_id: string
  choice_name: string
  price_delta_cents: number
}

export interface ShiftRead {
  id: string
  status: string
  opening_cash_cents: number
  opened_at: string | null
}

export interface GuestOrderLine {
  id: string
  product_id: string
  product_name: string
  qty: number
  line_total_cents: number
  note: string | null
  options_json: SelectedOption[] | null
}

export interface GuestOrder {
  id: string
  store_id: string
  table_id: string | null
  table_label: string | null
  status: string
  customer_note: string | null
  party_size: number | null
  estimated_subtotal_cents: number
  created_at: string
  lines: GuestOrderLine[]
}

export interface DiningTable {
  id: string
  label: string
  store_id: string
  is_active: boolean
}

export interface TableSessionOpen {
  session: { id: string; session_token: string; expires_at: string | null }
  table_label: string
  customer_order_url: string
}

export interface InvoiceRead {
  id: string
  order_id: string
  status: string
  invoice_number: string | null
  invoice_date: string | null
  total_cents: number
  tax_cents: number
  tax_type: number
  random_code: string | null
  barcode: string | null
  qr_left: string | null
  qr_right: string | null
}

export type DiscountType = 'none' | 'percentage' | 'amount'
