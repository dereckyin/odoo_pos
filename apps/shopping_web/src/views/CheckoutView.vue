<template>
  <div>
    <div class="subhead">
      <button type="button" class="back" @click="goCart" v-html="ii('back', 16)" />
      <h2>結帳</h2>
      <span class="step">2 / 2</span>
    </div>

    <div class="page-body">
      <!-- fulfillment -->
      <div v-if="session.mode === 'dinein'" class="card">
        <div class="card-title">取餐方式</div>
        <div class="cline">
          <div class="cinfo">
            <div class="cname">內用 · 桌號 {{ session.table }}</div>
            <div class="copts">餐點將由服務人員送至您的桌位</div>
          </div>
        </div>
      </div>

      <template v-else-if="session.mode === 'takeout'">
        <div class="card">
          <div class="card-title">取餐門市</div>
          <div class="store-line">
            <span v-html="ic('store', 20)" />
            <div>
              <div class="sn">{{ session.store?.name }}</div>
              <div class="sa">{{ session.store?.addr }}</div>
            </div>
          </div>
        </div>
        <div class="card">
          <div class="card-title">預計取餐時間<span class="req">必選</span></div>
          <div class="fieldwrap">
            <div class="timegrid">
              <button
                v-for="t in PICKUP_TIMES"
                :key="t[0]"
                type="button"
                :class="{ on: session.pickTime === t[0] }"
                @click="session.pickTime = t[0]"
              >
                {{ t[0] }}
                <small v-if="t[1]">{{ t[1] }}</small>
              </button>
            </div>
          </div>
        </div>
      </template>

      <template v-else>
        <div class="card">
          <div class="card-title">外送地址<span class="req">必填</span></div>
          <div class="fieldwrap">
            <label>收件地址</label>
            <input v-model="session.addrLine" placeholder="例：民生東路三段 100 號 5 樓" />
          </div>
          <div class="fieldwrap">
            <label>聯絡電話</label>
            <input
              v-model="session.addrPhone"
              inputmode="tel"
              placeholder="外送員聯絡用"
            />
          </div>
          <div class="fieldwrap">
            <label>聯絡姓名</label>
            <input v-model="session.customerName" placeholder="姓名" />
          </div>
          <div class="store-line" style="border-top: 1px solid var(--line)">
            <span v-html="ic('pin', 20)" />
            <div>
              <div class="sn">配送方式：店家自送</div>
              <div class="sa">
                外送費 NT${{ session.store?.deliveryFeeCents }}　·　預計送達約 30–40 分
              </div>
            </div>
          </div>
        </div>
        <div class="card">
          <div class="card-title">預計送達時間<span class="req">必選</span></div>
          <div class="fieldwrap">
            <div class="timegrid">
              <button
                v-for="t in PICKUP_TIMES"
                :key="t[0]"
                type="button"
                :class="{ on: session.pickTime === t[0] }"
                @click="session.pickTime = t[0]"
              >
                {{ t[0] }}
                <small v-if="t[1]">{{ t[1] }}</small>
              </button>
            </div>
          </div>
        </div>
      </template>

      <div class="member-toggle">
        <div class="mi">
          <div class="mk">餐飲聯盟 · 一張卡走遍商圈</div>
          <div class="mn">
            綁定會員：這單折 NT${{ MEMBER_DISCOUNT_CENTS }}、開始集點<br />
            <span style="font-size: 11px; font-weight: 400; color: #d6e4d2"
              >示意開關（LIFF 會員歸戶後續串接）</span
            >
          </div>
        </div>
        <div class="switch" :class="{ on: session.memberOn }" @click="session.memberOn = !session.memberOn" />
      </div>

      <div class="card">
        <div class="card-title">付款方式</div>
        <button
          v-for="p in pays"
          :key="p.k"
          type="button"
          class="pay-opt"
          :class="{ on: session.payMode === p.k }"
          @click="session.payMode = p.k"
        >
          <span class="radio" />
          <span class="pi">
            <span class="pn">{{ p.n }}</span>
            <span class="pd">{{ p.d }}</span>
          </span>
          <span v-html="ic(p.ic, 22)" />
        </button>
      </div>

      <div v-if="session.payMode !== 'cash'" class="card">
        <div class="card-title">電子發票 <span class="hint">示意（後續串接）</span></div>
        <div class="seg">
          <button
            type="button"
            :class="{ on: session.inv === 'member' }"
            @click="session.inv = 'member'"
          >
            存入會員載具
          </button>
          <button
            type="button"
            :class="{ on: session.inv === 'carrier' }"
            @click="session.inv = 'carrier'"
          >
            手機條碼
          </button>
          <button type="button" :class="{ on: session.inv === 'tax' }" @click="session.inv = 'tax'">
            統一編號
          </button>
        </div>
      </div>

      <div class="card">
        <OrderSummary
          :mode="session.mode"
          :subtotal="cart.subtotal"
          :delivery-fee="session.deliveryFee"
          :discount="session.discount"
          :total="cart.grandTotal()"
        />
      </div>
    </div>

    <div class="footbtn">
      <div class="foothint">{{ miss || session.submitError }}</div>
      <button
        type="button"
        class="btn-red"
        :disabled="!!miss || session.submitting"
        @click="onSubmit"
      >
        {{ session.submitting ? '送出中…' : '送出訂單' }}
        <span> NT$ {{ moneyYuan(cart.grandTotal()) }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import OrderSummary from '@/components/OrderSummary.vue'
import { moneyYuan } from '@/entry'
import { ic, ii } from '@/icons'
import { MEMBER_DISCOUNT_CENTS, PICKUP_TIMES } from '@/mock/demoMenu'
import { placeOrder } from '@/services/submitOrder'
import { useCartStore } from '@/stores/cart'
import { useSessionStore } from '@/stores/session'
import type { PaymentUiKey } from '@/types'

const session = useSessionStore()
const cart = useCartStore()
const router = useRouter()

const pays = computed(() => {
  const mode = session.mode
  const list: Array<{ k: PaymentUiKey; n: string; d: string; ic: string }> =
    mode === 'dinein'
      ? [
          { k: 'linepay', n: 'LINE Pay', d: '桌邊即時付款（示意）', ic: 'phone' },
          { k: 'card', n: '信用卡 / Apple Pay', d: '桌邊即時付款（示意）', ic: 'card' },
          { k: 'cash', n: '櫃檯付現', d: '用餐後至櫃檯結帳', ic: 'cash' },
        ]
      : mode === 'takeout'
        ? [
            { k: 'linepay', n: 'LINE Pay', d: '外帶建議先付（示意）', ic: 'phone' },
            { k: 'card', n: '信用卡 / Apple Pay', d: '線上先付（示意）', ic: 'card' },
            { k: 'cash', n: '到店付現', d: '取餐時付款', ic: 'cash' },
          ]
        : [
            { k: 'linepay', n: 'LINE Pay', d: '外送需線上先付（示意）', ic: 'phone' },
            { k: 'card', n: '信用卡 / Apple Pay', d: '線上先付（示意）', ic: 'card' },
          ]
  return list.filter((p) => {
    if (!session.store) return true
    if (p.k === 'cash') return session.store.paymentCounter
    return session.store.paymentOnline || session.store.paymentCounter
  })
})

watch(
  pays,
  (list) => {
    if (!list.find((p) => p.k === session.payMode) && list[0]) session.payMode = list[0].k
  },
  { immediate: true },
)

const miss = computed(() => {
  if (!cart.lines.length) return '購物車是空的'
  if (session.mode === 'takeout' && !session.pickTime) return '請先選擇取餐時間'
  if (session.mode === 'delivery') {
    if (cart.belowMin() && session.store)
      return `外送未達最低金額 NT$${session.store.deliveryMinCents}`
    if (!session.addrLine.trim()) return '請填寫外送地址'
    if (!session.addrPhone.trim()) return '請填寫聯絡電話'
    if (!session.pickTime) return '請選擇送達時間'
  }
  return ''
})

function goCart() {
  router.push({ name: 'cart', query: session.entryQuery() })
}

async function onSubmit() {
  if (miss.value || !session.store) return
  session.submitting = true
  session.submitError = ''
  try {
    const snap = await placeOrder({
      isDemo: session.isDemo,
      store: session.store,
      mode: session.mode,
      table: session.table,
      pickTime: session.pickTime,
      addrLine: session.addrLine,
      addrPhone: session.addrPhone,
      customerName: session.customerName,
      payMode: session.payMode,
      memberOn: session.memberOn,
      orderNote: session.orderNote,
      lines: cart.lines,
      subtotalCents: cart.subtotal,
      deliveryFeeCents: session.deliveryFee,
      discountCents: session.discount,
      totalCents: cart.grandTotal(),
    })
    session.done = snap
    await router.replace({ name: 'done', query: session.entryQuery() })
  } catch (err: unknown) {
    const ax = err as { response?: { data?: { detail?: string } }; message?: string }
    const detail = ax.response?.data?.detail
    session.submitError = typeof detail === 'string' ? detail : ax.message || '送出失敗'
  } finally {
    session.submitting = false
  }
}
</script>
