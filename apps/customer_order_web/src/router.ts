import { createRouter, createWebHistory } from 'vue-router'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/order' },
    {
      path: '/order',
      name: 'order',
      component: () => import('@/views/MenuView.vue'),
    },
    {
      path: '/cart',
      name: 'cart',
      component: () => import('@/views/CartView.vue'),
    },
    {
      path: '/status/:orderId',
      name: 'status',
      component: () => import('@/views/StatusView.vue'),
      props: true,
    },
    {
      path: '/no-token',
      name: 'no-token',
      component: () => import('@/views/NoTokenView.vue'),
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/order',
    },
  ],
})
