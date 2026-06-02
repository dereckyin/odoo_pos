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
          <a-tag :color="userRoleTagColor(record.role)">
            {{ userRoleLabel(record.role) }}
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
          <a-select
            v-if="!editingRoleLocked"
            v-model:value="form.role"
            style="width: 220px"
          >
            <a-select-option
              v-for="opt in USER_ROLE_OPTIONS"
              :key="opt.value"
              :value="opt.value"
            >
              {{ opt.label }}
            </a-select-option>
          </a-select>
          <a-input v-else :value="userRoleLabel('tenant_owner')" disabled />
          <div v-if="form.role === 'kitchen'" class="role-hint">
            廚房帳號僅能登入 POS 廚房看板（KDS），建議綁定所屬門店。
          </div>
          <div v-else-if="form.role === 'cashier'" class="role-hint">
            收銀員請綁定所屬門店，並在 POS 完成終端註冊後登入。
          </div>
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
import {
  USER_ROLE_OPTIONS,
  normalizeRoleForApi,
  userRoleLabel,
  userRoleTagColor,
  type AssignableUserRole,
} from '@/constants/userRoles'
import type { UserRead, StoreRead } from '@/types'

const users = ref<UserRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)
const editingRoleLocked = ref(false)

const form = reactive({
  username: '',
  display_name: '',
  password: '',
  role: 'cashier' as AssignableUserRole,
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
    editingRoleLocked.value = record.role === 'tenant_owner'
    form.username = record.username
    form.display_name = record.display_name
    form.password = ''
    form.role = normalizeRoleForApi(record.role)
    form.store_id = record.store_id
    form.is_active = record.is_active
  } else {
    editingId.value = null
    editingRoleLocked.value = false
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
      const payload: Record<string, unknown> = {
        display_name: form.display_name,
        store_id: form.store_id,
        is_active: form.is_active,
      }
      if (!editingRoleLocked.value) payload.role = form.role
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

<style scoped>
.role-hint {
  margin-top: 0.35rem;
  font-size: 0.85rem;
  color: rgba(0, 0, 0, 0.45);
  line-height: 1.4;
}
</style>
