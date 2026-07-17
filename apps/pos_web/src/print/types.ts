import type { SelectedOption } from '@/types'

/** 對應後端 print_jobs.printer_role：三台實體印表機各自獨立配對 */
export type PrinterKind = 'receipt' | 'kitchen' | 'label'

export type PrintDocType =
  | 'receipt'
  | 'kitchen_ticket'
  | 'confirmation'
  | 'label'
  | 'qr_slip'
  | 'invoice_proof'

export type PrintJobStatus = 'pending' | 'printing' | 'done' | 'failed'

/** 對應 apps/api/app/schemas/print_job.py::PrintJobRead */
export interface PrintJobRead {
  id: string
  tenant_id: string
  store_id: string
  printer_role: PrinterKind
  doc_type: PrintDocType
  payload: Record<string, unknown>
  status: PrintJobStatus
  retry_count: number
  last_error: string | null
  claimed_at: string | null
  completed_at: string | null
  created_at: string
  updated_at: string
}

export interface PrintJobPendingResponse {
  items: PrintJobRead[]
}

export type PrinterStatus = 'unpaired' | 'connecting' | 'ready' | 'error'

/**
 * 印表機驅動介面（可插拔）。業務邏輯 / PrintService 只依賴這個介面，
 * 之後若要換傳輸方式（例如 iOS 走本地列印伺服器）只需另外實作一個 driver。
 * 對照 web_pos_full/docs/POS_printer_integration_v3.md 第 4 節。
 */
export interface PrinterDriver {
  /** 使用者點擊觸發，首次配對或重新配對某一角色的印表機 */
  pair(kind: PrinterKind): Promise<void>
  /** 清除本機記住的配對資訊（換機或排除故障用） */
  forget(kind: PrinterKind): void
  /** 是否已配對且可連線（會嘗試靜默重連） */
  isReady(kind: PrinterKind): Promise<boolean>
  /** 送出已編碼好的位元組給指定角色的印表機 */
  print(kind: PrinterKind, bytes: Uint8Array): Promise<void>
  /** 透過收據機的 RJ11 埠踢開錢箱 */
  openCashDrawer(): Promise<void>
}

// ---------------------------------------------------------------------------
// 列印工作 payload —— 對應 apps/pos_web/src/lib/printPayloads.ts 產生的內容
// ---------------------------------------------------------------------------

export interface OrderLinePayload {
  id: string
  product_id: string
  product_name: string
  sku: string | null
  qty: number
  unit_price_cents: number
  line_discount_cents: number
  line_total_cents: number
  tax_rate: number
  note: string | null
  options_json: SelectedOption[] | null
}

export interface OrderPaymentPayload {
  id: string
  method: string
  amount_cents: number
  status: string
  tendered_cents: number | null
  change_due_cents: number | null
}

export interface OrderPrintPayload {
  id: string
  store_id: string
  terminal_id: string
  cashier_id: string
  shift_id: string | null
  status: string
  subtotal_cents: number
  discount_cents: number
  tax_cents: number
  total_cents: number
  note: string | null
  source_guest_order_id: string | null
  client_created_at: string
  lines: OrderLinePayload[]
  payments: OrderPaymentPayload[]
}

export interface InvoicePrintPayload {
  status: string
  invoice_number: string | null
  invoice_date: string | null
  random_code: string | null
  total_cents: number
  barcode: string | null
  qr_left: string | null
  qr_right: string | null
}

export interface ReceiptPrintPayload {
  order: OrderPrintPayload
  invoice: InvoicePrintPayload | null
  table_label: string
}

export interface KitchenLinePayload {
  name: string
  qty: number
  note: string | null
  options_label: string
}

export interface KitchenTicketPayload {
  guest_order_id: string
  table_label: string
  placed_at: string
  party_size?: number | null
  note: string | null
  lines: KitchenLinePayload[]
}

export interface ConfirmationLinePayload {
  name: string
  qty: number
  line_total_cents: number
  options_label: string
  note: string | null
}

export interface ConfirmationPayload {
  table_label: string
  placed_at: string
  order_ref: string
  note: string | null
  estimated_total_cents: number
  lines: ConfirmationLinePayload[]
}

export interface QrSlipPayload {
  store_name: string
  table_label: string
  order_url: string
  expires_at: string | null
}

export interface InvoiceProofPayload {
  store_name: string
  invoice_number: string
  invoice_date: string | null
  random_code: string
  total_cents: number
  buyer_tax_id: string | null
  barcode: string | null
  qr_left: string | null
  qr_right: string | null
}

export interface DrinkLabelPayload {
  product_name: string
  table_label: string
  order_ref: string
  placed_at: string
  cup_index: number
  cup_total: number
  options_label: string
  note: string | null
}

export interface LabelDocPayload {
  labels: DrinkLabelPayload[]
}
