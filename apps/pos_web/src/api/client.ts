import axios from 'axios'
import { useAuthStore } from '@/stores/auth'

function resolveApiBaseURL(): string {
  const raw = (import.meta.env.VITE_API_BASE as string | undefined)?.trim()
  if (raw) return raw.replace(/\/$/, '')
  return '/api'
}

const client = axios.create({
  baseURL: resolveApiBaseURL(),
  timeout: 30_000,
})

const ANON = ['/auth/login', '/auth/refresh', '/auth/pin-login']

client.interceptors.request.use((config) => {
  const auth = useAuthStore()
  const path = `${config.baseURL || ''}/${config.url || ''}`
  const isAnon = ANON.some((p) => path.includes(p))
  if (!isAnon && auth.accessToken) {
    config.headers.Authorization = `Bearer ${auth.accessToken}`
  }
  return config
})

client.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && original && !original._retry) {
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
