<template>
  <div>
    <a-page-header :title="pageTitle" :sub-title="pageSubtitle">
      <template v-if="!isCashier" #extra>
        <a-select
          v-model:value="storeId"
          style="width: 220px"
          placeholder="選擇書店"
          :options="bookstores.map((s) => ({ value: s.id, label: s.name }))"
          @change="reload"
        />
      </template>
    </a-page-header>

    <a-empty v-if="!loadingStores && !bookstores.length" description="尚無實體書店門店，請先到門店管理把門店類型設為實體書店" />

    <template v-else>
      <a-card title="現金收款" size="small" style="margin-bottom: 16px">
        <a-input-search
          ref="cashInput"
          v-model:value="cashValue"
          placeholder="掃描顧客 App 上的付款 QR，或輸入 6 位數付款碼"
          enter-button="查詢"
          size="large"
          :loading="cashLooking"
          autocomplete="off"
          @search="doCashLookup"
        />
        <div v-if="cashResult" class="verify-result" :class="`cash-${cashResult.result}`">
          <template v-if="cashResult.result === 'found' && cashResult.checkout">
            <ul class="verify-lines">
              <li v-for="ln in cashResult.checkout.lines" :key="ln.product_id">
                {{ ln.product_name }} × {{ ln.qty }}　NT$ {{ ln.line_total_cents }}
              </li>
            </ul>
            <div class="cash-row">原價 NT$ {{ cashResult.checkout.subtotal_cents }}</div>
            <div v-if="cashResult.checkout.discount_cents" class="cash-row">
              現金折扣 −NT$ {{ cashResult.checkout.discount_cents }}
            </div>
            <div class="cash-due">應收現金 NT$ {{ cashResult.checkout.total_cents }}</div>
            <a-alert
              v-if="cashResult.checkout.status === 'expired'"
              type="warning"
              show-icon
              style="margin: 8px 0"
              message="保留時間已過，庫存可能已釋出；請確認顧客手上的書再收款。"
            />
            <a-space style="margin-top: 8px" align="center" wrap>
              <span>收取</span>
              <a-input-number v-model:value="cashReceived" :min="0" :precision="0" style="width: 140px" />
              <span v-if="cashChange !== null" :class="{ 'cash-short': cashChange < 0 }">
                {{ cashChange < 0 ? `還差 NT$ ${-cashChange}` : `找零 NT$ ${cashChange}` }}
              </span>
              <a-popconfirm
                :title="`確認已收現金 NT$ ${cashResult.checkout.total_cents}？`"
                ok-text="確認收款"
                @confirm="doCashConfirm"
              >
                <a-button type="primary" size="large" :loading="cashConfirming" :disabled="cashChange !== null && cashChange < 0">
                  確認已收現金
                </a-button>
              </a-popconfirm>
            </a-space>
          </template>
          <div v-else class="verify-title">{{ cashResultLabel(cashResult.result) }}</div>
        </div>
      </a-card>

      <a-card size="small">
        <template #title>
          App 結帳紀錄
          <a-radio-group v-model:value="statusFilter" size="small" style="margin-left: 12px" @change="reload">
            <a-radio-button value="">全部</a-radio-button>
            <a-radio-button value="pending">待付款</a-radio-button>
            <a-radio-button value="paid">已付款</a-radio-button>
            <a-radio-button v-if="!isCashier" value="refunded">已退貨</a-radio-button>
          </a-radio-group>
        </template>
        <a-table
          :columns="columns"
          :data-source="rows"
          :loading="loading"
          row-key="id"
          size="small"
          :pagination="{ pageSize: 20 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'status'">
              <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
              <a-tooltip v-if="record.paid_after_expiry" title="保留逾時後才付款，庫存可能需人工確認">
                <a-tag color="orange">逾時付款</a-tag>
              </a-tooltip>
            </template>
            <template v-else-if="column.key === 'items'">
              <div v-for="ln in record.lines" :key="ln.product_id">{{ ln.product_name }} × {{ ln.qty }}</div>
            </template>
            <template v-else-if="column.key === 'total'">
              NT$ {{ record.total_cents }}
              <div v-if="record.discount_cents" class="sub">原價 {{ record.subtotal_cents }}</div>
            </template>
            <template v-else-if="column.key === 'method'">
              {{ record.payment_method === 'cash' ? '現金' : record.payment_method ? '線上' : '-' }}
            </template>
            <template v-else-if="column.key === 'paid_at'">{{ record.paid_at ? fmt(record.paid_at) : '-' }}</template>
            <template v-else-if="column.key === 'invoice'">
              <span v-if="record.invoice_number">{{ record.invoice_number }}</span>
              <a-tag v-else-if="record.invoice_status === 'failed'" color="red">開立失敗</a-tag>
              <span v-else>-</span>
            </template>
            <template v-else-if="column.key === 'actions'">
              <a-button v-if="!isCashier && record.status === 'paid'" size="small" danger @click="openRefund(record)">退貨</a-button>
            </template>
          </template>
        </a-table>
      </a-card>
    </template>

    <a-modal
      v-model:open="refundOpen"
      title="App 結帳退貨"
      ok-text="確認退貨"
      :ok-button-props="{ danger: true, disabled: !refundReason.trim() }"
      :confirm-loading="refunding"
      @ok="doRefund"
    >
      <p v-if="refundTarget">訂單 {{ refundTarget.order_no }}・NT$ {{ refundTarget.total_cents }}</p>
      <a-alert
        type="warning"
        show-icon
        style="margin-bottom: 12px"
        message="系統會回補庫存並作廢發票；刷卡款項需另至金流後台辦理退刷。"
      />
      <a-textarea v-model:value="refundReason" placeholder="退貨原因" :rows="3" :maxlength="500" />
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref } from 'vue'
import { message } from 'ant-design-vue'
import { useAuthStore } from '@/stores/auth'
import { listStores } from '@/api/stores'
import {
  confirmCashPayment,
  listBookstoreCheckouts,
  lookupCashPayment,
  refundBookstoreCheckout,
  type CashLookupResponse,
  type StaffCheckoutRead,
} from '@/api/bookstore'
import type { StoreRead } from '@/types'

