<template>
  <div>
    <a-page-header title="活動管理">
      <template #extra>
        <a-space>
          <a-button @click="openCheckIn">票券核銷</a-button>
          <a-button type="primary" @click="openModal()">新增活動</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="events" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'time'">
          {{ formatTime(record.starts_at) }}
        </template>
        <template v-if="column.key === 'capacity'">
          {{ record.registered_count }} / {{ record.capacity || '∞' }}
        </template>
        <template v-if="column.key === 'price'">{{ formatMoney(record.price_cents) }}</template>
        <template v-if="column.key === 'is_published'">
          <a-tag :color="record.is_published ? 'green' : 'default'">
            {{ record.is_published ? '已發布' : '草稿' }}
          </a-tag>
          <a-tag v-if="record.list_on_marketplace" color="blue">市集</a-tag>
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-button size="small" @click="openRegistrations(record)">報名名單</a-button>
            <a-popconfirm title="確定刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <!-- Create / edit -->
    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯活動' : '新增活動'" @ok="handleSave" :confirm-loading="saving" width="640px">
      <a-form :model="form" layout="vertical">
        <a-form-item label="活動名稱" required><a-input v-model:value="form.title" /></a-form-item>
        <a-form-item label="說明"><a-textarea v-model:value="form.description" :rows="3" /></a-form-item>
        <a-form-item label="地點"><a-input v-model:value="form.location" /></a-form-item>
        <a-form-item label="圖片網址"><a-input v-model:value="form.image_url" /></a-form-item>
        <a-row :gutter="16">
          <a-col :span="12"><a-form-item label="開始時間"><a-date-picker v-model:value="form.starts_at" show-time style="width: 100%" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="結束時間"><a-date-picker v-model:value="form.ends_at" show-time style="width: 100%" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="12"><a-form-item label="名額上限 (0=不限)"><a-input-number v-model:value="form.capacity" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="票價 (元)"><a-input-number v-model:value="priceYuan" :min="0" style="width: 100%" /></a-form-item></a-col>
        </a-row>
        <a-space>
          <a-form-item label="發布"><a-switch v-model:checked="form.is_published" /></a-form-item>
          <a-form-item label="上架市集"><a-switch v-model:checked="form.list_on_marketplace" /></a-form-item>
        </a-space>
      </a-form>
    </a-modal>

    <!-- Registrations -->
    <a-drawer v-model:open="regOpen" :title="`報名名單：${activeEvent?.title ?? ''}`" width="640">
      <a-form layout="inline" style="margin-bottom: 16px" :model="regForm">
        <a-form-item label="姓名"><a-input v-model:value="regForm.name" /></a-form-item>
        <a-form-item label="電話"><a-input v-model:value="regForm.phone" /></a-form-item>
        <a-form-item label="數量"><a-input-number v-model:value="regForm.qty" :min="1" /></a-form-item>
        <a-form-item><a-button type="primary" :loading="addingReg" @click="addRegistration">新增報名</a-button></a-form-item>
      </a-form>
      <a-table :columns="regColumns" :data-source="registrations" :loading="loadingReg" row-key="id" size="small">
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'status'">
            <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
          </template>
          <template v-if="column.key === 'reg_actions'">
            <a-popconfirm
              v-if="record.status === 'registered'"
              title="取消此報名？"
              @confirm="cancelReg(record.id)"
            >
              <a-button size="small" danger>取消</a-button>
            </a-popconfirm>
          </template>
        </template>
      </a-table>
    </a-drawer>

    <!-- Check-in -->
    <a-modal v-model:open="checkInOpen" title="票券核銷" :footer="null">
      <a-input-search
        v-model:value="checkInCode"
        placeholder="輸入或掃描票券代碼"
        enter-button="核銷"
        :loading="checking"
        @search="doCheckIn"
      />
      <a-result
        v-if="checkInResult"
        status="success"
        :title="`核銷成功：${checkInResult.name}`"
        :sub-title="`票券 ${checkInResult.ticket_code}，數量 ${checkInResult.qty}`"
        style="padding: 16px 0"
      />
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import dayjs, { Dayjs } from 'dayjs'
import {
  listEvents, createEvent, updateEvent, deleteEvent,
  listRegistrations, createRegistration, checkInTicket, cancelRegistration,
  type EventRead, type RegistrationRead,
} from '@/api/events'
import { formatMoney } from '@/utils/formatMoney'

const events = ref<EventRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  title: '',
  description: '' as string | null,
  location: '' as string | null,
  image_url: '' as string | null,
  starts_at: null as Dayjs | null,
  ends_at: null as Dayjs | null,
  capacity: 0,
  price_cents: 0,
  is_published: false,
  list_on_marketplace: false,
})

const priceYuan = computed({
  get: () => Math.round(form.price_cents / 100),
  set: (v: number) => { form.price_cents = Math.round((v || 0) * 100) },
})

