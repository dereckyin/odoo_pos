import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { ShiftRead } from '@/types'
import * as ordersApi from '@/api/orders'

export const useShiftStore = defineStore('shift', () => {
  const current = ref<ShiftRead | null>(null)
  const loading = ref(false)

  async function refresh() {
    loading.value = true
    try {
      const { data } = await ordersApi.fetchCurrentShift()
      current.value = data
    } finally {
      loading.value = false
    }
  }

  async function open(openingCashCents = 0) {
    const { data } = await ordersApi.openShift(openingCashCents)
    current.value = data
    return data
  }

  async function close(countedCashCents: number) {
    const { data } = await ordersApi.closeShift(countedCashCents)
    current.value = null
    return data
  }

  return { current, loading, refresh, open, close }
})
