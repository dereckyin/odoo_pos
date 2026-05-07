<template>
  <div>
    <a-page-header title="會員列表" />

    <a-input-search v-model:value="search" placeholder="搜尋姓名/電話" style="width: 300px; margin-bottom: 16px" allow-clear @search="fetchData" />

    <a-table :columns="columns" :data-source="members" :loading="loading" row-key="id">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'total_spent'">
          ${{ (record.total_spent_cents / 100).toFixed(0) }}
        </template>
        <template v-if="column.key === 'level'">
          {{ levelMap[record.level_id] || '-' }}
        </template>
        <template v-if="column.key === 'actions'">
          <a-button size="small" @click="$router.push({ name: 'member-detail', params: { id: record.id } })">查看</a-button>
        </template>
      </template>
    </a-table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { listMembers, listMemberLevels } from '@/api/members'
import type { MemberRead, MemberLevelRead } from '@/types'

const members = ref<MemberRead[]>([])
const levels = ref<MemberLevelRead[]>([])
const loading = ref(false)
const search = ref('')

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

onMounted(async () => {
  const { data } = await listMemberLevels()
  levels.value = data
  fetchData()
})
</script>
