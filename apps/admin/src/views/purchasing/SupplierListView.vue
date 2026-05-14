<template>
  <div>
    <a-page-header title="供應商" />
    <a-space style="margin-bottom: 16px">
      <a-button type="primary" @click="openCreate">新增供應商</a-button>
    </a-space>
    <a-table :columns="columns" :data-source="rows" :loading="loading" row-key="id" :pagination="{ pageSize: 30 }" />
    <a-modal v-model:open="modalOpen" title="新增供應商" ok-text="建立" @ok="submitCreate" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="代號" required><a-input v-model:value="form.code" /></a-form-item>
        <a-form-item label="名稱" required><a-input v-model:value="form.name" /></a-form-item>
        <a-form-item label="聯絡人"><a-input v-model:value="form.contact_name" /></a-form-item>
        <a-form-item label="電話"><a-input v-model:value="form.phone" /></a-form-item>
        <a-form-item label="備註"><a-textarea v-model:value="form.note" :rows="2" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listSuppliers, createSupplier } from '@/api/purchasing'
import type { SupplierRead, SupplierCreate } from '@/types'

const rows = ref<SupplierRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const form = ref<SupplierCreate>({ code: '', name: '', contact_name: '', phone: '', note: '' })

const columns = [
  { title: '代號', dataIndex: 'code', width: 120 },
  { title: '名稱', dataIndex: 'name' },
  { title: '聯絡人', dataIndex: 'contact_name', width: 120 },
  { title: '電話', dataIndex: 'phone', width: 140 },
]

async function load() {
  loading.value = true
  try {
    const { data } = await listSuppliers()
    rows.value = data
  } finally {
    loading.value = false
  }
}

function openCreate() {
  form.value = { code: '', name: '', contact_name: '', phone: '', note: '' }
  modalOpen.value = true
}

async function submitCreate() {
  if (!form.value.code.trim() || !form.value.name.trim()) {
    message.error('請填代號與名稱')
    return
  }
  saving.value = true
  try {
    await createSupplier({
      code: form.value.code.trim(),
      name: form.value.name.trim(),
      contact_name: form.value.contact_name?.trim() || null,
      phone: form.value.phone?.trim() || null,
      note: form.value.note?.trim() || null,
    })
    message.success('已建立')
    modalOpen.value = false
    await load()
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '建立失敗')
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>
