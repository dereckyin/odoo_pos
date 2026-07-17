<template>
  <div v-if="open && product" class="overlay" @click.self="close">
    <div class="sheet">
      <div class="sheet-head">
        <div>
          <div class="t">{{ product.name }}</div>
          <div class="p"><small>NT$ </small><span class="num">{{ moneyYuan(unit) }}</span></div>
        </div>
        <button type="button" class="sheet-close" @click="close">✕</button>
      </div>
      <div class="sheet-body">
        <div v-for="g in product.optionGroups" :key="g.id" class="opt-group">
          <div class="opt-title">
            {{ g.name }}
            <span v-if="g.is_required" class="req">必選</span>
            <span v-else-if="g.selection_type === 'multi'" class="opt">
              可複選{{ g.max_selections ? `（最多 ${g.max_selections}）` : '' }}
            </span>
            <span v-else class="opt">選填</span>
          </div>
          <div class="chips">
            <button
              v-for="c in g.choices"
              :key="c.id"
              type="button"
              class="chip"
              :class="{ on: selected[g.id]?.has(c.id), so: c.soldout }"
              :disabled="!!c.soldout"
              @click="pick(g, c.id)"
            >
              {{ c.name }}
              <span v-if="c.soldout" class="pp">售完</span>
              <span v-else-if="c.price_delta_cents" class="pp">
                {{ c.price_delta_cents > 0 ? '+' : '−' }}{{ Math.abs(c.price_delta_cents) }}
              </span>
            </button>
          </div>
        </div>
        <div class="opt-group">
          <div class="opt-title">備註 <span class="opt">選填</span></div>
          <textarea v-model="note" class="note-input" rows="2" placeholder="例：不要辣、醬多一點" />
        </div>
      </div>
      <div class="sheet-foot">
        <div class="qty">
          <button type="button" @click="qty = Math.max(1, qty - 1)">－</button>
          <span class="n num">{{ qty }}</span>
          <button type="button" @click="qty += 1">＋</button>
        </div>
        <button type="button" class="btn-red" @click="confirm">
          {{ editIndex != null ? '更新餐點' : '加入訂單' }}
          <span> NT$ {{ moneyYuan(unit * qty) }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { moneyYuan } from '@/entry'
import type { MenuProduct, PublicOptionGroup, SelectedOption } from '@/types'

const props = defineProps<{
  open: boolean
  product: MenuProduct | null
  editIndex: number | null
  initialOptions?: SelectedOption[]
  initialQty?: number
  initialNote?: string
}>()

const emit = defineEmits<{
  close: []
  confirm: [payload: { options: SelectedOption[]; qty: number; note: string }]
}>()

const selected = reactive<Record<string, Set<string>>>({})
const qty = ref(1)
const note = ref('')

watch(
  () => [props.open, props.product, props.initialOptions] as const,
  () => {
    for (const k of Object.keys(selected)) delete selected[k]
    qty.value = props.initialQty ?? 1
    note.value = props.initialNote ?? ''
    const p = props.product
    if (!p) return
    if (props.initialOptions?.length) {
      for (const g of p.optionGroups) selected[g.id] = new Set()
      for (const o of props.initialOptions) {
        if (!selected[o.group_id]) selected[o.group_id] = new Set()
        selected[o.group_id].add(o.choice_id)
      }
      return
    }
    for (const g of p.optionGroups) {
      selected[g.id] = new Set()
      if (g.is_required && g.selection_type === 'single') {
        const def =
          g.choices.find((c) => c.is_default && !c.soldout) ||
          g.choices.find((c) => c.price_delta_cents === 0 && !c.soldout) ||
          g.choices.find((c) => !c.soldout)
        if (def) selected[g.id].add(def.id)
      }
    }
  },
  { immediate: true },
)

const unit = computed(() => {
  if (!props.product) return 0
  let extra = 0
  for (const g of props.product.optionGroups) {
    for (const id of selected[g.id] ?? []) {
      const c = g.choices.find((x) => x.id === id)
      if (c) extra += c.price_delta_cents
    }
  }
  return props.product.priceCents + extra
})

function pick(g: PublicOptionGroup, choiceId: string) {
  const set = selected[g.id] ?? new Set()
  if (g.selection_type === 'multi') {
    if (set.has(choiceId)) set.delete(choiceId)
    else {
      if (g.max_selections != null && set.size >= g.max_selections) {
        window.alert(`${g.name}最多選 ${g.max_selections} 樣`)
        return
      }
      set.add(choiceId)
    }
    selected[g.id] = new Set(set)
  } else {
    selected[g.id] = new Set([choiceId])
  }
}

function buildOptions(): SelectedOption[] {
  if (!props.product) return []
  const out: SelectedOption[] = []
  for (const g of props.product.optionGroups) {
    for (const id of selected[g.id] ?? []) {
      const c = g.choices.find((x) => x.id === id)
      if (!c) continue
      out.push({
        group_id: g.id,
        group_name: g.name,
        choice_id: c.id,
        choice_name: c.name,
        price_delta_cents: c.price_delta_cents,
      })
    }
  }
  return out
}

function confirm() {
  if (!props.product) return
  for (const g of props.product.optionGroups) {
    if (g.is_required && !(selected[g.id]?.size)) {
      window.alert(`請選擇：${g.name}`)
      return
    }
  }
  emit('confirm', { options: buildOptions(), qty: qty.value, note: note.value.trim() })
}

function close() {
  emit('close')
}
</script>
