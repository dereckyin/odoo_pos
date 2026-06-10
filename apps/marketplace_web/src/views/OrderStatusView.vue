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
          <div class="big">{{ statusBig(order) }}</div>
          <p>{{ statusHint(order) }}</p>
          <div v-if="order.eta_minutes != null && order.status !== 'merged' && order.status !== 'cancelled'" class="eta">
            預估約 {{ order.eta_minutes }} 分鐘
          </div>
        </div>

        <div v-if="order.fulfillment_type === 'delivery'" class="track">
          <div v-for="step in deliverySteps" :key="step.key" class="step" :class="{ done: stepDone(step.key), active: order.delivery_status === step.key }">
            <span class="dot" />
            <span class="label">{{ step.label }}</span>
          </div>
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
          <div v-if="order.discount_cents > 0" class="disc">折抵 -${{ Math.round(order.discount_cents) }}</div>
          <strong>合計 ${{ Math.round(order.estimated_subtotal_cents) }}</strong>
        </section>

        <button
          v-if="order.payment_method === 'online' && order.payment_status !== 'paid'"
          class="pay-btn"
          @click="pay"
        >
          前往付款
        </button>

        <section v-if="order.can_review" class="card review">
          <h3>為這次訂單評分</h3>
          <div class="stars">
            <button v-for="n in 5" :key="n" :class="{ on: n <= rating }" @click="rating = n">★</button>
          </div>
          <textarea v-model="comment" rows="2" placeholder="留下您的評論（選填）" />
          <button class="submit" :disabled="reviewing" @click="sendReview">
            {{ reviewing ? '送出中…' : '送出評價' }}
          </button>
        </section>
        <section v-else-if="order.has_review" class="card"><p class="thanks">感謝您的評價！</p></section>
      </template>
      <div v-else class="state-page">找不到訂單</div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchOrderStatus, initiatePayment, submitReview } from '@/api'
import { getOrderAccess } from '@/orderAccess'
import type { MarketplaceOrderRead } from '@/types'

const route = useRoute()
const orderId = String(route.params.orderId)
const accessToken = String(route.query.token || getOrderAccess(orderId) || '')
const order = ref<MarketplaceOrderRead | null>(null)
const loading = ref(true)
const rating = ref(5)
const comment = ref('')
const reviewing = ref(false)
let pollHandle: number | null = null

const deliverySteps = [
  { key: 'pending', label: '已接單' },
  { key: 'preparing', label: '製作中' },
  { key: 'out_for_delivery', label: '外送中' },
  { key: 'delivered', label: '已送達' },
]
const deliveryOrder = ['pending', 'preparing', 'out_for_delivery', 'delivered']
function stepDone(key: string) {
  const cur = order.value?.delivery_status || 'pending'
  return deliveryOrder.indexOf(key) <= deliveryOrder.indexOf(cur)
}

function statusBig(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online' && o.payment_status !== 'paid' && o.status !== 'cancelled') return '待付款'
  return ({ submitted: '已送出', accepted: '準備中', ready: '可取餐', merged: '已完成', cancelled: '已取消' } as Record<string, string>)[o.status] || o.status
}
function statusHint(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online' && o.payment_status !== 'paid' && o.status !== 'cancelled') return '請完成線上付款'
  return ({
    submitted: '商家已收到您的訂單',
    accepted: '廚房正在準備',
    ready: o.fulfillment_type === 'delivery' ? '外送員準備出發' : '請依取餐方式取餐',
    merged: '感謝您的訂購',
    cancelled: '訂單已取消',
  } as Record<string, string>)[o.status] || ''
}
function fulfillmentLabel(f: string | null) {
  return ({ pickup: '外帶', delivery: '外送', dine_in: '內用' } as Record<string, string>)[f ?? ''] || ''
}
function paymentLabel(o: MarketplaceOrderRead) {
  if (o.payment_method === 'online') return o.payment_status === 'paid' ? '已線上付款' : '待線上付款'
  return '櫃台付款'
}

async function load() {
  if (!accessToken) {
    loading.value = false
    return
  }
  try {
    const { data } = await fetchOrderStatus(orderId, accessToken)
    order.value = data
  } catch {
    /* ignore */
  } finally {
    loading.value = false
  }
}

async function pay() {
  if (!order.value) return
  const returnUrl = `${window.location.origin}/orders/${orderId}?paid=1`
  const { data } = await initiatePayment(orderId, accessToken, returnUrl)
  if (data.payment_form_html) {
    document.open()
    document.write(data.payment_form_html)
    document.close()
    return
  }
  if (data.message) alert(data.message)
}

async function sendReview() {
  reviewing.value = true
  try {
    await submitReview({ order_id: orderId, access_token: accessToken, rating: rating.value, comment: comment.value || null })
    await load()
  } catch (e: unknown) {
    const err = e as { response?: { data?: { detail?: string } } }
    alert(err.response?.data?.detail || '評價失敗')
  } finally {
    reviewing.value = false
  }
}

onMounted(() => {
  load()
  pollHandle = window.setInterval(load, 5000)
})
onBeforeUnmount(() => {
  if (pollHandle != null) window.clearInterval(pollHandle)
})
</script>

<style scoped>
.body { padding: 16px; }
.status-card { background: var(--accent); color: #fff; padding: 20px; border-radius: 12px; margin-bottom: 16px; }
.big { font-size: 1.4rem; font-weight: 700; }
.eta { margin-top: 8px; font-size: 14px; opacity: .95; }
.track { display: flex; justify-content: space-between; background: var(--surface); border-radius: 12px; padding: 16px 12px; margin-bottom: 12px; }
.step { display: flex; flex-direction: column; align-items: center; gap: 6px; flex: 1; color: var(--muted); font-size: 12px; position: relative; }
.step .dot { width: 14px; height: 14px; border-radius: 50%; background: var(--border); }
.step.done .dot { background: var(--accent); }
.step.active .label { color: var(--accent); font-weight: 700; }
.card { background: var(--surface); padding: 16px; border-radius: 12px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.card h3 { margin: 0 0 8px; }
.card ul { padding-left: 18px; margin: 0 0 8px; }
.disc { color: #2a8; }
.pay-btn { width: 100%; border: 0; background: var(--accent); color: #fff; padding: 14px; border-radius: 10px; font-weight: 600; margin-bottom: 12px; }
.review .stars { display: flex; gap: 4px; margin-bottom: 8px; }
.review .stars button { border: 0; background: none; font-size: 28px; color: var(--border); }
.review .stars button.on { color: #e6a700; }
.review textarea { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 8px; margin-bottom: 8px; }
.review .submit { width: 100%; border: 0; background: var(--accent); color: #fff; padding: 12px; border-radius: 8px; font-weight: 600; }
.thanks { color: var(--accent); text-align: center; margin: 0; }
</style>
