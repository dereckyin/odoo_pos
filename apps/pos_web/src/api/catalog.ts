import client from './client'
import type { Category, OptionGroup, Product, ProductOptionLink, ProductOptionOverride } from '@/types'

export function fetchCategories() {
  return client.get<Category[]>('/categories')
}

export function fetchProducts(params?: { q?: string; category_id?: string; limit?: number }) {
  return client.get<Product[]>('/products', {
    params: { is_active: true, limit: 200, ...params },
  })
}

export function fetchOptionGroups() {
  return client.get<OptionGroup[]>('/option-groups')
}

export function fetchProductOptionLinks(productId: string) {
  return client.get<ProductOptionLink[]>(`/products/${productId}/option-groups`)
}

export function fetchProductOptionOverrides(productId: string) {
  return client.get<ProductOptionOverride[]>(`/products/${productId}/option-overrides`)
}
