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

            <!-- Payment Status Toggle -->
            <div class="payment-toggle-group">
              <label class="section-label">Payment Status</label>
              <div class="toggle-options">
                <button
                  type="button"
                  class="toggle-btn"
                  :class="{ active: form.paymentStatus === 'pending', pending: true }"
                  @click="form.paymentStatus = 'pending'"
                >
                  <span class="toggle-dot pending"></span>
                  Pending
                </button>
                <button
                  type="button"
                  class="toggle-btn"
                  :class="{ active: form.paymentStatus === 'paid', paid: true }"
                  @click="form.paymentStatus = 'paid'"
                >
                  <span class="toggle-dot paid"></span>
                  Paid
                </button>
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

            <div class="action-row mt-4">
              <button type="button" class="btn-secondary w-full" @click="addToCart" :disabled="!selectedEggType || form.quantity <= 0 || form.quantity > maxPacks">
                <PlusIcon class="icon-sm" />
                <span>ADD TO CART</span>
              </button>
              
              <button type="submit" class="btn-primary-glow w-full" :disabled="!isFormValid">
                <ZapIcon class="icon" />
                <span>GENERATE PREVIEW</span>
              </button>
            </div>
          </div>
        </form>
      </section>

      <!-- RIGHT: INVOICE PREVIEW & CART -->
      <section class="preview-area glass-panel">
        <!-- Cart Section -->
        <div class="cart-section" v-if="cart.length > 0 && !showPreview">
          <div class="cart-header">
            <h3 class="hero-font">Current Cart</h3>
            <span class="cart-count">{{ cart.length }} items</span>
          </div>
          
          <div class="cart-items">
            <div v-for="(item, index) in cart" :key="item.id" class="cart-item glass-panel" :class="{ 'is-editing': editingIndex === index }">
              <div class="item-info">
                <span class="item-label">{{ item.label }}</span>
                <span class="item-qty">{{ item.quantity }} Pack</span>
              </div>
              <div class="item-price-actions">
                <div v-if="editingIndex === index" class="price-editor">
                  <span class="prefix">Rp</span>
                  <input 
                    type="number" 
                    v-model.number="editingPriceValue" 
                    class="price-edit-input"
                    @keyup.enter="savePriceEdit(index)"
                  />
                  <button class="btn-save-price" @click="savePriceEdit(index)">
                    <CheckIcon class="icon-xs" />
                  </button>
                  <button class="btn-cancel-price" @click="editingIndex = null">
                    <XIcon class="icon-xs" />
                  </button>
                </div>
                <div v-else class="price-display">
                  <span class="item-subtotal">Rp {{ item.subtotal.toLocaleString() }}</span>
                  <span class="unit-price-hint">(@ Rp {{ item.price.toLocaleString() }})</span>
                  <button class="btn-edit-price" @click="startEditPrice(index, item.price)" title="Override Price">
                    <Edit3Icon class="icon-xs" />
                  </button>
                </div>
                <button v-if="editingIndex !== index" class="btn-remove" @click="removeFromCart(index)">
                  <Trash2Icon class="icon-xs" />
                </button>
              </div>
            </div>
          </div>

          <div class="cart-footer">
            <div class="cart-total-row">
              <span class="label">Total Order</span>
              <span class="value">Rp {{ cartTotal.toLocaleString() }}</span>
            </div>
          </div>
        </div>

        <div class="invoice-container" v-if="showPreview">
          <div class="invoice-header">
            <div class="inv-brand">
              <span class="hero-font">HERO FARM</span>
              <span class="inv-tag">OFFICIAL INVOICE</span>
            </div>
            <div class="inv-meta">
              <p>NO: #AWAITING-SAVING</p>
              <p>DATE: {{ new Date().toLocaleDateString('id-ID') }}</p>
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
                <tr v-for="item in cart" :key="item.id">
                  <td>{{ item.label }}</td>
                  <td>{{ item.quantity }} Pack ({{ item.quantity * 10 }} Butir)</td>
                  <td>{{ item.price.toLocaleString('id-ID') }}</td>
                  <td>{{ item.subtotal.toLocaleString('id-ID') }}</td>
                </tr>
              </tbody>
            </table>

            <div class="inv-footer">
              <div class="total-row">
                <span class="total-label">Grand Total</span>
                <span class="total-value">Rp {{ cartTotal.toLocaleString('id-ID') }}</span>
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
  MinusIcon,
  Trash2Icon,
  Edit3Icon,
  CheckIcon,
  XIcon
} from 'lucide-vue-next';
import { generateInvoiceHTML } from '../utils/invoiceTemplate';

