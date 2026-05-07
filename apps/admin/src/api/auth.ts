import client from './client'
import type { SessionRead } from '@/types'

export function login(username: string, password: string) {
  return client.post<SessionRead>('/auth/admin-login', { username, password })
}

export function refreshToken(refresh_token: string) {
  return client.post<SessionRead>('/auth/refresh', { refresh_token })
}
