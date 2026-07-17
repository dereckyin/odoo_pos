/**
 * ESC/POS 文件 encoder：把結構化的列印工作 payload 轉成可直接 transferOut 的位元組。
 * 涵蓋 doc_type：receipt、kitchen_ticket、confirmation、qr_slip、invoice_proof
 *（皆屬 printer_role 'receipt' 或 'kitchen'，實體上都是 ESC/POS 小票機）。
 */
import { optionsLabel } from '@/lib/utils'
import {
  ESC_ALIGN_CENTER,
  ESC_CUT,
  ESC_INIT,
  canvasToEscposRaster,
  concatBytes,
  createTicket,
  escCashDrawer,
  escFeed,
  escposBarcode,
  escposQr,
  finalizeTicket,
} from './raster'
import type {
  ConfirmationPayload,
  InvoiceProofPayload,
  KitchenTicketPayload,
  QrSlipPayload,
  ReceiptPrintPayload,
} from './types'

const STORE_NAME_FALLBACK = '點餐趣'

/** TWD `*_cents` are whole 元 — do not divide by 100. */
function money(cents: number): string {
  return `$${Math.round(cents)}`
}

function fmtTime(iso: string | null | undefined): string {
  if (!iso) return '—'
  try {
    return new Date(iso).toLocaleString('sv-SE')
  } catch {
    return iso
  }
}

function paymentLabel(method: string): string {
  switch (method) {
    case 'cash':
      return '現金'
    case 'credit_card':
      return '信用卡'
    case 'linepay':
      return 'LINE Pay'
    default:
      return method
  }
}

function wrapAsRasterDoc(build: () => ReturnType<typeof createTicket>, opts: { openDrawer?: boolean } = {}) {
  const ticket = build()
  const canvas = finalizeTicket(ticket)
  const raster = canvasToEscposRaster(canvas)
  const parts = [ESC_INIT, ESC_ALIGN_CENTER, raster, escFeed(1)]
  if (opts.openDrawer) parts.push(escCashDrawer())
  parts.push(escFeed(3), ESC_CUT)
  return concatBytes(...parts)
}

/** doc_type: 'receipt'（結帳收據，printer_role: receipt） */
export function buildReceiptDoc(payload: ReceiptPrintPayload): Uint8Array {
  const { order, invoice, table_label } = payload
  const isCash = order.payments.some((p) => p.method === 'cash')

  return wrapAsRasterDoc(
    () => {
      const t = createTicket()
      t.centerText(STORE_NAME_FALLBACK, 52, 'bold', 6)
      t.centerText(table_label ? `桌號 ${table_label}` : '現場帶走', 24, 'normal', 4)
      t.solid(16, 3)
      t.row('單號', order.id.slice(-8).toUpperCase(), 22, 'normal', 6)
      t.row('時間', fmtTime(order.client_created_at), 22, 'normal', 8)
      t.dashed(12)
      t.row('品項', '金額', 24, 'bold', 10)
      for (const line of order.lines) {
        t.row(line.product_name, money(line.line_total_cents), 26, 'normal', 2)
        const opts = optionsLabel(line.options_json ?? [])
        const detail = `  ${line.qty} x ${money(line.unit_price_cents)}${opts ? `（${opts}）` : ''}`
        t.leftText(detail, 20, 'normal', 6)
        if (line.note) t.leftText(`  備註：${line.note}`, 20, 'normal', 6)
      }
      t.dashed(12)
      t.row('小計', money(order.subtotal_cents), 22, 'normal', 6)
      if (order.discount_cents) t.row('折扣', `-${money(order.discount_cents)}`, 22, 'normal', 6)
      if (order.tax_cents) t.row('內含稅額', money(order.tax_cents), 20, 'normal', 6)
      t.solid(10, 2)
      t.row('總計', money(order.total_cents), 38, 'bold', 12)
      for (const p of order.payments) {
        t.row(paymentLabel(p.method), money(p.amount_cents), 20, 'normal', 4)
        if (p.tendered_cents != null) {
          t.leftText(`  收款 ${money(p.tendered_cents)}　找零 ${money(p.change_due_cents ?? 0)}`, 18, 'normal', 4)
        }
      }
      if (invoice?.invoice_number) {
        t.dashed(12)
        t.centerText(`發票號碼 ${invoice.invoice_number}`, 22, 'bold', 4)
        if (invoice.random_code) t.centerText(`隨機碼 ${invoice.random_code}`, 18, 'normal', 4)
      }
      t.feed(8)
      t.centerText('感謝惠顧・歡迎再度光臨', 20, 'normal', 0)
      return t
    },
    { openDrawer: isCash },
  )
}

