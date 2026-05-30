<template>
  <div>
    <a-page-header title="Webhook 訂閱" />

    <a-button type="primary" style="margin-bottom: 16px" @click="openCreate">新增 Webhook</a-button>

    <a-table :columns="columns" :data-source="subs" row-key="id" :loading="loading">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'events'">{{ record.events?.join(', ') }}</template>
        <template v-if="column.key === 'active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '啟用' : '停用' }}</a-tag>
        </template>
        <template v-if="column.key === 'actions'">
          <a-popconfirm title="刪除？" @confirm="remove(record.id)">
            <a-button size="small" danger>刪除</a-button>
          </a-popconfirm>
        </template>
      </template>
    </a-table>

    <a-modal v-model:open="modalOpen" title="新增 Webhook" @ok="save" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="URL"><a-input v-model:value="form.url" /></a-form-item>
        <a-form-item label="Secret"><a-input v-model:value="form.secret" /></a-form-item>
        <a-form-item label="事件">
          <a-select v-model:value="form.events" mode="multiple" style="width: 100%">
            <a-select-option value="member.created">member.created</a-select-option>
            <a-select-option value="points.earned">points.earned</a-select-option>
            <a-select-option value="level.upgraded">level.upgraded</a-select-option>
            <a-select-option value="order.paid">order.paid</a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listWebhooks, createWebhook, deleteWebhook } from '@/api/webhooks'
import type { WebhookSubscriptionRead } from '@/types'

const subs = ref<WebhookSubscriptionRead[]>([])
const loading = ref(false)
const saving = ref(false)
const modalOpen = ref(false)
const form = reactive({ url: '', secret: '', events: [] as string[] })

const columns = [
  { title: 'URL', dataIndex: 'url', ellipsis: true },
  { title: '事件', key: 'events' },
  { title: '狀態', key: 'active', width: 80 },
  { title: '操作', key: 'actions', width: 80 },
]

async function load() {
  loading.value = true
  try {
    const { data } = await listWebhooks()
    subs.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '需 Pro 方案')
  } finally {
    loading.value = false
  }
}

function openCreate() {
  form.url = ''
  form.secret = ''
  form.events = ['member.created']
  modalOpen.value = true
}

async function save() {
  saving.value = true
  try {
    await createWebhook(form)
    message.success('已建立')
    modalOpen.value = false
    load()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '建立失敗')
  } finally {
    saving.value = false
  }
}

async function remove(id: string) {
  await deleteWebhook(id)
  load()
}

onMounted(load)
</script>
