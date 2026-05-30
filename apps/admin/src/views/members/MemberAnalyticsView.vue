<template>
  <div>
    <a-page-header title="會員分析" />

    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :span="6"><a-statistic title="總會員" :value="overview?.total_members ?? 0" /></a-col>
        <a-col :span="6"><a-statistic title="30日新增" :value="overview?.new_members_30d ?? 0" /></a-col>
        <a-col :span="6"><a-statistic title="30日活躍" :value="overview?.active_30d ?? 0" /></a-col>
        <a-col :span="6"><a-statistic title="90日沉睡" :value="overview?.dormant_90d ?? 0" /></a-col>
      </a-row>
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :span="8"><a-statistic title="會員營收占比" :value="overview?.member_revenue_pct ?? 0" suffix="%" /></a-col>
        <a-col :span="8"><a-statistic title="會員訂單數" :value="overview?.member_order_count ?? 0" /></a-col>
        <a-col :span="8"><a-statistic title="總訂單數" :value="overview?.total_order_count ?? 0" /></a-col>
      </a-row>

      <a-card title="等級分布" style="margin-bottom: 24px">
        <a-table :columns="levelColumns" :data-source="levelStats" row-key="level_id" size="small" :pagination="false">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'spent'">{{ formatMoney(record.total_spent_cents) }}</template>
            <template v-if="column.key === 'avg'">{{ formatMoney(record.avg_spent_cents) }}</template>
          </template>
        </a-table>
      </a-card>

      <a-card title="RFM 九宮格 (Pro)" style="margin-bottom: 24px">
        <a-alert v-if="rfmError" type="warning" :message="rfmError" show-icon style="margin-bottom: 12px" />
        <a-table v-else :columns="rfmColumns" :data-source="rfm" row-key="key" size="small" :pagination="false">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'key'">{{ record.recency_bucket }} / {{ record.frequency_bucket }}</template>
            <template v-if="column.key === 'rev'">{{ formatMoney(record.revenue_cents) }}</template>
          </template>
        </a-table>
      </a-card>

      <a-card title="流失風險名單 (90天未消費)">
        <a-table :columns="churnColumns" :data-source="churn" row-key="member_id" size="small">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'spent'">{{ formatMoney(record.total_spent_cents) }}</template>
            <template v-if="column.key === 'actions'">
              <a-button size="small" @click="$router.push({ name: 'member-detail', params: { id: record.member_id } })">查看</a-button>
            </template>
          </template>
        </a-table>
      </a-card>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  getMemberOverview, getMemberLevelStats, getMemberRfm, getChurnRisk,
} from '@/api/memberAnalytics'
import { formatMoney } from '@/utils/formatMoney'
import type { MemberOverview, LevelStat, RfmCell, ChurnMember } from '@/types'

const loading = ref(false)
const overview = ref<MemberOverview | null>(null)
const levelStats = ref<LevelStat[]>([])
const rfm = ref<(RfmCell & { key: string })[]>([])
const churn = ref<ChurnMember[]>([])
const rfmError = ref('')

const levelColumns = [
  { title: '等級', dataIndex: 'level_name' },
  { title: '人數', dataIndex: 'count' },
  { title: '總消費', key: 'spent' },
  { title: '人均', key: 'avg' },
]

const rfmColumns = [
  { title: '分群', key: 'key' },
  { title: '人數', dataIndex: 'count' },
  { title: '營收', key: 'rev' },
]

const churnColumns = [
  { title: '姓名', dataIndex: 'name' },
  { title: '電話', dataIndex: 'phone' },
  { title: '累計消費', key: 'spent' },
  { title: '點數', dataIndex: 'points' },
  { title: '操作', key: 'actions', width: 80 },
]

onMounted(async () => {
  loading.value = true
  try {
    const [o, l, c] = await Promise.all([
      getMemberOverview(),
      getMemberLevelStats(),
      getChurnRisk(30),
    ])
    overview.value = o.data
    levelStats.value = l.data
    churn.value = c.data
    try {
      const r = await getMemberRfm()
      rfm.value = r.data.map(x => ({ ...x, key: `${x.recency_bucket}-${x.frequency_bucket}` }))
    } catch (e: any) {
      rfmError.value = e.response?.data?.detail || '需 Pro 方案才能使用 RFM 分析'
    }
  } finally {
    loading.value = false
  }
})
</script>
