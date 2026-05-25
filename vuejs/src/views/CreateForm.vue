<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api';

const router = useRouter();

const name = ref('');
const slug = ref('');
const description = ref('');
const limitOneResponse = ref(false);
const domainInput = ref('');
const allowedDomains = ref([]);

const errorMsg = ref('');
const validationErrors = ref({});
const isLoading = ref(false);

const addDomain = () => {
  const domain = domainInput.value.trim().toLowerCase();
  if (domain && !allowedDomains.value.includes(domain)) {
    // Basic domain validation
    if (domain.includes('.') && domain.length > 3) {
      allowedDomains.value.push(domain);
      domainInput.value = '';
    } else {
      errorMsg.value = 'Please enter a valid domain name (e.g. webtech.id)';
    }
  }
};

const removeDomain = (index) => {
  allowedDomains.value.splice(index, 1);
};

const handleSubmit = async () => {
  errorMsg.value = '';
  validationErrors.value = {};
  isLoading.value = true;
  
  // Format slug automatically just in case
  const formattedSlug = slug.value.trim().toLowerCase().replace(/\s+/g, '-');
  
  try {
    const response = await api.post('/forms', {
      name: name.value,
      slug: formattedSlug,
      description: description.value,
      limit_one_response: limitOneResponse.value,
      allowed_domains: allowedDomains.value
    });
    
    // Redirect to newly created form detail page to add questions
    router.push(`/forms/${response.data.form.slug}`);
  } catch (error) {
    if (error.response && error.response.status === 422) {
      validationErrors.value = error.response.data.errors || {};
      errorMsg.value = error.response.data.message || 'Validation failed';
    } else {
      errorMsg.value = 'An error occurred while creating the form. Please try again.';
      console.error(error);
    }
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div style="max-width: 600px; margin: 0 auto;">
    <div style="margin-bottom: 2rem;">
      <router-link to="/" class="btn btn-secondary btn-sm" style="margin-bottom: 1rem;">
        ← Back to Dashboard
      </router-link>
      <h1>Create New Form</h1>
      <p class="subtitle" style="margin-bottom: 0;">Specify details, settings and email domain restrictions</p>
    </div>

    <!-- Error Banner -->
    <div v-if="errorMsg" class="alert alert-danger">
      {{ errorMsg }}
    </div>

    <form @submit.prevent="handleSubmit" class="card">
      <div class="form-group">
        <label for="name">Form Name <span style="color: var(--danger-color);">*</span></label>
        <input 
          id="name"
          type="text" 
          v-model="name" 
          class="form-control" 
          placeholder="e.g. Stacks of Web Tech Members"
          required
        />
        <span v-if="validationErrors.name" style="color: var(--danger-color); font-size: 0.75rem;">
          {{ validationErrors.name[0] }}
        </span>
      </div>

      <div class="form-group">
        <label for="slug">Form Slug <span style="color: var(--danger-color);">*</span></label>
        <input 
          id="slug"
          type="text" 
          v-model="slug" 
          class="form-control" 
          placeholder="e.g. member-stacks (alphanumeric, dash and dot only)"
          required
        />
        <span v-if="validationErrors.slug" style="color: var(--danger-color); font-size: 0.75rem;">
          {{ validationErrors.slug[0] }}
        </span>
      </div>

      <div class="form-group">
        <label for="description">Description</label>
        <textarea 
          id="description"
          v-model="description" 
          class="form-control" 
          placeholder="Add form description..."
        ></textarea>
        <span v-if="validationErrors.description" style="color: var(--danger-color); font-size: 0.75rem;">
          {{ validationErrors.description[0] }}
        </span>
      </div>

      <!-- Switch limit one response -->
      <div class="form-group" style="margin: 1.5rem 0;">
        <label class="switch-container">
          <span class="switch">
            <input type="checkbox" v-model="limitOneResponse" />
            <span class="slider"></span>
          </span>
          <div>
            <div style="font-weight: 500;">Limit to 1 response</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">Users can only submit this form once</div>
          </div>
        </label>
      </div>

      <!-- Allowed Domains tagging system -->
      <div class="form-group" style="margin-bottom: 2rem;">
        <label for="domain">Allowed Email Domains</label>
        <div style="display: flex; gap: 0.5rem; margin-bottom: 0.5rem;">
          <input 
            id="domain"
            type="text" 
            v-model="domainInput" 
            class="form-control" 
            placeholder="e.g. webtech.id"
            @keydown.enter.prevent="addDomain"
          />
          <button type="button" @click="addDomain" class="btn btn-secondary">
            Add
          </button>
        </div>
        <p style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem;">
          Press enter or click Add. If left empty, anyone can access the form.
        </p>
        
        <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem;">
          <span v-for="(domain, idx) in allowedDomains" :key="idx" class="badge badge-tag">
            {{ domain }}
            <button type="button" @click="removeDomain(idx)">×</button>
          </span>
        </div>
      </div>

      <button type="submit" class="btn btn-primary" style="width: 100%;" :disabled="isLoading">
        {{ isLoading ? 'Creating...' : 'Create Form' }}
      </button>
    </form>
  </div>
</template>