// 1. STATE
const inventory = ref<any[]>([]);
const customers = ref<any[]>([]);
const selectedEggType = ref('hero_size');
const showPreview = ref(false);
const loading = ref(false);
const editingIndex = ref<number | null>(null);
const editingPriceValue = ref(0);


const customerSearch = ref('');
const customerPhone = ref('');
const showCustResults = ref(false);
const selectedCustomerId = ref<string | null>(null);

const form = reactive({
  quantity: 1,
  paymentStatus: 'paid' as 'paid' | 'pending',
});

const cart = ref<Array<{
  id: string,
  label: string,
  quantity: number,
  price: number,
  subtotal: number
}>>([]);

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

const cartTotal = computed(() => cart.value.reduce((sum, item) => sum + item.subtotal, 0));


const isFormValid = computed(() => {
  return cart.value.length > 0 && customerSearch.value.trim().length > 0;
});

// 4. METHODS
function selectExistingCustomer(customer: any) {
  customerSearch.value = customer.name;
  customerPhone.value = customer.whatsapp_number || '';
  selectedCustomerId.value = customer.id;
  showCustResults.value = false;
}

function addToCart() {
  if (!selectedEggType.value || form.quantity <= 0) return;
  
  const existing = cart.value.find(item => item.id === selectedEggType.value);
  if (existing) {
    existing.quantity += form.quantity;
    existing.subtotal = existing.quantity * existing.price;
  } else {
    cart.value.push({
      id: selectedEggType.value,
      label: selectedEggLabel.value,
      quantity: form.quantity,
      price: currentPrice.value,
      subtotal: currentTotal.value
    });
  }
  
  // Reset selection
  selectedEggType.value = 'hero_size'; // Reset to a default or empty
  form.quantity = 1;
}

function removeFromCart(index: number) {
  cart.value.splice(index, 1);
  if (editingIndex.value === index) editingIndex.value = null;
}

function startEditPrice(index: number, currentPrice: number) {
  editingIndex.value = index;
  editingPriceValue.value = currentPrice;
}

function savePriceEdit(index: number) {
  if (editingPriceValue.value <= 0) return;
  const item = cart.value[index];
  if (item) {
    item.price = editingPriceValue.value;
    item.subtotal = item.quantity * item.price;
  }
  editingIndex.value = null;
}


function handlePreview() {
  if (cart.value.length === 0) return;
  showPreview.value = true;
}

function printInvoice(saleId: string, customItems?: any[], customTotal?: number) {
  const invoiceData = {
    invoiceNo: `EP-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}${String(new Date().getDate()).padStart(2, '0')}${String(saleId).slice(-3).toUpperCase()}`,
    date: new Date().toLocaleDateString('id-ID'),
    customerName: selectedCustomerName.value,
    customerPhone: customerPhone.value,
    items: customItems || cart.value.map(item => ({
      description: item.label,
      quantity: item.quantity,
      unit: 'Pack',
      price: item.price,
      total: item.subtotal
    })),
    grandTotal: customTotal !== undefined ? customTotal : cartTotal.value
  };

  const html = generateInvoiceHTML(invoiceData);
  const printWindow = window.open('', '_blank');
  if (printWindow) {
    printWindow.document.write(html);
    printWindow.document.close();
    
    // Wait for styles/fonts to load before printing
    setTimeout(() => {
      printWindow.print();
    }, 500);
  }
}

