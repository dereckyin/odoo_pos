<template>
  <div>
    <a-page-header title="促銷活動">
      <template #extra>
        <a-button type="primary" @click="$router.push({ name: 'promotion-create' })">新增活動</a-button>
      </template>
    </a-page-header>

    <a-space style="margin-bottom: 16px">
      <a-select v-model:value="statusFilter" placeholder="狀態篩選" style="width: 160px" allow-clear @change="fetchData">
        <a-select-option value="active">進行中</a-select-option>
        <a-select-option value="scheduled">排程中</a-select-option>
        <a-select-option value="expired">已結束</a-select-option>
      </a-select>
    </a-space>

    <a-table :columns="columns" :data-source="promotions" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'strategy'">
          <a-tag>{{ strategyLabel[record.strategy] || record.strategy }}</a-tag>
        </template>
        <template v-if="column.key === 'period'">
          <span v-if="record.starts_at || record.ends_at">
            {{ record.starts_at ? dayjs(record.starts_at).format('YYYY-MM-DD') : '...' }}
            ~
            {{ record.ends_at ? dayjs(record.ends_at).format('YYYY-MM-DD') : '...' }}
          </span>
          <span v-else style="color: #ccc">無限期</span>
        </template>
        <template v-if="column.key === 'status'">
          <a-tag :color="getStatusColor(record)">{{ getStatusText(record) }}</a-tag>
        </template>
        <template v-if="column.key === 'is_active'">
          <a-switch :checked="record.is_active" size="small" @change="(v: boolean) => toggleActive(record, v)" />
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="$router.push({ name: 'promotion-edit', params: { id: record.id } })">編輯</a-button>
            <a-popconfirm title="確定刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import dayjs from 'dayjs'
import { message } from 'ant-design-vue'
import { listPromotions, deletePromotion, updatePromotion } from '@/api/promotions'
import type { PromotionRead } from '@/types'

const promotions = ref<PromotionRead[]>([])
const loading = ref(false)
const statusFilter = ref<string | undefined>()

const strategyLabel: Record<string, string> = {
  thresholdAmountOff: '滿額折',
  thresholdPercentOff: '滿額折%',
  nthItemDiscount: '第N件折',
  buyXGetY: '買X送Y',
  bundlePrice: '組合價',
}

const columns = [
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '策略', key: 'strategy', width: 120 },
  { title: '期間', key: 'period', width: 240 },
  { title: '優先', dataIndex: 'priority', key: 'priority', width: 70, sorter: (a: PromotionRead, b: PromotionRead) => b.priority - a.priority },
  { title: '狀態', key: 'status', width: 100 },
  { title: '啟用', key: 'is_active', width: 70 },
  { title: '操作', key: 'actions', width: 140 },
]

function getStatusText(r: PromotionRead) {
  if (!r.is_active) return '停用'
  const now = dayjs()
  if (r.starts_at && dayjs(r.starts_at).isAfter(now)) return '排程中'
  if (r.ends_at && dayjs(r.ends_at).isBefore(now)) return '已結束'
  return '進行中'
}

function getStatusColor(r: PromotionRead) {
  const s = getStatusText(r)
  if (s === '進行中') return 'green'
  if (s === '排程中') return 'blue'
  if (s === '已結束') return 'default'
  return 'default'
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listPromotions({ status: statusFilter.value })
    promotions.value = data
  } finally {
    loading.value = false
  }
}

async function toggleActive(record: PromotionRead, val: boolean) {
  await updatePromotion(record.id, { is_active: val })
  message.success(val ? '已啟用' : '已停用')
  fetchData()
}

async function handleDelete(id: string) {
  await deletePromotion(id)
  message.success('已刪除')
  fetchData()
}

onMounted(fetchData)
</script>
