<template>
  <div class="shift-page">
    <div class="card">
      <h1>開班</h1>
      <p>網頁收銀需先開班才能結帳。</p>
      <label>開班現金（元）<input v-model.number="openingCash" type="number" min="0" step="1" /></label>
      <p v-if="error" class="error">{{ error }}</p>
      <button data-testid="shift-open-btn" :disabled="loading" @click="openShift">{{ loading ? '處理中…' : '開始收銀' }}</button>
      <button class="ghost" type="button" @click="logout">登出</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useShiftStore } from '@/stores/shift'

const auth = useAuthStore()
const shift = useShiftStore()
const router = useRouter()

const openingCash = ref(0)
const loading = ref(false)
const error = ref('')

async function openShift() {
  loading.value = true
  error.value = ''
  try {
    await shift.open(Math.round(openingCash.value * 100))
    await router.push('/')
  } catch (e: unknown) {
    error.value = '開班失敗'
  } finally {
    loading.value = false
  }
}

function logout() {
  auth.logout()
  router.push('/login')
}
</script>

<style scoped>
.shift-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;
}
.card {
  width: min(360px, 100%);
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}
label {
  display: block;
  margin: 16px 0;
}
input {
  display: block;
  width: 100%;
  margin-top: 6px;
  padding: 8px;
  border: 1px solid #d9d9d9;
  border-radius: 6px;
}
button {
  width: 100%;
  padding: 12px;
  margin-top: 8px;
  border: none;
  border-radius: 8px;
  background: #1677ff;
  color: #fff;
  font-weight: 600;
}
button.ghost {
  background: transparent;
  color: #666;
  border: 1px solid #d9d9d9;
}
.error {
  color: #cf1322;
}
</style>
