<template>
  <div>
    <a-page-header title="會員簡訊群發" />

    <a-alert
      type="info"
      show-icon
      style="margin-bottom: 16px"
      message="僅會發送給「同意行銷」且有手機號碼的會員。簡訊費用依電信商計算，請斟酌發送頻率。"
    />

    <a-card title="撰寫訊息" style="margin-bottom: 24px">
      <a-form layout="vertical">
        <a-form-item label="訊息內容">
          <a-textarea
            v-model:value="message"
            :rows="4"
            :maxlength="480"
            show-count
            placeholder="輸入要群發的簡訊內容…"
          />
        </a-form-item>
        <a-space>
          <a-tag color="blue">預計發送對象：{{ audience }} 人</a-tag>
          <a-popconfirm
            :title="`確定要發送給 ${audience} 位會員嗎？`"
            :disabled="!message.trim() || audience === 0"
            @confirm="handleSend"
          >
            <a-button type="primary" :loading="sending" :disabled="!message.trim() || audience === 0">
              發送
            </a-button>
          </a-popconfirm>
          <a-button @click="refreshAudience" :loading="loadingAudience">重新整理人數</a-button>
        </a-space>
      </a-form>
    </a-card>

    <a-card title="發送紀錄">
      <a-table
        :columns="columns"
        :data-source="history"
        :loading="loadingHistory"
        row-key="id"
        size="small"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'created_at'">{{ formatTime(record.created_at) }}</template>
          <template v-if="column.key === 'result'">
            <a-tag color="green">成功 {{ record.sent_count }}</a-tag>
            <a-tag v-if="record.failed_count" color="red">失敗 {{ record.failed_count }}</a-tag>
          </template>
        </template>
      </a-table>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message as antMessage } from 'ant-design-vue'
import { getBroadcastAudience, listBroadcasts, sendBroadcast } from '@/api/memberBroadcast'
import type { MemberBroadcast } from '@/types'

const message = ref('')
const audience = ref(0)
const sending = ref(false)
const loadingAudience = ref(false)
const loadingHistory = ref(false)
const history = ref<MemberBroadcast[]>([])

const columns = [
  { title: '時間', key: 'created_at', width: 180 },
  { title: '訊息', dataIndex: 'message', ellipsis: true },
  { title: '對象數', dataIndex: 'audience_count', width: 90 },
  { title: '結果', key: 'result', width: 180 },
]

function formatTime(s: string) {
  return new Date(s).toLocaleString()
}

async function refreshAudience() {
  loadingAudience.value = true
  try {
    const { data } = await getBroadcastAudience()
    audience.value = data.count
  } catch (e: any) {
    antMessage.error(e.response?.data?.detail || '無法取得人數')
  } finally {
    loadingAudience.value = false
  }
}

async function fetchHistory() {
  loadingHistory.value = true
  try {
    const { data } = await listBroadcasts()
    history.value = data
  } finally {
    loadingHistory.value = false
  }
}

async function handleSend() {
  sending.value = true
  try {
    const { data } = await sendBroadcast(message.value.trim())
    antMessage.success(`已發送：成功 ${data.sent_count} 筆，失敗 ${data.failed_count} 筆`)
    message.value = ''
    fetchHistory()
  } catch (e: any) {
    antMessage.error(e.response?.data?.detail || '發送失敗')
  } finally {
    sending.value = false
  }
}

onMounted(() => {
  refreshAudience()
  fetchHistory()
})
</script>
