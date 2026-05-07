import client from './client'
import type { OrderRead } from '@/types'

export function listOrders(params?: { member_id?: string; terminal_id?: string; skip?: number; limit?: number }) {
  return client.get<OrderRead[]>('/orders', { params })
}

export function getOrder(id: string) {
  return client.get<OrderRead>(`/orders/${id}`)
}
