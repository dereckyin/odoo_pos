<template>
  <div class="tables-page">
    <header>
      <h1>開桌 / 點餐 QR</h1>
      <button :disabled="loading" @click="load">{{ loading ? '載入中…' : '重新整理' }}</button>
    </header>
    <p class="hint">開桌後會建立列印工作，由店內「列印工作站」App 印出 QR 單。</p>
    <div class="grid" data-testid="table-grid">
      <button
        v-for="t in tables"
        :key="t.id"
        class="table-btn"
        :disabled="opening === t.id"
        @click="openTable(t.id)"
      >
        {{ t.label }}
      </button>
    </div>
    <div v-if="lastSession" class="result">
      <h3>桌號 {{ lastSession.table_label }}</h3>
      <p>顧客點餐連結：</p>
      <a :href="lastSession.customer_order_url" data-testid="customer-order-link" target="_blank">{{ lastSession.customer_order_url }}</a>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import * as tablesApi from '@/api/tables'
import { useAuthStore } from '@/stores/auth'
import { enqueueTableQrPrint } from '@/lib/printPayloads'
import type { DiningTable, TableSessionOpen } from '@/types'

const auth = useAuthStore()
const tables = ref<DiningTable[]>([])
const loading = ref(false)
const opening = ref<string | null>(null)
const lastSession = ref<TableSessionOpen | null>(null)

async function load() {
  if (!auth.storeId) return
  loading.value = true
  try {
    const { data } = await tablesApi.listTables(auth.storeId)
    tables.value = data.filter((t) => t.is_active)
  } finally {
    loading.value = false
  }
}

async function openTable(tableId: string) {
  opening.value = tableId
  try {
    const { data } = await tablesApi.openTableSession(tableId)
    lastSession.value = data
    await enqueueTableQrPrint(data)
    alert(`已開桌 ${data.table_label}，QR 列印工作已送出`)
  } catch {
    alert('開桌失敗')
  } finally {
    opening.value = null
  }
}

onMounted(load)
</script>

<style scoped>
.tables-page {
  padding: 16px;
}
header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.hint {
  color: #666;
  font-size: 0.9rem;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 12px;
  margin-top: 16px;
}
.table-btn {
  padding: 20px;
  border: 1px solid #d9d9d9;
  border-radius: 10px;
  background: #fff;
  font-size: 1.1rem;
  font-weight: 700;
}
.result {
  margin-top: 24px;
  background: #fff;
  padding: 16px;
  border-radius: 10px;
}
.result a {
  word-break: break-all;
}
</style>
