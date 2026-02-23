<template>
  <div class="sales-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">REVENUE TERMINAL</h4>
        <h1 class="hero-font">New Order Entry</h1>
        <p class="text-dim">Record outbound batches and manage customer invoices.</p>
      </div>
      <div class="status-hub">
        <div class="status-pill glass-panel">
          <span class="dot" :class="heroStock < 20 ? 'critical' : 'online'"></span>
          HERO: {{ heroStock }}
        </div>
        <div class="status-pill glass-panel">
          <span class="dot" :class="standardStock < 20 ? 'critical' : 'online'"></span>
          STD: {{ standardStock }}
        </div>
        <div class="status-pill glass-panel">
          <span class="dot" :class="saltedStock < 20 ? 'critical' : 'online'"></span>
          ASIN: {{ saltedStock }}
        </div>
      </div>
    </header>

    <div class="sales-grid">
      <!-- LEFT: SELECTION & FORM -->
      <section class="form-area glass-panel">
        <h3 class="panel-title">Transaction Details</h3>
        
        <form @submit.prevent="handlePreview" class="pos-form">
          <div class="form-group customer-search-group">
            <div class="field-row">
              <div class="field-col">
                <label>Customer Name</label>
                <div class="search-input-wrapper" v-outside-click="() => showCustResults = false">
                  <input 
                    type="text" 
                    v-model="customerSearch" 
                    placeholder="Type name..." 
                    class="premium-input"
                    @focus="showCustResults = true"
                    required
                  />
                  <Transition name="fade">
                    <div v-if="showCustResults && filteredCustomers.length > 0" class="search-results-menu glass-panel">
                      <div 
                        v-for="c in filteredCustomers" 
                        :key="c.id" 
                        class="result-item"
                        @click="selectExistingCustomer(c)"
                      >
                        <div class="result-info">
                          <span class="r-name">{{ c.name }}</span>
                          <span class="r-phone">{{ c.whatsapp_number || '-' }}</span>
                        </div>
                      </div>
                    </div>
                  </Transition>
                </div>
              </div>
              <div class="field-col phone-col">
                <label>WA Number (Optional)</label>
                <input 
                  type="text" 
                  v-model="customerPhone" 
                  placeholder="0812..." 
                  class="premium-input"
                />
              </div>
            </div>
            <p v-if="customerSearch && !selectedCustomerId" class="hint-text">
              <SparklesIcon class="icon-xs" /> New customer: <strong>{{ customerSearch }}</strong> (System will auto-register)
            </p>
            <p v-else-if="selectedCustomerId" class="hint-text text-success">
              <CheckCircleIcon class="icon-xs" /> Registered customer selected.
            </p>
          </div>

          <div class="items-selection">
            <label class="section-label">Package Selection</label>
            <div class="pkg-grid">
              <div 
                v-for="item in sellableProducts" 
                :key="item.id" 
                class="pkg-card" 
                :class="{ active: selectedEggType === item.id, 'out-of-stock': item.current_stock <= 0 }"
                @click="selectedEggType = item.id"
              >
                <div class="pkg-card-glow"></div>
                <div class="pkg-info">
                  <span class="p-label">{{ item.label }}</span>
                  <span class="p-stock" :class="{ critical: item.current_stock < 20 }">
                    {{ item.current_stock }} butir left
                  </span>
                </div>
                <div class="p-price-tag">
                  <span class="currency">Rp</span>
                  <span class="amount">{{ item.base_price_per_pack.toLocaleString('id-ID') }}</span>
                </div>
                <div class="pkg-icon-wrapper">
                  <PackageIcon v-if="item.id === 'standard_size'" />
                  <CookingPotIcon v-else-if="item.id === 'salted_egg'" />
                  <ZapIcon v-else />
                </div>
              </div>
            </div>
          </div>

          <div class="order-config-box animate-slide-up" v-if="selectedEggType">
            <div class="config-row">
              <div class="qty-control-group">
                <label>Quantity (Packs)</label>
                <div class="qty-controller glass-panel">
                  <button type="button" class="qty-btn" @click="form.quantity > 1 ? form.quantity-- : null" :disabled="form.quantity <= 1">
                    <MinusIcon class="icon-sm" />
                  </button>
                  <input 
                    type="number" 
                    v-model.number="form.quantity" 
                    min="1" 
                    :max="maxPacks"
                    class="qty-display"
                  />
                  <button type="button" class="qty-btn" @click="form.quantity < maxPacks ? form.quantity++ : null">
                    <PlusIcon class="icon-sm" />
                  </button>
                </div>
              </div>

              <div class="total-display-group">
                <label>Line Total</label>
                <div class="current-total-glow">
                  <span class="currency">Rp</span>
                  <span class="amount">{{ currentTotal.toLocaleString('id-ID') }}</span>
                </div>
              </div>
            </div>

            <Transition name="fade">
              <div v-if="maxStock <= 0 || form.quantity > maxPacks" class="premium-warning glass-panel">
                <AlertCircleIcon class="warn-icon" /> 
                <div class="warn-content">
                  <p class="warn-title">Insufficient Stock</p>
                  <p class="warn-desc">Available: {{ maxStock }} butir ({{ maxPacks }} packs)</p>
                </div>
              </div>
            </Transition>

            <button type="submit" class="btn-primary-glow w-full mt-4" :disabled="!isFormValid || maxStock <= 0">
              <ZapIcon class="icon" />
              <span>GENERATE PREVIEW</span>
            </button>
          </div>
        </form>
      </section>

      <!-- RIGHT: INVOICE PREVIEW -->
      <section class="preview-area glass-panel">
        <div class="invoice-container" v-if="showPreview">
          <div class="invoice-header">
            <div class="inv-brand">
              <span class="hero-font">HERO FARM</span>
              <span class="inv-tag">OFFICIAL INVOICE</span>
            </div>
            <div class="inv-meta">
              <p>NO: #INV-{{ Date.now().toString().slice(-6) }}</p>
              <p>DATE: {{ new Date().toLocaleDateString() }}</p>
            </div>
          </div>
          
          <div class="inv-body">
            <div class="inv-target">
              <label>BILL TO:</label>
              <p class="target-name">{{ selectedCustomerName }}</p>
            </div>

            <table class="inv-table">
              <thead>
                <tr>
                  <th>Item Description</th>
                  <th>Qty</th>
                  <th>Price</th>
                  <th>Total</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{{ selectedEggLabel }}</td>
                  <td>{{ form.quantity }} Pack ({{ form.quantity * 10 }} Butir)</td>
                  <td>{{ currentPrice.toLocaleString('id-ID') }}</td>
                  <td>{{ currentTotal.toLocaleString('id-ID') }}</td>
                </tr>
              </tbody>
            </table>

            <div class="inv-footer">
              <div class="total-row">
                <span class="total-label">Grand Total</span>
                <span class="total-value">Rp {{ currentTotal.toLocaleString('id-ID') }}</span>
              </div>
            </div>
          </div>

          <div class="inv-actions">
            <button class="btn-secondary" @click="showPreview = false">Cancel</button>
            <button class="btn-primary" @click="confirmSale" :disabled="loading">
              {{ loading ? 'PROCESSING...' : 'CONFIRM & PRINT' }}
            </button>
          </div>
        </div>

        <div class="empty-preview" v-else>
          <div class="illustration">
            <FileTextIcon />
          </div>
          <h3>Awaiting Input</h3>
          <p>Fill in the details to generate a premium invoice preview.</p>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  PackageIcon, 
  ZapIcon, 
  FileTextIcon, 
  CookingPotIcon, 
  SparklesIcon, 
  CheckCircleIcon,
  AlertCircleIcon,
  PlusIcon,
  MinusIcon
} from 'lucide-vue-next';

