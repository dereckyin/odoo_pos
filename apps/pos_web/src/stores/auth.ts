import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import * as authApi from '@/api/auth'
import type { SessionRead } from '@/types'

const TERMINAL_KEYS = [
  'tenant_code', 'store_code', 'terminal_code', 'terminal_api_key',
] as const

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref(localStorage.getItem('access_token') || '')
  const refreshTokenVal = ref(localStorage.getItem('refresh_token') || '')
  const userId = ref(localStorage.getItem('user_id') || '')
  const username = ref(localStorage.getItem('username') || '')
  const displayName = ref(localStorage.getItem('display_name') || '')
  const tenantId = ref(localStorage.getItem('tenant_id') || '')
  const storeId = ref(localStorage.getItem('store_id') || '')
  const terminalId = ref(localStorage.getItem('terminal_id') || '')

  const tenantCode = ref(localStorage.getItem('tenant_code') || '')
  const storeCode = ref(localStorage.getItem('store_code') || '')
  const terminalCode = ref(localStorage.getItem('terminal_code') || '')
  const terminalApiKey = ref(localStorage.getItem('terminal_api_key') || '')

  const isAuthenticated = computed(() => !!accessToken.value)

  function setSession(s: SessionRead) {
    accessToken.value = s.access_token
    refreshTokenVal.value = s.refresh_token
    userId.value = s.user_id
    username.value = s.username
    displayName.value = s.display_name
    tenantId.value = s.tenant_id || ''
    storeId.value = s.store_id || ''
    terminalId.value = s.terminal_id || ''
    localStorage.setItem('access_token', s.access_token)
    localStorage.setItem('refresh_token', s.refresh_token)
    localStorage.setItem('user_id', s.user_id)
    localStorage.setItem('username', s.username)
    localStorage.setItem('display_name', s.display_name)
    localStorage.setItem('tenant_id', s.tenant_id || '')
    localStorage.setItem('store_id', s.store_id || '')
    localStorage.setItem('terminal_id', s.terminal_id || '')
  }

  function saveTerminalConfig(cfg: {
    tenant_code: string
    store_code: string
    terminal_code: string
    terminal_api_key: string
  }) {
    tenantCode.value = cfg.tenant_code
    storeCode.value = cfg.store_code
    terminalCode.value = cfg.terminal_code
    terminalApiKey.value = cfg.terminal_api_key
    localStorage.setItem('tenant_code', cfg.tenant_code)
    localStorage.setItem('store_code', cfg.store_code)
    localStorage.setItem('terminal_code', cfg.terminal_code)
    localStorage.setItem('terminal_api_key', cfg.terminal_api_key)
  }

  async function login(user: string, password: string) {
    const { data } = await authApi.login({
      tenant_code: tenantCode.value,
      store_code: storeCode.value,
      terminal_code: terminalCode.value,
      terminal_api_key: terminalApiKey.value,
      username: user,
      password,
    })
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

  function logout() {
    const rt = refreshTokenVal.value
    accessToken.value = ''
    refreshTokenVal.value = ''
    userId.value = ''
    username.value = ''
    displayName.value = ''
    tenantId.value = ''
    storeId.value = ''
    terminalId.value = ''
    ;['access_token', 'refresh_token', 'user_id', 'username', 'display_name', 'tenant_id', 'store_id', 'terminal_id']
      .forEach((k) => localStorage.removeItem(k))
    if (rt) authApi.logout(rt).catch(() => {})
  }

  const hasTerminalConfig = computed(
    () => !!(tenantCode.value && storeCode.value && terminalCode.value && terminalApiKey.value),
  )

  return {
    accessToken,
    userId,
    username,
    displayName,
    tenantId,
    storeId,
    terminalId,
    tenantCode,
    storeCode,
    terminalCode,
    terminalApiKey,
    isAuthenticated,
    hasTerminalConfig,
    setSession,
    saveTerminalConfig,
    login,
    refreshSession,
    logout,
  }
})
