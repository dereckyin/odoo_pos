import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { CartLine, SelectedOption } from '@/types'
import { useSessionStore } from './session'

function lineKey(productId: string, options: SelectedOption[], note: string) {
  const opt = options
    .map((o) => `${o.group_id}:${o.choice_id}`)
    .sort()
    .join('|')
  return `${productId}::${opt}::${note}`
}

export function unitPrice(baseCents: number, options: SelectedOption[]) {
  return baseCents + options.reduce((s, o) => s + o.price_delta_cents, 0)
}

export function optionsLabel(options: SelectedOption[]) {
  return options.map((o) => o.choice_name).join('・')
}

export const useCartStore = defineStore('cart', () => {
  const lines = ref<CartLine[]>([])

  const count = computed(() => lines.value.reduce((a, l) => a + l.qty, 0))
  const subtotal = computed(() => lines.value.reduce((a, l) => a + l.unitCents * l.qty, 0))

  function belowMin() {
    const session = useSessionStore()
    if (session.mode !== 'delivery' || !session.store) return false
    return subtotal.value < session.store.deliveryMinCents
  }

  function grandTotal() {
    const session = useSessionStore()
    return Math.max(0, subtotal.value + session.deliveryFee - session.discount)
  }

  function addLine(input: {
    productId: string
    name: string
    baseCents: number
    qty: number
    options: SelectedOption[]
    note: string
    noDelivery: boolean
  }) {
    const unitCents = unitPrice(input.baseCents, input.options)
    const key = lineKey(input.productId, input.options, input.note)
    const existing = lines.value.find((l) => l.key === key)
    if (existing) {
      existing.qty += input.qty
      return
    }
    lines.value.push({
      key,
      productId: input.productId,
      name: input.name,
      qty: input.qty,
      unitCents,
      options: input.options,
      optionsLabel: optionsLabel(input.options),
      note: input.note,
      noDelivery: input.noDelivery,
    })
  }

  function replaceLine(
    index: number,
    input: {
      productId: string
      name: string
      baseCents: number
      qty: number
      options: SelectedOption[]
      note: string
      noDelivery: boolean
    },
  ) {
    const unitCents = unitPrice(input.baseCents, input.options)
    lines.value[index] = {
      key: lineKey(input.productId, input.options, input.note),
      productId: input.productId,
      name: input.name,
      qty: input.qty,
      unitCents,
      options: input.options,
      optionsLabel: optionsLabel(input.options),
      note: input.note,
      noDelivery: input.noDelivery,
    }
  }

  function changeQty(index: number, delta: number) {
    const line = lines.value[index]
    if (!line) return
    line.qty += delta
    if (line.qty <= 0) lines.value.splice(index, 1)
  }

  function removeNoDelivery() {
    const removed = lines.value.filter((l) => l.noDelivery).map((l) => l.name)
    lines.value = lines.value.filter((l) => !l.noDelivery)
    return removed
  }

  function clear() {
    lines.value = []
  }

  return {
    lines,
    count,
    subtotal,
    belowMin,
    grandTotal,
    addLine,
    replaceLine,
    changeQty,
    removeNoDelivery,
    clear,
  }
})
