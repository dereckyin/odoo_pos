import client from './client'

export interface DiscountPreset {
  label: string
  pct_off: number
}

export interface ConsignmentBooksSettings {
  book_share_pct: number
  store_ids: string[]
  discount_presets: DiscountPreset[]
}

export interface BookLookup {
  barcode: string
  barcode_kind: string
  title: string
  author: string
  publisher: string
  isbn: string | null
  list_price_cents: number
  sale_price_cents: number | null
  category_main: string | null
  category_sub: string | null
  image_url: string | null
  sale_disc: number | null
  source: string
}

export interface BookProduct {
  id: string
  sku: string
  name: string
  price_cents: number
  category_id: string | null
  image_url: string | null
  unit: string
  product_kind: string
  barcodes: string[]
  author: string | null
  publisher: string | null
  isbn: string | null
  list_price_cents: number | null
  sale_disc: number | null
  on_hand: number | null
}

export interface BookImportError {
  row: number
  barcode: string
  message: string
}

export interface BookImportResult {
  received: number
  skipped: number
  errors: BookImportError[]
}

export interface ConsignmentSettlementRow {
  store_id: string
  store_name: string
  qty: number
  gross_revenue_cents: number
  refund_cents: number
  revenue_cents: number
  gross_book_share_cents: number
  refund_book_share_cents: number
  book_share_cents: number
  gross_restaurant_share_cents: number
  refund_restaurant_share_cents: number
  restaurant_share_cents: number
}

export interface ConsignmentSettlementReport {
  book_share_pct: number
  rows: ConsignmentSettlementRow[]
  total_qty: number
  gross_revenue_cents: number
  refund_cents: number
  total_revenue_cents: number
  gross_book_share_cents: number
  refund_book_share_cents: number
  total_book_share_cents: number
  gross_restaurant_share_cents: number
  refund_restaurant_share_cents: number
  total_restaurant_share_cents: number
}

export function getConsignmentSettings() {
  return client.get<ConsignmentBooksSettings>('/books/settings')
}

export function updateConsignmentSettings(payload: Partial<ConsignmentBooksSettings>) {
  return client.patch<ConsignmentBooksSettings>('/books/settings', payload)
}

export function listBooks(params?: { q?: string; store_id?: string }) {
  return client.get<BookProduct[]>('/books', { params })
}

export function lookupBook(barcode: string) {
  return client.get<BookLookup>('/books/lookup', { params: { barcode } })
}

export function receiveBook(payload: { barcode: string; store_id: string; qty: number }) {
  return client.post<BookProduct>('/books/receive', payload)
}

export function importBooksCsv(file: File) {
  const form = new FormData()
  form.append('file', file)
  return client.post<BookImportResult>('/books/import-csv', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}

export function getConsignmentSettlement(params?: {
  since?: string
  until?: string
  store_id?: string
}) {
  return client.get<ConsignmentSettlementReport>('/reports/consignment-settlement', { params })
}
