import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PublicMember } from '@/types'

const STORAGE_KEY = 'mp_member'
const TOKEN_KEY = 'mp_member_token'

let tokenGetter: () => string | null = () => null

/** Allow the api client to read the current token without a circular import. */
export function getMemberToken(): string | null {
  return tokenGetter()
}

export const useMemberStore = defineStore('member', () => {
  const member = ref<PublicMember | null>(null)
  const token = ref<string | null>(null)

  const isLoggedIn = computed(() => member.value != null && token.value != null)
  const points = computed(() => member.value?.cross_store_points ?? member.value?.points ?? 0)

  function restore() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) member.value = JSON.parse(raw)
      token.value = localStorage.getItem(TOKEN_KEY)
    } catch {
      member.value = null
      token.value = null
    }
  }

  function setMember(m: PublicMember) {
    member.value = m
    localStorage.setItem(STORAGE_KEY, JSON.stringify(m))
    if (m.token) {
      token.value = m.token
      localStorage.setItem(TOKEN_KEY, m.token)
    }
  }

  function updatePoints(p: number) {
    if (member.value) {
      member.value.cross_store_points = p
      member.value.points = p
      localStorage.setItem(STORAGE_KEY, JSON.stringify(member.value))
    }
  }

  function logout() {
    member.value = null
    token.value = null
    localStorage.removeItem(STORAGE_KEY)
    localStorage.removeItem(TOKEN_KEY)
  }

  function estimatedEarnPoints(subtotalCents: number) {
    return Math.floor(subtotalCents / 100)
  }

  restore()
  tokenGetter = () => token.value
  return { member, token, isLoggedIn, points, setMember, updatePoints, logout, estimatedEarnPoints }
})
