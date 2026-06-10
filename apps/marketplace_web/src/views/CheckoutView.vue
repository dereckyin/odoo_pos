<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.back()">‹</button>
      <span class="title">結帳</span>
      <span class="spacer" />
    </header>

    <main class="body" v-if="cart.storeCount">
      <section class="block contact">
        <h3>聯絡資訊</h3>
        <input v-model="customerName" placeholder="姓名" />
        <input v-model="customerPhone" placeholder="手機" inputmode="tel" />
        <div class="member-row">
          <button v-if="!memberStore.isLoggedIn" type="button" class="link" @click="loginOpen = true">
            會員登入：跨店累點 / 折抵 / 優惠券
          </button>
          <span v-else class="member-chip">
            {{ memberStore.member!.name }}（{{ memberStore.points }} 點）
            <button class="link" @click="$router.push({ name: 'member' })">會員中心</button>
          </span>
        </div>
      </section>

      <section v-for="sc in cart.orderedCarts" :key="sc.slug" class="block store-card">
        <h3 class="store-title">{{ sc.meta.display_name }}</h3>

        <div class="field">
          <label>取餐方式</label>
          <div class="opts">
            <label v-if="sc.meta.supports_pickup"><input v-model="forms[sc.slug].fulfillment" type="radio" value="pickup" /> 外帶自取</label>
            <label v-if="sc.meta.supports_delivery"><input v-model="forms[sc.slug].fulfillment" type="radio" value="delivery" /> 外送</label>
            <label v-if="sc.meta.supports_dine_in"><input v-model="forms[sc.slug].fulfillment" type="radio" value="dine_in" /> 內用</label>
          </div>
        </div>

        <div v-if="forms[sc.slug].fulfillment === 'delivery'" class="field">
          <label>外送地址</label>
          <textarea v-model="forms[sc.slug].deliveryAddress" rows="2" placeholder="完整地址" />
          <input v-model="forms[sc.slug].deliveryNote" placeholder="樓層 / 門牌備註（選填）" />
          <button type="button" class="link" @click="useLocation(sc.slug)">
            {{ forms[sc.slug].lat ? '✓ 已定位' : '使用目前位置' }}
          </button>
        </div>

        <div v-if="forms[sc.slug].fulfillment === 'dine_in'" class="field">
          <label>內用資訊</label>
          <input v-model="forms[sc.slug].tableLabel" placeholder="桌號（選填）" />
          <input v-model.number="forms[sc.slug].partySize" type="number" min="1" placeholder="人數（選填）" />
        </div>

        <div class="field">
          <label>付款方式</label>
          <div class="opts">
            <label v-if="sc.meta.payment_counter"><input v-model="forms[sc.slug].payment" type="radio" value="counter" /> 櫃台 / 現場付款</label>
            <label v-if="sc.meta.payment_online"><input v-model="forms[sc.slug].payment" type="radio" value="online" /> 線上付款</label>
          </div>
        </div>

        <div v-if="memberStore.isLoggedIn && forms[sc.slug].payment === 'online'" class="field redeem">
          <label>使用點數折抵（{{ memberStore.points }} 點可用，1 點 = $1）</label>
          <input
            v-model.number="forms[sc.slug].pointsRedeemed"
            type="number"
            min="0"
            :max="maxRedeem(sc)"
            placeholder="0"
          />
          <label>優惠券代碼（選填）</label>
          <input v-model="forms[sc.slug].couponCode" placeholder="輸入優惠券代碼" />
          <p class="hint">點數與優惠券折抵將於結帳完成後套用。</p>
        </div>

        <div class="store-summary">
          <div>小計 ${{ Math.round(cart.storeSubtotalCents(sc.slug)) }}</div>
          <div v-if="forms[sc.slug].fulfillment === 'delivery'">外送費 ${{ Math.round(sc.meta.delivery_fee_cents) }}</div>
          <div v-if="estimatedDiscount(sc) > 0" class="disc">折抵 -${{ estimatedDiscount(sc) }}</div>
          <strong>小計合計 ${{ storeTotal(sc) }}</strong>
        </div>
      </section>

      <section class="block">
        <label>整筆備註</label>
        <textarea v-model="customerNote" rows="2" placeholder="給商家的話（選填）" />
      </section>

      <div class="summary">
        <strong>應付合計 ${{ grandTotal }}</strong>
      </div>

      <button class="submit" :disabled="submitting" @click="submit">
        {{ submitting ? '送出中…' : '確認下單' }}
      </button>
    </main>
    <main v-else class="state-page"><p>購物車是空的</p></main>

    <MemberLoginModal :open="loginOpen" :store-slug="firstSlug" @close="loginOpen = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { initiatePayment, submitBatchOrder, type BatchStoreCart } from '@/api'
