<template>
  <div v-if="open" class="overlay" @click.self="emit('close')">
    <div class="sheet">
      <div class="grab" />
      <h3>排序與篩選</h3>

      <div class="group">
        <label>排序</label>
        <div class="opts">
          <button
            v-for="o in sortOpts"
            :key="o.v"
            type="button"
            :class="{ active: sort === o.v }"
            @click="sort = o.v"
          >
            {{ o.label }}
          </button>
        </div>
      </div>

      <div class="group">
        <label>價位</label>
        <div class="opts">
          <button
            v-for="p in [1, 2, 3]"
            :key="p"
            type="button"
            :class="{ active: prices.includes(p) }"
            @click="togglePrice(p)"
          >
            {{ '$'.repeat(p) }}
          </button>
        </div>
      </div>

      <div class="group row">
        <label>僅顯示營業中</label>
        <button type="button" class="toggle" :class="{ on: openNow }" @click="openNow = !openNow">
          <span class="knob" />
        </button>
      </div>

      <div class="actions">
        <button type="button" class="reset" @click="reset">重設</button>
        <button type="button" class="apply" @click="emit('close')">查看結果</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{ open: boolean }>()
const emit = defineEmits<{ close: [] }>()

const sort = defineModel<string>('sort', { required: true })
const prices = defineModel<number[]>('prices', { required: true })
const openNow = defineModel<boolean>('openNow', { required: true })

const sortOpts = [
  { v: 'recommended', label: '推薦' },
  { v: 'rating', label: '評分最高' },
  { v: 'distance', label: '距離最近' },
  { v: 'prep', label: '出餐最快' },
]

function togglePrice(p: number) {
  const cur = prices.value
  prices.value = cur.includes(p) ? cur.filter((x) => x !== p) : [...cur, p]
}

function reset() {
  sort.value = 'recommended'
  prices.value = []
  openNow.value = false
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
  z-index: 120;
}
.sheet {
  background: var(--surface);
  width: 100%;
  border-radius: 18px 18px 0 0;
  padding: 12px 18px calc(18px + env(safe-area-inset-bottom));
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 80vh;
  overflow-y: auto;
}
.grab {
  width: 40px;
  height: 4px;
  border-radius: 2px;
  background: var(--border);
  margin: 0 auto 4px;
}
h3 {
  margin: 0;
  font-size: 16px;
}
.group label {
  display: block;
  font-size: 13px;
  color: var(--muted);
  margin-bottom: 8px;
}
.group.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.group.row label {
  margin: 0;
  color: var(--text);
  font-size: 14px;
}
.opts {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.opts button {
  border: 1px solid var(--border);
  background: var(--surface);
  border-radius: 18px;
  padding: 8px 16px;
  font-size: 14px;
  color: var(--text);
}
.opts button.active {
  border-color: var(--accent);
  background: var(--accent-soft);
  color: var(--accent);
  font-weight: 600;
}
.toggle {
  width: 44px;
  height: 26px;
  border-radius: 13px;
  border: 0;
  background: var(--border);
  position: relative;
  transition: background 0.15s;
}
.toggle.on {
  background: var(--accent);
}
.toggle .knob {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #fff;
  transition: transform 0.15s;
}
.toggle.on .knob {
  transform: translateX(18px);
}
.actions {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}
.actions button {
  flex: 1;
  border-radius: 12px;
  padding: 12px;
  font-size: 15px;
  font-weight: 600;
}
.reset {
  border: 1px solid var(--border);
  background: var(--surface);
  color: var(--text);
}
.apply {
  border: 0;
  background: var(--accent);
  color: #fff;
}
@media (min-width: 900px) {
  .overlay {
    align-items: center;
  }
  .sheet {
    width: min(440px, 92vw);
    border-radius: 16px;
  }
  .grab {
    display: none;
  }
}
</style>
