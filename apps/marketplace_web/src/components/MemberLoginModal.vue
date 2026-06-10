<template>
  <div v-if="open" class="overlay" @click.self="close">
    <div class="modal">
      <div v-if="mode !== 'otp'" class="tabs">
        <button type="button" :class="{ active: mode === 'login' }" @click="switchMode('login')">登入</button>
        <button type="button" :class="{ active: mode === 'register' }" @click="switchMode('register')">註冊</button>
      </div>

      <!-- 密碼登入 -->
      <template v-if="mode === 'login'">
        <p class="hint">使用手機號碼與密碼登入</p>
        <input v-model="phone" placeholder="手機號碼" inputmode="tel" autocomplete="username" />
        <input v-model="password" type="password" placeholder="密碼" autocomplete="current-password" @keyup.enter="login" />
        <button class="btn primary" :disabled="busy || !phone || !password" @click="login">登入</button>
        <div class="links">
          <button class="link" @click="switchMode('otp')">用驗證碼登入</button>
        </div>
      </template>

      <!-- 註冊 -->
      <template v-else-if="mode === 'register'">
        <p class="hint">建立跨店市集會員，享點數與專屬優惠</p>
        <input v-model="name" placeholder="姓名 / 暱稱" autocomplete="name" />
        <input v-model="phone" placeholder="手機號碼" inputmode="tel" autocomplete="username" />
        <input v-model="password" type="password" placeholder="密碼（至少 8 碼）" autocomplete="new-password" />
        <input v-model="email" type="email" placeholder="Email（選填）" autocomplete="email" />
        <label class="field-label">生日（選填）</label>
        <input v-model="birthday" type="date" />
        <input v-model="referralCode" placeholder="推薦碼（選填）" />
        <label class="terms">
          <input v-model="termsAccepted" type="checkbox" />
          <span>我已閱讀並同意服務條款與隱私權政策</span>
        </label>
        <button
          class="btn primary"
          :disabled="busy || !canRegister"
          @click="register"
        >註冊</button>
      </template>

      <!-- 驗證碼登入（次要） -->
      <template v-else>
        <h3>驗證碼登入</h3>
        <p class="hint">輸入手機號碼收取驗證碼</p>
        <input v-model="phone" placeholder="手機號碼" inputmode="tel" />
        <button v-if="!otpSent" class="btn" :disabled="busy || !phone" @click="requestOtp">取得驗證碼</button>
        <template v-else>
          <input v-model="code" placeholder="6 碼驗證碼" inputmode="numeric" maxlength="6" />
          <p v-if="devCode" class="dev">驗證碼：{{ devCode }}</p>
          <button class="btn primary" :disabled="busy || code.length < 4" @click="verify">登入</button>
        </template>
        <div class="links">
          <button class="link" @click="switchMode('login')">返回密碼登入</button>
        </div>
      </template>

      <p v-if="error" class="error">{{ error }}</p>
      <button class="link cancel" @click="close">取消</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  loginMemberPassword,
  registerMember,
  requestMemberOtp,
  verifyMemberOtp,
} from '@/api'
import { useMemberStore } from '@/stores/member'

const props = defineProps<{ open: boolean; storeSlug?: string; initialMode?: 'login' | 'register' }>()
const emit = defineEmits<{ close: [] }>()

const memberStore = useMemberStore()

type Mode = 'login' | 'register' | 'otp'
const mode = ref<Mode>(props.initialMode ?? 'login')

const phone = ref('')
const password = ref('')
const name = ref('')
const email = ref('')
const birthday = ref('')
const referralCode = ref('')
const termsAccepted = ref(false)

const code = ref('')
const otpSent = ref(false)
const devCode = ref('')

const busy = ref(false)
const error = ref('')

const canRegister = computed(
  () => !!name.value.trim() && !!phone.value.trim() && password.value.length >= 8 && termsAccepted.value,
)

