<template>
  <div>
    <a-page-header title="訂單查詢">
      <template #extra>
        <a-space wrap>
          <a-range-picker
            v-model:value="dateRange"
            :presets="datePresets"
            format="YYYY/MM/DD"
            @change="onFilterChange"
          />
          <a-select
            v-if="storeOptions.length > 1"
            v-model:value="storeFilter"
            style="width: 200px"
            placeholder="門店"
            allow-clear
            :options="storeOptions"
            @change="onFilterChange"
          />
          <a-select
            v-model:value="statusFilter"
            style="width: 140px"
            placeholder="狀態"
            allow-clear
            :options="statusOptions"
            @change="onFilterChange"
          />
          <a-select
            v-model:value="paymentFilter"
            style="width: 140px"
            placeholder="付款方式"
            allow-clear
            :options="paymentOptions"
            @change="onFilterChange"
          />
          <a-input-search
            v-model:value="keyword"
            placeholder="訂單編號 / 發票號"
            style="width: 200px"
            allow-clear
            @search="onFilterChange"
          />
          <a-button @click="fetchData">
            <template #icon><ReloadOutlined /></template>
            重新整理
          </a-button>
          <a-button :loading="exporting" @click="handleExport">匯出 CSV</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-table
      :columns="columns"
      :data-source="orders"
      :loading="loading"
      row-key="id"
      :pagination="pagination"
      @change="onTableChange"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'order_no'">
          <a @click="goDetail(record.id)">{{ record.order_no || record.id.slice(0, 8) }}</a>
        </template>
        <template v-if="column.key === 'time'">
          {{ formatTime(record.client_created_at || record.created_at) }}
        </template>
        <template v-if="column.key === 'store'">
          {{ record.store_name || '—' }}
        </template>
        <template v-if="column.key === 'total'">
          {{ formatMoney(record.total_cents) }}
        </template>
        <template v-if="column.key === 'net'">
          {{ formatMoney(record.total_cents - record.refunded_cents) }}
        </template>
        <template v-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-if="column.key === 'payment'">
          <a-tag v-for="m in record.payment_methods || []" :key="m" style="margin: 2px">
            {{ paymentLabel(m) }}
          </a-tag>
        </template>
        <template v-if="column.key === 'member'">
          {{ record.member_name || '散客' }}
        </template>
        <template v-if="column.key === 'source'">
          <a-tag :color="record.source === 'qr' ? 'purple' : 'blue'">
            {{ record.source === 'qr' ? 'QR 點餐' : 'POS' }}
          </a-tag>
        </template>
        <template v-if="column.key === 'actions'">
          <a-button size="small" @click="goDetail(record.id)">查看</a-button>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ReloadOutlined } from '@ant-design/icons-vue'
import dayjs, { type Dayjs } from 'dayjs'
import { listOrders, exportOrdersCsv } from '@/api/orders'
import { listStores } from '@/api/stores'
import { formatMoney } from '@/utils/formatMoney'
import type { OrderListItem, StoreRead } from '@/types'
import { message } from 'ant-design-vue'

