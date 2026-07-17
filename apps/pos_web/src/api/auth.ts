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

export function adminLogin(params: {
  tenant_code?: string | null
  username: string
  password: string
  totp_code?: string | null
}) {
  return client.post<SessionRead>('/auth/admin-login', params)
}

export function registerTerminal(
  params: { store_code: string; terminal_code: string },
  adminToken: string,
) {
  return client.post<{ terminal_id: string; store_id: string; api_key: string }>(
    '/auth/terminals/register',
    params,
    { headers: { Authorization: `Bearer ${adminToken}` } },
  )
}

export function refreshToken(refresh_token: string) {
  return client.post<SessionRead>('/auth/refresh', { refresh_token })
}

export function logout(refresh_token: string) {
  return client.post('/auth/logout', { refresh_token })
}
