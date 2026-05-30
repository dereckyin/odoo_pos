import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { PublicProduct, SelectedOption } from '@/types'

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
  const customerNote = ref('')
  const partySize = ref<number | null>(null)

  const itemCount = computed(() => lines.value.reduce((s, l) => s + l.qty, 0))
  const subtotalCents = computed(() =>
    lines.value.reduce((s, l) => s + unitPriceCents(l.product, l.selectedOptions) * l.qty, 0),
  )

  function add(product: PublicProduct, qty = 1, selectedOptions: SelectedOption[] = []) {
    const key = lineKey(product.id, selectedOptions)
    const existing = lines.value.find((l) => l.lineKey === key)
    if (existing) {
      existing.qty += qty
    } else {
      lines.value.push({
        lineKey: key,
        product,
        qty,
        note: '',
        selectedOptions,
      })
    }
  }

  function setQty(lineKey: string, qty: number) {
    const line = lines.value.find((l) => l.lineKey === lineKey)
    if (!line) return
    if (qty <= 0) {
      lines.value = lines.value.filter((l) => l.lineKey !== lineKey)
    } else {
      line.qty = qty
    }
  }

  function setNote(lineKey: string, note: string) {
    const line = lines.value.find((l) => l.lineKey === lineKey)
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
    unitPriceCents,
  }
})
