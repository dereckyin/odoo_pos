import client from './client'
import type {
  MemberRead, MemberCreate, MemberUpdate,
  MemberLevelRead, MemberLevelCreate,
  CouponRead, CouponCreate,
  PointTransactionRead,
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

export function adjustPoints(data: { member_id: string; delta: number; reason: string; order_id?: string }) {
  return client.post<PointTransactionRead>('/members/points', data)
}

export function listCoupons(params?: { member_id?: string }) {
  return client.get<CouponRead[]>('/coupons', { params })
}

export function createCoupon(data: CouponCreate) {
  return client.post<CouponRead>('/coupons', data)
}
