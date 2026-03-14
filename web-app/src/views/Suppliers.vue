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

    <!-- GROUPED BY CATEGORY -->
    <template v-for="group in groupedSuppliers" :key="group.key">
      <div class="category-section">
        <div class="category-header">
          <span class="category-icon">{{ group.icon }}</span>
          <span class="category-label" :class="group.key">{{ group.label }}</span>
          <span class="category-count">{{ group.items.length }}</span>
        </div>

        <div class="suppliers-grid">
          <div v-for="supplier in group.items" :key="supplier.id" class="supplier-card glass-panel" :class="getCategoryClass(supplier.category)">
            <div class="card-accent"></div>
            <div class="card-header-premium">
              <div class="header-main">
                <div class="vendor-avatar" :class="getCategoryClass(supplier.category)">
                  {{ supplier.name.charAt(0).toUpperCase() }}
                </div>
                <div class="header-info">
                  <h3 class="name-full" :title="supplier.name">{{ supplier.name }}</h3>
                  <div class="service-chip" :class="getCategoryClass(supplier.category)">{{ getCategoryLabel(supplier.category) }}</div>
                </div>
              </div>
              
              <div class="header-actions">
                <button class="btn-circular" @click="editSupplier(supplier)" title="Edit Vendor">
                  <Edit3Icon class="icon-sv" />
                </button>
                <button class="btn-circular del" @click="deleteSupplier(supplier)" title="Hapus">
                  <Trash2Icon class="icon-sv" />
                </button>
              </div>
            </div>
            
            <div class="card-body-elite">
              <!-- CATALOG PREVIEW -->
              <div class="catalog-section-card">
                <span class="catalog-label">KATALOG</span>
                <div v-if="supplier.price_list?.length" class="materials-preview">
                  <div v-for="(item, idx) in supplier.price_list.slice(0, 2)" :key="idx" class="m-tag">
                    <span class="m-name">{{ item.item_name }}</span>
                    <span class="m-price font-mono">Rp {{ item.price.toLocaleString() }}</span>
                  </div>
                  <div v-if="supplier.price_list.length > 2" class="m-more">+{{ supplier.price_list.length - 2 }} lainnya</div>
                </div>
                <div v-else class="materials-empty">Belum ada katalog</div>
              </div>

              <div class="info-divider"></div>

              <div class="info-row">
                <UserIcon class="icon-xs" />
                <span class="val">{{ supplier.contact_person || 'Belum ada kontak' }}</span>
              </div>
              <div class="info-row">
                <PhoneIcon class="icon-xs" />
                <span class="val">{{ supplier.phone || '-' }}</span>
              </div>
              <div class="info-row">
                <MapPinIcon class="icon-xs" />
                <span class="val">{{ supplier.address || 'Belum ada alamat' }}</span>
              </div>

              <!-- OUTSTANDING DEBT -->
              <div v-if="supplier.total_utang > 0" class="debt-warning-box">
                <div class="dw-left">
                  <span class="dw-label">💰 UTANG AKTIF</span>
                  <span class="dw-val font-mono">Rp {{ supplier.total_utang.toLocaleString() }}</span>
                </div>
              </div>
              <div v-else class="debt-clear">
                <span>✓ Tidak ada utang</span>
              </div>
            </div>

            <div class="card-actions-premium">
              <div class="action-btns-group">
                <button class="btn-action-ghost" @click="viewCatalog(supplier)">
                  🗂️ Lihat Katalog
                </button>
                <button class="btn-action-ghost" @click="viewDeliveries(supplier)">
                  📜 Riwayat
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <div v-if="suppliers.length === 0" class="empty-state glass-panel">
      <PackageIcon class="empty-icon" />
      <h3>Belum ada supplier</h3>
      <p>Klik 'Add New Supplier' untuk menambahkan vendor pertama.</p>
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

    <!-- CATALOG VIEWER MODAL -->
    <Teleport to="body">
      <div v-if="showCatalogModal" class="modal-overlay" @click.self="showCatalogModal = false">
        <div class="modal-panel animate-pop">
           <div class="modal-header">
             <div class="mh-left">
               <div class="mh-icon-box">
                 <PackageIcon class="icon-md" />
               </div>
               <div class="mh-title-area">
                 <h3 class="modal-title">Product Catalog</h3>
                 <p class="modal-subtitle">{{ catalogVendorName }}</p>
               </div>
             </div>
             <button class="btn-close-modal" @click="showCatalogModal = false">
               <PlusIcon class="icon-close-rotate" />
             </button>
           </div>

           <div class="modal-body-scroll">
             <div class="catalog-list-premium">
               <div v-for="(item, idx) in catalogData" :key="idx" class="catalog-row-premium">
                 <div class="cr-info">
                   <div class="cr-icon">🛒</div>
                   <span class="cr-name">{{ item.item_name }}</span>
                 </div>
                 <div class="cr-price-area">
                   <span class="cr-price font-mono">Rp {{ item.price.toLocaleString() }}</span>
                   <span class="cr-unit">/ {{ item.unit }}</span>
                 </div>
               </div>
             </div>
           </div>

           <div class="modal-footer">
             <button class="btn-modal-primary" @click="showCatalogModal = false">CLOSE VIEW</button>
           </div>
        </div>
      </div>
    </Teleport>

    <!-- DELIVERY HISTORY MODAL -->
    <Teleport to="body">
      <div v-if="showHistoryModal" class="modal-overlay" @click.self="showHistoryModal = false">
        <div class="modal-panel animate-pop history-modal">
           <div class="modal-header">
             <div class="mh-left">
               <div class="mh-icon-box history">
                 <TruckIcon class="icon-md" />
               </div>
               <div class="mh-title-area">
                 <h3 class="modal-title">Supply History</h3>
                 <p class="modal-subtitle">{{ historyVendorName }}</p>
               </div>
             </div>
             <button class="btn-close-modal" @click="showHistoryModal = false">
               <PlusIcon class="icon-close-rotate" />
             </button>
           </div>

           <div class="modal-body-scroll">
             <div v-if="loadingHistory" class="loading-state-so">
               <Loader2Icon class="spin icon-lg" />
               <p>Fetching supply logs...</p>
             </div>
             
             <div v-else-if="deliveryHistory.length === 0" class="history-empty">
               <ArchiveIcon class="icon-xl" />
               <p>No delivery records found for this vendor.</p>
             </div>

             <div v-else class="history-list-premium">
               <div v-for="log in deliveryHistory" :key="log.id" class="history-card-premium">
                 <div class="hc-date">
                   <span class="d-label">DELIVERY DATE</span>
                   <span class="d-val">{{ new Date(log.purchase_date).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) }}</span>
                 </div>
                 <div class="hc-main">
                    <div class="hc-product">
                      <span class="p-badge-mini" :class="log.product_id">{{ (log.product_id || 'GENERAL').replace('_', ' ').toUpperCase() }}</span>
                      <span class="p-qty font-mono">{{ (log.total_eggs_bought / 10).toFixed(1) }} <small>KG</small></span>
                    </div>
                    <div class="hc-price font-mono">
                      Rp {{ (log.total_cost || 0).toLocaleString() }}
                    </div>
                 </div>
                 <div class="hc-status" :class="{ paid: log.remaining_debt <= 0 }">
                    {{ log.remaining_debt <= 0 ? '✓ LUNAS' : '⚠️ UTANG' }}
                 </div>
               </div>
             </div>
           </div>

           <div class="modal-footer">
             <button class="btn-modal-primary" @click="showHistoryModal = false">CLOSE LOGS</button>
           </div>
        </div>
      </div>
    </Teleport>



    <!-- ADD/EDIT SLIDE-OVER -->
    <Teleport to="body">
      <div v-if="showAddModal" class="slide-over-overlay" @click.self="closeModal">
        <div class="slide-over-panel glass-panel animate-slide-left">
          <div class="so-header">
            <div class="so-header-content">
              <div class="so-icon-box">
                <TruckIcon v-if="!editingId" class="so-icon" />
                <Edit3Icon v-else class="so-icon" />
              </div>
              <div class="so-title-area">
                <h2 class="hero-font so-title">{{ editingId ? 'Update Vendor' : 'New Vendor Registration' }}</h2>
                <p class="text-dim so-subtitle">Pastikan data vendor akurat untuk perhitungan HPP stok.</p>
              </div>
            </div>
            <button class="btn-close-so" @click="closeModal">
              <PlusIcon class="icon-close-rotate" />
            </button>
          </div>

          <div class="so-body">
            <form @submit.prevent="submitSupplier" class="so-form">
              <div class="so-section">
                <h3 class="so-section-title">📘 BASIC INFORMATION</h3>
                <div class="form-group">
                  <label>Vendor Name / Farm Name</label>
                  <input type="text" v-model="form.name" v-titlecase placeholder="e.g. Farm Berkah Telur" class="premium-input-so" required />
                </div>

                <div class="form-group">
                  <label>Contact Person</label>
                  <input type="text" v-model="form.contact_person" v-titlecase placeholder="e.g. Pak Haji Somad" class="premium-input-so" />
                </div>

                <div class="form-group">
                  <label>Phone / WhatsApp</label>
                  <input type="text" v-model="form.phone" placeholder="08..." class="premium-input-so" />
                </div>

                <div class="form-group">
                  <label>Full Address</label>
                  <textarea v-model="form.address" v-titlecase placeholder="Lokasi vendor..." rows="3" class="premium-input-so"></textarea>
                </div>

                <div class="form-group">
                  <CustomDropdown 
                    v-model="form.category" 
                    :options="categoryOptions" 
                    label="Service / Category" 
                    placeholder="Pilih tipe supply..."
                    class="premium-dropdown-so"
                  />
                  <p class="field-hint">Kategori ini akan menentukan filter pada saat pencatatan pembelian.</p>
                </div>
              </div>

              <div class="so-divider"></div>

              <!-- PRODUCT CATALOG SECTION -->
              <div class="so-section">
                <div class="so-section-header">
                  <h3 class="so-section-title">📂 PRODUCT CATALOG</h3>
                  <button type="button" class="btn-add-item-so" @click="addPriceItem">
                    <PlusIcon class="icon-xs" />
                    <span>TAMBAH PRODUK</span>
                  </button>
                </div>
                <p class="section-desc">Daftar item yang disupply vendor ini beserta harga belinya.</p>

                <div class="catalog-list-so">
                  <div v-for="(item, idx) in form.price_list" :key="idx" class="catalog-entry-so glass-panel">
                    <div class="entry-main-so">
                      <input 
                        type="text" 
                        v-model="item.item_name" 
                        v-titlecase
                        placeholder="Nama Item (misal: Telur Standard)" 
                        class="input-clean-so"
                      />
                      <div class="entry-values-so">
                        <div class="price-input-wrap-so">
                          <span class="prefix-so">Rp</span>
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
                          class="unit-input-so"
                        />
                      </div>
                    </div>
                    <button type="button" class="btn-remove-entry-so" @click="removePriceItem(idx)">
                      <Trash2Icon class="icon-xs" />
                    </button>
                  </div>
                  <div v-if="form.price_list.length === 0" class="catalog-empty-hint-so">
                    Belum ada item dalam katalog vendor ini.
                  </div>
                </div>
              </div>
            </form>
          </div>

          <div class="so-footer">
            <button type="button" class="btn-secondary-so" @click="closeModal">Cancel</button>
            <button type="button" class="btn-primary-so" :disabled="submitting" @click="submitSupplier">
              <TruckIcon class="icon-md" v-if="!submitting" />
              <span>{{ submitting ? 'SAVING...' : (editingId ? 'UPDATE VENDOR' : 'SIMPAN VENDOR') }}</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { useRoute } from 'vue-router';
