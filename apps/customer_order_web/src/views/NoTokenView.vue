<template>
  <div class="empty-page">
    <h1>沒有桌位資訊</h1>
    <p>請使用桌上的 QR Code 進入點餐頁。</p>
    <p class="hint">若 QR 無法掃描，請聯絡店員協助。</p>
  </div>
</template>

<style scoped>
.empty-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 24px;
  gap: 8px;
}
.empty-page h1 {
  font-size: 22px;
  margin: 0;
}
.empty-page .hint {
  color: #999;
  font-size: 14px;
}
</style>