// 1. STATE
const inventory = ref<any[]>([]);
const customers = ref<any[]>([]);
const selectedEggType = ref('hero_size');
const showPreview = ref(false);
const loading = ref(false);

const customerSearch = ref('');
const customerPhone = ref('');
const showCustResults = ref(false);
const selectedCustomerId = ref<string | null>(null);

const form = reactive({
  quantity: 1,
});

// 2. FETCHING
async function fetchData() {
  const { data: inv } = await supabase.from('inventory').select('*');
  if (inv) inventory.value = inv;

  const { data: cust } = await supabase.from('customers').select('*').order('name');
  if (cust) customers.value = cust;
}

// 3. COMPUTED
const heroStock = computed(() => inventory.value.find(i => i.id === 'hero_size')?.current_stock ?? 0);
const standardStock = computed(() => inventory.value.find(i => i.id === 'standard_size')?.current_stock ?? 0);
const saltedStock = computed(() => inventory.value.find(i => i.id === 'salted_egg')?.current_stock ?? 0);

const filteredCustomers = computed(() => {
  if (!customerSearch.value) return [];
  const q = customerSearch.value.toLowerCase();
  return customers.value.filter(c => c.name.toLowerCase().includes(q));
});

const selectedCustomerName = computed(() => {
  return customerSearch.value || 'Guest Customer';
});