import { 
  TruckIcon, 
  Edit3Icon, 
  PackageIcon,
  UserIcon,
  PhoneIcon,
  MapPinIcon,
  PlusIcon,
  Trash2Icon,
  ArchiveIcon,
  ChevronDownIcon,
  RefreshCcwIcon
} from 'lucide-vue-next';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import { useAuthStore } from '../stores/auth';
import { useToast } from '../composables/useToast';
import { sanitizePayload } from '../utils/sanitize';

const { showToast } = useToast();
const authStore = useAuthStore();
const suppliers = ref<any[]>([]);
const deletedSuppliers = ref<any[]>([]);
const showArchive = ref(false);
const showAddModal = ref(false);
const submitting = ref(false);
const inventory = ref<any[]>([]);
const editingId = ref<string | null>(null);

// Catalog Viewer State
const showCatalogModal = ref(false);
const catalogVendorName = ref('');
const catalogData = ref<any[]>([]);
// History Viewer State
const showHistoryModal = ref(false);
const historyVendorName = ref('');
const deliveryHistory = ref<any[]>([]);
const loadingHistory = ref(false);


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

function getCategoryLabel(cat: string) {
  if (!cat) return 'Lainnya';
  if (cat.includes('Telur')) return 'Supplier Telur';
  if (cat.includes('Kemasan') || cat.includes('Box')) return 'Kemasan';
  if (cat.includes('Stiker')) return 'Stiker';
  if (cat.includes('Card')) return 'Kartu';
  return cat;
}

