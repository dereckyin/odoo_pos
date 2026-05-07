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
