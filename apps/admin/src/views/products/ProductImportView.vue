<template>
  <div>
    <a-page-header title="CSV 批次匯入" @back="$router.push({ name: 'products' })" />

    <a-card>
      <a-upload-dragger
        :before-upload="handleUpload"
        :show-upload-list="false"
        accept=".csv"
      >
        <p class="ant-upload-drag-icon"><InboxOutlined /></p>
        <p class="ant-upload-text">點擊或拖曳 CSV 檔案至此處</p>
        <p class="ant-upload-hint">支援標準 CSV 格式，包含 sku, name, price_cents 等欄位</p>
      </a-upload-dragger>

      <a-spin v-if="importing" tip="匯入中..." style="margin-top: 24px" />

      <a-result v-if="result" :status="result.status" :title="result.title" :sub-title="result.subTitle" style="margin-top: 24px">
        <template #extra>
          <a-button type="primary" @click="$router.push({ name: 'products' })">回商品列表</a-button>
        </template>
      </a-result>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { InboxOutlined } from '@ant-design/icons-vue'
import { importProductsCsv } from '@/api/products'

const importing = ref(false)
const result = ref<{ status: 'success' | 'error'; title: string; subTitle: string } | null>(null)

async function handleUpload(file: File) {
  importing.value = true
  result.value = null
  try {
    const { data } = await importProductsCsv(file)
    result.value = {
      status: 'success',
      title: '匯入完成',
      subTitle: `成功匯入 ${data.created ?? 0} 筆，更新 ${data.updated ?? 0} 筆`,
    }
  } catch (e: any) {
    result.value = {
      status: 'error',
      title: '匯入失敗',
      subTitle: e.response?.data?.detail || '請檢查 CSV 格式',
    }
  } finally {
    importing.value = false
  }
  return false
}
</script>
