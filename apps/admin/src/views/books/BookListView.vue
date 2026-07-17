<template>
  <div>
    <a-page-header title="寄賣書籍" sub-title="書籍主檔與庫存" />
    <a-space style="margin-bottom: 16px">
      <a-input-search v-model:value="query" placeholder="書名 / 作者 / 條碼" style="width: 280px" @search="load" />
      <a-select
        v-model:value="storeId"
        allow-clear
        placeholder="全部門店加總"
        style="width: 200px"
        :options="storeOptions"
        @change="load"
      />
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
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listBooks } from '@/api/books'
import type { BookProduct } from '@/api/books'
import { listStores } from '@/api/stores'
import { formatMoney } from '@/utils/formatMoney'

const rows = ref<BookProduct[]>([])
const loading = ref(false)
const query = ref('')
const storeId = ref<string | undefined>()
const storeOptions = ref<{ label: string; value: string }[]>([])

const columns = [
  { title: '書名', dataIndex: 'name' },
  { title: '作者', dataIndex: 'author', width: 120 },
  { title: '條碼', dataIndex: 'sku', width: 140 },
  { title: '牌價', key: 'list_price', width: 72 },
  { title: '售價', key: 'sale_price', width: 72 },
  { title: '折扣', key: 'sale_disc', width: 72 },
  { title: '庫存', key: 'on_hand', width: 72 },
]

function formatSaleDisc(disc: number | null | undefined) {
  if (disc == null) return '—'
  return `${disc}折`
}

function formatOnHand(qty: number | null | undefined) {
  if (qty == null) return 0
  return Number.isInteger(qty) ? qty : qty.toFixed(1)
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

onMounted(async () => {
  const { data: stores } = await listStores()
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  await load()
})
</script>
