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
        <div class="card-accent"></div>
        <div class="card-header-premium">
          <div class="header-main">
            <div class="vendor-avatar">
              {{ supplier.name.charAt(0).toUpperCase() }}
            </div>
            <div class="header-info">
              <h3 class="name" :title="supplier.name">{{ supplier.name }}</h3>
              <div class="service-chip">{{ supplier.category || 'General' }}</div>
            </div>
          </div>
          
          <div class="header-actions">
            <button class="btn-circular" @click="editSupplier(supplier)" title="Edit Vendor">
              <Edit3Icon class="icon-sv" />
            </button>
            <button class="btn-circular del" @click="deleteSupplier(supplier)" title="Delete Vendor">
              <Trash2Icon class="icon-sv" />
            </button>
          </div>
        </div>
        
        <div class="card-body-elite">
          <!-- MATERIALS PREVIEW -->
          <div v-if="supplier.price_list?.length" class="materials-preview">
            <div v-for="(item, idx) in supplier.price_list.slice(0, 2)" :key="idx" class="m-tag">
              <span class="m-name">{{ item.item_name }}</span>
              <span class="m-price">Rp {{ item.price.toLocaleString() }}</span>
            </div>
            <div v-if="supplier.price_list.length > 2" class="m-more">+{{ supplier.price_list.length - 2 }} more</div>
          </div>
          <div v-else class="materials-empty">No catalog defined</div>

          <div class="info-divider"></div>

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
          <div class="action-btns-group">
            <button class="btn-action-main secondary" @click="viewCatalog(supplier)">
              <SparklesIcon class="icon-xs" />
              <span>VIEW CATALOG</span>
            </button>
            <button class="btn-action-main" @click="viewDeliveries(supplier)">
              <HistoryIcon class="icon-xs" />
              <span>DELIVERIES</span>
            </button>
          </div>
        </div>
      </div>

      <div v-if="suppliers.length === 0" class="empty-state glass-panel">
        <PackageIcon class="empty-icon" />
        <h3>No active suppliers</h3>
        <p>Your supply chain is clean. Add your first vendor to track HPP and stock logs.</p>
      </div>
    </div>

    <!-- DELETED ARCHIVE (ADMIN ONLY) -->
    <section v-if="authStore.isAdmin" class="archive-section mt-12">
      <div class="archive-header" @click="showArchive = !showArchive">
        <div class="ah-left">
          <ArchiveIcon class="icon-sm" />
          <h3 class="subtitle">DELETED RECORDS ARCHIVE</h3>
          <span class="archive-count">{{ deletedSuppliers.length }}</span>
        </div>
        <ChevronDownIcon class="archive-chevron" :class="{ open: showArchive }" />
      </div>

      <div v-if="showArchive" class="archive-content animate-slide-down">
        <div v-if="deletedSuppliers.length === 0" class="archive-empty">
          No deleted suppliers found.
        </div>
        <div v-else class="archive-table-wrap glass-panel">
          <table class="archive-table">
            <thead>
              <tr>
                <th>Vendor Name</th>
                <th>Category</th>
                <th>Deleted At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="vendor in deletedSuppliers" :key="vendor.id">
                <td class="font-bold">{{ vendor.name }}</td>
                <td>{{ vendor.category }}</td>
                <td class="text-dim text-xs">{{ new Date(vendor.deleted_at).toLocaleString() }}</td>
                <td class="actions">
                  <button class="btn-restore" @click="restoreSupplier(vendor)">
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

            <div class="modal-divider"></div>

            <!-- PRODUCT CATALOG SECTION -->
            <div class="catalog-section">
              <div class="section-header">
                <div class="sh-left">
                  <SparklesIcon class="icon-sh" />
                  <h3 class="hero-font subtitle">Product Catalog</h3>
                </div>
                <button type="button" class="btn-add-item" @click="addPriceItem">
                  <PlusIcon class="icon-xs" />
                  <span>ADD ITEM</span>
                </button>
              </div>
              <p class="section-desc">List raw materials and set current purchase prices.</p>

              <div class="catalog-list">
                <div v-for="(item, idx) in form.price_list" :key="idx" class="catalog-entry glass-panel">
                  <div class="entry-main">
                    <input 
                      type="text" 
                      v-model="item.item_name" 
                      placeholder="Material Name (e.g. Standard Egg)" 
                      class="input-clean"
                    />
                    <div class="entry-values">
                      <div class="price-input-wrap">
                        <span class="prefix">Rp</span>
                        <input 
                          type="number" 
                          v-model.number="item.price" 
                          placeholder="0" 
                        />
                      </div>
                      <input 
                        type="text" 
                        v-model="item.unit" 
                        placeholder="unit" 
                        class="unit-input"
                      />
                    </div>
                  </div>
                  <button type="button" class="btn-remove-entry" @click="removePriceItem(idx)">
                    <Trash2Icon class="icon-xs" />
                  </button>
                </div>
                <div v-if="form.price_list.length === 0" class="catalog-empty-hint">
                  No materials added to this vendor's catalog yet.
                </div>
              </div>
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
import { ref, reactive, onMounted, onUnmounted, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { useRoute } from 'vue-router';
import { 
  TruckIcon, 
  Edit3Icon, 
  PackageIcon,
  UserIcon,
  PhoneIcon,
  MapPinIcon,
  HistoryIcon,
  SparklesIcon,
  PlusIcon,
  Trash2Icon,
  ArchiveIcon,
  ChevronDownIcon,
  RefreshCcwIcon
} from 'lucide-vue-next';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import { useAuthStore } from '../stores/auth';

const authStore = useAuthStore();
const suppliers = ref<any[]>([]);
const deletedSuppliers = ref<any[]>([]);
const showArchive = ref(false);
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
  category: '',
  price_list: [] as any[]
});

