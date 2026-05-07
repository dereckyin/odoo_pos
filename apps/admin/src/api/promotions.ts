import client from './client'
import type { PromotionRead, PromotionCreate, PromotionUpdate } from '@/types'

export function listPromotions(params?: { active_only?: boolean; status?: string }) {
  return client.get<PromotionRead[]>('/promotions', { params })
}

export function getPromotion(id: string) {
  return client.get<PromotionRead>(`/promotions/${id}`)
}

export function createPromotion(data: PromotionCreate) {
  return client.post<PromotionRead>('/promotions', data)
}

export function updatePromotion(id: string, data: PromotionUpdate) {
  return client.patch<PromotionRead>(`/promotions/${id}`, data)
}

export function deletePromotion(id: string) {
  return client.delete(`/promotions/${id}`)
}
