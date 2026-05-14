<template>
  <div v-if="po">
    <a-page-header :title="title">
      <template #extra>
        <a-button @click="$router.push({ name: 'purchase-orders' })">返回列表</a-button>
      </template>
    </a-page-header>
    <a-descriptions bordered size="small" style="margin-bottom: 16px">
      <a-descriptions-item label="狀態"><a-tag>{{ po.status }}</a-tag></a-descriptions-item>
      <a-descriptions-item label="門店">{{ storeName(po.store_id) }}</a-descriptions-item>
      <a-descriptions-item label="供應商">{{ supplierLabel(po.supplier_id) }}</a-descriptions-item>
      <a-descriptions-item label="參考號">{{ po.reference || '—' }}</a-descriptions-item>
      <a-descriptions-item label="下單時間">{{ po.ordered_at || '—' }}</a-descriptions-item>
    </a-descriptions>

    <a-space v-if="po.status === 'draft'" style="margin-bottom: 12px" wrap>
      <a-popconfirm title="確認送出為「已下單」？之後可分批收貨入庫。" @confirm="doOrder">
        <a-button type="primary">確認下單</a-button>
      </a-popconfirm>
      <a-popconfirm title="取消此草稿？" @confirm="doCancel">
        <a-button danger>取消採購單</a-button>
      </a-popconfirm>
    </a-space>
    <a-space v-else-if="po.status === 'ordered' || po.status === 'partial'" style="margin-bottom: 12px" wrap>
      <a-button type="primary" @click="recvOpen = true">收貨入庫</a-button>
      <a-popconfirm v-if="!anyReceived" title="取消尚未收貨的採購單？" @confirm="doCancel">
        <a-button danger>取消採購單</a-button>
      </a-popconfirm>
    </a-space>

    <a-table
      :columns="cols"
      :data-source="po.lines"
      row-key="id"
      size="small"
      :pagination="false"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'prod'">
          {{ productLabel(record.product_id) }}
        </template>
        <template v-else-if="column.key === 'rem'">
          {{ remaining(record) }}
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="recvOpen" title="收貨入庫" ok-text="確認收貨" :confirm-loading="recvBusy" @ok="submitReceive">
      <p style="color: rgba(0,0,0,.55); margin-bottom: 12px">僅填本次實際入庫數，可小於剩餘量；會寫入庫存流水並更新採購狀態。</p>
      <div v-for="ln in po.lines" :key="ln.id" style="margin-bottom: 10px" class="recv-row">
        <div style="flex: 1; min-width: 0">{{ productLabel(ln.product_id) }}</div>
        <span style="margin: 0 8px">剩餘 {{ remaining(ln) }}</span>
        <a-input-number v-model:value="recvQty[ln.id]" :min="0" :max="remaining(ln)" :step="1" style="width: 120px" />
      </div>
    </a-modal>
  </div>
  <a-spin v-else :spinning="loading" />
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue'
import {
  getPurchaseOrder,
  patchPurchaseOrderStatus,
  receivePurchaseOrder,
  listSuppliers,
} from '@/api/purchasing'
import { listStores } from '@/api/stores'
import { listProducts } from '@/api/products'
import type { PurchaseOrderRead, StoreRead, SupplierRead, ProductRead, PurchaseOrderLineRead } from '@/types'

const route = useRoute()
const po = ref<PurchaseOrderRead | null>(null)
const loading = ref(true)
const stores = ref<StoreRead[]>([])
const suppliers = ref<SupplierRead[]>([])
const products = ref<ProductRead[]>([])
const recvOpen = ref(false)
const recvBusy = ref(false)
const recvQty = reactive<Record<string, number | null>>({})

const title = computed(() => `採購單 ${route.params.id}`)

const anyReceived = computed(() => (po.value?.lines || []).some((l) => l.qty_received > 0))

const cols = [
  { title: '商品', key: 'prod' },
  { title: '訂購', dataIndex: 'qty_ordered', width: 90 },
  { title: '已收', dataIndex: 'qty_received', width: 90 },
  { title: '尚可收', key: 'rem', width: 90 },
]

function remaining(ln: PurchaseOrderLineRead) {
  return Math.max(0, Number(ln.qty_ordered) - Number(ln.qty_received))
}

function storeName(id: string) {
  return stores.value.find((s) => s.id === id)?.name || id
}

function supplierLabel(id: string) {
  const s = suppliers.value.find((x) => x.id === id)
  return s ? `${s.code} ${s.name}` : id
}

function productLabel(pid: string) {
  const p = products.value.find((x) => x.id === pid)
  return p ? `${p.sku} ${p.name}` : pid
}

async function reload() {
  const id = route.params.id as string
  const { data } = await getPurchaseOrder(id)
  po.value = data
  for (const ln of data.lines) {
    recvQty[ln.id] = 0
  }
}

async function doOrder() {
  try {
    const id = route.params.id as string
    await patchPurchaseOrderStatus(id, 'ordered')
    message.success('已標記為已下單')
    await reload()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '失敗')
  }
}

async function doCancel() {
  try {
    const id = route.params.id as string
    await patchPurchaseOrderStatus(id, 'cancelled')
    message.success('已取消')
    await reload()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '失敗')
  }
}

async function submitReceive() {
  if (!po.value) return
  const lines = po.value.lines
    .map((ln) => ({
      line_id: ln.id,
      qty: Number(recvQty[ln.id] || 0),
    }))
    .filter((x) => x.qty > 0)
  if (!lines.length) {
    message.error('請至少輸入一筆大於 0 的收貨量')
    return
  }
  recvBusy.value = true
  try {
    await receivePurchaseOrder(po.value.id, { lines })
    message.success('收貨入庫完成')
    recvOpen.value = false
    await reload()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '收貨失敗')
  } finally {
    recvBusy.value = false
  }
}

onMounted(async () => {
  loading.value = true
  try {
    const [st, sup, pr] = await Promise.all([listStores(), listSuppliers(), listProducts({ limit: 200 })])
    stores.value = st.data
    suppliers.value = sup.data
    products.value = pr.data
    await reload()
  } catch {
    message.error('無法載入採購單')
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.recv-row {
  display: flex;
  align-items: center;
  gap: 4px;
}
</style>
