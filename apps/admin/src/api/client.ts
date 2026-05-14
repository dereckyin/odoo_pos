import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

/** 預設走 Vite proxy（/api → 本機 8000）。設為完整 URL 時略過 proxy，直接打後端。 */
function resolveApiBaseURL(): string {
  const raw = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim()
  if (raw) return raw.replace(/\/$/, '')
  return '/api'
}

const client = axios.create({
  baseURL: resolveApiBaseURL(),
  timeout: 30_000,
})

/** Paths that must not send a stale Bearer (login / refresh / public flows). */
function isAnonymousApiPath(config: { baseURL?: string; url?: string }): boolean {
  const base = (config.baseURL || '').replace(/\/$/, '')
  const path = (config.url || '').replace(/^\//, '')
  const full = `${base}/${path}`.replace(/\/+/g, '/')
  return (
    full.includes('/auth/admin-login') ||
    full.includes('/auth/refresh') ||
    full.includes('/public/')
  )
}

client.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (!isAnonymousApiPath(config)) {
    if (auth.accessToken) {
      config.headers.Authorization = `Bearer ${auth.accessToken}`
    }
  } else {
    delete config.headers.Authorization
  }
  const overrideTenant = (config as any).tenantOverride as string | undefined
  if (auth.isPlatformSuper && overrideTenant) {
    config.headers['X-Tenant-Id'] = overrideTenant
  }
  return config
})

client.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      const auth = useAuthStore()
      const ok = await auth.refreshSession()
      if (ok) {
        original.headers.Authorization = `Bearer ${auth.accessToken}`
        return client(original)
      }
      auth.logout()
    }
    return Promise.reject(error)
  },
)

export default client
