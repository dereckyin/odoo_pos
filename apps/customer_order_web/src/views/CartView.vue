<template>
  <div class="cart-page">
    <header class="topbar">
      <button class="back" @click="goBack">‹</button>
      <span class="title">購物車</span>
      <span class="spacer" />
    </header>

    <main class="cart-list" v-if="cart.lines.length > 0">
      <div v-for="line in cart.lines" :key="line.lineKey" class="line">
        <div class="line-head">
          <div class="name">{{ line.product.name }}</div>
          <div class="price">${{ Math.round(cart.unitPriceCents(line.product, line.selectedOptions)) }}</div>
        </div>
        <div v-if="line.selectedOptions.length" class="options">
          {{ line.selectedOptions.map((o) => o.choice_name).join(' · ') }}
        </div>
        <div class="qty-row">
          <button @click="dec(line.lineKey, line.qty)">−</button>
          <span class="qty">{{ line.qty }}</span>
          <button @click="inc(line.lineKey, line.qty)">+</button>
          <span class="line-total">小計 ${{
            Math.round(cart.unitPriceCents(line.product, line.selectedOptions) * line.qty)
          }}</span>
        </div>
        <input
          v-model="line.note"
          class="note-input"
          placeholder="其他備註（選填）"
        />
      </div>

      <div class="block">
        <label>整單備註</label>
        <textarea
          v-model="cart.customerNote"
          rows="2"
          placeholder="例：兒童餐具、麻煩慢一點上菜"
        />
      </div>

      <div class="block">
        <label>用餐人數（選填）</label>
        <input
          v-model.number="cart.partySize"
          type="number"
          min="1"
          max="20"
          inputmode="numeric"
        />
      </div>

      <div class="block member-block">
        <div class="member-row">
          <label>會員</label>
          <button v-if="!memberStore.isLoggedIn" type="button" class="member-btn" @click="loginOpen = true">登入累點</button>
          <div v-else class="member-info">
            <span>{{ memberStore.member!.name }}（{{ memberStore.member!.points }} 點）</span>
            <button type="button" class="link-btn" @click="memberStore.logout()">登出</button>
          </div>
        </div>
        <p v-if="memberStore.isLoggedIn" class="earn-hint">
          預估本次累點 {{ memberStore.estimatedEarnPoints(cart.subtotalCents) }} 點（櫃台結帳後入帳）
        </p>
      </div>

      <p class="payment-hint">送出後請至櫃台結帳。</p>
    </main>

    <main v-else class="empty"><p>購物車是空的</p></main>

    <MemberLoginModal :open="loginOpen" :table-token="tableToken" @close="loginOpen = false" />

    <footer v-if="cart.lines.length > 0" class="submit-bar">
      <div class="total">
        <span>合計</span>
        <strong>${{ Math.round(cart.subtotalCents) }}</strong>
      </div>
      <button class="submit-btn" :disabled="submitting" @click="submit">
        {{ submitting ? '送出中…' : '送出點餐' }}
      </button>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { submitOrder } from '@/api'
import { tableTokenFromRoute } from '@/tableToken'
import { useCartStore } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'
import MemberLoginModal from '@/components/MemberLoginModal.vue'

const router = useRouter()
const route = useRoute()
const cart = useCartStore()
const memberStore = useMemberStore()
const submitting = ref(false)
const loginOpen = ref(false)
const tableToken = computed(() => tableTokenFromRoute(route) || '')

onMounted(() => memberStore.restore())

function goBack() {
  const t = tableTokenFromRoute(route)
  router.push({ path: '/order', query: t ? { t } : {} })
}

function inc(lineKey: string, q: number) {
  cart.setQty(lineKey, q + 1)
}
function dec(lineKey: string, q: number) {
  cart.setQty(lineKey, q - 1)
}

async function submit() {
  const t = tableTokenFromRoute(route)
  if (!t) {
    alert('沒有桌位資訊，請重新掃碼')
    return
  }
  submitting.value = true
  try {
    const { data } = await submitOrder(t, {
      customer_note: cart.customerNote || null,
      party_size: cart.partySize ?? null,
      member_id: memberStore.member?.id ?? null,
      lines: cart.lines.map((l) => ({
        product_id: l.product.id,
        qty: l.qty,
        note: l.note || null,
        options: l.selectedOptions.length ? l.selectedOptions : null,
      })),
    })
    cart.clear()
    router.replace({ name: 'status', params: { orderId: data.id }, query: { t } })
  } catch (e: any) {
    alert(e.response?.data?.detail || '送單失敗，請稍後再試')
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.cart-page {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  padding-bottom: 96px;
}
.topbar {
  position: sticky;
  top: 0;
  background: #fff;
  padding: 12px 16px;
  display: grid;
  grid-template-columns: 40px 1fr 40px;
  align-items: center;
  border-bottom: 1px solid #eee;
}
.topbar .back {
  background: transparent;
  border: 0;
  font-size: 28px;
  color: #ff6b35;
}
.topbar .title {
  text-align: center;
  font-size: 16px;
  font-weight: 600;
}
.cart-list {
  padding: 12px;
  flex: 1;
}
.line {
  background: #fff;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 10px;
}
.line-head {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}
.line-head .name {
  font-weight: 600;
}
.line-head .price {
  color: #ff6b35;
}
.options {
  font-size: 13px;
  color: #888;
  margin-bottom: 6px;
}
.qty-row {
  display: flex;
  gap: 8px;
  align-items: center;
}
.qty-row button {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: #ffeee6;
  color: #ff6b35;
  border: 0;
  font-size: 20px;
}
.qty-row .qty {
  min-width: 24px;
  text-align: center;
  font-weight: 600;
}
.line-total {
  margin-left: auto;
  color: #888;
}
.note-input {
  margin-top: 8px;
  width: 100%;
  padding: 8px;
  border: 1px solid #eee;
  border-radius: 8px;
  font-size: 14px;
}
.block {
  margin: 12px 0;
}
.block label {
  display: block;
  font-size: 13px;
  color: #555;
  margin-bottom: 6px;
}
.block textarea,
.block input {
  width: 100%;
  padding: 8px;
  border-radius: 8px;
  border: 1px solid #ddd;
  font-size: 14px;
}
.payment-hint {
  text-align: center;
  color: #888;
  font-size: 13px;
  margin: 16px 0;
}
.member-block { background: #fff8f4; padding: 12px; border-radius: 10px; }
.member-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.member-btn { background: #ff6b35; color: #fff; border: 0; padding: 6px 12px; border-radius: 8px; }
.member-info { display: flex; align-items: center; gap: 8px; font-size: 14px; }
.link-btn { background: none; border: none; color: #888; font-size: 13px; }
.earn-hint { font-size: 12px; color: #c45c3e; margin: 8px 0 0; }
.empty {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #888;
}
.submit-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  align-items: center;
  background: #fff;
  border-top: 1px solid #eee;
  padding: 10px 16px calc(10px + env(safe-area-inset-bottom));
  gap: 12px;
}
.submit-bar .total {
  flex: 0 0 auto;
  display: flex;
  flex-direction: column;
}
.submit-bar .total strong {
  font-size: 20px;
  color: #ff6b35;
}
.submit-bar .submit-btn {
  flex: 1;
  background: #ff6b35;
  color: #fff;
  border: 0;
  border-radius: 10px;
  padding: 14px 20px;
  font-size: 17px;
  font-weight: 600;
}
.submit-bar .submit-btn:disabled {
  background: #ccc;
}
</style>
