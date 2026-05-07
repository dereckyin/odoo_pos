<template>
  <div>
    <a-page-header title="總覽" sub-title="快速查看系統狀態" />
    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :span="6">
          <a-card>
            <a-statistic title="商品數" :value="stats.products" />
          </a-card>
        </a-col>
        <a-col :span="6">
          <a-card>
            <a-statistic title="進行中活動" :value="stats.active_promotions" />
          </a-card>
        </a-col>
        <a-col :span="6">
          <a-card>
            <a-statistic title="會員數" :value="stats.members" />
          </a-card>
        </a-col>
        <a-col :span="6">
          <a-card>
            <a-statistic title="今日訂單" :value="stats.today_orders" />
          </a-card>
        </a-col>
      </a-row>
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :span="6">
          <a-card>
            <a-statistic title="今日營收" :value="stats.today_revenue_cents / 100" prefix="$" :precision="0" />
          </a-card>
        </a-col>
      </a-row>
    </a-spin>
    <a-row :gutter="16">
      <a-col :span="12">
        <a-card title="快速操作">
          <a-space wrap>
            <a-button type="primary" @click="$router.push({ name: 'product-create' })">新增商品</a-button>
            <a-button @click="$router.push({ name: 'promotion-create' })">新增促銷</a-button>
            <a-button @click="$router.push({ name: 'coupon-create' })">新增優惠券</a-button>
            <a-button @click="$router.push({ name: 'orders' })">訂單查詢</a-button>
          </a-space>
        </a-card>
      </a-col>
      <a-col :span="12">
        <a-card title="系統資訊">
          <a-descriptions :column="1" bordered size="small">
            <a-descriptions-item label="登入帳號">{{ auth.username }}</a-descriptions-item>
            <a-descriptions-item label="角色">{{ auth.role }}</a-descriptions-item>
          </a-descriptions>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { getDashboardStats, type DashboardStats } from '@/api/dashboard'

const auth = useAuthStore()
const loading = ref(false)
const stats = reactive<DashboardStats>({
  products: 0,
  active_promotions: 0,
  members: 0,
  today_orders: 0,
  today_revenue_cents: 0,
})

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getDashboardStats()
    Object.assign(stats, data)
  } catch {
    // best-effort
  } finally {
    loading.value = false
  }
})
</script>
