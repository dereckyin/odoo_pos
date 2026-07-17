import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useShiftStore } from '@/stores/shift'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue') },
    { path: '/shift', name: 'shift', component: () => import('@/views/ShiftView.vue'), meta: { auth: true } },
    {
      path: '/',
      component: () => import('@/layouts/PosLayout.vue'),
      meta: { auth: true, shift: true },
      children: [
        { path: '', name: 'cashier', component: () => import('@/views/CashierView.vue') },
        { path: 'kds', name: 'kds', component: () => import('@/views/KdsView.vue') },
        { path: 'tables', name: 'tables', component: () => import('@/views/TablesView.vue') },
        { path: 'printer', name: 'printer', component: () => import('@/views/PrinterSetupView.vue') },
      ],
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()
  if (to.meta.auth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.name === 'login' && auth.isAuthenticated) {
    return { name: 'cashier' }
  }
  if (to.meta.shift) {
    const shift = useShiftStore()
    if (!shift.current) await shift.refresh()
    if (!shift.current) return { name: 'shift' }
  }
  return true
})

export default router