const groupedSuppliers = computed(() => {
  const groups: Record<string, { key: string; icon: string; label: string; items: any[] }> = {};
  
  const categoryConfig: Record<string, { icon: string; label: string; order: number }> = {
    telur: { icon: '🥚', label: 'SUPPLIER TELUR', order: 1 },
    kemasan: { icon: '📦', label: 'SUPPLIER KEMASAN', order: 2 },
    lainnya: { icon: '🏷️', label: 'SUPPLIER LAINNYA', order: 3 }
  };

  suppliers.value.forEach(s => {
    const cat = (s.category || '').toLowerCase();
    let key = 'lainnya';
    if (cat.includes('telur') || cat.includes('egg') || cat.includes('ayam')) key = 'telur';
    else if (cat.includes('kemasan') || cat.includes('box') || cat.includes('stiker') || cat.includes('card') || cat.includes('packaging')) key = 'kemasan';

    if (!groups[key]) {
      const cfg = categoryConfig[key];
      groups[key] = { key, icon: cfg?.icon || '📁', label: cfg?.label || key.toUpperCase(), items: [] };
    }
    groups[key]!.items.push(s);
  });

  return Object.values(groups).sort((a, b) => {
    const aOrder = categoryConfig[a.key]?.order || 99;
    const bOrder = categoryConfig[b.key]?.order || 99;
    return aOrder - bOrder;
  });
});

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
    
    const { data: utangData } = await supabase.from('utang_supplier').select('supplier_id, remaining').gt('remaining', 0);
    const utangMap: Record<string, number> = {};
    if (utangData) {
      utangData.forEach(u => {
        utangMap[u.supplier_id] = (utangMap[u.supplier_id] || 0) + Number(u.remaining);
      });
    }

    suppliers.value = (vendorData || []).map(v => ({
      ...v,
      total_utang: utangMap[v.id] || 0
    }));

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
  const payload = sanitizePayload(JSON.parse(JSON.stringify(form)));
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

