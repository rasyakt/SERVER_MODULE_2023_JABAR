<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../api';

const route = useRoute();
const router = useRouter();
const slug = route.params.slug;

const form = ref(null);
const isLoading = ref(false);
const errorMsg = ref('');
const submitErrors = ref({});
const isSubmitting = ref(false);
const isSubmitted = ref(false);

// Reactive answers state: keyed by question ID, storing the value
const answers = ref({});

const fetchForm = async () => {
  isLoading.value = true;
  errorMsg.value = '';
  
  try {
    const response = await api.get(`/forms/${slug}`);
    form.value = response.data.form;
    
    // Initialize empty values for each question
    form.value.questions.forEach(q => {
      if (q.choice_type === 'checkboxes') {
        answers.value[q.id] = []; // Checkboxes starts with array
      } else {
        answers.value[q.id] = '';
      }
    });
  } catch (error) {
    if (error.response) {
      if (error.response.status === 403) {
        // Forbidden email domain
        router.push('/forbidden');
      } else if (error.response.status === 404) {
        errorMsg.value = 'Form not found';
      } else {
        errorMsg.value = 'Failed to load the form.';
      }
    } else {
      errorMsg.value = 'Unable to connect to server.';
    }
    console.error(error);
  } finally {
    isLoading.value = false;
  }
};

// Parse choices string into list array
const getChoicesList = (choicesStr) => {
  if (!choicesStr) return [];
  return choicesStr.split(',').map(opt => opt.trim());
};

// Check if all required questions are filled out
const isSubmitDisabled = computed(() => {
  if (!form.value) return true;
  
  for (const q of form.value.questions) {
    if (q.is_required) {
      const val = answers.value[q.id];
      if (q.choice_type === 'checkboxes') {
        if (!val || val.length === 0) {
          return true; // No checkboxes checked
        }
      } else {
        if (val === undefined || val === null || String(val).trim() === '') {
          return true; // Input or text area is empty
        }
      }
    }
  }
  
  return false;
});

const handleSubmit = async () => {
  errorMsg.value = '';
  submitErrors.value = {};
  isSubmitting.value = true;
  
  // Format dynamic answers payload
  const formattedAnswers = Object.keys(answers.value).map(qId => {
    let val = answers.value[qId];
    
    // If checkboxes, join with comma
    if (Array.isArray(val)) {
      val = val.join(',');
    }
    
    return {
      question_id: parseInt(qId),
      value: val
    };
  });
  
  try {
    await api.post(`/forms/${slug}/responses`, {
      answers: formattedAnswers
    });
    
    isSubmitted.value = true;
  } catch (error) {
    if (error.response) {
      if (error.response.status === 422) {
        submitErrors.value = error.response.data.errors || {};
        errorMsg.value = error.response.data.message || 'Submission failed';
      } else if (error.response.status === 403) {
        router.push('/forbidden');
      } else {
        errorMsg.value = error.response.data.message || 'An error occurred during submission.';
      }
    } else {
      errorMsg.value = 'Network error. Please try again.';
    }
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(fetchForm);
</script>

<template>
  <div class="submit-container" style="margin: 2rem auto;">
    
    <!-- Error Alert Box -->
    <div v-if="errorMsg" class="alert alert-danger">
      {{ errorMsg }}
    </div>

    <!-- Loading Screen -->
    <div v-if="isLoading" style="text-align: center; padding: 4rem;">
      <p style="color: var(--text-secondary);">Loading form content...</p>
    </div>

    <!-- Successful Submission Thank You Page -->
    <div v-else-if="isSubmitted" class="card success-card">
      <div class="success-icon">✓</div>
      <h1>Response Submitted</h1>
      <p class="subtitle" style="margin-bottom: 2rem;">Thank you! Your response for this form has been successfully saved.</p>
      <router-link to="/" class="btn btn-primary btn-sm">
        Return to Dashboard
      </router-link>
    </div>

    <!-- Form Filling View -->
    <div v-else-if="form">
      <div class="submit-header">
        <h1>{{ form.name }}</h1>
        <p class="subtitle" style="margin-bottom: 0.5rem;" v-if="form.description">
          {{ form.description }}
        </p>
        <div style="font-size: 0.75rem; color: var(--text-muted);">
          Form created by: <strong>User {{ form.creator_id }}</strong>
        </div>
      </div>

      <form @submit.prevent="handleSubmit">
        <div v-for="q in form.questions" :key="q.id" class="submit-question-card">
          <div class="submit-question-name">
            {{ q.name }}
            <span v-if="q.is_required" class="submit-question-required">*</span>
          </div>

          <!-- 1. Short Answer -->
          <div v-if="q.choice_type === 'short answer'">
            <input 
              type="text" 
              v-model="answers[q.id]" 
              class="form-control" 
              placeholder="Your answer..."
              :required="q.is_required === 1"
            />
          </div>

          <!-- 2. Paragraph -->
          <div v-else-if="q.choice_type === 'paragraph'">
            <textarea 
              v-model="answers[q.id]" 
              class="form-control" 
              placeholder="Your long answer..."
              :required="q.is_required === 1"
            ></textarea>
          </div>

          <!-- 3. Date -->
          <div v-else-if="q.choice_type === 'date'">
            <input 
              type="date" 
              v-model="answers[q.id]" 
              class="form-control" 
              :required="q.is_required === 1"
            />
          </div>

          <!-- 4. Time -->
          <div v-else-if="q.choice_type === 'time'">
            <input 
              type="time" 
              v-model="answers[q.id]" 
              class="form-control" 
              :required="q.is_required === 1"
            />
          </div>

          <!-- 5. Multiple Choice -->
          <div v-else-if="q.choice_type === 'multiple choice'" class="submit-options-list">
            <label v-for="opt in getChoicesList(q.choices)" :key="opt" class="submit-option-label">
              <input 
                type="radio" 
                :name="'radio-' + q.id" 
                :value="opt" 
                v-model="answers[q.id]" 
              />
              {{ opt }}
            </label>
          </div>

          <!-- 6. Dropdown -->
          <div v-else-if="q.choice_type === 'dropdown'">
            <select v-model="answers[q.id]" class="form-control" style="background-color: #ffffff;">
              <option value="" disabled selected>Select option...</option>
              <option v-for="opt in getChoicesList(q.choices)" :key="opt" :value="opt">
                {{ opt }}
              </option>
            </select>
          </div>

          <!-- 7. Checkboxes -->
          <div v-else-if="q.choice_type === 'checkboxes'" class="submit-options-list">
            <label v-for="opt in getChoicesList(q.choices)" :key="opt" class="submit-option-label">
              <input 
                type="checkbox" 
                :value="opt" 
                v-model="answers[q.id]" 
              />
              {{ opt }}
            </label>
          </div>
        </div>

        <!-- Submit Panel -->
        <div style="display: flex; justify-content: flex-end; margin-top: 1.5rem;">
          <button 
            type="submit" 
            class="btn btn-primary" 
            :disabled="isSubmitting || isSubmitDisabled"
            style="padding: 0.75rem 2.5rem;"
          >
            {{ isSubmitting ? 'Submitting...' : 'Submit' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
