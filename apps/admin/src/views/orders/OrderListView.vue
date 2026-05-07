<template>
  <div>
    <a-page-header title="訂單查詢" />

    <a-table :columns="columns" :data-source="orders" :loading="loading" row-key="id" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'total'">
          ${{ (record.total_cents / 100).toFixed(2) }}
        </template>
        <template v-if="column.key === 'status'">
          <a-tag :color="record.status === 'paid' ? 'green' : 'default'">{{ record.status }}</a-tag>
        </template>
        <template v-if="column.key === 'created_at'">
          {{ record.created_at?.slice(0, 19).replace('T', ' ') }}
        </template>
        <template v-if="column.key === 'actions'">
          <a-button size="small" @click="$router.push({ name: 'order-detail', params: { id: record.id } })">查看</a-button>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { listOrders } from '@/api/orders'
import type { OrderRead } from '@/types'

const orders = ref<OrderRead[]>([])
const loading = ref(false)

const columns = [
  { title: '訂單 ID', dataIndex: 'id', key: 'id', ellipsis: true, width: 200 },
  { title: '金額', key: 'total', width: 120 },
  { title: '狀態', key: 'status', width: 80 },
  { title: '建立時間', key: 'created_at', width: 180 },
  { title: '操作', key: 'actions', width: 80 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listOrders({ limit: 100 })
    orders.value = data
  } finally {
    loading.value = false
  }
}

onMounted(fetchData)
</script>
