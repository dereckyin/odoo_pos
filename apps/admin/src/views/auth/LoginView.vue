<template>
  <div class="login-wrapper">
    <a-card class="login-card" title="點餐趣｜後台管理系統">
      <a-form :model="form" @finish="handleLogin" layout="vertical">
        <a-form-item label="租戶代號" name="tenant_code">
          <a-input
            v-model:value="form.tenant_code"
            size="large"
            placeholder="例：demo（店家後台必填）"
            allow-clear
          />
          <template #extra>
            <span class="field-hint">
              一般店家／門市管理員請填租戶代號；僅「平台超管」可留白。
              若曾做多租戶遷移但尚未 seed，資料庫可能只有 <code>__legacy__</code> 租戶，請填該代號。
            </span>
          </template>
        </a-form-item>
        <a-form-item label="帳號" name="username" :rules="[{ required: true, message: '請輸入帳號' }]">
          <a-input v-model:value="form.username" size="large" placeholder="請輸入帳號" />
        </a-form-item>
        <a-form-item label="密碼" name="password" :rules="[{ required: true, message: '請輸入密碼' }]">
          <a-input-password v-model:value="form.password" size="large" placeholder="請輸入密碼" @pressEnter="handleLogin" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" html-type="submit" :loading="loading" block size="large">
            登入
          </a-button>
        </a-form-item>
        <a-alert v-if="errorMsg" :message="errorMsg" type="error" show-icon closable @close="errorMsg = ''" />
        <a-collapse ghost class="dev-hint">
          <a-collapse-panel key="1" header="本機登入參考">
            <ul class="hint-list">
              <li>有跑過 seed：租戶 <code>demo</code>，帳號 <code>admin</code>，密碼 <code>admin123</code></li>
              <li>僅有舊版遷移資料：租戶填 <code>__legacy__</code>，帳號 <code>admin</code>，密碼 <code>admin123</code></li>
              <li>若錯誤變成 <code>tenant not found</code>，代表該租戶代號不存在，請改填上列正確代號或執行 seed。</li>
            </ul>
          </a-collapse-panel>
        </a-collapse>
        <div class="signup-link">
          還沒有帳號？
          <a @click.prevent="$router.push({ name: 'signup' })">申請開通新店家</a>
        </div>
      </a-form>
    </a-card>

    <!-- First-login forced password change ------------------------------ -->
    <a-modal
      v-model:open="changeVisible"
      title="首次登入請修改密碼"
      :closable="false"
      :mask-closable="false"
      :keyboard="false"
      :confirm-loading="changing"
      ok-text="變更密碼"
      @ok="submitChangePassword"
    >
      <a-alert
        message="您的密碼為一次性密碼，請立即變更後才能繼續使用後台。"
        type="warning"
        show-icon
        style="margin-bottom: 16px"
      />
      <a-form layout="vertical">
        <a-form-item label="目前的一次性密碼" :rules="[{ required: true }]">
          <a-input-password v-model:value="changeForm.old_password" />
        </a-form-item>
        <a-form-item label="新密碼" :rules="[{ required: true }]" extra="建議至少 12 碼，含英數字與符號">
          <a-input-password v-model:value="changeForm.new_password" />
        </a-form-item>
        <a-form-item label="再次輸入新密碼" :rules="[{ required: true }]">
          <a-input-password v-model:value="changeForm.confirm" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { message } from 'ant-design-vue'
import { formatApiError } from '@/api/formatApiError'
import { useAuthStore } from '@/stores/auth'
import * as authApi from '@/api/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const loading = ref(false)
const errorMsg = ref('')
const form = reactive({
  tenant_code: '',
  username: '',
  password: '',
})

const changeVisible = ref(false)
const changing = ref(false)
const changeForm = reactive({ old_password: '', new_password: '', confirm: '' })

async function handleLogin() {
  loading.value = true
  errorMsg.value = ''
  const tenant = form.tenant_code.trim() || undefined
  const user = form.username.trim()
  const pass = form.password
  try {
    await auth.login(user, pass, tenant)
    if (auth.mustChangePassword) {
      changeForm.old_password = pass
      changeVisible.value = true
      return
    }
    finishLogin()
  } catch (e: unknown) {
    errorMsg.value = formatApiError(e)
  } finally {
    loading.value = false
  }
}

function finishLogin() {
  const redirect = (route.query.redirect as string) || '/'
  router.push(redirect)
}

async function submitChangePassword() {
  if (
    !changeForm.old_password ||
    !changeForm.new_password ||
    !changeForm.confirm
  ) {
    message.warning('請填寫所有欄位')
    return
  }
  if (changeForm.new_password !== changeForm.confirm) {
    message.warning('兩次輸入的新密碼不一致')
    return
  }
  if (changeForm.new_password.length < 8) {
    message.warning('新密碼至少需 8 碼')
    return
  }
  changing.value = true
  try {
    await authApi.changePassword(changeForm.old_password, changeForm.new_password)
    message.success('密碼已更新，請重新登入')
    await auth.logout()
    changeVisible.value = false
    // Force a full re-login under the new password.
    form.password = ''
  } catch (e: any) {
    message.error(e.response?.data?.detail || '修改密碼失敗')
  } finally {
    changing.value = false
  }
}
</script>

<style scoped>
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.login-card {
  width: 400px;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,.18);
}
.signup-link {
  text-align: center;
  margin-top: 8px;
  color: rgba(0, 0, 0, 0.55);
  font-size: 13px;
}
.signup-link a {
  cursor: pointer;
}
.field-hint {
  color: rgba(0, 0, 0, 0.55);
  font-size: 12px;
  line-height: 1.5;
}
.dev-hint {
  margin-top: 8px;
  text-align: left;
}
.hint-list {
  margin: 0;
  padding-left: 18px;
  font-size: 13px;
  color: rgba(0, 0, 0, 0.65);
}
.hint-list code {
  background: rgba(0, 0, 0, 0.06);
  padding: 0 4px;
  border-radius: 2px;
}
</style>
