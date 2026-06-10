<template>
  <div>
    <a-page-header title="市集 Banner／活動">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增 Banner</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="banners" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'image'">
          <a-image v-if="record.image_url" :src="record.image_url" :width="96" />
          <span v-else>-</span>
        </template>
        <template v-else-if="column.key === 'link'">
          <span>{{ linkLabel(record) }}</span>
        </template>
        <template v-else-if="column.key === 'active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '啟用' : '停用' }}</a-tag>
        </template>
        <template v-else-if="column.key === 'window'">
          <span style="font-size: 12px; color: #888">{{ windowLabel(record) }}</span>
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-popconfirm title="確定要刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" :title="editingId ? '編輯 Banner' : '新增 Banner'" @ok="handleSave" :confirm-loading="saving">
      <a-form :model="form" layout="vertical">
        <a-form-item label="標題" :rules="[{ required: true }]">
          <a-input v-model:value="form.title" />
        </a-form-item>
        <a-form-item label="副標題">
          <a-input v-model:value="form.subtitle" />
        </a-form-item>
        <a-form-item label="圖片">
          <a-upload :before-upload="handleUpload" :show-upload-list="false" accept="image/*">
            <a-button :loading="uploading">上傳圖片</a-button>
          </a-upload>
          <a-input v-model:value="form.image_url" placeholder="或直接填入圖片 URL" style="margin-top: 8px" />
          <a-image v-if="form.image_url" :src="form.image_url" :width="160" style="margin-top: 8px" />
        </a-form-item>
        <a-form-item label="點擊連結類型">
          <a-select v-model:value="form.link_type" style="width: 100%">
            <a-select-option value="none">無</a-select-option>
            <a-select-option value="store">前往商家（slug）</a-select-option>
            <a-select-option value="cuisine">篩選類型（cuisine tag）</a-select-option>
            <a-select-option value="external">外部連結（URL）</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item v-if="form.link_type !== 'none'" :label="targetLabel">
          <a-input v-model:value="form.link_target" :placeholder="targetPlaceholder" />
        </a-form-item>
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="排序">
              <a-input-number v-model:value="form.sort_order" :min="0" style="width: 100%" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="啟用">
              <a-switch v-model:checked="form.is_active" />
            </a-form-item>
          </a-col>
        </a-row>
        <a-form-item label="上架時間（選填）">
          <a-date-picker
            v-model:value="form.starts_at"
            show-time
            value-format="YYYY-MM-DDTHH:mm:ss"
            style="width: 100%"
            placeholder="開始"
          />
        </a-form-item>
        <a-form-item label="下架時間（選填）">
          <a-date-picker
            v-model:value="form.ends_at"
            show-time
            value-format="YYYY-MM-DDTHH:mm:ss"
            style="width: 100%"
            placeholder="結束"
          />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  listMarketplaceBanners,
  createMarketplaceBanner,
  updateMarketplaceBanner,
  deleteMarketplaceBanner,
  uploadPlatformImage,
  type MarketplaceBanner,
} from '@/api/platform'

const banners = ref<MarketplaceBanner[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const uploading = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  title: '',
  subtitle: '' as string | null,
  image_url: '',
  link_type: 'none',
  link_target: '' as string | null,
  sort_order: 0,
  is_active: true,
  starts_at: null as string | null,
  ends_at: null as string | null,
})

const columns = [
  { title: '圖片', key: 'image', width: 120 },
  { title: '標題', dataIndex: 'title', key: 'title' },
  { title: '連結', key: 'link' },
  { title: '排序', dataIndex: 'sort_order', key: 'sort_order', width: 80 },
  { title: '狀態', key: 'active', width: 90 },
  { title: '檔期', key: 'window' },
  { title: '操作', key: 'actions', width: 160 },
]

const LINK_LABELS: Record<string, string> = {
  none: '無',
  store: '商家',
  cuisine: '類型',
  external: '外部連結',
}

const targetLabel = computed(() => {
  if (form.link_type === 'store') return '商家 slug'
  if (form.link_type === 'cuisine') return 'cuisine tag'
  return '外部 URL'
})
const targetPlaceholder = computed(() => {
  if (form.link_type === 'store') return '例如 my-store'
  if (form.link_type === 'cuisine') return '例如 飲料'
  return 'https://...'
})

function linkLabel(record: MarketplaceBanner) {
  const base = LINK_LABELS[record.link_type] || record.link_type
  return record.link_target ? `${base}：${record.link_target}` : base
}

function windowLabel(record: MarketplaceBanner) {
  const fmt = (s: string | null) => (s ? s.replace('T', ' ').slice(0, 16) : '—')
  if (!record.starts_at && !record.ends_at) return '長期'
  return `${fmt(record.starts_at)} ~ ${fmt(record.ends_at)}`
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listMarketplaceBanners()
    banners.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: MarketplaceBanner) {
  if (record) {
    editingId.value = record.id
    form.title = record.title
    form.subtitle = record.subtitle
    form.image_url = record.image_url
    form.link_type = record.link_type
    form.link_target = record.link_target
    form.sort_order = record.sort_order
    form.is_active = record.is_active
    form.starts_at = record.starts_at
    form.ends_at = record.ends_at
  } else {
    editingId.value = null
    form.title = ''
    form.subtitle = ''
    form.image_url = ''
    form.link_type = 'none'
    form.link_target = ''
    form.sort_order = 0
    form.is_active = true
    form.starts_at = null
    form.ends_at = null
  }
  modalOpen.value = true
}

async function handleUpload(file: File) {
  uploading.value = true
  try {
    const { data } = await uploadPlatformImage(file)
    form.image_url = data.url
    message.success('圖片上傳成功')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '上傳失敗')
  } finally {
    uploading.value = false
  }
  return false
}

async function handleSave() {
  if (!form.title.trim() || !form.image_url.trim()) {
    message.error('請填寫標題與圖片')
    return
  }
  saving.value = true
  const payload = {
    title: form.title,
    subtitle: form.subtitle || null,
    image_url: form.image_url,
    link_type: form.link_type,
    link_target: form.link_type === 'none' ? null : form.link_target || null,
    sort_order: form.sort_order,
    is_active: form.is_active,
    starts_at: form.starts_at,
    ends_at: form.ends_at,
  }
  try {
    if (editingId.value) {
      await updateMarketplaceBanner(editingId.value, payload)
      message.success('已更新')
    } else {
      await createMarketplaceBanner(payload)
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
    await deleteMarketplaceBanner(id)
    message.success('已刪除')
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '刪除失敗')
  }
}

onMounted(fetchData)
</script>
