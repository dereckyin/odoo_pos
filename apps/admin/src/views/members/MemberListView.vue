<template>
  <div>
    <a-page-header title="會員列表">
      <template #extra>
        <a-button type="primary" @click="openCreate">新增會員</a-button>
      </template>
    </a-page-header>

    <a-input-search v-model:value="search" placeholder="搜尋姓名/電話" style="width: 300px; margin-bottom: 16px" allow-clear @search="fetchData" />

    <a-table :columns="columns" :data-source="members" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'total_spent'">
          {{ formatMoney(record.total_spent_cents) }}
        </template>
        <template v-if="column.key === 'level'">
          {{ levelMap[record.level_id] || '-' }}
        </template>
        <template v-if="column.key === 'actions'">
          <a-button size="small" @click="$router.push({ name: 'member-detail', params: { id: record.id } })">查看</a-button>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="createOpen" title="新增會員" @ok="handleCreate" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="手機" required><a-input v-model:value="form.phone" /></a-form-item>
        <a-form-item label="姓名" required><a-input v-model:value="form.name" /></a-form-item>
        <a-form-item label="Email"><a-input v-model:value="form.email" /></a-form-item>
        <a-form-item label="等級">
          <a-select v-model:value="form.level_id" allow-clear placeholder="選擇等級">
            <a-select-option v-for="l in levels" :key="l.id" :value="l.id">{{ l.name }}</a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listMembers, listMemberLevels, createMember } from '@/api/members'
import { formatMoney } from '@/utils/formatMoney'
import type { MemberRead, MemberLevelRead } from '@/types'

const members = ref<MemberRead[]>([])
const levels = ref<MemberLevelRead[]>([])
const loading = ref(false)
const saving = ref(false)
const search = ref('')
const createOpen = ref(false)
const form = reactive({ phone: '', name: '', email: null as string | null, level_id: null as string | null })

const levelMap = computed(() => {
  const map: Record<string, string> = {}
  levels.value.forEach(l => { map[l.id] = l.name })
  return map
})

const columns = [
  { title: '姓名', dataIndex: 'name', key: 'name' },
  { title: '電話', dataIndex: 'phone', key: 'phone' },
  { title: '等級', key: 'level', width: 100 },
  { title: '點數', dataIndex: 'points', key: 'points', width: 80 },
  { title: '累計消費', key: 'total_spent', width: 120 },
  { title: '操作', key: 'actions', width: 80 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listMembers({ q: search.value || undefined })
    members.value = data
  } finally {
    loading.value = false
  }
}

function openCreate() {
  form.phone = ''
  form.name = ''
  form.email = null
  form.level_id = null
  createOpen.value = true
}

async function handleCreate() {
  if (!form.phone || !form.name) return message.warning('請填寫手機與姓名')
  saving.value = true
  try {
    await createMember({ phone: form.phone, name: form.name, email: form.email, level_id: form.level_id })
    message.success('已建立')
    createOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '建立失敗')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const { data } = await listMemberLevels()
  levels.value = data
  fetchData()
})
</script>
