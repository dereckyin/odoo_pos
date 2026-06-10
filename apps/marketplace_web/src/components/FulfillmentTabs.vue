<template>
  <div class="ff-tabs">
    <button type="button" :class="{ active: model === 'delivery' }" @click="model = 'delivery'">
      <span class="ic">🛵</span>
      <span>外送</span>
    </button>
    <button type="button" :class="{ active: model === 'pickup' }" @click="model = 'pickup'">
      <span class="ic">🛍️</span>
      <span>外帶自取</span>
    </button>
  </div>
</template>

<script setup lang="ts">
const model = defineModel<'delivery' | 'pickup'>({ required: true })
</script>

<style scoped>
.ff-tabs {
  display: flex;
  gap: 8px;
  background: var(--accent-soft);
  border-radius: 14px;
  padding: 4px;
}
.ff-tabs button {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border: 0;
  background: transparent;
  border-radius: 11px;
  padding: 10px 8px;
  font-size: 15px;
  font-weight: 600;
  color: var(--muted);
}
.ff-tabs button.active {
  background: var(--surface);
  color: var(--accent);
  box-shadow: 0 1px 4px rgba(51, 51, 51, 0.12);
}
.ff-tabs .ic {
  font-size: 17px;
}
</style>
