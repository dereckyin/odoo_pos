<template>
  <div>
    <a-page-header title="環境洞察">
      <template #extra>
        <a-space wrap>
          <a-select
            v-model:value="storeId"
            style="width: 240px"
            placeholder="選擇門店"
            :options="storeOptions"
            @change="loadData"
          />
          <a-range-picker v-model:value="dateRange" format="YYYY/MM/DD" @change="loadData" />
          <a-button :loading="geocoding" @click="runGeocode">更新地理座標</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-alert
      message="人流指標以訂單密度（筆/日）作為來客代理估算值，非實際 foot traffic 量測。"
      type="warning"
      show-icon
      style="margin-bottom: 16px"
    />

    <a-spin :spinning="loading">
      <a-row :gutter="16" style="margin-bottom: 16px">
        <a-col :span="8">
          <a-card><a-statistic title="雨天日均營收" :value="weather?.rainy_avg_revenue ?? 0" :formatter="statMoney" /></a-card>
        </a-col>
        <a-col :span="8">
          <a-card><a-statistic title="晴天日均營收" :value="weather?.clear_avg_revenue ?? 0" :formatter="statMoney" /></a-card>
        </a-col>
        <a-col :span="8">
          <a-card>
            <a-statistic
              title="代理來客（晴/雨 筆/日）"
              :value="`${(weather?.clear_avg_orders ?? 0).toFixed(1)} / ${(weather?.rainy_avg_orders ?? 0).toFixed(1)}`"
            />
          </a-card>
        </a-col>
      </a-row>

      <a-card v-if="weather?.insights?.length" title="洞察摘要" style="margin-bottom: 16px">
        <a-list :data-source="weather.insights" size="small">
          <template #renderItem="{ item }">
            <a-list-item>{{ item.text }}</a-list-item>
          </template>
        </a-list>
      </a-card>

      <a-row :gutter="16">
        <a-col :span="14">
          <a-card title="溫度 vs 營收">
            <v-chart :option="scatterOption" autoresize style="height: 360px" />
          </a-card>
        </a-col>
        <a-col :span="10">
          <a-card title="晴雨天訂單量">
            <v-chart :option="rainOption" autoresize style="height: 360px" />
          </a-card>
        </a-col>
      </a-row>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import dayjs, { type Dayjs } from 'dayjs'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { ScatterChart, BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { listStores, geocodeStore } from '@/api/stores'
import { getWeatherCorrelation, type WeatherCorrelation } from '@/api/analytics'
import { statMoneyFormatter } from '@/utils/formatMoney'
import type { StoreRead } from '@/types'

use([CanvasRenderer, ScatterChart, BarChart, GridComponent, TooltipComponent])

const loading = ref(false)
const geocoding = ref(false)
const stores = ref<StoreRead[]>([])
const storeId = ref<string>()
const dateRange = ref<[Dayjs, Dayjs]>([dayjs().subtract(29, 'day').startOf('day'), dayjs().endOf('day')])
const weather = ref<WeatherCorrelation | null>(null)

const storeOptions = computed(() =>
  stores.value.map((s) => ({
    label: `${s.code} ${s.name}${s.latitude ? '' : ' (未定位)'}`,
    value: s.id,
  })),
)

const statMoney = statMoneyFormatter

async function loadData() {
  if (!storeId.value) return
  loading.value = true
  try {
    const { data } = await getWeatherCorrelation({
      store_id: storeId.value,
      since: dateRange.value[0].startOf('day').toISOString(),
      until: dateRange.value[1].endOf('day').toISOString(),
    })
    weather.value = data
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '無法載入環境資料（請先執行地理編碼）')
    weather.value = null
  } finally {
    loading.value = false
  }
}

async function runGeocode() {
  if (!storeId.value) return
  geocoding.value = true
  try {
    await geocodeStore(storeId.value)
    message.success('地理座標已更新')
    const { data } = await listStores()
    stores.value = data
    await loadData()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '地理編碼失敗')
  } finally {
    geocoding.value = false
  }
}

const scatterOption = computed(() => {
  const pts = weather.value?.daily.filter((d) => d.temp_c != null) || []
  return {
    tooltip: { trigger: 'item' },
    xAxis: { type: 'value', name: '溫度 °C' },
    yAxis: { type: 'value', name: '營收 (元)' },
    series: [{
      type: 'scatter',
      data: pts.map((d) => [d.temp_c, d.revenue_cents, d.date, d.rainy]),
    }],
  }
})

const rainOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  xAxis: { type: 'category', data: ['晴天', '雨天'] },
  yAxis: { type: 'value', name: '日均訂單' },
  series: [{
    type: 'bar',
    data: [weather.value?.clear_avg_orders ?? 0, weather.value?.rainy_avg_orders ?? 0],
  }],
}))

onMounted(async () => {
  const { data } = await listStores()
  stores.value = data
  if (data.length) {
    storeId.value = data[0].id
    loadData()
  }
})
</script>
