<template>
  <div v-if="banners.length" class="banner-carousel">
    <div
      ref="trackEl"
      class="track"
      @scroll.passive="onScroll"
      @pointerenter="stop"
      @pointerleave="start"
    >
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
    <div v-if="banners.length > 1" class="dots">
      <button
        v-for="(b, i) in banners"
        :key="b.id"
        type="button"
        class="dot"
        :class="{ active: i === index }"
        :aria-label="`第 ${i + 1} 張`"
        @click="go(i)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { resolveUploadPath } from '@/api'
import type { MarketplaceBanner } from '@/types'

const props = defineProps<{ banners: MarketplaceBanner[] }>()
const emit = defineEmits<{ select: [banner: MarketplaceBanner] }>()

const trackEl = ref<HTMLElement | null>(null)
const index = ref(0)
let timer: number | undefined

function go(i: number) {
  const track = trackEl.value
  const items = track?.children
  if (!track || !items || !items.length) return
  const n = items.length
  index.value = ((i % n) + n) % n
  const el = items[index.value] as HTMLElement
  track.scrollTo({ left: el.offsetLeft, behavior: 'smooth' })
}

function start() {
  stop()
  if (props.banners.length <= 1) return
  timer = window.setInterval(() => go(index.value + 1), 4500)
}

function stop() {
  if (timer) {
    window.clearInterval(timer)
    timer = undefined
  }
}

function onScroll() {
  const track = trackEl.value
  if (!track) return
  const items = Array.from(track.children) as HTMLElement[]
  let best = 0
  let bestDist = Infinity
  items.forEach((el, i) => {
    const dist = Math.abs(el.offsetLeft - track.scrollLeft)
    if (dist < bestDist) {
      bestDist = dist
      best = i
    }
  })
  index.value = best
}

onMounted(start)
onBeforeUnmount(stop)
watch(() => props.banners.length, start)
</script>

<style scoped>
.banner-carousel {
  overflow: hidden;
}
.track {
  position: relative;
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
.dots {
  display: flex;
  justify-content: center;
  gap: 6px;
  margin-top: 8px;
}
.dot {
  width: 7px;
  height: 7px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: var(--border);
  cursor: pointer;
  transition: width 0.2s, background 0.2s;
}
.dot.active {
  width: 18px;
  border-radius: 4px;
  background: var(--accent);
}
@media (min-width: 900px) {
  .banner {
    flex-basis: 48%;
    aspect-ratio: 16 / 6;
  }
}
</style>
