<template>
  <div class="login-page">
    <form class="card" data-testid="pos-login-form" @submit.prevent="onSubmit">
      <h1>點餐趣 網頁收銀</h1>

      <!-- ─── 日常登入（終端已綁定） ─── -->
      <template v-if="mode === 'cashier'">
        <p class="hint">
          此瀏覽器已綁定終端。收銀員只需輸入帳號密碼即可登入。
        </p>
        <div class="bound">
          <div class="bound-row"><span>租戶</span><b>{{ auth.tenantCode }}</b></div>
          <div class="bound-row"><span>門市</span><b>{{ auth.storeCode }}</b></div>
          <div class="bound-row"><span>終端</span><b>{{ auth.terminalCode }}</b></div>
        </div>

        <fieldset>
          <legend>收銀員</legend>
          <label>帳號<input v-model="username" autocomplete="username" required /></label>
          <label>密碼<input v-model="password" type="password" autocomplete="current-password" required /></label>
        </fieldset>

        <p v-if="error" class="error">{{ error }}</p>
        <button type="submit" data-testid="pos-login-submit" :disabled="loading">
          {{ loading ? '登入中…' : '登入' }}
        </button>
        <button type="button" class="linkish" @click="enterSetup">重新綁定此瀏覽器（需管理員）</button>
      </template>

      <!-- ─── 首次／重新綁定（管理員取得網頁終端金鑰） ─── -->
      <template v-else>
        <p class="hint">
          網頁版不需手抄 API Key。請用<strong>店長／管理員</strong>帳號綁定此瀏覽器一次，
          系統會自動產生並儲存終端金鑰；之後收銀員只需帳密登入。
        </p>

        <fieldset>
          <legend>1. 管理員驗證</legend>
          <label>租戶代碼<input v-model="tenantCode" required placeholder="例如 demo" /></label>
          <label>管理員帳號<input v-model="adminUser" required autocomplete="username" /></label>
          <label>管理員密碼<input v-model="adminPass" type="password" required autocomplete="current-password" /></label>
        </fieldset>

        <fieldset>
          <legend>2. 綁定門市終端</legend>
          <label>門市代碼<input v-model="storeCode" required placeholder="例如 S001" /></label>
          <label>
            終端代碼
            <input v-model="terminalCode" required placeholder="網頁建議 WEB 或 WEB-01" />
          </label>
          <p class="mini">同一門市可多個瀏覽器用不同終端代碼（如 WEB-01、WEB-02）。</p>
        </fieldset>

        <p v-if="error" class="error">{{ error }}</p>
        <p v-if="info" class="info">{{ info }}</p>
        <button type="submit" :disabled="loading">
          {{ loading ? '綁定中…' : '綁定此瀏覽器' }}
        </button>
        <button
          v-if="auth.hasTerminalConfig"
          type="button"
          class="linkish"
          @click="mode = 'cashier'"
        >
          返回收銀員登入
        </button>
      </template>
    </form>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import * as authApi from '@/api/auth'
import { useAuthStore } from '@/stores/auth'
import { useShiftStore } from '@/stores/shift'

const auth = useAuthStore()
const shift = useShiftStore()
const router = useRouter()

const mode = ref<'cashier' | 'setup'>(auth.hasTerminalConfig ? 'cashier' : 'setup')

const tenantCode = ref(auth.tenantCode || 'demo')
const storeCode = ref(auth.storeCode || 'S001')
const terminalCode = ref(auth.terminalCode || defaultWebTerminalCode())
const adminUser = ref('admin')
const adminPass = ref('')
const username = ref(auth.username || '')
const password = ref('')
const loading = ref(false)
const error = ref('')
const info = ref('')

function defaultWebTerminalCode() {
  const existing = localStorage.getItem('pos_web_terminal_hint')
  if (existing) return existing
  const code = `WEB-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
  localStorage.setItem('pos_web_terminal_hint', code)
  return code
}

onMounted(() => {
  if (auth.isAuthenticated) router.replace('/')
})

function enterSetup() {
  mode.value = 'setup'
  error.value = ''
  info.value = ''
  tenantCode.value = auth.tenantCode || tenantCode.value
  storeCode.value = auth.storeCode || storeCode.value
  terminalCode.value = auth.terminalCode || terminalCode.value || defaultWebTerminalCode()
}

async function onSubmit() {
  error.value = ''
  info.value = ''
  loading.value = true
  try {
    if (mode.value === 'setup') {
      await bindBrowser()
    } else {
      await cashierLogin()
    }
  } catch (e: unknown) {
    const msg = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail
    error.value = typeof msg === 'string' ? msg : mode.value === 'setup' ? '綁定失敗，請確認管理員權限與門市代碼' : '登入失敗，請確認帳密'
  } finally {
    loading.value = false
  }
}

async function bindBrowser() {
  const { data: adminSession } = await authApi.adminLogin({
    tenant_code: tenantCode.value.trim(),
    username: adminUser.value.trim(),
    password: adminPass.value,
  })
  const { data: reg } = await authApi.registerTerminal(
    {
      store_code: storeCode.value.trim(),
      terminal_code: terminalCode.value.trim(),
    },
    adminSession.access_token,
  )
  auth.saveTerminalConfig({
    tenant_code: tenantCode.value.trim(),
    store_code: storeCode.value.trim(),
    terminal_code: terminalCode.value.trim(),
    terminal_api_key: reg.api_key,
  })
  localStorage.setItem('pos_web_terminal_hint', terminalCode.value.trim())
  adminPass.value = ''
  info.value = '綁定成功。請用收銀員帳密登入。'
  mode.value = 'cashier'
}

async function cashierLogin() {
  await auth.login(username.value.trim(), password.value)
  await shift.refresh()
  await router.push(shift.current ? '/' : '/shift')
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
  background: #f3f0ea;
}
.card {
  width: min(420px, 100%);
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  border: 1px solid #e6e0d6;
  box-shadow: none;
}
h1 {
  margin: 0 0 8px;
  font-size: 1.35rem;
}
.hint {
  color: #666;
  font-size: 0.85rem;
  margin-bottom: 16px;
  line-height: 1.55;
}
.bound {
  background: #fbf9f5;
  border: 1px solid #e6e0d6;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 14px;
}
.bound-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  padding: 3px 0;
  color: #8a857c;
}
.bound-row b {
  color: #22201c;
  font-weight: 700;
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
  box-sizing: border-box;
}
.mini {
  margin: 0;
  font-size: 12px;
  color: #8a857c;
  line-height: 1.4;
}
button[type='submit'] {
  width: 100%;
  padding: 12px;
  border: 0;
  border-radius: 8px;
  background: #1677ff;
  color: #fff;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
}
button[type='submit']:disabled {
  opacity: 0.6;
}
.linkish {
  display: block;
  width: 100%;
  margin-top: 12px;
  border: 0;
  background: none;
  color: #8a857c;
  font-size: 13px;
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.error {
  color: #b5342a;
  font-size: 0.85rem;
  margin-bottom: 8px;
}
.info {
  color: #4a7a4e;
  font-size: 0.85rem;
  margin-bottom: 8px;
}
</style>
