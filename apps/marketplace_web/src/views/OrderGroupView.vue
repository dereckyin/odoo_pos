<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.push({ name: 'home' })">‹</button>
      <span class="title">訂單追蹤</span>
      <span class="spacer" />
    </header>

    <main class="body">
      <div v-if="loading" class="state-page">查詢中…</div>
      <template v-else-if="orders.length">
        <p class="summary">共 {{ orders.length }} 家商店 · 合計 ${{ grandTotal }}</p>
        <article v-for="o in orders" :key="o.id" class="order-card" @click="goOrder(o)">
          <div class="head">
            <strong>{{ o.store_name }}</strong>
            <span class="status" :class="o.status">{{ statusBig(o) }}</span>
          </div>
          <div class="meta">
            {{ fulfillmentLabel(o.fulfillment_type) }} ·
            {{ o.eta_minutes != null && o.status !== 'merged' ? `約 ${o.eta_minutes} 分` : paymentLabel(o) }}
          </div>
          <div class="lines">{{ o.lines.map((l) => `${l.product_name}×${l.qty}`).join('、') }}</div>
          <div class="foot">
            <span>${{ Math.round(o.estimated_subtotal_cents) }}</span>
            <button
              v-if="o.payment_method === 'online' && o.payment_status !== 'paid'"
              class="pay"
              @click.stop="pay(o)"
            >
              前往付款
            </button>
          </div>
        </article>
      </template>
      <div v-else class="state-page">找不到訂單</div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchOrderStatus, initiatePayment } from '@/api'
import { getOrderGroup } from '@/orderAccess'
import type { MarketplaceOrderRead } from '@/types'

const route = useRoute()
const router = useRouter()
const groupId = String(route.params.groupId)
const refs = getOrderGroup(groupId)
const tokens = new Map(refs.map((r) => [r.order_id, r.access_token]))
const orders = ref<MarketplaceOrderRead[]>([])
const loading = ref(true)
let pollHandle: number | null = null

const grandTotal = computed(() => orders.value.reduce((s, o) => s + Math.round(o.estimated_subtotal_cents), 0))

function statusBig(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online' && o.payment_status !== 'paid' && o.status !== 'cancelled') return '待付款'
  return ({ submitted: '已送出', accepted: '準備中', ready: '可取餐', merged: '已完成', cancelled: '已取消' } as Record<string, string>)[o.status] || o.status
}
function fulfillmentLabel(f: string | null) {
  return ({ pickup: '外帶', delivery: '外送', dine_in: '內用' } as Record<string, string>)[f ?? ''] || ''
}
function paymentLabel(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online') return o.payment_status === 'paid' ? '已付款' : '待付款'
  return '櫃台付款'
}

async function load() {
  const results: MarketplaceOrderRead[] = []
  for (const r of refs) {
    try {
      const { data } = await fetchOrderStatus(r.order_id, r.access_token)
      results.push(data)
    } catch {
      /* skip */
    }
  }
  orders.value = results
  loading.value = false
}

function goOrder(o: MarketplaceOrderRead) {
  router.push({ name: 'order-status', params: { orderId: o.id }, query: { token: tokens.get(o.id) } })
}

async function pay(o: MarketplaceOrderRead) {
  const token = tokens.get(o.id)
  if (!token) return
  const returnUrl = `${window.location.origin}/order-groups/${groupId}`
  const { data } = await initiatePayment(o.id, token, returnUrl)
  if (data.payment_form_html) {
    document.open()
    document.write(data.payment_form_html)
    document.close()
    return
  }
  if (data.message) alert(data.message)
}

onMounted(() => {
  load()
  pollHandle = window.setInterval(load, 6000)
})
onBeforeUnmount(() => {
  if (pollHandle != null) window.clearInterval(pollHandle)
})
</script>

<style scoped>
.body { padding: 16px; }
.summary { color: var(--muted); margin: 0 0 12px; }
.order-card { background: var(--surface); border-radius: 12px; padding: 14px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(15,23,42,.06); cursor: pointer; }
.head { display: flex; justify-content: space-between; align-items: center; }
.status { font-size: 13px; color: var(--accent); font-weight: 600; }
.status.cancelled { color: #b33; }
.status.merged { color: #2a8; }
.meta { font-size: 12px; color: var(--muted); margin-top: 4px; }
.lines { font-size: 13px; margin-top: 8px; color: #555; }
.foot { display: flex; justify-content: space-between; align-items: center; margin-top: 10px; font-weight: 600; }
.pay { border: 0; background: var(--accent); color: #fff; padding: 8px 14px; border-radius: 8px; font-weight: 600; }
</style>
