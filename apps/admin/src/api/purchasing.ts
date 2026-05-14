import client from './client'
import type {
  PurchaseOrderCreate,
  PurchaseOrderRead,
  PurchaseOrderReceive,
  SupplierCreate,
  SupplierRead,
  SupplierUpdate,
} from '@/types'

export function listSuppliers() {
  return client.get<SupplierRead[]>('/purchasing/suppliers')
}

export function createSupplier(data: SupplierCreate) {
  return client.post<SupplierRead>('/purchasing/suppliers', data)
}

export function updateSupplier(id: string, data: SupplierUpdate) {
  return client.patch<SupplierRead>(`/purchasing/suppliers/${id}`, data)
}

export function listPurchaseOrders(params?: { store_id?: string; status_in?: string }) {
  return client.get<PurchaseOrderRead[]>('/purchasing/orders', { params })
}

export function getPurchaseOrder(id: string) {
  return client.get<PurchaseOrderRead>(`/purchasing/orders/${id}`)
}

export function createPurchaseOrder(data: PurchaseOrderCreate) {
  return client.post<PurchaseOrderRead>('/purchasing/orders', data)
}

export function patchPurchaseOrderStatus(id: string, status: 'ordered' | 'cancelled') {
  return client.patch<PurchaseOrderRead>(`/purchasing/orders/${id}`, { status })
}

export function receivePurchaseOrder(id: string, data: PurchaseOrderReceive) {
  return client.post<PurchaseOrderRead>(`/purchasing/orders/${id}/receive`, data)
}
