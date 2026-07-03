<template>
  <div class="kds">
    <header>
      <h1>廚房顯示 / 桌邊訂單</h1>
      <button :disabled="loading" @click="refresh">{{ loading ? '更新中…' : '重新整理' }}</button>
    </header>
    <div v-if="!orders.length" class="empty">目前沒有待處理訂單</div>
    <div class="grid">
      <article v-for="o in orders" :key="o.id" class="card" :class="o.status" data-testid="kds-order-card">
        <header>
          <strong>{{ o.table_label || '外帶' }}</strong>
          <span class="status">{{ statusLabel(o.status) }}</span>
        </header>
        <ul>
          <li v-for="l in o.lines" :key="l.id">
            {{ l.product_name }} × {{ l.qty }}
            <span v-if="l.options_json?.length" class="opts">
              {{ l.options_json.map((x) => x.choice_name).join(' · ') }}
            </span>
          </li>
        </ul>
        <p v-if="o.customer_note" class="note">備註：{{ o.customer_note }}</p>
        <footer>
          <button v-if="o.status === 'submitted'" data-testid="kds-accept-btn" @click="accept(o.id)">接單並列印</button>
          <button v-if="o.status === 'accepted'" @click="ready(o.id)">出餐完成</button>
          <button v-if="o.status === 'ready'" @click="complete(o.id)">已送達</button>
        </footer>
      </article>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import * as guestApi from '@/api/guestOrders'
import { useCatalogStore } from '@/stores/catalog'
import { enqueueGuestOrderPrints } from '@/lib/printPayloads'
import type { GuestOrder } from '@/types'

const catalog = useCatalogStore()
const orders = ref<GuestOrder[]>([])
const loading = ref(false)
let timer: ReturnType<typeof setInterval> | null = null

function statusLabel(s: string) {
  return ({ submitted: '新訂單', accepted: '製作中', ready: '待送達' } as Record<string, string>)[s] ?? s
}

async function refresh() {
  loading.value = true
  try {
    const { data } = await guestApi.listGuestOrders()
    orders.value = data
  } finally {
    loading.value = false
  }
}

async function accept(id: string) {
  const { data } = await guestApi.acceptGuestOrder(id)
  await enqueueGuestOrderPrints(data, catalog.products)
  await refresh()
}

async function ready(id: string) {
  await guestApi.markGuestOrderReady(id)
  await refresh()
}

async function complete(id: string) {
  await guestApi.completeGuestOrder(id)
  await refresh()
}

onMounted(async () => {
  if (!catalog.products.length) await catalog.load()
  await refresh()
  timer = setInterval(refresh, 15000)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.kds {
  padding: 16px;
}
header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}
.card {
  background: #fff;
  border-radius: 10px;
  padding: 12px;
  border-left: 4px solid #faad14;
}
.card.accepted {
  border-left-color: #1677ff;
}
.card.ready {
  border-left-color: #52c41a;
}
.card header {
  margin-bottom: 8px;
}
.status {
  float: right;
  font-size: 0.8rem;
  color: #666;
}
.opts {
  display: block;
  font-size: 0.8rem;
  color: #888;
}
.note {
  font-size: 0.85rem;
  color: #666;
}
footer button {
  width: 100%;
  margin-top: 8px;
  padding: 8px;
  border: none;
  border-radius: 6px;
  background: #1677ff;
  color: #fff;
}
.empty {
  text-align: center;
  color: #999;
  padding: 48px;
}
</style>
