<template>
  <div class="login-wrapper">
    <a-card class="login-card" title="POS 後台管理系統">
      <a-form :model="form" @finish="handleLogin" layout="vertical">
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
      </a-form>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const loading = ref(false)
const errorMsg = ref('')
const form = reactive({ username: '', password: '' })

async function handleLogin() {
  loading.value = true
  errorMsg.value = ''
  try {
    await auth.login(form.username, form.password)
    const redirect = (route.query.redirect as string) || '/'
    router.push(redirect)
  } catch (e: any) {
    errorMsg.value = e.response?.data?.detail || '登入失敗，請檢查帳號密碼'
  } finally {
    loading.value = false
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
</style>
