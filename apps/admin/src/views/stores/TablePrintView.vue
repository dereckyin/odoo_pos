<template>
  <div class="print-page">
    <div class="no-print toolbar">
      <a-space>
        <a-button @click="back">返回</a-button>
        <a-radio-group v-model:value="layout" button-style="solid">
          <a-radio-button value="6">A4・每頁 6 張</a-radio-button>
          <a-radio-button value="8">A4・每頁 8 張</a-radio-button>
        </a-radio-group>
        <a-button type="primary" @click="doPrint">
          <template #icon><PrinterOutlined /></template>列印 / 另存 PDF
        </a-button>
      </a-space>
      <a-typography-text type="secondary" style="margin-left: 12px">
        提示：列印對話框中可選實體印表機，或選「另存為 PDF」批次保存。
      </a-typography-text>
    </div>

    <div v-if="loading" class="no-print loading"><a-spin /></div>

    <div v-else class="sheet" :class="`grid-${layout}`">
      <div v-for="t in items" :key="t.id" class="cell">
        <div class="store-line">{{ storeNameOf(t.store_id) }}</div>
        <div class="table-line">桌 {{ t.label }}</div>
        <qrcode-vue :value="urlFor(t)" :size="qrSize" level="M" />
        <div class="hint-line">掃我點餐</div>
        <div class="url-line">{{ urlFor(t) }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import QrcodeVue from 'qrcode.vue'
import { PrinterOutlined } from '@ant-design/icons-vue'
import { listTables } from '@/api/tables'
import { listStores } from '@/api/stores'
import { customerOrderUrl } from '@/lib/customerOrderBase'
import type { DiningTableRead, StoreRead } from '@/types'

const route = useRoute()
const router = useRouter()

const items = ref<DiningTableRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const layout = ref<'6' | '8'>('6')

const qrSize = computed(() => (layout.value === '6' ? 220 : 180))

function urlFor(t: DiningTableRead) {
  return customerOrderUrl(t.public_token)
}
function storeNameOf(storeId: string) {
  return stores.value.find((s) => s.id === storeId)?.name || ''
}

function back() {
  router.back()
}

function doPrint() {
  window.print()
}

async function load() {
  loading.value = true
  try {
    const ids = ((route.query.ids as string) || '').split(',').filter(Boolean)
    const [storesRes, ...rest] = await Promise.all([
      listStores(),
      // We don't have a get-by-ids endpoint; fetch all (incl. inactive) and filter.
      listTables({ include_inactive: true }),
    ])
    stores.value = storesRes.data
    const all = rest[0].data
    const map = new Map(all.map((t) => [t.id, t]))
    items.value = ids
      .map((id) => map.get(id))
      .filter((t): t is DiningTableRead => !!t)
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.print-page {
  background: #f0f2f5;
  min-height: 100vh;
}
.toolbar {
  position: sticky;
  top: 0;
  z-index: 10;
  background: #fff;
  padding: 12px 16px;
  border-bottom: 1px solid #eee;
  display: flex;
  align-items: center;
}
.loading {
  display: flex;
  justify-content: center;
  padding: 64px 0;
}
.sheet {
  margin: 16px auto;
  width: 210mm;
  background: #fff;
  display: grid;
  gap: 6mm;
  padding: 10mm;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
}
.sheet.grid-6 {
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: 90mm;
}
.sheet.grid-8 {
  grid-template-columns: repeat(2, 1fr);
  grid-auto-rows: 67mm;
}
.cell {
  border: 1px dashed #bbb;
  border-radius: 6px;
  padding: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  break-inside: avoid;
}
.store-line {
  font-size: 14px;
  color: #555;
}
.table-line {
  font-size: 28px;
  font-weight: 700;
  margin: 4px 0 8px;
}
.hint-line {
  font-size: 14px;
  letter-spacing: 4px;
  color: #444;
  margin-top: 6px;
}
.url-line {
  font-size: 10px;
  color: #999;
  margin-top: 2px;
  word-break: break-all;
}

@media print {
  .no-print {
    display: none !important;
  }
  .print-page {
    background: #fff;
  }
  .sheet {
    margin: 0;
    box-shadow: none;
    padding: 8mm;
  }
  @page {
    size: A4 portrait;
    margin: 0;
  }
}
</style>
