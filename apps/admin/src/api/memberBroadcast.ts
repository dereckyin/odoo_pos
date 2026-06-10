import client from './client'
import type { MemberBroadcast } from '@/types'

export function getBroadcastAudience() {
  return client.get<{ count: number }>('/members/broadcasts/audience')
}

export function listBroadcasts(limit = 50) {
  return client.get<MemberBroadcast[]>('/members/broadcasts', { params: { limit } })
}

export function sendBroadcast(message: string) {
  return client.post<MemberBroadcast>('/members/broadcasts', { message })
}
