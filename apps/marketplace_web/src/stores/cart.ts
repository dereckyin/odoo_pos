import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { MarketplaceMenuMeta, PublicProduct, SelectedOption } from '@/types'

export interface CartLine {
  lineKey: string
  product: PublicProduct
  qty: number
  note: string
  selectedOptions: SelectedOption[]
}

function lineKey(productId: string, options: SelectedOption[]) {
  const sig = [...options].map((o) => `${o.group_id}:${o.choice_id}`).sort().join('|')
  return `${productId}|${sig}`
}

function unitPriceCents(product: PublicProduct, options: SelectedOption[]) {
  return product.price_cents + options.reduce((s, o) => s + o.price_delta_cents, 0)
}

export const useCartStore = defineStore('cart', () => {
  const lines = ref<CartLine[]>([])
  const storeSlug = ref<string | null>(null)
  const storeMeta = ref<MarketplaceMenuMeta | null>(null)

  const itemCount = computed(() => lines.value.reduce((s, l) => s + l.qty, 0))
  const subtotalCents = computed(() =>
    lines.value.reduce((s, l) => s + unitPriceCents(l.product, l.selectedOptions) * l.qty, 0),
  )
  const totalCents = computed(() => {
    const delivery = storeMeta.value?.delivery_fee_cents ?? 0
    return subtotalCents.value + delivery
  })

  function bindStore(meta: MarketplaceMenuMeta) {
    if (storeSlug.value && storeSlug.value !== meta.slug && lines.value.length > 0) {
      throw new Error('DIFFERENT_STORE')
    }
    storeSlug.value = meta.slug
    storeMeta.value = meta
  }

  function tryBindStore(meta: MarketplaceMenuMeta): boolean {
    if (storeSlug.value && storeSlug.value !== meta.slug && lines.value.length > 0) {
      return false
    }
    bindStore(meta)
    return true
  }

  function add(product: PublicProduct, qty = 1, selectedOptions: SelectedOption[] = []) {
    const key = lineKey(product.id, selectedOptions)
    const existing = lines.value.find((l) => l.lineKey === key)
    if (existing) {
      existing.qty += qty
    } else {
      lines.value.push({ lineKey: key, product, qty, note: '', selectedOptions })
    }
  }

  function setQty(key: string, qty: number) {
    const line = lines.value.find((l) => l.lineKey === key)
    if (!line) return
    if (qty <= 0) lines.value = lines.value.filter((l) => l.lineKey !== key)
    else line.qty = qty
  }

  function clear() {
    lines.value = []
    storeSlug.value = null
    storeMeta.value = null
  }

  return {
    lines,
    storeSlug,
    storeMeta,
    itemCount,
    subtotalCents,
    totalCents,
    bindStore,
    tryBindStore,
    add,
    setQty,
    clear,
    unitPriceCents,
  }
})