const selectedEggLabel = computed(() => {
  return inventory.value.find(i => i.id === selectedEggType.value)?.label || 'Eggs';
});

const maxStock = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.current_stock ?? 0);
const maxPacks = computed(() => Math.floor(maxStock.value / 10));

const currentPrice = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.base_price_per_pack ?? 0);
const currentTotal = computed(() => form.quantity * currentPrice.value);
const sellableProducts = computed(() => inventory.value.filter(i => i.item_type !== 'packaging'));
const isFormValid = computed(() => form.quantity > 0 && form.quantity <= maxPacks.value && customerSearch.value.trim().length > 0);

// 4. METHODS
function selectExistingCustomer(customer: any) {
  customerSearch.value = customer.name;
  customerPhone.value = customer.whatsapp_number || '';
  selectedCustomerId.value = customer.id;
  showCustResults.value = false;
}

function handlePreview() {
  showPreview.value = true;
}

async function confirmSale() {
  loading.value = true;
  
  try {
    let finalCustomerId = selectedCustomerId.value;

    // A. Auto-Register if it's a new name (and doesn't match an existing one exactly)
    if (!finalCustomerId && customerSearch.value) {
      // Final check if name exists but wasn't selected
      const existing = customers.value.find(c => c.name.toLowerCase() === customerSearch.value.toLowerCase());
      if (existing) {
        finalCustomerId = existing.id;
      } else {
        const { data: newCust, error: custError } = await supabase
          .from('customers')
          .insert([{ name: customerSearch.value, whatsapp_number: customerPhone.value }])
          .select()
          .single();
        
        if (custError) throw custError;
        finalCustomerId = newCust.id;
      }
    }

    // B. Create Sale Record
    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert({
        customer_id: finalCustomerId,
        total_price: currentTotal.value,
        payment_status: 'paid'
      })
      .select()
      .single();

    if (saleError) throw saleError;

    // C. Create Sale Item
    await supabase.from('sale_items').insert({
      sale_id: sale.id,
      egg_type: selectedEggType.value,
      quantity: form.quantity,
      unit_price: currentPrice.value,
      subtotal: currentTotal.value
    });

    // D. Update Inventory & Log
    const quantityInButir = form.quantity * 10;
    const newEggStock = maxStock.value - quantityInButir;
    
    // 1. Update Egg Stock
    await supabase.from('inventory').update({ current_stock: newEggStock }).eq('id', selectedEggType.value);
    await supabase.from('stock_logs').insert({
      egg_type: selectedEggType.value,
      change: -quantityInButir,
      log_type: 'sale',
      notes: `Sale to ${selectedCustomerName.value} (${form.quantity} Pack) (#${sale.id})`
    });

    // 2. Update Packaging Materials Stock (Deduct 1 per Pack)
    const supplies = ['packaging_standard', 'sticker_label', 'mini_card'];
    for (const supplyId of supplies) {
      const currentSupply = inventory.value.find(i => i.id === supplyId);
      if (currentSupply) {
        const newSupplyStock = Math.max(0, currentSupply.current_stock - form.quantity);
        await supabase.from('inventory').update({ current_stock: newSupplyStock }).eq('id', supplyId);
        
        await supabase.from('stock_logs').insert({
          egg_type: supplyId,
          change: -form.quantity,
          log_type: 'sale',
          notes: `Auto-deduct for Sale #${sale.id} (${form.quantity} units)`
        });
      }
    }

    alert('Transaction Successful!');
    showPreview.value = false;
    form.quantity = 1;
    customerSearch.value = '';
    customerPhone.value = '';
    selectedCustomerId.value = null;
    fetchData();
  } catch (e: any) {
    alert('Error: ' + e.message);
  } finally {
    loading.value = false;
  }
}

