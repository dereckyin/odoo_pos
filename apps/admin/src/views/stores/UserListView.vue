<template>
  <div>
    <a-page-header title="使用者管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增使用者</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="users" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'role'">
          <a-tag :color="record.role === 'admin' ? 'red' : record.role === 'manager' ? 'blue' : 'default'">
            {{ roleLabel[record.role] || record.role }}
          </a-tag>
        </template>
        <template v-if="column.key === 'is_active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '啟用' : '停用' }}</a-tag>
        </template>
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

    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯使用者' : '新增使用者'" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="帳號" v-if="!editingId">
          <a-input v-model:value="form.username" />
        </a-form-item>
        <a-form-item label="顯示名稱">
          <a-input v-model:value="form.display_name" />
        </a-form-item>
        <a-form-item :label="editingId ? '新密碼（留空不修改）' : '密碼'">
          <a-input-password v-model:value="form.password" />
        </a-form-item>
        <a-form-item label="角色">
          <a-select v-model:value="form.role" style="width: 200px">
            <a-select-option value="admin">管理員</a-select-option>
            <a-select-option value="manager">店長</a-select-option>
            <a-select-option value="cashier">收銀員</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="所屬門店">
          <a-select v-model:value="form.store_id" placeholder="選填" allow-clear style="width: 100%">
            <a-select-option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="狀態">
          <a-switch v-model:checked="form.is_active" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listUsers, createUser, updateUser, deleteUser } from '@/api/users'
import { listStores } from '@/api/stores'
import type { UserRead, StoreRead } from '@/types'

const users = ref<UserRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)

const roleLabel: Record<string, string> = {
  admin: '管理員',
  manager: '店長',
  cashier: '收銀員',
}

const form = reactive({
  username: '',
  display_name: '',
  password: '',
  role: 'cashier',
  store_id: null as string | null,
  is_active: true,
})

const columns = [
  { title: '帳號', dataIndex: 'username' },
  { title: '名稱', dataIndex: 'display_name' },
  { title: '角色', key: 'role', width: 100 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'actions', width: 140 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listUsers()
    users.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: UserRead) {
  if (record) {
    editingId.value = record.id
    form.username = record.username
    form.display_name = record.display_name
    form.password = ''
    form.role = record.role
    form.store_id = record.store_id
    form.is_active = record.is_active
  } else {
    editingId.value = null
    form.username = ''
    form.display_name = ''
    form.password = ''
    form.role = 'cashier'
    form.store_id = null
    form.is_active = true
  }
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingId.value) {
      const payload: Record<string, any> = {
        display_name: form.display_name,
        role: form.role,
        store_id: form.store_id,
        is_active: form.is_active,
      }
      if (form.password) payload.password = form.password
      await updateUser(editingId.value, payload)
      message.success('已更新')
    } else {
      await createUser({ ...form })
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
  await deleteUser(id)
  message.success('已刪除')
  fetchData()
}

onMounted(async () => {
  const { data } = await listStores()
  stores.value = data
  fetchData()
})
</script>
