<script setup>
import { ref, onMounted } from 'vue';
import api from '../api';

const forms = ref([]);
const isLoading = ref(false);
const errorMsg = ref('');
const copiedSlug = ref('');

const fetchForms = async () => {
  isLoading.value = true;
  errorMsg.value = '';
  
  try {
    const response = await api.get('/forms');
    forms.value = response.data.forms || [];
  } catch (error) {
    errorMsg.value = 'Failed to load forms. Please try again.';
    console.error(error);
  } finally {
    isLoading.value = false;
  }
};

const getSubmitUrl = (slug) => {
  return `${window.location.origin}/forms/${slug}/submit`;
};

const copyToClipboard = (slug) => {
  const url = getSubmitUrl(slug);
  navigator.clipboard.writeText(url).then(() => {
    copiedSlug.value = slug;
    setTimeout(() => {
      copiedSlug.value = '';
    }, 2000);
  });
};

onMounted(fetchForms);
</script>

<template>
  <div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
      <div>
        <h1>My Forms</h1>
        <p class="subtitle" style="margin-bottom: 0;">Manage and monitor responses for all your forms</p>
      </div>
      <router-link to="/create-form" class="btn btn-primary">
        Create Form
      </router-link>
    </div>

    <!-- Error Alert -->
    <div v-if="errorMsg" class="alert alert-danger">
      {{ errorMsg }}
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" style="text-align: center; padding: 3rem;">
      <p style="color: var(--text-secondary);">Loading your forms...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="forms.length === 0" class="card" style="text-align: center; padding: 4rem 2rem;">
      <div style="font-size: 3rem; color: var(--text-muted); margin-bottom: 1rem;">📝</div>
      <h2>No Forms Created Yet</h2>
      <p class="subtitle" style="margin-bottom: 1.5rem;">Create your first custom form to start collecting responses</p>
      <router-link to="/create-form" class="btn btn-primary">
        Create Your First Form
      </router-link>
    </div>

    <!-- Forms Listing -->
    <div v-else class="list-grid">
      <div v-for="form in forms" :key="form.id" class="list-item">
        <div class="list-item-header">
          <router-link :to="`/forms/${form.slug}`" class="list-item-title">
            {{ form.name }}
          </router-link>
          <span class="badge" style="font-size: 0.7rem;">
            /forms/{{ form.slug }}
          </span>
        </div>
        
        <p class="list-item-desc" v-if="form.description">
          {{ form.description }}
        </p>
        <p class="list-item-desc" v-else style="color: var(--text-muted); font-style: italic;">
          No description provided.
        </p>

        <div class="list-item-meta">
          <span>Limit 1 response: <strong>{{ form.limit_one_response === 1 ? 'Yes' : 'No' }}</strong></span>
        </div>

        <div style="display: flex; gap: 0.5rem; margin-top: 1rem; align-items: center; background-color: #f8fafc; padding: 0.5rem; border-radius: var(--radius-sm); border: 1px solid var(--border-color);">
          <input 
            type="text" 
            readonly 
            :value="getSubmitUrl(form.slug)" 
            class="form-control" 
            style="font-size: 0.8rem; padding: 0.25rem 0.5rem; background-color: #ffffff;"
            @click="$event.target.select()"
          />
          <button @click="copyToClipboard(form.slug)" class="btn btn-secondary btn-sm" style="white-space: nowrap;">
            {{ copiedSlug === form.slug ? 'Copied!' : 'Copy Link' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
