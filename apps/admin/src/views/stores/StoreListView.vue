<template>
  <div>
    <a-page-header title="門店管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增門店</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="stores" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-popconfirm title="確定刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯門店' : '新增門店'" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="門店代碼">
          <a-input v-model:value="form.code" />
        </a-form-item>
        <a-form-item label="名稱">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="統編">
          <a-input v-model:value="form.tax_id" />
        </a-form-item>
        <a-form-item label="地址">
          <a-input v-model:value="form.address" />
        </a-form-item>
        <a-form-item label="電話">
          <a-input v-model:value="form.phone" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listStores, createStore, updateStore, deleteStore } from '@/api/stores'
import type { StoreRead } from '@/types'

const stores = ref<StoreRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  code: '',
  name: '',
  tax_id: null as string | null,
  address: null as string | null,
  phone: null as string | null,
})

const columns = [
  { title: '代碼', dataIndex: 'code', width: 120 },
  { title: '名稱', dataIndex: 'name' },
  { title: '統編', dataIndex: 'tax_id', width: 120 },
  { title: '地址', dataIndex: 'address' },
  { title: '電話', dataIndex: 'phone', width: 140 },
  { title: '操作', key: 'actions', width: 140 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listStores()
    stores.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: StoreRead) {
  if (record) {
    editingId.value = record.id
    form.code = record.code
    form.name = record.name
    form.tax_id = record.tax_id
    form.address = record.address
    form.phone = record.phone
  } else {
    editingId.value = null
    form.code = ''
    form.name = ''
    form.tax_id = null
    form.address = null
    form.phone = null
  }
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingId.value) {
      await updateStore(editingId.value, { ...form })
      message.success('已更新')
    } else {
      await createStore({ ...form })
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
  await deleteStore(id)
  message.success('已刪除')
  fetchData()
}

onMounted(fetchData)
</script>
