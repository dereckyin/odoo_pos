<template>
  <div>
    <a-page-header title="寄賣書籍" sub-title="書籍主檔與庫存" />
    <a-space style="margin-bottom: 16px" wrap>
      <a-input-search v-model:value="query" placeholder="書名 / 作者 / 條碼" style="width: 280px" @search="load" />
      <a-select
        v-model:value="storeId"
        allow-clear
        placeholder="全部門店加總"
        style="width: 200px"
        :options="storeOptions"
        @change="load"
      />
      <a-range-picker v-model:value="exportRange" :allow-clear="true" />
      <a-button :loading="exporting" @click="handleExport">匯出區間列表</a-button>
      <a-button @click="$router.push({ name: 'book-receive' })">寄賣入庫</a-button>
    </a-space>
    <a-table :columns="columns" :data-source="rows" :loading="loading" row-key="id" :pagination="{ pageSize: 30 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'list_price'">
          {{ formatMoney(record.list_price_cents) }}
        </template>
        <template v-else-if="column.key === 'sale_price'">
          {{ formatMoney(record.price_cents) }}
        </template>
        <template v-else-if="column.key === 'sale_disc'">
          {{ formatSaleDisc(record.sale_disc) }}
        </template>
        <template v-else-if="column.key === 'on_hand'">
          {{ formatOnHand(record.on_hand) }}
        </template>
        <template v-else-if="column.key === 'last_received_at'">
          {{ formatRecvDate(record.last_received_at) }}
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import type { Dayjs } from 'dayjs'
import { exportBooksCsv, listBooks } from '@/api/books'
import type { BookProduct } from '@/api/books'
import { listStores } from '@/api/stores'
import { formatMoney } from '@/utils/formatMoney'

const rows = ref<BookProduct[]>([])
const loading = ref(false)
const exporting = ref(false)
const query = ref('')
const storeId = ref<string | undefined>()
const storeOptions = ref<{ label: string; value: string }[]>([])
const exportRange = ref<[Dayjs, Dayjs] | undefined>()

const columns = [
  { title: '書名', dataIndex: 'name' },
  { title: '作者', dataIndex: 'author', width: 120 },
  { title: '條碼', dataIndex: 'sku', width: 140 },
  { title: 'ISBN', dataIndex: 'isbn', width: 150 },
  { title: '牌價', key: 'list_price', width: 72 },
  { title: '售價', key: 'sale_price', width: 72 },
  { title: '折扣', key: 'sale_disc', width: 72 },
  { title: '庫存', key: 'on_hand', width: 72 },
  { title: '進貨日期', key: 'last_received_at', width: 110 },
]

function formatSaleDisc(disc: number | null | undefined) {
  if (disc == null) return '—'
  return `${disc}折`
}

function formatOnHand(qty: number | null | undefined) {
  if (qty == null) return 0
  return Number.isInteger(qty) ? qty : qty.toFixed(1)
}

function formatRecvDate(raw: string | null | undefined) {
  if (!raw) return '—'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return '—'
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

async function load() {
  loading.value = true
  try {
    const { data } = await listBooks({
      q: query.value || undefined,
      store_id: storeId.value,
    })
    rows.value = data
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '載入失敗')
  } finally {
    loading.value = false
  }
}

async function handleExport() {
  if (!exportRange.value || exportRange.value.length !== 2) {
    message.warning('請先選擇進貨日期區間')
    return
  }
  exporting.value = true
  try {
    const [from, to] = exportRange.value
    const res = await exportBooksCsv({
      date_from: from.format('YYYY-MM-DD'),
      date_to: to.format('YYYY-MM-DD'),
      q: query.value || undefined,
      store_id: storeId.value,
    })
    const url = URL.createObjectURL(res.data)
    const a = document.createElement('a')
    a.href = url
    a.download = `books-export-${from.format('YYYY-MM-DD')}_${to.format('YYYY-MM-DD')}.csv`
    a.click()
    URL.revokeObjectURL(url)
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '匯出失敗')
  } finally {
    exporting.value = false
  }
}

onMounted(async () => {
  const { data: stores } = await listStores()
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  await load()
})
</script>
