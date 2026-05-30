<template>
  <div>
    <a-page-header title="選項庫管理">
      <template #extra>
        <a-space>
          <a-button @click="seedTemplate" :loading="seeding">匯入飲料店範本</a-button>
          <a-button type="primary" @click="openGroupModal()">新增選項群組</a-button>
        </a-space>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="groups" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'type'">
          {{ record.selection_type === 'multi' ? '多選' : '單選' }}
          <span v-if="record.is_required" style="color: #f5222d"> *</span>
        </template>
        <template v-if="column.key === 'choices'">
          {{ record.choices?.length ?? 0 }} 項
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openGroupModal(record)">編輯</a-button>
            <a-button size="small" @click="openChoices(record)">選項值</a-button>
            <a-popconfirm title="確定刪除？" @confirm="handleDeleteGroup(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="groupModalOpen" :title="editingGroupId ? '編輯選項群組' : '新增選項群組'" @ok="saveGroup" :confirm-loading="saving">
      <a-form :model="groupForm" layout="vertical">
        <a-form-item label="名稱" required>
          <a-input v-model:value="groupForm.name" placeholder="甜度、冰塊、加料…" />
        </a-form-item>
        <a-form-item label="選擇方式">
          <a-radio-group v-model:value="groupForm.selection_type">
            <a-radio value="single">單選</a-radio>
            <a-radio value="multi">多選</a-radio>
          </a-radio-group>
        </a-form-item>
        <a-form-item label="必選">
          <a-switch v-model:checked="groupForm.is_required" />
        </a-form-item>
        <a-form-item v-if="groupForm.selection_type === 'multi'" label="最少 / 最多選幾項">
          <a-space>
            <a-input-number v-model:value="groupForm.min_selections" :min="0" />
            <a-input-number v-model:value="groupForm.max_selections" :min="1" placeholder="不限" />
          </a-space>
        </a-form-item>
        <a-form-item label="排序">
          <a-input-number v-model:value="groupForm.sort_order" :min="0" />
        </a-form-item>
      </a-form>
    </a-modal>

    <a-drawer v-model:open="choicesDrawerOpen" :title="`選項值：${activeGroup?.name ?? ''}`" width="520">
      <a-button type="dashed" block style="margin-bottom: 12px" @click="openChoiceModal()">+ 新增選項</a-button>
      <a-table :data-source="activeGroup?.choices ?? []" :pagination="false" row-key="id" size="small">
        <a-table-column title="名稱" data-index="name" />
        <a-table-column title="加價(元)" key="price">
          <template #default="{ record }">{{ Math.round(record.price_delta_cents) }}</template>
        </a-table-column>
        <a-table-column title="預設" key="def">
          <template #default="{ record }">{{ record.is_default ? '是' : '' }}</template>
        </a-table-column>
        <a-table-column title="操作" key="act">
          <template #default="{ record }">
            <a-space>
              <a-button size="small" @click="openChoiceModal(record)">編輯</a-button>
              <a-popconfirm title="刪除？" @confirm="deleteChoice(record.id)">
                <a-button size="small" danger>刪</a-button>
              </a-popconfirm>
            </a-space>
          </template>
        </a-table-column>
      </a-table>
    </a-drawer>

    <a-modal v-model:open="choiceModalOpen" :title="editingChoiceId ? '編輯選項' : '新增選項'" @ok="saveChoice" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="名稱" required><a-input v-model:value="choiceForm.name" /></a-form-item>
        <a-form-item label="加價 (元)"><a-input-number v-model:value="choiceForm.price_yuan" :min="0" /></a-form-item>
        <a-form-item label="預設選中"><a-switch v-model:checked="choiceForm.is_default" /></a-form-item>
        <a-form-item label="排序"><a-input-number v-model:value="choiceForm.sort_order" :min="0" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  listOptionGroups,
  createOptionGroup,
  updateOptionGroup,
  deleteOptionGroup,
  createOptionChoice,
  updateOptionChoice,
  deleteOptionChoice,
  seedDrinkShopTemplate,
} from '@/api/options'
import type { OptionGroupRead, OptionChoiceRead } from '@/types'

