<template>
  <div v-if="open && product" class="overlay" @click.self="emit('close')">
    <div class="sheet">
      <header>
        <h2>{{ product.name }}</h2>
        <p class="price">${{ (unitPrice / 100).toFixed(0) }}</p>
        <button class="close" @click="emit('close')">×</button>
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
import type { OptionChoice, OptionGroup, ProductWithOptions, SelectedOption } from '@/types'

const props = defineProps<{ open: boolean; product: ProductWithOptions | null }>()
const emit = defineEmits<{ close: []; confirm: [options: SelectedOption[]] }>()

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

function choiceLabel(c: OptionChoice) {
  return c.price_delta_cents > 0 ? `${c.name} (+$${(c.price_delta_cents / 100).toFixed(0)})` : c.name
}

function selectSingle(groupId: string, choiceId: string) {
  selected[groupId] = new Set([choiceId])
}

function toggleMulti(g: OptionGroup, choiceId: string) {
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
    if (g.is_required && !(selected[g.id]?.size)) {
      throw new Error(`請選擇 ${g.name}`)
    }
  }
  return out
}

function confirm() {
  try {
    emit('confirm', buildOptions())
  } catch (e: unknown) {
    alert(e instanceof Error ? e.message : '請完成選項')
  }
}
</script>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 100;
}
.sheet {
  background: #fff;
  width: min(520px, 100%);
  max-height: 85vh;
  border-radius: 16px 16px 0 0;
  display: flex;
  flex-direction: column;
}
header {
  padding: 16px;
  border-bottom: 1px solid #f0f0f0;
  position: relative;
}
.close {
  position: absolute;
  right: 12px;
  top: 8px;
  border: none;
  background: none;
  font-size: 1.5rem;
}
.groups {
  overflow: auto;
  padding: 16px;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.chips button {
  border: 1px solid #d9d9d9;
  border-radius: 999px;
  padding: 6px 12px;
  background: #fff;
}
.chips button.active {
  border-color: #1677ff;
  background: #e6f4ff;
}
.radios label {
  display: block;
  margin-bottom: 8px;
}
footer {
  padding: 16px;
  border-top: 1px solid #f0f0f0;
}
.confirm {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 8px;
  background: #1677ff;
  color: #fff;
  font-weight: 600;
}
</style>
