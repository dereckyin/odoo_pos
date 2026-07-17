<template>
  <div>
    <a-page-header title="寄賣書籍設定" sub-title="分帳比例、門店開放、POS 折扣快捷鈕" />
    <a-spin :spinning="loading">
      <a-form v-if="form" layout="vertical" style="max-width: 640px">
        <a-form-item label="書籍公司分帳比例 (%)">
          <a-input-number v-model:value="form.book_share_pct" :min="0" :max="100" style="width: 160px" />
          <div class="field-hint">餐廳留存 = 100% − 此值；以實際成交價計算</div>
        </a-form-item>
        <a-form-item label="開放門店（留白 = 全部）">
          <a-select
            v-model:value="form.store_ids"
            mode="multiple"
            allow-clear
            placeholder="全部門店"
            :options="storeOptions"
            style="width: 100%"
          />
        </a-form-item>
        <a-divider>POS 折扣快捷鈕</a-divider>
        <div v-for="(preset, idx) in form.discount_presets" :key="idx" class="preset-row">
          <a-input v-model:value="preset.label" placeholder="標籤（例：9折）" style="width: 120px" />
          <a-input-number v-model:value="preset.pct_off" :min="0" :max="100" addon-after="%" style="width: 140px" />
          <a-button danger type="text" @click="removePreset(idx)">刪除</a-button>
        </div>
        <a-button type="dashed" block style="margin-bottom: 16px" @click="addPreset">新增折扣鈕</a-button>
        <a-button type="primary" :loading="saving" @click="save">儲存設定</a-button>
      </a-form>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { getConsignmentSettings, updateConsignmentSettings } from '@/api/books'
import type { ConsignmentBooksSettings, DiscountPreset } from '@/api/books'
import { listStores } from '@/api/stores'

const loading = ref(false)
const saving = ref(false)
const form = ref<ConsignmentBooksSettings | null>(null)
const storeOptions = ref<{ label: string; value: string }[]>([])

function addPreset() {
  if (!form.value) return
  form.value.discount_presets.push({ label: '7折', pct_off: 30 })
}

function removePreset(idx: number) {
  form.value?.discount_presets.splice(idx, 1)
}

async function load() {
  loading.value = true
  try {
    const [{ data: settings }, { data: stores }] = await Promise.all([
      getConsignmentSettings(),
      listStores(),
    ])
    form.value = {
      book_share_pct: settings.book_share_pct,
      store_ids: settings.store_ids || [],
      discount_presets: [...(settings.discount_presets || [])],
    }
    storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '載入失敗')
  } finally {
    loading.value = false
  }
}

async function save() {
  if (!form.value) return
  saving.value = true
  try {
    await updateConsignmentSettings({
      book_share_pct: form.value.book_share_pct,
      store_ids: form.value.store_ids,
      discount_presets: form.value.discount_presets,
    })
    message.success('已儲存')
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.field-hint { color: #888; font-size: 12px; margin-top: 4px; }
.preset-row { display: flex; gap: 8px; align-items: center; margin-bottom: 8px; }
</style>
