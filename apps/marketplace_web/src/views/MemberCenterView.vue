<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.push({ name: 'home' })">‹</button>
      <span class="title">會員中心</span>
      <span class="spacer" />
    </header>

    <main v-if="!memberStore.isLoggedIn" class="state-page">
      <p>登入後即可查看訂單、點數與優惠券</p>
      <button class="submit" @click="loginOpen = true">會員登入</button>
    </main>

    <main v-else class="body">
      <section class="profile">
        <div class="avatar">{{ (profile?.name || profile?.phone || '?').charAt(0) }}</div>
        <div>
          <div class="pname">{{ profile?.name || '會員' }}</div>
          <div class="pphone">{{ profile?.phone }}</div>
        </div>
        <button class="logout" @click="doLogout">登出</button>
      </section>

      <div class="stat-row">
        <div class="stat"><span class="num">{{ profile?.points ?? 0 }}</span><span>跨店點數</span></div>
        <div class="stat"><span class="num">${{ Math.round((profile?.wallet_balance_cents ?? 0)) }}</span><span>錢包</span></div>
        <div class="stat"><span class="num">{{ coupons.length }}</span><span>優惠券</span></div>
      </div>

      <nav class="tabs">
        <button v-for="t in tabs" :key="t.key" :class="{ active: tab === t.key }" @click="tab = t.key">{{ t.label }}</button>
      </nav>

      <!-- Orders -->
      <section v-if="tab === 'orders'">
        <div v-if="!orders.length" class="empty">尚無訂單</div>
        <article v-for="o in orders" :key="o.id" class="row">
          <div class="row-head">
            <strong>{{ o.store_name }}</strong>
            <span>{{ formatDate(o.created_at) }}</span>
          </div>
          <div class="row-sub">{{ o.lines.map((l) => `${l.product_name}×${l.qty}`).join('、') }}</div>
          <div class="row-foot">
            <span>${{ Math.round(o.estimated_subtotal_cents) }} · {{ statusLabel(o.status) }}</span>
            <span class="actions">
              <button class="link" @click="reorder(o)">再訂一次</button>
              <button class="link" @click="openOrder(o)">查看</button>
            </span>
          </div>
        </article>
      </section>

      <!-- Points -->
      <section v-else-if="tab === 'points'">
        <div class="balance-card">目前 {{ points?.balance ?? 0 }} 點</div>
        <div v-if="!points?.entries.length" class="empty">尚無點數紀錄</div>
        <article v-for="(e, i) in points?.entries" :key="i" class="row">
          <div class="row-head">
            <span>{{ reasonLabel(e.reason) }}</span>
            <strong :class="{ pos: e.delta > 0, neg: e.delta < 0 }">{{ e.delta > 0 ? '+' : '' }}{{ e.delta }}</strong>
          </div>
          <div class="row-sub">{{ formatDate(e.created_at) }}</div>
        </article>
      </section>

      <!-- Coupons -->
      <section v-else-if="tab === 'coupons'">
        <div v-if="!coupons.length" class="empty">尚無可用優惠券</div>
        <article v-for="c in coupons" :key="c.code" class="coupon">
          <div class="cval">{{ couponLabel(c) }}</div>
          <div class="ccode">代碼 {{ c.code }}</div>
          <div v-if="c.min_spend_cents" class="cmin">滿 ${{ c.min_spend_cents }} 可用</div>
          <div v-if="c.expires_at" class="cexp">{{ formatDate(c.expires_at) }} 到期</div>
        </article>
      </section>

      <!-- Favorites -->
      <section v-else-if="tab === 'favorites'">
        <div v-if="!favorites.length" class="empty">尚無收藏店家</div>
        <article
          v-for="f in favorites"
          :key="f.slug"
          class="row clickable"
          @click="$router.push({ name: 'store', params: { slug: f.slug } })"
        >
          <div class="row-head">
            <strong>{{ f.display_name }}</strong>
            <span class="rating">★ {{ f.rating_avg ? f.rating_avg.toFixed(1) : '新店' }}</span>
          </div>
          <div class="row-sub">{{ f.tagline || (f.cuisine_tags || []).join('、') }}</div>
        </article>
      </section>

      <!-- Wallet -->
      <section v-else-if="tab === 'wallet'">
        <div class="balance-card">餘額 ${{ Math.round(wallet?.balance_cents ?? 0) }}</div>
        <div class="topup">
          <button v-for="amt in [100, 300, 500, 1000]" :key="amt" @click="doTopup(amt)">儲值 ${{ amt }}</button>
        </div>
        <div v-if="!wallet?.transactions.length" class="empty">尚無交易紀錄</div>
        <article v-for="(t, i) in wallet?.transactions" :key="i" class="row">
          <div class="row-head">
            <span>{{ walletReason(t.reason) }}</span>
            <strong :class="{ pos: t.delta_cents > 0, neg: t.delta_cents < 0 }">{{ t.delta_cents > 0 ? '+' : '' }}${{ Math.round(t.delta_cents) }}</strong>
          </div>
          <div class="row-sub">{{ formatDate(t.created_at) }}</div>
        </article>
      </section>

      <!-- Referral / profile -->
      <section v-else-if="tab === 'more'">
        <div class="card">
          <h3>推薦好友</h3>
          <p>分享您的推薦碼，雙方各得 {{ referral?.reward_points ?? 50 }} 點</p>
          <div class="ref-code">{{ referral?.code }}</div>
          <p class="muted">已成功推薦 {{ referral?.referred_count ?? 0 }} 人</p>
          <div class="apply">
            <input v-model="applyCode" placeholder="輸入他人的推薦碼" />
            <button class="link" @click="doApplyReferral">套用</button>
          </div>
        </div>
        <div class="card">
          <h3>個人資料</h3>
          <label>暱稱</label>
          <input v-model="editName" placeholder="暱稱" />
          <label>生日（領取生日禮）</label>
          <input v-model="editBirthday" type="date" />
          <button class="submit" @click="saveProfile">儲存</button>
        </div>
      </section>
    </main>

    <MemberLoginModal :open="loginOpen" :store-slug="''" @close="onLoginClose" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import {
  applyReferral,
  fetchMyCoupons,
  fetchMyFavorites,
  fetchMyOrders,
  fetchMyPoints,
  fetchMyProfile,
  fetchMyReferral,
  fetchMyWallet,
  topupWallet,
  updateMyProfile,
} from '@/api'
import { useMenuCacheStore } from '@/stores/menuCache'
import { useCartStore } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'
import MemberLoginModal from '@/components/MemberLoginModal.vue'
import type {
  MarketplaceOrderRead,
  MemberCoupon,
  MemberProfile,
  MarketplaceStoreSummary,
  PointsSummary,
  ReferralInfo,
  WalletRead,
} from '@/types'