// Custom directive for clicking outside
const vOutsideClick = {
  mounted(el: any, binding: any) {
    el.clickOutsideEvent = (event: Event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value();
      }
    };
    document.addEventListener('click', el.clickOutsideEvent);
  },
  unmounted(el: any) {
    document.removeEventListener('click', el.clickOutsideEvent);
  },
};

onMounted(fetchData);
</script>

<style scoped>
.sales-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-hub {
  display: flex;
  gap: 12px;
}

.status-pill {
  padding: 8px 16px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85rem;
  font-weight: 700;
}

.dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.dot.online { background: var(--color-success); box-shadow: 0 0 10px var(--color-success); }
.dot.critical { background: var(--color-error); box-shadow: 0 0 10px var(--color-error); }

.sales-grid {
  display: grid;
  grid-template-columns: 1fr 1.2fr;
  gap: 24px;
}

.panel-title {
  margin-bottom: 24px;
  font-size: 1rem;
  letter-spacing: 0.05em;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.form-area {
  padding: 32px;
}

.pos-form {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.customer-search-group {
  position: relative;
}

.field-row {
  display: flex;
  gap: 16px;
}

.field-col {
  flex: 1;
}

.phone-col {
  max-width: 180px;
}

.search-input-wrapper {
  position: relative;
}

.search-results-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  z-index: 100;
  max-height: 200px;
  overflow-y: auto;
  background: rgba(10, 10, 10, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid var(--glass-border);
  padding: 8px;
  border-radius: var(--radius-md);
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
}

.result-item {
  padding: 12px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-smooth);
}

.result-item:hover {
  background: rgba(255, 255, 255, 0.05);
}

.r-name { display: block; font-weight: 700; color: white; }
.r-phone { font-size: 0.75rem; color: var(--color-text-dim); }

.hint-text {
  margin-top: 8px;
  font-size: 0.75rem;
  color: var(--color-text-dim);
  display: flex;
  align-items: center;
  gap: 6px;
}

.text-success { color: var(--color-success); }

.premium-input {
  width: 100%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  padding: 14px 20px;
  border-radius: var(--radius-md);
  color: white;
  font-family: var(--font-body);
}

.section-label {
  font-size: 0.75rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  display: block;
  margin-bottom: 12px;
}

.pkg-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.pkg-card {
  padding: 24px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: 20px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

.pkg-card-glow {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at 50% 0%, rgba(255, 140, 0, 0.1), transparent 70%);
  opacity: 0;
  transition: opacity 0.4s ease;
}

.pkg-card:hover { 
  background: rgba(255, 255, 255, 0.05);
  transform: translateY(-4px);
  border-color: rgba(255, 140, 0, 0.3);
}

.pkg-card:hover .pkg-card-glow { opacity: 1; }

.pkg-card.active {
  border-color: var(--color-primary);
  background: rgba(255, 140, 0, 0.08);
  box-shadow: 0 10px 30px rgba(255, 140, 0, 0.15);
}

.pkg-card.active .pkg-card-glow { opacity: 1; }

.pkg-card.out-of-stock {
  border-color: rgba(255, 62, 62, 0.2);
  opacity: 0.6;
}

.pkg-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  position: relative;
  z-index: 1;
}

