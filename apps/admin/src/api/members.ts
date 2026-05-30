import client from './client'
import type {
  MemberRead, MemberCreate, MemberUpdate,
  MemberLevelRead, MemberLevelCreate, MemberLevelUpdate,
  CouponRead, CouponCreate,
  PointTransactionRead,
  LoyaltyRuleRead, LoyaltyRuleCreate, LoyaltyRuleUpdate, LoyaltySettings,
  OrderListResponse,
} from '@/types'

export function listMembers(params?: { q?: string; limit?: number }) {
  return client.get<MemberRead[]>('/members', { params })
}

export function getMember(id: string) {
  return client.get<MemberRead>(`/members/${id}`)
}

export function createMember(data: MemberCreate) {
  return client.post<MemberRead>('/members', data)
}

export function updateMember(id: string, data: MemberUpdate) {
  return client.patch<MemberRead>(`/members/${id}`, data)
}

export function listMemberLevels() {
  return client.get<MemberLevelRead[]>('/members/levels')
}

export function createMemberLevel(data: MemberLevelCreate) {
  return client.post<MemberLevelRead>('/members/levels', data)
}

export function updateMemberLevel(id: string, data: MemberLevelUpdate) {
  return client.patch<MemberLevelRead>(`/members/levels/${id}`, data)
}

export function deleteMemberLevel(id: string) {
  return client.delete(`/members/levels/${id}`)
}

export function adjustPoints(data: { member_id: string; delta: number; reason: string; order_id?: string }) {
  return client.post<PointTransactionRead>('/members/points', data)
}

export function listPointTransactions(memberId: string, limit = 50) {
  return client.get<PointTransactionRead[]>(`/members/${memberId}/points`, { params: { limit } })
}

export function listMemberOrders(memberId: string, params?: { limit?: number; offset?: number }) {
  return client.get<OrderListResponse>(`/members/${memberId}/orders`, { params })
}

export function getLoyaltySettings() {
  return client.get<LoyaltySettings>('/members/loyalty/settings')
}

export function updateLoyaltySettings(data: LoyaltySettings) {
  return client.put<LoyaltySettings>('/members/loyalty/settings', data)
}

export function listLoyaltyRules() {
  return client.get<LoyaltyRuleRead[]>('/members/loyalty/rules')
}

export function createLoyaltyRule(data: LoyaltyRuleCreate) {
  return client.post<LoyaltyRuleRead>('/members/loyalty/rules', data)
}

export function updateLoyaltyRule(id: string, data: LoyaltyRuleUpdate) {
  return client.patch<LoyaltyRuleRead>(`/members/loyalty/rules/${id}`, data)
}

export function deleteLoyaltyRule(id: string) {
  return client.delete(`/members/loyalty/rules/${id}`)
}

export function listCoupons(params?: { member_id?: string }) {
  return client.get<CouponRead[]>('/coupons', { params })
}

export function createCoupon(data: CouponCreate) {
  return client.post<CouponRead>('/coupons', data)
}
