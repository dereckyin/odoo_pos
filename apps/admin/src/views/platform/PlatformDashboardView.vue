<template>
  <div>
    <a-page-header title="平台營運總覽" sub-title="跨商家待辦與市集 KPI" />
    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card hoverable @click="$router.push({ name: 'platform-applications' })">
            <a-statistic title="待審核申請" :value="stats.pending_applications" />
          </a-card>
        </a-col>
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card hoverable @click="$router.push({ name: 'platform-marketplace' })">
            <a-statistic title="待審核市集" :value="stats.pending_marketplace_listings" />
          </a-card>
        </a-col>
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card hoverable @click="$router.push({ name: 'platform-tenants' })">
            <a-statistic title="營運中租戶" :value="stats.active_tenants" />
          </a-card>
        </a-col>
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card>
            <a-statistic title="停權租戶" :value="stats.suspended_tenants" />
          </a-card>
        </a-col>
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card>
            <a-statistic title="今日市集訂單" :value="stats.marketplace_orders_today" />
          </a-card>
        </a-col>
        <a-col :xs="12" :sm="8" :lg="4">
          <a-card>
            <a-statistic title="今日市集營收" :value="stats.marketplace_revenue_today_cents" prefix="NT$" />
          </a-card>
        </a-col>
      </a-row>
    </a-spin>

    <a-row :gutter="16">
      <a-col :span="24">
        <a-card title="快速操作">
          <a-space wrap>
            <a-button type="primary" @click="$router.push({ name: 'platform-applications' })">審核開店申請</a-button>
            <a-button type="primary" ghost @click="$router.push({ name: 'platform-marketplace' })">審核市集上架</a-button>
            <a-button @click="$router.push({ name: 'platform-tenants' })">管理租戶</a-button>
            <a-button @click="$router.push({ name: 'platform-plans' })">查看訂閱方案</a-button>
            <a-button @click="tenantPickerOpen = true">進入商家後台</a-button>
          </a-space>
        </a-card>
      </a-col>
    </a-row>

    <TenantPickerModal v-model:open="tenantPickerOpen" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { fetchPlatformDashboard, type PlatformDashboardStats } from '@/api/platform'
import TenantPickerModal from '@/components/TenantPickerModal.vue'

const loading = ref(false)
const tenantPickerOpen = ref(false)
const stats = reactive<PlatformDashboardStats>({
  pending_applications: 0,
  pending_marketplace_listings: 0,
  active_tenants: 0,
  suspended_tenants: 0,
  marketplace_orders_today: 0,
  marketplace_revenue_today_cents: 0,
})

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await fetchPlatformDashboard()
    Object.assign(stats, data)
  } finally {
    loading.value = false
  }
})
</script>
