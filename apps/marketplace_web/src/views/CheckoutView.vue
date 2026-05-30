<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.back()">‹</button>
      <span class="title">結帳</span>
      <span class="spacer" />
    </header>

    <main class="body" v-if="cart.storeMeta">
      <section class="block">
        <h3>取餐方式</h3>
        <div class="opts">
          <label v-if="cart.storeMeta.supports_pickup"><input v-model="fulfillment" type="radio" value="pickup" /> 外帶自取</label>
          <label v-if="cart.storeMeta.supports_delivery"><input v-model="fulfillment" type="radio" value="delivery" /> 外送</label>
          <label v-if="cart.storeMeta.supports_dine_in"><input v-model="fulfillment" type="radio" value="dine_in" /> 內用</label>
        </div>
      </section>

      <section class="block">
        <h3>聯絡資訊</h3>
        <input v-model="customerName" placeholder="姓名" />
        <input v-model="customerPhone" placeholder="手機" inputmode="tel" />
      </section>

      <section v-if="fulfillment === 'delivery'" class="block">
        <h3>外送地址</h3>
        <textarea v-model="deliveryAddress" rows="2" placeholder="完整地址" />
        <input v-model="deliveryNote" placeholder="樓層、門牌備註（選填）" />
      </section>

      <section v-if="fulfillment === 'dine_in'" class="block">
        <h3>內用資訊</h3>
        <input v-model="tableLabel" placeholder="桌號（選填）" />
        <input v-model.number="partySize" type="number" min="1" placeholder="人數（選填）" />
      </section>

      <section class="block">
        <h3>付款方式</h3>
        <div class="opts">
          <label v-if="cart.storeMeta.payment_counter"><input v-model="paymentMethod" type="radio" value="counter" /> 櫃台付款</label>
          <label v-if="cart.storeMeta.payment_online"><input v-model="paymentMethod" type="radio" value="online" /> 線上付款</label>
        </div>
      </section>

      <section class="block">
        <label>備註</label>
        <textarea v-model="customerNote" rows="2" />
      </section>

      <div class="member-row">
        <button v-if="!memberStore.isLoggedIn" type="button" class="link" @click="loginOpen = true">會員登入累點</button>
        <span v-else>{{ memberStore.member!.name }}（{{ memberStore.member!.points }} 點）</span>
      </div>

      <div class="summary">
        <div>小計 ${{ Math.round(cart.subtotalCents) }}</div>
        <div v-if="fulfillment === 'delivery'">外送費 ${{ Math.round(cart.storeMeta.delivery_fee_cents) }}</div>
        <strong>合計 ${{ Math.round(total) }}</strong>
      </div>

      <button class="submit" :disabled="submitting" @click="submit">
        {{ submitting ? '送出中…' : '確認下單' }}
      </button>
    </main>

    <MemberLoginModal :open="loginOpen" :store-slug="cart.storeSlug || ''" @close="loginOpen = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { initiatePayment, submitOrder } from '@/api'
import { saveOrderAccess } from '@/orderAccess'
import { useCartStore } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'
import MemberLoginModal from '@/components/MemberLoginModal.vue'

const router = useRouter()
const cart = useCartStore()
const memberStore = useMemberStore()

if (!cart.storeSlug || !cart.lines.length) router.replace({ name: 'home' })

const meta = cart.storeMeta!
const fulfillment = ref(meta.supports_pickup ? 'pickup' : meta.supports_delivery ? 'delivery' : 'dine_in')
const paymentMethod = ref(meta.payment_counter ? 'counter' : 'online')
const customerName = ref('')
const customerPhone = ref('')
const deliveryAddress = ref('')
const deliveryNote = ref('')
const tableLabel = ref('')
const partySize = ref<number | null>(null)
const customerNote = ref('')
const submitting = ref(false)
const loginOpen = ref(false)

const total = computed(() => {
  let t = cart.subtotalCents
  if (fulfillment.value === 'delivery') t += meta.delivery_fee_cents
  return t
})

async function submit() {
  if (!customerName.value.trim() || !customerPhone.value.trim()) {
    alert('請填寫姓名與手機')
    return
  }
  if (fulfillment.value === 'delivery' && !deliveryAddress.value.trim()) {
    alert('請填寫外送地址')
    return
  }
  submitting.value = true
  try {
    const { data } = await submitOrder(cart.storeSlug!, {
      fulfillment_type: fulfillment.value,
      payment_method: paymentMethod.value,
      customer_name: customerName.value.trim(),
      customer_phone: customerPhone.value.trim(),
      customer_note: customerNote.value || null,
      party_size: partySize.value,
      member_id: memberStore.member?.id ?? null,
      delivery_address: fulfillment.value === 'delivery' ? deliveryAddress.value : null,
      delivery_note: deliveryNote.value || null,
      table_label: fulfillment.value === 'dine_in' ? tableLabel.value || null : null,
      lines: cart.lines.map((l) => ({
        product_id: l.product.id,
        qty: l.qty,
        note: l.note || null,
        options: l.selectedOptions,
      })),
    })
    saveOrderAccess(data.order_id, data.access_token)
    cart.clear()

    if (paymentMethod.value === 'online') {
      const returnUrl = `${window.location.origin}/orders/${data.order_id}?paid=1`
      const pay = await initiatePayment(data.order_id, data.access_token, returnUrl)
      if (pay.data.payment_form_html) {
        document.open()
        document.write(pay.data.payment_form_html)
        document.close()
        return
      }
      if (pay.data.message) alert(pay.data.message)
    }

    router.replace({
      name: 'order-status',
      params: { orderId: data.order_id },
      query: { token: data.access_token },
    })
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
.block { margin-bottom: 20px; }
.block h3 { margin: 0 0 8px; font-size: 15px; }
.block input, .block textarea { width: 100%; margin-bottom: 8px; padding: 10px; border: 1px solid #ddd; border-radius: 8px; }
.opts label { display: block; padding: 8px 0; }
.summary { background: #fffcf8; padding: 12px; border-radius: 10px; margin: 16px 0; }
.submit { width: 100%; border: 0; background: #c45c3e; color: #fff; padding: 14px; border-radius: 10px; font-size: 16px; font-weight: 600; }
.link { background: none; border: none; color: #c45c3e; }
.member-row { margin-bottom: 12px; }
</style>
