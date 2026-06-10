<template>
  <div>
    <a-page-header title="分類管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增頂層分類</a-button>
      </template>
    </a-page-header>

    <a-table
      :columns="columns"
      :data-source="treeData"
      :loading="loading"
      row-key="id"
      :pagination="false"
      :default-expand-all-rows="true"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'name'">
          <span>{{ record.name }}</span>
          <a-tag v-if="record.depth === 2" color="blue" style="margin-left: 8px">第3層</a-tag>
        </template>
        <template v-if="column.key === 'path'">
          <span style="color: #888">{{ record.path_label || record.name }}</span>
        </template>
        <template v-if="column.key === 'color'">
          <div v-if="record.color" :style="{ width: '24px', height: '24px', borderRadius: '4px', background: record.color }" />
          <span v-else>-</span>
        </template>
        <template v-if="column.key === 'hp'">
          <span>{{ record.hide_from_public_ordering ? '是' : '' }}</span>
        </template>
        <template v-if="column.key === 'hb'">
          <span>{{ record.hide_from_pos_browse ? '是' : '' }}</span>
        </template>
        <template v-if="column.key === 'actions'">
          <a-space>
            <a-button
              size="small"
              :disabled="(record.depth ?? 0) >= 2"
              @click="openModal(undefined, record.id)"
            >
              新增子分類
            </a-button>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-popconfirm title="確定要刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="modalTitle" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="名稱" :rules="[{ required: true }]">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="上層分類">
          <a-tree-select
            v-model:value="form.parent_id"
            allow-clear
            placeholder="無（頂層）"
            tree-default-expand-all
            :tree-data="parentTreeOptions"
            :field-names="{ label: 'path_label', value: 'id', children: 'children' }"
            style="width: 100%"
          />
        </a-form-item>
        <a-form-item label="排序">
          <a-input-number v-model:value="form.sort_order" :min="0" style="width: 120px" />
        </a-form-item>
        <a-form-item label="顏色">
          <a-input v-model:value="form.color" placeholder="#FF5733" style="width: 160px" />
        </a-form-item>
        <a-form-item label="圖示">
          <a-input v-model:value="form.icon" placeholder="選填" />
        </a-form-item>
        <a-form-item label="QR／桌邊菜單隱藏整個分類">
          <a-switch v-model:checked="form.hide_from_public_ordering" />
        </a-form-item>
        <a-form-item label="POS「全部」隱藏此分類內商品">
          <a-switch v-model:checked="form.hide_from_pos_browse" />
          <div style="color: #888; font-size: 12px">店員仍可點進此分類或掃碼結帳。</div>
        </a-form-item>
        <a-divider style="margin: 12px 0">會員適用規則（子分類／商品可繼承）</a-divider>
        <a-form-item label="可享會員折扣">
          <a-switch v-model:checked="form.member_discount_eligible" />
          <div style="color: #888; font-size: 12px">關閉後此分類（含子分類）商品不計會員等級折扣。</div>
        </a-form-item>
        <a-form-item label="可累積點數">
          <a-switch v-model:checked="form.points_earn_eligible" />
        </a-form-item>
        <a-form-item label="可使用點數折抵">
          <a-switch v-model:checked="form.points_redeem_eligible" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  listCategoriesTree,
  createCategory,
  updateCategory,
  deleteCategory,
} from '@/api/products'
import type { CategoryRead, CategoryTreeNode } from '@/types'

const treeData = ref<CategoryTreeNode[]>([])
const flatCategories = ref<CategoryRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)
const presetParentId = ref<string | null>(null)

const form = reactive({
  name: '',
  parent_id: null as string | null,
  sort_order: 0,
  color: null as string | null,
  icon: null as string | null,
  hide_from_public_ordering: false,
  hide_from_pos_browse: false,
  member_discount_eligible: true,
  points_earn_eligible: true,
  points_redeem_eligible: true,
})

const columns = [
  { title: '名稱', key: 'name' },
  { title: '完整路徑', key: 'path' },
  { title: '排序', dataIndex: 'sort_order', key: 'sort_order', width: 80 },
  { title: '顏色', key: 'color', width: 80 },
  { title: 'QR隱藏', key: 'hp', width: 72 },
  { title: 'POS全部隱藏', key: 'hb', width: 100 },
  { title: '操作', key: 'actions', width: 280 },
]

const modalTitle = computed(() => {
  if (editingId.value) return '編輯分類'
  if (presetParentId.value) return '新增子分類'
  return '新增頂層分類'
})

function flattenTree(nodes: CategoryTreeNode[], out: CategoryRead[] = []) {
  for (const n of nodes) {
    out.push(n)
    if (n.children?.length) flattenTree(n.children, out)
  }
  return out
}

function filterParentOptions(nodes: CategoryTreeNode[], excludeId: string | null): CategoryTreeNode[] {
  return nodes
    .filter((n) => n.id !== excludeId && (n.depth ?? 0) < 2)
    .map((n) => ({
      ...n,
      path_label: n.path_label || n.name,
      children: n.children?.length ? filterParentOptions(n.children, excludeId) : [],
    }))
}

const parentTreeOptions = computed(() => filterParentOptions(treeData.value, editingId.value))

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listCategoriesTree()
    treeData.value = data
    flatCategories.value = flattenTree(data)
  } finally {
    loading.value = false
  }
}

function openModal(record?: CategoryRead, parentId?: string) {
  presetParentId.value = parentId ?? null
  if (record) {
    editingId.value = record.id
    form.name = record.name
    form.parent_id = record.parent_id
    form.sort_order = record.sort_order
    form.color = record.color
    form.icon = record.icon
    form.hide_from_public_ordering = record.hide_from_public_ordering ?? false
    form.hide_from_pos_browse = record.hide_from_pos_browse ?? false
    form.member_discount_eligible = record.member_discount_eligible ?? true
    form.points_earn_eligible = record.points_earn_eligible ?? true
    form.points_redeem_eligible = record.points_redeem_eligible ?? true
  } else {
    editingId.value = null
    form.name = ''
    form.parent_id = parentId ?? null
    form.sort_order = 0
    form.color = null
    form.icon = null
    form.hide_from_public_ordering = false
    form.hide_from_pos_browse = false
    form.member_discount_eligible = true
    form.points_earn_eligible = true
    form.points_redeem_eligible = true
  }
  modalOpen.value = true
}

async function handleSave() {
  saving.value = true
  try {
    if (editingId.value) {
      await updateCategory(editingId.value, { ...form })
      message.success('已更新')
    } else {
      await createCategory({ ...form })
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
  try {
    await deleteCategory(id)
    message.success('已刪除')
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '刪除失敗')
  }
}

onMounted(fetchData)
</script>