const router = useRouter()
const memberStore = useMemberStore()
const menuCache = useMenuCacheStore()
const cart = useCartStore()

const tabs = [
  { key: 'orders', label: '訂單' },
  { key: 'points', label: '點數' },
  { key: 'coupons', label: '優惠券' },
  { key: 'favorites', label: '收藏' },
  { key: 'wallet', label: '錢包' },
  { key: 'more', label: '更多' },
] as const
const tab = ref<(typeof tabs)[number]['key']>('orders')
const loginOpen = ref(false)

const profile = ref<MemberProfile | null>(null)
const orders = ref<MarketplaceOrderRead[]>([])
const points = ref<PointsSummary | null>(null)
const coupons = ref<MemberCoupon[]>([])
const favorites = ref<MarketplaceStoreSummary[]>([])
const wallet = ref<WalletRead | null>(null)
const referral = ref<ReferralInfo | null>(null)
const applyCode = ref('')
const editName = ref('')
const editBirthday = ref('')

function formatDate(s: string) {
  return new Date(s).toLocaleDateString('zh-TW', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}
function statusLabel(s: string) {
  return ({ submitted: '已送出', accepted: '準備中', ready: '可取餐', merged: '已完成', cancelled: '已取消' } as Record<string, string>)[s] || s
}
function reasonLabel(r: string) {
  if (r.startsWith('order:')) return '消費累點'
  if (r.startsWith('redeem:')) return '點數折抵'
  if (r === 'referral_reward') return '推薦獎勵'
  if (r === 'referral_signup') return '註冊推薦'
  if (r === 'birthday_bonus') return '生日禮'
  return r
}
function walletReason(r: string) {
  return ({ topup: '儲值', spend: '消費', refund: '退款', bonus: '贈送' } as Record<string, string>)[r] || r
}
function couponLabel(c: MemberCoupon) {
  if (c.type === 'percentage') return `${c.value} 折優惠`
  if (c.type === 'amount') return `折抵 $${c.value}`
  return '優惠券'
}

async function loadAll() {
  if (!memberStore.isLoggedIn) return
  try {
    const [p, o, pt, cp, fav, w, ref_] = await Promise.all([
      fetchMyProfile(),
      fetchMyOrders(),
      fetchMyPoints(),
      fetchMyCoupons(),
      fetchMyFavorites(),
      fetchMyWallet(),
      fetchMyReferral(),
    ])
    profile.value = p.data
    orders.value = o.data
    points.value = pt.data
    coupons.value = cp.data
    favorites.value = fav.data
    wallet.value = w.data
    referral.value = ref_.data
    editName.value = p.data.name || ''
    editBirthday.value = p.data.birthday || ''
    memberStore.updatePoints(p.data.points)
  } catch {
    /* token may be expired */
    memberStore.logout()
  }
}

function openOrder(o: MarketplaceOrderRead) {
  router.push({ name: 'order-status', params: { orderId: o.id } })
}

async function reorder(o: MarketplaceOrderRead) {
  try {
    const menu = await menuCache.ensureMenu(o.store_slug)
    for (const ln of o.lines) {
      const product = menu.products.find((p) => p.id === ln.product_id)
      if (product) cart.add(menu.meta, product, ln.qty, ln.options_json || [])
    }
    router.push({ name: 'cart' })
  } catch {
    router.push({ name: 'store', params: { slug: o.store_slug } })
  }
}

async function doTopup(amt: number) {
  const { data } = await topupWallet(amt)
  wallet.value = data
  if (profile.value) profile.value.wallet_balance_cents = data.balance_cents
}

async function doApplyReferral() {
  if (!applyCode.value.trim()) return
  try {
    const { data } = await applyReferral(applyCode.value.trim())
    referral.value = data
    applyCode.value = ''
    await loadAll()
    alert('推薦碼套用成功，已獲得點數！')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { detail?: string } } }
    alert(err.response?.data?.detail || '套用失敗')
  }
}