async function viewDeliveries(vendor: any) {
  historyVendorName.value = vendor.name;
  showHistoryModal.value = true;
  loadingHistory.value = true;
  deliveryHistory.value = [];

  try {
    const { data, error } = await supabase
      .from('purchases')
      .select('*, utang_supplier(remaining)')
      .eq('supplier_id', vendor.id)
      .order('purchase_date', { ascending: false })
      .limit(10);

    if (error) throw error;
    // Override remaining_debt with live utang_supplier data
    deliveryHistory.value = (data || []).map((p: any) => {
      const utang = Array.isArray(p.utang_supplier) ? p.utang_supplier[0] : p.utang_supplier;
      return {
        ...p,
        remaining_debt: utang ? Number(utang.remaining) : (p.remaining_debt || 0)
      };
    });
  } catch (err: any) {
    console.error('Failed to fetch history:', err);
    showToast('Gagal mengambil riwayat pengiriman.', 'error');
  } finally {
    loadingHistory.value = false;
  }
}

function viewCatalog(vendor: any) {
  if (!vendor.price_list || vendor.price_list.length === 0) {
    showToast(`Vendor ${vendor.name} belum memiliki katalog produk.`, 'warning');
    return;
  }
  catalogVendorName.value = vendor.name;
  catalogData.value = vendor.price_list;
  showCatalogModal.value = true;
}

const route = useRoute();
onMounted(() => {
  fetchData();
});

onUnmounted(() => {
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

.category-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 40px;
}

.category-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding-left: 8px;
}

