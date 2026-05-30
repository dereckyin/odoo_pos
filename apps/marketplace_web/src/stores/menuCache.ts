import { defineStore } from 'pinia'
import { ref } from 'vue'
import { fetchStoreMenu } from '@/api'
import type { MarketplaceMenu } from '@/types'

export const useMenuCacheStore = defineStore('menuCache', () => {
  const menus = ref<Record<string, MarketplaceMenu>>({})
  const loading = ref<Record<string, boolean>>({})

  async function ensureMenu(slug: string): Promise<MarketplaceMenu> {
    const cached = menus.value[slug]
    if (cached) return cached
    if (loading.value[slug]) {
      await new Promise<void>((resolve) => {
        const check = () => {
          if (menus.value[slug] || !loading.value[slug]) resolve()
          else setTimeout(check, 50)
        }
        check()
      })
      const again = menus.value[slug]
      if (again) return again
    }
    loading.value[slug] = true
    try {
      const { data } = await fetchStoreMenu(slug)
      menus.value[slug] = data
      return data
    } finally {
      loading.value[slug] = false
    }
  }

  function getMenu(slug: string): MarketplaceMenu | null {
    return menus.value[slug] ?? null
  }

  return { menus, ensureMenu, getMenu }
})