import { saveOrderAccess, saveOrderGroup } from '@/orderAccess'
import { useCartStore, type StoreCart } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'
import MemberLoginModal from '@/components/MemberLoginModal.vue'

const router = useRouter()
const cart = useCartStore()
const memberStore = useMemberStore()

if (!cart.storeCount) router.replace({ name: 'home' })

interface StoreForm {
  fulfillment: string
  payment: string
  deliveryAddress: string
  deliveryNote: string
  lat: number | null
  lng: number | null
  tableLabel: string
  partySize: number | null
  pointsRedeemed: number
  couponCode: string
}

const forms = reactive<Record<string, StoreForm>>({})
for (const sc of cart.orderedCarts) {
  forms[sc.slug] = {
    fulfillment: sc.meta.supports_pickup ? 'pickup' : sc.meta.supports_delivery ? 'delivery' : 'dine_in',
    payment: sc.meta.payment_counter ? 'counter' : 'online',
    deliveryAddress: '',
    deliveryNote: '',
    lat: null,
    lng: null,
    tableLabel: '',
    partySize: null,
    pointsRedeemed: 0,
    couponCode: '',
  }
}

const customerName = ref(memberStore.member?.name ?? '')
const customerPhone = ref(memberStore.member?.phone ?? '')
const customerNote = ref('')
const submitting = ref(false)
const loginOpen = ref(false)
const firstSlug = computed(() => cart.storeSlugs[0] ?? '')

function maxRedeem(sc: StoreCart) {
  const subtotal = Math.round(cart.storeSubtotalCents(sc.slug))
  const fee = forms[sc.slug].fulfillment === 'delivery' ? sc.meta.delivery_fee_cents : 0
  // server caps at 50% of order; mirror that as a soft client cap
  return Math.min(memberStore.points, Math.floor((subtotal + fee) * 0.5))
}

function estimatedDiscount(sc: StoreCart) {
  const f = forms[sc.slug]
  if (!memberStore.isLoggedIn || f.payment !== 'online') return 0
  return Math.max(0, Math.min(f.pointsRedeemed || 0, maxRedeem(sc)))
}

function storeTotal(sc: StoreCart) {
  const subtotal = Math.round(cart.storeSubtotalCents(sc.slug))
  const fee = forms[sc.slug].fulfillment === 'delivery' ? sc.meta.delivery_fee_cents : 0
  return Math.max(0, subtotal + fee - estimatedDiscount(sc))
}

const grandTotal = computed(() => cart.orderedCarts.reduce((s, sc) => s + storeTotal(sc), 0))

function useLocation(slug: string) {
  if (!navigator.geolocation) return
  navigator.geolocation.getCurrentPosition((pos) => {
    forms[slug].lat = pos.coords.latitude
    forms[slug].lng = pos.coords.longitude
  })
}

