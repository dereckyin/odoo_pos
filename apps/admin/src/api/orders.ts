import client from './client'
import type { OrderListItem, OrderListResponse } from '@/types'

export interface OrderListParams {
  member_id?: string
  terminal_id?: string
  store_id?: string
  status?: string
  payment_method?: string
  since?: string
  until?: string
  q?: string
  offset?: number
  limit?: number
}

export function listOrders(params?: OrderListParams) {
  return client.get<OrderListResponse>('/orders', { params })
}

export function exportOrdersCsv(params?: Omit<OrderListParams, 'offset' | 'limit'>) {
  return client.get('/orders/export-csv', { params, responseType: 'blob' })
}

export function getOrder(id: string) {
  return client.get<OrderListItem>(`/orders/${id}`)
}
