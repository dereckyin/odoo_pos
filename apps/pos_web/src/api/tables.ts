import client from './client'
import type { DiningTable, TableSessionOpen } from '@/types'

export function listTables(storeId: string) {
  return client.get<DiningTable[]>('/dining-tables', { params: { store_id: storeId } })
}

export function openTableSession(tableId: string) {
  return client.post<TableSessionOpen>(`/dining-tables/${tableId}/sessions`)
}

export function closeTableSession(sessionId: string) {
  return client.post(`/dining-tables/sessions/${sessionId}/close`)
}
