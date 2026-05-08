<template>
  <div>
    <a-page-header :title="isEdit ? '編輯商品' : '新增商品'" @back="$router.push({ name: 'products' })" />

    <a-spin :spinning="loading">
      <a-form :model="form" :label-col="{ span: 4 }" :wrapper-col="{ span: 16 }" @finish="handleSubmit">
        <a-form-item label="商品名稱" name="name" :rules="[{ required: true, message: '請輸入名稱' }]">
          <a-input v-model:value="form.name" />
        </a-form-item>

        <a-form-item label="SKU" name="sku" :rules="[{ required: true, message: '請輸入 SKU' }]">
          <a-input v-model:value="form.sku" />
        </a-form-item>

        <a-form-item label="售價 (元)" :rules="[{ required: true, message: '請輸入售價' }]">
          <a-input-number v-model:value="priceDisplay" :min="0" :precision="0" style="width: 200px" />
        </a-form-item>

        <a-form-item label="成本 (元)">
          <a-input-number v-model:value="costDisplay" :min="0" :precision="0" style="width: 200px" />
        </a-form-item>

        <a-form-item label="稅率">
          <a-input-number v-model:value="form.tax_rate" :min="0" :max="1" :step="0.01" style="width: 200px" />
        </a-form-item>

        <a-form-item label="分類">
          <a-select v-model:value="form.category_id" placeholder="選擇分類" allow-clear style="width: 280px">
            <a-select-option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</a-select-option>
          </a-select>
        </a-form-item>

        <a-form-item label="計重商品">
          <a-switch v-model:checked="form.is_weighted" />
        </a-form-item>

        <a-form-item label="單位">
          <a-input v-model:value="form.unit" style="width: 120px" />
        </a-form-item>

        <a-form-item label="上架">
          <a-switch v-model:checked="form.is_active" />
        </a-form-item>

        <a-form-item label="商品圖片">
          <a-upload
            :before-upload="handleUpload"
            :show-upload-list="false"
            accept="image/*"
          >
            <a-button :loading="uploading">上傳圖片</a-button>
          </a-upload>
          <div v-if="form.image_url" style="margin-top: 8px; display: flex; align-items: flex-start; gap: 12px">
            <a-image :src="form.image_url" :width="120" />
            <a-button danger @click="removeImage">刪除圖片</a-button>
          </div>
        </a-form-item>

        <a-form-item label="條碼">
          <div v-for="(bc, idx) in barcodes" :key="idx" style="display: flex; gap: 8px; margin-bottom: 8px">
            <a-input v-model:value="barcodes[idx]" style="width: 260px" />
            <a-button danger @click="barcodes.splice(idx, 1)">移除</a-button>
          </div>
          <a-button type="dashed" @click="barcodes.push('')">+ 新增條碼</a-button>
        </a-form-item>

        <a-form-item label="描述">
          <a-textarea v-model:value="form.description" :rows="3" />
        </a-form-item>

        <a-form-item :wrapper-col="{ offset: 4 }">
          <a-space>
            <a-button type="primary" html-type="submit" :loading="submitting">{{ isEdit ? '儲存' : '建立' }}</a-button>
            <a-button @click="$router.push({ name: 'products' })">取消</a-button>
          </a-space>
        </a-form-item>
      </a-form>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { getProduct, createProduct, updateProduct, listCategories, uploadImage } from '@/api/products'
import type { CategoryRead } from '@/types'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const loading = ref(false)
const submitting = ref(false)
const uploading = ref(false)
const categories = ref<CategoryRead[]>([])
const barcodes = ref<string[]>([])

const form = reactive({
  name: '',
  sku: '',
  tax_rate: 0.05,
  category_id: undefined as string | undefined,
  is_weighted: false,
  unit: '個',
  is_active: true,
  image_url: '' as string | null,
  description: '' as string | null,
})

const priceDisplay = ref(0)
const costDisplay = ref<number | null>(null)

async function handleUpload(file: File) {
  uploading.value = true
  try {
    const { data } = await uploadImage(file)
    form.image_url = data.url
    message.success('圖片上傳成功')
  } catch {
    message.error('圖片上傳失敗')
  } finally {
    uploading.value = false
  }
  return false
}

function removeImage() {
  form.image_url = null
  message.success('已移除圖片，請記得按儲存')
}

async function handleSubmit() {
  submitting.value = true
  try {
    const payload = {
      ...form,
      price_cents: Math.round(priceDisplay.value),
      cost_cents: costDisplay.value != null ? Math.round(costDisplay.value) : null,
      barcodes: barcodes.value.filter(b => b.trim()),
    }
    if (isEdit.value) {
      await updateProduct(route.params.id as string, payload)
      message.success('已更新')
    } else {
      await createProduct(payload)
      message.success('已建立')
    }
    router.push({ name: 'products' })
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  const { data: cats } = await listCategories()
  categories.value = cats

  if (isEdit.value) {
    loading.value = true
    try {
      const { data } = await getProduct(route.params.id as string)
      form.name = data.name
      form.sku = data.sku
      form.tax_rate = data.tax_rate
      form.category_id = data.category_id ?? undefined
      form.is_weighted = data.is_weighted
      form.unit = data.unit
      form.is_active = data.is_active
      form.image_url = data.image_url
      form.description = data.description
      priceDisplay.value = data.price_cents
      costDisplay.value = data.cost_cents
      barcodes.value = [...data.barcodes]
    } finally {
      loading.value = false
    }
  }
})
</script>
