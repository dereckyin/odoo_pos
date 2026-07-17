<template>
  <div class="printer-setup">
    <h2>印表機設定</h2>

    <p v-if="!printer.supported" class="warning">
      這個瀏覽器/環境不支援 WebUSB，無法直接列印。請改用 Chrome 或 Edge，並確認網址是
      <code>https://</code> 或 <code>http://localhost</code>（iOS 完全不支援 WebUSB）。
    </p>

    <div class="cards">
      <div v-for="kind in kinds" :key="kind" class="card">
        <div class="card-head">
          <span class="name">{{ KIND_LABEL[kind] }}</span>
          <span class="badge" :class="printer.status[kind]">{{ statusLabel(printer.status[kind]) }}</span>
        </div>
        <p v-if="printer.lastError[kind]" class="err">{{ printer.lastError[kind] }}</p>
        <div class="actions">
          <button :disabled="!printer.supported || printer.status[kind] === 'connecting'" @click="printer.pair(kind)">
            {{ printer.status[kind] === 'ready' ? '重新配對' : '配對裝置' }}
          </button>
          <button class="ghost" :disabled="printer.status[kind] !== 'ready'" @click="printer.testPrint(kind)">
            測試列印
          </button>
          <button class="ghost danger" :disabled="printer.status[kind] === 'unpaired'" @click="printer.forget(kind)">
            忘記裝置
          </button>
        </div>
      </div>
    </div>

    <div class="poll-status">
      <span>輪詢：{{ printer.polling ? '運作中' : '已停止' }}</span>
      <span v-if="printer.lastPolledAt">上次輪詢 {{ formatTime(printer.lastPolledAt) }}</span>
      <span>已列印 {{ printer.printedCount }}</span>
      <span>失敗 {{ printer.failedCount }}</span>
      <button class="ghost" @click="printer.refreshStatus()">重新整理狀態</button>
    </div>

    <p v-if="!anyReady" class="hint-box">
      目前沒有已配對的印表機，系統<strong>不會搶列印佇列</strong>（避免未配對時一直失敗）。
      請用 Chrome／Edge，USB 接上印表機後點「配對裝置」。Windows 若 claim 失敗，需用 Zadig 換成 WinUSB。
      若這台電腦不印，請改用已配對的 Flutter POS／另一台網頁收銀。
    </p>

    <div class="log">
      <div v-for="(entry, i) in printer.logs" :key="i" class="log-line" :class="entry.level">
        [{{ entry.time }}] {{ entry.message }}
      </div>
      <p v-if="!printer.logs.length" class="empty">尚無紀錄</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { usePrinterStore } from '@/stores/printer'
import { KIND_LABEL } from '@/print/WebUSBDriver'
import type { PrinterKind, PrinterStatus } from '@/print/types'

const printer = usePrinterStore()
const kinds: PrinterKind[] = ['receipt', 'kitchen', 'label']
const anyReady = computed(() => kinds.some((k) => printer.status[k] === 'ready'))

function statusLabel(s: PrinterStatus): string {
  switch (s) {
    case 'ready':
      return '就緒'
    case 'connecting':
      return '連線中'
    case 'error':
      return '錯誤'
    default:
      return '未配對'
  }
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('zh-TW', { hour12: false })
}
</script>

<style scoped>
.printer-setup {
  padding: 20px;
  max-width: 900px;
  margin: 0 auto;
}
.warning {
  background: #fffbe6;
  border: 1px solid #ffe58f;
  color: #874d00;
  padding: 10px 14px;
  border-radius: 8px;
  margin-bottom: 16px;
}
.hint-box {
  background: #f6ffed;
  border: 1px solid #b7eb8f;
  color: #389e0d;
  padding: 10px 14px;
  border-radius: 8px;
  margin: 0 0 16px;
  font-size: 13px;
  line-height: 1.55;
}
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}
.card {
  background: #fff;
  border: 1px solid #e8e8e8;
  border-radius: 10px;
  padding: 14px;
}
.card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.name {
  font-weight: 700;
}
.badge {
  font-size: 0.8rem;
  padding: 2px 10px;
  border-radius: 999px;
  background: #f0f0f0;
  color: #666;
}
.badge.ready {
  background: #f6ffed;
  color: #389e0d;
}
.badge.connecting {
  background: #e6f4ff;
  color: #1677ff;
}
.badge.error {
  background: #fff1f0;
  color: #cf1322;
}
.err {
  color: #cf1322;
  font-size: 0.85rem;
  margin-bottom: 8px;
}
.actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.actions button {
  padding: 6px 12px;
  border: none;
  border-radius: 6px;
  background: #1677ff;
  color: #fff;
  font-size: 0.85rem;
}
.actions button.ghost {
  background: #fff;
  border: 1px solid #d9d9d9;
  color: #333;
}
.actions button.ghost.danger {
  color: #cf1322;
  border-color: #ffa39e;
}
.actions button:disabled {
  opacity: 0.5;
}
.poll-status {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  align-items: center;
  font-size: 0.85rem;
  color: #666;
  margin-bottom: 12px;
}
.poll-status button {
  padding: 4px 10px;
  border: 1px solid #d9d9d9;
  border-radius: 6px;
  background: #fff;
}
.log {
  background: #001529;
  color: #d9d9d9;
  border-radius: 8px;
  padding: 10px 12px;
  font-family: 'SFMono-Regular', Consolas, monospace;
  font-size: 0.78rem;
  max-height: 320px;
  overflow-y: auto;
}
.log-line.ok {
  color: #95de64;
}
.log-line.error {
  color: #ff7875;
}
.log .empty {
  color: #888;
}
</style>