async function saveProfile() {
  const { data } = await updateMyProfile({ name: editName.value || null, birthday: editBirthday.value || null })
  profile.value = data
  alert('已儲存')
}

function doLogout() {
  memberStore.logout()
  router.push({ name: 'home' })
}

function onLoginClose() {
  loginOpen.value = false
  loadAll()
}

watch(() => memberStore.isLoggedIn, (v) => v && loadAll())
onMounted(loadAll)
</script>

<style scoped>
.body { padding: 16px; padding-bottom: 40px; }
.profile { display: flex; align-items: center; gap: 12px; }
.avatar { width: 52px; height: 52px; border-radius: 50%; background: var(--accent); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 22px; font-weight: 700; }
.pname { font-weight: 700; font-size: 18px; }
.pphone { color: var(--muted); font-size: 13px; }
.logout { margin-left: auto; border: 1px solid var(--border); background: #fff; border-radius: 8px; padding: 6px 12px; font-size: 13px; }
.stat-row { display: flex; gap: 10px; margin: 16px 0; }
.stat { flex: 1; background: var(--surface); border-radius: 12px; padding: 14px; text-align: center; display: flex; flex-direction: column; gap: 4px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.stat .num { font-size: 20px; font-weight: 700; color: var(--accent); }
.stat span:last-child { font-size: 12px; color: var(--muted); }
.tabs { display: flex; gap: 6px; overflow-x: auto; margin-bottom: 14px; }
.tabs button { flex-shrink: 0; border: 0; background: var(--surface); padding: 8px 14px; border-radius: 16px; font-size: 14px; }
.tabs button.active { background: var(--accent); color: #fff; }
.row { background: var(--surface); border-radius: 10px; padding: 12px; margin-bottom: 10px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.row.clickable { cursor: pointer; }
.row-head { display: flex; justify-content: space-between; align-items: center; }
.row-head span { font-size: 12px; color: var(--muted); }
.row-sub { font-size: 13px; color: #555; margin-top: 6px; }
.row-foot { display: flex; justify-content: space-between; align-items: center; margin-top: 8px; font-size: 13px; }
.actions { display: flex; gap: 12px; }
.link { border: 0; background: none; color: var(--accent); padding: 0; }
.pos { color: #2a8; }
.neg { color: #b33; }
.rating { color: #e6a700 !important; font-weight: 600; }
.balance-card { background: var(--accent); color: #fff; border-radius: 12px; padding: 18px; font-size: 18px; font-weight: 700; margin-bottom: 12px; }
.empty { color: var(--muted); text-align: center; padding: 30px 0; }
.coupon { background: var(--surface); border-radius: 10px; padding: 14px; margin-bottom: 10px; border-left: 4px solid var(--accent); box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.cval { font-weight: 700; color: var(--accent); }
.ccode { font-size: 13px; margin-top: 4px; }
.cmin, .cexp { font-size: 12px; color: var(--muted); margin-top: 2px; }
.topup { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 14px; }
.topup button { border: 1px solid var(--accent); background: #fff; color: var(--accent); border-radius: 8px; padding: 8px 14px; }
.card { background: var(--surface); border-radius: 12px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.card h3 { margin: 0 0 8px; }
.card label { display: block; font-size: 13px; color: var(--muted); margin: 8px 0 4px; }
.card input { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 8px; }
.ref-code { font-size: 24px; font-weight: 700; letter-spacing: 2px; color: var(--accent); margin: 8px 0; }
.muted { color: var(--muted); font-size: 13px; }
.apply { display: flex; gap: 8px; align-items: center; margin-top: 10px; }
.apply input { flex: 1; }
.submit { width: 100%; border: 0; background: var(--accent); color: #fff; padding: 12px; border-radius: 8px; font-weight: 600; margin-top: 12px; }
</style>
