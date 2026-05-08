<template>
  <div>
    <a-page-header title="桌邊訂單監控">
      <template #extra>
        <a-space>
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
                  <span v-if="item.note">備註：{{ item.note }}・</span>
                  <span>單價 ${{ (item.unit_price_cents / 100).toFixed(0) }}・小計 ${{
                    (item.line_total_cents / 100).toFixed(0)
                  }}</span>
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
        <template v-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-if="column.key === 'estimated_subtotal_cents'">
          ${{ (record.estimated_subtotal_cents / 100).toFixed(0) }}
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
import dayjs from 'dayjs'
import { listGuestOrders } from '@/api/tables'
import { listStores } from '@/api/stores'
import type { GuestOrderRead, StoreRead } from '@/types'

const orders = ref<GuestOrderRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const storeFilter = ref<string | undefined>(undefined)
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

const columns = [
  { title: '桌號', dataIndex: 'table_label', width: 100 },
  { title: '狀態', key: 'status', width: 100 },
  { title: '人數', dataIndex: 'party_size', width: 80 },
  { title: '估計金額', key: 'estimated_subtotal_cents', width: 120 },
  { title: '送出時間', key: 'created_at', width: 180 },
  { title: 'guest order id', dataIndex: 'id' },
]

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
