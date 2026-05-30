<template>
  <div v-if="open" class="overlay" @click.self="emit('close')">
    <div class="modal">
      <h3>會員登入</h3>
      <p class="hint">輸入手機號碼收取驗證碼（示範環境會直接顯示驗證碼）</p>
      <input v-model="phone" placeholder="手機號碼" inputmode="tel" />
      <button v-if="!sent" class="btn" :disabled="busy || !phone" @click="requestOtp">取得驗證碼</button>
      <template v-else>
        <input v-model="code" placeholder="6 碼驗證碼" inputmode="numeric" maxlength="6" />
        <p v-if="devCode" class="dev">驗證碼：{{ devCode }}</p>
        <button class="btn primary" :disabled="busy || code.length < 4" @click="verify">登入</button>
      </template>
      <button class="link" @click="emit('close')">取消</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { requestMemberOtp, verifyMemberOtp } from '@/api'
import { useMemberStore } from '@/stores/member'

const props = defineProps<{ open: boolean; tableToken: string }>()
const emit = defineEmits<{ close: [] }>()

const memberStore = useMemberStore()
const phone = ref('')
const code = ref('')
const sent = ref(false)
const devCode = ref('')
const busy = ref(false)

async function requestOtp() {
  busy.value = true
  try {
    const { data } = await requestMemberOtp(props.tableToken, phone.value.trim())
    sent.value = true
    devCode.value = data.dev_code || ''
  } finally {
    busy.value = false
  }
}

async function verify() {
  busy.value = true
  try {
    const { data } = await verifyMemberOtp(props.tableToken, phone.value.trim(), code.value.trim())
    memberStore.setMember(data)
    emit('close')
  } finally {
    busy.value = false
  }
}
</script>

<style scoped>
.overlay { position: fixed; inset: 0; background: rgba(0,0,0,.45); display: flex; align-items: center; justify-content: center; z-index: 100; }
.modal { background: #fff; border-radius: 12px; padding: 20px; width: min(360px, 92vw); display: flex; flex-direction: column; gap: 10px; }
.hint { font-size: 13px; color: #666; margin: 0; }
input { padding: 10px; border: 1px solid #ddd; border-radius: 8px; }
.btn { padding: 10px; border-radius: 8px; border: 1px solid #ccc; background: #f5f5f5; }
.btn.primary { background: #c45c3e; color: #fff; border-color: #c45c3e; }
.link { background: none; border: none; color: #888; }
.dev { color: #c45c3e; font-weight: 600; }
</style>
