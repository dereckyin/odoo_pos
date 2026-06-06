import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getModules } from '@/api/tenant'

export const useTenantModulesStore = defineStore('tenantModules', () => {
  const onlineOrdering = ref(false)
  const marketplace = ref(false)
  const businessIntelligence = ref(false)
  const consignmentBooks = ref(false)
  const loaded = ref(false)
  const loading = ref(false)

  const guestOrdersEnabled = computed(
    () => onlineOrdering.value || marketplace.value,
  )

  async function fetch() {
    loading.value = true
    try {
      const { data } = await getModules()
      onlineOrdering.value = data.online_ordering
      marketplace.value = data.marketplace
      businessIntelligence.value = data.business_intelligence
      consignmentBooks.value = data.consignment_books
      loaded.value = true
    } catch {
      onlineOrdering.value = false
      marketplace.value = false
      businessIntelligence.value = false
      consignmentBooks.value = false
      loaded.value = false
    } finally {
      loading.value = false
    }
  }

  function reset() {
    onlineOrdering.value = false
    marketplace.value = false
    businessIntelligence.value = false
    consignmentBooks.value = false
    loaded.value = false
  }

  return {
    onlineOrdering,
    marketplace,
    businessIntelligence,
    consignmentBooks,
    guestOrdersEnabled,
    loaded,
    loading,
    fetch,
    reset,
  }
})
