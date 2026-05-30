<template>
  <div>
    <a-page-header title="市集上架審核" sub-title="平台超管專用" :back-icon="false">
      <template #extra>
        <a-radio-group v-model:value="statusFilter" button-style="solid" @change="reload">
          <a-radio-button value="pending">待審核</a-radio-button>
          <a-radio-button value="approved">已上架</a-radio-button>
          <a-radio-button value="suspended">已下架</a-radio-button>
        </a-radio-group>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="rows" :loading="loading" row-key="id" size="middle">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'status'">
          <a-tag>{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-else-if="column.key === 'modes'">
          <a-space>
            <a-tag v-if="record.supports_pickup">外帶</a-tag>
            <a-tag v-if="record.supports_delivery">外送</a-tag>
            <a-tag v-if="record.supports_dine_in">內用</a-tag>
          </a-space>
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space>
            <a-button
              v-if="record.status === 'pending'"
              type="primary"
              size="small"
              @click="approve(record.id)"
            >
              核准上架
            </a-button>
            <a-button
              v-if="record.status === 'approved'"
              danger
              size="small"
              @click="suspend(record.id)"
            >
              下架
            </a-button>
          </a-space>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { message } from 'ant-design-vue'
import * as platformApi from '@/api/platform'
import type { MarketplaceListing } from '@/api/marketplace'

const loading = ref(false)
const statusFilter = ref('pending')
const rows = ref<MarketplaceListing[]>([])

const columns = [
  { title: '店名', dataIndex: 'display_name', key: 'name' },
  { title: 'Slug', dataIndex: 'slug', key: 'slug' },
  { title: '狀態', key: 'status' },
  { title: '取餐方式', key: 'modes' },
  { title: '提交時間', dataIndex: 'submitted_at', key: 'submitted_at' },
  { title: '操作', key: 'actions', width: 160 },
]

function statusLabel(s: string) {
  const map: Record<string, string> = {
    draft: '草稿',
    pending: '待審核',
    approved: '已上架',
    suspended: '已下架',
  }
  return map[s] ?? s
}

async function reload() {
  loading.value = true
  try {
    const { data } = await platformApi.listMarketplaceApplications(statusFilter.value)
    rows.value = data
  } finally {
    loading.value = false
  }
}

async function approve(id: string) {
  await platformApi.approveMarketplaceListing(id)
  message.success('已核准')
  reload()
}

async function suspend(id: string) {
  await platformApi.suspendMarketplaceListing(id)
  message.success('已下架')
  reload()
}

onMounted(reload)
</script>
