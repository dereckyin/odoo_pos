<template>
  <div class="status-page">
    <header class="topbar">
      <button class="back" @click="newOrder">繼續加點</button>
      <span class="title">點餐狀態</span>
      <span class="spacer" />
    </header>

    <main class="content">
      <div v-if="loading" class="state">查詢中…</div>
      <div v-else-if="!order" class="state">找不到訂單</div>
      <template v-else>
        <div class="status-card" :class="statusClass(order.status)">
          <div class="big">{{ statusBig(order.status) }}</div>
          <div class="sub">{{ statusHint(order.status) }}</div>
        </div>

        <section class="card">
          <h3>桌號</h3>
          <p class="big-text">{{ order.table_label }}</p>
        </section>

        <section class="card">
          <h3>已點餐點</h3>
          <ul class="lines">
            <li v-for="ln in order.lines" :key="ln.id">
              <span>{{ ln.product_name }} × {{ ln.qty }}</span>
              <span class="amt">${{ Math.round(ln.line_total_cents) }}</span>
            </li>
          </ul>
          <div class="total-row">
            <span>估計合計</span>
            <strong>${{ Math.round(order.estimated_subtotal_cents) }}</strong>
          </div>
          <p class="hint">※ 實際金額以櫃台結帳為準</p>
        </section>
      </template>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchOrderStatus } from '@/api'
import { tableTokenFromRoute } from '@/tableToken'
import type { GuestOrderRead } from '@/types'

const route = useRoute()
const router = useRouter()

const order = ref<GuestOrderRead | null>(null)
const loading = ref(true)
let pollHandle: number | null = null

const orderId = String(route.params.orderId || '')

async function load() {
  const t = tableTokenFromRoute(route)
  if (!t || !orderId) return
  try {
    const { data } = await fetchOrderStatus(t, orderId)
    order.value = data
  } catch {
    // ignore polling errors silently
  } finally {
    loading.value = false
  }
}

function newOrder() {
  const t = tableTokenFromRoute(route)
  router.push({ path: '/order', query: t ? { t } : {} })
}

function statusClass(s: GuestOrderRead['status']) {
  return s
}
function statusBig(s: GuestOrderRead['status']) {
  return ({
    submitted: '已送出',
    accepted: '餐點準備中',
    ready: '餐點已備好',
    merged: '已結帳',
    cancelled: '已取消',
  } as Record<string, string>)[s]
}
function statusHint(s: GuestOrderRead['status']) {
  return ({
    submitted: '請耐心等候，店員稍後會接單。',
    accepted: '廚房正在準備您的餐點，請稍候。',
    ready: '請至櫃台結帳，謝謝。',
    merged: '感謝您的光臨。',
    cancelled: '此訂單已取消。',
  } as Record<string, string>)[s]
}

onMounted(() => {
  load()
  pollHandle = window.setInterval(load, 4000)
})
onBeforeUnmount(() => {
  if (pollHandle != null) window.clearInterval(pollHandle)
})
</script>

<style scoped>
.status-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.topbar {
  background: #fff;
  padding: 12px 16px;
  display: grid;
  grid-template-columns: 100px 1fr 100px;
  align-items: center;
  border-bottom: 1px solid #eee;
}
.topbar .back {
  background: #ffeee6;
  color: #ff6b35;
  border: 0;
  border-radius: 16px;
  padding: 6px 10px;
  font-size: 13px;
}
.topbar .title {
  text-align: center;
  font-weight: 600;
}
.content {
  padding: 16px;
}
.state {
  text-align: center;
  color: #888;
  padding: 48px 0;
}
.status-card {
  border-radius: 12px;
  padding: 24px;
  text-align: center;
  margin-bottom: 16px;
  background: #fff;
}
.status-card.submitted {
  background: #fff5e6;
  color: #b8730d;
}
.status-card.accepted {
  background: #e6f0ff;
  color: #1a4ed8;
}
.status-card.ready {
  background: #e6ffed;
  color: #15803d;
}
.status-card.merged,
.status-card.cancelled {
  background: #f0f0f0;
  color: #555;
}
.status-card .big {
  font-size: 22px;
  font-weight: 700;
}
.status-card .sub {
  font-size: 14px;
  margin-top: 6px;
}
.card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 12px;
}
.card h3 {
  margin: 0 0 8px;
  font-size: 14px;
  color: #888;
}
.big-text {
  font-size: 32px;
  font-weight: 700;
  margin: 0;
  color: #ff6b35;
}
.lines {
  list-style: none;
  padding: 0;
  margin: 0;
}
.lines li {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f1f1f1;
}
.total-row {
  display: flex;
  justify-content: space-between;
  margin-top: 8px;
  font-size: 16px;
}
.total-row strong {
  font-size: 20px;
  color: #ff6b35;
}
.hint {
  margin-top: 6px;
  color: #999;
  font-size: 12px;
}
</style>
