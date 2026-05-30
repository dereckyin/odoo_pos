<template>
  <div>
    <a-page-header title="會員等級管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增等級</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="levels" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'discount_rate'">
          {{ record.discount_rate < 1 ? `${((1 - record.discount_rate) * 100).toFixed(0)}% off` : '無折扣' }}
        </template>
        <template v-if="column.key === 'color'">
          <div v-if="record.color" :style="{ width: '24px', height: '24px', borderRadius: '4px', background: record.color }" />
          <span v-else>-</span>
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

    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯等級' : '新增等級'" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="等級名稱"><a-input v-model:value="form.name" /></a-form-item>
        <a-form-item label="折扣率 (0~1, 例如 0.9 = 9折)">
          <a-input-number v-model:value="form.discount_rate" :min="0" :max="1" :step="0.05" style="width: 160px" />
        </a-form-item>
        <a-form-item label="升等最低消費"><a-input-number v-model:value="form.min_spend" :min="0" style="width: 200px" /></a-form-item>
        <a-form-item label="升等最低點數"><a-input-number v-model:value="form.min_points" :min="0" style="width: 200px" /></a-form-item>
        <a-form-item label="排序"><a-input-number v-model:value="form.sort_order" :min="0" style="width: 120px" /></a-form-item>
        <a-form-item label="顏色"><a-input v-model:value="form.color" placeholder="#FF5733" style="width: 160px" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listMemberLevels, createMemberLevel, updateMemberLevel, deleteMemberLevel } from '@/api/members'
import type { MemberLevelRead } from '@/types'

const levels = ref<MemberLevelRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  name: '',
  discount_rate: 1.0,
  min_spend: 0,
  min_points: 0,
  color: null as string | null,
  sort_order: 0,
})

const columns = [
  { title: '名稱', dataIndex: 'name' },
  { title: '折扣', key: 'discount_rate', width: 120 },
  { title: '最低消費', dataIndex: 'min_spend', width: 120 },
  { title: '最低點數', dataIndex: 'min_points', width: 120 },
  { title: '顏色', key: 'color', width: 80 },
  { title: '排序', dataIndex: 'sort_order', width: 80 },
  { title: '操作', key: 'actions', width: 140 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listMemberLevels()
    levels.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: MemberLevelRead) {
  editingId.value = record?.id ?? null
  form.name = record?.name ?? ''
  form.discount_rate = record?.discount_rate ?? 1.0
  form.min_spend = record?.min_spend ?? 0
  form.min_points = record?.min_points ?? 0
  form.color = record?.color ?? null
  form.sort_order = record?.sort_order ?? 0
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingId.value) {
      await updateMemberLevel(editingId.value, { ...form })
    } else {
      await createMemberLevel({ ...form })
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
    await deleteMemberLevel(id)
    message.success('已刪除')
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '刪除失敗')
  }
}

onMounted(fetchData)
</script>
