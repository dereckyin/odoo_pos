import client from './client'
import type { StoreRead, StoreCreate, StoreUpdate, TerminalRead } from '@/types'

export function listStores() {
  return client.get<StoreRead[]>('/stores')
}

export function getStore(id: string) {
  return client.get<StoreRead>(`/stores/${id}`)
}

export function createStore(data: StoreCreate) {
  return client.post<StoreRead>('/stores', data)
}

export function updateStore(id: string, data: StoreUpdate) {
  return client.patch<StoreRead>(`/stores/${id}`, data)
}

export function deleteStore(id: string) {
  return client.delete(`/stores/${id}`)
}

export function listTerminals(storeId: string) {
  return client.get<TerminalRead[]>(`/stores/${storeId}/terminals`)
}

export function geocodeStore(storeId: string) {
  return client.post<StoreRead>(`/stores/${storeId}/geocode`)
}
