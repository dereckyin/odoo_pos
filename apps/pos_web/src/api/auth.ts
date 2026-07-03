import client from './client'
import type { SessionRead } from '@/types'

export interface PosLoginParams {
  tenant_code: string
  store_code: string
  terminal_code: string
  terminal_api_key: string
  username: string
  password: string
}

export function login(params: PosLoginParams) {
  return client.post<SessionRead>('/auth/login', params)
}

export function refreshToken(refresh_token: string) {
  return client.post<SessionRead>('/auth/refresh', { refresh_token })
}

export function logout(refresh_token: string) {
  return client.post('/auth/logout', { refresh_token })
}
