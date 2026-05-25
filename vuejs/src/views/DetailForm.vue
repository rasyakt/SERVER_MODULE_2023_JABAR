<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../api';

const route = useRoute();
const router = useRouter();
const slug = route.params.slug;

const activeTab = ref('general'); // 'general' | 'questions' | 'responses'
const form = ref(null);
const responses = ref([]);
const isLoading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

// Question Builder states
const qName = ref('');
const qType = ref('short answer');
const qRequired = ref(false);
const choiceInput = ref('');
const qChoices = ref([]);
const isAddingQuestion = ref(false);

const isChoicesRequired = computed(() => {
  return ['multiple choice', 'dropdown', 'checkboxes'].includes(qType.value);
});

const getSubmitUrl = () => {
  return `${window.location.origin}/forms/${slug}/submit`;
};

const copyStatus = ref(false);
const copyLink = () => {
  navigator.clipboard.writeText(getSubmitUrl()).then(() => {
    copyStatus.value = true;
    setTimeout(() => {
      copyStatus.value = false;
    }, 2000);
  });
};

const addChoice = () => {
  const choice = choiceInput.value.trim();
  if (choice && !qChoices.value.includes(choice)) {
    qChoices.value.push(choice);
    choiceInput.value = '';
  }
};

const removeChoice = (index) => {
  qChoices.value.splice(index, 1);
};

const fetchDetail = async () => {
  isLoading.value = true;
  errorMsg.value = '';
  
  try {
    const formResponse = await api.get(`/forms/${slug}`);
    form.value = formResponse.data.form;
    
    // If authenticated user is creator, fetch responses as well
    const currentUser = JSON.parse(localStorage.getItem('user'));
    if (form.value.creator_id === currentUser?.id) {
      await fetchResponses();
    }
  } catch (error) {
    if (error.response && error.response.status === 404) {
      errorMsg.value = 'Form not found';
    } else {
      errorMsg.value = 'Failed to load form details.';
    }
    console.error(error);
  } finally {
    isLoading.value = false;
  }
};

const fetchResponses = async () => {
  try {
    const resp = await api.get(`/forms/${slug}/responses`);
    responses.value = resp.data.responses || [];
  } catch (error) {
    console.error('Failed to load responses:', error);
  }
};

const handleAddQuestion = async () => {
  errorMsg.value = '';
  successMsg.value = '';
  
  if (isChoicesRequired.value && qChoices.value.length === 0) {
    errorMsg.value = 'Please add at least one choice for multiple choice, dropdown, or checkbox questions.';
    return;
  }
  
  isAddingQuestion.value = true;
  
  try {
    const res = await api.post(`/forms/${slug}/questions`, {
      name: qName.value,
      choice_type: qType.value,
      is_required: qRequired.value,
      choices: qChoices.value
    });
    
    // Add to list dynamically
    if (form.value) {
      form.value.questions.push({
        id: res.data.question.id,
        form_id: res.data.question.form_id,
        name: res.data.question.name,
        choice_type: res.data.question.choice_type,
        choices: res.data.question.choices,
        is_required: res.data.question.is_required ? 1 : 0
      });
    }
    
    // Reset inputs
    qName.value = '';
    qType.value = 'short answer';
    qRequired.value = false;
    qChoices.value = [];
    choiceInput.value = '';
    
    successMsg.value = 'Question added successfully!';
    setTimeout(() => { successMsg.value = ''; }, 3000);
  } catch (error) {
    if (error.response && error.response.status === 422) {
      errorMsg.value = error.response.data.message || 'Validation failed';
    } else {
      errorMsg.value = 'Failed to add question. Please try again.';
    }
  } finally {
    isAddingQuestion.value = false;
  }
};

const handleRemoveQuestion = async (qId) => {
  errorMsg.value = '';
  successMsg.value = '';
  
  if (!confirm('Are you sure you want to remove this question? All submitted answers for this question will be deleted.')) {
    return;
  }
  
  try {
    await api.delete(`/forms/${slug}/questions/${qId}`);
    
    // Remove dynamically
    if (form.value) {
      form.value.questions = form.value.questions.filter(q => q.id !== qId);
    }
    
    successMsg.value = 'Question removed successfully.';
    setTimeout(() => { successMsg.value = ''; }, 3000);
  } catch (error) {
    errorMsg.value = 'Failed to remove question.';
  }
};

onMounted(fetchDetail);
</script>

