import client from './client'
import type { SubscriptionPlanRead } from '@/types'

// ----- Tenant payment-gateway settings -------------------------------------

export interface TenantPaymentSettingRead {
  id: string
  tenant_id: string
  driver: string
  is_enabled: boolean
  is_sandbox: boolean
  merchant_id: string | null
}

export interface TenantPaymentSettingUpsert {
  driver: 'ecpay' | 'newebpay' | 'linepay' | 'cash'
  is_enabled?: boolean
  is_sandbox?: boolean
  merchant_id?: string | null
  hash_key?: string | null
  hash_iv?: string | null
  channel_id?: string | null
  channel_secret?: string | null
}

export function listPaymentSettings() {
  return client.get<TenantPaymentSettingRead[]>('/tenant/payment-settings')
}

export function upsertPaymentSetting(payload: TenantPaymentSettingUpsert) {
  return client.put<TenantPaymentSettingRead>('/tenant/payment-settings', payload)
}

export function deletePaymentSetting(driver: string) {
  return client.delete(`/tenant/payment-settings/${driver}`)
}

// ----- Tenant invoice-gateway settings -------------------------------------

export interface TenantInvoiceSettingRead {
  id: string
  tenant_id: string
  driver: string
  is_enabled: boolean
  is_sandbox: boolean
  merchant_id: string | null
  company_tax_id: string | null
}

export interface TenantInvoiceSettingUpsert {
  driver: 'ecpay' | 'ezpay'
  is_enabled?: boolean
  is_sandbox?: boolean
  merchant_id?: string | null
  hash_key?: string | null
  hash_iv?: string | null
  company_tax_id?: string | null
}

export function listInvoiceSettings() {
  return client.get<TenantInvoiceSettingRead[]>('/tenant/invoice-settings')
}

export function upsertInvoiceSetting(payload: TenantInvoiceSettingUpsert) {
  return client.put<TenantInvoiceSettingRead>('/tenant/invoice-settings', payload)
}

// ----- Subscription / usage / audit logs -----------------------------------

export interface TenantSubscriptionRead {
  id: string
  tenant_id: string
  plan_id: string
  status: string
  started_at: string
  current_period_end: string | null
  cancelled_at: string | null
}

export interface UsageCounterRead {
  metric: string
  period: string
  value: number
}

export interface AuditLogRead {
  id: string
  tenant_id: string | null
  user_id: string | null
  action: string
  resource_type: string
  resource_id: string | null
  ip: string | null
  created_at: string
  extra: Record<string, any> | null
}

export function getMySubscription() {
  return client.get<TenantSubscriptionRead | null>('/tenant/subscription')
}

export function getMyPlan() {
  return client.get<SubscriptionPlanRead | null>('/tenant/plan')
}

export function getMyUsage() {
  return client.get<UsageCounterRead[]>('/tenant/usage')
}

export interface AuditLogQuery {
  action?: string
  resource_type?: string
  limit?: number
}

export function listAuditLogs(params: AuditLogQuery = {}) {
  return client.get<AuditLogRead[]>('/tenant/audit-logs', { params })
}

export interface TenantGeneralSettings {
  timezone: string
}

export function getGeneralSettings() {
  return client.get<TenantGeneralSettings>('/tenant/general-settings')
}

export function updateGeneralSettings(payload: Partial<TenantGeneralSettings>) {
  return client.patch<TenantGeneralSettings>('/tenant/general-settings', payload)
}

export interface TenantModulesRead {
  online_ordering: boolean
  marketplace: boolean
  business_intelligence: boolean
  consignment_books: boolean
}

export function getModules() {
  return client.get<TenantModulesRead>('/tenant/modules')
}
