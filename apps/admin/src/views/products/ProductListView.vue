<template>
  <div>
    <a-page-header title="商品列表">
      <template #extra>
        <a-button type="primary" @click="$router.push({ name: 'product-create' })">新增商品</a-button>
        <a-button @click="$router.push({ name: 'product-import' })">CSV 匯入</a-button>
      </template>
    </a-page-header>

    <a-space style="margin-bottom: 16px" wrap>
      <a-input-search v-model:value="search" placeholder="搜尋商品名稱/SKU" style="width: 260px" allow-clear @search="fetchData" />
      <a-select v-model:value="filterCategory" placeholder="分類篩選" style="width: 180px" allow-clear @change="fetchData">
        <a-select-option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</a-select-option>
      </a-select>
      <a-select v-model:value="filterActive" placeholder="上架狀態" style="width: 140px" allow-clear @change="fetchData">
        <a-select-option :value="true">上架中</a-select-option>
        <a-select-option :value="false">已下架</a-select-option>
      </a-select>
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
import { ref, reactive, onMounted, computed } from 'vue'
import { message } from 'ant-design-vue'
import { listProducts, deleteProduct, updateProduct, listCategories } from '@/api/products'
import type { ProductRead, CategoryRead } from '@/types'

const products = ref<ProductRead[]>([])
const categories = ref<CategoryRead[]>([])
const loading = ref(false)
const search = ref('')
const filterCategory = ref<string | undefined>()
const filterActive = ref<boolean | undefined>()

const categoryMap = computed(() => {
  const map: Record<string, string> = {}
  categories.value.forEach(c => { map[c.id] = c.name })
  return map
})

const columns = [
  { title: '圖片', key: 'image_url', width: 72 },
  { title: 'SKU', dataIndex: 'sku', key: 'sku', width: 120 },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '售價', key: 'price_cents', width: 100 },
  { title: '分類', key: 'category_id', width: 120 },
  { title: '條碼', key: 'barcodes', width: 180 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'actions', width: 200 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listProducts({
      q: search.value || undefined,
      category_id: filterCategory.value,
      is_active: filterActive.value,
    })
    products.value = data
  } finally {
    loading.value = false
  }
}

async function handleDelete(id: string) {
  await deleteProduct(id)
  message.success('已刪除')
  fetchData()
}

async function toggleActive(record: ProductRead) {
  await updateProduct(record.id, { is_active: !record.is_active })
  message.success(record.is_active ? '已下架' : '已上架')
  fetchData()
}

onMounted(async () => {
  const { data } = await listCategories()
  categories.value = data
  fetchData()
})
</script>
