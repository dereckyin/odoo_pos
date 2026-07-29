<template>
  <div>
    <a-page-header title="桌邊 / 網路訂單監控">
      <template #extra>
        <a-space>
          <a-select
            v-model:value="channelFilter"
            style="width: 140px"
            allow-clear
            placeholder="來源"
            :options="channelOptions"
            @change="fetchData"
          />
          <a-select
            v-model:value="fulfillmentFilter"
            style="width: 120px"
            allow-clear
            placeholder="取餐"
            :options="fulfillmentOptions"
            @change="fetchData"
          />
          <a-select
            v-model:value="storeFilter"
            style="width: 220px"
            placeholder="選擇門店"
            allow-clear
            :options="storeOptions"
            @change="fetchData"
          />
          <a-select
            v-model:value="statusFilter"
            style="width: 280px"
            placeholder="狀態"
            mode="multiple"
            :options="statusOptions"
            @change="fetchData"
          />
          <a-button @click="fetchData">
            <template #icon><ReloadOutlined /></template>重新整理
          </a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-table
      :columns="columns"
      :data-source="orders"
      :loading="loading"
      row-key="id"
      :pagination="false"
      :expand-row-by-click="true"
    >
      <template #expandedRowRender="{ record }">
        <a-list size="small" :data-source="record.lines">
          <template #renderItem="{ item }">
            <a-list-item>
              <a-list-item-meta :title="`${item.product_name} × ${item.qty}`">
                <template #description>
                  <span v-if="item.options_json?.length">{{ item.options_json.map((o: any) => o.choice_name).join(' · ') }}・</span>
                  <span v-if="item.note">備註：{{ item.note }}・</span>
                  <span>單價 NT${{ item.unit_price_cents }}・小計 NT${{ item.line_total_cents }}</span>
                </template>
              </a-list-item-meta>
            </a-list-item>
          </template>
        </a-list>
        <div v-if="record.customer_note" style="margin-top: 8px">
          <a-tag color="orange">顧客備註</a-tag>
          {{ record.customer_note }}
        </div>
      </template>

      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'channel'">
          {{ channelLabel(record.channel) }}
        </template>
        <template v-else-if="column.key === 'fulfillment'">
          {{ fulfillmentLabel(record.fulfillment_type) }}
        </template>
        <template v-else-if="column.key === 'contact'">
          <span v-if="record.table_label">{{ record.table_label }}</span>
          <span v-else-if="record.customer_phone">{{ record.customer_name }} {{ record.customer_phone }}</span>
          <span v-else>—</span>
        </template>
        <template v-else-if="column.key === 'payment'">
          {{ paymentLabel(record) }}
        </template>
        <template v-else-if="column.key === 'delivery'">
          <template v-if="record.fulfillment_type === 'delivery'">
            <div>{{ deliveryLabel(record) }}</div>
            <a-button
              v-if="nextDelivery(record)"
              type="link"
              size="small"
              :loading="advancing === record.id"
              @click="advanceDelivery(record)"
            >
              → {{ deliveryStageLabel(nextDelivery(record)!) }}
            </a-button>
          </template>
          <template v-else>—</template>
        </template>
        <template v-else-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-if="column.key === 'estimated_subtotal_cents'">
          NT${{ record.estimated_subtotal_cents }}
        </template>
        <template v-if="column.key === 'created_at'">
          {{ formatTime(record.created_at) }}
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { ReloadOutlined } from '@ant-design/icons-vue'
import { message } from 'ant-design-vue'
import dayjs from 'dayjs'
import { listGuestOrders, setGuestOrderDeliveryStatus } from '@/api/tables'
import { listStores } from '@/api/stores'
import type { GuestOrderRead, StoreRead } from '@/types'

const DELIVERY_FLOW = ['pending', 'preparing', 'out_for_delivery', 'delivered'] as const
const advancing = ref<string | null>(null)

const orders = ref<GuestOrderRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const storeFilter = ref<string | undefined>(undefined)
const channelFilter = ref<string | undefined>(undefined)
const fulfillmentFilter = ref<string | undefined>(undefined)
const statusFilter = ref<string[]>(['submitted', 'accepted', 'ready'])
let pollHandle: number | null = null

const storeOptions = computed(() =>
  stores.value.map((s) => ({ label: `${s.code} ${s.name}`, value: s.id })),
)

const statusOptions = [
  { label: '已送出', value: 'submitted' },
  { label: '烹調中', value: 'accepted' },
  { label: '待結帳', value: 'ready' },
  { label: '已結帳', value: 'merged' },
  { label: '已取消', value: 'cancelled' },
]

