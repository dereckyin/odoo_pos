import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

const client = axios.create({
  baseURL: '/api',
  timeout: 30_000,
})

client.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (auth.accessToken) {
    config.headers.Authorization = `Bearer ${auth.accessToken}`
  }
  // Platform super can act on behalf of a specific tenant by passing
  // X-Tenant-Id explicitly. For everyone else the backend pulls the
  // tenant directly from the JWT — never trust ``store_id`` / tenant
  // from request bodies.
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