.p-label { font-weight: 800; font-size: 1rem; color: white; }
.p-stock { font-size: 0.75rem; color: var(--color-success); font-weight: 700; }
.p-stock.critical { color: #FF3E3E; }

.p-price-tag {
  margin-top: 16px;
  display: flex;
  align-items: baseline;
  gap: 4px;
  position: relative;
  z-index: 1;
}

.p-price-tag .currency { font-size: 0.75rem; font-weight: 800; color: var(--color-primary); }
.p-price-tag .amount { font-size: 1.4rem; font-weight: 900; color: white; }

.pkg-icon-wrapper {
  position: absolute;
  right: 20px;
  bottom: 20px;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
  color: var(--color-primary);
  opacity: 0.5;
}

/* ORDER CONFIG BOX */
.order-config-box {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 20px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.config-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  align-items: flex-end;
}

.qty-control-group label, .total-display-group label {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  margin-bottom: 8px;
  display: block;
}

.qty-controller {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px;
  border-radius: 15px;
  background: rgba(255, 255, 255, 0.02);
}

.qty-btn {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.qty-btn:hover:not(:disabled) {
  background: var(--color-primary);
  border-color: var(--color-primary);
}

.qty-btn:disabled { opacity: 0.2; cursor: not-allowed; }

.qty-display {
  background: transparent;
  border: none;
  width: 50px;
  text-align: center;
  color: white;
  font-size: 1.2rem;
  font-weight: 800;
  outline: none;
}

.qty-display::-webkit-inner-spin-button { -webkit-appearance: none; }

.current-total-glow {
  text-align: right;
  display: flex;
  align-items: baseline;
  justify-content: flex-end;
  gap: 4px;
}

.current-total-glow .currency { font-size: 0.85rem; font-weight: 700; color: var(--color-primary); }
.current-total-glow .amount { font-size: 2rem; font-weight: 950; color: white; line-height: 1; }

/* PREMIUM WARNING */
.premium-warning {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  border-color: rgba(255, 66, 66, 0.3);
  background: rgba(255, 66, 66, 0.05);
  border-radius: 15px;
}

.warn-icon { color: #FF3E3E; width: 24px; height: 24px; }
.warn-title { font-weight: 800; color: #FF3E3E; font-size: 0.8rem; text-transform: uppercase; }
.warn-desc { font-size: 0.7rem; color: var(--color-text-dim); }

.mt-4 { margin-top: 16px; }

.animate-slide-up { animation: slideUp 0.4s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* INVOICE PREVIEW */
.preview-area {
  padding: 48px;
  display: flex;
  flex-direction: column;
}

.invoice-container {
  animation: slideInUp 0.6s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes slideInUp {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

.invoice-header {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px solid var(--glass-border);
  padding-bottom: 24px;
}

.inv-brand { display: flex; flex-direction: column; }
.inv-brand span:first-child { font-size: 1.5rem; color: var(--color-primary); }
.inv-tag { font-size: 0.65rem; font-weight: 800; letter-spacing: 0.2em; color: var(--color-text-dim); }

.inv-meta { text-align: right; font-size: 0.8rem; color: var(--color-text-dim); }

.inv-body { margin-top: 32px; flex: 1; }

.inv-target label { font-size: 0.7rem; font-weight: 800; color: var(--color-text-dim); }
.target-name { font-size: 1.2rem; font-weight: 700; margin-top: 4px; }

.inv-table {
  width: 100%;
  margin-top: 40px;
  border-collapse: collapse;
}

.inv-table th {
  text-align: left;
  padding: 12px;
  font-size: 0.7rem;
  color: var(--color-text-dim);
  border-bottom: 1px solid var(--glass-border);
}

.inv-table td { padding: 16px 12px; font-size: 0.9rem; border-bottom: 1px solid rgba(255,255,255,0.03); }

.inv-footer {
  margin-top: 40px;
  display: flex;
  justify-content: flex-end;
}

.total-row {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.total-label { font-size: 0.75rem; color: var(--color-text-dim); }
.total-value { font-size: 2rem; font-weight: 800; color: var(--color-primary); }

.inv-actions {
  margin-top: 48px;
  display: flex;
  justify-content: flex-end;
  gap: 16px;
}

.empty-preview {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: var(--color-text-dim);
}

.empty-preview .illustration { font-size: 80px; opacity: 0.05; margin-bottom: 24px; }
.empty-preview h3 { font-family: var(--font-headline); font-size: 1.2rem; margin-bottom: 8px; }

/* FADE TRANSITION */
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
