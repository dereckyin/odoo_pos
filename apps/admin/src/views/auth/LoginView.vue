<template>
  <div class="login-wrapper">
    <a-card class="login-card" title="POS 後台管理系統">
      <a-form :model="form" @finish="handleLogin" layout="vertical">
        <a-form-item label="租戶代號" name="tenant_code" extra="平台超管登入時可留白">
          <a-input
            v-model:value="form.tenant_code"
            size="large"
            placeholder="例：demo"
            allow-clear
          />
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
import { useAuthStore } from '@/stores/auth'
import * as authApi from '@/api/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const loading = ref(false)
const errorMsg = ref('')
const form = reactive({ tenant_code: '', username: '', password: '' })

const changeVisible = ref(false)
const changing = ref(false)
const changeForm = reactive({ old_password: '', new_password: '', confirm: '' })

async function handleLogin() {
  loading.value = true
  errorMsg.value = ''
  try {
    await auth.login(form.username, form.password, form.tenant_code || undefined)
    if (auth.mustChangePassword) {
      changeForm.old_password = form.password
      changeVisible.value = true
      return
    }
    finishLogin()
  } catch (e: any) {
    errorMsg.value = e.response?.data?.detail || '登入失敗，請檢查帳號密碼'
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
</style>
