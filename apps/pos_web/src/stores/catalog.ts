import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { Category, OptionGroup, Product, ProductOptionLink, ProductOptionOverride, ProductWithOptions } from '@/types'
import * as catalogApi from '@/api/catalog'

export const useCatalogStore = defineStore('catalog', () => {
  const categories = ref<Category[]>([])
  const products = ref<Product[]>([])
  const optionGroups = ref<OptionGroup[]>([])
  const loading = ref(false)
  const selectedCategoryId = ref<string | null>(null)
  const searchQuery = ref('')

  const visibleCategories = computed(() =>
    categories.value.filter((c) => !c.hide_from_pos_browse),
  )

  const visibleProducts = computed(() => {
    let list = products.value.filter((p) => p.is_active && !p.hide_from_pos_browse)
    if (selectedCategoryId.value) {
      list = list.filter((p) => p.category_id === selectedCategoryId.value)
    }
    const q = searchQuery.value.trim().toLowerCase()
    if (q) {
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          p.barcodes.some((b) => b.includes(q)),
      )
    }
    return list
  })

  async function load() {
    loading.value = true
    try {
      const [catRes, prodRes, optRes] = await Promise.all([
        catalogApi.fetchCategories(),
        catalogApi.fetchProducts({ limit: 200 }),
        catalogApi.fetchOptionGroups(),
      ])
      categories.value = catRes.data
      products.value = prodRes.data
      optionGroups.value = optRes.data
    } finally {
      loading.value = false
    }
  }

  async function loadProductOptions(productId: string): Promise<ProductWithOptions> {
    const product = products.value.find((p) => p.id === productId)
    if (!product) throw new Error('product not found')
    const [linksRes, overridesRes] = await Promise.all([
      catalogApi.fetchProductOptionLinks(productId),
      catalogApi.fetchProductOptionOverrides(productId),
    ])
    const groups = buildProductOptionGroups(linksRes.data, optionGroups.value, overridesRes.data)
    return { ...product, option_groups: groups }
  }

  return {
    categories,
    products,
    loading,
    selectedCategoryId,
    searchQuery,
    visibleCategories,
    visibleProducts,
    load,
    loadProductOptions,
  }
})

function buildProductOptionGroups(
  links: ProductOptionLink[],
  allGroups: OptionGroup[],
  overrides: ProductOptionOverride[],
) {
  const overrideMap = new Map(overrides.map((o) => [o.option_choice_id, o]))
  const byId = new Map(allGroups.map((g) => [g.id, g]))
  const out: OptionGroup[] = []
  for (const link of [...links].sort((a, b) => a.sort_order - b.sort_order)) {
    const base = byId.get(link.option_group_id)
    if (!base) continue
    const choices = base.choices
      .filter((c) => c.is_active)
      .map((c) => {
        const ov = overrideMap.get(c.id)
        if (ov?.is_hidden) return null
        return {
          ...c,
          price_delta_cents: ov?.price_delta_cents ?? c.price_delta_cents,
        }
      })
      .filter((c): c is NonNullable<typeof c> => c != null)
    out.push({
      ...base,
      is_required: link.is_required ?? base.is_required,
      choices,
    })
  }
  return out
}
