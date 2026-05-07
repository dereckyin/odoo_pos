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
          {{ ((1 - record.discount_rate) * 100).toFixed(0) }}% off
        </template>
        <template v-if="column.key === 'color'">
          <div v-if="record.color" :style="{ width: '24px', height: '24px', borderRadius: '4px', background: record.color }" />
          <span v-else>-</span>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" title="新增等級" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="等級名稱">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="折扣率 (0~1, 例如 0.9 = 9折)">
          <a-input-number v-model:value="form.discount_rate" :min="0" :max="1" :step="0.05" style="width: 160px" />
        </a-form-item>
        <a-form-item label="升等最低消費 (分)">
          <a-input-number v-model:value="form.min_spend" :min="0" style="width: 200px" />
        </a-form-item>
        <a-form-item label="升等最低點數">
          <a-input-number v-model:value="form.min_points" :min="0" style="width: 200px" />
        </a-form-item>
        <a-form-item label="顏色">
          <a-input v-model:value="form.color" placeholder="#FF5733" style="width: 160px" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listMemberLevels, createMemberLevel } from '@/api/members'
import type { MemberLevelRead } from '@/types'

const levels = ref<MemberLevelRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)

const form = reactive({
  name: '',
  discount_rate: 1.0,
  min_spend: 0,
  min_points: 0,
  color: null as string | null,
})

const columns = [
  { title: '名稱', dataIndex: 'name' },
  { title: '折扣', key: 'discount_rate', width: 120 },
  { title: '最低消費', dataIndex: 'min_spend', width: 120 },
  { title: '最低點數', dataIndex: 'min_points', width: 120 },
  { title: '顏色', key: 'color', width: 80 },
  { title: '排序', dataIndex: 'sort_order', width: 80 },
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

function openModal() {
  form.name = ''
  form.discount_rate = 1.0
  form.min_spend = 0
  form.min_points = 0
  form.color = null
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    await createMemberLevel({ ...form })
    message.success('已建立')
    modalOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    saving.value = false
  }
}

onMounted(fetchData)
</script>
