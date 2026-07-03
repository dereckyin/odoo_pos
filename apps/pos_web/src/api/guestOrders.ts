import client from './client'
import type { GuestOrder } from '@/types'

export function listGuestOrders(params?: { status_in?: string }) {
  return client.get<GuestOrder[]>('/guest-orders', {
    params: { status_in: params?.status_in ?? 'submitted,accepted,ready', limit: 100 },
  })
}

export function acceptGuestOrder(id: string) {
  return client.post<GuestOrder>(`/guest-orders/${id}/accept`)
}

export function markGuestOrderReady(id: string) {
  return client.post<GuestOrder>(`/guest-orders/${id}/ready`)
}

export function completeGuestOrder(id: string) {
  return client.post<GuestOrder>(`/guest-orders/${id}/complete`)
}
