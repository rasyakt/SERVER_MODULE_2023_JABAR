<script setup>
import { ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import api from './api';

const router = useRouter();
const route = useRoute();

const isAuthenticated = ref(false);
const user = ref(null);

const checkAuth = () => {
  const token = localStorage.getItem('accessToken');
  const storedUser = localStorage.getItem('user');
  isAuthenticated.value = !!token;
  user.value = storedUser ? JSON.parse(storedUser) : null;
};

// Check on initial load and route changes
watch(() => route.path, checkAuth, { immediate: true });

const handleLogout = async () => {
  try {
    await api.post('/auth/logout');
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('user');
    isAuthenticated.value = false;
    user.value = null;
    router.push('/login');
  }
};
</script>

<template>
  <div id="app">
    <nav class="navbar">
      <router-link to="/" class="nav-brand">
        Formify <span>Inc.</span>
      </router-link>
      
      <div v-if="isAuthenticated" class="nav-menu">
        <span class="nav-user" v-if="user">{{ user.name }} ({{ user.email }})</span>
        <router-link to="/" class="btn btn-secondary btn-sm">Dashboard</router-link>
        <button @click="handleLogout" class="btn btn-primary btn-sm">Logout</button>
      </div>
    </nav>

    <main class="container">
      <router-view></router-view>
    </main>
  </div>
</template>

<style>
/* Global CSS transitions or layout resets */
</style>
