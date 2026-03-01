<template>
  <div class="customers-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">CRM TERMINAL</h4>
        <h1 class="hero-font">Loyalty Database</h1>
        <p class="text-dim">Manage your clients and their purchase history.</p>
      </div>
      <div class="header-actions">
        <button class="btn-secondary" @click="recalculateAllStats" :disabled="syncing">
          <RefreshCwIcon class="icon" :class="{ 'spin': syncing }" />
          <span>SYNC ALL STATS</span>
        </button>
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
          <div class="footer-actions">
            <button class="btn-icon" @click="editCustomer(customer)">
              <Edit3Icon class="icon-sm" />
            </button>
            <button class="btn-icon del" @click="deleteCustomer(customer)">
              <Trash2Icon class="icon-sm" />
            </button>
          </div>
        </div>
      </div>

      <div v-if="filteredCustomers.length === 0" class="empty-state glass-panel">
        <UsersIcon class="empty-icon" />
        <h3>No active clients found</h3>
        <p>Start by registering your first premium customer.</p>
      </div>
    </div>

    <!-- DELETED ARCHIVE (ADMIN ONLY) -->
    <section v-if="authStore.isAdmin" class="archive-section mt-12">
      <div class="archive-header" @click="showArchive = !showArchive">
        <div class="ah-left">
          <ArchiveIcon class="icon-sm" />
          <h3 class="subtitle">DELETED RECORDS ARCHIVE</h3>
          <span class="archive-count">{{ deletedCustomers.length }}</span>
        </div>
        <ChevronDownIcon class="archive-chevron" :class="{ open: showArchive }" />
      </div>

      <div v-if="showArchive" class="archive-content animate-slide-down">
        <div v-if="deletedCustomers.length === 0" class="archive-empty">
          No deleted clients found.
        </div>
        <div v-else class="archive-table-wrap glass-panel">
          <table class="archive-table">
            <thead>
              <tr>
                <th>Client Name</th>
                <th>Phone</th>
                <th>Deleted At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="customer in deletedCustomers" :key="customer.id">
                <td class="font-bold">{{ customer.name }}</td>
                <td class="text-dim">{{ customer.whatsapp_number }}</td>
                <td class="text-dim text-xs">{{ new Date(customer.deleted_at).toLocaleString() }}</td>
                <td class="actions">
                  <button class="btn-restore" @click="restoreCustomer(customer)">
                    <RefreshCcwIcon class="icon-xs" />
                    <span>RESTORE</span>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

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

    <!-- VIEW HISTORY MODAL -->
    <Teleport to="body">
      <div v-if="showHistoryModal" class="modal-overlay" @click.self="showHistoryModal = false">
        <div class="modal-card glass-panel animate-pop history-modal">
          <div class="modal-header">
            <div>
              <h2 class="hero-font">Purchase History</h2>
              <p class="text-dim">Tracking records for {{ selectedCustomer?.name }}</p>
            </div>
            <button class="btn-close" @click="showHistoryModal = false">×</button>
          </div>

          <div class="history-list mt-6">
            <div v-if="loadingHistory" class="loading-state">
              <RefreshCwIcon class="icon spin" />
              <span>Fetching records...</span>
            </div>
            <div v-else-if="customerHistory.length === 0" class="empty-history">
              No orders found for this customer.
            </div>
            <div v-else class="history-table-wrapper">
              <table class="history-table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Order ID</th>
                    <th>Status</th>
                    <th class="text-right">Total</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="order in customerHistory" :key="order.id">
                    <td class="date">{{ new Date(order.created_at).toLocaleDateString('id-ID') }}</td>
                    <td class="id">#{{ order.id.slice(-6).toUpperCase() }}</td>
                    <td>
                      <span class="status-pill" :class="order.payment_status">
                        {{ order.payment_status }}
                      </span>
                    </td>
                    <td class="text-right amount">Rp {{ order.total_price.toLocaleString() }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="modal-actions mt-8">
            <button class="btn-secondary" @click="showHistoryModal = false">CLOSE</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  UserPlusIcon, 
  UsersIcon, 
  SearchIcon, 
  Edit3Icon,
  RefreshCwIcon,
  ArchiveIcon,
  ChevronDownIcon,
  RefreshCcwIcon,
  Trash2Icon
} from 'lucide-vue-next';
import { useAuthStore } from '../stores/auth';

