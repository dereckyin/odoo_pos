<template>
  <div class="login-page">
    <form class="card" data-testid="pos-login-form" @submit.prevent="onSubmit">
      <h1>點餐趣 網頁收銀</h1>
      <p class="hint">需使用已註冊的終端機金鑰登入（純線上模式，斷網無法收銀）</p>

      <fieldset>
        <legend>終端設定</legend>
        <label>租戶代碼<input v-model="tenantCode" required /></label>
        <label>門市代碼<input v-model="storeCode" required /></label>
        <label>終端代碼<input v-model="terminalCode" required /></label>
        <label>終端 API Key<input v-model="terminalApiKey" type="password" required /></label>
      </fieldset>

      <fieldset>
        <legend>收銀員</legend>
        <label>帳號<input v-model="username" autocomplete="username" required /></label>
        <label>密碼<input v-model="password" type="password" autocomplete="current-password" required /></label>
      </fieldset>

      <p v-if="error" class="error">{{ error }}</p>
      <button type="submit" data-testid="pos-login-submit" :disabled="loading">{{ loading ? '登入中…' : '登入' }}</button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useShiftStore } from '@/stores/shift'

const auth = useAuthStore()
const shift = useShiftStore()
const router = useRouter()

const tenantCode = ref(auth.tenantCode)
const storeCode = ref(auth.storeCode)
const terminalCode = ref(auth.terminalCode)
const terminalApiKey = ref(auth.terminalApiKey)
const username = ref(auth.username || '')
const password = ref('')
const loading = ref(false)
const error = ref('')

onMounted(() => {
  if (auth.isAuthenticated) router.replace('/')
})

async function onSubmit() {
  error.value = ''
  loading.value = true
  try {
    auth.saveTerminalConfig({
      tenant_code: tenantCode.value.trim(),
      store_code: storeCode.value.trim(),
      terminal_code: terminalCode.value.trim(),
      terminal_api_key: terminalApiKey.value.trim(),
    })
    await auth.login(username.value.trim(), password.value)
    await shift.refresh()
    await router.push(shift.current ? '/' : '/shift')
  } catch (e: unknown) {
    const msg = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail
    error.value = typeof msg === 'string' ? msg : '登入失敗，請確認終端金鑰與帳密'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
}
.card {
  width: min(420px, 100%);
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}
h1 {
  margin: 0 0 8px;
  font-size: 1.35rem;
}
.hint {
  color: #666;
  font-size: 0.85rem;
  margin-bottom: 16px;
}
fieldset {
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  margin-bottom: 16px;
  padding: 12px;
}
legend {
  padding: 0 6px;
  font-size: 0.85rem;
  color: #666;
}
label {
  display: block;
  margin-bottom: 10px;
  font-size: 0.9rem;
}
input {
  display: block;
  width: 100%;
  margin-top: 4px;
  padding: 8px 10px;
  border: 1px solid #d9d9d9;
  border-radius: 6px;
}
button {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 8px;
  background: #1677ff;
  color: #fff;
  font-weight: 600;
}
button:disabled {
  opacity: 0.6;
}
.error {
  color: #cf1322;
  font-size: 0.9rem;
}
</style>
