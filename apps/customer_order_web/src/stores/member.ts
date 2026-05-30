import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface PublicMember {
  id: string
  name: string
  phone: string
  points: number
  level_id: string | null
}

export const useMemberStore = defineStore('member', () => {
  const member = ref<PublicMember | null>(null)

  const isLoggedIn = computed(() => member.value != null)
  const estimatedEarnPoints = (subtotalCents: number) =>
    member.value ? Math.max(0, Math.floor(subtotalCents / 100)) : 0

  function setMember(m: PublicMember | null) {
    member.value = m
    if (m) {
      localStorage.setItem('cust_member', JSON.stringify(m))
    } else {
      localStorage.removeItem('cust_member')
    }
  }

  function restore() {
    const raw = localStorage.getItem('cust_member')
    if (raw) {
      try {
        member.value = JSON.parse(raw) as PublicMember
      } catch {
        member.value = null
      }
    }
  }

  function logout() {
    setMember(null)
  }

  return { member, isLoggedIn, estimatedEarnPoints, setMember, restore, logout }
})
