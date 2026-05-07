import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as authApi from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref(localStorage.getItem('access_token') || '')
  const refreshTokenVal = ref(localStorage.getItem('refresh_token') || '')
  const userId = ref(localStorage.getItem('user_id') || '')
  const username = ref(localStorage.getItem('username') || '')
  const displayName = ref(localStorage.getItem('display_name') || '')
  const role = ref(localStorage.getItem('role') || '')

  const isAuthenticated = computed(() => !!accessToken.value)

  function setSession(s: {
    access_token: string; refresh_token: string; user_id: string
    username: string; display_name: string; role: string
  }) {
    accessToken.value = s.access_token
    refreshTokenVal.value = s.refresh_token
    userId.value = s.user_id
    username.value = s.username
    displayName.value = s.display_name
    role.value = s.role
    localStorage.setItem('access_token', s.access_token)
    localStorage.setItem('refresh_token', s.refresh_token)
    localStorage.setItem('user_id', s.user_id)
    localStorage.setItem('username', s.username)
    localStorage.setItem('display_name', s.display_name)
    localStorage.setItem('role', s.role)
  }

  async function login(user: string, password: string) {
    const { data } = await authApi.login(user, password)
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
    accessToken.value = ''
    refreshTokenVal.value = ''
    userId.value = ''
    username.value = ''
    displayName.value = ''
    role.value = ''
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user_id')
    localStorage.removeItem('username')
    localStorage.removeItem('display_name')
    localStorage.removeItem('role')
  }

  return { accessToken, refreshTokenVal, userId, username, displayName, role, isAuthenticated, login, refreshSession, logout }
})
