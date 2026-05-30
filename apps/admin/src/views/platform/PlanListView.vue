<template>
  <div>
    <a-page-header title="訂閱方案" sub-title="平台提供的 SaaS 方案（唯讀）" />
    <a-table :columns="columns" :data-source="plans" :loading="loading" row-key="id" :pagination="false" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { listPlans } from '@/api/platform'
import type { SubscriptionPlanRead } from '@/types'

const loading = ref(false)
const plans = ref<SubscriptionPlanRead[]>([])

const columns = [
  { title: '方案代碼', dataIndex: 'code', key: 'code' },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '月費 (NT$)', dataIndex: 'price_cents', key: 'price_cents' },
  { title: '門店上限', dataIndex: 'max_stores', key: 'max_stores' },
  { title: '商品上限', dataIndex: 'max_products', key: 'max_products' },
  { title: '月訂單上限', dataIndex: 'max_orders_per_month', key: 'max_orders_per_month' },
  {
    title: '狀態',
    key: 'is_active',
    customRender: ({ record }: { record: SubscriptionPlanRead }) => (record.is_active ? '啟用' : '停用'),
  },
]

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await listPlans()
    plans.value = data
  } finally {
    loading.value = false
  }
})
</script>
