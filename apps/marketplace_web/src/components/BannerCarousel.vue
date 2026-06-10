<template>
  <div v-if="banners.length" class="banner-carousel">
    <div class="track">
      <button
        v-for="b in banners"
        :key="b.id"
        type="button"
        class="banner"
        @click="emit('select', b)"
      >
        <img :src="resolveUploadPath(b.image_url)" :alt="b.title" />
        <div v-if="b.title || b.subtitle" class="overlay">
          <div class="title">{{ b.title }}</div>
          <div v-if="b.subtitle" class="subtitle">{{ b.subtitle }}</div>
        </div>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { resolveUploadPath } from '@/api'
import type { MarketplaceBanner } from '@/types'

defineProps<{ banners: MarketplaceBanner[] }>()
const emit = defineEmits<{ select: [banner: MarketplaceBanner] }>()
</script>

<style scoped>
.banner-carousel {
  overflow: hidden;
}
.track {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  padding-bottom: 4px;
}
.track::-webkit-scrollbar {
  display: none;
}
.banner {
  position: relative;
  flex: 0 0 86%;
  scroll-snap-align: start;
  border: 0;
  padding: 0;
  border-radius: 16px;
  overflow: hidden;
  background: var(--accent-soft);
  aspect-ratio: 16 / 7;
}
.banner img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.overlay {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 14px 16px;
  text-align: left;
  background: linear-gradient(0deg, rgba(0, 0, 0, 0.55), rgba(0, 0, 0, 0));
  color: #fff;
}
.title {
  font-size: 16px;
  font-weight: 700;
}
.subtitle {
  font-size: 12px;
  opacity: 0.92;
  margin-top: 2px;
}
@media (min-width: 900px) {
  .banner {
    flex-basis: 48%;
    aspect-ratio: 16 / 6;
  }
}
</style>
