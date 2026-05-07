<template>
  <div>
    <a-page-header title="優惠券管理">
      <template #extra>
        <a-button type="primary" @click="$router.push({ name: 'coupon-create' })">新增優惠券</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="coupons" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'type'">
          <a-tag>{{ typeLabel[record.type] || record.type }}</a-tag>
        </template>
        <template v-if="column.key === 'value'">
          {{ record.type === 'percentage' ? `${record.value}%` : `$${record.value}` }}
        </template>
        <template v-if="column.key === 'status'">
          <a-tag v-if="record.used_at" color="default">已使用</a-tag>
          <a-tag v-else-if="record.expires_at && dayjs(record.expires_at).isBefore(dayjs())" color="red">已過期</a-tag>
          <a-tag v-else color="green">可使用</a-tag>
        </template>
        <template v-if="column.key === 'expires_at'">
          {{ record.expires_at ? dayjs(record.expires_at).format('YYYY-MM-DD') : '無期限' }}
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import dayjs from 'dayjs'
import { listCoupons } from '@/api/members'
import type { CouponRead } from '@/types'

const coupons = ref<CouponRead[]>([])
const loading = ref(false)

const typeLabel: Record<string, string> = {
  percentage: '百分比折扣',
  amount: '固定金額',
  freeItem: '免費商品',
}

const columns = [
  { title: '代碼', dataIndex: 'code', key: 'code' },
  { title: '類型', key: 'type', width: 120 },
  { title: '面額', key: 'value', width: 100 },
  { title: '最低消費', dataIndex: 'min_spend_cents', key: 'min_spend', width: 100, customRender: ({ text }: { text: number }) => `$${(text / 100).toFixed(0)}` },
  { title: '到期日', key: 'expires_at', width: 120 },
  { title: '狀態', key: 'status', width: 100 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listCoupons()
    coupons.value = data
  } finally {
    loading.value = false
  }
}

onMounted(fetchData)
</script>
