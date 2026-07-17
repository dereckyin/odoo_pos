<template>
  <div>
    <a-page-header title="商品列表">
      <template #extra>
        <a-button type="primary" @click="$router.push({ name: 'product-create' })">新增商品</a-button>
        <a-button @click="$router.push({ name: 'product-import' })">CSV 匯入</a-button>
        <a-button :loading="exporting" @click="handleExport">匯出 CSV</a-button>
      </template>
    </a-page-header>

    <a-space style="margin-bottom: 16px" wrap>
      <a-input-search v-model:value="search" placeholder="搜尋商品名稱/SKU" style="width: 260px" allow-clear @search="fetchData" />
      <a-tree-select
        v-model:value="filterCategory"
        placeholder="分類篩選"
        style="width: 280px"
        allow-clear
        tree-default-expand-all
        :tree-data="categoryTreeOptions"
        :field-names="{ label: 'path_label', value: 'id', children: 'children' }"
        @change="fetchData"
      />
      <a-select v-model:value="filterActive" placeholder="上架狀態" style="width: 140px" allow-clear @change="fetchData">
        <a-select-option :value="true">上架中</a-select-option>
        <a-select-option :value="false">已下架</a-select-option>
      </a-select>
      <a-select
        v-model:value="filterStore"
        placeholder="門店（在庫）"
        style="width: 160px"
        allow-clear
        :options="storeOptions"
        @change="fetchData"
      />
    </a-space>

    <a-table :columns="columns" :data-source="products" :loading="loading" row-key="id" :pagination="{ pageSize: 20 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'image_url'">
          <a-image v-if="record.image_url" :src="record.image_url" :width="48" :height="48" style="object-fit: cover; border-radius: 4px" />
          <span v-else style="color: #ccc">無圖片</span>
        </template>
        <template v-if="column.key === 'price_cents'">
          NT${{ record.price_cents }}
        </template>
        <template v-if="column.key === 'category_id'">
          {{ categoryMap[record.category_id] || '-' }}
        </template>
        <template v-if="column.key === 'track_inventory'">
          <a-tag v-if="record.track_inventory !== false" color="blue">追蹤</a-tag>
          <a-tag v-else>不追蹤</a-tag>
        </template>
        <template v-if="column.key === 'on_hand'">
          <span v-if="record.track_inventory === false" class="muted">—</span>
          <span v-else>{{ formatOnHand(record.id) }}</span>
        </template>
        <template v-if="column.key === 'is_active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '上架' : '下架' }}</a-tag>
        </template>
        <template v-if="column.key === 'barcodes'">
          <a-tag v-for="b in record.barcodes" :key="b" style="margin-bottom: 2px">{{ b }}</a-tag>
          <span v-if="!record.barcodes?.length" style="color: #ccc">-</span>
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="$router.push({ name: 'product-edit', params: { id: record.id } })">編輯</a-button>
            <a-popconfirm title="確定要刪除此商品？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
            <a-button size="small" @click="toggleActive(record)">
              {{ record.is_active ? '下架' : '上架' }}
            </a-button>
          </a-space>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { message } from 'ant-design-vue'
import { listProducts, deleteProduct, updateProduct, listCategoriesTree, exportProductsCsv } from '@/api/products'
import { listInventoryLevels } from '@/api/inventory'
import { listStores } from '@/api/stores'
import type { ProductRead, CategoryTreeNode, InventoryLevelRead } from '@/types'

const products = ref<ProductRead[]>([])
const inventoryLevels = ref<InventoryLevelRead[]>([])
const storeOptions = ref<{ label: string; value: string }[]>([])
const filterStore = ref<string | undefined>()
const categoryTreeOptions = ref<CategoryTreeNode[]>([])
const flatCategories = ref<{ id: string; path_label?: string; name: string }[]>([])
const loading = ref(false)
const exporting = ref(false)
const search = ref('')
const filterCategory = ref<string | undefined>()
const filterActive = ref<boolean | undefined>()

const categoryMap = computed(() => {
  const map: Record<string, string> = {}
  flatCategories.value.forEach((c) => {
    map[c.id] = c.path_label || c.name
  })
  return map
})

const onHandByProduct = computed(() => {
  const map: Record<string, number> = {}
  for (const lv of inventoryLevels.value) {
    if (filterStore.value && lv.store_id !== filterStore.value) continue
    map[lv.product_id] = (map[lv.product_id] ?? 0) + lv.on_hand
  }
  return map
})

function formatOnHand(productId: string) {
  const qty = onHandByProduct.value[productId]
  if (qty === undefined) return 0
  return Number.isInteger(qty) ? qty : qty.toFixed(1)
}

function flattenTree(nodes: CategoryTreeNode[], out: { id: string; path_label?: string; name: string }[] = []) {
  for (const n of nodes) {
    out.push(n)
    if (n.children?.length) flattenTree(n.children, out)
  }
  return out
}

function decorateTree(nodes: CategoryTreeNode[]): CategoryTreeNode[] {
  return nodes.map((n) => ({
    ...n,
    path_label: n.path_label || n.name,
    children: n.children?.length ? decorateTree(n.children) : [],
  }))
}

const columns = [
  { title: '圖片', key: 'image_url', width: 72 },
  { title: 'SKU', dataIndex: 'sku', key: 'sku', width: 120 },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '售價', key: 'price_cents', width: 100 },
  { title: '分類', key: 'category_id', width: 200 },
  { title: '追蹤', key: 'track_inventory', width: 72 },
  { title: '在庫', key: 'on_hand', width: 72 },
  { title: '條碼', key: 'barcodes', width: 180 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'actions', width: 200 },
]

async function fetchData() {
  loading.value = true
  try {
    const [{ data }, { data: levels }] = await Promise.all([
      listProducts({
        q: search.value || undefined,
        category_id: filterCategory.value,
        is_active: filterActive.value,
        limit: 200,
      }),
      listInventoryLevels(filterStore.value ? { store_id: filterStore.value } : undefined),
    ])
    products.value = data
    inventoryLevels.value = levels
  } finally {
    loading.value = false
  }
}

async function handleDelete(id: string) {
  await deleteProduct(id)
  message.success('已刪除')
  fetchData()
}

async function handleExport() {
  exporting.value = true
  try {
    const res = await exportProductsCsv({
      q: search.value || undefined,
      category_id: filterCategory.value,
      is_active: filterActive.value,
    })
    const url = URL.createObjectURL(res.data)
    const a = document.createElement('a')
    a.href = url
    a.download = 'products-export.csv'
    a.click()
    URL.revokeObjectURL(url)
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '匯出失敗')
  } finally {
    exporting.value = false
  }
}

async function toggleActive(record: ProductRead) {
  await updateProduct(record.id, { is_active: !record.is_active })
  message.success(record.is_active ? '已下架' : '已上架')
  fetchData()
}

onMounted(async () => {
  const [{ data }, { data: stores }] = await Promise.all([listCategoriesTree(), listStores()])
  categoryTreeOptions.value = decorateTree(data)
  flatCategories.value = flattenTree(data)
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  fetchData()
})
</script>

<style scoped>
.muted {
  color: rgba(0, 0, 0, 0.25);
}
</style>
