import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import type { MarketplaceMenuMeta, PublicProduct, SelectedOption } from '@/types'

export interface CartLine {
  lineKey: string
  product: PublicProduct
  qty: number
  note: string
  selectedOptions: SelectedOption[]
}

export interface StoreCart {
  slug: string
  meta: MarketplaceMenuMeta
  lines: CartLine[]
}

const STORAGE_KEY = 'mp_cart_v2'

function lineKey(productId: string, options: SelectedOption[]) {
  const sig = [...options].map((o) => `${o.group_id}:${o.choice_id}`).sort().join('|')
  return `${productId}|${sig}`
}

function unitPriceCents(product: PublicProduct, options: SelectedOption[]) {
  return product.price_cents + options.reduce((s, o) => s + o.price_delta_cents, 0)
}

function storeSubtotal(cart: StoreCart) {
  return cart.lines.reduce((s, l) => s + unitPriceCents(l.product, l.selectedOptions) * l.qty, 0)
}

export const useCartStore = defineStore('cart', () => {
  const carts = ref<Record<string, StoreCart>>({})

  function restore() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) carts.value = JSON.parse(raw)
    } catch {
      carts.value = {}
    }
  }
  restore()

  watch(
    carts,
    (v) => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
      } catch {
        /* ignore quota errors */
      }
    },
    { deep: true },
  )

  const storeSlugs = computed(() => Object.keys(carts.value))
  const storeCount = computed(() => storeSlugs.value.length)
  const itemCount = computed(() =>
    Object.values(carts.value).reduce((s, c) => s + c.lines.reduce((n, l) => n + l.qty, 0), 0),
  )
  const subtotalCents = computed(() =>
    Object.values(carts.value).reduce((s, c) => s + storeSubtotal(c), 0),
  )
  const orderedCarts = computed(() => Object.values(carts.value))

  function getCart(slug: string): StoreCart | undefined {
    return carts.value[slug]
  }

  function storeSubtotalCents(slug: string): number {
    const c = carts.value[slug]
    return c ? storeSubtotal(c) : 0
  }

  function storeItemCount(slug: string): number {
    const c = carts.value[slug]
    return c ? c.lines.reduce((n, l) => n + l.qty, 0) : 0
  }

  function ensureStore(meta: MarketplaceMenuMeta) {
    if (!carts.value[meta.slug]) {
      carts.value[meta.slug] = { slug: meta.slug, meta, lines: [] }
    } else {
      // refresh meta (delivery fee / hours may have changed)
      carts.value[meta.slug].meta = meta
    }
  }

  function add(meta: MarketplaceMenuMeta, product: PublicProduct, qty = 1, selectedOptions: SelectedOption[] = []) {
    ensureStore(meta)
    const cart = carts.value[meta.slug]
    const key = lineKey(product.id, selectedOptions)
    const existing = cart.lines.find((l) => l.lineKey === key)
    if (existing) existing.qty += qty
    else cart.lines.push({ lineKey: key, product, qty, note: '', selectedOptions })
  }

  function setQty(slug: string, key: string, qty: number) {
    const cart = carts.value[slug]
    if (!cart) return
    const line = cart.lines.find((l) => l.lineKey === key)
    if (!line) return
    if (qty <= 0) {
      cart.lines = cart.lines.filter((l) => l.lineKey !== key)
      if (cart.lines.length === 0) delete carts.value[slug]
    } else {
      line.qty = qty
    }
  }

  function clearStore(slug: string) {
    delete carts.value[slug]
  }

  function clearAll() {
    carts.value = {}
  }

  return {
    carts,
    storeSlugs,
    storeCount,
    orderedCarts,
    itemCount,
    subtotalCents,
    getCart,
    storeSubtotalCents,
    storeItemCount,
    ensureStore,
    add,
    setQty,
    clearStore,
    clearAll,
    unitPriceCents,
  }
})
