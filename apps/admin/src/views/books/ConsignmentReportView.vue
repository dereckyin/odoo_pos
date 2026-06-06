<template>
  <div>
    <a-page-header title="寄賣分帳報表" />
    <a-space style="margin-bottom: 16px">
      <a-range-picker v-model:value="range" />
      <a-select
        v-model:value="storeId"
        allow-clear
        placeholder="全部門店"
        style="width: 200px"
        :options="storeOptions"
      />
      <a-button type="primary" @click="load">查詢</a-button>
    </a-space>
    <a-descriptions v-if="report" bordered size="small" :column="2" style="margin-bottom: 16px">
      <a-descriptions-item label="分帳比例">書籍公司 {{ report.book_share_pct }}%</a-descriptions-item>
      <a-descriptions-item label="銷售總額">{{ formatMoney(report.gross_revenue_cents) }}</a-descriptions-item>
      <a-descriptions-item label="退款沖銷">{{ formatMoney(report.refund_cents) }}</a-descriptions-item>
      <a-descriptions-item label="淨成交額">{{ formatMoney(report.total_revenue_cents) }}</a-descriptions-item>
      <a-descriptions-item label="應付書籍公司（淨）">{{ formatMoney(report.total_book_share_cents) }}</a-descriptions-item>
      <a-descriptions-item label="餐廳留存（淨）">{{ formatMoney(report.total_restaurant_share_cents) }}</a-descriptions-item>
    </a-descriptions>
    <a-table
      v-if="report"
      :columns="columns"
      :data-source="report.rows"
      row-key="store_id"
      :pagination="false"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'money'">
          {{ formatMoney(record[column.dataIndex as keyof typeof record] as number) }}
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import dayjs, { type Dayjs } from 'dayjs'
import { message } from 'ant-design-vue'
import { getConsignmentSettlement } from '@/api/books'
import type { ConsignmentSettlementReport } from '@/api/books'
import { listStores } from '@/api/stores'

const range = ref<[Dayjs, Dayjs]>([dayjs().subtract(30, 'day'), dayjs()])
const storeId = ref<string | undefined>()
const report = ref<ConsignmentSettlementReport | null>(null)
const storeOptions = ref<{ label: string; value: string }[]>([])

const columns = [
  { title: '門店', dataIndex: 'store_name' },
  { title: '淨冊數', dataIndex: 'qty', width: 72 },
  { title: '銷售額', dataIndex: 'gross_revenue_cents', key: 'money' },
  { title: '退款', dataIndex: 'refund_cents', key: 'money' },
  { title: '淨成交', dataIndex: 'revenue_cents', key: 'money' },
  { title: '應付書籍公司', dataIndex: 'book_share_cents', key: 'money' },
  { title: '餐廳留存', dataIndex: 'restaurant_share_cents', key: 'money' },
]

function formatMoney(cents: number) {
  return `$${(cents / 100).toLocaleString()}`
}

async function load() {
  try {
    const [since, until] = range.value
    const { data } = await getConsignmentSettlement({
      since: since.startOf('day').toISOString(),
      until: until.endOf('day').toISOString(),
      store_id: storeId.value,
    })
    report.value = data
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '查詢失敗')
  }
}

onMounted(async () => {
  const { data: stores } = await listStores()
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  await load()
})
</script>
