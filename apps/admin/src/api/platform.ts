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

export interface TenantDirectCreatePayload {
  company_name: string
  contact_name: string
  contact_email: string
  contact_phone?: string | null
  tax_id?: string | null
  plan_code: string
  tenant_code: string
  owner_username: string
  address?: string | null
  seed_default_products?: boolean
  seed_default_promotions?: boolean
}

export interface TenantDirectCreateResponse {
  tenant_id: string
  tenant_code: string
  owner_username: string
  one_time_password: string
}

export function directCreateTenant(payload: TenantDirectCreatePayload) {
  return client.post<TenantDirectCreateResponse>('/platform/tenants/direct-create', payload)
}

export interface TenantModulesRead {
  online_ordering: boolean
  marketplace: boolean
  business_intelligence: boolean
  consignment_books: boolean
  line: boolean
  events: boolean
}

export interface TenantModulesUpdate {
  online_ordering?: boolean
  marketplace?: boolean
  business_intelligence?: boolean
  consignment_books?: boolean
  line?: boolean
  events?: boolean
}

export function getTenantModules(id: string) {
  return client.get<TenantModulesRead>(`/platform/tenants/${id}/modules`)
}

export function updateTenantModules(id: string, payload: TenantModulesUpdate) {
  return client.patch<TenantModulesRead>(`/platform/tenants/${id}/modules`, payload)
}

// ----- Plans (admin view) ---------------------------------------------------

export function listPlans() {
  return client.get<SubscriptionPlanRead[]>('/platform/plans')
}

export interface PlatformDashboardStats {
  pending_applications: number
  pending_marketplace_listings: number
  active_tenants: number
  suspended_tenants: number
  marketplace_orders_today: number
  marketplace_revenue_today_cents: number
}

export function fetchPlatformDashboard() {
  return client.get<PlatformDashboardStats>('/platform/dashboard')
}

// ----- Marketplace applications ---------------------------------------------

export function listMarketplaceApplications(status = 'pending') {
  return client.get<import('./marketplace').MarketplaceListing[]>('/platform/marketplace/applications', {
    params: { status_filter: status },
  })
}

export function approveMarketplaceListing(id: string) {
  return client.post<import('./marketplace').MarketplaceListing>(
    `/platform/marketplace/applications/${id}/approve`,
  )
}

export function suspendMarketplaceListing(id: string) {
  return client.post<import('./marketplace').MarketplaceListing>(
    `/platform/marketplace/applications/${id}/suspend`,
  )
}

// ----- Marketplace banners --------------------------------------------------

export interface MarketplaceBanner {
  id: string
  title: string
  subtitle: string | null
  image_url: string
  link_type: string
  link_target: string | null
  sort_order: number
  is_active: boolean
  starts_at: string | null
  ends_at: string | null
  created_at: string
  updated_at: string
}

export interface MarketplaceBannerPayload {
  title?: string
  subtitle?: string | null
  image_url?: string
  link_type?: string
  link_target?: string | null
  sort_order?: number
  is_active?: boolean
  starts_at?: string | null
  ends_at?: string | null
}

export function listMarketplaceBanners() {
  return client.get<MarketplaceBanner[]>('/platform/marketplace-banners')
}

export function createMarketplaceBanner(payload: MarketplaceBannerPayload) {
  return client.post<MarketplaceBanner>('/platform/marketplace-banners', payload)
}

export function updateMarketplaceBanner(id: string, payload: MarketplaceBannerPayload) {
  return client.patch<MarketplaceBanner>(`/platform/marketplace-banners/${id}`, payload)
}

export function deleteMarketplaceBanner(id: string) {
  return client.delete(`/platform/marketplace-banners/${id}`)
}

export function uploadPlatformImage(file: File) {
  const form = new FormData()
  form.append('file', file)
  return client.post<{ url: string }>('/platform/uploads/images', form)
}
