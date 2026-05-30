<template>
  <div v-if="open && product" class="overlay" @click.self="close">
    <div class="sheet">
      <header>
        <h2>{{ product.name }}</h2>
        <p class="price">${{ Math.round(unitPrice) }}</p>
        <button class="close" @click="close">×</button>
      </header>

      <div class="groups">
        <section v-for="g in product.option_groups" :key="g.id">
          <h3>{{ g.name }}<span v-if="g.is_required"> *</span></h3>
          <div v-if="g.selection_type === 'multi'" class="chips">
            <button
              v-for="c in g.choices"
              :key="c.id"
              :class="{ active: selected[g.id]?.has(c.id) }"
              @click="toggleMulti(g, c.id)"
            >
              {{ choiceLabel(c) }}
            </button>
          </div>
          <div v-else class="radios">
            <label v-for="c in g.choices" :key="c.id">
              <input
                type="radio"
                :name="g.id"
                :value="c.id"
                :checked="selected[g.id]?.has(c.id)"
                @change="selectSingle(g.id, c.id)"
              />
              {{ choiceLabel(c) }}
            </label>
          </div>
        </section>
      </div>

      <footer>
        <button class="confirm" @click="confirm">加入購物車</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import type { PublicOptionChoice, PublicOptionGroup, PublicProduct, SelectedOption } from '@/types'

const props = defineProps<{
  open: boolean
  product: PublicProduct | null
}>()

const emit = defineEmits<{
  close: []
  confirm: [options: SelectedOption[]]
}>()

const selected = reactive<Record<string, Set<string>>>({})

watch(
  () => props.product,
  (p) => {
    for (const k of Object.keys(selected)) delete selected[k]
    if (!p) return
    for (const g of p.option_groups) {
      selected[g.id] = new Set()
      if (g.selection_type === 'single') {
        const def = g.choices.find((c) => c.is_default) ?? g.choices[0]
        if (def) selected[g.id].add(def.id)
      }
    }
  },
  { immediate: true },
)

const unitPrice = computed(() => {
  if (!props.product) return 0
  let extra = 0
  for (const g of props.product.option_groups) {
    for (const id of selected[g.id] ?? []) {
      const c = g.choices.find((x) => x.id === id)
      if (c) extra += c.price_delta_cents
    }
  }
  return props.product.price_cents + extra
})

function choiceLabel(c: PublicOptionChoice) {
  return c.price_delta_cents > 0 ? `${c.name} (+$${Math.round(c.price_delta_cents)})` : c.name
}

function selectSingle(groupId: string, choiceId: string) {
  selected[groupId] = new Set([choiceId])
}

function toggleMulti(g: PublicOptionGroup, choiceId: string) {
  const set = selected[g.id] ?? new Set()
  if (set.has(choiceId)) set.delete(choiceId)
  else {
    if (g.max_selections != null && set.size >= g.max_selections) return
    set.add(choiceId)
  }
  selected[g.id] = new Set(set)
}

function buildOptions(): SelectedOption[] {
  if (!props.product) return []
  const out: SelectedOption[] = []
  for (const g of props.product.option_groups) {
    for (const id of selected[g.id] ?? []) {
      const c = g.choices.find((x) => x.id === id)!
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

function validate() {
  if (!props.product) return '無商品'
  for (const g of props.product.option_groups) {
    const count = selected[g.id]?.size ?? 0
    if (g.selection_type === 'single' && g.is_required && count !== 1) return `請選擇${g.name}`
    if (g.selection_type === 'multi') {
      const min = g.min_selections || (g.is_required ? 1 : 0)
      if (count < min) return `請選擇${g.name}`
    }
  }
  return null
}

function confirm() {
  const err = validate()
  if (err) {
    alert(err)
    return
  }
  emit('confirm', buildOptions())
}

function close() {
  emit('close')
}
</script>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  z-index: 100;
  display: flex;
  align-items: flex-end;
}
.sheet {
  background: #fff;
  width: 100%;
  max-height: 85vh;
  border-radius: 16px 16px 0 0;
  display: flex;
  flex-direction: column;
}
header {
  padding: 16px;
  border-bottom: 1px solid #eee;
  position: relative;
}
header h2 {
  margin: 0;
  font-size: 18px;
}
.price {
  color: #ff6b35;
  font-weight: 600;
  margin: 4px 0 0;
}
.close {
  position: absolute;
  right: 12px;
  top: 12px;
  border: 0;
  background: transparent;
  font-size: 28px;
  color: #888;
}
.groups {
  overflow-y: auto;
  padding: 12px 16px;
  flex: 1;
}
section {
  margin-bottom: 16px;
}
section h3 {
  font-size: 14px;
  margin: 0 0 8px;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.chips button {
  border: 1px solid #ddd;
  background: #fff;
  border-radius: 20px;
  padding: 8px 14px;
}
.chips button.active {
  border-color: #ff6b35;
  background: #ffeee6;
  color: #ff6b35;
}
.radios label {
  display: block;
  padding: 8px 0;
}
footer {
  padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  border-top: 1px solid #eee;
}
.confirm {
  width: 100%;
  background: #ff6b35;
  color: #fff;
  border: 0;
  border-radius: 10px;
  padding: 14px;
  font-size: 16px;
  font-weight: 600;
}
</style>
