import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { adaptApiMenu } from '@/adapters/menuAdapter'
import { fetchStoreMenu } from '@/api'
import { buildEntryQuery, parseEntryFromSearch } from '@/entry'
import { buildDemoMenu, MEMBER_DISCOUNT_CENTS } from '@/mock/demoMenu'
import type {
  DoneSnapshot,
  FulfillmentMode,
  PaymentUiKey,
  ShoppingMenu,
} from '@/types'
import { useCartStore } from './cart'

export const useSessionStore = defineStore('session', () => {
  const storeSlug = ref('')
  const mode = ref<FulfillmentMode>('takeout')
  const table = ref('')
  const lockedDineIn = ref(false)
  const menu = ref<ShoppingMenu | null>(null)
  const loading = ref(false)
  const loadError = ref('')
  const pickTime = ref('')
  const addrLine = ref('')
  const addrPhone = ref('')
  const customerName = ref('客人')
  const payMode = ref<PaymentUiKey>('linepay')
  const inv = ref<'member' | 'carrier' | 'tax'>('member')
  const memberOn = ref(true)
  const orderNote = ref('')
  const done = ref<DoneSnapshot | null>(null)
  const submitting = ref(false)
  const submitError = ref('')

  const store = computed(() => menu.value?.store ?? null)
  const isDemo = computed(() => menu.value?.isDemo ?? true)
  const deliveryFee = computed(() =>
    mode.value === 'delivery' ? store.value?.deliveryFeeCents ?? 0 : 0,
  )
  const discount = computed(() => {
    const cart = useCartStore()
    return memberOn.value && cart.lines.length ? MEMBER_DISCOUNT_CENTS : 0
  })

  function applySearch(search: string) {
    const e = parseEntryFromSearch(search)
    storeSlug.value = e.store
    mode.value = e.mode
    table.value = e.table
    lockedDineIn.value = e.lockedDineIn
  }

  function entryQuery() {
    return buildEntryQuery({
      store: storeSlug.value || undefined,
      mode: mode.value,
      table: lockedDineIn.value || mode.value === 'dinein' ? table.value || undefined : undefined,
    })
  }

  async function loadMenu() {
    loading.value = true
    loadError.value = ''
    try {
      if (!storeSlug.value) {
        menu.value = buildDemoMenu()
        return
      }
      const { data } = await fetchStoreMenu(storeSlug.value)
      menu.value = adaptApiMenu(data)
      // Clamp mode to what store supports
      if (mode.value === 'delivery' && !menu.value.store.supportsDelivery) mode.value = 'takeout'
      if (mode.value === 'takeout' && !menu.value.store.supportsPickup && menu.value.store.supportsDelivery) {
        mode.value = 'delivery'
      }
      if (mode.value === 'dinein' && !menu.value.store.supportsDineIn && !lockedDineIn.value) {
        mode.value = menu.value.store.supportsPickup ? 'takeout' : 'delivery'
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : '載入菜單失敗'
      loadError.value = `${msg}（已改用示菜單）`
      menu.value = buildDemoMenu()
      menu.value.store.slug = storeSlug.value || 'demo'
    } finally {
      loading.value = false
    }
  }

  function switchMode(next: FulfillmentMode) {
    if (lockedDineIn.value) return
    const cart = useCartStore()
    if (next === 'delivery') {
      const removed = cart.removeNoDelivery()
      if (removed.length) {
        window.alert(`已從購物車移除不外送的品項：${removed.join('、')}`)
      }
    }
    mode.value = next
    pickTime.value = ''
    payMode.value = 'linepay'
  }

  function simulateEntry(entry: 'dinein' | 'takeout') {
    const cart = useCartStore()
    cart.clear()
    pickTime.value = ''
    addrLine.value = ''
    addrPhone.value = ''
    memberOn.value = true
    payMode.value = 'linepay'
    done.value = null
    if (entry === 'dinein') {
      mode.value = 'dinein'
      table.value = table.value || 'A5'
      lockedDineIn.value = true
    } else {
      mode.value = 'takeout'
      table.value = ''
      lockedDineIn.value = false
    }
  }

  function resetAfterDone() {
    const cart = useCartStore()
    cart.clear()
    pickTime.value = ''
    addrLine.value = ''
    addrPhone.value = ''
    memberOn.value = true
    payMode.value = 'linepay'
    orderNote.value = ''
    done.value = null
    submitError.value = ''
  }

  return {
    storeSlug,
    mode,
    table,
    lockedDineIn,
    menu,
    loading,
    loadError,
    pickTime,
    addrLine,
    addrPhone,
    customerName,
    payMode,
    inv,
    memberOn,
    orderNote,
    done,
    submitting,
    submitError,
    store,
    isDemo,
    deliveryFee,
    discount,
    applySearch,
    entryQuery,
    loadMenu,
    switchMode,
    simulateEntry,
    resetAfterDone,
  }
})
