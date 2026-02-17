<template>
  <div class="sales-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">REVENUE TERMINAL</h4>
        <h1 class="hero-font">Sales Trace</h1>
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
      </div>
    </header>

    <div class="sales-grid">
      <!-- LEFT: SELECTION & FORM -->
      <section class="form-area glass-panel">
        <h3 class="panel-title">Transaction Details</h3>
        
        <form @submit.prevent="handlePreview" class="pos-form">
          <div class="form-group">
            <label>Customer / Client</label>
            <div class="custom-select-wrapper">
              <select v-model="form.customer_id" class="premium-input">
                <option :value="null">Guest Customer</option>
                <option v-for="c in customers" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </div>
          </div>

          <div class="items-selection">
            <label>Package Selection</label>
            <div class="pkg-grid">
              <div 
                v-for="item in inventory" 
                :key="item.id" 
                class="pkg-card" 
                :class="{ active: selectedEggType === item.id, disabled: item.current_stock <= 0 }"
                @click="item.current_stock > 0 && (selectedEggType = item.id)"
              >
                <div class="pkg-info">
                  <span class="p-label">{{ item.label }}</span>
                  <span class="p-stock">{{ item.current_stock }} available</span>
                </div>
                <div class="p-price">Rp {{ item.base_price_per_pack.toLocaleString() }}</div>
                <PackageIcon class="pkg-icon" />
              </div>
            </div>
          </div>

          <div class="quantity-input-group">
            <div class="form-group">
              <label>Quantity (Pack / 10 Butir)</label>
              <input 
                type="number" 
                v-model.number="form.quantity" 
                min="1" 
                :max="maxPacks"
                class="premium-input qty-box"
              />
            </div>
            <div class="total-preview-mini">
              <span class="label">Line Total</span>
              <span class="value">Rp {{ currentTotal.toLocaleString() }}</span>
            </div>
          </div>

          <button type="submit" class="btn-primary-glow w-full" :disabled="!isFormValid">
            <ZapIcon class="icon" />
            <span>GENERATE PREVIEW</span>
          </button>
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
                  <td>{{ currentPrice.toLocaleString() }}</td>
                  <td>{{ currentTotal.toLocaleString() }}</td>
                </tr>
              </tbody>
            </table>

            <div class="inv-footer">
              <div class="total-row">
                <span class="total-label">Grand Total</span>
                <span class="total-value">Rp {{ currentTotal.toLocaleString() }}</span>
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
import { PackageIcon, ZapIcon, FileTextIcon } from 'lucide-vue-next';

const inventory = ref<any[]>([]);
const customers = ref<any[]>([]);
const selectedEggType = ref('hero_size');
const showPreview = ref(false);
const loading = ref(false);

const form = reactive({
  customer_id: null,
  quantity: 1,
});

async function fetchData() {
  const { data: inv } = await supabase.from('inventory').select('*');
  if (inv) inventory.value = inv;

  const { data: cust } = await supabase.from('customers').select('*');
  if (cust) customers.value = cust;
}

const heroStock = computed(() => inventory.value.find(i => i.id === 'hero_size')?.current_stock ?? 0);
const standardStock = computed(() => inventory.value.find(i => i.id === 'standard_size')?.current_stock ?? 0);

const maxStock = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.current_stock ?? 0);
const maxPacks = computed(() => Math.floor(maxStock.value / 10));

const currentPrice = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.base_price_per_pack ?? 0);
const currentTotal = computed(() => form.quantity * currentPrice.value);
const isFormValid = computed(() => form.quantity > 0 && form.quantity <= maxPacks.value);

const selectedCustomerName = computed(() => {
  if (!form.customer_id) return 'Guest Customer';
  return customers.value.find(c => c.id === form.customer_id)?.name || 'Guest';
});

const selectedEggLabel = computed(() => {
  return inventory.value.find(i => i.id === selectedEggType.value)?.label || 'Eggs';
});

function handlePreview() {
  showPreview.value = true;
}

async function confirmSale() {
  loading.value = true;
  
  try {
    // 1. Create Sale Record
    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert({
        customer_id: form.customer_id,
        total_amount: currentTotal.value,
        payment_status: 'paid'
      })
      .select()
      .single();

    if (saleError) throw saleError;

    // 2. Create Sale Item
    await supabase.from('sale_items').insert({
      sale_id: sale.id,
      egg_type: selectedEggType.value,
      quantity: form.quantity,
      unit_price: currentPrice.value,
      subtotal: currentTotal.value
    });

    // 3. Update Inventory & Log (Subtract in Butir)
    const quantityInButir = form.quantity * 10;
    const newStock = maxStock.value - quantityInButir;
    
    await supabase.from('inventory').update({ current_stock: newStock }).eq('id', selectedEggType.value);
    
    await supabase.from('stock_logs').insert({
      egg_type: selectedEggType.value,
      change: -quantityInButir,
      log_type: 'sale',
      notes: `Sale to ${selectedCustomerName.value} (${form.quantity} Pack / ${quantityInButir} Butir) (#${sale.id})`
    });

    alert('Transaction Successful!');
    showPreview.value = false;
    form.quantity = 1;
    fetchData();
  } catch (e: any) {
    alert('Error: ' + e.message);
  } finally {
    loading.value = false;
  }
}

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

.premium-input {
  width: 100%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  padding: 14px 20px;
  border-radius: var(--radius-md);
  color: white;
  font-family: var(--font-body);
}

.pkg-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-top: 12px;
}

.pkg-card {
  padding: 20px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-md);
  cursor: pointer;
  position: relative;
  transition: var(--transition-smooth);
}

.pkg-card:hover { background: rgba(255, 255, 255, 0.05); }
.pkg-card.active {
  border-color: var(--color-primary);
  background: rgba(255, 140, 0, 0.05);
  box-shadow: 0 0 20px rgba(255, 140, 0, 0.1);
}

.pkg-card.disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.pkg-info { display: flex; flex-direction: column; gap: 4px; }
.p-label { font-weight: 700; font-size: 0.9rem; }
.p-stock { font-size: 0.7rem; color: var(--color-text-dim); }
.p-price { margin-top: 8px; font-weight: 800; color: var(--color-primary); }

.pkg-icon {
  position: absolute;
  right: 12px;
  top: 12px;
  width: 16px;
  height: 16px;
  opacity: 0.2;
}

.quantity-input-group {
  display: grid;
  grid-template-columns: 1fr 1fr;
  align-items: flex-end;
  gap: 24px;
}

.total-preview-mini {
  padding: 14px;
  border-bottom: 2px solid var(--color-primary);
  display: flex;
  flex-direction: column;
}

.total-preview-mini .label { font-size: 0.65rem; color: var(--color-text-dim); }
.total-preview-mini .value { font-size: 1.2rem; font-weight: 800; }

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
</style>
