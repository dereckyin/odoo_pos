<template>
  <div>
    <a-page-header title="採購單" />
    <a-space style="margin-bottom: 16px" wrap>
      <a-select v-model:value="storeFilter" placeholder="門店篩選" style="width: 200px" allow-clear @change="load">
        <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
      </a-select>
      <a-button type="primary" @click="openCreate">新增採購單</a-button>
    </a-space>
    <a-table :columns="columns" :data-source="orders" :loading="loading" row-key="id" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'act'">
          <a-button type="link" @click="$router.push({ name: 'purchase-order-detail', params: { id: record.id } })">
            詳情／收貨
          </a-button>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="createOpen" title="新增採購單（草稿）" width="720px" :confirm-loading="saving" @ok="submitCreate">
      <a-form layout="vertical">
        <a-row :gutter="12">
          <a-col :span="12">
            <a-form-item label="門店" required>
              <a-select v-model:value="draft.store_id" style="width: 100%">
                <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="供應商" required>
              <a-select v-model:value="draft.supplier_id" style="width: 100%" show-search option-filter-prop="label">
                <a-select-option v-for="u in suppliers" :key="u.id" :value="u.id" :label="u.name + u.code">
                  {{ u.code }} — {{ u.name }}
                </a-select-option>
              </a-select>
            </a-form-item>
          </a-col>
        </a-row>
        <a-form-item label="採購單號（選填）"><a-input v-model:value="draft.reference" placeholder="內部參考編號" /></a-form-item>
        <a-form-item label="明細">
          <a-table :columns="lineCols" :data-source="draft.lines" row-key="id" size="small" :pagination="false">
            <template #bodyCell="{ column, record, index }">
              <template v-if="column.key === 'product'">
                <a-select
                  v-model:value="record.product_id"
                  style="width: 100%"
                  show-search
                  :filter-option="filterProduct"
                  :options="productOptions"
                />
              </template>
              <template v-if="column.key === 'qty'">
                <a-input-number v-model:value="record.qty_ordered" :min="0.001" :step="1" style="width: 120px" />
              </template>
              <template v-if="column.key === 'rm'">
                <a-button type="link" danger @click="removeLine(index)" :disabled="draft.lines.length <= 1">移除</a-button>
              </template>
            </template>
          </a-table>
          <a-button style="margin-top: 8px" @click="addLine">新增品項</a-button>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { listPurchaseOrders, createPurchaseOrder, listSuppliers } from '@/api/purchasing'
import { listStores } from '@/api/stores'
import { listProducts } from '@/api/products'
import type { PurchaseOrderRead, StoreRead, SupplierRead, ProductRead, PurchaseOrderLineIn } from '@/types'

const router = useRouter()
const orders = ref<PurchaseOrderRead[]>([])
const stores = ref<StoreRead[]>([])
const suppliers = ref<SupplierRead[]>([])
const products = ref<ProductRead[]>([])
const loading = ref(false)
const storeFilter = ref<string | undefined>()
const createOpen = ref(false)
const saving = ref(false)

type DraftLine = PurchaseOrderLineIn
const draft = ref<{ store_id: string; supplier_id: string; reference: string; lines: DraftLine[] }>({
  store_id: '',
  supplier_id: '',
  reference: '',
  lines: [],
})

const productOptions = computed(() =>
  products.value.map((p) => ({ value: p.id, label: `${p.sku} ${p.name}` })),
)

const columns = [
  { title: '採購單 ID', dataIndex: 'id', ellipsis: true, width: 200 },
  { title: '門店', dataIndex: 'store_id', width: 200 },
  { title: '供應商', dataIndex: 'supplier_id', width: 200 },
  { title: '狀態', dataIndex: 'status', width: 100 },
  { title: '參考號', dataIndex: 'reference', width: 140 },
  { title: '建立時間', dataIndex: 'created_at', width: 180 },
  { title: '', key: 'act', width: 140 },
]

const lineCols = [
  { title: '商品', key: 'product', width: 360 },
  { title: '訂購量', key: 'qty', width: 140 },
  { title: '', key: 'rm', width: 80 },
]

function filterProduct(input: string, option: { label?: string }) {
  return (option?.label || '').toLowerCase().includes(input.toLowerCase())
}

function addLine() {
  draft.value.lines.push({ id: crypto.randomUUID(), product_id: '', qty_ordered: 1 })
}

function removeLine(i: number) {
  draft.value.lines.splice(i, 1)
}

async function load() {
  loading.value = true
  try {
    const { data } = await listPurchaseOrders({ store_id: storeFilter.value })
    orders.value = data
  } finally {
    loading.value = false
  }
}

function openCreate() {
  draft.value = {
    store_id: draft.value.store_id || stores.value[0]?.id || '',
    supplier_id: suppliers.value[0]?.id || '',
    reference: '',
    lines: [{ id: crypto.randomUUID(), product_id: '', qty_ordered: 1 }],
  }
  createOpen.value = true
}

async function submitCreate() {
  if (!draft.value.store_id || !draft.value.supplier_id) {
    message.error('請選擇門店與供應商')
    return
  }
  for (const ln of draft.value.lines) {
    if (!ln.product_id || !ln.qty_ordered || ln.qty_ordered <= 0) {
      message.error('請完整填寫品項與數量')
      return
    }
  }
  saving.value = true
  try {
    const id = crypto.randomUUID()
    await createPurchaseOrder({
      id,
      store_id: draft.value.store_id,
      supplier_id: draft.value.supplier_id,
      reference: draft.value.reference.trim() || null,
      lines: draft.value.lines.map((l) => ({
        id: l.id,
        product_id: l.product_id,
        qty_ordered: Number(l.qty_ordered),
      })),
    })
    message.success('草稿已建立')
    createOpen.value = false
    await load()
    router.push({ name: 'purchase-order-detail', params: { id } })
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '建立失敗')
    throw e
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const [st, sup, pr] = await Promise.all([listStores(), listSuppliers(), listProducts({ limit: 200 })])
  stores.value = st.data
  suppliers.value = sup.data
  products.value = pr.data
  await load()
})
</script>
