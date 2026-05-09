import client from './client'
import type {
  TenantApplicationRead,
  TenantRead,
  SubscriptionPlanRead,
} from '@/types'

// ----- Tenant applications --------------------------------------------------

export function listApplications(status?: string) {
  return client.get<TenantApplicationRead[]>('/platform/applications', {
    params: status ? { status } : undefined,
  })
}

export function getApplication(id: string) {
  return client.get<TenantApplicationRead>(`/platform/applications/${id}`)
}

export interface ApplicationApprovePayload {
  plan_code: string
  owner_username: string
  tenant_code?: string
}

export function approveApplication(id: string, payload: ApplicationApprovePayload) {
  return client.post<TenantApplicationRead>(
    `/platform/applications/${id}/approve`,
    payload,
  )
}

export function rejectApplication(id: string, reason: string) {
  return client.post<TenantApplicationRead>(
    `/platform/applications/${id}/reject`,
    { reason },
  )
}

// ----- Tenants --------------------------------------------------------------

export function listTenants(status?: string) {
  return client.get<TenantRead[]>('/platform/tenants', {
    params: status ? { status } : undefined,
  })
}

export function getTenant(id: string) {
  return client.get<TenantRead>(`/platform/tenants/${id}`)
}

export interface TenantUpdatePayload {
  name?: string
  contact_email?: string
  contact_phone?: string | null
  status?: string
  plan_code?: string | null
}

export function updateTenant(id: string, payload: TenantUpdatePayload) {
  return client.patch<TenantRead>(`/platform/tenants/${id}`, payload)
}

// ----- Plans (admin view) ---------------------------------------------------

export function listPlans() {
  return client.get<SubscriptionPlanRead[]>('/platform/plans')
}