const auth = useAuthStore()
const isCashier = computed(() => auth.isFloorCashier)
const pageTitle = computed(() => (isCashier.value ? '櫃台收款' : '實體書店 App 結帳'))
const pageSubtitle = '掃描顧客 App 付款碼，確認收款後即可帶書離開'
const bookstores = ref<StoreRead[]>([])
const loadingStores = ref(true)
const storeId = ref<string>()
const rows = ref<StaffCheckoutRead[]>([])
const loading = ref(false)
const statusFilter = ref('')

const cashInput = ref()
const cashValue = ref('')
const cashLooking = ref(false)
const cashConfirming = ref(false)
const cashResult = ref<CashLookupResponse | null>(null)
const cashReceived = ref<number | null>(null)
const cashChange = computed(() => {
  const due = cashResult.value?.checkout?.total_cents
  if (due == null || cashReceived.value == null) return null
  return cashReceived.value - due
})

const refundOpen = ref(false)
const refundTarget = ref<StaffCheckoutRead | null>(null)
const refundReason = ref('')
const refunding = ref(false)

const columns = computed(() => {
  const base = [
    { title: '訂單', dataIndex: 'order_no', width: 170 },
    { title: '狀態', key: 'status', width: 140 },
    { title: '品項', key: 'items' },
    { title: '金額', key: 'total', width: 100 },
    { title: '付款方式', key: 'method', width: 90 },
    { title: '付款時間', key: 'paid_at', width: 160 },
  ]
  if (isCashier.value) return base
  return [
    ...base,
    { title: '發票', key: 'invoice', width: 120 },
    { title: '', key: 'actions', width: 80 },
  ]
})

function fmt(iso: string) {
  return new Date(iso).toLocaleString()
}

