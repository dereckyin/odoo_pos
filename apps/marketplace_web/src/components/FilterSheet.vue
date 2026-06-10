<template>
  <div v-if="open" class="overlay" @click.self="emit('close')">
    <div class="sheet">
      <div class="grab" />
      <h3>排序與篩選</h3>

      <FilterControls v-model:sort="sort" v-model:prices="prices" v-model:open-now="openNow" />

      <div class="actions">
        <button type="button" class="apply" @click="emit('close')">查看結果</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import FilterControls from './FilterControls.vue'

defineProps<{ open: boolean }>()
const emit = defineEmits<{ close: [] }>()

const sort = defineModel<string>('sort', { required: true })
const prices = defineModel<number[]>('prices', { required: true })
const openNow = defineModel<boolean>('openNow', { required: true })
</script>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 120;
}
.sheet {
  background: var(--surface);
  width: 100%;
  border-radius: 18px 18px 0 0;
  padding: 12px 18px calc(18px + env(safe-area-inset-bottom));
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 80vh;
  overflow-y: auto;
}
.grab {
  width: 40px;
  height: 4px;
  border-radius: 2px;
  background: var(--border);
  margin: 0 auto 4px;
}
h3 {
  margin: 0;
  font-size: 16px;
}
.actions {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}
.actions button {
  flex: 1;
  border-radius: 12px;
  padding: 12px;
  font-size: 15px;
  font-weight: 600;
}
.apply {
  border: 0;
  background: var(--accent);
  color: #fff;
}
@media (min-width: 900px) {
  .overlay {
    align-items: center;
  }
  .sheet {
    width: min(440px, 92vw);
    border-radius: 16px;
  }
  .grab {
    display: none;
  }
}
</style>
