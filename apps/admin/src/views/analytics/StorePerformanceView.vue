<template>
  <div>
    <a-page-header title="門店績效">
      <template #extra>
        <a-space>
          <a-range-picker v-model:value="dateRange" :presets="datePresets" format="YYYY/MM/DD" @change="loadData" />
          <a-switch v-model:checked="comparePrior" checked-children="成長率" un-checked-children="成長率" @change="loadData" />
        </a-space>
      </template>
    </a-page-header>

    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 16px">
        <a-col :span="24">
          <a-card title="門店地圖（氣泡大小 = 營收）">
            <v-chart :option="mapOption" autoresize style="height: 360px" />
            <a-typography-text type="secondary">需先於門店管理設定地址並執行地理編碼</a-typography-text>
          </a-card>
        </a-col>
      </a-row>

      <a-card title="門店排行">
        <a-table :columns="columns" :data-source="rows" row-key="store_id" :pagination="false">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'revenue'">{{ formatMoney(record.revenue_cents) }}</template>
            <template v-if="column.key === 'net'">{{ formatMoney(record.net_cents) }}</template>
            <template v-if="column.key === 'avg'">{{ formatMoney(record.avg_order_cents) }}</template>
            <template v-if="column.key === 'refund_rate'">{{ record.refund_rate }}%</template>
            <template v-if="column.key === 'growth'">
              <span v-if="record.growth_pct == null">—</span>
              <span v-else :style="{ color: record.growth_pct >= 0 ? '#3f8600' : '#cf1322' }">
                {{ record.growth_pct >= 0 ? '+' : '' }}{{ record.growth_pct }}%
              </span>
            </template>
          </template>
        </a-table>
      </a-card>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import dayjs, { type Dayjs } from 'dayjs'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { ScatterChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { getStoreComparison, type StoreComparisonRow } from '@/api/analytics'
import { formatMoney } from '@/utils/formatMoney'

use([CanvasRenderer, ScatterChart, GridComponent, TooltipComponent])

const loading = ref(false)
const rows = ref<StoreComparisonRow[]>([])
const dateRange = ref<[Dayjs, Dayjs]>([dayjs().subtract(29, 'day').startOf('day'), dayjs().endOf('day')])
const comparePrior = ref(true)

const datePresets = [
  { label: '近 30 天', value: [dayjs().subtract(29, 'day').startOf('day'), dayjs().endOf('day')] },
  { label: '本月', value: [dayjs().startOf('month'), dayjs().endOf('day')] },
]

const columns = [
  { title: '門店', dataIndex: 'store_name' },
  { title: '代碼', dataIndex: 'store_code', width: 100 },
  { title: '營收', key: 'revenue', width: 120 },
  { title: '淨營收', key: 'net', width: 120 },
  { title: '訂單數', dataIndex: 'order_count', width: 90 },
  { title: '客單價', key: 'avg', width: 110 },
  { title: '退款率', key: 'refund_rate', width: 90 },
  { title: '成長率', key: 'growth', width: 90 },
]

const mapOption = computed(() => {
  const withCoords = rows.value.filter((r) => r.latitude != null && r.longitude != null)
  const maxRev = Math.max(...withCoords.map((r) => r.revenue_cents), 1)
  return {
    tooltip: {
      formatter: (p: any) => {
        const d = p.data
        return `${d[3]}<br/>營收 ${formatMoney(d[2])}`
      },
    },
    xAxis: { type: 'value', name: '經度', scale: true },
    yAxis: { type: 'value', name: '緯度', scale: true },
    series: [{
      type: 'scatter',
      symbolSize: (val: number[]) => Math.max(12, (val[2] / maxRev) * 60),
      data: withCoords.map((r) => [r.longitude, r.latitude, r.revenue_cents, r.store_name]),
    }],
  }
})

async function loadData() {
  loading.value = true
  try {
    const { data } = await getStoreComparison({
      since: dateRange.value[0].startOf('day').toISOString(),
      until: dateRange.value[1].endOf('day').toISOString(),
      compare_prior: comparePrior.value,
    })
    rows.value = data
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>