/** doc_type: 'kitchen_ticket'（廚房出單，printer_role: kitchen；不含金額） */
export function buildKitchenTicketDoc(payload: KitchenTicketPayload): Uint8Array {
  return wrapAsRasterDoc(() => {
    const t = createTicket()
    t.centerText('廚房單', 48, 'bold', 8)
    t.centerText(payload.table_label || '現場', 30, 'bold', 6)
    t.solid(14, 3)
    t.row('時間', fmtTime(payload.placed_at), 20, 'normal', 6)
    if (payload.party_size) t.row('人數', String(payload.party_size), 20, 'normal', 6)
    t.dashed(12)
    for (const line of payload.lines) {
      t.leftText(`${line.qty} x  ${line.name}`, 30, 'bold', 4)
      if (line.options_label) t.leftText(`    ${line.options_label}`, 22, 'normal', 4)
      if (line.note) t.leftText(`    備註：${line.note}`, 22, 'normal', 8)
      else t.feed(4)
    }
    if (payload.note) {
      t.dashed(10)
      t.leftText(`整單備註：${payload.note}`, 22, 'bold', 4)
    }
    return t
  })
}

/** doc_type: 'confirmation'（桌邊點餐送出後的顧客確認單，printer_role: receipt） */
export function buildConfirmationDoc(payload: ConfirmationPayload): Uint8Array {
  return wrapAsRasterDoc(() => {
    const t = createTicket()
    t.centerText(STORE_NAME_FALLBACK, 44, 'bold', 6)
    t.centerText('點餐確認單', 26, 'normal', 6)
    t.solid(14, 3)
    t.row('桌號', payload.table_label, 22, 'normal', 6)
    t.row('單號', payload.order_ref, 22, 'normal', 6)
    t.row('時間', fmtTime(payload.placed_at), 20, 'normal', 8)
    t.dashed(12)
    for (const line of payload.lines) {
      t.row(`${line.qty} x ${line.name}`, money(line.line_total_cents), 24, 'normal', 2)
      if (line.options_label) t.leftText(`    ${line.options_label}`, 20, 'normal', 6)
      if (line.note) t.leftText(`    備註：${line.note}`, 20, 'normal', 6)
    }
    t.dashed(12)
    t.row('預估金額', money(payload.estimated_total_cents), 28, 'bold', 10)
    if (payload.note) t.leftText(`整單備註：${payload.note}`, 20, 'normal', 6)
    t.feed(6)
    t.centerText('請至櫃台結帳，謝謝', 20, 'normal', 0)
    return t
  })
}

/** doc_type: 'qr_slip'（開桌一次性 QR 貼紙，printer_role: receipt） */
export function buildQrSlipDoc(payload: QrSlipPayload): Uint8Array {
  const ticket = createTicket()
  ticket.centerText(payload.store_name || STORE_NAME_FALLBACK, 44, 'bold', 8)
  ticket.centerText(`桌號 ${payload.table_label}`, 40, 'bold', 12)
  ticket.centerText('掃碼點餐', 24, 'normal', 4)
  const canvasTop = finalizeTicket(ticket)
  const rasterTop = canvasToEscposRaster(canvasTop)

  const tail = createTicket(576, 400)
  if (payload.expires_at) tail.centerText(`本次點餐有效至 ${fmtTime(payload.expires_at)}`, 18, 'normal', 4)
  tail.centerText('結帳或併單後本 QR 即失效', 18, 'normal', 0)
  const canvasTail = finalizeTicket(tail)
  const rasterTail = canvasToEscposRaster(canvasTail)

  return concatBytes(
    ESC_INIT,
    ESC_ALIGN_CENTER,
    rasterTop,
    escFeed(1),
    escposQr(payload.order_url, 10),
    escFeed(1),
    rasterTail,
    escFeed(3),
    ESC_CUT,
  )
}

/** doc_type: 'invoice_proof'（電子發票證明聯，printer_role: receipt） */
export function buildInvoiceProofDoc(payload: InvoiceProofPayload): Uint8Array {
  const ticket = createTicket()
  ticket.centerText(payload.store_name || STORE_NAME_FALLBACK, 36, 'bold', 6)
  ticket.centerText('電子發票證明聯', 26, 'normal', 8)
  ticket.solid(12, 2)
  ticket.centerText(payload.invoice_number, 44, 'bold', 8)
  ticket.centerText(fmtTime(payload.invoice_date), 20, 'normal', 6)
  ticket.centerText(`隨機碼 ${payload.random_code}`, 22, 'normal', 8)
  ticket.centerText(`總計 $${Math.round(payload.total_cents)}`, 26, 'bold', 8)
  const canvasTop = finalizeTicket(ticket)
  const rasterTop = canvasToEscposRaster(canvasTop)

  const parts = [ESC_INIT, ESC_ALIGN_CENTER, rasterTop, escFeed(1)]
  if (payload.barcode) {
    parts.push(escposBarcode(payload.barcode), escFeed(1))
  }
  if (payload.qr_left) parts.push(escposQr(payload.qr_left, 6), escFeed(1))
  if (payload.qr_right) parts.push(escposQr(payload.qr_right, 6), escFeed(1))
  parts.push(escFeed(3), ESC_CUT)
  return concatBytes(...parts)
}