const router = useRouter()
const orders = ref<OrderListItem[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const exporting = ref(false)
const total = ref(0)
const page = ref(1)
const pageSize = ref(20)

const dateRange = ref<[Dayjs, Dayjs] | null>(null)
const storeFilter = ref<string | undefined>()
const statusFilter = ref<string | undefined>()
const paymentFilter = ref<string | undefined>()
const keyword = ref('')

const datePresets = [
  { label: '今日', value: [dayjs().startOf('day'), dayjs().endOf('day')] },
  { label: '昨日', value: [dayjs().subtract(1, 'day').startOf('day'), dayjs().subtract(1, 'day').endOf('day')] },
  { label: '本週', value: [dayjs().startOf('week'), dayjs().endOf('day')] },
  { label: '本月', value: [dayjs().startOf('month'), dayjs().endOf('day')] },
]

const storeOptions = computed(() =>
  stores.value.map((s) => ({ label: `${s.code} ${s.name}`, value: s.id })),
)

const statusOptions = [
  { label: '已付款', value: 'paid' },
  { label: '部分退款', value: 'partiallyRefunded' },
  { label: '已退款', value: 'refunded' },
]

const paymentOptions = [
  { label: '現金', value: 'cash' },
  { label: '信用卡', value: 'card' },
  { label: 'Line Pay', value: 'linepay' },
  { label: '悠遊卡', value: 'easycard' },
]

const columns = [
  { title: '訂單編號', key: 'order_no', width: 180 },
  { title: '交易時間', key: 'time', width: 160 },
  { title: '門店', key: 'store', width: 120 },
  { title: '金額', key: 'total', width: 110 },
  { title: '淨額', key: 'net', width: 110 },
  { title: '狀態', key: 'status', width: 100 },
  { title: '付款', key: 'payment', width: 120 },
  { title: '會員', key: 'member', width: 100 },
  { title: '來源', key: 'source', width: 90 },
  { title: '操作', key: 'actions', width: 80 },
]

const pagination = computed(() => ({
  current: page.value,
  pageSize: pageSize.value,
  total: total.value,
  showSizeChanger: true,
  showTotal: (t: number) => `共 ${t} 筆`,
}))

function formatTime(iso: string | null) {
  if (!iso) return '—'
  return dayjs(iso).format('YYYY/MM/DD HH:mm')
}

function statusColor(s: string) {
  if (s === 'paid') return 'green'
  if (s === 'partiallyRefunded') return 'orange'
  if (s === 'refunded') return 'red'
  return 'default'
}

function statusLabel(s: string) {
  return (
    { paid: '已付款', partiallyRefunded: '部分退款', refunded: '已退款' } as Record<string, string>
  )[s] || s
}

function paymentLabel(m: string) {
  return (
    { cash: '現金', card: '信用卡', linepay: 'Line Pay', easycard: '悠遊卡' } as Record<string, string>
  )[m] || m
}

function goDetail(id: string) {
  router.push({ name: 'order-detail', params: { id } })
}

function queryParams() {
  const params: Record<string, string | number> = {
    offset: (page.value - 1) * pageSize.value,
    limit: pageSize.value,
  }
  if (dateRange.value?.[0]) params.since = dateRange.value[0].startOf('day').toISOString()
  if (dateRange.value?.[1]) params.until = dateRange.value[1].endOf('day').toISOString()
  if (storeFilter.value) params.store_id = storeFilter.value
  if (statusFilter.value) params.status = statusFilter.value
  if (paymentFilter.value) params.payment_method = paymentFilter.value
  if (keyword.value.trim()) params.q = keyword.value.trim()
  return params
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listOrders(queryParams())
    orders.value = data.items
    total.value = data.total
  } finally {
    loading.value = false
  }
}

async function handleExport() {
  exporting.value = true
  try {
    const res = await exportOrdersCsv({
      since: dateRange.value?.[0]?.startOf('day').toISOString(),
      until: dateRange.value?.[1]?.endOf('day').toISOString(),
      store_id: storeFilter.value,
      status: statusFilter.value,
      payment_method: paymentFilter.value,
      q: keyword.value.trim() || undefined,
    })
    const url = URL.createObjectURL(res.data)
    const a = document.createElement('a')
    a.href = url
    a.download = 'orders-export.csv'
    a.click()
    URL.revokeObjectURL(url)
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '匯出失敗')
  } finally {
    exporting.value = false
  }
}

function onFilterChange() {
  page.value = 1
  fetchData()
}

function onTableChange(pag: { current?: number; pageSize?: number }) {
  page.value = pag.current ?? 1
  pageSize.value = pag.pageSize ?? 20
  fetchData()
}

onMounted(async () => {
  dateRange.value = [dayjs().startOf('day'), dayjs().endOf('day')]
  try {
    const { data } = await listStores()
    stores.value = data
  } catch {
    /* best-effort */
  }
  fetchData()
})
</script>
