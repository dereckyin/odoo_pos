<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.push({ name: 'home' })">‹</button>
      <span class="title">訂單狀態</span>
      <span class="spacer" />
    </header>

    <main class="body">
      <div v-if="loading" class="state-page">查詢中…</div>
      <template v-else-if="order">
        <div class="status-card">
          <div class="big">{{ statusBig(order.status) }}</div>
          <p>{{ statusHint(order.status) }}</p>
        </div>
        <section class="card">
          <h3>{{ order.store_name }}</h3>
          <p>{{ fulfillmentLabel(order.fulfillment_type) }} · {{ paymentLabel(order) }}</p>
          <p v-if="order.delivery_address">地址：{{ order.delivery_address }}</p>
        </section>
        <section class="card">
          <h3>餐點</h3>
          <ul>
            <li v-for="ln in order.lines" :key="ln.id">
              {{ ln.product_name }} × {{ ln.qty }} — ${{ Math.round(ln.line_total_cents) }}
            </li>
          </ul>
          <strong>合計 ${{ Math.round(order.estimated_subtotal_cents) }}</strong>
        </section>
      </template>
      <div v-else class="state-page">找不到訂單</div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchOrderStatus } from '@/api'
import { getOrderAccess } from '@/orderAccess'
import type { MarketplaceOrderRead } from '@/types'

const route = useRoute()
const orderId = String(route.params.orderId)
const accessToken = String(route.query.token || getOrderAccess(orderId) || '')
const order = ref<MarketplaceOrderRead | null>(null)
const loading = ref(true)
let pollHandle: number | null = null

function statusBig(s: string) {
  return ({ submitted: '已送出', accepted: '準備中', ready: '可取餐', merged: '已完成', cancelled: '已取消' } as Record<string, string>)[s] || s
}
function statusHint(s: string) {
  return ({
    submitted: '商家已收到您的訂單',
    accepted: '廚房正在準備',
    ready: '請依取餐方式取餐或等候外送',
    merged: '感謝您的訂購',
    cancelled: '訂單已取消',
  } as Record<string, string>)[s] || ''
}
function fulfillmentLabel(f: string | null) {
  return ({ pickup: '外帶', delivery: '外送', dine_in: '內用' } as Record<string, string>)[f ?? ''] || ''
}
function paymentLabel(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online') return o.payment_status === 'paid' ? '已線上付款' : '待線上付款'
  return '櫃台付款'
}

async function load() {
  if (!accessToken) return
  try {
    const { data } = await fetchOrderStatus(orderId, accessToken)
    order.value = data
  } catch { /* ignore */ }
  finally { loading.value = false }
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
.body { padding: 16px; }
.status-card { background: var(--accent); color: #fff; padding: 20px; border-radius: 12px; margin-bottom: 16px; }
.big { font-size: 1.4rem; font-weight: 700; }
.card { background: var(--surface); padding: 16px; border-radius: 12px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.card h3 { margin: 0 0 8px; }
.card ul { padding-left: 18px; margin: 0 0 8px; }
</style>
