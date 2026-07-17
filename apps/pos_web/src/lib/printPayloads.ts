import type { CartLine, DiscountType } from '@/stores/cart'
import type { GuestOrder, InvoiceRead, Product, SelectedOption } from '@/types'
import { newUuid, optionsLabel, orderRefShort } from './utils'
import * as printApi from '@/api/printJobs'

export function unitPriceCents(
  priceCents: number,
  options: SelectedOption[],
): number {
  return priceCents + options.reduce((s, o) => s + o.price_delta_cents, 0)
}

export function calcTotals(
  lines: CartLine[],
  discountType: DiscountType,
  discountValue: number,
) {
  const subtotal = lines.reduce(
    (s, l) => s + unitPriceCents(l.product.price_cents, l.selectedOptions) * l.qty,
    0,
  )
  let discount = 0
  if (discountType === 'percentage') discount = Math.round(subtotal * (discountValue / 100))
  // discountValue for `amount` is already in 元 (same unit as *_cents for TWD)
  else if (discountType === 'amount') discount = Math.round(discountValue)
  discount = Math.min(discount, subtotal)
  const taxable = subtotal - discount
  const taxRate = lines[0]?.product.tax_rate ?? 0.05
  const tax = taxable > 0 ? Math.round((taxable * taxRate) / (1 + taxRate)) : 0
  return { subtotal, discount, tax, total: taxable }
}

function kitchenLinesFromCart(lines: CartLine[]) {
  return lines.map((l) => ({
    name: l.product.name,
    qty: l.qty,
    note: l.note || null,
    options_label: optionsLabel(l.selectedOptions),
  }))
}

function kitchenLinesFromGuest(order: GuestOrder) {
  return order.lines.map((l) => ({
    name: l.product_name,
    qty: l.qty,
    note: l.note,
    options_label: optionsLabel(l.options_json ?? []),
  }))
}

export function drinkLabelsFromCart(
  lines: CartLine[],
  labelProductIds: Set<string>,
  tableLabel: string,
  orderRef: string,
) {
  const labels: Record<string, unknown>[] = []
  const placedAt = new Date().toISOString()
  for (const line of lines) {
    if (!labelProductIds.has(line.product.id)) continue
    const cups = Math.max(1, Math.round(line.qty))
    for (let i = 1; i <= cups; i++) {
      labels.push({
        product_name: line.product.name,
        table_label: tableLabel,
        order_ref: orderRef,
        placed_at: placedAt,
        cup_index: i,
        cup_total: cups,
        options_label: optionsLabel(line.selectedOptions),
        note: line.note || null,
      })
    }
  }
  return labels
}

export function drinkLabelsFromGuest(order: GuestOrder, labelProductIds: Set<string>) {
  const labels: Record<string, unknown>[] = []
  const ref = orderRefShort(order.id)
  const table = order.table_label ?? '桌邊'
  for (const line of order.lines) {
    if (!labelProductIds.has(line.product_id)) continue
    const cups = Math.max(1, Math.round(line.qty))
    for (let i = 1; i <= cups; i++) {
      labels.push({
        product_name: line.product_name,
        table_label: table,
        order_ref: ref,
        placed_at: order.created_at,
        cup_index: i,
        cup_total: cups,
        options_label: optionsLabel(line.options_json ?? []),
        note: line.note,
      })
    }
  }
  return labels
}

export async function enqueueGuestOrderPrints(order: GuestOrder, products: Product[]) {
  const labelIds = new Set(products.filter((p) => p.print_label).map((p) => p.id))
  const table = order.table_label ?? '桌邊'
  const jobs = [
    printApi.createPrintJob({
      printer_role: 'kitchen',
      doc_type: 'kitchen_ticket',
      payload: {
        guest_order_id: order.id,
        table_label: table,
        placed_at: order.created_at,
        party_size: order.party_size,
        note: order.customer_note,
        lines: kitchenLinesFromGuest(order),
      },
    }),
    printApi.createPrintJob({
      printer_role: 'receipt',
      doc_type: 'confirmation',
      payload: {
        table_label: table,
        placed_at: order.created_at,
        order_ref: orderRefShort(order.id),
        note: order.customer_note,
        estimated_total_cents: order.estimated_subtotal_cents,
        lines: order.lines.map((l) => ({
          name: l.product_name,
          qty: l.qty,
          line_total_cents: l.line_total_cents,
          options_label: optionsLabel(l.options_json ?? []),
          note: l.note,
        })),
      },
    }),
  ]
  const labels = drinkLabelsFromGuest(order, labelIds)
  if (labels.length) {
    jobs.push(
      printApi.createPrintJob({
        printer_role: 'label',
        doc_type: 'label',
        payload: { labels },
      }),
    )
  }
  await Promise.all(jobs)
}

