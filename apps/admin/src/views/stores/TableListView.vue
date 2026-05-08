<template>
  <div>
    <a-page-header title="桌位管理">
      <template #extra>
        <a-space>
          <a-select
            v-model:value="storeFilter"
            style="width: 220px"
            placeholder="選擇門店"
            allow-clear
            :options="storeOptions"
            @change="fetchData"
          />
          <a-checkbox v-model:checked="includeInactive" @change="fetchData">含停用</a-checkbox>
          <a-button :disabled="!selectedRowKeys.length" @click="printSelected">
            <template #icon><PrinterOutlined /></template>
            列印選取（{{ selectedRowKeys.length }}）
          </a-button>
          <a-button type="primary" :disabled="!storeFilter" @click="openCreate">新增桌位</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-alert
      v-if="!storeFilter"
      type="info"
      show-icon
      message="請先選擇門店；新增桌位需先選定該桌所屬門店。"
      style="margin-bottom: 16px"
    />

    <a-table
      :columns="columns"
      :data-source="tables"
      :loading="loading"
      row-key="id"
      :pagination="false"
      :row-selection="{ selectedRowKeys, onChange: onSelectChange }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'is_active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">
            {{ record.is_active ? '啟用' : '停用' }}
          </a-tag>
        </template>
        <template v-if="column.key === 'token'">
          <a-typography-text code copyable :content="record.public_token" />
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="showQr(record)">
              <template #icon><QrcodeOutlined /></template>QR
            </a-button>
            <a-button size="small" @click="openEdit(record)">編輯</a-button>
            <a-popconfirm
              title="重設 token 會作廢已印出的 QR，確定？"
              @confirm="rotate(record.id)"
            >
              <a-button size="small">重設 token</a-button>
            </a-popconfirm>
            <a-popconfirm title="確定刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="formOpen"
      :title="editingId ? '編輯桌位' : '新增桌位'"
      @ok="handleSave"
      :confirm-loading="saving"
    >
      <a-form :model="form" layout="vertical">
        <a-form-item label="門店" :required="!editingId">
          <a-select
            v-model:value="form.store_id"
            :options="storeOptions"
            :disabled="!!editingId"
            placeholder="選擇門店"
          />
        </a-form-item>
        <a-form-item label="桌號" required>
          <a-input v-model:value="form.label" placeholder="例：A3、吧台 1" />
        </a-form-item>
        <a-form-item label="座位數">
          <a-input-number v-model:value="form.seats" :min="1" :max="50" />
        </a-form-item>
        <a-form-item label="備註">
          <a-input v-model:value="form.note" />
        </a-form-item>
        <a-form-item v-if="editingId">
          <a-checkbox v-model:checked="form.is_active">啟用</a-checkbox>
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal
      v-model:open="qrOpen"
      :title="`桌 ${qrTarget?.label} QR`"
      :footer="null"
      width="380px"
    >
      <div v-if="qrTarget" class="qr-modal-body" ref="qrPrintRoot">
        <div class="qr-block">
          <div class="store-line">{{ storeNameOf(qrTarget.store_id) }}</div>
          <div class="table-line">桌 {{ qrTarget.label }}</div>
          <div class="qr-image">
            <qrcode-vue :value="urlFor(qrTarget)" :size="220" level="M" />
          </div>
          <div class="hint-line">掃我點餐</div>
          <div class="url-line">{{ urlFor(qrTarget) }}</div>
        </div>
        <a-button type="primary" block @click="printSingle">
          <template #icon><PrinterOutlined /></template>列印此桌
        </a-button>
      </div>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { useRouter } from 'vue-router'
import { PrinterOutlined, QrcodeOutlined } from '@ant-design/icons-vue'
import QrcodeVue from 'qrcode.vue'
import {
  listTables,
  createTable,
  updateTable,
  deleteTable,
  rotateTableToken,
} from '@/api/tables'
import { listStores } from '@/api/stores'
import type { DiningTableRead, StoreRead } from '@/types'

const router = useRouter()

const tables = ref<DiningTableRead[]>([])
const stores = ref<StoreRead[]>([])
const loading = ref(false)
const storeFilter = ref<string | undefined>(undefined)
const includeInactive = ref(false)

