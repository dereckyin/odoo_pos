<template>
  <div>
    <a-page-header title="銷售報表">
      <template #extra>
        <a-space wrap>
          <a-range-picker v-model:value="dateRange" :presets="datePresets" format="YYYY/MM/DD" @change="loadAll" />
          <a-select
            v-if="storeOptions.length > 1"
            v-model:value="storeId"
            style="width: 200px"
            placeholder="全部門店"
            allow-clear
            :options="storeOptions"
            @change="loadAll"
          />
          <a-switch v-model:checked="comparePrior" checked-children="同期比較" un-checked-children="同期比較" @change="loadAll" />
        </a-space>
      </template>
    </a-page-header>

    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 24px">
        <a-col :span="4">
          <a-card><a-statistic title="總營收" :value="summary?.total_revenue_cents ?? 0" :formatter="statMoney" /></a-card>
        </a-col>
        <a-col :span="4">
          <a-card><a-statistic title="淨營收" :value="summary?.net_revenue_cents ?? 0" :formatter="statMoney" /></a-card>
        </a-col>
        <a-col :span="4">
          <a-card><a-statistic title="訂單數" :value="summary?.total_orders ?? 0" /></a-card>
        </a-col>
        <a-col :span="4">
          <a-card><a-statistic title="平均客單價" :value="summary?.avg_order_cents ?? 0" :formatter="statMoney" /></a-card>
        </a-col>
        <a-col :span="4">
          <a-card>
            <a-statistic title="退款率" :value="summary?.refund_rate ?? 0" suffix="%" :precision="1" />
          </a-card>
        </a-col>
        <a-col :span="4">
          <a-card>
            <a-statistic title="QR 占比" :value="summary?.qr_ratio ?? 0" suffix="%" :precision="1" />
          </a-card>
        </a-col>
      </a-row>

      <a-alert
        v-if="summary?.revenue_change_pct != null"
        :message="`與上期相比營收 ${summary.revenue_change_pct >= 0 ? '成長' : '下滑'} ${Math.abs(summary.revenue_change_pct)}%`"
        type="info"
        show-icon
        style="margin-bottom: 16px"
      />

      <a-row :gutter="16">
        <a-col :span="14">
          <a-card title="日營收趨勢">
            <v-chart :option="dailyChartOption" autoresize style="height: 320px" />
          </a-card>
        </a-col>
        <a-col :span="10">
          <a-card title="付款方式">
            <v-chart :option="paymentChartOption" autoresize style="height: 320px" />
          </a-card>
        </a-col>
      </a-row>

      <a-row :gutter="16" style="margin-top: 16px">
        <a-col :span="14">
          <a-card title="時段熱力圖（週 × 小時）">
            <v-chart :option="heatmapOption" autoresize style="height: 360px" />
          </a-card>
        </a-col>
        <a-col :span="10">
          <a-card title="Top 10 商品">
            <v-chart :option="topProductsOption" autoresize style="height: 360px" />
          </a-card>
        </a-col>
      </a-row>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import dayjs, { type Dayjs } from 'dayjs'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, PieChart, BarChart, HeatmapChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  VisualMapComponent,
} from 'echarts/components'
import { listStores } from '@/api/stores'
import {
  getSalesSummary,
  getDailySeries,
  getHourlyHeatmap,
  getPaymentMix,
  getTopProducts,
  type SalesSummary,
  type DailyPoint,
  type HeatmapCell,
  type PaymentMixItem,
  type TopProduct,
} from '@/api/reports'
import { statMoneyFormatter } from '@/utils/formatMoney'
import type { StoreRead } from '@/types'

use([
  CanvasRenderer,
  LineChart,
  PieChart,
  BarChart,
  HeatmapChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  VisualMapComponent,
])

const loading = ref(false)
const summary = ref<SalesSummary | null>(null)
const daily = ref<DailyPoint[]>([])
const heatmap = ref<HeatmapCell[]>([])
const payments = ref<PaymentMixItem[]>([])
const topProducts = ref<TopProduct[]>([])
const stores = ref<StoreRead[]>([])
const dateRange = ref<[Dayjs, Dayjs]>([dayjs().subtract(29, 'day').startOf('day'), dayjs().endOf('day')])
const storeId = ref<string | undefined>()
const comparePrior = ref(true)

const datePresets = [
  { label: '近 7 天', value: [dayjs().subtract(6, 'day').startOf('day'), dayjs().endOf('day')] },
  { label: '近 30 天', value: [dayjs().subtract(29, 'day').startOf('day'), dayjs().endOf('day')] },
  { label: '本月', value: [dayjs().startOf('month'), dayjs().endOf('day')] },
]

const storeOptions = computed(() =>
  stores.value.map((s) => ({ label: `${s.code} ${s.name}`, value: s.id })),
)

const WEEKDAYS = ['週一', '週二', '週三', '週四', '週五', '週六', '週日']

const statMoney = statMoneyFormatter

function queryParams() {
  return {
    since: dateRange.value[0].startOf('day').toISOString(),
    until: dateRange.value[1].endOf('day').toISOString(),
    store_id: storeId.value,
    compare_prior: comparePrior.value,
    limit: 10,
  }
}

async function loadAll() {
  loading.value = true
  try {
    const params = queryParams()
    const [s, d, h, p, t] = await Promise.all([
      getSalesSummary(params),
      getDailySeries(params),
      getHourlyHeatmap(params),
      getPaymentMix(params),
      getTopProducts(params),
    ])
    summary.value = s.data
    daily.value = d.data
    heatmap.value = h.data
    payments.value = p.data
    topProducts.value = t.data
  } finally {
    loading.value = false
  }
}

const dailyChartOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['營收', '淨營收'] },
  xAxis: { type: 'category', data: daily.value.map((d) => d.date) },
  yAxis: { type: 'value' },
  series: [
    { name: '營收', type: 'line', smooth: true, data: daily.value.map((d) => d.revenue_cents / 100) },
    { name: '淨營收', type: 'line', smooth: true, data: daily.value.map((d) => d.net_cents / 100) },
  ],
}))

const paymentChartOption = computed(() => ({
  tooltip: { trigger: 'item' },
  series: [
    {
      type: 'pie',
      radius: '65%',
      data: payments.value.map((p) => ({
        name: p.method,
        value: p.amount_cents / 100,
      })),
    },
  ],
}))

const heatmapOption = computed(() => {
  const hours = Array.from({ length: 24 }, (_, i) => `${i}`)
  const data = heatmap.value.map((c) => [c.hour, c.weekday, c.order_count])
  const max = Math.max(...heatmap.value.map((c) => c.order_count), 1)
  return {
    tooltip: { position: 'top' },
    grid: { height: '70%', top: '10%' },
    xAxis: { type: 'category', data: hours, splitArea: { show: true } },
    yAxis: { type: 'category', data: WEEKDAYS, splitArea: { show: true } },
    visualMap: { min: 0, max, calculable: true, orient: 'horizontal', left: 'center', bottom: '0%' },
    series: [{ type: 'heatmap', data, label: { show: false } }],
  }
})

const topProductsOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  grid: { left: '30%' },
  xAxis: { type: 'value' },
  yAxis: {
    type: 'category',
    data: topProducts.value.map((p) => p.product_name).reverse(),
  },
  series: [
    {
      type: 'bar',
      data: topProducts.value.map((p) => p.total_revenue_cents / 100).reverse(),
    },
  ],
}))

onMounted(async () => {
  try {
    const { data } = await listStores()
    stores.value = data
  } catch {
    /* best-effort */
  }
  loadAll()
})
</script>