function getCategoryClass(cat: string) {
  if (!cat) return '';
  if (cat.includes('Telur')) return 'accent-egg';
  if (cat.includes('Kemasan') || cat.includes('Box')) return 'accent-pack';
  return 'accent-general';
}

async function fetchData() {
  console.log('Fetching fresh data for Suppliers...');
  try {
    const { data: vendorData, error: vError } = await supabase
      .from('suppliers')
      .select('*')
      .eq('is_deleted', false)
      .order('name');
    
    if (vError) {
      console.error('Failed to fetch suppliers:', vError);
      return;
    }
    
    suppliers.value = vendorData || [];

    // Fetch deleted if admin
    if (authStore.isAdmin) {
      const { data: delData } = await supabase
        .from('suppliers')
        .select('*')
        .eq('is_deleted', true)
        .order('deleted_at', { ascending: false });
      deletedSuppliers.value = delData || [];
    }
    console.log(`Loaded ${suppliers.value.length} vendors`);

    const { data: invData, error: iError } = await supabase.from('inventory').select('*');
    if (!iError) inventory.value = invData || [];
  } catch (err) {
    console.error('Unexpected fetch error:', err);
  }
}

function closeModal() {
  showAddModal.value = false;
  editingId.value = null;
  form.name = '';
  form.contact_person = '';
  form.phone = '';
  form.address = '';
  form.category = '';
  form.price_list = [];
}

function editSupplier(vendor: any) {
  editingId.value = vendor.id;
  form.name = vendor.name;
  form.contact_person = vendor.contact_person || '';
  form.phone = vendor.phone || '';
  form.address = vendor.address || '';
  form.category = vendor.category || '';
  form.price_list = Array.isArray(vendor.price_list) ? [...vendor.price_list] : [];
  showAddModal.value = true;
}

