<template>
  <div>
    <a-page-header title="庫存水位">
      <template #extra>
        <a-space>
          <a-button type="primary" @click="openAdjust('initial')">期初建檔</a-button>
          <a-button @click="openAdjust('adjustment')">手動調整</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-space style="margin-bottom: 16px">
      <a-select v-model:value="storeFilter" placeholder="門店篩選" style="width: 200px" allow-clear @change="fetchData">
        <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
      </a-select>
    </a-space>

    <a-table :columns="columns" :data-source="levels" :loading="loading" row-key="id" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'store'">
          {{ record.store_name || record.store_id }}
        </template>
        <template v-else-if="column.key === 'product'">
          <div>{{ record.product_name || record.product_id }}</div>
          <div v-if="record.product_sku" class="sku-hint">{{ record.product_sku }}</div>
        </template>
        <template v-else-if="column.key === 'alert'">
          <a-tag v-if="record.on_hand <= record.safety_stock" color="red">低於安全庫存</a-tag>
          <a-tag v-else color="green">正常</a-tag>
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-button size="small" @click="openAdjust('adjustment', record)">調整</a-button>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="modalOpen"
      :title="modalKind === 'initial' ? '期初建檔' : '手動調整庫存'"
      :confirm-loading="saving"
      ok-text="確認"
      cancel-text="取消"
      @ok="submitAdjust"
    >
      <a-form layout="vertical">
        <a-form-item label="門店" required>
          <a-select
            v-model:value="form.store_id"
            placeholder="選擇門店"
            :options="storeOptions"
            :disabled="!!presetLevel"
          />
        </a-form-item>
        <a-form-item label="商品" required>
          <a-select
            v-model:value="form.product_id"
            show-search
            :filter-option="false"
            placeholder="輸入名稱或 SKU 搜尋"
            :options="productOptions"
            :disabled="!!presetLevel"
            @search="onProductSearch"
          />
        </a-form-item>
        <a-form-item v-if="modalKind === 'initial'" label="期初在庫數量" required>
          <a-input-number v-model:value="form.qty" :min="0" style="width: 160px" />
          <div class="field-hint">直接設定該門店的在庫數量（覆蓋現值）</div>
        </a-form-item>
        <a-form-item v-else label="增減數量" required>
          <a-input-number v-model:value="form.qty" style="width: 160px" />
          <div class="field-hint">正數增加、負數減少</div>
        </a-form-item>
        <a-form-item label="備註">
          <a-input v-model:value="form.note" placeholder="選填" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listInventoryLevels, adjustInventory } from '@/api/inventory'
import { listStores } from '@/api/stores'
import { listProducts } from '@/api/products'
import type { InventoryLevelRead, StoreRead } from '@/types'

const levels = ref<InventoryLevelRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const saving = ref(false)
const storeFilter = ref<string | undefined>()
const modalOpen = ref(false)
const modalKind = ref<'initial' | 'adjustment'>('adjustment')
const presetLevel = ref<InventoryLevelRead | null>(null)
const productOptions = ref<{ label: string; value: string }[]>([])

const form = reactive({
  store_id: undefined as string | undefined,
  product_id: undefined as string | undefined,
  qty: 0,
  note: '',
})

const storeOptions = computed(() => stores.value.map((s) => ({ label: s.name, value: s.id })))

const columns = [
  { title: '門店', key: 'store', width: 160 },
  { title: '商品', key: 'product' },
  { title: '在庫', dataIndex: 'on_hand', width: 100 },
  { title: '安全庫存', dataIndex: 'safety_stock', width: 100 },
  { title: '保留', dataIndex: 'reserved', width: 100 },
  { title: '狀態', key: 'alert', width: 140 },
  { title: '操作', key: 'actions', width: 88 },
]

async function onProductSearch(q: string) {
  if (!q.trim()) return
  const { data } = await listProducts({ q: q.trim(), limit: 50 })
  productOptions.value = data
    .filter((p) => p.track_inventory !== false)
    .map((p) => ({ label: `${p.name}（${p.sku}）`, value: p.id }))
}

function openAdjust(kind: 'initial' | 'adjustment', record?: InventoryLevelRead) {
  modalKind.value = kind
  presetLevel.value = record ?? null
  form.store_id = record?.store_id ?? storeFilter.value
  form.product_id = record?.product_id
  form.qty = kind === 'initial' ? Math.max(0, record?.on_hand ?? 0) : 0
  form.note = ''
  productOptions.value = record
    ? [{ label: `${record.product_name}（${record.product_sku || ''}）`, value: record.product_id }]
    : []
  modalOpen.value = true
}

async function submitAdjust() {
  if (!form.store_id || !form.product_id) {
    message.warning('請選擇門店與商品')
    return Promise.reject()
  }
  if (form.qty === null || form.qty === undefined || Number.isNaN(Number(form.qty))) {
    message.warning('請輸入有效數量')
    return Promise.reject()
  }
  saving.value = true
  try {
    await adjustInventory({
      store_id: form.store_id,
      product_id: form.product_id,
      mode: modalKind.value === 'initial' ? 'set' : 'delta',
      qty: Number(form.qty),
      note: form.note.trim() || undefined,
      reason: modalKind.value,
    })
    message.success(modalKind.value === 'initial' ? '期初建檔完成' : '庫存已調整')
    modalOpen.value = false
    await fetchData()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '操作失敗')
    return Promise.reject()
  } finally {
    saving.value = false
  }
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listInventoryLevels({ store_id: storeFilter.value })
    levels.value = data
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  const { data } = await listStores()
  stores.value = data
  fetchData()
})
</script>

<style scoped>
.sku-hint,
.field-hint {
  color: rgba(0, 0, 0, 0.45);
  font-size: 12px;
  margin-top: 4px;
}
</style>
