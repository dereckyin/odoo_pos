<template>
  <div class="picker">
    <header>
      <div class="brand">
        <h1>統一點餐</h1>
        <div class="branch">選擇要點餐的店家</div>
      </div>
      <div class="powered">POWERED BY 餐飲聯盟平台</div>
    </header>

    <div v-if="loading" class="loading-box">載入店家中…</div>
    <div v-else-if="error" class="err-box">
      <p>{{ error }}</p>
      <button type="button" class="retry" @click="load">重試</button>
    </div>
    <div v-else-if="!stores.length" class="empty-box">
      <p>目前尚無開放線上點餐的店家</p>
      <p class="hint">店家可於後台「門店管理」啟用線上點餐</p>
    </div>
    <ul v-else class="store-list">
      <li v-for="s in stores" :key="s.id">
        <button type="button" class="store-card" @click="pick(s)">
          <div class="name">{{ s.name }}</div>
          <div v-if="s.address" class="addr">{{ s.address }}</div>
          <div class="tags">
            <span v-if="s.supports_dine_in" class="tag">內用</span>
            <span v-if="s.supports_pickup" class="tag">外帶</span>
            <span v-if="s.supports_delivery" class="tag">外送</span>
            <span v-if="!s.is_open" class="tag closed">休息中</span>
          </div>
        </button>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { fetchShoppingStores, type ShoppingStoreSummary } from '@/api'
import type { FulfillmentMode } from '@/types'

const router = useRouter()
const stores = ref<ShoppingStoreSummary[]>([])
const loading = ref(false)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await fetchShoppingStores()
    stores.value = data
  } catch (err: unknown) {
    error.value = err instanceof Error ? err.message : '載入店家失敗'
    stores.value = []
  } finally {
    loading.value = false
  }
}

function defaultMode(s: ShoppingStoreSummary): FulfillmentMode {
  if (s.supports_pickup) return 'takeout'
  if (s.supports_dine_in) return 'dinein'
  if (s.supports_delivery) return 'delivery'
  return 'takeout'
}

function pick(s: ShoppingStoreSummary) {
  router.push({ path: '/', query: { store: s.id, mode: defaultMode(s) } })
}

onMounted(load)
</script>

<style scoped>
.picker {
  min-height: 100vh;
}
header {
  padding: 20px 20px 16px;
  border-bottom: 1px solid var(--line);
}
.brand h1 {
  font-weight: 900;
  font-size: 24px;
  letter-spacing: 0.06em;
}
.branch {
  font-size: 13px;
  color: var(--muted);
  margin-top: 4px;
}
.powered {
  font-size: 10px;
  color: var(--muted);
  letter-spacing: 0.14em;
  margin-top: 10px;
}
.loading-box,
.err-box,
.empty-box {
  padding: 40px 24px;
  text-align: center;
  color: var(--muted);
  font-size: 14px;
  line-height: 1.7;
}
.err-box {
  color: var(--red);
}
.hint {
  font-size: 12px;
  margin-top: 6px;
}
.retry {
  margin-top: 14px;
  border: 1.5px solid var(--red);
  background: var(--card);
  color: var(--red);
  border-radius: 6px;
  padding: 8px 20px;
  font-weight: 700;
  font-size: 13px;
}
.store-list {
  list-style: none;
  padding: 14px 14px 40px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.store-card {
  width: 100%;
  text-align: left;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 14px 16px;
  transition: border-color 0.15s;
}
.store-card:hover,
.store-card:focus {
  border-color: var(--red);
}
.name {
  font-weight: 800;
  font-size: 16px;
  letter-spacing: 0.04em;
}
.addr {
  font-size: 12px;
  color: var(--muted);
  margin-top: 4px;
  line-height: 1.5;
}
.tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}
.tag {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
  border: 1px solid var(--line);
  color: var(--ink);
  background: #fcfaf6;
}
.tag.closed {
  color: var(--amber);
  border-color: var(--amber);
}
</style>