watch(
  () => props.open,
  (v) => {
    if (v) {
      mode.value = props.initialMode ?? 'login'
      error.value = ''
    }
  },
)

function extractError(e: unknown, fallback: string): string {
  const err = e as { response?: { data?: { detail?: string } } }
  return err.response?.data?.detail || fallback
}

function switchMode(m: Mode) {
  mode.value = m
  error.value = ''
  if (m !== 'otp') {
    otpSent.value = false
    code.value = ''
    devCode.value = ''
  }
}

function close() {
  emit('close')
}

async function login() {
  busy.value = true
  error.value = ''
  try {
    const { data } = await loginMemberPassword(phone.value.trim(), password.value)
    memberStore.setMember(data)
    close()
  } catch (e: unknown) {
    error.value = extractError(e, '登入失敗')
  } finally {
    busy.value = false
  }
}

async function register() {
  if (!canRegister.value) return
  busy.value = true
  error.value = ''
  try {
    const { data } = await registerMember({
      phone: phone.value.trim(),
      password: password.value,
      name: name.value.trim(),
      email: email.value.trim() || null,
      birthday: birthday.value || null,
      referral_code: referralCode.value.trim() || null,
      terms_accepted: termsAccepted.value,
    })
    memberStore.setMember(data)
    close()
  } catch (e: unknown) {
    error.value = extractError(e, '註冊失敗')
  } finally {
    busy.value = false
  }
}

async function requestOtp() {
  busy.value = true
  error.value = ''
  try {
    const { data } = await requestMemberOtp(props.storeSlug || '', phone.value.trim())
    otpSent.value = true
    devCode.value = data.dev_code || ''
  } catch (e: unknown) {
    error.value = extractError(e, '取得驗證碼失敗')
  } finally {
    busy.value = false
  }
}

async function verify() {
  busy.value = true
  error.value = ''
  try {
    const { data } = await verifyMemberOtp(props.storeSlug || '', phone.value.trim(), code.value.trim())
    memberStore.setMember(data)
    close()
  } catch (e: unknown) {
    error.value = extractError(e, '驗證失敗')
  } finally {
    busy.value = false
  }
}
</script>

<style scoped>
.overlay { position: fixed; inset: 0; background: rgba(0,0,0,.45); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal { background: #fff; border-radius: 14px; padding: 20px; width: min(380px, 94vw); max-height: 90vh; overflow-y: auto; display: flex; flex-direction: column; gap: 10px; }
.tabs { display: flex; gap: 6px; background: var(--accent-soft); border-radius: 12px; padding: 4px; }
.tabs button { flex: 1; border: 0; background: transparent; border-radius: 9px; padding: 9px; font-size: 15px; font-weight: 600; color: var(--muted); }
.tabs button.active { background: #fff; color: var(--accent); box-shadow: 0 1px 4px rgba(51,51,51,.12); }
h3 { margin: 0; }
.hint { font-size: 13px; color: #666; margin: 0; }
.field-label { font-size: 12px; color: #888; margin: -2px 0 -6px; }
input[type="text"], input:not([type]), input[type="tel"], input[type="email"], input[type="password"], input[type="date"] {
  padding: 11px; border: 1px solid #ddd; border-radius: 9px; font-size: 15px;
}
.terms { display: flex; align-items: flex-start; gap: 8px; font-size: 13px; color: #555; }
.terms input { width: 16px; height: 16px; margin-top: 2px; }
.btn { padding: 11px; border-radius: 9px; border: 1px solid #ccc; background: #f5f5f5; font-weight: 600; }
.btn.primary { background: var(--accent); color: #fff; border-color: var(--accent); }
.btn:disabled { opacity: .55; }
.links { display: flex; justify-content: center; }
.link { background: none; border: none; color: var(--accent); font-size: 13px; }
.link.cancel { color: #999; margin-top: 2px; }
.dev { color: var(--accent); font-weight: 600; margin: 0; }
.error { color: #d4380d; font-size: 13px; margin: 0; }
</style>
