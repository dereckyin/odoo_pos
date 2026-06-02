import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getModules } from '@/api/tenant'

export const useTenantModulesStore = defineStore('tenantModules', () => {
  const onlineOrdering = ref(false)
  const marketplace = ref(false)
  const businessIntelligence = ref(false)
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
      loaded.value = true
    } catch {
      onlineOrdering.value = false
      marketplace.value = false
      businessIntelligence.value = false
      loaded.value = false
    } finally {
      loading.value = false
    }
  }

  function reset() {
    onlineOrdering.value = false
    marketplace.value = false
    businessIntelligence.value = false
    loaded.value = false
  }

  return {
    onlineOrdering,
    marketplace,
    businessIntelligence,
    guestOrdersEnabled,
    loaded,
    loading,
    fetch,
    reset,
  }
})
