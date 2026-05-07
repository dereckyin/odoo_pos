<template>
  <div>
    <a-page-header title="庫存水位" />

    <a-space style="margin-bottom: 16px">
      <a-select v-model:value="storeFilter" placeholder="門店篩選" style="width: 200px" allow-clear @change="fetchData">
        <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
      </a-select>
    </a-space>

    <a-table :columns="columns" :data-source="levels" :loading="loading" row-key="id" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'alert'">
          <a-tag v-if="record.on_hand <= record.safety_stock" color="red">低於安全庫存</a-tag>
          <a-tag v-else color="green">正常</a-tag>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { listInventoryLevels } from '@/api/inventory'
import { listStores } from '@/api/stores'
import type { InventoryLevelRead, StoreRead } from '@/types'

const levels = ref<InventoryLevelRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const storeFilter = ref<string | undefined>()

const columns = [
  { title: '門店', dataIndex: 'store_id', width: 200 },
  { title: '商品', dataIndex: 'product_id' },
  { title: '在庫', dataIndex: 'on_hand', width: 100 },
  { title: '安全庫存', dataIndex: 'safety_stock', width: 100 },
  { title: '保留', dataIndex: 'reserved', width: 100 },
  { title: '狀態', key: 'alert', width: 140 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listInventoryLevels({ store_id: storeFilter.value })
    levels.value = data
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  const { data } = await listStores()
  stores.value = data
  fetchData()
})
</script>