<template>
  <div>
    <!-- Back btn -->
    <div style="margin-bottom: 1.5rem;">
      <router-link to="/" class="btn btn-secondary btn-sm">
        ← Back to Dashboard
      </router-link>
    </div>

    <!-- Alert Messaging -->
    <div v-if="errorMsg" class="alert alert-danger">
      {{ errorMsg }}
    </div>
    <div v-if="successMsg" class="alert alert-success">
      {{ successMsg }}
    </div>

    <div v-if="isLoading" style="text-align: center; padding: 4rem;">
      <p style="color: var(--text-secondary);">Loading form details...</p>
    </div>

    <div v-else-if="form">
      <div style="margin-bottom: 2rem;">
        <h1>{{ form.name }}</h1>
        <p class="subtitle" style="margin-bottom: 0;">Manage form properties, questions, and view respondents</p>
      </div>

      <!-- Navigation Tabs -->
      <div class="tabs-container">
        <button 
          @click="activeTab = 'general'" 
          :class="['tab-btn', { active: activeTab === 'general' }]"
        >
          General (Form Details)
        </button>
        <button 
          @click="activeTab = 'questions'" 
          :class="['tab-btn', { active: activeTab === 'questions' }]"
        >
          Questions ({{ form.questions.length }})
        </button>
        <button 
          @click="activeTab = 'responses'" 
          :class="['tab-btn', { active: activeTab === 'responses' }]"
        >
          Responses ({{ responses.length }})
        </button>
      </div>

      <!-- Tab Content: General -->
      <div v-if="activeTab === 'general'">
        <div class="card detail-disabled-box">
          <h2 style="font-size: 1.05rem; margin-bottom: 1.25rem; color: var(--text-secondary);">
            Form Properties (Read-Only)
          </h2>
          
          <div class="form-group">
            <label>Form Name</label>
            <input type="text" :value="form.name" class="form-control" disabled />
          </div>

          <div class="form-group">
            <label>Slug URL</label>
            <input type="text" :value="form.slug" class="form-control" disabled />
          </div>

          <div class="form-group">
            <label>Description</label>
            <textarea class="form-control" disabled>{{ form.description || 'No description provided.' }}</textarea>
          </div>

          <div class="form-group" style="margin: 1rem 0;">
            <label class="switch-container" style="opacity: 0.65; cursor: not-allowed;">
              <span class="switch">
                <input type="checkbox" :checked="form.limit_one_response === 1" disabled />
                <span class="slider"></span>
              </span>
              <div>
                <div style="font-weight: 500; font-size: 0.85rem;">Limit to 1 response</div>
              </div>
            </label>
          </div>

          <div class="form-group">
            <label>Allowed Email Domains</label>
            <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.25rem;">
              <span v-if="form.allowed_domains.length === 0" style="color: var(--text-muted); font-size: 0.85rem; font-style: italic;">
                Anyone (Public Access)
              </span>
              <span v-else v-for="domain in form.allowed_domains" :key="domain" class="badge">
                {{ domain }}
              </span>
            </div>
          </div>
        </div>

        <!-- Share Form Link -->
        <div class="card" style="border-color: var(--border-color-focus);">
          <h2>Share Form</h2>
          <p class="subtitle" style="margin-bottom: 1rem; font-size: 0.85rem;">Copy the public link below to send to invited respondents:</p>
          <div style="display: flex; gap: 0.5rem;">
            <input type="text" readonly :value="getSubmitUrl()" class="form-control" @click="$event.target.select()" />
            <button @click="copyLink" class="btn btn-primary" style="white-space: nowrap;">
              {{ copyStatus ? 'Copied!' : 'Copy Link' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Tab Content: Questions -->
      <div v-else-if="activeTab === 'questions'">
        <!-- Existing Questions -->
        <div style="margin-bottom: 2rem;">
          <h2>Questions List</h2>
          <div v-if="form.questions.length === 0" class="card" style="text-align: center; padding: 2.5rem; color: var(--text-secondary);">
            <p>No questions added to this form yet. Use the form below to create one!</p>
          </div>
          <div v-else class="list-grid">
            <div v-for="(q, index) in form.questions" :key="q.id" class="list-item" style="padding: 1rem 1.25rem;">
              <div class="list-item-header">
                <div>
                  <span style="font-weight: 600; color: var(--text-secondary); margin-right: 0.5rem;">#{{ index + 1 }}</span>
                  <span style="font-weight: 600;">{{ q.name }}</span>
                  <span v-if="q.is_required === 1" class="submit-question-required">*</span>
                </div>
                <button @click="handleRemoveQuestion(q.id)" class="btn btn-danger btn-sm">
                  Remove
                </button>
              </div>
              <div class="list-item-meta" style="margin-top: 0.25rem; font-size: 0.8rem;">
                <span class="badge" style="font-size: 0.7rem; background-color: #f1f5f9;">
                  Type: {{ q.choice_type }}
                </span>
                <span v-if="q.choices" style="color: var(--text-secondary);">
                  Choices: [ {{ q.choices }} ]
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Add Question Card -->
        <div class="card">
          <h2>Add a New Question</h2>
          <p class="subtitle" style="margin-bottom: 1.25rem; font-size: 0.85rem;">Define the question name, input type, and constraints</p>
          
          <form @submit.prevent="handleAddQuestion">
            <div class="form-group">
              <label for="q-name">Question Name <span style="color: var(--danger-color);">*</span></label>
              <input 
                id="q-name"
                type="text" 
                v-model="qName" 
                class="form-control" 
                placeholder="e.g. Born Date or Most Favorite JS Framework"
                required
              />
            </div>

            <div class="form-group">
              <label for="q-type">Choice Type <span style="color: var(--danger-color);">*</span></label>
              <select id="q-type" v-model="qType" class="form-control" style="background-color: #ffffff;">
                <option value="short answer">Short Answer (TextField)</option>
                <option value="paragraph">Paragraph (TextArea)</option>
                <option value="date">Date Input</option>
                <option value="time">Time Input</option>
                <option value="multiple choice">Multiple Choice (Radio Buttons)</option>
                <option value="dropdown">Dropdown (Select Box)</option>
                <option value="checkboxes">Checkboxes</option>
              </select>
            </div>

            <!-- Dynamic choices management for option list types -->
            <div v-if="isChoicesRequired" class="form-group" style="margin: 1.25rem 0;">
              <label>Choices Options <span style="color: var(--danger-color);">*</span></label>
              <div style="display: flex; gap: 0.5rem; margin-bottom: 0.5rem;">
                <input 
                  type="text" 
                  v-model="choiceInput" 
                  class="form-control" 
                  placeholder="e.g. Male or React JS"
                  @keydown.enter.prevent="addChoice"
                />
                <button type="button" @click="addChoice" class="btn btn-secondary btn-sm">
                  Add Option
                </button>
              </div>
              <p style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem;">
                Press enter or click Add Option to append list options.
              </p>
              
              <div style="display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 0.5rem;">
                <span v-if="qChoices.length === 0" style="color: var(--text-muted); font-size: 0.8rem; font-style: italic;">
                  No options added yet.
                </span>
                <span v-else v-for="(choice, idx) in qChoices" :key="idx" class="badge badge-tag" style="background-color: #f1f5f9;">
                  {{ choice }}
                  <button type="button" @click="removeChoice(idx)">×</button>
                </span>
              </div>
            </div>

            <!-- Is required switch -->
            <div class="form-group" style="margin: 1rem 0;">
              <label class="switch-container">
                <span class="switch">
                  <input type="checkbox" v-model="qRequired" />
                  <span class="slider"></span>
                </span>
                <div>
                  <span style="font-weight: 500; font-size: 0.85rem;">Required question</span>
                </div>
              </label>
            </div>

            <button type="submit" class="btn btn-primary btn-sm" :disabled="isAddingQuestion" style="margin-top: 0.5rem;">
              {{ isAddingQuestion ? 'Adding...' : 'Save Question' }}
            </button>
          </form>
        </div>
      </div>

      <!-- Tab Content: Responses -->
      <div v-else-if="activeTab === 'responses'">
        <h2>Response Summary</h2>
        <div style="display: grid; grid-template-columns: 1fr; gap: 1rem; margin-bottom: 2rem;">
          <div class="card" style="text-align: center; padding: 1.5rem;">
            <div style="font-size: 2rem; font-weight: 700; color: var(--text-primary);">
              {{ responses.length }}
            </div>
            <div style="font-size: 0.8rem; color: var(--text-muted); font-weight: 500; text-transform: uppercase;">
              Total Submissions
            </div>
          </div>
        </div>

        <h2>Respondent Sheets</h2>
        <div v-if="responses.length === 0" class="card" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
          <p>No one has submitted responses for this form yet.</p>
        </div>
        
        <div v-else class="table-container">
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Submitter</th>
                <!-- Render a header for each question in the form -->
                <th v-for="q in form.questions" :key="q.id">
                  {{ q.name }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(res, idx) in responses" :key="idx">
                <td style="white-space: nowrap;">{{ res.date }}</td>
                <td>
                  <div style="font-weight: 500;">{{ res.user.name }}</div>
                  <div style="font-size: 0.75rem; color: var(--text-muted);">{{ res.user.email }}</div>
                </td>
                <!-- Render answers mapped to the questions dynamically -->
                <td v-for="q in form.questions" :key="q.id">
                  <span v-if="res.answers[q.name] !== undefined">
                    {{ res.answers[q.name] }}
                  </span>
                  <span v-else style="color: var(--text-muted); font-style: italic; font-size: 0.75rem;">
                    N/A
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
