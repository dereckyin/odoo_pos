import { createRouter, createWebHistory } from 'vue-router'

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: () => import('@/views/HomeGateView.vue') },
    { path: '/cart', name: 'cart', component: () => import('@/views/CartView.vue') },
    { path: '/checkout', name: 'checkout', component: () => import('@/views/CheckoutView.vue') },
    { path: '/done', name: 'done', component: () => import('@/views/DoneView.vue') },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})