async function submit() {
  if (!customerName.value.trim() || !customerPhone.value.trim()) {
    alert('請填寫姓名與手機')
    return
  }
  for (const sc of cart.orderedCarts) {
    const f = forms[sc.slug]
    if (f.fulfillment === 'delivery' && !f.deliveryAddress.trim()) {
      alert(`請填寫「${sc.meta.display_name}」的外送地址`)
      return
    }
    if (cart.storeSubtotalCents(sc.slug) < (sc.meta.min_order_cents || 0)) {
      alert(`「${sc.meta.display_name}」未達最低消費 $${sc.meta.min_order_cents}`)
      return
    }
  }

  submitting.value = true
  try {
    const carts: BatchStoreCart[] = cart.orderedCarts.map((sc) => {
      const f = forms[sc.slug]
      return {
        store_slug: sc.slug,
        fulfillment_type: f.fulfillment,
        payment_method: f.payment,
        delivery_address: f.fulfillment === 'delivery' ? f.deliveryAddress : null,
        delivery_lat: f.fulfillment === 'delivery' ? f.lat : null,
        delivery_lng: f.fulfillment === 'delivery' ? f.lng : null,
        delivery_note: f.deliveryNote || null,
        table_label: f.fulfillment === 'dine_in' ? f.tableLabel || null : null,
        party_size: f.partySize,
        store_note: customerNote.value || null,
        points_redeemed: f.pointsRedeemed || 0,
        coupon_code: f.couponCode.trim() || null,
        lines: sc.lines.map((l) => ({
          product_id: l.product.id,
          qty: l.qty,
          note: l.note || null,
          options: l.selectedOptions,
        })),
      }
    })

    const { data } = await submitBatchOrder({
      customer_name: customerName.value.trim(),
      customer_phone: customerPhone.value.trim(),
      carts,
    })

    for (const o of data.orders) saveOrderAccess(o.order_id, o.access_token)
    saveOrderGroup(
      data.order_group_id,
      data.orders.map((o) => ({ order_id: o.order_id, access_token: o.access_token })),
    )
    cart.clearAll()

    const onlineOrders = data.orders.filter((o) => o.payment_method === 'online')
    // Single online order: redirect straight to the payment gateway.
    if (data.orders.length === 1 && onlineOrders.length === 1) {
      const o = onlineOrders[0]
      const returnUrl = `${window.location.origin}/orders/${o.order_id}?paid=1`
      const pay = await initiatePayment(o.order_id, o.access_token, returnUrl)
      if (pay.data.payment_form_html) {
        document.open()
        document.write(pay.data.payment_form_html)
        document.close()
        return
      }
      if (pay.data.message) alert(pay.data.message)
      router.replace({ name: 'order-status', params: { orderId: o.order_id }, query: { token: o.access_token } })
      return
    }

    // Multi-store (or mixed): go to group tracking; online orders pay there.
    router.replace({ name: 'order-group', params: { groupId: data.order_group_id } })
  } catch (e: unknown) {
    const err = e as { response?: { data?: { detail?: string } } }
    alert(err.response?.data?.detail || '下單失敗')
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.body { padding: 16px; padding-bottom: 100px; }
.block { margin-bottom: 16px; }
.block > h3 { margin: 0 0 8px; font-size: 15px; }
.contact input { width: 100%; margin-bottom: 8px; padding: 10px; border: 1px solid var(--border); border-radius: 8px; }
.store-card { background: var(--surface); border-radius: 12px; padding: 14px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.store-title { margin: 0 0 10px; font-size: 16px; }
.field { margin-bottom: 12px; }
.field > label { display: block; font-size: 13px; color: var(--muted); margin-bottom: 4px; }
.field input, .field textarea { width: 100%; margin-bottom: 6px; padding: 10px; border: 1px solid var(--border); border-radius: 8px; }
.opts label { display: block; padding: 6px 0; font-size: 14px; }
.opts input { width: auto; margin: 0 6px 0 0; }
.redeem { background: var(--accent-soft); border-radius: 8px; padding: 10px; }
.hint { font-size: 12px; color: var(--muted); margin: 4px 0 0; }
.store-summary { border-top: 1px solid var(--border); padding-top: 8px; text-align: right; font-size: 14px; }
.store-summary .disc { color: #2a8; }
.store-summary strong { display: block; margin-top: 4px; }
.summary { background: var(--surface); padding: 14px; border-radius: 10px; margin: 16px 0; text-align: right; font-size: 18px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.submit { width: 100%; border: 0; background: var(--accent); color: #fff; padding: 14px; border-radius: 10px; font-size: 16px; font-weight: 600; }
.link { background: none; border: none; color: var(--accent); padding: 0; }
.member-row { margin-top: 8px; }
.member-chip { display: flex; gap: 10px; align-items: center; font-size: 14px; }
</style>
