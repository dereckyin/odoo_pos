<template>
  <div>
    <a-page-header title="LINE 官方帳號設定" />

    <a-alert
      type="info"
      show-icon
      style="margin-bottom: 16px"
      message="設定 LINE Messaging API 與 LIFF 參數後，會員可用 LINE 登入綁定，並可推播活動/生日通知。"
    />

    <a-card style="max-width: 640px">
      <a-spin :spinning="loading">
        <a-form layout="vertical">
          <a-form-item label="Channel ID">
            <a-input v-model:value="form.channel_id" placeholder="LINE Login / Messaging Channel ID" />
          </a-form-item>
          <a-form-item label="LIFF ID">
            <a-input v-model:value="form.liff_id" placeholder="LIFF App ID（前端登入用）" />
          </a-form-item>
          <a-form-item label="Channel Secret">
            <a-input-password
              v-model:value="form.channel_secret"
              :placeholder="current.has_channel_secret ? '已設定（留空表示不變更）' : '用於驗證 webhook 簽章'"
            />
          </a-form-item>
          <a-form-item label="Channel Access Token">
            <a-input-password
              v-model:value="form.access_token"
              :placeholder="current.has_access_token ? '已設定（留空表示不變更）' : '用於推播訊息（Messaging API）'"
            />
          </a-form-item>
          <a-form-item label="Webhook URL（填入 LINE Developers）">
            <a-typography-text copyable :content="webhookUrl" />
          </a-form-item>
          <a-button type="primary" :loading="saving" @click="save">儲存設定</a-button>
        </a-form>
      </a-spin>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { message } from 'ant-design-vue'
import { getLineSettings, updateLineSettings, type LineSettingsRead } from '@/api/tenant'

const loading = ref(false)
const saving = ref(false)
const current = ref<LineSettingsRead>({
  channel_id: '', liff_id: '', has_channel_secret: false, has_access_token: false,
})

const form = reactive({
  channel_id: '',
  liff_id: '',
  channel_secret: '',
  access_token: '',
})

const webhookUrl = computed(() => {
  const base = window.location.origin.replace(/\/$/, '')
  return `${base}/api/v1/line/webhook/{tenant_id}`
})

async function load() {
  loading.value = true
  try {
    const { data } = await getLineSettings()
    current.value = data
    form.channel_id = data.channel_id
    form.liff_id = data.liff_id
    form.channel_secret = ''
    form.access_token = ''
  } finally {
    loading.value = false
  }
}

async function save() {
  saving.value = true
  try {
    const payload: Record<string, string> = {
      channel_id: form.channel_id,
      liff_id: form.liff_id,
    }
    if (form.channel_secret) payload.channel_secret = form.channel_secret
    if (form.access_token) payload.access_token = form.access_token
    const { data } = await updateLineSettings(payload)
    current.value = data
    form.channel_secret = ''
    form.access_token = ''
    message.success('已儲存')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>
