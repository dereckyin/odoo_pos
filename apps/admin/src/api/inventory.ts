import client from './client'
import type { InventoryLevelRead, TransferRead, StocktakeRead } from '@/types'

export function listInventoryLevels(params?: { store_id?: string }) {
  return client.get<InventoryLevelRead[]>('/inventory/levels', { params })
}

export function updateInventoryLevel(id: string, data: { safety_stock?: number }) {
  return client.patch(`/inventory/levels/${id}`, data)
}

export function createTransfer(data: {
  id: string; from_store_id: string; to_store_id: string; note?: string
  lines: { id: string; product_id: string; qty: number }[]
}) {
  return client.post<TransferRead>('/inventory/transfers', data)
}

export function updateTransfer(id: string, data: { status: string }) {
  return client.patch<TransferRead>(`/inventory/transfers/${id}`, data)
}

export function createStocktake(data: {
  id: string; store_id: string; note?: string
  lines: { id: string; product_id: string; expected_qty: number; actual_qty: number }[]
}) {
  return client.post<StocktakeRead>('/inventory/stocktakes', data)
}

export function adjustInventory(data: {
  store_id: string
  product_id: string
  mode: 'delta' | 'set'
  qty: number
  note?: string
  reason?: 'adjustment' | 'initial'
}) {
  return client.post<InventoryLevelRead>('/inventory/adjust', data)
}