const groups = ref<OptionGroupRead[]>([])
const loading = ref(false)
const saving = ref(false)
const seeding = ref(false)
const groupModalOpen = ref(false)
const choicesDrawerOpen = ref(false)
const choiceModalOpen = ref(false)
const editingGroupId = ref<string | null>(null)
const editingChoiceId = ref<string | null>(null)
const activeGroup = ref<OptionGroupRead | null>(null)

const groupForm = reactive({
  name: '',
  selection_type: 'single' as 'single' | 'multi',
  is_required: true,
  min_selections: 0,
  max_selections: null as number | null,
  sort_order: 0,
})

const choiceForm = reactive({
  name: '',
  price_yuan: 0,
  is_default: false,
  sort_order: 0,
})

const columns = [
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '類型', key: 'type', width: 100 },
  { title: '選項數', key: 'choices', width: 80 },
  { title: '排序', dataIndex: 'sort_order', key: 'sort_order', width: 72 },
  { title: '操作', key: 'actions', width: 220 },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listOptionGroups()
    groups.value = data
  } finally {
    loading.value = false
  }
}

function openGroupModal(record?: OptionGroupRead) {
  editingGroupId.value = record?.id ?? null
  groupForm.name = record?.name ?? ''
  groupForm.selection_type = record?.selection_type ?? 'single'
  groupForm.is_required = record?.is_required ?? true
  groupForm.min_selections = record?.min_selections ?? 0
  groupForm.max_selections = record?.max_selections ?? null
  groupForm.sort_order = record?.sort_order ?? 0
  groupModalOpen.value = true
}

async function saveGroup() {
  if (!groupForm.name.trim()) {
    message.error('請輸入名稱')
    return
  }
  saving.value = true
  try {
    const payload = { ...groupForm, name: groupForm.name.trim() }
    if (editingGroupId.value) {
      await updateOptionGroup(editingGroupId.value, payload)
    } else {
      await createOptionGroup(payload)
    }
    groupModalOpen.value = false
    await fetchData()
    message.success('已儲存')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

async function handleDeleteGroup(id: string) {
  await deleteOptionGroup(id)
  await fetchData()
}

function openChoices(record: OptionGroupRead) {
  activeGroup.value = record
  choicesDrawerOpen.value = true
}

function openChoiceModal(record?: OptionChoiceRead) {
  editingChoiceId.value = record?.id ?? null
  choiceForm.name = record?.name ?? ''
  choiceForm.price_yuan = record ? Math.round(record.price_delta_cents) : 0
  choiceForm.is_default = record?.is_default ?? false
  choiceForm.sort_order = record?.sort_order ?? 0
  choiceModalOpen.value = true
}

async function saveChoice() {
  if (!activeGroup.value) return
  if (!choiceForm.name.trim()) {
    message.error('請輸入名稱')
    return
  }
  saving.value = true
  try {
    const payload = {
      name: choiceForm.name.trim(),
      price_delta_cents: Math.round(choiceForm.price_yuan),
      is_default: choiceForm.is_default,
      sort_order: choiceForm.sort_order,
    }
    if (editingChoiceId.value) {
      await updateOptionChoice(activeGroup.value.id, editingChoiceId.value, payload)
    } else {
      await createOptionChoice(activeGroup.value.id, payload)
    }
    choiceModalOpen.value = false
    await fetchData()
    activeGroup.value = groups.value.find((g) => g.id === activeGroup.value!.id) ?? null
    message.success('已儲存')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

async function deleteChoice(choiceId: string) {
  if (!activeGroup.value) return
  await deleteOptionChoice(activeGroup.value.id, choiceId)
  await fetchData()
  activeGroup.value = groups.value.find((g) => g.id === activeGroup.value!.id) ?? null
}

async function seedTemplate() {
  seeding.value = true
  try {
    await seedDrinkShopTemplate()
    await fetchData()
    message.success('已建立飲料店範本選項')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '建立失敗')
  } finally {
    seeding.value = false
  }
}

onMounted(fetchData)
</script>
