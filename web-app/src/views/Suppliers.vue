<template>
  <div class="suppliers-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">SUPPLY CHAIN TERMINAL</h4>
        <h1 class="hero-font">Stock Sources</h1>
        <p class="text-dim">Manage your suppliers and egg procurement sources.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary" @click="showAddModal = true">
          <TruckIcon class="icon" />
          <span>ADD NEW SUPPLIER</span>
        </button>
      </div>
    </header>

    <div class="suppliers-grid">
      <div v-for="supplier in suppliers" :key="supplier.id" class="supplier-card glass-panel" :class="getCategoryClass(supplier.category)">
        <!-- Vertical Accent Bar -->
        <div class="card-accent"></div>
        
        <div class="card-header-premium">
          <div class="vendor-avatar">
            {{ supplier.name.charAt(0).toUpperCase() }}
          </div>
          <div class="header-info">
            <h3 class="name">{{ supplier.name }}</h3>
            <div class="service-chip">{{ supplier.category || 'General' }}</div>
          </div>
        </div>
        
        <div class="card-body-elite">
          <div class="info-row">
            <UserIcon class="icon-xs" />
            <span class="val">{{ supplier.contact_person || 'No Contact' }}</span>
          </div>
          <div class="info-row">
            <PhoneIcon class="icon-xs" />
            <span class="val">{{ supplier.phone || '-' }}</span>
          </div>
          <div class="info-row">
            <MapPinIcon class="icon-xs" />
            <span class="val truncate">{{ supplier.address || 'No Address' }}</span>
          </div>
        </div>

        <div class="card-actions-premium">
          <button class="btn-action-main" @click="viewDeliveries(supplier)">
            <HistoryIcon class="icon-xs" />
            <span>VIEW DELIVERIES</span>
          </button>
          <button class="btn-action-icon" @click="editSupplier(supplier)" title="Edit Vendor">
            <Edit3Icon class="icon-sm" />
          </button>
        </div>
      </div>

      <div v-if="suppliers.length === 0" class="empty-state glass-panel">
        <PackageIcon class="empty-icon" />
        <h3>No suppliers registered</h3>
        <p>Your supply chain is empty. Add your first vendor to track HPP and stock logs.</p>
      </div>
    </div>

    <!-- ADD/EDIT MODAL -->
    <Teleport to="body">
      <div v-if="showAddModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">{{ editingId ? 'Update Vendor' : 'New Vendor Registration' }}</h2>
          <p class="text-dim">Ensure vendor data is accurate for inventory HPP calculation.</p>

          <form @submit.prevent="submitSupplier" class="modal-form">
            <div class="form-group">
              <label>Vendor Name / Farm Name</label>
              <input type="text" v-model="form.name" placeholder="e.g. Farm Berkah Telur" required />
            </div>

            <div class="form-group">
              <label>Contact Person</label>
              <input type="text" v-model="form.contact_person" placeholder="e.g. Pak Haji Somad" />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Phone / WhatsApp</label>
                <input type="text" v-model="form.phone" placeholder="08..." />
              </div>
            </div>

            <div class="form-group">
              <label>Full Address</label>
              <textarea v-model="form.address" placeholder="Vendor location..."></textarea>
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="form.category" 
                :options="categoryOptions" 
                label="Service / Category" 
                placeholder="Select supply type..."
              />
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="closeModal">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'SAVING...' : (editingId ? 'UPDATE VENDOR' : 'SAVE VENDOR') }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  TruckIcon, 
  Edit3Icon, 
  PackageIcon,
  UserIcon,
  PhoneIcon,
  MapPinIcon,
  HistoryIcon
} from 'lucide-vue-next';
import CustomDropdown from '../components/ui/CustomDropdown.vue';

const suppliers = ref<any[]>([]);
const showAddModal = ref(false);
const submitting = ref(false);
const inventory = ref<any[]>([]);
const editingId = ref<string | null>(null);

const categoryOptions = [
  { label: '🥚 Telur Hero', value: 'Telur Hero' },
  { label: '🥚 Telur Standard', value: 'Telur Standard' },
  { label: '🧂 Telur Asin', value: 'Telur Asin' },
  { label: '📦 Kemasan Paper Box', value: 'Kemasan' },
  { label: '🏷️ Stiker Label', value: 'Stiker' },
  { label: '💌 Thank You Card', value: 'Card' }
];

const form = reactive({
  name: '',
  contact_person: '',
  phone: '',
  address: '',
  category: ''
});

