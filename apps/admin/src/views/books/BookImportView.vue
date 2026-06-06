<template>
  <div>
    <a-page-header title="寄賣書籍 CSV 入庫" @back="$router.push({ name: 'book-receive' })" />

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
        message="每列會呼叫 TAAZE 查書、建立主檔並入庫。11 碼為 TAAZE 商品編號；ISBN/EAN 13 碼請改用商品編號貼紙。"
      />
      <div style="margin-top: 16px">
        <a-button type="link" :loading="downloadingTemplate" @click="downloadTemplate">
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
        <p class="ant-upload-hint">欄位：barcode, qty, store_id, store_code（store_id 與 store_code 擇一）</p>
      </a-upload-dragger>

      <a-spin v-if="importing" tip="入庫中..." style="margin-top: 24px" />

      <div v-if="result" style="margin-top: 24px">
        <a-result
          :status="result.status"
          :title="result.title"
          :sub-title="result.subTitle"
        >
          <template #extra>
            <a-button type="primary" @click="$router.push({ name: 'books' })">回書籍列表</a-button>
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
import { message } from 'ant-design-vue'
import client from '@/api/client'
import { importBooksCsv } from '@/api/books'

interface ImportError {
  row: number
  barcode: string
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
  { field: 'barcode', required: '是', desc: '11 碼 TAAZE 商品編號或 8 碼他社條碼' },
  { field: 'qty', required: '是', desc: '入庫數量（正數）' },
  { field: 'store_id', required: '擇一', desc: '門店 UUID' },
  { field: 'store_code', required: '擇一', desc: '門店代號（與門店管理一致）' },
]

const errorColumns = [
  { title: '列', dataIndex: 'row', width: 60 },
  { title: '條碼', dataIndex: 'barcode', width: 140 },
  { title: '錯誤', dataIndex: 'message' },
]

const importing = ref(false)
const downloadingTemplate = ref(false)
const result = ref<ImportResultState | null>(null)

async function downloadTemplate() {
  downloadingTemplate.value = true
  try {
    const res = await client.get('/books/import-csv/template', { responseType: 'blob' })
    const url = URL.createObjectURL(res.data)
    const a = document.createElement('a')
    a.href = url
    a.download = 'book-import-sample.csv'
    a.click()
    URL.revokeObjectURL(url)
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '下載範例失敗')
  } finally {
    downloadingTemplate.value = false
  }
}

async function handleUpload(file: File) {
  importing.value = true
  result.value = null
  try {
    const { data } = await importBooksCsv(file)
    const hasErrors = data.errors.length > 0
    result.value = {
      status: hasErrors ? (data.received > 0 ? 'warning' : 'error') : 'success',
      title: hasErrors ? '部分入庫完成' : '入庫完成',
      subTitle: `成功 ${data.received} 筆，略過 ${data.skipped} 筆`,
      errors: data.errors,
    }
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '匯入失敗')
  } finally {
    importing.value = false
  }
  return false
}
</script>
