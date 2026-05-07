export interface SessionRead {
  user_id: string
  username: string
  display_name: string
  role: string
  store_id: string
  terminal_id: string
  access_token: string
  refresh_token: string
  expires_at: number
}

export interface CategoryRead {
  id: string
  name: string
  parent_id: string | null
  sort_order: number
  color: string | null
  icon: string | null
  updated_at: string
  deleted_at: string | null
}

export interface CategoryCreate {
  name: string
  parent_id?: string | null
  sort_order?: number
  color?: string | null
  icon?: string | null
}

export type CategoryUpdate = Partial<CategoryCreate>

export interface ProductRead {
  id: string
  sku: string
  name: string
  price_cents: number
  cost_cents: number | null
  category_id: string | null
  image_url: string | null
  tax_rate: number
  is_weighted: boolean
  unit: string
  is_active: boolean
  description: string | null
  barcodes: string[]
  updated_at: string
  deleted_at: string | null
}

export interface ProductCreate {
  sku: string
  name: string
  price_cents: number
  cost_cents?: number | null
  category_id?: string | null
  image_url?: string | null
  tax_rate?: number
  is_weighted?: boolean
  unit?: string
  is_active?: boolean
  description?: string | null
  barcodes?: string[]
}

export type ProductUpdate = Partial<ProductCreate>

export interface PromotionRead {
  id: string
  name: string
  strategy: string
  config: Record<string, any>
  priority: number
  starts_at: string | null
  ends_at: string | null
  is_active: boolean
  stackable: boolean
  applicable_product_ids: string[]
  applicable_category_ids: string[]
  member_level_ids: string[]
  description: string | null
  updated_at: string
  deleted_at: string | null
}

export interface PromotionCreate {
  name: string
  strategy: string
  config?: Record<string, any>
  priority?: number
  starts_at?: string | null
  ends_at?: string | null
  is_active?: boolean
  stackable?: boolean
  applicable_product_ids?: string[]
  applicable_category_ids?: string[]
  member_level_ids?: string[]
  description?: string | null
}

export type PromotionUpdate = Partial<PromotionCreate>

export interface MemberLevelRead {
  id: string
  name: string
  discount_rate: number
  min_spend: number
  min_points: number
  color: string | null
  sort_order: number
}

export interface MemberLevelCreate {
  name: string
  discount_rate?: number
  min_spend?: number
  min_points?: number
  color?: string | null
  sort_order?: number
}

export interface MemberRead {
  id: string
  phone: string
  name: string
  email: string | null
  birthday: string | null
  points: number
  total_spent_cents: number
  level_id: string | null
  qr_code: string | null
  joined_at: string
  last_visit_at: string | null
  note: string | null
  updated_at: string
  deleted_at: string | null
}

export interface MemberCreate {
  phone: string
  name: string
  email?: string | null
  birthday?: string | null
  points?: number
  level_id?: string | null
  qr_code?: string | null
  note?: string | null
}

export type MemberUpdate = Partial<MemberCreate>

export interface CouponRead {
  id: string
  code: string
  type: string
  value: number
  member_id: string | null
  min_spend_cents: number
  expires_at: string | null
  used_at: string | null
}

export interface CouponCreate {
  code: string
  type: string
  value: number
  member_id?: string | null
  min_spend_cents?: number
  expires_at?: string | null
}

export interface PointTransactionRead {
  id: string
  member_id: string
  delta: number
  reason: string
  order_id: string | null
  expires_at: string | null
  created_at: string
}

export interface StoreRead {
  id: string
  code: string
  name: string
  tax_id: string | null
  address: string | null
  phone: string | null
  updated_at: string
}

export interface StoreCreate {
  code: string
  name: string
  tax_id?: string | null
  address?: string | null
  phone?: string | null
}

export type StoreUpdate = Partial<StoreCreate>

export interface TerminalRead {
  id: string
  store_id: string
  code: string
  last_seen_at: string | null
}

export interface InventoryLevelRead {
  id: string
  store_id: string
  product_id: string
  on_hand: number
  safety_stock: number
  reserved: number
  updated_at: string
}

export interface TransferRead {
  id: string
  from_store_id: string
  to_store_id: string
  status: string
  dispatched_at: string | null
  received_at: string | null
  note: string | null
  created_at: string
}

export interface StocktakeRead {
  id: string
  store_id: string
  completed_at: string | null
  note: string | null
  created_at: string
}

export interface OrderLineRead {
  id: string
  product_id: string
  product_name: string
  sku: string
  qty: number
  unit_price_cents: number
  line_discount_cents: number
  line_total_cents: number
  tax_rate: number
  note: string | null
}

export interface PaymentRead {
  id: string
  method: string
  amount_cents: number
  status: string
  gateway_ref: string | null
  tendered_cents: number | null
  change_due_cents: number | null
}

export interface OrderRead {
  id: string
  store_id: string
  terminal_id: string
  cashier_id: string
  member_id: string | null
  status: string
  subtotal_cents: number
  discount_cents: number
  tax_cents: number
  total_cents: number
  refunded_cents: number
  invoice_number: string | null
  invoice_carrier: string | null
  note: string | null
  created_at: string
  client_created_at: string | null
  lines: OrderLineRead[]
  payments: PaymentRead[]
}

export interface UserRead {
  id: string
  username: string
  display_name: string
  role: string
  store_id: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface UserCreate {
  username: string
  password: string
  display_name: string
  role: string
  store_id?: string | null
  is_active?: boolean
}

export interface UserUpdate {
  display_name?: string
  role?: string
  store_id?: string | null
  is_active?: boolean
  password?: string
}

export interface Paginated<T> {
  items: T[]
  total: number
}
