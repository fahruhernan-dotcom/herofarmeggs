<template>
  <div class="stock-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">B2B LOGISTICS</h4>
        <h1 class="hero-font">Inventory Control</h1>
        <p class="text-dim">Monitor and adjust the Hero Standard stock levels.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary" @click="showAdjustmentModal = true">
          <PlusIcon class="icon" />
          <span>NEW STOCK ENTRY</span>
        </button>
      </div>
    </header>

    <section class="inventory-section">
      <div class="section-badge">PRIMARY PRODUCTS</div>
      <div class="stock-grid">
        <div v-for="item in eggInventory" :key="item.id" class="stock-card glass-panel" :class="[item.id, { 'low-stock': item.current_stock <= 20 }]">
          <div class="card-bg-icon">
            <PackageIcon v-if="item.id === 'standard_size'" />
            <CookingPotIcon v-else-if="item.id === 'salted_egg'" />
            <ZapIcon v-else />
          </div>
          <div class="card-content">
            <div class="top">
              <span class="label">{{ item.label }}</span>
              <div v-if="item.current_stock <= 20" class="pulsing-badge critical">
                <AlertTriangleIcon class="icon-xs" />
                <span>RESTOCK REQ.</span>
              </div>
              <div v-else class="pulsing-badge safe">
                <div class="dot online"></div>
                <span>OPTIMAL</span>
              </div>
            </div>
            <div class="main">
              <h2 class="stock-value">
                <span class="v-num">{{ item.current_stock }}</span>
                <span class="v-unit">butir</span>
              </h2>
              <div class="price-info">
                <div class="retail-tag clickable" @click="openEditProduct(item)" title="Click to Change Price">
                  <span class="rt-label">Retail</span>
                  <span class="rt-val">Rp {{ item.base_price_per_pack.toLocaleString('id-ID') }}</span>
                </div>
                <div v-if="authStore.profile?.role === 'admin'" class="hpp-glass">
                  <LockIcon class="icon-xs" />
                  <div class="hpp-inner">
                    <span class="hpp-label">HPP Total</span>
                    <span class="hpp-val">Rp {{ (item.cost_price || 0).toLocaleString('id-ID') }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="card-footer-elite">
              <div class="mini-stat">
                <span class="ms-label">Safety Stock</span>
                <span class="ms-value">20</span>
              </div>
              <div class="card-actions">
                <button v-if="authStore.profile?.role === 'admin'" class="btn-icon-circle" @click="openEditProduct(item)" title="Edit Specs">
                  <Edit3Icon class="icon-sm" />
                </button>
                <button class="btn-tactical" @click="quickAdjust(item.id)">
                  <span>ADJUST STOCK</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="inventory-section">
      <div class="section-badge">SUPPLIES & PACKAGING</div>
      <div class="stock-grid">
        <div v-for="item in supplyInventory" :key="item.id" class="stock-card glass-panel supply-card" :class="{ 'low-stock': item.current_stock <= 20 }">
          <div class="card-bg-icon"><PackageIcon /></div>
          <div class="card-content">
            <div class="top">
              <span class="label">{{ item.label }}</span>
              <div v-if="item.current_stock <= 20" class="pulsing-badge critical small">
                <span>LOW</span>
              </div>
            </div>
            <div class="main">
              <h2 class="stock-value supply">
                <span class="v-num">{{ item.current_stock }}</span>
                <span class="v-unit">units</span>
              </h2>
              <div class="price-info">
                <div class="hpp-glass supply">
                  <TruckIcon class="icon-xs" />
                  <div class="hpp-inner">
                    <span class="hpp-label">Effective Cost</span>
                    <span class="hpp-val">Rp {{ (item.cost_per_egg || 0).toLocaleString('id-ID') }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="card-footer-elite">
              <div class="mini-stat">
                <span class="ms-label">Safety Stock</span>
                <span class="ms-value">20</span>
              </div>
              <div class="card-actions">
                <button v-if="authStore.profile?.role === 'admin'" class="btn-primary-tactical" @click="openPackagingPurchase(item)">
                  <PlusIcon class="icon-sm" />
                  <span>RESTOCK</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- RECENT TRANSACTIONS / LOGS -->
    <section class="logs-section glass-panel">
      <div class="section-header">
        <h3 class="hero-font">Audit Trail</h3>
        <span class="text-dim">Last 20 operations</span>
      </div>
      
      <div class="logs-table-wrapper">
        <table class="logs-table">
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Type</th>
              <th>Change</th>
              <th>Reason</th>
              <th>Admin</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="log in logs" :key="log.id" class="log-row">
              <td class="time">{{ formatTime(log.created_at) }}</td>
              <td>
                <span class="log-badge" :class="log.log_type">{{ log.log_type }}</span>
              </td>
              <td class="change" :class="log.change > 0 ? 'pos' : 'neg'">
                {{ log.change > 0 ? '+' : '' }}{{ log.change.toLocaleString('id-ID') }}
              </td>
              <td class="notes">
                <span class="note-text">{{ formatLogNotes(log.notes) }}</span>
              </td>
              <td class="admin">System Admin</td>
            </tr>
            <tr v-if="logs.length === 0">
              <td colspan="5" class="empty">No logs found. Start by adding stock.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- ADJUSTMENT MODAL -->
    <Teleport to="body">
      <div v-if="showAdjustmentModal" class="modal-overlay" @click.self="showAdjustmentModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Stock Adjustment</h2>
          <p class="text-dim">Record arrivals, sorted waste, or manual corrections.</p>

          <form @submit.prevent="submitAdjustment" class="modal-form">
            <div class="form-group">
              <CustomDropdown 
                v-model="form.egg_type" 
                :options="eggTypeOptions" 
                label="Egg Type" 
                placeholder="Select product..."
              />
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="form.log_type" 
                :options="operationTypeOptions" 
                label="Operation Type" 
                placeholder="Select operation..."
              />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Amount Recv/Change (Butir)</label>
                <input type="number" v-model.number="form.change" placeholder="e.g. 100" required />
              </div>
              <div v-if="form.log_type === 'arrival'" class="form-group">
                <label>Damaged / Broken</label>
                <input type="number" v-model.number="form.damaged" placeholder="e.g. 5" />
              </div>
            </div>

            <div v-if="form.log_type === 'arrival'" class="form-group price-arrival-group animate-slide">
              <label>Purchase Price (Per Butir)</label>
              <div class="price-input-wrapper">
                <span class="prefix">Rp</span>
                <input type="number" v-model.number="form.purchase_price" placeholder="e.g. 1500" />
              </div>
              <div v-if="suggestedPrices.length > 0" class="price-suggestions">
                <span class="s-hint">From {{ form.supplier }} catalog:</span>
                <div class="s-chips">
                  <button 
                    v-for="p in suggestedPrices" 
                    :key="p.item_name"
                    type="button"
                    class="price-chip"
                    @click="form.purchase_price = p.price"
                  >
                    {{ p.item_name }}: Rp {{ p.price }}
                  </button>
                </div>
              </div>
            </div>
            
            <div v-if="form.log_type === 'arrival' && form.damaged > 0" class="form-group info-box animate-slide">
              <label>Effective HPP per Butir</label>
              <div class="calc-result">
                Rp {{ calculateEffectiveEggCost().toLocaleString('id-ID') }}
              </div>
              <p class="text-dim mini-text">Formula: (Price × Total) ÷ (Total - Damaged)</p>
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="form.supplier" 
                :options="supplierOptions" 
                label="Supplier (Optional)" 
                placeholder="Select vendor..."
              />
            </div>

            <div class="form-group">
              <label>Notes</label>
              <textarea v-model="form.notes" placeholder="e.g. Batch from Blitar supplier"></textarea>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showAdjustmentModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'RECORDING...' : 'SAVE CHANGES' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- EDIT PRODUCT MODAL (HPP & PRICE) -->
    <Teleport to="body">
      <div v-if="showEditModal" class="modal-overlay" @click.self="showEditModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Edit Product Specs</h2>
          <p class="text-dim">Update prices and costs for {{ editForm.label }}.</p>

          <form @submit.prevent="saveProductEdit" class="modal-form">
            <div class="form-row">
              <div class="form-group">
                <label>HPP Telur (Per Butir)</label>
                <input type="number" v-model.number="editForm.cost_per_egg" placeholder="e.g. 1500" required />
              </div>
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Kemasan</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_packaging" readonly class="input-readonly" />
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Stiker</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_sticker" readonly class="input-readonly" />
              </div>
              <div class="form-group">
                <div class="label-with-badge">
                  <label>HPP Kartu</label>
                  <span class="badge-sync">AUTO-SYNC</span>
                </div>
                <input type="number" v-model.number="editForm.cost_per_card" readonly class="input-readonly" />
              </div>
            </div>

            <div class="form-group info-box">
              <label>Estimasi HPP Total (Per 10 Butir)</label>
              <div class="calc-result">
                Rp {{ ((editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card).toLocaleString() }}
              </div>
            </div>

            <div class="form-group">
              <label>Harga Jual / Retail (Per Pack)</label>
              <input type="number" v-model.number="editForm.base_price_per_pack" required />
            </div>

            <div class="form-group info-box mt-4">
              <label>Price Evolution History</label>
              <div v-if="loadingHistory" class="text-dim mini-text">Loading records...</div>
              <div v-else-if="priceHistory.length === 0" class="text-dim mini-text">No price changes recorded.</div>
              <div v-else class="history-mini-list">
                <div v-for="ph in priceHistory" :key="ph.id" class="ph-row">
                  <span class="ph-type" :class="ph.price_type">{{ ph.price_type.toUpperCase() }}</span>
                  <div class="ph-details">
                    <span class="ph-old">Rp {{ ph.old_price?.toLocaleString('id-ID') }}</span>
                    <span class="ph-arr">→</span>
                    <span class="ph-new">Rp {{ ph.new_price?.toLocaleString('id-ID') }}</span>
                  </div>
                  <span class="ph-date text-dim">{{ formatTime(ph.changed_at) }}</span>
                </div>
              </div>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showEditModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'SAVING...' : 'UPDATE SPECS' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- PACKAGING PURCHASE MODAL -->
    <Teleport to="body">
      <div v-if="showPackagingModal" class="modal-overlay" @click.self="showPackagingModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Restock Packaging</h2>
          <p class="text-dim">Calculate effective HPP including shipping and waste.</p>

          <form @submit.prevent="submitPackagingPurchase" class="modal-form">
            <div class="form-row">
              <div class="form-group">
                <label>Total Item Price</label>
                <input type="number" v-model.number="packForm.price" placeholder="e.g. 30000" required />
              </div>
              <div class="form-group">
                <label>Shipping Cost</label>
                <input type="number" v-model.number="packForm.shipping" placeholder="e.g. 5000" />
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label>Quantity Ordered</label>
                <input type="number" v-model.number="packForm.qty" placeholder="30" required />
              </div>
              <div class="form-group">
                <label>Quantity Damaged</label>
                <input type="number" v-model.number="packForm.damaged" placeholder="0" />
              </div>
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="packForm.supplier" 
                :options="supplierOptions" 
                label="Supplier (Optional)" 
                placeholder="Select vendor..."
              />
            </div>

            <div class="form-group info-box">
              <label>Effective HPP per Unit</label>
              <div class="calc-result">
                Rp {{ calculateEffectivePackCost().toLocaleString() }}
              </div>
              <p class="text-dim mini-text">Formula: (Price + Shipping) / (Total - Damaged)</p>
            </div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showPackagingModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'PROCESSING...' : 'CONFIRM PURCHASE' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive, computed, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { useRoute } from 'vue-router';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import { 
  PlusIcon, 
  PackageIcon, 
  ZapIcon, 
  CookingPotIcon, 
  Edit3Icon,
  AlertTriangleIcon,
  LockIcon,
  TruckIcon
} from 'lucide-vue-next';

const authStore = useAuthStore();

const inventory = ref<any[]>([]);
const logs = ref<any[]>([]);
const suppliers = ref<any[]>([]);
const showAdjustmentModal = ref(false);
const showEditModal = ref(false);
const showPackagingModal = ref(false);
const submitting = ref(false);

const priceHistory = ref<any[]>([]);
const loadingHistory = ref(false);

const eggInventory = computed(() => inventory.value.filter(i => i.item_type !== 'packaging'));
const supplyInventory = computed(() => inventory.value.filter(i => i.item_type === 'packaging'));

const eggTypeOptions = computed(() => inventory.value
  .filter(item => item.item_type === 'egg')
  .map(item => ({
    label: item.label,
    value: item.id
  }))
);

const supplierOptions = computed(() => suppliers.value.map(s => ({
  label: `${s.name} ${s.category ? `(${s.category})` : ''}`,
  value: s.name
})));

const suggestedPrices = computed(() => {
  if (!form.supplier || !form.egg_type) return [];
  const supplier = suppliers.value.find(s => s.name === form.supplier);
  if (!supplier || !Array.isArray(supplier.price_list)) return [];
  
  // Filter price list for items matching current egg type label keywords
  const eggLabel = inventory.value.find(i => i.id === form.egg_type)?.label.toLowerCase() || '';
  return supplier.price_list.filter((item: any) => 
    item.item_name.toLowerCase().includes(eggLabel.split(' ')[0]) || 
    eggLabel.includes(item.item_name.toLowerCase().split(' ')[0])
  );
});


const operationTypeOptions = [
  { label: 'Stock Arrival (+)', value: 'arrival' },
  { label: 'Sorting Waste (-)', value: 'sorting_waste' },
  { label: 'Manual Fix', value: 'manual_adjustment' }
];

const form = reactive({
  egg_type: 'hero_size',
  log_type: 'arrival',
  change: 0,
  damaged: 0,
  purchase_price: 0,
  supplier: '',
  notes: ''
});


const editForm = reactive({
  id: '',
  label: '',
  base_price_per_pack: 0,
  cost_per_egg: 0,
  cost_per_packaging: 0,
  cost_per_sticker: 0,
  cost_per_card: 0,
  old_base_price: 0,
  old_cost_price: 0
});

const packForm = reactive({
  id: '',
  label: '',
  price: 0,
  shipping: 0,
  qty: 0,
  damaged: 0,
  supplier: ''
});

async function fetchData() {
  const { data: inv } = await supabase.from('inventory').select('*');
  if (inv) inventory.value = inv;

  const { data: logData } = await supabase
    .from('stock_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(20);
  if (logData) logs.value = logData;

  const { data: sup } = await supabase.from('suppliers').select('*').order('name');
  if (sup) suppliers.value = sup;
}


function formatTime(date: string) {
  return new Date(date).toLocaleString('id-ID', { 
    day: '2-digit', 
    month: 'short', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
} // Added closing brace for formatTime

function formatLogNotes(notes: string) {
  if (!notes) return '-';
  // If note contains a UUID (sale #), slice it for cleaner UI
  return notes.replace(/#([a-f0-9-]{36})/, (_, id) => `#${id.slice(-8).toUpperCase()}`);
}

function quickAdjust(type: string) {
    form.egg_type = type;
    showAdjustmentModal.value = true;
}

function openEditProduct(item: any) {
  // Always fetch latest supply costs from supplyInventory to ensure sync
  const latestPackaging = supplyInventory.value.find(s => s.id === 'packaging_standard')?.cost_per_egg || 0;
  const latestSticker = supplyInventory.value.find(s => s.id === 'sticker_label')?.cost_per_egg || 0;
  const latestCard = supplyInventory.value.find(s => s.id === 'mini_card')?.cost_per_egg || 0;

  editForm.id = item.id;
  editForm.label = item.label;
  editForm.base_price_per_pack = item.base_price_per_pack;
  editForm.old_base_price = item.base_price_per_pack;
  editForm.old_cost_price = item.cost_price || 0;
  editForm.cost_per_egg = item.cost_per_egg || 0;
  
  // Use either the item's stored value or the latest from global supply list
  editForm.cost_per_packaging = latestPackaging || item.cost_per_packaging || 0;
  editForm.cost_per_sticker = latestSticker || item.cost_per_sticker || 0;
  editForm.cost_per_card = latestCard || item.cost_per_card || 0;
  
  showEditModal.value = true;
  
  // Fetch price history
  loadingHistory.value = true;
  priceHistory.value = [];
  supabase
    .from('price_history')
    .select('*')
    .eq('product_id', item.id)
    .order('changed_at', { ascending: false })
    .limit(5)
    .then(({ data }) => {
      if (data) priceHistory.value = data;
      loadingHistory.value = false;
    });
}

async function saveProductEdit() {
  submitting.value = true;
  const newCostPrice = (editForm.cost_per_egg * 10) + editForm.cost_per_packaging + editForm.cost_per_sticker + editForm.cost_per_card;

  const { error } = await supabase
    .from('inventory')
    .update({
      base_price_per_pack: editForm.base_price_per_pack,
      cost_per_egg: editForm.cost_per_egg,
      cost_per_packaging: editForm.cost_per_packaging,
      cost_per_sticker: editForm.cost_per_sticker,
      cost_per_card: editForm.cost_per_card,
      cost_price: newCostPrice,
      updated_at: new Date().toISOString()
    })
    .eq('id', editForm.id);

  if (!error) {
    // Audit Price Changes
    const authorName = authStore.profile?.full_name || 'Admin';
    if (editForm.base_price_per_pack !== editForm.old_base_price) {
      await supabase.from('price_history').insert({
        product_id: editForm.id,
        price_type: 'selling',
        old_price: editForm.old_base_price,
        new_price: editForm.base_price_per_pack,
        changed_by: authorName
      });
    }

    if (newCostPrice !== editForm.old_cost_price) {
      await supabase.from('price_history').insert({
        product_id: editForm.id,
        price_type: 'hpp',
        old_price: editForm.old_cost_price,
        new_price: newCostPrice,
        changed_by: authorName
      });
    }

    showEditModal.value = false;
    fetchData();
  } else {
    console.error('Update Error:', error);
    alert('Gagal Simpan! Pastikan Anda sudah menjalankan SQL ALTER TABLE di Supabase. Detail: ' + error.message);
  }
  submitting.value = false;
}

function openPackagingPurchase(item: any) {
  packForm.id = item.id;
  packForm.label = item.label;
  packForm.price = 0;
  packForm.shipping = 0;
  packForm.qty = 0;
  packForm.damaged = 0;
  packForm.supplier = '';
  showPackagingModal.value = true;
}

function calculateEffectivePackCost() {
  const totalCost = packForm.price + packForm.shipping;
  const goodQty = packForm.qty - packForm.damaged;
  if (goodQty <= 0) return 0;
  return Math.round(totalCost / goodQty);
}

async function submitPackagingPurchase() {
  submitting.value = true;
  const effectiveCost = calculateEffectivePackCost();
  const goodQty = packForm.qty - packForm.damaged;

  try {
    // 1. Update Packaging Inventory
    const currentItem = inventory.value.find(i => i.id === packForm.id);
    const newStock = (currentItem?.current_stock ?? 0) + goodQty;

    const { error: invError } = await supabase.from('inventory')
      .update({ 
        current_stock: newStock, 
        cost_per_egg: effectiveCost, // We use this field to store unit cost for supplies
        updated_at: new Date().toISOString() 
      })
      .eq('id', packForm.id);

    if (invError) throw invError;

    // 2. Log Transaction
    const purchaseNotes = `Purchase: Rp${packForm.price.toLocaleString('id-ID')} + Rp${packForm.shipping.toLocaleString('id-ID')} ship (Waste: ${packForm.damaged})`;
    const supplierNote = packForm.supplier ? ` | Supplier: ${packForm.supplier}` : '';

    await supabase.from('stock_logs').insert({
      egg_type: packForm.id,
      change: goodQty,
      log_type: 'arrival',
      notes: purchaseNotes + supplierNote
    });

    // 3. Proactive: Update Egg products HPP based on supply type
    if (packForm.id === 'packaging_standard') {
      await supabase.from('inventory').update({ cost_per_packaging: effectiveCost }).eq('item_type', 'egg');
    } else if (packForm.id === 'sticker_label') {
      await supabase.from('inventory').update({ cost_per_sticker: effectiveCost }).eq('item_type', 'egg');
    } else if (packForm.id === 'mini_card') {
      await supabase.from('inventory').update({ cost_per_card: effectiveCost }).eq('item_type', 'egg');
    }
    
    // Recalculate total cost_price for all eggs
    const { data: eggs } = await supabase.from('inventory').select('*').eq('item_type', 'egg');
    if (eggs) {
      for (const egg of eggs) {
        const totalHpp = (egg.cost_per_egg * 10) + (egg.cost_per_packaging || 0) + (egg.cost_per_sticker || 0) + (egg.cost_per_card || 0);
        await supabase.from('inventory').update({ cost_price: totalHpp }).eq('id', egg.id);
      }
    }

    showPackagingModal.value = false;
    fetchData();
    alert(`Success! Updated ${packForm.label} cost and recalculated all product HPPs.`);
  } catch (err: any) {
    alert('Error: ' + err.message);
  } finally {
    submitting.value = false;
  }
}

function calculateEffectiveEggCost() {
  if (form.log_type !== 'arrival') return 0;
  const totalCost = form.change * form.purchase_price;
  const goodQty = form.change - (form.damaged || 0);
  if (goodQty <= 0) return 0;
  return Math.round(totalCost / goodQty);
}

async function submitAdjustment() {
  submitting.value = true;
  
  // 1. Determine direction
  let finalChange = form.change;
  let effectiveEggCost = form.purchase_price;
  let wasteAmount = form.damaged || 0;

  if (form.log_type === 'arrival') {
    if (wasteAmount > 0) {
      finalChange = form.change - wasteAmount; // actual good eggs added to inventory
      effectiveEggCost = calculateEffectiveEggCost(); // new HPP
    }
  } else if (form.log_type === 'sorting_waste' && finalChange > 0) {
    finalChange = -finalChange;
  }

  // 2. Insert Log
  const initialNotes = form.supplier ? `[${form.supplier}] ${form.notes}` : form.notes;
  let finalNotes = initialNotes;
  
  if (form.log_type === 'arrival' && wasteAmount > 0) {
    finalNotes = `${initialNotes} (Waste: ${wasteAmount} butir)`.trim();
  }

  const { error: logError } = await supabase.from('stock_logs').insert({
    egg_type: form.egg_type,
    change: finalChange,
    log_type: form.log_type,
    unit_price: form.log_type === 'arrival' ? effectiveEggCost : 0,
    notes: finalNotes
  });


  if (!logError) {
    // 3. Update Inventory (Atomic increment in real DB is better, but this works for internal use)
    const currentItem = inventory.value.find(i => i.id === form.egg_type);
    const newStock = (currentItem?.current_stock ?? 0) + finalChange;
    
    const updatePayload: any = { 
      current_stock: newStock, 
      updated_at: new Date().toISOString() 
    };

    // If arrival with price, update cost_per_egg and recalculate HPP
    if (form.log_type === 'arrival' && form.purchase_price > 0 && currentItem) {
      updatePayload.cost_per_egg = effectiveEggCost;
      // Recalculate total cost_price
      updatePayload.cost_price = (effectiveEggCost * 10) + 
        (currentItem.cost_per_packaging || 0) + 
        (currentItem.cost_per_sticker || 0) + 
        (currentItem.cost_per_card || 0);
    }

    await supabase.from('inventory')
      .update(updatePayload)
      .eq('id', form.egg_type);


    showAdjustmentModal.value = false;
    form.change = 0;
    form.damaged = 0;
    form.purchase_price = 0;
    form.supplier = '';
    form.notes = '';
    fetchData();
  }


  submitting.value = false;
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

// Force refresh data on route change
watch(() => route.path, () => {
  fetchData();
});
</script>

<style scoped>
.stock-page {
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

.label-with-badge {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.badge-sync {
  font-size: 0.6rem;
  background: var(--color-success);
  color: black;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 800;
  letter-spacing: 0.05em;
}

.input-readonly {
  background: rgba(255, 255, 255, 0.02) !important;
  color: var(--color-text-dim) !important;
  cursor: not-allowed;
  border-style: dashed !important;
}

.inventory-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-badge {
  font-family: var(--font-headline);
  font-size: 0.7rem;
  font-weight: 800;
  color: var(--color-primary);
  letter-spacing: 0.15em;
  background: rgba(255, 140, 0, 0.1);
  padding: 4px 12px;
  border-radius: 20px;
  width: fit-content;
  border: 1px solid rgba(255, 140, 0, 0.2);
}

.mini-text {
  font-size: 0.7rem;
  margin-top: 8px;
}

.btn-primary-lite {
  background: var(--color-primary);
  color: white;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  border: none;
  transition: var(--transition-smooth);
}

.btn-primary-lite:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-glow);
}

.supply-card .stock-value {
  color: var(--color-success);
}

.stock-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 24px;
}

.stock-card {
  min-height: 320px;
  padding: 0;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

.stock-card:hover {
  transform: translateY(-8px);
  border-color: rgba(255, 140, 0, 0.3);
  box-shadow: 0 15px 40px rgba(0,0,0,0.4);
}

.stock-card.low-stock {
  border-color: rgba(255, 66, 66, 0.2);
}

.card-bg-icon {
  position: absolute;
  right: -20px;
  top: -20px;
  opacity: 0.03;
  color: white;
  z-index: 1;
}

.card-bg-icon svg {
  width: 180px;
  height: 180px;
}

.card-content {
  position: relative;
  z-index: 2;
  padding: 32px;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.label {
  text-transform: uppercase;
  font-weight: 900;
  letter-spacing: 0.15em;
  font-size: 0.7rem;
  color: var(--color-text-dim);
}

.pulsing-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.6rem;
  font-weight: 800;
  letter-spacing: 0.05em;
}

.pulsing-badge.critical {
  background: rgba(255, 66, 66, 0.1);
  color: #ff4242;
  animation: pulse-red 2s infinite;
}

.pulsing-badge.safe {
  background: rgba(0, 255, 157, 0.05);
  color: var(--color-success);
}

.pulsing-badge.safe .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--color-success);
  box-shadow: 0 0 8px var(--color-success);
}

.main {
  margin: 20px 0;
}

.stock-value {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 16px;
}

.v-num {
  font-size: 4rem;
  font-weight: 900;
  line-height: 1;
  color: white;
  letter-spacing: -2px;
}

.v-unit {
  font-size: 1rem;
  color: var(--color-text-dim);
  font-weight: 600;
}

.stock-value.supply .v-num { color: var(--color-success); }

.price-info {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.retail-tag {
  display: flex;
  flex-direction: column;
}

.rt-label { font-size: 0.6rem; text-transform: uppercase; color: var(--color-primary); font-weight: 800; }
.rt-val { font-size: 1.1rem; font-weight: 850; color: white; }

.hpp-glass {
  padding: 10px 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  backdrop-filter: blur(5px);
}

.hpp-glass svg { opacity: 0.3; }

.hpp-inner { display: flex; flex-direction: column; }
.hpp-label { font-size: 0.55rem; text-transform: uppercase; color: var(--color-text-dim); font-weight: 800; }
.hpp-val { font-size: 0.85rem; font-weight: 800; color: white; }

.hpp-glass.supply .hpp-val { color: var(--color-primary); }

.card-footer-elite {
  margin-top: auto;
  padding-top: 20px;
  border-top: 1px solid var(--glass-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.mini-stat { display: flex; flex-direction: column; }
.ms-label { font-size: 0.6rem; color: var(--color-text-dim); text-transform: uppercase; }
.ms-value { font-weight: 800; font-size: 0.9rem; color: white; }

.card-actions { display: flex; display: flex; gap: 12px; }

.btn-icon-circle {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  color: var(--color-text-dim);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-icon-circle:hover {
  background: white;
  color: black;
  transform: rotate(15deg);
}

.btn-tactical {
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 10px 18px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.75rem;
  letter-spacing: 0.05em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-tactical:hover {
  transform: scale(1.05);
  box-shadow: 0 0 20px rgba(255, 140, 0, 0.3);
}

.btn-primary-tactical {
  background: var(--color-success);
  color: black;
  border: none;
  padding: 10px 18px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary-tactical:hover {
  transform: scale(1.05);
  box-shadow: 0 0 20px rgba(0, 255, 157, 0.3);
}

@keyframes pulse-red {
  0% { box-shadow: 0 0 0 0 rgba(255, 66, 66, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(255, 66, 66, 0); }
  100% { box-shadow: 0 0 0 0 rgba(255, 66, 66, 0); }
}

.btn-lite {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-lite:hover { background: rgba(255, 255, 255, 0.1); }

/* LOGS TABLE */
.retail-tag.clickable {
  cursor: pointer;
  background: rgba(255, 140, 0, 0.1);
  border: 1px dashed rgba(255, 140, 0, 0.3);
  transition: all 0.3s ease;
}

.retail-tag.clickable:hover {
  background: var(--color-primary);
  color: black;
  transform: scale(1.05);
  border-style: solid;
}

/* Price Arrival Group */
.price-arrival-group {
  margin-top: 8px;
  padding: 16px;
  background: rgba(255, 140, 0, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 140, 0, 0.1);
}

.price-input-wrapper {
  display: flex;
  align-items: center;
  background: rgba(0, 0, 0, 0.2);
  border: 1px solid var(--glass-border);
  border-radius: 8px;
  padding: 0 12px;
}

.price-input-wrapper .prefix {
  font-weight: 800;
  color: var(--color-primary);
  margin-right: 8px;
}

.price-input-wrapper input {
  border: none !important;
  background: transparent !important;
  padding: 12px 0 !important;
}

.price-suggestions {
  margin-top: 12px;
}

.s-hint {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--color-text-dim);
  display: block;
  margin-bottom: 8px;
}

.s-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.price-chip {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.price-chip:hover {
  background: var(--color-primary);
  color: black;
  border-color: var(--color-primary);
}

.animate-slide {
  animation: slideDown 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.logs-section {

  padding: 32px;
}

.section-header { margin-bottom: 24px; }

.logs-table-wrapper {
  overflow-x: auto;
}

.logs-table {
  width: 100%;
  border-collapse: collapse;
}

.logs-table th {
  text-align: left;
  padding: 12px 16px;
  color: var(--color-text-dim);
  font-size: 0.75rem;
  text-transform: uppercase;
  border-bottom: 1px solid var(--glass-border);
}

.logs-table td {
  padding: 16px;
  font-size: 0.9rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.log-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
}

.log-badge.arrival { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.log-badge.sorting_waste { background: rgba(255, 62, 62, 0.1); color: var(--color-error); }
.log-badge.manual_adjustment { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }

.change { font-weight: 800; }
.change.pos { color: var(--color-success); }
.change.neg { color: var(--color-error); }

.note-text {
  color: white;
  font-weight: 500;
}

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
  align-items: flex-start;
  padding: 40px 20px;
  overflow-y: auto;
  z-index: 1000;
}

.modal-card {
  width: 100%;
  max-width: 500px;
  padding: 40px;
  margin: auto;
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

.history-mini-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 8px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 8px;
  padding: 8px;
}

.ph-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 8px;
  border-bottom: 1px dashed var(--glass-border);
  font-size: 0.75rem;
}

.ph-row:last-child {
  border-bottom: none;
}

.ph-type {
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.6rem;
}

.ph-type.selling { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.ph-type.hpp { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }

.ph-details {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ph-old { text-decoration: line-through; color: var(--color-error); }
.ph-arr { color: var(--color-text-dim); }
.ph-new { color: white; font-weight: 700; }
.ph-date { font-size: 0.6rem; }


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

.form-row {
  display: flex;
  gap: 16px;
}

.form-row .form-group {
  flex: 1;
}

.info-box {
  background: rgba(255, 140, 0, 0.05);
  border: 1px solid rgba(255, 140, 0, 0.15);
  padding: 16px;
  border-radius: var(--radius-md);
}

.calc-result {
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--color-primary);
  margin-top: 4px;
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