async function confirmSale() {
  if (cart.value.length === 0) return;
  
  loading.value = true;
  
  // Capture snapshot for printing since cart will be cleared
  const cartSnapshot = cart.value.map(item => ({
    description: item.label,
    quantity: item.quantity,
    unit: 'Pack',
    price: item.price,
    total: item.subtotal
  }));
  const totalSnapshot = cartTotal.value;

  try {
    let finalCustomerId = selectedCustomerId.value;

    // A. Auto-Register if it's a new name
    if (!finalCustomerId && customerSearch.value) {
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
        total_price: totalSnapshot,
        payment_status: form.paymentStatus,
        fulfillment_status: 'processing',
        stock_reserved: true
      })
      .select()
      .single();

    if (saleError) throw saleError;

    // C. Create Sale Items & Update Stock
    for (const item of cartSnapshot) {
      // Find original item id for database
      const originalItem = cart.value.find(c => c.label === item.description);
      const eggId = originalItem?.id;

      await supabase.from('sale_items').insert({
        sale_id: sale.id,
        egg_type: eggId,
        quantity: item.quantity,
        unit_price: item.price,
        subtotal: item.total
      });

      // Update Egg Stock
      const eggInInv = inventory.value.find(i => i.id === eggId);
      if (eggInInv) {
        const quantityInButir = item.quantity * 10;
        const newEggStock = eggInInv.current_stock - quantityInButir;
        await supabase.from('inventory').update({ current_stock: newEggStock }).eq('id', eggId);
        
        await supabase.from('stock_logs').insert({
          egg_type: eggId,
          change: -quantityInButir,
          log_type: 'sale',
          notes: `Sale #${sale.id.toString().substring(0,6).toUpperCase()} (${item.quantity} Pack)`
        });

        // Price Override Audit
        if (item.price !== eggInInv.base_price_per_pack) {
          const uemail = await supabase.auth.getUser().then(r => r.data.user?.email || 'Unknown');
          await supabase.from('price_overrides').insert({
            sale_id: sale.id,
            product_id: eggId,
            original_price: eggInInv.base_price_per_pack,
            override_price: item.price,
            override_by: uemail
          });
        }
      }
    }

    // D. Update Packaging Materials
    const totalPacks = cartSnapshot.reduce((sum, i) => sum + i.quantity, 0);
    const supplies = ['packaging_standard', 'sticker_label', 'mini_card'];
    for (const supplyId of supplies) {
      const currentSupply = inventory.value.find(i => i.id === supplyId);
      if (currentSupply) {
        const newSupplyStock = Math.max(0, currentSupply.current_stock - totalPacks);
        await supabase.from('inventory').update({ current_stock: newSupplyStock }).eq('id', supplyId);
      }
    }

    // E. Update Customer Stats
    const currentCustomer = customers.value.find(c => c.id === finalCustomerId);
    if (currentCustomer) {
      const newOrders = (currentCustomer.total_orders || 0) + 1;
      const newSpent = (currentCustomer.total_spent || 0) + totalSnapshot;
      await supabase.from('customers')
        .update({ total_orders: newOrders, total_spent: newSpent, updated_at: new Date().toISOString() })
        .eq('id', finalCustomerId);
    }

    // Auto-Trigger Print with snapshot
    printInvoice(sale.id, cartSnapshot, totalSnapshot);

    // Reset state
    showPreview.value = false;
    form.quantity = 1;
    form.paymentStatus = 'paid';
    cart.value = [];
    customerSearch.value = '';
    customerPhone.value = '';
    selectedCustomerId.value = null;
    fetchData();

    alert('Transaction Successful!');
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

/* PAYMENT TOGGLE */
.payment-toggle-group {
  margin-top: 4px;
}

.toggle-options {
  display: flex;
  gap: 10px;
}

.toggle-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 20px;
  border-radius: 12px;
  border: 1px solid var(--glass-border);
  background: rgba(255, 255, 255, 0.03);
  color: var(--color-text-dim);
  font-family: var(--font-body);
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
  flex: 1;
  justify-content: center;
}

.toggle-btn:hover {
  background: rgba(255, 255, 255, 0.06);
  color: white;
}

.toggle-btn.active.pending {
  background: rgba(255, 170, 0, 0.1);
  border-color: rgba(255, 170, 0, 0.4);
  color: #FFAA00;
}