const channelOptions = [
  { label: '桌邊 QR', value: 'table_qr' },
  { label: '網路市集', value: 'marketplace' },
  { label: '統一點餐', value: 'shopping' },
]
const fulfillmentOptions = [
  { label: '外帶', value: 'pickup' },
  { label: '外送', value: 'delivery' },
  { label: '內用', value: 'dine_in' },
]

const columns = [
  { title: '來源', key: 'channel', width: 100 },
  { title: '取餐', key: 'fulfillment', width: 80 },
  { title: '桌號/聯絡', key: 'contact', width: 120 },
  { title: '付款', key: 'payment', width: 100 },
  { title: '送達', key: 'delivery', width: 90 },
  { title: '狀態', key: 'status', width: 100 },
  { title: '人數', dataIndex: 'party_size', width: 80 },
  { title: '估計金額', key: 'estimated_subtotal_cents', width: 120 },
  { title: '送出時間', key: 'created_at', width: 180 },
  { title: 'guest order id', dataIndex: 'id' },
]

function channelLabel(ch: string | null | undefined) {
  return (
    ({ table_qr: 'QR', marketplace: '市集', shopping: '統一點餐' } as Record<string, string>)[
      ch ?? ''
    ] || ch || '—'
  )
}
function fulfillmentLabel(s: string | null | undefined) {
  return ({ pickup: '外帶', delivery: '外送', dine_in: '內用' } as Record<string, string>)[s ?? ''] || '—'
}
function paymentLabel(record: GuestOrderRead) {
  if (record.payment_method === 'online') {
    return record.payment_status === 'paid' ? '線上已付' : '線上待付'
  }
  if (record.payment_method === 'counter') return '櫃台付'
  return '—'
}
function deliveryStageLabel(s: string) {
  return (
    {
      pending: '待處理',
      preparing: '備餐中',
      out_for_delivery: '外送中',
      delivered: '已送達',
    } as Record<string, string>
  )[s] || s
}
function deliveryLabel(record: GuestOrderRead) {
  if (record.fulfillment_type !== 'delivery') return '—'
  return deliveryStageLabel(record.delivery_status || 'pending')
}
function nextDelivery(record: GuestOrderRead): string | null {
  const cur = record.delivery_status || 'pending'
  const idx = DELIVERY_FLOW.indexOf(cur as (typeof DELIVERY_FLOW)[number])
  if (idx < 0 || idx >= DELIVERY_FLOW.length - 1) return null
  return DELIVERY_FLOW[idx + 1]
}
async function advanceDelivery(record: GuestOrderRead) {
  const next = nextDelivery(record)
  if (!next) return
  advancing.value = record.id
  try {
    const { data } = await setGuestOrderDeliveryStatus(record.id, next)
    const i = orders.value.findIndex((o) => o.id === data.id)
    if (i >= 0) orders.value[i] = data
    message.success(`已更新為「${deliveryStageLabel(next)}」`)
  } catch {
    message.error('更新外送狀態失敗')
  } finally {
    advancing.value = null
  }
}
function statusColor(s: string) {
  switch (s) {
    case 'submitted':
      return 'orange'
    case 'accepted':
      return 'blue'
    case 'ready':
      return 'green'
    case 'merged':
      return 'default'
    case 'cancelled':
      return 'red'
    default:
      return 'default'
  }
}
function statusLabel(s: string) {
  return (
    {
      submitted: '已送出',
      accepted: '烹調中',
      ready: '待結帳',
      merged: '已結帳',
      cancelled: '已取消',
    } as Record<string, string>
  )[s] || s
}
function formatTime(t: string) {
  return dayjs(t).format('YYYY-MM-DD HH:mm:ss')
}

async function fetchStores() {
  const { data } = await listStores()
  stores.value = data
  if (!storeFilter.value && data.length) storeFilter.value = data[0].id
}
async function fetchData() {
  loading.value = true
  try {
    const { data } = await listGuestOrders({
      store_id: storeFilter.value,
      status_in: statusFilter.value.join(','),
      channel: channelFilter.value,
      fulfillment_type: fulfillmentFilter.value,
    })
    orders.value = data
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await fetchStores()
  await fetchData()
  pollHandle = window.setInterval(fetchData, 5000)
})
onBeforeUnmount(() => {
  if (pollHandle != null) window.clearInterval(pollHandle)
})
</script>