const authStore = useAuthStore();
const customers = ref<any[]>([]);
const deletedCustomers = ref<any[]>([]);
const showArchive = ref(false);
const searchQuery = ref('');
const showAddModal = ref(false);
const showHistoryModal = ref(false);
const loadingHistory = ref(false);
const syncing = ref(false);
const submitting = ref(false);
const editingId = ref<string | null>(null);
const selectedCustomer = ref<any>(null);
const customerHistory = ref<any[]>([]);

const form = reactive({
  name: '',
  whatsapp_number: '',
  address: ''
});

async function fetchData() {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .eq('is_deleted', false)
    .order('created_at', { ascending: false });
  
  if (error) console.error('CRM Error:', error);
  
  if (data) customers.value = data;

  if (authStore.isAdmin) {
    const { data: delData } = await supabase
      .from('customers')
      .select('*')
      .eq('is_deleted', true)
      .order('deleted_at', { ascending: false });
    deletedCustomers.value = delData || [];
  }
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
  if (submitting.value) return;
  submitting.value = true;
  
  try {
    const payload = {
      name: form.name,
      whatsapp_number: form.whatsapp_number,
      address: form.address,
      updated_at: new Date().toISOString()
    };

    let result;
    if (editingId.value) {
      result = await supabase
        .from('customers')
        .update(payload)
        .eq('id', editingId.value);
    } else {
      result = await supabase
        .from('customers')
        .insert([payload]);
    }

    if (result.error) throw result.error;

    closeModal();
    await fetchData();
  } catch (err: any) {
    console.error('Save Error:', err);
    alert('Failed to save customer: ' + (err.message || 'Unknown error'));
  } finally {
    submitting.value = false;
  }
}

async function deleteCustomer(customer: any) {
  if (!confirm(`Move "${customer.name}" to archive? You can restore it later.`)) return;
  
  submitting.value = true;
  try {
    const { error } = await supabase
      .from('customers')
      .update({ 
        is_deleted: true,
        deleted_at: new Date().toISOString()
      })
      .eq('id', customer.id);

    if (error) {
      alert('Error: ' + error.message);
    } else {
      fetchData();
    }
  } catch (err: any) {
    alert('System Error: ' + err.message);
  } finally {
    submitting.value = false;
  }
}

async function restoreCustomer(customer: any) {
  submitting.value = true;
  try {
    const { error } = await supabase
      .from('customers')
      .update({ is_deleted: false, deleted_at: null })
      .eq('id', customer.id);

    if (error) {
      alert('Error: ' + error.message);
    } else {
      fetchData();
    }
  } catch (err: any) {
    alert('System Error: ' + err.message);
  } finally {
    submitting.value = false;
  }
}

async function viewHistory(customer: any) {
  selectedCustomer.value = customer;
  showHistoryModal.value = true;
  loadingHistory.value = true;
  customerHistory.value = [];
  
  const { data } = await supabase
    .from('sales')
    .select('*')
    .eq('customer_id', customer.id)
    .order('created_at', { ascending: false });
    
  if (data) customerHistory.value = data;
  loadingHistory.value = false;
}

async function recalculateAllStats() {
  if (!confirm('This will scan all sales and update every customer\'s total orders and total spent. Continue?')) return;
  
  syncing.value = true;
  try {
    // 1. Get all sales
    const { data: sales, error: salesError } = await supabase
      .from('sales')
      .select('customer_id, total_price, payment_status');
    
    if (salesError) throw salesError;
    if (!sales) return;

    // 2. Map totals
    const statsMap: Record<string, { count: number, spent: number }> = {};
    sales.forEach(s => {
      const cid = s.customer_id;
      if (!cid) return;
      if (!statsMap[cid]) statsMap[cid] = { count: 0, spent: 0 };
      
      const stats = statsMap[cid];
      if (s.payment_status !== 'cancelled') {
        stats.count++;
        if (s.payment_status === 'paid') {
          stats.spent += (Number(s.total_price) || 0);
        }
      }
    });

    // 3. Update all customers in parallel for speed
    const updatePromises = Object.entries(statsMap).map(([id, stats]) => {
      return supabase.from('customers').update({
        total_orders: stats.count,
        total_spent: stats.spent,
        updated_at: new Date().toISOString()
      }).eq('id', id);
    });

    await Promise.all(updatePromises);

    alert('Sync complete! All customer statistics have been updated from transaction data.');
    await fetchData();
  } catch (err: any) {
    console.error('Sync Error:', err);
    alert('Sync Error: ' + err.message);
  } finally {
    syncing.value = false;
  }
}

