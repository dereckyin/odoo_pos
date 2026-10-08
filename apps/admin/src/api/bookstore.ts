import client from './client'
import type { BookstoreSettings, StoreRead } from '@/types'

export interface DoorQrRead {
  content: string
  expires_at: string
}

export interface BookstoreCheckoutLine {
  product_id: string
  product_name: string
  isbn: string | null
  qty: number
  unit_price_cents: number
  line_total_cents: number
}

export interface StaffCheckoutRead {
  id: string
  store_id: string
  status: 'pending' | 'paid' | 'expired' | 'cancelled' | 'refunded'
  subtotal_cents: number
  discount_cents: number
  total_cents: number
  payment_method: 'cash' | 'online' | null
  expires_at: string | null
  order_no: string | null
  invoice_status: string
  invoice_number: string | null
  paid_at: string | null
  paid_after_expiry: boolean
  exit_verified_at: string | null
  refunded_at: string | null
  created_at: string
  lines: BookstoreCheckoutLine[]
}

export interface ExitVerifyResponse {
  result: 'valid' | 'already_used' | 'expired' | 'not_paid' | 'invalid'
  checkout_id: string | null
  order_no: string | null
  total_cents: number | null
  paid_at: string | null
  verified_at: string | null
  lines: BookstoreCheckoutLine[]
}

export interface CashLookupResponse {
  result: 'found' | 'invalid' | 'already_paid' | 'closed'
  checkout: StaffCheckoutRead | null
}

export interface RefundResponse {
  checkout: StaffCheckoutRead
  invoice_voided: boolean
  gateway_refund: 'manual'
  message: string
}

export function getDoorQr(storeId: string) {
  return client.get<DoorQrRead>(`/bookstore/stores/${storeId}/door-qr`)
}

export function issueDoorQr(storeId: string) {
  return client.post<DoorQrRead>(`/bookstore/stores/${storeId}/door-qr`)
}

export function updateBookstoreSettings(
  storeId: string,
  payload: Pick<BookstoreSettings, 'is_open' | 'cash_enabled' | 'cash_price_pct' | 'online_payment_enabled'>,
) {
  return client.patch<StoreRead>(`/bookstore/stores/${storeId}/settings`, payload)
}

export function verifyExitPass(payload: { token?: string; code?: string; store_id?: string }) {
  return client.post<ExitVerifyResponse>('/bookstore/exit-pass/verify', payload)
}

export function lookupCashPayment(payload: { token?: string; code?: string; store_id?: string }) {
  return client.post<CashLookupResponse>('/bookstore/cash/lookup', payload)
}

export function confirmCashPayment(checkoutId: string, expectedTotalCents: number) {
  return client.post<StaffCheckoutRead>(`/bookstore/checkouts/${checkoutId}/cash-confirm`, {
    expected_total_cents: expectedTotalCents,
  })
}

export function listBookstoreCheckouts(params: { store_id?: string; status?: string; limit?: number }) {
  return client.get<StaffCheckoutRead[]>('/bookstore/checkouts', { params })
}

export function refundBookstoreCheckout(id: string, reason: string) {
  return client.post<RefundResponse>(`/bookstore/checkouts/${id}/refund`, { reason })
}
