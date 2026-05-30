<template>
  <div>
    <a-page-header title="銷售分析">
      <template #extra>
        <a-space>
          <a-segmented v-model:value="rangeDays" :options="rangeOptions" @change="loadAll" />
          <a-select
            v-if="storeOptions.length > 1"
            v-model:value="storeId"
            style="width: 200px"
            placeholder="全部門店"
            allow-clear
            :options="storeOptions"
            @change="loadAll"
          />
        </a-space>
      </template>
    </a-page-header>

    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 16px">
        <a-col :span="24">
          <a-card title="經營洞察">
            <a-list v-if="insights.length" :data-source="insights" size="small">
              <template #renderItem="{ item }">
                <a-list-item>{{ item.text }}</a-list-item>
              </template>
            </a-list>
            <a-empty v-else description="尚無洞察" />
          </a-card>
        </a-col>
      </a-row>

      <a-row :gutter="16">
        <a-col :span="12">
          <a-card title="品類營收占比">
            <v-chart :option="categoryOption" autoresize style="height: 320px" />
          </a-card>
        </a-col>
        <a-col :span="12">
          <a-card title="客單價分布">
            <v-chart :option="aovOption" autoresize style="height: 320px" />
          </a-card>
        </a-col>
      </a-row>

      <a-row :gutter="16" style="margin-top: 16px">
        <a-col :span="12">
          <a-card title="星期模式">
            <v-chart :option="weekdayOption" autoresize style="height: 280px" />
          </a-card>
        </a-col>
        <a-col :span="12">
          <a-card title="熱門加購選項">
            <a-table :columns="addonColumns" :data-source="addons" row-key="choice_name" size="small" :pagination="false" />
          </a-card>
        </a-col>
      </a-row>

      <a-row :gutter="16" style="margin-top: 16px">
        <a-col :span="8">
          <a-statistic title="折扣總額" :value="discountStats?.total_discount_cents ?? 0" :formatter="statMoney" />
        </a-col>
        <a-col :span="8">
          <a-statistic title="有折扣訂單" :value="discountStats?.discounted_orders ?? 0" suffix="筆" />
        </a-col>
        <a-col :span="8">
          <a-statistic title="折扣占銷售比" :value="discountStats?.discount_rate_pct ?? 0" suffix="%" :precision="1" />
        </a-col>
      </a-row>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import dayjs from 'dayjs'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { PieChart, BarChart, LineChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'
import { listStores } from '@/api/stores'
import { getCategoryMix, getDailySeries, type CategoryMixItem } from '@/api/reports'
import {
  getAovDistribution,
  getDiscountStats,
  getTopAddons,
  getWeekdayPattern,
  getAnalyticsInsights,
  type AovBucket,
  type DiscountStats,
  type AddonStat,
  type WeekdayPattern,
  type InsightItem,
} from '@/api/analytics'
import { statMoneyFormatter } from '@/utils/formatMoney'
import type { StoreRead } from '@/types'

use([CanvasRenderer, PieChart, BarChart, LineChart, GridComponent, TooltipComponent, LegendComponent])

const loading = ref(false)
const rangeDays = ref(30)
const storeId = ref<string | undefined>()
const stores = ref<StoreRead[]>([])
const categories = ref<CategoryMixItem[]>([])
const aov = ref<AovBucket[]>([])
const weekday = ref<WeekdayPattern[]>([])
const addons = ref<AddonStat[]>([])
const discountStats = ref<DiscountStats | null>(null)
const insights = ref<InsightItem[]>([])
const trend = ref<{ date: string; revenue: number }[]>([])

const rangeOptions = [
  { label: '7 天', value: 7 },
  { label: '30 天', value: 30 },
  { label: '90 天', value: 90 },
]

const storeOptions = computed(() =>
  stores.value.map((s) => ({ label: `${s.code} ${s.name}`, value: s.id })),
)

const addonColumns = [
  { title: '選項', dataIndex: 'choice_name' },
  { title: '次數', dataIndex: 'count', width: 80 },
  { title: '加價營收', key: 'rev', width: 120 },
]

const statMoney = statMoneyFormatter

function queryParams() {
  const since = dayjs().subtract(rangeDays.value - 1, 'day').startOf('day').toISOString()
  const until = dayjs().endOf('day').toISOString()
  return { since, until, store_id: storeId.value, compare_prior: true }
}

async function loadAll() {
  loading.value = true
  try {
    const params = queryParams()
    const [cat, a, wd, ad, ds, ins, daily] = await Promise.all([
      getCategoryMix(params),
      getAovDistribution(params),
      getWeekdayPattern(params),
      getTopAddons(params),
      getDiscountStats(params),
      getAnalyticsInsights(params),
      getDailySeries(params),
    ])
    categories.value = cat.data
    aov.value = a.data
    weekday.value = wd.data
    addons.value = ad.data
    discountStats.value = ds.data
    insights.value = ins.data
    trend.value = daily.data.map((d) => ({ date: d.date, revenue: d.revenue_cents / 100 }))
  } finally {
    loading.value = false
  }
}

const categoryOption = computed(() => ({
  tooltip: { trigger: 'item' },
  series: [{
    type: 'pie',
    radius: '60%',
    data: categories.value.map((c) => ({ name: c.category_name, value: c.revenue_cents / 100 })),
  }],
}))

const aovOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: aov.value.map((b) => b.label) },
  yAxis: { type: 'value' },
  series: [{ type: 'bar', data: aov.value.map((b) => b.count) }],
}))

const weekdayOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: weekday.value.map((w) => w.weekday_label) },
  yAxis: { type: 'value' },
  series: [{ type: 'line', smooth: true, data: weekday.value.map((w) => w.revenue_cents / 100) }],
}))

onMounted(async () => {
  try {
    const { data } = await listStores()
    stores.value = data
  } catch { /* */ }
  loadAll()
})
</script>
