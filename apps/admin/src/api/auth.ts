import client from './client'
import type {
  SessionRead,
  TenantApplyRequest,
  TenantApplyResponse,
  TenantApplicationRead,
  SubscriptionPlanRead,
} from '@/types'

export function login(username: string, password: string, tenant_code?: string) {
  return client.post<SessionRead>('/auth/admin-login', {
    username,
    password,
    tenant_code: tenant_code || undefined,
  })
}

export function refreshToken(refresh_token: string) {
  return client.post<SessionRead>('/auth/refresh', { refresh_token })
}

export function logout(refresh_token: string | null) {
  return client.post('/auth/logout', { refresh_token })
}

export function changePassword(old_password: string, new_password: string) {
  return client.post('/auth/change-password', { old_password, new_password })
}

// ----- Public store-signup application -------------------------------------

export function publicListPlans() {
  return client.get<SubscriptionPlanRead[]>('/public/plans')
}

export function applyForTenant(payload: TenantApplyRequest) {
  return client.post<TenantApplyResponse>('/public/applications', payload)
}

export function verifyApplication(application_id: string, code: string) {
  return client.post<TenantApplicationRead>('/public/applications/verify', {
    application_id,
    code,
  })
}

export function getApplicationStatus(application_id: string) {
  return client.get<TenantApplicationRead>(`/public/applications/${application_id}`)
}

export interface TenantApplyResumeResponse {
  application_id: string
  contact_email: string
  status: string
  company_name: string
  message: string
}

export function resumeApplication(contact_email: string) {
  return client.post<TenantApplyResumeResponse>('/public/applications/resume', {
    contact_email,
  })
}

export function resendApplicationOtp(application_id: string) {
  return client.post(`/public/applications/${application_id}/resend-otp`)
}
