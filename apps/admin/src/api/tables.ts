import client from './client'
import type {
  DiningTableCreate,
  DiningTableRead,
  DiningTableUpdate,
  GuestOrderRead,
} from '@/types'

export function listTables(params?: { store_id?: string; include_inactive?: boolean }) {
  return client.get<DiningTableRead[]>('/admin/tables', { params })
}

export function createTable(data: DiningTableCreate) {
  return client.post<DiningTableRead>('/admin/tables', data)
}

export function updateTable(id: string, data: DiningTableUpdate) {
  return client.patch<DiningTableRead>(`/admin/tables/${id}`, data)
}

export function deleteTable(id: string) {
  return client.delete(`/admin/tables/${id}`)
}

export function rotateTableToken(id: string) {
  return client.post<{ id: string; public_token: string }>(`/admin/tables/${id}/rotate-token`)
}

export function listGuestOrders(params?: {
  store_id?: string
  status_in?: string
  channel?: string
  fulfillment_type?: string
}) {
  return client.get<GuestOrderRead[]>('/guest-orders', { params })
}

export function setGuestOrderDeliveryStatus(id: string, status: string) {
  return client.post<GuestOrderRead>(`/guest-orders/${id}/delivery-status`, { status })
}
