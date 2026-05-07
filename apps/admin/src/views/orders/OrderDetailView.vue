<template>
  <div>
    <a-page-header title="訂單詳情" @back="$router.push({ name: 'orders' })" />

    <a-spin :spinning="loading">
      <a-descriptions bordered :column="2" v-if="order" style="margin-bottom: 24px">
        <a-descriptions-item label="訂單 ID">{{ order.id }}</a-descriptions-item>
        <a-descriptions-item label="狀態">
          <a-tag :color="order.status === 'paid' ? 'green' : 'default'">{{ order.status }}</a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="小計">NT${{ order.subtotal_cents }}</a-descriptions-item>
        <a-descriptions-item label="折扣">NT${{ order.discount_cents }}</a-descriptions-item>
        <a-descriptions-item label="稅額">NT${{ order.tax_cents }}</a-descriptions-item>
        <a-descriptions-item label="總計">NT${{ order.total_cents }}</a-descriptions-item>
        <a-descriptions-item label="已退款">NT${{ order.refunded_cents }}</a-descriptions-item>
        <a-descriptions-item label="建立時間">{{ order.created_at?.slice(0, 19).replace('T', ' ') }}</a-descriptions-item>
      </a-descriptions>

      <a-divider>訂單明細</a-divider>
      <a-table :columns="lineColumns" :data-source="order?.lines || []" row-key="id" size="small" :pagination="false">
        <template #bodyCell="{ column, text }">
          <template v-if="column.key === 'unit_price'">NT${{ text }}</template>
          <template v-if="column.key === 'line_total'">NT${{ text }}</template>
        </template>
      </a-table>

      <a-divider>付款資訊</a-divider>
      <a-table :columns="payColumns" :data-source="order?.payments || []" row-key="id" size="small" :pagination="false">
        <template #bodyCell="{ column, text }">
          <template v-if="column.key === 'amount'">NT${{ text }}</template>
        </template>
      </a-table>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { getOrder } from '@/api/orders'
import type { OrderRead } from '@/types'

const route = useRoute()
const order = ref<OrderRead | null>(null)
const loading = ref(false)

const lineColumns = [
  { title: '商品', dataIndex: 'product_name' },
  { title: 'SKU', dataIndex: 'sku', width: 120 },
  { title: '數量', dataIndex: 'qty', width: 80 },
  { title: '單價', dataIndex: 'unit_price_cents', key: 'unit_price', width: 100 },
  { title: '小計', dataIndex: 'line_total_cents', key: 'line_total', width: 100 },
]

const payColumns = [
  { title: '方式', dataIndex: 'method' },
  { title: '金額', dataIndex: 'amount_cents', key: 'amount', width: 120 },
  { title: '狀態', dataIndex: 'status', width: 100 },
]

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getOrder(route.params.id as string)
    order.value = data
  } finally {
    loading.value = false
  }
})
</script>
