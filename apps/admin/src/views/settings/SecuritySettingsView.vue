<template>
  <div>
    <a-page-header title="安全設定" sub-title="管理您帳號的雙重驗證（2FA）" />

    <a-card style="max-width: 560px">
      <a-descriptions :column="1" bordered size="small" style="margin-bottom: 16px">
        <a-descriptions-item label="帳號">{{ auth.username }}</a-descriptions-item>
        <a-descriptions-item label="雙重驗證">
          <a-tag :color="enabled ? 'green' : 'default'">{{ enabled ? '已啟用' : '未啟用' }}</a-tag>
        </a-descriptions-item>
      </a-descriptions>

      <div v-if="!enabled">
        <a-button type="primary" :loading="enrolling" @click="startEnroll" v-if="!enrollData">
          啟用雙重驗證
        </a-button>

        <div v-if="enrollData" class="enroll">
          <a-alert
            type="info"
            show-icon
            message="請使用 Google Authenticator / Microsoft Authenticator 等驗證器掃描下方 QR Code，或手動輸入金鑰。"
            style="margin-bottom: 16px"
          />
          <div class="qr-box">
            <qrcode-vue :value="enrollData.otpauth_uri" :size="180" level="M" />
          </div>
          <a-typography-paragraph copyable :content="enrollData.secret" class="secret">
            金鑰：{{ enrollData.secret }}
          </a-typography-paragraph>
          <a-form layout="vertical" style="margin-top: 12px">
            <a-form-item label="輸入驗證器產生的 6 位數字以完成啟用">
              <a-input v-model:value="verifyCode" maxlength="6" inputmode="numeric" placeholder="6 位數字" style="width: 200px" />
            </a-form-item>
            <a-space>
              <a-button type="primary" :loading="verifying" @click="confirmEnroll">確認啟用</a-button>
              <a-button @click="cancelEnroll">取消</a-button>
            </a-space>
          </a-form>
        </div>
      </div>

      <div v-else>
        <a-alert type="success" show-icon message="此帳號已啟用雙重驗證，登入時需輸入驗證碼。" style="margin-bottom: 16px" />
        <a-form layout="vertical">
          <a-form-item label="輸入登入密碼以停用雙重驗證">
            <a-input-password v-model:value="disablePassword" style="width: 260px" />
          </a-form-item>
          <a-button danger :loading="disabling" @click="confirmDisable">停用雙重驗證</a-button>
        </a-form>
      </div>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import QrcodeVue from 'qrcode.vue'
import { useAuthStore } from '@/stores/auth'
import { enrollTotp, verifyTotp, disableTotp } from '@/api/auth'
import { getMe } from '@/api/users'

const auth = useAuthStore()
const enabled = ref(false)

const enrolling = ref(false)
const enrollData = ref<{ secret: string; otpauth_uri: string } | null>(null)
const verifyCode = ref('')
const verifying = ref(false)

const disablePassword = ref('')
const disabling = ref(false)

async function loadStatus() {
  try {
    const { data } = await getMe()
    enabled.value = !!data.totp_enabled
  } catch {
    /* ignore */
  }
}

async function startEnroll() {
  enrolling.value = true
  try {
    const { data } = await enrollTotp()
    enrollData.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '啟用失敗')
  } finally {
    enrolling.value = false
  }
}

function cancelEnroll() {
  enrollData.value = null
  verifyCode.value = ''
}

async function confirmEnroll() {
  if (verifyCode.value.length !== 6) {
    message.warning('請輸入 6 位數字')
    return
  }
  verifying.value = true
  try {
    await verifyTotp(verifyCode.value)
    message.success('雙重驗證已啟用')
    enrollData.value = null
    verifyCode.value = ''
    enabled.value = true
  } catch (e: any) {
    message.error(e.response?.data?.detail || '驗證碼錯誤')
  } finally {
    verifying.value = false
  }
}

async function confirmDisable() {
  if (!disablePassword.value) {
    message.warning('請輸入密碼')
    return
  }
  disabling.value = true
  try {
    await disableTotp(disablePassword.value)
    message.success('雙重驗證已停用')
    disablePassword.value = ''
    enabled.value = false
  } catch (e: any) {
    message.error(e.response?.data?.detail || '停用失敗')
  } finally {
    disabling.value = false
  }
}

onMounted(loadStatus)
</script>

<style scoped>
.qr-box {
  display: flex;
  justify-content: center;
  padding: 12px;
}
.secret {
  text-align: center;
  font-family: monospace;
}
.enroll {
  margin-top: 8px;
}
</style>
