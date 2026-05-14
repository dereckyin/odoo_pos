<template>
  <div>
    <a-page-header title="分類管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增分類</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="categories" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'color'">
          <div v-if="record.color" :style="{ width: '24px', height: '24px', borderRadius: '4px', background: record.color }" />
          <span v-else>-</span>
        </template>
        <template v-if="column.key === 'hp'">
          <span>{{ record.hide_from_public_ordering ? '是' : '' }}</span>
        </template>
        <template v-if="column.key === 'hb'">
          <span>{{ record.hide_from_pos_browse ? '是' : '' }}</span>
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-popconfirm title="確定要刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯分類' : '新增分類'" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="名稱" :rules="[{ required: true }]">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="上層分類">
          <a-select v-model:value="form.parent_id" allow-clear placeholder="無（頂層）">
            <a-select-option v-for="c in categories.filter(c => c.id !== editingId)" :key="c.id" :value="c.id">
              {{ c.name }}
            </a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="排序">
          <a-input-number v-model:value="form.sort_order" :min="0" style="width: 120px" />
        </a-form-item>
        <a-form-item label="顏色">
          <a-input v-model:value="form.color" placeholder="#FF5733" style="width: 160px" />
        </a-form-item>
        <a-form-item label="圖示">
          <a-input v-model:value="form.icon" placeholder="選填" />
        </a-form-item>
        <a-form-item label="QR／桌邊菜單隱藏整個分類">
          <a-switch v-model:checked="form.hide_from_public_ordering" />
        </a-form-item>
        <a-form-item label="POS「全部」隱藏此分類內商品">
          <a-switch v-model:checked="form.hide_from_pos_browse" />
          <div style="color: #888; font-size: 12px">店員仍可點進此分類或掃碼結帳。</div>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listCategories, createCategory, updateCategory, deleteCategory } from '@/api/products'
import type { CategoryRead } from '@/types'

const categories = ref<CategoryRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  name: '',
  parent_id: null as string | null,
  sort_order: 0,
  color: null as string | null,
  icon: null as string | null,
  hide_from_public_ordering: false,
  hide_from_pos_browse: false,
})

const columns = [
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '排序', dataIndex: 'sort_order', key: 'sort_order', width: 80 },
  { title: '顏色', key: 'color', width: 80 },
  { title: 'QR隱藏', key: 'hp', width: 72 },
  { title: 'POS全部隱藏', key: 'hb', width: 100 },
  { title: '操作', key: 'actions', width: 160 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listCategories()
    categories.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: CategoryRead) {
  if (record) {
    editingId.value = record.id
    form.name = record.name
    form.parent_id = record.parent_id
    form.sort_order = record.sort_order
    form.color = record.color
    form.icon = record.icon
    form.hide_from_public_ordering = record.hide_from_public_ordering ?? false
    form.hide_from_pos_browse = record.hide_from_pos_browse ?? false
  } else {
    editingId.value = null
    form.name = ''
    form.parent_id = null
    form.sort_order = 0
    form.color = null
    form.icon = null
    form.hide_from_public_ordering = false
    form.hide_from_pos_browse = false
  }
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingId.value) {
      await updateCategory(editingId.value, { ...form })
      message.success('已更新')
    } else {
      await createCategory({ ...form })
      message.success('已建立')
    }
    modalOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    saving.value = false
  }
}

async function handleDelete(id: string) {
  await deleteCategory(id)
  message.success('已刪除')
  fetchData()
}

onMounted(fetchData)
</script>
