<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api';

const router = useRouter();

const email = ref('');
const password = ref('');
const errorMsg = ref('');
const validationErrors = ref({});
const isLoading = ref(false);

const handleLogin = async () => {
  errorMsg.value = '';
  validationErrors.value = {};
  isLoading.value = true;
  
  try {
    const response = await api.post('/auth/login', {
      email: email.value,
      password: password.value
    });
    
    // Store credentials
    localStorage.setItem('accessToken', response.data.user.accessToken);
    localStorage.setItem('user', JSON.stringify({
      name: response.data.user.name,
      email: response.data.user.email
    }));
    
    // Redirect to home dashboard
    router.push('/');
  } catch (error) {
    if (error.response) {
      if (error.response.status === 422) {
        validationErrors.value = error.response.data.errors || {};
        errorMsg.value = error.response.data.message || 'Validation failed';
      } else if (error.response.status === 401) {
        errorMsg.value = error.response.data.message || 'Incorrect credentials';
      } else {
        errorMsg.value = 'An unexpected error occurred. Please try again.';
      }
    } else {
      errorMsg.value = 'Unable to connect to server. Please check your connection.';
    }
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div class="card" style="max-width: 420px; margin: 4rem auto;">
    <h2>Login to Formify</h2>
    <p class="subtitle" style="margin-bottom: 1.5rem;">Enter your credentials to manage your forms</p>

    <!-- Error Alert Box -->
    <div v-if="errorMsg" class="alert alert-danger">
      {{ errorMsg }}
    </div>

    <form @submit.prevent="handleLogin">
      <div class="form-group">
        <label for="email">Email Address</label>
        <input 
          id="email"
          type="email" 
          v-model="email" 
          class="form-control" 
          placeholder="e.g. user1@webtech.id"
          required
        />
        <span v-if="validationErrors.email" style="color: var(--danger-color); font-size: 0.75rem;">
          {{ validationErrors.email[0] }}
        </span>
      </div>

      <div class="form-group" style="margin-bottom: 1.5rem;">
        <label for="password">Password</label>
        <input 
          id="password"
          type="password" 
          v-model="password" 
          class="form-control" 
          placeholder="Enter password"
          required
        />
        <span v-if="validationErrors.password" style="color: var(--danger-color); font-size: 0.75rem;">
          {{ validationErrors.password[0] }}
        </span>
      </div>

      <button type="submit" class="btn btn-primary" style="width: 100%;" :disabled="isLoading">
        {{ isLoading ? 'Logging in...' : 'Login' }}
      </button>
    </form>
  </div>
</template>
