import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { Product, SelectedOption } from '@/types'

export type DiscountType = 'none' | 'percentage' | 'amount'

export interface CartLine {
  lineKey: string
  id: string
  product: Product
  qty: number
  note: string
  selectedOptions: SelectedOption[]
}

function lineKey(productId: string, options: SelectedOption[]) {
  const sig = [...options].map((o) => `${o.group_id}:${o.choice_id}`).sort().join('|')
  return `${productId}|${sig}`
}

export const useCartStore = defineStore('cart', () => {
  const lines = ref<CartLine[]>([])
  const note = ref('')
  const discountType = ref<DiscountType>('none')
  const discountValue = ref(0)
  const tableLabel = ref<string | null>(null)
  const sourceGuestOrderId = ref<string | null>(null)

  const itemCount = computed(() => lines.value.reduce((s, l) => s + l.qty, 0))

  function add(product: Product, qty = 1, selectedOptions: SelectedOption[] = []) {
    const key = lineKey(product.id, selectedOptions)
    const existing = lines.value.find((l) => l.lineKey === key)
    if (existing) {
      existing.qty += qty
    } else {
      lines.value.push({
        lineKey: key,
        id: crypto.randomUUID(),
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
    if (qty <= 0) lines.value = lines.value.filter((l) => l.lineKey !== lineKey)
    else line.qty = qty
  }

  function clear() {
    lines.value = []
    note.value = ''
    discountType.value = 'none'
    discountValue.value = 0
    tableLabel.value = null
    sourceGuestOrderId.value = null
  }

  return {
    lines,
    note,
    discountType,
    discountValue,
    tableLabel,
    sourceGuestOrderId,
    itemCount,
    add,
    setQty,
    clear,
  }
})