export async function enqueueCheckoutPrints(opts: {
  orderPayload: Record<string, unknown>
  invoice: InvoiceRead | null
  cartLines: CartLine[]
  products: Product[]
  tableLabel?: string
  storeName?: string
  needsProof: boolean
}) {
  const {
    orderPayload,
    invoice,
    cartLines,
    products,
    tableLabel,
    storeName = '點餐趣',
    needsProof,
  } = opts
  const labelIds = new Set(products.filter((p) => p.print_label).map((p) => p.id))
  const ref = orderRefShort(orderPayload.id as string)
  const table = tableLabel ?? '現場'

  const jobs = [
    printApi.createPrintJob({
      printer_role: 'receipt',
      doc_type: 'receipt',
      payload: {
        order: orderPayload,
        invoice: invoice?.status === 'issued' ? invoice : null,
        table_label: table,
      },
    }),
    printApi.createPrintJob({
      printer_role: 'kitchen',
      doc_type: 'kitchen_ticket',
      payload: {
        guest_order_id: orderPayload.id,
        table_label: table,
        placed_at: orderPayload.client_created_at,
        note: orderPayload.note,
        lines: kitchenLinesFromCart(cartLines),
      },
    }),
  ]

  if (needsProof && invoice?.invoice_number) {
    jobs.push(
      printApi.createPrintJob({
        printer_role: 'receipt',
        doc_type: 'invoice_proof',
        payload: {
          store_name: storeName,
          invoice_number: invoice.invoice_number,
          invoice_date: invoice.invoice_date,
          random_code: invoice.random_code ?? '0000',
          total_cents: invoice.total_cents,
          buyer_tax_id: null,
          barcode: invoice.barcode,
          qr_left: invoice.qr_left,
          qr_right: invoice.qr_right,
        },
      }),
    )
  }

  const labels = drinkLabelsFromCart(cartLines, labelIds, table, ref)
  if (labels.length) {
    jobs.push(
      printApi.createPrintJob({
        printer_role: 'label',
        doc_type: 'label',
        payload: { labels },
      }),
    )
  }

  await Promise.all(jobs)
}

export async function enqueueTableQrPrint(session: {
  table_label: string
  customer_order_url: string
  session: { expires_at: string | null }
}) {
  await printApi.createPrintJob({
    printer_role: 'receipt',
    doc_type: 'qr_slip',
    payload: {
      store_name: '點餐趣',
      table_label: session.table_label,
      order_url: session.customer_order_url,
      expires_at: session.session.expires_at,
    },
  })
}

export function buildOrderPayload(opts: {
  orderId: string
  storeId: string
  terminalId: string
  cashierId: string
  shiftId: string | null
  lines: CartLine[]
  payments: { id: string; method: string; amount_cents: number; tendered_cents?: number; change_due_cents?: number }[]
  subtotal: number
  discount: number
  tax: number
  total: number
  note?: string
  sourceGuestOrderId?: string
}) {
  return {
    id: opts.orderId,
    store_id: opts.storeId,
    terminal_id: opts.terminalId,
    cashier_id: opts.cashierId,
    shift_id: opts.shiftId,
    status: 'paid',
    subtotal_cents: opts.subtotal,
    discount_cents: opts.discount,
    tax_cents: opts.tax,
    total_cents: opts.total,
    note: opts.note ?? null,
    source_guest_order_id: opts.sourceGuestOrderId ?? null,
    client_created_at: new Date().toISOString(),
    lines: opts.lines.map((l) => {
      const unit = unitPriceCents(l.product.price_cents, l.selectedOptions)
      const lineTotal = unit * l.qty
      return {
        id: l.id || newUuid(),
        product_id: l.product.id,
        product_name: l.product.name,
        sku: l.product.sku,
        qty: l.qty,
        unit_price_cents: unit,
        line_discount_cents: 0,
        line_total_cents: lineTotal,
        tax_rate: l.product.tax_rate,
        note: l.note || null,
        options_json: l.selectedOptions.length ? l.selectedOptions : null,
      }
    }),
    payments: opts.payments.map((p) => ({
      id: p.id,
      method: p.method,
      amount_cents: p.amount_cents,
      status: 'captured',
      tendered_cents: p.tendered_cents ?? null,
      change_due_cents: p.change_due_cents ?? null,
    })),
  }
}
