<template>
  <div>
    <a-page-header title="條碼標籤列印" sub-title="挑選商品並設定份數，產生可列印的條碼標籤" />

    <div class="toolbar no-print">
      <a-input v-model:value="search" placeholder="搜尋名稱 / SKU" allow-clear style="width: 240px" @change="fetchProducts" />
      <a-button @click="fetchProducts">搜尋</a-button>
      <a-divider type="vertical" />
      <a-checkbox v-model:checked="showName">顯示品名</a-checkbox>
      <a-checkbox v-model:checked="showPrice">顯示售價</a-checkbox>
      <a-divider type="vertical" />
      <a-button type="primary" :disabled="labels.length === 0" @click="print">列印（{{ labels.length }} 張）</a-button>
    </div>

    <div class="layout no-print">
      <a-table
        class="picker"
        :columns="columns"
        :data-source="products"
        :loading="loading"
        row-key="id"
        size="small"
        :pagination="{ pageSize: 20 }"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'price'">{{ formatMoney(record.price_cents) }}</template>
          <template v-else-if="column.key === 'barcode'">
            {{ record.barcodes?.[0] || record.sku }}
          </template>
          <template v-else-if="column.key === 'actions'">
            <a-input-number v-model:value="qtyMap[record.id]" :min="1" :max="200" style="width: 80px" />
            <a-button size="small" type="link" @click="addLabels(record)">加入</a-button>
          </template>
        </template>
      </a-table>

      <div class="cart">
        <h4>待列印標籤</h4>
        <a-empty v-if="labels.length === 0" description="尚未加入標籤" />
        <a-list v-else size="small" :data-source="groupedLabels">
          <template #renderItem="{ item }">
            <a-list-item>
              <span>{{ item.name }} ×{{ item.count }}</span>
              <a-button size="small" danger type="link" @click="removeGroup(item.code)">移除</a-button>
            </a-list-item>
          </template>
        </a-list>
        <a-button v-if="labels.length" block style="margin-top: 8px" @click="labels = []">清空</a-button>
      </div>
    </div>

    <!-- Print area -->
    <div class="print-sheet" ref="sheet">
      <div v-for="(lb, idx) in labels" :key="idx" class="label">
        <div v-if="showName" class="label-name">{{ lb.name }}</div>
        <svg class="label-barcode" :ref="(el) => setSvgRef(el, idx)"></svg>
        <div v-if="showPrice" class="label-price">{{ formatMoney(lb.price_cents) }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { message } from 'ant-design-vue'
import JsBarcode from 'jsbarcode'
import { listProducts } from '@/api/products'
import type { ProductRead } from '@/types'
import { formatMoney } from '@/utils/formatMoney'

interface Label {
  code: string
  name: string
  price_cents: number
}

const products = ref<ProductRead[]>([])
const loading = ref(false)
const search = ref('')
const showName = ref(true)
const showPrice = ref(true)
const qtyMap = reactive<Record<string, number>>({})
const labels = ref<Label[]>([])
const svgRefs: (Element | null)[] = []

const columns = [
  { title: '商品', dataIndex: 'name', key: 'name' },
  { title: 'SKU', dataIndex: 'sku', key: 'sku', width: 140 },
  { title: '條碼', key: 'barcode', width: 160 },
  { title: '售價', key: 'price', width: 100 },
  { title: '份數', key: 'actions', width: 160 },
]

const groupedLabels = computed(() => {
  const map = new Map<string, { code: string; name: string; count: number }>()
  for (const l of labels.value) {
    const g = map.get(l.code)
    if (g) g.count += 1
    else map.set(l.code, { code: l.code, name: l.name, count: 1 })
  }
  return [...map.values()]
})

function setSvgRef(el: any, idx: number) {
  svgRefs[idx] = el as Element | null
}

async function fetchProducts() {
  loading.value = true
  try {
    const { data } = await listProducts({ q: search.value || undefined, limit: 200 })
    products.value = data
  } finally {
    loading.value = false
  }
}

function addLabels(p: ProductRead) {
  const code = p.barcodes?.[0] || p.sku
  if (!code) {
    message.warning('此商品沒有條碼或 SKU')
    return
  }
  const qty = qtyMap[p.id] || 1
  for (let i = 0; i < qty; i++) {
    labels.value.push({ code, name: p.name, price_cents: p.price_cents })
  }
  renderBarcodes()
}

function removeGroup(code: string) {
  labels.value = labels.value.filter((l) => l.code !== code)
  renderBarcodes()
}

function renderBarcodes() {
  nextTick(() => {
    labels.value.forEach((lb, idx) => {
      const el = svgRefs[idx]
      if (!el) return
      try {
        JsBarcode(el, lb.code, {
          format: 'CODE128',
          width: 1.6,
          height: 48,
          fontSize: 12,
          margin: 4,
          displayValue: true,
        })
      } catch {
        /* invalid code: skip */
      }
    })
  })
}

function print() {
  renderBarcodes()
  nextTick(() => setTimeout(() => window.print(), 150))
}

onMounted(fetchProducts)
</script>

<style scoped>
.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}
.layout {
  display: flex;
  gap: 16px;
  align-items: flex-start;
}
.picker {
  flex: 1;
}
.cart {
  width: 280px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 12px;
}
.cart h4 {
  margin: 0 0 8px;
}
.print-sheet {
  display: none;
}
.label {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 48mm;
  height: 30mm;
  padding: 2mm;
  box-sizing: border-box;
  page-break-inside: avoid;
  text-align: center;
}
.label-name {
  font-size: 11px;
  font-weight: 600;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.label-price {
  font-size: 12px;
  font-weight: 700;
}

@media print {
  .no-print {
    display: none !important;
  }
  .print-sheet {
    display: flex !important;
    flex-wrap: wrap;
    gap: 0;
  }
}
</style>