let refreshInterval: any;

onMounted(() => {
  fetchData();
  refreshInterval = setInterval(fetchData, 10000);
});

onUnmounted(() => {
  clearInterval(refreshInterval);
});
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

/* HISTORY MODAL & UTILS */
.history-modal {
  max-width: 700px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.btn-close {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 1.5rem;
  cursor: pointer;
}

.loading-state, .empty-history {
  padding: 60px 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: var(--color-text-dim);
}

.history-table-wrapper {
  max-height: 400px;
  overflow-y: auto;
  border-radius: var(--radius-md);
  border: 1px solid var(--glass-border);
}

.history-table {
  width: 100%;
  border-collapse: collapse;
}

.history-table th {
  text-align: left;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.03);
  font-size: 0.7rem;
  text-transform: uppercase;
  color: var(--color-text-dim);
  position: sticky;
  top: 0;
}

.history-table td {
  padding: 14px 16px;
  border-bottom: 1px solid var(--glass-border);
  font-size: 0.85rem;
}

.history-table .date { color: var(--color-text-dim); }
.history-table .id { font-family: 'JetBrains Mono', monospace; color: var(--color-primary); }
.history-table .amount { font-weight: 700; color: white; }

.status-pill {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: 4px;
}

.status-pill.paid { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.status-pill.pending { background: rgba(255, 170, 0, 0.1); color: #FFAA00; }
.status-pill.cancelled { background: rgba(255, 66, 66, 0.1); color: var(--color-error); }

.spin { animation: spin 1.2s linear infinite; }
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.mt-6 { margin-top: 24px; }
.mt-8 { margin-top: 32px; }
.text-right { text-align: right; }
.w-full { width: 100%; }

.footer-actions {
  display: flex;
  gap: 8px;
}

.btn-icon.del:hover {
  border-color: var(--color-error);
  color: var(--color-error);
}

/* ARCHIVE STYLES */
.mt-12 { margin-top: 48px; }

.archive-section {
  border-top: 1px solid var(--glass-border);
  padding-top: 32px;
}

.archive-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.archive-header:hover {
  background: rgba(255, 255, 255, 0.04);
}

.ah-left { display: flex; align-items: center; gap: 12px; }
.ah-left .subtitle { margin: 0; font-size: 0.8rem; letter-spacing: 0.1em; color: var(--color-text-dim); }

.archive-count {
  background: rgba(255, 255, 255, 0.1);
  padding: 2px 8px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
}

.archive-chevron {
  width: 18px;
  height: 18px;
  color: var(--color-text-dim);
  transition: transform 0.3s ease;
}

.archive-chevron.open { transform: rotate(180deg); }

.archive-content { margin-top: 16px; }

.archive-empty {
  text-align: center;
  padding: 40px;
  color: var(--color-text-dim);
  font-style: italic;
  font-size: 0.85rem;
}

.archive-table-wrap { overflow: hidden; }

.archive-table {
  width: 100%;
  border-collapse: collapse;
}

.archive-table th {
  text-align: left;
  padding: 12px 16px;
  font-size: 0.65rem;
  text-transform: uppercase;
  color: var(--color-text-dim);
  border-bottom: 1px solid var(--glass-border);
}

.archive-table td {
  padding: 12px 16px;
  font-size: 0.8rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.btn-restore {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(0, 255, 157, 0.1);
  border: 1px solid rgba(0, 255, 157, 0.2);
  color: var(--color-success);
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 0.65rem;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-restore:hover {
  background: var(--color-success);
  color: black;
}

.animate-slide-down {
  animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
