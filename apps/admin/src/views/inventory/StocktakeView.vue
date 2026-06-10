<template>
  <div>
    <a-page-header title="盤點" sub-title="清點實際庫存，差異會自動產生庫存調整異動" />

    <a-space style="margin-bottom: 16px" wrap>
      <span>門店</span>
      <a-select v-model:value="storeId" style="width: 220px" placeholder="選擇門店" @change="loadLevels">
        <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
      </a-select>
      <a-input v-model:value="filter" placeholder="搜尋商品名稱 / SKU" allow-clear style="width: 240px" />
      <a-button type="primary" :disabled="!storeId || !hasCounts" :loading="saving" @click="submit">
        送出盤點
      </a-button>
    </a-space>

    <a-table
      :columns="columns"
      :data-source="filteredRows"
      :loading="loading"
      row-key="product_id"
      size="middle"
      :pagination="{ pageSize: 50 }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'expected'">
          {{ record.expected_qty }}
        </template>
        <template v-else-if="column.key === 'actual'">
          <a-input-number v-model:value="record.actual_qty" :min="0" style="width: 120px" />
        </template>
        <template v-else-if="column.key === 'diff'">
          <span :style="{ color: diff(record) === 0 ? 'inherit' : diff(record) > 0 ? '#52c41a' : '#f5222d' }">
            {{ diff(record) > 0 ? '+' : '' }}{{ diff(record) }}
          </span>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listInventoryLevels, createStocktake } from '@/api/inventory'
import { listStores } from '@/api/stores'
import type { InventoryLevelRead, StoreRead } from '@/types'

interface Row {
  product_id: string
  product_name: string
  product_sku: string
  expected_qty: number
  actual_qty: number | null
}

const stores = ref<StoreRead[]>([])
const storeId = ref<string | undefined>(undefined)
const rows = ref<Row[]>([])
const loading = ref(false)
const saving = ref(false)
const filter = ref('')

const columns = [
  { title: '商品', dataIndex: 'product_name', key: 'product_name' },
  { title: 'SKU', dataIndex: 'product_sku', key: 'product_sku', width: 160 },
  { title: '系統庫存', key: 'expected', width: 110 },
  { title: '實際盤點', key: 'actual', width: 150 },
  { title: '差異', key: 'diff', width: 100 },
]

const filteredRows = computed(() => {
  const q = filter.value.trim().toLowerCase()
  if (!q) return rows.value
  return rows.value.filter(
    (r) =>
      (r.product_name || '').toLowerCase().includes(q) ||
      (r.product_sku || '').toLowerCase().includes(q),
  )
})

const hasCounts = computed(() => rows.value.some((r) => r.actual_qty !== null))

function diff(r: Row) {
  return (r.actual_qty ?? r.expected_qty) - r.expected_qty
}

async function loadLevels() {
  if (!storeId.value) return
  loading.value = true
  try {
    const { data } = await listInventoryLevels({ store_id: storeId.value })
    rows.value = data.map((l: InventoryLevelRead) => ({
      product_id: l.product_id,
      product_name: l.product_name || l.product_id,
      product_sku: l.product_sku || '',
      expected_qty: Number(l.on_hand),
      actual_qty: null,
    }))
  } finally {
    loading.value = false
  }
}

async function submit() {
  if (!storeId.value) return
  const counted = rows.value.filter((r) => r.actual_qty !== null)
  if (!counted.length) {
    message.warning('請至少輸入一筆實際盤點數量')
    return
  }
  saving.value = true
  try {
    await createStocktake({
      id: crypto.randomUUID(),
      store_id: storeId.value,
      lines: counted.map((r) => ({
        id: crypto.randomUUID(),
        product_id: r.product_id,
        expected_qty: r.expected_qty,
        actual_qty: r.actual_qty as number,
      })),
    })
    message.success('盤點已完成，差異已調整庫存')
    loadLevels()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '送出失敗')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const { data } = await listStores()
  stores.value = data
  if (stores.value.length === 1) {
    storeId.value = stores.value[0].id
    loadLevels()
  }
})
</script>
