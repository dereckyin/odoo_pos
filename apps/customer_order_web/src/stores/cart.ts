import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PublicProduct } from '@/types'

export interface CartLine {
  product: PublicProduct
  qty: number
  note: string
}

export const useCartStore = defineStore('cart', () => {
  const lines = ref<CartLine[]>([])
  const customerNote = ref('')
  const partySize = ref<number | null>(null)

  const itemCount = computed(() => lines.value.reduce((s, l) => s + l.qty, 0))
  const subtotalCents = computed(() =>
    lines.value.reduce((s, l) => s + l.product.price_cents * l.qty, 0),
  )

  function add(product: PublicProduct, qty = 1) {
    const existing = lines.value.find((l) => l.product.id === product.id)
    if (existing) {
      existing.qty += qty
    } else {
      lines.value.push({ product, qty, note: '' })
    }
  }
  function setQty(productId: string, qty: number) {
    const line = lines.value.find((l) => l.product.id === productId)
    if (!line) return
    if (qty <= 0) {
      lines.value = lines.value.filter((l) => l.product.id !== productId)
    } else {
      line.qty = qty
    }
  }
  function setNote(productId: string, note: string) {
    const line = lines.value.find((l) => l.product.id === productId)
    if (line) line.note = note
  }
  function clear() {
    lines.value = []
    customerNote.value = ''
    partySize.value = null
  }

  return {
    lines,
    customerNote,
    partySize,
    itemCount,
    subtotalCents,
    add,
    setQty,
    setNote,
    clear,
  }
})
