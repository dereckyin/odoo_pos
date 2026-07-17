<template>
  <div v-if="d">
    <div class="subhead">
      <h2 style="text-align: center; width: 100%">訂單已成立</h2>
    </div>
    <div class="done-hero">
      <div class="mark"><span v-html="ii('check', 30)" /></div>
      <h2>{{ d.mode === 'dinein' ? '感謝您的訂購' : '訂單已送出' }}</h2>
      <div class="sub" v-html="heroSub" />
      <div class="order-no">
        <div>
          <div class="k">{{ leftKey }}</div>
          <div class="v num">{{ d.pickupNo }}</div>
        </div>
        <div>
          <div class="k">{{ rightKey }}</div>
          <div class="v num">{{ rightVal }}</div>
        </div>
      </div>
    </div>

    <div
      class="notice"
      :class="{ amber: d.mode === 'takeout' }"
      v-html="noticeHtml"
    />

    <div v-if="d.mode === 'delivery'" class="progress">
      <div class="pstep on"><div class="pd" /><div class="pl">已接單</div></div>
      <div class="pstep"><div class="pd" /><div class="pl">製作中</div></div>
      <div class="pstep"><div class="pd" /><div class="pl">外送中</div></div>
      <div class="pstep"><div class="pd" /><div class="pl">已送達</div></div>
    </div>

    <div class="page-body" style="padding-top: 0">
      <div class="card">
        <div class="card-title">訂單內容</div>
        <div v-for="it in d.lines" :key="it.key" class="cline">
          <div class="cinfo">
            <div class="cname">{{ it.name }} ×{{ it.qty }}</div>
            <div v-if="it.optionsLabel" class="copts">{{ it.optionsLabel }}</div>
          </div>
          <div class="cprice num">NT$ {{ moneyYuan(it.unitCents * it.qty) }}</div>
        </div>
        <OrderSummary
          :mode="d.mode"
          :subtotal="d.subtotalCents"
          :delivery-fee="d.deliveryFeeCents"
          :discount="d.discountCents"
          :total="d.totalCents"
        />
      </div>
      <p v-if="d.isDemo" class="empty" style="padding: 8px 0 16px">
        示範模式：未呼叫後端。加上 ?store=&lt;slug&gt; 可送真實訂單。
      </p>
      <button type="button" class="btn-ghost" @click="backMenu">返回菜單</button>
    </div>
  </div>
  <div v-else class="loading-box">
    沒有訂單資料
    <div style="margin-top: 16px">
      <button type="button" class="btn-ghost" @click="backMenu">返回菜單</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import OrderSummary from '@/components/OrderSummary.vue'
import { moneyYuan } from '@/entry'
import { ii } from '@/icons'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
const router = useRouter()
const d = computed(() => session.done)

const heroSub = computed(() => {
  const x = d.value
  if (!x) return ''
  const cash = x.payment === 'cash'
  if (x.mode === 'dinein') {
    return `${cash ? '請於用餐後至櫃檯結帳' : '付款完成（示意）'}　·　餐點將送到 ${x.table} 桌`
  }
  if (x.mode === 'takeout') {
    return `${cash ? '請於取餐時至櫃檯付款' : '付款完成（示意）'}　·　備好會通知你`
  }
  return `付款完成（示意）　·　${x.storeName} 將為你配送`
})

const leftKey = computed(() => (d.value?.mode === 'takeout' ? '取餐號碼' : '訂單編號'))
const rightKey = computed(() => {
  if (d.value?.mode === 'dinein') return '內用桌號'
  if (d.value?.mode === 'takeout') return '預計取餐'
  return '預計送達'
})
const rightVal = computed(() => {
  const x = d.value
  if (!x) return ''
  if (x.mode === 'dinein') return x.table
  return x.pickTime === '盡快' ? (x.mode === 'takeout' ? '盡快' : '盡快') : x.pickTime || '—'
})

const noticeHtml = computed(() => {
  const x = d.value
  if (!x) return ''
  const pts = Math.round(x.totalCents / 10) + (x.memberOn ? 10 : 0)
  const ptsLine = x.memberOn ? `已綁定會員（示意），本單獲得 <b>${pts} 點</b>。` : ''
  if (x.mode === 'dinein') {
    return `餐點狀態會通知你：接單 → 製作中 → 已送餐。${ptsLine}`
  }
  if (x.mode === 'takeout') {
    return `餐點狀態會通知你：接單 → 製作中 → <b>可取餐</b>（憑取餐號到門市領取）。${ptsLine}`
  }
  return `外送由<b>店家自己配送</b>。送達地址：${x.address}。${ptsLine}`
})

function backMenu() {
  session.resetAfterDone()
  router.replace({ name: 'menu', query: session.entryQuery() })
}
</script>