async function submitSupplier() {
  if (submitting.value) return;
  submitting.value = true;
  
  // Clean payload from Reactive Proxy
  const payload = JSON.parse(JSON.stringify(form));
  console.log('Final Payload to Database:', payload);
  try {
    let result;

    if (editingId.value) {
      result = await supabase
        .from('suppliers')
        .update(payload)
        .eq('id', editingId.value);
    } else {
      result = await supabase
        .from('suppliers')
        .insert(payload);
    }

    if (result.error) {
      console.error('Supabase Error:', result.error);
      alert('Error: ' + result.error.message);
    } else {
      console.log('Supplier saved successfully');
      closeModal();
      fetchData();
    }
  } catch (err: any) {
    console.error('Unexpected crash during save:', err);
    alert('System Error: ' + err.message);
  } finally {
    submitting.value = false;
  }
}

async function deleteSupplier(vendor: any) {
  if (!confirm(`Move "${vendor.name}" to archive? You can restore it later.`)) return;
  
  submitting.value = true;
  try {
    const { error } = await supabase
      .from('suppliers')
      .update({ 
        is_deleted: true,
        deleted_at: new Date().toISOString()
      })
      .eq('id', vendor.id);

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

async function restoreSupplier(vendor: any) {
  submitting.value = true;
  try {
    const { error } = await supabase
      .from('suppliers')
      .update({ is_deleted: false, deleted_at: null })
      .eq('id', vendor.id);

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

function addPriceItem() {
  form.price_list.push({ item_name: '', price: 0, unit: 'butir' });
}

function removePriceItem(index: number) {
  form.price_list.splice(index, 1);
}

function viewDeliveries(vendor: any) {
  alert('History deliveries from ' + vendor.name + ' feature is coming soon!');
}

function viewCatalog(vendor: any) {
  if (!vendor.price_list || vendor.price_list.length === 0) {
    alert('No items in catalog for ' + vendor.name);
    return;
  }
  const list = vendor.price_list.map((i: any) => `- ${i.item_name}: Rp ${i.price.toLocaleString()} / ${i.unit}`).join('\n');
  alert(`Product Catalog - ${vendor.name}\n\n${list}`);
}

const route = useRoute();
let refreshInterval: any;

onMounted(() => {
  fetchData();
  refreshInterval = setInterval(fetchData, 10000);
});

onUnmounted(() => {
  clearInterval(refreshInterval);
});

// Force refresh when route changes
watch(() => route.path, () => {
  fetchData();
});
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
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.supplier-card:hover {
  transform: translateY(-8px);
  border-color: rgba(255, 140, 0, 0.3);
  box-shadow: 0 40px 80px rgba(0,0,0,0.5);
}

.card-accent {
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: var(--color-primary);
  opacity: 0.3;
}

.accent-egg .card-accent { background: #FFD700; }
.accent-pack .card-accent { background: #00D1FF; }
.accent-general .card-accent { background: #7B61FF; }

.supplier-card:hover .card-accent {
  opacity: 1;
}

.card-header-premium {
  padding: 24px 32px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  gap: 16px;
  background: linear-gradient(to bottom, rgba(255,255,255,0.02), transparent);
}

.header-main {
  display: flex;
  align-items: center;
  gap: 20px;
  flex: 1;
  min-width: 0;
}

.vendor-avatar {
  width: 52px;
  height: 52px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
  font-weight: 800;
  color: var(--color-primary);
  flex-shrink: 0;
}

.header-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
  min-width: 0;
}

.name {
  font-size: 1.15rem;
  font-weight: 800;
  color: white;
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

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

.header-actions {
  display: flex;
  gap: 10px;
  flex-shrink: 0;
}

.btn-circular {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: var(--color-text-dim);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-circular:hover {
  background: white;
  color: black;
  border-color: white;
  transform: scale(1.1);
}

.btn-circular.del:hover {
  background: var(--color-error);
  color: white;
  border-color: var(--color-error);
}

.icon-sv {
  width: 14px;
  height: 14px;
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

.action-secondary-group {
  display: none;
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

/* NEW: CATALOG STYLES */
.header-badges {
  display: flex;
  gap: 8px;
  align-items: center;
}

.catalog-badge {
  font-size: 0.55rem;
  font-weight: 900;
  background: rgba(123, 97, 255, 0.1);
  color: #7B61FF;
  padding: 2px 6px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  gap: 4px;
  border: 1px solid rgba(123, 97, 255, 0.2);
}

.icon-xs-inline { width: 10px; height: 10px; }

.materials-preview {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 8px;
}

.m-tag {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(255, 255, 255, 0.03);
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.m-name { font-size: 0.75rem; font-weight: 700; color: var(--color-text-dim); }
.m-price { font-size: 0.75rem; font-weight: 800; color: var(--color-primary); }

.m-more {
  font-size: 0.65rem;
  font-weight: 700;
  color: var(--color-text-dim);
  text-align: center;
  opacity: 0.6;
}

.materials-empty {
  font-size: 0.75rem;
  color: var(--color-text-dim);
  opacity: 0.3;
  font-style: italic;
  padding: 12px 0;
  text-align: center;
}

.info-divider {
  height: 1px;
  background: linear-gradient(to right, transparent, rgba(255,255,255,0.05), transparent);
  margin: 8px 0;
}

.action-btns-group {
  display: flex;
  gap: 8px;
}

.btn-action-main.secondary {
  border-color: rgba(123, 97, 255, 0.3);
  color: #BBADFF;
}

.btn-action-main.secondary:hover {
  background: #7B61FF;
  color: white;
}

/* MODAL CATALOG */
.modal-divider {
  height: 1px;
  background: var(--glass-border);
  margin: 10px 0;
}

.catalog-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sh-left { display: flex; align-items: center; gap: 10px; }
.icon-sh { width: 18px; height: 18px; color: var(--color-primary); }
.subtitle { font-size: 1rem; margin: 0; }

.btn-add-item {
  background: rgba(255, 140, 0, 0.1);
  border: 1px solid rgba(255, 140, 0, 0.2);
  color: var(--color-primary);
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 0.65rem;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-add-item:hover {
  background: var(--color-primary);
  color: black;
}

.section-desc { font-size: 0.75rem; color: var(--color-text-dim); }

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

.catalog-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 250px;
  overflow-y: auto;
  padding-right: 4px;
}

.catalog-entry {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
}

.entry-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.input-clean {
  background: transparent !important;
  border: none !important;
  padding: 0 !important;
  font-weight: 700 !important;
  font-size: 0.9rem !important;
}

.entry-values {
  display: flex;
  gap: 12px;
  align-items: center;
}

.price-input-wrap {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 4px 8px;
  border-radius: 6px;
  gap: 6px;
}

.price-input-wrap .prefix { font-size: 0.7rem; font-weight: 800; opacity: 0.5; }
.price-input-wrap input {
  background: transparent !important;
  border: none !important;
  padding: 0 !important;
  width: 80px !important;
  font-size: 0.8rem !important;
  font-weight: 700 !important;
}

.unit-input {
  width: 60px !important;
  background: rgba(255, 255, 255, 0.03) !important;
  border: 1px dashed var(--glass-border) !important;
  padding: 4px 8px !important;
  border-radius: 6px !important;
  font-size: 0.75rem !important;
  text-align: center;
}

.btn-remove-entry {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: rgba(255, 62, 62, 0.1);
  border: 1px solid rgba(255, 62, 62, 0.2);
  color: var(--color-error);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-remove-entry:hover {
  background: var(--color-error);
  color: white;
}

.catalog-empty-hint {
  text-align: center;
  padding: 20px;
  font-size: 0.8rem;
  color: var(--color-text-dim);
  opacity: 0.5;
  border: 1px dashed var(--glass-border);
  border-radius: 12px;
}
</style>
