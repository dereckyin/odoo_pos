<template>
  <div>
    <a-page-header
      :title="order ? `訂單 ${order.order_no || ''}` : '訂單詳情'"
      @back="$router.push({ name: 'orders' })"
    />

    <a-spin :spinning="loading">
      <a-descriptions bordered :column="2" v-if="order" style="margin-bottom: 24px">
        <a-descriptions-item label="訂單編號">{{ order.order_no || '—' }}</a-descriptions-item>
        <a-descriptions-item label="狀態">
          <a-tag :color="statusColor(order.status)">{{ statusLabel(order.status) }}</a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="交易時間">
          {{ formatTime(order.client_created_at || order.created_at) }}
        </a-descriptions-item>
        <a-descriptions-item label="門店">{{ order.store_name || '—' }}</a-descriptions-item>
        <a-descriptions-item label="收銀員">{{ order.cashier_name || '—' }}</a-descriptions-item>
        <a-descriptions-item label="會員">{{ order.member_name || '散客' }}</a-descriptions-item>
        <a-descriptions-item label="來源">
          <a-tag :color="order.source === 'qr' ? 'purple' : 'blue'">
            {{ order.source === 'qr' ? 'QR 點餐' : 'POS 收銀' }}
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="發票號">{{ order.invoice_number || '—' }}</a-descriptions-item>
        <a-descriptions-item label="小計">{{ formatMoney(order.subtotal_cents) }}</a-descriptions-item>
        <a-descriptions-item label="折扣">{{ formatMoney(order.discount_cents) }}</a-descriptions-item>
        <a-descriptions-item label="稅額">{{ formatMoney(order.tax_cents) }}</a-descriptions-item>
        <a-descriptions-item label="總計">{{ formatMoney(order.total_cents) }}</a-descriptions-item>
        <a-descriptions-item label="已退款">{{ formatMoney(order.refunded_cents) }}</a-descriptions-item>
        <a-descriptions-item label="淨額">
          {{ formatMoney(order.total_cents - order.refunded_cents) }}
        </a-descriptions-item>
        <a-descriptions-item v-if="order.note" label="備註" :span="2">{{ order.note }}</a-descriptions-item>
      </a-descriptions>

      <a-collapse v-if="order" ghost style="margin-bottom: 16px">
        <a-collapse-panel key="tech" header="技術資訊">
          <a-descriptions :column="1" size="small">
            <a-descriptions-item label="UUID">{{ order.id }}</a-descriptions-item>
            <a-descriptions-item label="store_id">{{ order.store_id }}</a-descriptions-item>
            <a-descriptions-item label="terminal_id">{{ order.terminal_id }}</a-descriptions-item>
            <a-descriptions-item v-if="order.source_guest_order_id" label="guest_order_id">
              {{ order.source_guest_order_id }}
            </a-descriptions-item>
          </a-descriptions>
        </a-collapse-panel>
      </a-collapse>

      <a-divider>訂單明細</a-divider>
      <a-table
        :columns="lineColumns"
        :data-source="order?.lines || []"
        row-key="id"
        size="small"
        :pagination="false"
      >
        <template #bodyCell="{ column, record, text }">
          <template v-if="column.key === 'product_name'">
            <div>{{ record.product_name }}</div>
            <div v-if="record.options_json?.length" style="font-size: 12px; color: #888">
              {{ record.options_json.map((o: any) => o.choice_name).join(' · ') }}
            </div>
            <div v-if="record.note" style="font-size: 12px; color: #fa8c16">備註：{{ record.note }}</div>
          </template>
          <template v-if="column.key === 'unit_price'">{{ formatMoney(text) }}</template>
          <template v-if="column.key === 'line_total'">{{ formatMoney(text) }}</template>
        </template>
      </a-table>

      <a-divider>付款資訊</a-divider>
      <a-table
        :columns="payColumns"
        :data-source="order?.payments || []"
        row-key="id"
        size="small"
        :pagination="false"
      >
        <template #bodyCell="{ column, text }">
          <template v-if="column.key === 'amount'">{{ formatMoney(text) }}</template>
          <template v-if="column.key === 'method'">{{ paymentLabel(text) }}</template>
        </template>
      </a-table>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import dayjs from 'dayjs'
import { getOrder } from '@/api/orders'
import { formatMoney } from '@/utils/formatMoney'
import type { OrderListItem } from '@/types'

const route = useRoute()
const order = ref<OrderListItem | null>(null)
const loading = ref(false)

const lineColumns = [
  { title: '商品', dataIndex: 'product_name', key: 'product_name' },
  { title: 'SKU', dataIndex: 'sku', width: 120 },
  { title: '數量', dataIndex: 'qty', width: 80 },
  { title: '單價', dataIndex: 'unit_price_cents', key: 'unit_price', width: 100 },
  { title: '小計', dataIndex: 'line_total_cents', key: 'line_total', width: 100 },
]

const payColumns = [
  { title: '方式', dataIndex: 'method', key: 'method' },
  { title: '金額', dataIndex: 'amount_cents', key: 'amount', width: 120 },
  { title: '狀態', dataIndex: 'status', width: 100 },
]

function formatTime(iso: string | null) {
  if (!iso) return '—'
  return dayjs(iso).format('YYYY/MM/DD HH:mm:ss')
}

function statusColor(s: string) {
  if (s === 'paid') return 'green'
  if (s === 'partiallyRefunded') return 'orange'
  if (s === 'refunded') return 'red'
  return 'default'
}

function statusLabel(s: string) {
  return (
    { paid: '已付款', partiallyRefunded: '部分退款', refunded: '已退款' } as Record<string, string>
  )[s] || s
}

function paymentLabel(m: string) {
  return (
    { cash: '現金', card: '信用卡', linepay: 'Line Pay', easycard: '悠遊卡' } as Record<string, string>
  )[m] || m
}

onMounted(async () => {
  loading.value = true
  try {
    const { data } = await getOrder(route.params.id as string)
    order.value = data
  } finally {
    loading.value = false
  }
})
</script>
