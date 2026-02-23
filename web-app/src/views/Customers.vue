<template>
  <div class="customers-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">CRM TERMINAL</h4>
        <h1 class="hero-font">Loyalty Database</h1>
        <p class="text-dim">Manage your clients and their purchase history.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary" @click="showAddModal = true">
          <UserPlusIcon class="icon" />
          <span>REGISTER NEW CLIENT</span>
        </button>
      </div>
    </header>

    <div class="search-bar glass-panel">
      <SearchIcon class="search-icon" />
      <input 
        type="text" 
        v-model="searchQuery" 
        placeholder="Search by name or phone number..." 
        class="search-input"
      />
    </div>

    <div class="customers-grid">
      <div v-for="customer in filteredCustomers" :key="customer.id" class="customer-card glass-panel">
        <div class="card-header">
          <div class="avatar">
            {{ customer.name.charAt(0).toUpperCase() }}
          </div>
          <div class="info">
            <h3 class="name">{{ customer.name }}</h3>
            <p class="phone text-dim">{{ customer.whatsapp_number || 'No WA' }}</p>
          </div>
        </div>
        
        <div class="card-body">
          <div class="stat-item">
            <span class="label">Total Orders</span>
            <span class="value">{{ customer.total_orders || 0 }}</span>
          </div>
          <div class="stat-item">
            <span class="label">Total Value</span>
            <span class="value">Rp {{ (customer.total_spent || 0).toLocaleString() }}</span>
          </div>
        </div>

        <div class="card-footer">
          <button class="btn-lite" @click="viewHistory(customer)">View History</button>
          <button class="btn-icon" @click="editCustomer(customer)">
            <Edit3Icon class="icon-sm" />
          </button>
        </div>
      </div>

      <div v-if="filteredCustomers.length === 0" class="empty-state glass-panel">
        <UsersIcon class="empty-icon" />
        <h3>No clients found</h3>
        <p>Start by registering your first premium customer.</p>
      </div>
    </div>

    <!-- ADD/EDIT MODAL -->
    <Teleport to="body">
      <div v-if="showAddModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">{{ editingId ? 'Update Client' : 'Register Client' }}</h2>
          <p class="text-dim">Keep your customer data precise for better CRM analytics.</p>

          <form @submit.prevent="submitCustomer" class="modal-form">
            <div class="form-group">
              <label>Full Name</label>
              <input type="text" v-model="form.name" placeholder="e.g. Budi Santoso" required />
            </div>

            <div class="form-group">
              <label>WhatsApp Number</label>
              <input type="text" v-model="form.whatsapp_number" placeholder="e.g. 0812..." />
            </div>

            <div class="form-group">
              <label>Address / Note</label>
              <textarea v-model="form.address" placeholder="Shipping address or special notes..."></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="closeModal">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'SAVING...' : (editingId ? 'UPDATE CLIENT' : 'REGISTER CLIENT') }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  UserPlusIcon, 
  UsersIcon, 
  SearchIcon, 
  Edit3Icon
} from 'lucide-vue-next';

const customers = ref<any[]>([]);
const searchQuery = ref('');
const showAddModal = ref(false);
const submitting = ref(false);
const editingId = ref<string | null>(null);

const form = reactive({
  name: '',
  whatsapp_number: '',
  address: ''
});

async function fetchData() {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) console.error('CRM Error:', error);
  
  if (data) customers.value = data;
}

const filteredCustomers = computed(() => {
  if (!searchQuery.value) return customers.value;
  const q = searchQuery.value.toLowerCase();
  return customers.value.filter(c => 
    c.name.toLowerCase().includes(q) || 
    (c.whatsapp_number && c.whatsapp_number.includes(q))
  );
});

function closeModal() {
  showAddModal.value = false;
  editingId.value = null;
  form.name = '';
  form.whatsapp_number = '';
  form.address = '';
}

function editCustomer(customer: any) {
  editingId.value = customer.id;
  form.name = customer.name;
  form.whatsapp_number = customer.whatsapp_number || '';
  form.address = customer.address || '';
  showAddModal.value = true;
}

async function submitCustomer() {
  submitting.value = true;
  
  const payload = {
    name: form.name,
    whatsapp_number: form.whatsapp_number,
    address: form.address,
    updated_at: new Date()
  };

  let error;
  if (editingId.value) {
    const { error: e } = await supabase
      .from('customers')
      .update(payload)
      .eq('id', editingId.value);
    error = e;
  } else {
    const { error: e } = await supabase
      .from('customers')
      .insert(payload);
    error = e;
  }

  if (!error) {
    closeModal();
    fetchData();
  } else {
    alert('Error: ' + error.message);
  }

  submitting.value = false;
}

function viewHistory(customer: any) {
  // Navigation to sales or show history modal
  alert('History for ' + customer.name + ' coming soon in next update!');
}

onMounted(fetchData);
</script>

<style scoped>
.customers-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  margin-bottom: 8px;
}

.text-dim { color: var(--color-text-dim); }

.search-bar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 4px 24px;
  border-radius: var(--radius-xl);
}

.search-icon {
  width: 20px;
  height: 20px;
  color: var(--color-text-dim);
}

.search-input {
  flex: 1;
  background: transparent;
  border: none;
  padding: 16px 0;
  color: white;
  font-family: var(--font-body);
  outline: none;
}

.customers-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.customer-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.avatar {
  width: 48px;
  height: 48px;
  background: var(--color-primary-glow);
  color: var(--color-primary);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 1.2rem;
  border: 1px solid var(--color-primary);
}

.name { font-size: 1.1rem; color: white; margin-bottom: 2px; }
.phone { font-size: 0.85rem; }

.card-body {
  display: grid;
  grid-template-columns: 1fr 1fr;
  padding: 16px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: var(--radius-md);
  border: 1px solid var(--glass-border);
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-item .label { font-size: 0.65rem; text-transform: uppercase; color: var(--color-text-dim); }
.stat-item .value { font-weight: 700; font-size: 0.95rem; color: var(--color-primary); }

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-lite {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-lite:hover { background: rgba(255, 255, 255, 0.1); }

.btn-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-sm);
  color: var(--color-text-dim);
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-icon:hover { 
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.icon-sm { width: 14px; height: 14px; }

.empty-state {
  grid-column: 1 / -1;
  padding: 60px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}

.empty-icon { width: 48px; height: 48px; opacity: 0.1; }

/* MODAL */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-card {
  width: 100%;
  max-width: 500px;
  padding: 40px;
}

.modal-form {
  margin-top: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.form-group select, .form-group input, .form-group textarea {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 12px;
  border-radius: var(--radius-sm);
  color: white;
  font-family: var(--font-body);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 16px;
  margin-top: 12px;
}

.btn-secondary {
  background: transparent;
  border: 1px solid var(--glass-border);
  color: white;
  padding: 12px 24px;
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.animate-pop {
  animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