.category-icon { font-size: 1.25rem; }
.category-label {
  font-size: 0.85rem;
  font-weight: 900;
  letter-spacing: 0.15em;
  color: var(--color-text-dim);
}

.category-label.telur { color: var(--gold); }
.category-label.kemasan { color: var(--sky); }

.category-count {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 2px 10px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-text-dim);
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
  gap: 6px;
  flex: 1;
  min-width: 0;
}

.name-full {
  font-size: 1.2rem;
  font-weight: 850;
  color: white;
  margin: 0;
  line-height: 1.2;
}

.service-chip {
  font-size: 0.6rem;
  font-weight: 900;
  text-transform: uppercase;
  padding: 3px 10px;
  border-radius: 6px;
  width: fit-content;
  letter-spacing: 0.1em;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: var(--color-text-dim);
}

.service-chip.accent-egg { color: var(--gold); background: rgba(255, 215, 0, 0.1); border-color: rgba(255, 215, 0, 0.2); }
.service-chip.accent-pack { color: var(--sky); background: rgba(0, 209, 255, 0.1); border-color: rgba(0, 209, 255, 0.2); }


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

/* CATALOG SECTION IN CARD */
.catalog-section-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.catalog-label {
  font-size: 0.65rem;
  font-weight: 900;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
  opacity: 0.6;
}

.materials-preview {
  display: flex;
  flex-direction: column;
  gap: 8px;
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

.m-name {
  font-size: 0.8rem;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.8);
}

.m-price {
  font-size: 0.8rem;
  font-weight: 800;
  color: var(--color-primary);
}

.m-more {
  font-size: 0.7rem;
  font-weight: 700;
  color: var(--color-text-dim);
  opacity: 0.5;
  margin-top: 4px;
}

.materials-empty {
  font-size: 0.75rem;
  color: var(--color-text-dim);
  opacity: 0.4;
  font-style: italic;
}

.debt-warning-box {
  margin-top: auto;
  padding: 14px 18px;
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.2);
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.debt-clear {
  margin-top: auto;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--color-success);
  opacity: 0.6;
  display: flex;
  align-items: center;
  gap: 6px;
}

.card-actions-premium {
  padding: 20px 32px;
  background: rgba(255, 255, 255, 0.02);
  border-top: 1px solid var(--glass-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-action-ghost {
  flex: 1;
  padding: 12px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: 10px;
  color: var(--color-text-dim);
  font-size: 0.75rem;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
}

.btn-action-ghost:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.3);
  color: white;
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

/* SLIDE OVER STYLES */
.slide-over-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100vh;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(12px);
  z-index: 2000;
  display: flex;
  justify-content: flex-end;
}

.slide-over-panel {
  width: 100%;
  max-width: 520px;
  height: 100%;
  background: #09090b;
  border-left: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  flex-direction: column;
  box-shadow: -40px 0 80px rgba(0, 0, 0, 0.8);
}