const selectedRowKeys = ref<string[]>([])

const formOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)
const form = reactive({
  store_id: undefined as string | undefined,
  label: '',
  seats: undefined as number | undefined,
  note: '',
  is_active: true,
})

const qrOpen = ref(false)
const qrTarget = ref<DiningTableRead | null>(null)
const qrPrintRoot = ref<HTMLElement | null>(null)

const storeOptions = computed(() =>
  stores.value.map((s) => ({ label: `${s.code} ${s.name}`, value: s.id })),
)

const columns = [
  { title: '桌號', dataIndex: 'label', width: 120 },
  { title: '座位', dataIndex: 'seats', width: 80 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: 'public token', key: 'token', width: 240 },
  { title: '備註', dataIndex: 'note' },
  { title: '操作', key: 'actions', width: 360 },
]

const customerBase = (import.meta.env.VITE_CUSTOMER_BASE_URL || 'http://localhost:5174').replace(
  /\/+$/,
  '',
)

function urlFor(t: DiningTableRead) {
  return `${customerBase}/order?t=${t.public_token}`
}

function storeNameOf(storeId: string) {
  return stores.value.find((s) => s.id === storeId)?.name || ''
}

async function fetchStores() {
  const { data } = await listStores()
  stores.value = data
  if (!storeFilter.value && data.length) storeFilter.value = data[0].id
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listTables({
      store_id: storeFilter.value,
      include_inactive: includeInactive.value,
    })
    tables.value = data
    selectedRowKeys.value = []
  } finally {
    loading.value = false
  }
}

function onSelectChange(keys: (string | number)[]) {
  selectedRowKeys.value = keys.map(String)
}

function openCreate() {
  editingId.value = null
  form.store_id = storeFilter.value
  form.label = ''
  form.seats = undefined
  form.note = ''
  form.is_active = true
  formOpen.value = true
}

function openEdit(record: DiningTableRead) {
  editingId.value = record.id
  form.store_id = record.store_id
  form.label = record.label
  form.seats = record.seats ?? undefined
  form.note = record.note ?? ''
  form.is_active = record.is_active
  formOpen.value = true
}

async function handleSave() {
  if (!form.label) {
    message.error('請輸入桌號')
    return
  }
  saving.value = true
  try {
    if (editingId.value) {
      await updateTable(editingId.value, {
        label: form.label,
        seats: form.seats ?? null,
        note: form.note || null,
        is_active: form.is_active,
      })
      message.success('已更新')
    } else {
      if (!form.store_id) {
        message.error('請選擇門店')
        return
      }
      await createTable({
        store_id: form.store_id,
        label: form.label,
        seats: form.seats ?? null,
        note: form.note || null,
      })
      message.success('已建立')
    }
    formOpen.value = false
    await fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    saving.value = false
  }
}

async function rotate(id: string) {
  await rotateTableToken(id)
  message.success('已重設 token，請重新列印 QR')
  await fetchData()
}

async function handleDelete(id: string) {
  await deleteTable(id)
  message.success('已刪除')
  await fetchData()
}

function showQr(record: DiningTableRead) {
  qrTarget.value = record
  qrOpen.value = true
}

function printSingle() {
  if (!qrTarget.value) return
  router.push({ name: 'tables-print', query: { ids: qrTarget.value.id } })
}

function printSelected() {
  if (!selectedRowKeys.value.length) return
  router.push({ name: 'tables-print', query: { ids: selectedRowKeys.value.join(',') } })
}

onMounted(async () => {
  await fetchStores()
  await fetchData()
})
</script>

<style scoped>
.qr-modal-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}
.qr-block {
  border: 1px dashed #d9d9d9;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
  width: 100%;
}
.store-line {
  font-size: 14px;
  color: #555;
}
.table-line {
  font-size: 28px;
  font-weight: 700;
  margin: 4px 0 12px;
}
.qr-image {
  display: flex;
  justify-content: center;
  margin-bottom: 8px;
}
.hint-line {
  font-size: 14px;
  letter-spacing: 4px;
  color: #444;
}
.url-line {
  font-size: 11px;
  color: #999;
  word-break: break-all;
  margin-top: 4px;
}
</style>
