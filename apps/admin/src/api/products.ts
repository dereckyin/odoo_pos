import client from './client'
import type { ProductRead, ProductCreate, ProductUpdate, CategoryRead, CategoryCreate, CategoryUpdate } from '@/types'

export function listProducts(params?: { q?: string; category_id?: string; is_active?: boolean; skip?: number; limit?: number }) {
  return client.get<ProductRead[]>('/products', { params })
}

export function getProduct(id: string) {
  return client.get<ProductRead>(`/products/${id}`)
}

export function createProduct(data: ProductCreate) {
  return client.post<ProductRead>('/products', data)
}

export function updateProduct(id: string, data: ProductUpdate) {
  return client.patch<ProductRead>(`/products/${id}`, data)
}

export function deleteProduct(id: string) {
  return client.delete(`/products/${id}`)
}

export function importProductsCsv(file: File) {
  const form = new FormData()
  form.append('file', file)
  return client.post('/products/import-csv', form)
}

export function listCategories() {
  return client.get<CategoryRead[]>('/categories')
}

export function createCategory(data: CategoryCreate) {
  return client.post<CategoryRead>('/categories', data)
}

export function updateCategory(id: string, data: CategoryUpdate) {
  return client.patch<CategoryRead>(`/categories/${id}`, data)
}

export function deleteCategory(id: string) {
  return client.delete(`/categories/${id}`)
}

export function uploadImage(file: File) {
  const form = new FormData()
  form.append('file', file)
  return client.post<{ url: string }>('/uploads/images', form)
}