.animate-slide-left {
  animation: slideLeft 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideLeft {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.so-header {
  padding: 40px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}

.so-header-content {
  display: flex;
  gap: 24px;
}

.so-icon-box {
  width: 52px;
  height: 52px;
  background: rgba(16, 185, 129, 0.1);
  border: 1px solid rgba(16, 185, 129, 0.2);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.so-icon { color: #10b981; width: 24px; height: 24px; }

.so-title-area { display: flex; flex-direction: column; gap: 6px; }
.so-title { font-size: 1.5rem; margin: 0; color: white; font-weight: 800; letter-spacing: -0.02em; }
.so-subtitle { font-size: 0.85rem; margin: 0; color: rgba(255,255,255,0.4); }

.btn-close-so {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.03);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.btn-close-so:hover {
  background: white;
  color: black;
  transform: rotate(90deg) scale(1.1);
}

.icon-close-rotate { transform: rotate(45deg); width: 16px; height: 16px; }

.so-body {
  flex: 1;
  overflow-y: auto;
  padding: 40px;
}

.so-section {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.so-section-title {
  font-size: 0.75rem;
  font-weight: 900;
  letter-spacing: 0.2em;
  color: #38bdf8;
  margin-bottom: 8px;
  text-transform: uppercase;
  opacity: 0.8;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.form-group label {
  font-size: 14px;
  font-weight: 700;
  color: rgba(255,255,255,0.8);
}

.premium-input-so {
  width: 100%;
  background: #000;
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 14px 18px;
  border-radius: 12px;
  color: white;
  font-family: inherit;
  font-size: 15px;
  outline: none;
  transition: all 0.3s ease;
  box-sizing: border-box;
}

.premium-input-so:focus {
  border-color: #38bdf8;
  box-shadow: 0 0 0 4px rgba(56, 189, 248, 0.1);
}

textarea.premium-input-so {
  resize: vertical;
  min-height: 100px;
}

.field-hint {
  font-size: 0.75rem;
  color: rgba(255,255,255,0.3);
  margin-top: 6px;
  line-height: 1.5;
}

.so-divider {
  height: 1px;
  background: rgba(255,255,255,0.04);
  margin: 40px 0;
}

.so-footer {
  padding: 32px 40px;
  display: flex;
  gap: 16px;
  background: rgba(255, 255, 255, 0.015);
  border-top: 1px solid rgba(255, 255, 255, 0.04);
}

.btn-secondary-so {
  flex: 1;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: transparent;
  color: white;
  font-weight: 800;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary-so:hover {
  background: rgba(255, 255, 255, 0.05);
  border-color: white;
}

.btn-primary-so {
  flex: 2;
  padding: 16px;
  border-radius: 12px;
  background: white;
  color: black;
  font-weight: 900;
  font-size: 0.95rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  border: none;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.btn-primary-so:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.4);
}

.btn-primary-so:active:not(:disabled) {
  transform: translateY(0);
}

.btn-primary-so:disabled { opacity: 0.3; cursor: not-allowed; }

/* CATALOG IN SO */
.so-section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-add-item-so {
  background: rgba(16, 185, 129, 0.1);
  border: 1px solid rgba(16, 185, 129, 0.2);
  color: #10b981;
  padding: 8px 16px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 850;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  letter-spacing: 0.05em;
}

.btn-add-item-so:hover {
  background: #10b981;
  color: white;
  transform: scale(1.05);
}

.catalog-list-so {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-desc {
  font-size: 13px;
  color: rgba(255,255,255,0.4);
  margin-top: -12px;
}

.catalog-entry-so {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  background: #000;
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 16px;
  transition: border-color 0.2s;
}

.catalog-entry-so:focus-within {
  border-color: #10b981;
}

.entry-main-so {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.input-clean-so {
  background: transparent !important;
  border: none !important;
  padding: 0 !important;
  font-size: 1rem !important;
  font-weight: 800 !important;
  color: white !important;
  outline: none;
}

.input-clean-so::placeholder { color: rgba(255,255,255,0.25); }

.entry-values-so {
  display: flex;
  gap: 12px;
}

.price-input-wrap-so {
  flex: 1;
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 10px 16px;
  border-radius: 10px;
  gap: 10px;
}

.prefix-so { font-size: 12px; font-weight: 800; color: #10b981; }

.price-input-wrap-so input {
  background: transparent !important;
  border: none !important;
  width: 100% !important;
  color: white !important;
  font-weight: 700 !important;
  outline: none;
  font-family: 'DM Mono', monospace;
}

.unit-input-so {
  width: 70px !important;
  background: rgba(255, 255, 255, 0.03) !important;
  border: 1px dashed rgba(255, 255, 255, 0.15) !important;
  padding: 10px !important;
  border-radius: 10px !important;
  text-align: center !important;
  font-size: 13px !important;
  color: rgba(255,255,255,0.6) !important;
  outline: none;
}

.btn-remove-entry-so {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: rgba(239, 68, 68, 0.05);
  border: 1px solid rgba(239, 68, 68, 0.1);
  color: #ef4444;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-remove-entry-so:hover {
  background: #ef4444;
  color: white;
  transform: scale(1.1);
}

.catalog-empty-hint-so {
  padding: 40px;
  text-align: center;
  color: rgba(255,255,255,0.2);
  font-size: 0.9rem;
  border: 2px dashed rgba(255,255,255,0.05);
  border-radius: 20px;
}

/* MODAL SYSTEM */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100vh;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(12px);
  z-index: 2100;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 20px;
}

.modal-panel {
  width: 100%;
  max-width: 500px;
  background: #0d0d0f;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 24px;
  box-shadow: 0 40px 100px rgba(0,0,0,0.8);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.modal-header {
  padding: 32px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}

.mh-left { display: flex; gap: 20px; align-items: center; }

.mh-icon-box {
  width: 48px;
  height: 48px;
  background: rgba(56, 189, 248, 0.1);
  border: 1px solid rgba(56, 189, 248, 0.2);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #38bdf8;
}

.mh-title-area { display: flex; flex-direction: column; gap: 4px; }
.modal-title { font-size: 1.25rem; margin: 0; color: white; font-weight: 800; }
.modal-subtitle { font-size: 0.85rem; margin: 0; color: rgba(255,255,255,0.4); }

.btn-close-modal {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-close-modal:hover { background: white; color: black; transform: rotate(90deg); }

.modal-body-scroll {
  padding: 32px;
  max-height: 400px;
  overflow-y: auto;
}

.catalog-list-premium {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.catalog-row-premium {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.04);
  border-radius: 14px;
  transition: all 0.2s ease;
}

.catalog-row-premium:hover {
  background: rgba(255, 255, 255, 0.04);
  border-color: rgba(56, 189, 248, 0.3);
  transform: scale(1.02);
}

.cr-info { display: flex; align-items: center; gap: 14px; }
.cr-icon { font-size: 1.1rem; }
.cr-name { font-size: 0.95rem; font-weight: 700; color: white; }

.cr-price-area { text-align: right; display: flex; flex-direction: column; }
.cr-price { font-size: 1rem; font-weight: 800; color: #38bdf8; }
.cr-unit { font-size: 0.7rem; font-weight: 700; color: rgba(255,255,255,0.3); text-transform: uppercase; letter-spacing: 0.05em; }

.modal-footer {
  padding: 24px 32px;
  background: rgba(255, 255, 255, 0.01);
  border-top: 1px solid rgba(255, 255, 255, 0.04);
}

.btn-modal-primary {
  width: 100%;
  padding: 14px;
  border-radius: 12px;
  background: white;
  color: black;
  font-weight: 950;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-modal-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 20px rgba(0,0,0,0.5); }

.animate-pop { animation: popModal 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
@keyframes popModal { from { opacity: 0; transform: scale(0.9) translateY(20px); } to { opacity: 1; transform: scale(1) translateY(0); } }

/* HISTORY SPECIFIC */
.mh-icon-box.history {
  background: rgba(245, 158, 11, 0.1);
  border-color: rgba(245, 158, 11, 0.2);
  color: #f59e0b;
}

.history-card-premium {
  padding: 20px;
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.04);
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 12px;
}

.hc-date { display: flex; flex-direction: column; gap: 4px; }
.hc-date .d-label { font-size: 8px; font-weight: 800; color: rgba(255,255,255,0.3); letter-spacing: 0.1em; }
.hc-date .d-val { font-size: 0.9rem; font-weight: 800; color: white; }

.hc-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #000;
  border-radius: 12px;
}

.hc-product { display: flex; align-items: center; gap: 12px; }
.p-badge-mini {
  font-size: 9px;
  font-weight: 850;
  padding: 3px 8px;
  border-radius: 4px;
  background: rgba(255,255,255,0.05);
  color: rgba(255,255,255,0.6);
}
.p-badge-mini.hero { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
.p-badge-mini.standard_size { background: rgba(139, 92, 246, 0.1); color: #a78bfa; }
.p-badge-mini.salted_egg { background: rgba(16, 185, 129, 0.1); color: #10b981; }

.p-qty { font-size: 1.1rem; color: white; font-weight: 800; }
.p-qty small { font-size: 0.6rem; opacity: 0.4; margin-left: 2px; }

.hc-price { font-size: 1rem; font-weight: 800; color: #f59e0b; }

.hc-status {
  font-size: 10px;
  font-weight: 900;
  color: #ef4444;
  text-align: right;
  opacity: 0.8;
}

.hc-status.paid { color: #10b981; }

.loading-state-so {
  padding: 60px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: rgba(255,255,255,0.4);
}

.history-empty {
  padding: 60px;
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 16px;
  color: rgba(255,255,255,0.2);
}

.icon-xl { width: 48px; height: 48px; opacity: 0.1; }

</style>



