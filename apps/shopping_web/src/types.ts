export type FulfillmentMode = 'dinein' | 'takeout' | 'delivery'

export type PaymentUiKey = 'linepay' | 'card' | 'cash'

export interface PublicOptionChoice {
  id: string
  name: string
  price_delta_cents: number
  is_default: boolean
  soldout?: boolean
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

export interface SelectedOption {
  group_id: string
  group_name: string
  choice_id: string
  choice_name: string
  price_delta_cents: number
}

export interface StoreInfo {
  slug: string
  name: string
  addr: string
  deliveryOn: boolean
  deliveryFeeCents: number
  deliveryMinCents: number
  supportsPickup: boolean
  supportsDelivery: boolean
  supportsDineIn: boolean
  paymentCounter: boolean
  paymentOnline: boolean
  isOpen: boolean
  prepTimeMin: number
}

export interface MenuCategory {
  id: string
  name: string
  en: string
  sortOrder: number
}

export interface MenuProduct {
  id: string
  categoryId: string
  categoryName: string
  name: string
  description: string | null
  priceCents: number
  imageUrl: string | null
  iconKey: string
  soldout: boolean
  noDelivery: boolean
  tags: Array<'rec' | 'hot' | 'veg'>
  optionGroups: PublicOptionGroup[]
}

export interface ShoppingMenu {
  store: StoreInfo
  categories: MenuCategory[]
  products: MenuProduct[]
  isDemo: boolean
}

export interface CartLine {
  key: string
  productId: string
  name: string
  qty: number
  unitCents: number
  options: SelectedOption[]
  optionsLabel: string
  note: string
  noDelivery: boolean
}

export interface MarketplaceOrderCreated {
  order_id: string
  access_token: string
  payment_method: string
  payment_status: string | null
  estimated_subtotal_cents: number
}

export interface SubmitOrderPayload {
  fulfillment_type: string
  payment_method: string
  customer_name: string
  customer_phone: string
  customer_note?: string | null
  party_size?: number | null
  delivery_address?: string | null
  delivery_note?: string | null
  table_label?: string | null
  lines: {
    product_id: string
    qty: number
    note?: string | null
    options?: SelectedOption[]
  }[]
}

export interface DoneSnapshot {
  mode: FulfillmentMode
  table: string
  pickTime: string
  address: string
  phone: string
  payment: PaymentUiKey
  memberOn: boolean
  orderId: string | null
  accessToken: string | null
  pickupNo: string
  lines: CartLine[]
  subtotalCents: number
  deliveryFeeCents: number
  discountCents: number
  totalCents: number
  storeName: string
  isDemo: boolean
  paidOnline: boolean
}