function getCategoryClass(cat: string) {
  if (!cat) return '';
  if (cat.includes('Telur')) return 'accent-egg';
  if (cat.includes('Kemasan') || cat.includes('Box')) return 'accent-pack';
  return 'accent-general';
}

async function fetchData() {
  const { data: vendorData } = await supabase
    .from('suppliers')
    .select('*')
    .order('name');
  
  if (vendorData) suppliers.value = vendorData;

  const { data: invData } = await supabase.from('inventory').select('*');
  if (invData) inventory.value = invData;
}

function closeModal() {
  showAddModal.value = false;
  editingId.value = null;
  form.name = '';
  form.contact_person = '';
  form.phone = '';
  form.address = '';
  form.category = '';
}

function editSupplier(vendor: any) {
  editingId.value = vendor.id;
  form.name = vendor.name;
  form.contact_person = vendor.contact_person || '';
  form.phone = vendor.phone || '';
  form.address = vendor.address || '';
  form.category = vendor.category || '';
  showAddModal.value = true;
}

async function submitSupplier() {
  submitting.value = true;
  const payload = { ...form };

  let error;
  if (editingId.value) {
    const { error: e } = await supabase
      .from('suppliers')
      .update(payload)
      .eq('id', editingId.value);
    error = e;
  } else {
    const { error: e } = await supabase
      .from('suppliers')
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

function viewDeliveries(vendor: any) {
  alert('History deliveries from ' + vendor.name + ' feature is coming soon!');
}

onMounted(fetchData);
</script>

<style scoped>
.suppliers-page {
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

.suppliers-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.supplier-card {
  padding: 0;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
  min-height: 280px;
}

.supplier-card:hover {
  transform: translateY(-8px);
  border-color: rgba(255, 140, 0, 0.2);
  box-shadow: 0 20px 40px rgba(0,0,0,0.4);
}

.card-accent {
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: var(--color-primary);
  opacity: 0.5;
}

.accent-egg .card-accent { background: #FFD700; }
.accent-pack .card-accent { background: #00D1FF; }

.card-header-premium {
  padding: 24px 32px;
  display: flex;
  align-items: center;
  gap: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.vendor-avatar {
  width: 56px;
  height: 56px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.4rem;
  font-weight: 900;
  color: var(--color-primary);
  font-family: 'JetBrains Mono', monospace;
}

.header-info { display: flex; flex-direction: column; gap: 4px; }
.name { font-size: 1.2rem; font-weight: 800; color: white; }

.service-chip {
  font-size: 0.6rem;
  font-weight: 900;
  text-transform: uppercase;
  color: var(--color-primary);
  background: rgba(255, 140, 0, 0.1);
  padding: 2px 8px;
  border-radius: 4px;
  width: fit-content;
  letter-spacing: 0.1em;
}

.card-body-elite {
  padding: 24px 32px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  flex: 1;
}

.info-row {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--color-text-dim);
}

.info-row svg { opacity: 0.4; }
.info-row .val { font-size: 0.85rem; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.card-actions-premium {
  padding: 20px 32px;
  background: rgba(255, 255, 255, 0.02);
  border-top: 1px solid var(--glass-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-action-main {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 10px 16px;
  border-radius: 10px;
  font-size: 0.7rem;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-action-main:hover {
  background: white;
  color: black;
}

.btn-action-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: transparent;
  border: 1px solid var(--glass-border);
  color: var(--color-text-dim);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-action-icon:hover {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.empty-state {
  grid-column: 1 / -1;
  padding: 80px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
  color: var(--color-text-dim);
}

.empty-icon { width: 64px; height: 64px; opacity: 0.05; }

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
  align-items: flex-start; /* Start from top to allow scrolling */
  padding: 40px 20px;
  overflow-y: auto;
  z-index: 1000;
}

.modal-card { 
  width: 100%; 
  max-width: 500px; 
  padding: 40px;
  margin: auto; /* Keeps it centered if less than screen height */
}

.modal-form { margin-top: 24px; display: flex; flex-direction: column; gap: 20px; }

.form-group { display: flex; flex-direction: column; gap: 8px; }
.form-group label { font-size: 0.8rem; font-weight: 700; color: var(--color-text-dim); text-transform: uppercase; }
.form-group input, .form-group textarea {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 12px;
  border-radius: var(--radius-sm);
  color: white;
  font-family: var(--font-body);
}

.modal-actions { display: flex; justify-content: flex-end; gap: 16px; margin-top: 12px; }

.btn-secondary { background: transparent; border: 1px solid var(--glass-border); color: white; padding: 12px 24px; border-radius: var(--radius-sm); cursor: pointer; }

.animate-pop { animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
