<template>
  <div>
    <a-page-header title="租戶管理" sub-title="平台超管專用" :back-icon="false">
      <template #extra>
        <a-radio-group v-model:value="statusFilter" button-style="solid" @change="reload">
          <a-radio-button value="">全部</a-radio-button>
          <a-radio-button value="active">啟用</a-radio-button>
          <a-radio-button value="suspended">停權</a-radio-button>
          <a-radio-button value="cancelled">已取消</a-radio-button>
        </a-radio-group>
      </template>
    </a-page-header>

    <a-table
      :columns="columns"
      :data-source="rows"
      :loading="loading"
      row-key="id"
      :pagination="{ pageSize: 20 }"
      size="middle"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ record.status }}</a-tag>
        </template>
        <template v-else-if="column.key === 'created_at'">
          {{ new Date(record.created_at).toLocaleString() }}
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space size="small">
            <a-button size="small" @click="openEdit(record)">編輯</a-button>
            <a-button
              v-if="record.status === 'active'"
              size="small"
              danger
              @click="quickStatus(record, 'suspended')"
            >
              停權
            </a-button>
            <a-button
              v-else-if="record.status === 'suspended'"
              size="small"
              type="primary"
              @click="quickStatus(record, 'active')"
            >
              恢復
            </a-button>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="editVisible"
      title="編輯租戶"
      :confirm-loading="editLoading"
      @ok="submitEdit"
    >
      <a-form v-if="current" :model="editForm" layout="vertical">
        <a-form-item label="名稱">
          <a-input v-model:value="editForm.name" />
        </a-form-item>
        <a-form-item label="聯絡信箱">
          <a-input v-model:value="editForm.contact_email" />
        </a-form-item>
        <a-form-item label="聯絡電話">
          <a-input v-model:value="editForm.contact_phone" />
        </a-form-item>
        <a-form-item label="狀態">
          <a-select v-model:value="editForm.status">
            <a-select-option value="active">active</a-select-option>
            <a-select-option value="suspended">suspended</a-select-option>
            <a-select-option value="cancelled">cancelled</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="方案代號">
          <a-input v-model:value="editForm.plan_code" placeholder="例：starter" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import * as platformApi from '@/api/platform'
import type { TenantRead } from '@/types'

const rows = ref<TenantRead[]>([])
const loading = ref(false)
const statusFilter = ref<string>('')

const editVisible = ref(false)
const editLoading = ref(false)
const current = ref<TenantRead | null>(null)
const editForm = ref<{
  name: string
  contact_email: string
  contact_phone: string
  status: string
  plan_code: string
}>({ name: '', contact_email: '', contact_phone: '', status: '', plan_code: '' })

const columns = [
  { title: '代號', dataIndex: 'code', key: 'code' },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '聯絡信箱', dataIndex: 'contact_email', key: 'contact_email' },
  { title: '統編', dataIndex: 'tax_id', key: 'tax_id' },
  { title: '方案', dataIndex: 'plan_code', key: 'plan_code' },
  { title: '狀態', key: 'status' },
  { title: '建立時間', key: 'created_at' },
  { title: '操作', key: 'actions', width: 180 },
]

function statusColor(s: string) {
  return ({
    active: 'green',
    suspended: 'orange',
    cancelled: 'red',
    trial: 'blue',
  } as Record<string, string>)[s] || 'default'
}

async function reload() {
  loading.value = true
  try {
    const { data } = await platformApi.listTenants(statusFilter.value || undefined)
    rows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入租戶列表')
  } finally {
    loading.value = false
  }
}

function openEdit(rec: TenantRead) {
  current.value = rec
  editForm.value = {
    name: rec.name,
    contact_email: rec.contact_email,
    contact_phone: rec.contact_phone || '',
    status: rec.status,
    plan_code: rec.plan_code || '',
  }
  editVisible.value = true
}

async function submitEdit() {
  if (!current.value) return
  editLoading.value = true
  try {
    await platformApi.updateTenant(current.value.id, {
      name: editForm.value.name,
      contact_email: editForm.value.contact_email,
      contact_phone: editForm.value.contact_phone || null,
      status: editForm.value.status,
      plan_code: editForm.value.plan_code || null,
    })
    message.success('已更新')
    editVisible.value = false
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '更新失敗')
  } finally {
    editLoading.value = false
  }
}

async function quickStatus(rec: TenantRead, s: string) {
  try {
    await platformApi.updateTenant(rec.id, { status: s })
    message.success(`已切換至 ${s}`)
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '更新失敗')
  }
}

onMounted(reload)
</script>
