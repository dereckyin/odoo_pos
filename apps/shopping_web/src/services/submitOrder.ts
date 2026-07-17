import { submitOrder as apiSubmit } from '@/api'
import type { CartLine, DoneSnapshot, FulfillmentMode, PaymentUiKey, StoreInfo } from '@/types'

function fulfillmentType(mode: FulfillmentMode): string {
  if (mode === 'dinein') return 'dine_in'
  if (mode === 'delivery') return 'delivery'
  return 'pickup'
}

function paymentMethod(ui: PaymentUiKey, store: StoreInfo): string {
  if (ui === 'cash') return store.paymentCounter ? 'counter' : 'online'
  return store.paymentOnline ? 'online' : 'counter'
}

export async function placeOrder(input: {
  isDemo: boolean
  store: StoreInfo
  mode: FulfillmentMode
  table: string
  pickTime: string
  addrLine: string
  addrPhone: string
  customerName: string
  payMode: PaymentUiKey
  memberOn: boolean
  orderNote: string
  lines: CartLine[]
  subtotalCents: number
  deliveryFeeCents: number
  discountCents: number
  totalCents: number
}): Promise<DoneSnapshot> {
  const paidOnline = input.payMode !== 'cash'
  const pickupNo =
    input.mode === 'takeout'
      ? `T${30 + Math.floor(Math.random() * 60)}`
      : input.mode === 'delivery'
        ? `D${100 + Math.floor(Math.random() * 99)}`
        : `#${1200 + Math.floor(Math.random() * 99)}`

  let orderId: string | null = null
  let accessToken: string | null = null

  if (!input.isDemo && input.store.slug && input.store.slug !== 'demo') {
    const noteBits = [input.orderNote.trim(), input.pickTime ? `時段：${input.pickTime}` : '']
      .filter(Boolean)
      .join('｜')
    const { data } = await apiSubmit(input.store.slug, {
      fulfillment_type: fulfillmentType(input.mode),
      payment_method: paymentMethod(input.payMode, input.store),
      customer_name: input.customerName || '客人',
      customer_phone: input.addrPhone || '0900000000',
      customer_note: noteBits || null,
      delivery_address: input.mode === 'delivery' ? input.addrLine : null,
      delivery_note: input.mode === 'delivery' ? input.pickTime || null : null,
      table_label: input.mode === 'dinein' ? input.table || null : null,
      lines: input.lines.map((l) => ({
        product_id: l.productId,
        qty: l.qty,
        note: l.note || null,
        options: l.options,
      })),
    })
    orderId = data.order_id
    accessToken = data.access_token
  }

  return {
    mode: input.mode,
    table: input.table,
    pickTime: input.pickTime,
    address: input.addrLine,
    phone: input.addrPhone,
    payment: input.payMode,
    memberOn: input.memberOn,
    orderId,
    accessToken,
    pickupNo: orderId ? orderId.slice(-6).toUpperCase() : pickupNo,
    lines: input.lines.map((l) => ({ ...l })),
    subtotalCents: input.subtotalCents,
    deliveryFeeCents: input.deliveryFeeCents,
    discountCents: input.discountCents,
    totalCents: input.totalCents,
    storeName: input.store.name,
    isDemo: input.isDemo,
    paidOnline,
  }
}
