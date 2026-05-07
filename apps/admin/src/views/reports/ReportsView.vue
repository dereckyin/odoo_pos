<template>
  <div>
    <a-page-header title="銷售報表" />

    <a-row :gutter="16" style="margin-bottom: 24px">
      <a-col :span="8">
        <a-card>
          <a-statistic title="今日營收" :value="todayRevenue" prefix="$" />
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card>
          <a-statistic title="今日訂單數" :value="todayCount" />
        </a-card>
      </a-col>
      <a-col :span="8">
        <a-card>
          <a-statistic title="平均客單價" :value="avgOrder" prefix="$" />
        </a-card>
      </a-col>
    </a-row>

    <a-card title="近期訂單統計">
      <a-empty v-if="!orders.length" description="尚無訂單資料" />
      <div v-else>
        <p>共 {{ orders.length }} 筆訂單，總營收 ${{ totalRevenue.toFixed(2) }}</p>
      </div>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { listOrders } from '@/api/orders'
import type { OrderRead } from '@/types'

const orders = ref<OrderRead[]>([])

const totalRevenue = computed(() => orders.value.reduce((sum, o) => sum + o.total_cents, 0) / 100)
const todayRevenue = computed(() => {
  const today = new Date().toISOString().slice(0, 10)
  return orders.value
    .filter(o => o.created_at?.slice(0, 10) === today)
    .reduce((sum, o) => sum + o.total_cents, 0) / 100
})
const todayCount = computed(() => {
  const today = new Date().toISOString().slice(0, 10)
  return orders.value.filter(o => o.created_at?.slice(0, 10) === today).length
})
const avgOrder = computed(() => orders.value.length ? totalRevenue.value / orders.value.length : 0)

onMounted(async () => {
  try {
    const { data } = await listOrders({ limit: 500 })
    orders.value = data
  } catch {
    // best-effort
  }
})
</script>
