<template>
  <div>
    <a-page-header title="跨品牌聯盟管理">
      <template #extra>
        <a-button type="primary" @click="createOpen = true">建立聯盟</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="networks" :loading="loading" row-key="id" :pagination="false" />

    <a-modal v-model:open="createOpen" title="建立聯盟" @ok="handleCreate" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="名稱"><a-input v-model:value="form.name" /></a-form-item>
        <a-form-item label="代碼"><a-input v-model:value="form.code" placeholder="north-food" /></a-form-item>
        <a-form-item label="說明"><a-textarea v-model:value="form.description" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listAllianceNetworks, createAllianceNetwork } from '@/api/alliance'
import type { AllianceNetworkRead } from '@/types'

const networks = ref<AllianceNetworkRead[]>([])
const loading = ref(false)
const saving = ref(false)
const createOpen = ref(false)
const form = reactive({ name: '', code: '', description: '' })

const columns = [
  { title: '名稱', dataIndex: 'name' },
  { title: '代碼', dataIndex: 'code' },
  { title: '狀態', dataIndex: 'status' },
  { title: '說明', dataIndex: 'description' },
]

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listAllianceNetworks()
    networks.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '載入失敗')
  } finally {
    loading.value = false
  }
}

async function handleCreate() {
  saving.value = true
  try {
    await createAllianceNetwork(form)
    message.success('已建立')
    createOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '建立失敗')
  } finally {
    saving.value = false
  }
}

onMounted(fetchData)
</script>
