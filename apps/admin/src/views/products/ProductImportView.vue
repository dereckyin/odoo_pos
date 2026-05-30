<template>
  <div>
    <a-page-header title="CSV 批次匯入" @back="$router.push({ name: 'products' })" />

    <a-card title="欄位說明" style="margin-bottom: 16px">
      <a-table
        :columns="fieldColumns"
        :data-source="fieldRows"
        :pagination="false"
        size="small"
        row-key="field"
      />
      <a-alert
        type="info"
        show-icon
        style="margin-top: 16px"
        message="分類路徑須與「分類管理」中的完整路徑一致（例如：飲料 / 手搖 / 奶茶）。請先在分類管理建立對應分類後再匯入。"
      />
      <a-alert
        type="info"
        show-icon
        style="margin-top: 8px"
        message="品項選項（甜度、冰塊、加料等）不包含在 CSV 中，匯入後請至商品編輯頁綁定。"
      />
      <div style="margin-top: 16px">
        <a-button type="link" href="/templates/product-import-sample.csv" download="product-import-sample.csv">
          <DownloadOutlined /> 下載範例 CSV
        </a-button>
      </div>
    </a-card>

    <a-card>
      <a-upload-dragger
        :before-upload="handleUpload"
        :show-upload-list="false"
        accept=".csv"
      >
        <p class="ant-upload-drag-icon"><InboxOutlined /></p>
        <p class="ant-upload-text">點擊或拖曳 CSV 檔案至此處</p>
        <p class="ant-upload-hint">支援 UTF-8 CSV，欄位：sku, name, price_cents, category_path, barcode, is_weighted, unit</p>
      </a-upload-dragger>

      <a-spin v-if="importing" tip="匯入中..." style="margin-top: 24px" />

      <div v-if="result" style="margin-top: 24px">
        <a-result
          :status="result.status"
          :title="result.title"
          :sub-title="result.subTitle"
        >
          <template #extra>
            <a-button type="primary" @click="$router.push({ name: 'products' })">回商品列表</a-button>
          </template>
        </a-result>

        <a-table
          v-if="result.errors.length"
          :columns="errorColumns"
          :data-source="result.errors"
          :pagination="false"
          size="small"
          row-key="row"
          style="margin-top: 16px"
        />
      </div>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { DownloadOutlined, InboxOutlined } from '@ant-design/icons-vue'
import { importProductsCsv } from '@/api/products'

interface ImportError {
  row: number
  sku: string
  message: string
}

interface ImportResultState {
  status: 'success' | 'warning' | 'error'
  title: string
  subTitle: string
  errors: ImportError[]
}

const fieldColumns = [
  { title: '欄位', dataIndex: 'field', key: 'field', width: 140 },
  { title: '必填', dataIndex: 'required', key: 'required', width: 60 },
  { title: '說明', dataIndex: 'desc', key: 'desc' },
]

const fieldRows = [
  { field: 'sku', required: '是', desc: '商品編號；相同 SKU 視為更新' },
  { field: 'name', required: '否', desc: '商品名稱，空白則使用 sku' },
  { field: 'price_cents', required: '否', desc: '售價（分），預設 0' },
  { field: 'category_path', required: '否', desc: '多層分類路徑，以「 / 」分隔，須與後台分類管理完全一致' },
  { field: 'barcode', required: '否', desc: '主條碼' },
  { field: 'is_weighted', required: '否', desc: '1 / true / yes 表示計重商品' },
  { field: 'unit', required: '否', desc: '單位，預設「個」' },
]

const errorColumns = [
  { title: '列號', dataIndex: 'row', key: 'row', width: 80 },
  { title: 'SKU', dataIndex: 'sku', key: 'sku', width: 160 },
  { title: '錯誤訊息', dataIndex: 'message', key: 'message' },
]

const importing = ref(false)
const result = ref<ImportResultState | null>(null)

async function handleUpload(file: File) {
  importing.value = true
  result.value = null
  try {
    const { data } = await importProductsCsv(file)
    const errors: ImportError[] = data.errors ?? []
    const skipped = data.skipped ?? 0
    const created = data.created ?? 0
    const updated = data.updated ?? 0
    const hasSuccess = created + updated > 0
    result.value = {
      status: errors.length && hasSuccess ? 'warning' : errors.length ? 'error' : 'success',
      title: hasSuccess ? '匯入完成' : '匯入失敗',
      subTitle: `新增 ${created} 筆，更新 ${updated} 筆${skipped ? `，跳過 ${skipped} 筆` : ''}`,
      errors,
    }
  } catch (e: any) {
    result.value = {
      status: 'error',
      title: '匯入失敗',
      subTitle: e.response?.data?.detail || '請檢查 CSV 格式',
      errors: [],
    }
  } finally {
    importing.value = false
  }
  return false
}
</script>
