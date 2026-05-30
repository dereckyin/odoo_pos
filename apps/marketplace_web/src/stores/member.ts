import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PublicMember } from '@/types'

const STORAGE_KEY = 'mp_member'

export const useMemberStore = defineStore('member', () => {
  const member = ref<PublicMember | null>(null)

  const isLoggedIn = computed(() => member.value != null)

  function restore() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) member.value = JSON.parse(raw)
    } catch {
      member.value = null
    }
  }

  function setMember(m: PublicMember) {
    member.value = m
    localStorage.setItem(STORAGE_KEY, JSON.stringify(m))
  }

  function logout() {
    member.value = null
    localStorage.removeItem(STORAGE_KEY)
  }

  function estimatedEarnPoints(subtotalCents: number) {
    return Math.floor(subtotalCents / 100)
  }

  restore()
  return { member, isLoggedIn, setMember, logout, estimatedEarnPoints }
})
