import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as authApi from '@/api/auth'
import type { SessionRead } from '@/types'

const KEYS = [
  'access_token', 'refresh_token', 'user_id', 'username', 'display_name',
  'role', 'tenant_id', 'tenant_code', 'store_id',
  'acting_tenant_id', 'acting_tenant_name',
] as const

export interface ActingTenant {
  id: string
  name: string
}

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref(localStorage.getItem('access_token') || '')
  const refreshTokenVal = ref(localStorage.getItem('refresh_token') || '')
  const userId = ref(localStorage.getItem('user_id') || '')
  const username = ref(localStorage.getItem('username') || '')
  const displayName = ref(localStorage.getItem('display_name') || '')
  const role = ref(localStorage.getItem('role') || '')
  const tenantId = ref(localStorage.getItem('tenant_id') || '')
  const tenantCode = ref(localStorage.getItem('tenant_code') || '')
  const storeId = ref(localStorage.getItem('store_id') || '')
  const actingTenantId = ref(localStorage.getItem('acting_tenant_id') || '')
  const actingTenantName = ref(localStorage.getItem('acting_tenant_name') || '')
  const mustChangePassword = ref(false)

  const isAuthenticated = computed(() => !!accessToken.value)
  const isPlatformSuper = computed(() => role.value === 'platform_super')
  const isPlatformMode = computed(() => isPlatformSuper.value && !actingTenantId.value)
  const isMerchantMode = computed(() => !isPlatformSuper.value || !!actingTenantId.value)
  const isPureTenantUser = computed(
    () =>
      !isPlatformSuper.value &&
      (role.value === 'tenant_owner' ||
        role.value === 'tenant_admin' ||
        role.value === 'admin'),
  )
  const isTenantAdmin = computed(
    () =>
      role.value === 'tenant_owner' ||
      role.value === 'tenant_admin' ||
      role.value === 'admin' ||
      (isPlatformSuper.value && !!actingTenantId.value),
  )

  function setSession(s: SessionRead) {
    accessToken.value = s.access_token
    refreshTokenVal.value = s.refresh_token
    userId.value = s.user_id
    username.value = s.username
    displayName.value = s.display_name
    role.value = s.role
    tenantId.value = s.tenant_id || ''
    tenantCode.value = s.tenant_code || ''
    storeId.value = s.store_id || ''
    mustChangePassword.value = !!s.must_change_password
    localStorage.setItem('access_token', s.access_token)
    localStorage.setItem('refresh_token', s.refresh_token)
    localStorage.setItem('user_id', s.user_id)
    localStorage.setItem('username', s.username)
    localStorage.setItem('display_name', s.display_name)
    localStorage.setItem('role', s.role)
    localStorage.setItem('tenant_id', s.tenant_id || '')
    localStorage.setItem('tenant_code', s.tenant_code || '')
    localStorage.setItem('store_id', s.store_id || '')
  }

  function enterTenantMode(tenant: ActingTenant) {
    actingTenantId.value = tenant.id
    actingTenantName.value = tenant.name
    localStorage.setItem('acting_tenant_id', tenant.id)
    localStorage.setItem('acting_tenant_name', tenant.name)
  }

  function exitTenantMode() {
    actingTenantId.value = ''
    actingTenantName.value = ''
    localStorage.removeItem('acting_tenant_id')
    localStorage.removeItem('acting_tenant_name')
  }

  async function login(user: string, password: string, tenant_code?: string, totp_code?: string) {
    const { data } = await authApi.login(user, password, tenant_code, totp_code)
    exitTenantMode()
    setSession(data)
  }

  async function refreshSession(): Promise<boolean> {
    if (!refreshTokenVal.value) return false
    try {
      const { data } = await authApi.refreshToken(refreshTokenVal.value)
      setSession(data)
      return true
    } catch {
      return false
    }
  }

  async function logout() {
    const rt = refreshTokenVal.value
    accessToken.value = ''
    refreshTokenVal.value = ''
    userId.value = ''
    username.value = ''
    displayName.value = ''
    role.value = ''
    tenantId.value = ''
    tenantCode.value = ''
    storeId.value = ''
    actingTenantId.value = ''
    actingTenantName.value = ''
    mustChangePassword.value = false
    KEYS.forEach((k) => localStorage.removeItem(k))
    if (rt) {
      try { await authApi.logout(rt) } catch { /* ignore */ }
    }
  }

  return {
    accessToken,
    refreshTokenVal,
    userId,
    username,
    displayName,
    role,
    tenantId,
    tenantCode,
    storeId,
    actingTenantId,
    actingTenantName,
    mustChangePassword,
    isAuthenticated,
    isPlatformSuper,
    isPlatformMode,
    isMerchantMode,
    isPureTenantUser,
    isTenantAdmin,
    login,
    refreshSession,
    logout,
    enterTenantMode,
    exitTenantMode,
  }
})
