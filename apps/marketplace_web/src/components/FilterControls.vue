<template>
  <div class="filter-controls">
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

    <button type="button" class="reset-link" @click="reset">重設篩選</button>
  </div>
</template>

<script setup lang="ts">
const sort = defineModel<string>('sort', { required: true })
const prices = defineModel<number[]>('prices', { required: true })
const openNow = defineModel<boolean>('openNow', { required: true })

const sortOpts = [
  { v: 'recommended', label: '推薦' },
  { v: 'popular', label: '熱門' },
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
.filter-controls {
  display: flex;
  flex-direction: column;
  gap: 16px;
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
.reset-link {
  align-self: flex-start;
  border: 0;
  background: none;
  color: var(--muted);
  font-size: 13px;
  text-decoration: underline;
  padding: 0;
}
</style>