function statusLabel(s: string) {
  return ({ pending: '待付款', paid: '已付款', expired: '逾時', cancelled: '已取消', refunded: '已退貨' } as Record<string, string>)[s] || s
}

function statusColor(s: string) {
  return ({ paid: 'green', refunded: 'red', pending: 'blue' } as Record<string, string>)[s] || 'default'
}

function cashResultLabel(r: CashLookupResponse['result']) {
  return {
    found: '',
    invalid: '找不到這筆現金付款，請確認付款碼',
    already_paid: '這筆已經收過款了',
    closed: '這筆結帳已取消或退貨，請顧客重新結帳',
  }[r]
}

function errText(e: any, fallback: string) {
  const d = e.response?.data?.detail
  return typeof d === 'object' && d ? d.message : d || fallback
}

async function doCashLookup() {
  const raw = cashValue.value.trim()
  if (!raw || !storeId.value) return
  cashLooking.value = true
  cashReceived.value = null
  try {
    const isCode = /^\d{6}$/.test(raw)
    const { data } = await lookupCashPayment(
      isCode ? { code: raw, store_id: storeId.value } : { token: raw, store_id: storeId.value },
    )
    cashResult.value = data
  } catch (e: any) {
    message.error(errText(e, '查詢失敗'))
  } finally {
    cashLooking.value = false
    cashValue.value = ''
  }
}

async function doCashConfirm() {
  const checkout = cashResult.value?.checkout
  if (!checkout) return
  cashConfirming.value = true
  try {
    const { data } = await confirmCashPayment(checkout.id, checkout.total_cents)
    message.success(`已收款 NT$ ${data.total_cents}，訂單完成，顧客可以帶書離開`)
    cashResult.value = null
    cashReceived.value = null
    reload()
    await nextTick()
    cashInput.value?.focus?.()
  } catch (e: any) {
    message.error(errText(e, '收款失敗'))
  } finally {
    cashConfirming.value = false
  }
}

async function reload() {
  if (!storeId.value) return
  loading.value = true
  try {
    const { data } = await listBookstoreCheckouts({
      store_id: storeId.value,
      status: statusFilter.value || undefined,
      limit: 200,
    })
    rows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入')
  } finally {
    loading.value = false
  }
}

function openRefund(rec: StaffCheckoutRead) {
  refundTarget.value = rec
  refundReason.value = ''
  refundOpen.value = true
}

async function doRefund() {
  if (!refundTarget.value) return
  refunding.value = true
  try {
    const { data } = await refundBookstoreCheckout(refundTarget.value.id, refundReason.value.trim())
    message.success(data.message)
    refundOpen.value = false
    reload()
  } catch (e: any) {
    const d = e.response?.data?.detail
    message.error(typeof d === 'object' ? d.message : d || '退貨失敗')
  } finally {
    refunding.value = false
  }
}

onMounted(async () => {
  try {
    const { data } = await listStores()
    bookstores.value = data.filter((s) => s.store_kind === 'bookstore')
    storeId.value =
      (auth.storeId && bookstores.value.some((s) => s.id === auth.storeId) && auth.storeId) ||
      bookstores.value[0]?.id
    await reload()
  } finally {
    loadingStores.value = false
  }
})
</script>

<style scoped>
.verify-result {
  margin-top: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 15px;
}
.verify-title {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 4px;
}
.verify-lines {
  margin: 8px 0 0;
  padding-left: 20px;
}
.cash-found {
  background: #f0f5ff;
  border: 1px solid #adc6ff;
}
.cash-already_paid {
  background: #fffbe6;
  border: 1px solid #ffe58f;
}
.cash-invalid,
.cash-closed {
  background: #fff1f0;
  border: 1px solid #ffa39e;
}
.cash-row {
  color: #555;
  margin-top: 4px;
}
.cash-due {
  font-size: 24px;
  font-weight: 700;
  margin-top: 6px;
}
.cash-short {
  color: #cf1322;
  font-weight: 600;
}
.sub {
  color: #999;
  font-size: 12px;
  text-decoration: line-through;
}
</style>
