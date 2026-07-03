import client from './client'
import type { ShiftRead } from '@/types'

export function fetchCurrentShift() {
  return client.get<ShiftRead | null>('/shifts/current')
}

export function openShift(opening_cash_cents = 0) {
  return client.post<ShiftRead>('/shifts/open', { opening_cash_cents })
}

export function closeShift(counted_cash_cents: number) {
  return client.post<ShiftRead>('/shifts/close', { counted_cash_cents })
}

export function uploadOrder(payload: Record<string, unknown>) {
  return client.post('/orders', payload)
}

export function issueInvoice(payload: Record<string, unknown>) {
  return client.post('/invoices/issue', payload)
}