const columns = [
  { title: '活動', dataIndex: 'title' },
  { title: '時間', key: 'time', width: 170 },
  { title: '報名/名額', key: 'capacity', width: 110 },
  { title: '票價', key: 'price', width: 100 },
  { title: '狀態', key: 'is_published', width: 140 },
  { title: '操作', key: 'actions', width: 240 },
]

function formatTime(s: string | null) {
  return s ? dayjs(s).format('YYYY-MM-DD HH:mm') : '-'
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listEvents()
    events.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: EventRead) {
  editingId.value = record?.id ?? null
  form.title = record?.title ?? ''
  form.description = record?.description ?? ''
  form.location = record?.location ?? ''
  form.image_url = record?.image_url ?? ''
  form.starts_at = record?.starts_at ? dayjs(record.starts_at) : null
  form.ends_at = record?.ends_at ? dayjs(record.ends_at) : null
  form.capacity = record?.capacity ?? 0
  form.price_cents = record?.price_cents ?? 0
  form.is_published = record?.is_published ?? false
  form.list_on_marketplace = record?.list_on_marketplace ?? false
  modalOpen.value = true
}

async function handleSave() {
  if (!form.title.trim()) {
    message.error('請輸入活動名稱')
    return
  }
  saving.value = true
  try {
    const payload = {
      title: form.title,
      description: form.description || null,
      location: form.location || null,
      image_url: form.image_url || null,
      starts_at: form.starts_at ? form.starts_at.toISOString() : null,
      ends_at: form.ends_at ? form.ends_at.toISOString() : null,
      capacity: form.capacity,
      price_cents: form.price_cents,
      is_published: form.is_published,
      list_on_marketplace: form.list_on_marketplace,
    }
    if (editingId.value) {
      await updateEvent(editingId.value, payload)
    } else {
      await createEvent(payload)
    }
    message.success('已儲存')
    modalOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    saving.value = false
  }
}

async function handleDelete(id: string) {
  try {
    await deleteEvent(id)
    message.success('已刪除')
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '刪除失敗')
  }
}

// Registrations
const regOpen = ref(false)
const loadingReg = ref(false)
const addingReg = ref(false)
const activeEvent = ref<EventRead | null>(null)
const registrations = ref<RegistrationRead[]>([])
const regForm = reactive({ name: '', phone: '', qty: 1 })

const regColumns = [
  { title: '姓名', dataIndex: 'name' },
  { title: '電話', dataIndex: 'phone' },
  { title: '數量', dataIndex: 'qty', width: 70 },
  { title: '票券碼', dataIndex: 'ticket_code', width: 110 },
  { title: '狀態', key: 'status', width: 90 },
  { title: '操作', key: 'reg_actions', width: 90 },
]

function statusColor(s: string) {
  return s === 'checked_in' ? 'green' : s === 'cancelled' ? 'red' : 'blue'
}
function statusLabel(s: string) {
  return s === 'checked_in' ? '已核銷' : s === 'cancelled' ? '已取消' : '已報名'
}

async function openRegistrations(record: EventRead) {
  activeEvent.value = record
  regOpen.value = true
  await loadRegistrations()
}

async function loadRegistrations() {
  if (!activeEvent.value) return
  loadingReg.value = true
  try {
    const { data } = await listRegistrations(activeEvent.value.id)
    registrations.value = data
  } finally {
    loadingReg.value = false
  }
}

async function addRegistration() {
  if (!activeEvent.value || !regForm.name.trim()) {
    message.error('請輸入姓名')
    return
  }
  addingReg.value = true
  try {
    await createRegistration(activeEvent.value.id, {
      name: regForm.name, phone: regForm.phone || null, qty: regForm.qty,
    })
    regForm.name = ''
    regForm.phone = ''
    regForm.qty = 1
    message.success('已新增報名')
    await loadRegistrations()
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '新增失敗')
  } finally {
    addingReg.value = false
  }
}

async function cancelReg(id: string) {
  try {
    await cancelRegistration(id)
    message.success('已取消')
    await loadRegistrations()
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '取消失敗')
  }
}

// Check-in
const checkInOpen = ref(false)
const checkInCode = ref('')
const checking = ref(false)
const checkInResult = ref<RegistrationRead | null>(null)

function openCheckIn() {
  checkInCode.value = ''
  checkInResult.value = null
  checkInOpen.value = true
}

async function doCheckIn() {
  if (!checkInCode.value.trim()) return
  checking.value = true
  try {
    const { data } = await checkInTicket(checkInCode.value.trim())
    checkInResult.value = data
    checkInCode.value = ''
    message.success('核銷成功')
    if (regOpen.value) loadRegistrations()
    fetchData()
  } catch (e: any) {
    checkInResult.value = null
    message.error(e.response?.data?.detail || '核銷失敗')
  } finally {
    checking.value = false
  }
}

onMounted(fetchData)
</script>
