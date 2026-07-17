<template>
  <div class="ff-tabs">
    <button type="button" :class="{ active: model === 'pickup' }" @click="model = 'pickup'">
      <span class="ic">🛍️</span>
      <span>外帶自取</span>
    </button>
    <button type="button" :class="{ active: model === 'delivery' }" @click="model = 'delivery'">
      <span class="ic">🛵</span>
      <span>外送</span>
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
  background: transparent;
  border-radius: 0;
  padding: 0;
}
.ff-tabs button {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  border: 1px solid var(--border);
  background: var(--surface);
  border-radius: 7px;
  padding: 8px 6px;
  font-size: 13px;
  font-weight: 700;
  color: var(--muted);
}
.ff-tabs button.active {
  background: var(--surface);
  color: var(--accent);
  border-color: var(--accent);
  border-width: 1.5px;
  box-shadow: none;
}
.ff-tabs .ic {
  font-size: 16px;
}
</style>