.toggle-btn.active.paid {
  background: rgba(0, 255, 157, 0.08);
  border-color: rgba(0, 255, 157, 0.35);
  color: var(--color-success);
}

.toggle-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
}

.toggle-dot.pending { background: #FFAA00; box-shadow: 0 0 6px rgba(255, 170, 0, 0.5); }
.toggle-dot.paid { background: var(--color-success); box-shadow: 0 0 6px rgba(0, 255, 157, 0.5); }

/* CART STYLES */
.cart-section {
  padding: 24px;
  border-bottom: 1px solid var(--glass-border);
}

.cart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.cart-count {
  font-size: 0.7rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--color-primary);
  background: rgba(255, 140, 0, 0.1);
  padding: 4px 10px;
  border-radius: 8px;
}

.cart-items {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 300px;
  overflow-y: auto;
  padding-right: 8px;
}

.cart-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.02);
}

.item-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.item-label { font-weight: 700; font-size: 0.95rem; color: white; }
.item-qty { font-size: 0.75rem; color: var(--color-text-dim); }

.item-price-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.item-subtotal { font-weight: 800; color: var(--color-primary); font-size: 0.95rem; }

.item-price-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.price-display {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.unit-price-hint {
  font-size: 0.65rem;
  color: var(--color-text-dim);
  font-weight: 700;
}

.price-editor {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(255, 140, 0, 0.1);
  padding: 4px 8px;
  border-radius: 8px;
  border: 1px solid rgba(255, 140, 0, 0.2);
}

.price-edit-input {
  width: 80px;
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--color-primary);
  color: white;
  font-size: 0.85rem;
  font-weight: 800;
  text-align: right;
  padding: 2px 4px;
}

.price-edit-input:focus {
  outline: none;
  border-bottom-width: 2px;
}

.btn-edit-price, .btn-save-price, .btn-cancel-price {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.btn-edit-price:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.btn-save-price { color: var(--color-success); }
.btn-save-price:hover { background: rgba(0, 255, 157, 0.1); }

.btn-cancel-price { color: var(--color-error); }
.btn-cancel-price:hover { background: rgba(255, 66, 66, 0.1); }

.is-editing {
  border-color: var(--color-primary) !important;
  background: rgba(255, 140, 0, 0.05) !important;
}

.btn-remove {

  background: rgba(255, 66, 66, 0.1);
  border: 1px solid rgba(255, 66, 66, 0.2);
  color: var(--color-error);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-remove:hover {
  background: var(--color-error);
  color: white;
}

.cart-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px dotted var(--glass-border);
}

.cart-total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.cart-total-row .label { font-size: 0.8rem; color: var(--color-text-dim); font-weight: 600; }
.cart-total-row .value { font-size: 1.4rem; font-weight: 900; color: white; }

.action-row {
  display: flex;
  gap: 16px;
}

.icon-xs { width: 14px; height: 14px; }
.icon-sm { width: 18px; height: 18px; }

.section-label {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  margin-bottom: 12px;
  display: block;
}

.action-row {
  display: flex;
  gap: 16px;
}

.w-full {
  width: 100%;
}

/* PREMIUM BUTTONS */
.btn-primary, .btn-primary-glow, .btn-secondary {
  border-radius: 12px;
  padding: 14px 24px;
  font-weight: 700;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
  border: none;
  font-family: inherit;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  height: 54px;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
  box-shadow: 0 4px 15px rgba(255, 140, 0, 0.2);
}

.btn-primary:hover:not(:disabled) {
  background: #ff8c00;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 140, 0, 0.3);
}

.btn-primary-glow {
  background: linear-gradient(135deg, var(--color-primary), #ffb800);
  color: white;
  box-shadow: 0 0 20px rgba(255, 140, 0, 0.25);
  position: relative;
  overflow: hidden;
}

.btn-primary-glow:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 0 30px rgba(255, 140, 0, 0.45);
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.2);
  transform: translateY(-2px);
}

.btn-primary:disabled, .btn-primary-glow:disabled, .btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
  background: rgba(255, 255, 255, 0.05);
  color: var(--color-text-dim);
  border: 1px solid var(--glass-border);
}
</style>
