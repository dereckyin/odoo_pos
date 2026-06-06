<template>
  <div>
    <a-page-header title="寄賣入庫" sub-title="將書籍送入指定門店庫存" />
    <a-form layout="vertical" style="max-width: 480px">
      <a-form-item label="門店" required>
        <a-select v-model:value="storeId" :options="storeOptions" placeholder="選擇門店" />
      </a-form-item>
      <a-form-item label="搜尋書籍" required>
        <a-select
          v-model:value="productId"
          show-search
          :filter-option="false"
          :options="bookOptions"
          placeholder="輸入書名或條碼搜尋"
          @search="onSearch"
        />
      </a-form-item>
      <a-form-item label="入庫數量" required>
        <a-input-number v-model:value="qty" :min="1" style="width: 160px" />
      </a-form-item>
      <a-button type="primary" :loading="saving" @click="submit">確認入庫</a-button>
    </a-form>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listBooks, receiveBook } from '@/api/books'
import { listStores } from '@/api/stores'

const storeId = ref<string>()
const productId = ref<string>()
const qty = ref(1)
const saving = ref(false)
const storeOptions = ref<{ label: string; value: string }[]>([])
const bookOptions = ref<{ label: string; value: string }[]>([])

async function onSearch(q: string) {
  if (!q.trim()) return
  const { data } = await listBooks({ q: q.trim() })
  bookOptions.value = data.map((b) => ({
    label: `${b.name}（${b.sku}）`,
    value: b.id,
  }))
}

async function submit() {
  if (!storeId.value || !productId.value) {
    message.warning('請選擇門店與書籍')
    return
  }
  saving.value = true
  try {
    await receiveBook({ store_id: storeId.value, product_id: productId.value, qty: qty.value })
    message.success('入庫成功')
    productId.value = undefined
    qty.value = 1
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '入庫失敗')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const { data: stores } = await listStores()
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  const { data: books } = await listBooks()
  bookOptions.value = books.map((b) => ({ label: `${b.name}（${b.sku}）`, value: b.id }))
})
</script>
