import { createRouter, createWebHistory } from 'vue-router';

import Login from './views/Login.vue';
import Home from './views/Home.vue';
import CreateForm from './views/CreateForm.vue';
import DetailForm from './views/DetailForm.vue';
import SubmitForm from './views/SubmitForm.vue';
import Forbidden from './views/Forbidden.vue';

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { guest: true }
  },
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { requiresAuth: true }
  },
  {
    path: '/create-form',
    name: 'CreateForm',
    component: CreateForm,
    meta: { requiresAuth: true }
  },
  {
    path: '/forms/:slug',
    name: 'DetailForm',
    component: DetailForm,
    meta: { requiresAuth: true }
  },
  {
    path: '/forms/:slug/submit',
    name: 'SubmitForm',
    component: SubmitForm,
    meta: { requiresAuth: true } // Submitting response requires authentication in Sanctum too to check user email domain!
  },
  {
    path: '/forbidden',
    name: 'Forbidden',
    component: Forbidden
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

// Navigation Guard: Check Auth
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('accessToken');
  
  if (to.matched.some(record => record.meta.requiresAuth)) {
    if (!token) {
      next({ name: 'Login' });
    } else {
      next();
    }
  } else if (to.matched.some(record => record.meta.guest)) {
    if (token) {
      next({ name: 'Home' });
    } else {
      next();
    }
  } else {
    next();
  }
});

export default router;
