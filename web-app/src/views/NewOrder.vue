<template>
  <div class="sales-page">
    <!-- HEADER SECTION -->
    <header class="header desktop-only">
      <div class="header-left">
        <h4 class="brand-tag">REVENUE TERMINAL</h4>
        <h1 class="hero-font white-title">New Order Entry</h1>
      </div>
      
      <!-- STOCK INDICATOR BAR -->
      <div class="stock-bar glass-panel">
        <div 
          v-for="item in sellableProducts" 
          :key="item.id" 
          class="stock-chip"
          :class="[item.id, getStockStatusClass(item)]"
        >
          <span class="chip-icon">🥚</span>
          <span class="chip-label">{{ item.label }}</span>
          <span class="chip-val">{{ formatStock(item.current_stock) }}</span>
        </div>
      </div>
    </header>

    <!-- RETRYING BANNER -->
    <div v-if="isRetrying" class="retry-banner glass-panel animate-fade-in">
      <span class="retry-dot pulse"></span>
      <span>Mencoba memuat ulang... (percobaan ke-{{ retryCount }})</span>
    </div>

    <!-- FETCH ERROR STATE -->
    <section v-if="fetchError" class="fetch-error-card glass-panel animate-pop">
      <div class="fec-icon">⚠️</div>
      <h3 class="fec-title">Koneksi bermasalah</h3>
      <p class="fec-desc">Data inventori tidak bisa dimuat.</p>
      <button class="btn-primary mt-6" @click="retryFetch">
        🔄 Coba Lagi
      </button>
      <p class="fec-hint mt-4">Pastikan koneksi internetmu stabil</p>
    </section>

    <!-- MOBILE STOCK BAR -->
    <div class="mobile-stock-nav scroll-x glass-panel mobile-only mb-6">
      <div 
        v-for="item in sellableProducts" 
        :key="'m-'+item.id" 
        class="stock-chip-mini"
        :class="[item.id, { 'oos': item.current_stock <= 0 }]"
      >
        <span class="scm-label">{{ item.label[0] }}</span>
        <span class="scm-val">{{ formatStock(item.current_stock) }}</span>
      </div>
    </div>

    <div class="sales-grid">
      <!-- LEFT PANEL: TRANSACTION DETAILS -->
      <section class="form-area glass-panel">
        <div class="step-indicator">STEP 1: CUSTOMER INFO</div>
        
        <div class="field-row">
          <div class="field-col">
            <label>Customer Name</label>
            <div class="search-input-wrapper" v-outside-click="() => showCustResults = false">
              <input 
                type="text" 
                v-model="customerSearch" 
                v-titlecase
                placeholder="Type name..." 
                class="premium-input"
                @focus="showCustResults = true"
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
          <div class="field-col">
            <label>WA Number (Optional)</label>
            <input 
              type="text" 
              v-model="customerPhone" 
              placeholder="0812..." 
              class="premium-input"
            />
          </div>
        </div>

        <div class="items-selection mt-32">
          <div class="step-indicator">STEP 2: PACKAGE SELECTION</div>
          <div class="pkg-grid-3" v-if="loading">
            <div class="skeleton-wrap p-20 text-center">
              <SkeletonLoader v-for="i in 3" :key="i" type="card" height="120px" />
              <p class="loading-hint mt-12">{{ loadingMsg }}</p>
            </div>
          </div>
          <div class="pkg-grid-3" v-else-if="sellableProducts.length > 0">
            <div 
              v-for="item in sellableProducts" 
              :key="item.id" 
              class="pkg-card-v2" 
              :class="{ 
                active: selectedEggType === item.id, 
                'out-of-stock': item.current_stock <= 0,
                [item.id]: true
              }"
              @click="item.current_stock > 0 ? selectedEggType = item.id : null"
            >
              <div class="pkg-status-badge" v-if="item.current_stock <= 0">HABIS</div>
              <div class="pkg-name">[{{ item.label.toUpperCase() }}]</div>
              <div class="pkg-available">{{ calcMaxPacks(item.current_stock) }} pack tersedia</div>
              <div class="pkg-price">{{ formatCurrency(item.base_price_per_pack || 0) }}</div>
              <div class="pkg-glow" v-if="selectedEggType === item.id"></div>
            </div>
          </div>
          <div v-else class="empty-inventory-alert glass-panel p-20 text-center">
            <p class="text-dim mb-12">Tidak ada produk tersedia atau gagal memuat data.</p>
            <button @click="fetchData" class="btn-secondary btn-sm">RETRY DATA FETCH</button>
          </div>
        </div>

        <!-- STEP 3: QUANTITY + PAYMENT (Shown after grade selected) -->
        <Transition name="slide-fade">
          <div class="order-config-v2 mt-32" v-if="selectedEggType">
            <div class="step-indicator">STEP 3: QUANTITY & PAYMENT</div>
            
            <div class="qty-payment-row">
              <div class="qty-stepper-box">
                <label>QUANTITY</label>
                <div class="stepper glass-panel">
                  <button type="button" class="step-btn" @click="form.quantity > 1 ? form.quantity-- : null" :disabled="form.quantity <= 1">
                    <MinusIcon class="icon-sm gold" />
                  </button>
                  <input type="number" v-model.number="form.quantity" min="1" :max="maxPacks" class="step-input" />
                  <button type="button" class="step-btn" @click="form.quantity < maxPacks ? form.quantity++ : null">
                    <PlusIcon class="icon-sm gold" />
                  </button>
                </div>
              </div>
              
              <div class="live-total-box">
                <label>LINE TOTAL</label>
                <div class="mono-total">{{ formatCurrency(currentTotal) }}</div>
              </div>
            </div>

            <div class="payment-selection mt-24">
              <label>PAYMENT TYPE</label>
              <div class="toggle-group-v2">
                <button
                  type="button"
                  class="toggle-v2"
                  :class="{ active: form.paymentStatus === 'tunai' }"
                  @click="form.paymentStatus = 'tunai'"
                >
                  <span class="t-dot" :class="{ filled: form.paymentStatus === 'tunai' }"></span>
                  <span>Tunai (Cash)</span>
                </button>
                <button
                  type="button"
                  class="toggle-v2"
                  :class="{ active: form.paymentStatus === 'transfer' }"
                  @click="form.paymentStatus = 'transfer'"
                >
                  <span class="t-dot" :class="{ filled: form.paymentStatus === 'transfer' }"></span>
                  <span>Transfer Bank</span>
                </button>
                <button
                  type="button"
                  class="toggle-v2"
                  :class="{ active: form.paymentStatus === 'piutang' }"
                  @click="form.paymentStatus = 'piutang'"
                >
                  <span class="t-dot" :class="{ filled: form.paymentStatus === 'piutang' }"></span>
                  <span>Piutang (Tempo)</span>
                </button>
              </div>
            </div>

            <!-- PIUTANG DUE DATE -->
            <Transition name="slide-fade">
              <div v-if="form.paymentStatus === 'piutang'" class="due-date-alert glass-panel mt-16">
                <div class="alert-content">
                  <p class="alert-title">⚠ Tanggal Jatuh Tempo</p>
                  <input type="date" v-model="form.dueDate" class="premium-input-date" />
                  <p class="alert-hint">Wajib diisi untuk transaksi tempo</p>
                </div>
              </div>
            </Transition>

            <div class="action-buttons mt-32">
              <button 
                type="button" 
                class="btn-primary w-full" 
                @click="addToCart" 
                :disabled="!canAddToCart"
              >
                <PlusIcon class="icon-sm" />
                <span>+ ADD TO CART</span>
              </button>
            </div>
          </div>
        </Transition>

        <!-- CART SUMMARY -->
        <Transition name="slide-fade">
          <div class="cart-summary-v2 mt-40 glass-panel" v-if="cart.length > 0">
            <div class="cs-header">
              <h3 class="hero-font">🛒 KERANJANG</h3>
              <span class="cs-count">{{ cart.length }} item</span>
            </div>
            
            <div class="cs-items">
              <div v-for="(item, index) in cart" :key="item.id" class="cs-line">
                <span class="cs-name">{{ item.label }} × {{ item.quantity }} pack</span>
                <span class="cs-price">{{ formatCurrency(item.subtotal) }}</span>
                <button class="cs-remove" @click="removeFromCart(index)">&times;</button>
              </div>
            </div>

            <div class="cs-divider"></div>

            <div class="cs-totals">
              <div class="cs-row">
                <span>Subtotal</span>
                <span>{{ formatCurrency(cartTotal) }}</span>
              </div>
              <div class="cs-row muted" v-if="authStore.profile?.role === 'admin'">
                <span>Est. HPP</span>
                <span>{{ formatCurrency(cartMarginAnalysis.totalHpp) }}</span>
              </div>
              <div class="cs-row profit" v-if="authStore.profile?.role === 'admin'">
                <span>Est. Profit</span>
                <span class="success-text">{{ formatCurrency(cartMarginAnalysis.profit) }} 🟢</span>
              </div>
            </div>

          </div>
        </Transition>
      </section>

      <!-- RIGHT PANEL: INVOICE PREVIEW -->
      <section class="preview-area glass-panel" :class="{ 'mobile-hidden': cart.length === 0 }">
        <div v-if="cart.length === 0" class="empty-state-v2 desktop-only">
          <div class="receipt-icon">
            <FileTextIcon :size="64" />
          </div>
          <h3>Awaiting Input</h3>
          <p>Tambahkan item ke keranjang untuk melihat preview nota.</p>
        </div>

        <div v-else class="invoice-container-v2 animate-pop">
           <div class="invoice-v2-paper glass-panel">
              <div class="inv-v2-header">
                <div class="brand">
                  <h2 class="hero-font gold-text">HERO FARM</h2>
                  <p class="tagline">Official Revenue Terminal</p>
                </div>
                <div class="inv-meta">
                  <p>NO: {{ generatedInvoiceNo }}</p>
                  <p>DATE: {{ new Date().toLocaleDateString('id-ID') }}</p>
                </div>
              </div>

              <div class="inv-v2-client mt-24">
                <label>BILLING TO:</label>
                <h3>{{ customerSearch || 'Guest' }}</h3>
                <p v-if="customerPhone">{{ customerPhone }}</p>
              </div>

              <div class="inv-v2-tags mt-16">
                 <span class="p-badge" :class="form.paymentStatus">
                   {{ 
                     form.paymentStatus === 'piutang' ? 'PIUTANG TEMPO' : 
                     form.paymentStatus === 'transfer' ? 'TRANSFER BANK' : 'TUNAI' 
                   }}
                 </span>
                 <span v-if="form.paymentStatus === 'piutang'" class="due-badge">
                   Jatuh Tempo: {{ form.dueDate }}
                 </span>
              </div>

              <table class="inv-v2-table mt-24">
                <thead>
                  <tr>
                    <th>Grade</th>
                    <th>Qty</th>
                    <th>Price</th>
                    <th class="text-right">Total</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in cart" :key="item.id">
                    <td>{{ item.label }}</td>
                    <td>{{ item.quantity }}pk ({{ item.quantity * 10 }}b)</td>
                    <td>{{ formatCurrency(item.price/10) }}</td>
                    <td class="text-right">{{ formatCurrency(item.subtotal) }}</td>
                  </tr>
                </tbody>
              </table>

              <div class="inv-v2-footer mt-32">
                <div class="total-big">
                  <label>GROSS TOTAL</label>
                  <div class="val">{{ formatCurrency(cartTotal) }}</div>
                </div>
                <div class="profit-mini" v-if="authStore.profile?.role === 'admin'">
                  <label>EST. PROFIT</label>
                  <span class="success-text">{{ formatCurrency(cartMarginAnalysis.profit) }}</span>
                </div>
              </div>
           </div>

           <div class="preview-actions mt-32">
              <button class="btn-primary flex-1 py-4 text-sm font-bold tracking-wider" @click="confirmSale" :disabled="loading">
                <CheckIcon class="icon-md mr-2" v-if="!loading" />
                <Loader2Icon class="icon-md spin mr-2" v-else />
                CONFIRM & PRINT INVOICE
              </button>
           </div>
        </div>
      </section>
    </div>

    <!-- MOBILE STICKY FOOTER -->
    <div class="mobile-sticky-actions mobile-only" v-if="cart.length > 0">
      <div class="msa-info">
        <span class="msa-label">TOTAL ({{ cart.length }} Item)</span>
        <span class="msa-val">{{ formatCurrency(cartTotal) }}</span>
      </div>
      <button class="btn-primary" @click="confirmSale" :disabled="loading">
        <CheckIcon class="icon-sm" v-if="!loading" />
        <span>CONFIRM</span>
      </button>
    </div>

    <!-- CUSTOM CONFIRM MODAL -->
    <CustomConfirmModal 
      v-model="showConfirmModal"
      :title="confirmData.title"
      :message="confirmData.message"
      @confirm="confirmData.onConfirm()"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { withTimeout } from '../utils/safeAsync';
import { 
  PlusIcon, 
  MinusIcon,
  FileTextIcon, 
  CheckIcon,
  Loader2Icon
} from 'lucide-vue-next';
import { useToast } from '../composables/useToast';
import SkeletonLoader from '../components/ui/SkeletonLoader.vue';
import CustomConfirmModal from '../components/ui/CustomConfirmModal.vue';
import { generateInvoiceHTML } from '../utils/invoiceTemplate';

const { showToast } = useToast();
const authStore = useAuthStore();

// GLOBAL UTILS
// @ts-ignore
import { GRADES, normalizeGrade, getGradeLabel } from '../constants/grades';
// @ts-ignore
import { formatCurrency, formatStock, formatPct, toTitleCase } from '../utils/formatters';
// @ts-ignore
import { calcHppPerPack, calcMargin, calcMaxPacks } from '../utils/calculations';

// Custom directive for title case
const vTitlecase = {
  mounted(el: HTMLInputElement) {
    el.addEventListener('input', (event: Event) => {
      const target = event.target as HTMLInputElement;
      target.value = toTitleCase(target.value);
    });
  },
  updated(el: HTMLInputElement) {
    // Ensure initial value is title cased if it changes programmatically
    el.value = toTitleCase(el.value);
  }
};

// 1. STATE
const inventory = ref<any[]>([]);
const customers = ref<any[]>([]);
const selectedEggType = ref('');
const showPreview = ref(false);
const loading = ref(false);
const showConfirmModal = ref(false);
const confirmData = reactive({
  title: '',
  message: '',
  onConfirm: () => {}
});

// Error Recovery State (cart is preserved during retries)
const fetchError = ref(false);
const retryCount = ref(0);
const isRetrying = ref(false);

const customerSearch = ref('');
const customerPhone = ref('');
const showCustResults = ref(false);
const selectedCustomerId = ref<string | null>(null);

const form = reactive({
  quantity: 1,
  paymentStatus: 'tunai' as 'tunai' | 'transfer' | 'piutang',
  dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
});

const cart = ref<Array<{
  id: string,
  label: string,
  quantity: number,
  price: number,
  subtotal: number,
  overrideReason?: string
}>>([]);

// 2. FETCHING
const loadingMsg = ref('Initializing terminal...');

async function fetchData() {
  if (loading.value) return;
  loading.value = true;
  loadingMsg.value = 'Connecting to inventory...';
  
  try {
    // 1. Fetch Inventory
    const { data: inv, error: invErr } = await withTimeout(
      supabase.from('inventory').select('*'),
      undefined, 'pos-inventory'
    );
    if (invErr) throw invErr;
    if (inv) inventory.value = inv;

    loadingMsg.value = 'Fetching CRM database...';
    // 2. Fetch Customers
    const { data: cust, error: custErr } = await withTimeout(
      supabase.from('customers').select('*').limit(100),
      undefined, 'pos-customers'
    );
    if (custErr) {
        console.warn('Customer fetch failed, proceeding anyway:', custErr);
    }
    if (cust) customers.value = cust;
    
  } catch (err: any) {
    console.error('Terminal Data Sync Error:', err);
    throw err; // Let safeFetchData handle retries
  } finally {
    loading.value = false;
    loadingMsg.value = '';
  }
}

async function safeFetchData() {
  fetchError.value = false;
  retryCount.value = 0;
  isRetrying.value = false;
  try {
    await fetchData();
  } catch (err: any) {
    let succeeded = false;
    for (let attempt = 1; attempt <= 3; attempt++) {
      retryCount.value = attempt;
      isRetrying.value = true;
      const delay = 1000 * Math.pow(2, attempt - 1);
      await new Promise(r => setTimeout(r, delay));
      try {
        await fetchData();
        succeeded = true;
        break;
      } catch { /* continue */ }
    }
    isRetrying.value = false;
    if (!succeeded) {
      fetchError.value = true;
      showToast('Gagal memuat data. Tap Coba Lagi.', 'error');
    }
  }
}

function retryFetch() {
  fetchError.value = false;
  retryCount.value = 0;
  safeFetchData();
}

// 3. COMPUTED
const filteredCustomers = computed(() => {
  if (!customerSearch.value) return [];
  const q = customerSearch.value.toLowerCase();
  return customers.value.filter(c => c.name?.toLowerCase().includes(q));
});

const sellableProducts = computed(() => {
  const canonicalIds = ['hero', 'salted_egg'];
  // Deduplicate by canonical ID
  const seen = new Set();
  return inventory.value
    .filter(i => canonicalIds.includes(normalizeGrade(i.id)))
    .filter(i => {
      const cid = normalizeGrade(i.id);
      if (seen.has(cid)) return false;
      seen.add(cid);
      return true;
    })
    .sort((a, b) => canonicalIds.indexOf(normalizeGrade(a.id)) - canonicalIds.indexOf(normalizeGrade(b.id)));
});

const maxStock = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.current_stock ?? 0);
const maxPacks = computed(() => calcMaxPacks(maxStock.value));

const currentPrice = computed(() => inventory.value.find(i => i.id === selectedEggType.value)?.base_price_per_pack ?? 0);
const currentTotal = computed(() => form.quantity * currentPrice.value);

function getStockStatusClass(item: any) {
  const current = item.current_stock || 0;
  const safety = item.safety_stock || 20;
  
  if (current <= 0) return 'out-of-stock-pulse';
  if (current <= safety) return 'status-critical';
  if (current <= safety * 2) return 'status-low';
  return 'status-safe';
}

const cartTotal = computed(() => cart.value.reduce((sum, item) => sum + item.subtotal, 0));

const canAddToCart = computed(() => {
  if (form.paymentStatus === 'piutang' && !form.dueDate) return false;
  return selectedEggType.value && form.quantity > 0 && form.quantity <= maxPacks.value;
});

const cartMarginAnalysis = computed(() => {
  const totalHpp = cart.value.reduce((sum, item) => {
    const inv = inventory.value.find(i => i.id === item.id);
    return sum + (item.quantity * (inv?.hpp_per_pack || 0));
  }, 0);
  const profit = cartTotal.value - totalHpp;
  const marginPct = calcMargin(cartTotal.value, totalHpp);
  return { totalHpp, profit, marginPct };
});

const generatedInvoiceNo = computed(() => {
  const d = new Date();
  const dateStr = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  return `EP-${dateStr}XXX`;
});

// 4. METHODS
function selectExistingCustomer(customer: any) {
  customerSearch.value = customer.name;
  customerPhone.value = customer.whatsapp_number || '';
  selectedCustomerId.value = customer.id;
  showCustResults.value = false;
}

function addToCart() {
  if (!canAddToCart.value) return;
  
  const existing = cart.value.find(item => item.id === selectedEggType.value);
  
  if (existing) {
    existing.quantity += form.quantity;
    existing.subtotal = existing.quantity * existing.price;
  } else {
    cart.value.push({
      id: selectedEggType.value,
      label: getGradeLabel(selectedEggType.value),
      quantity: form.quantity,
      price: currentPrice.value,
      subtotal: currentTotal.value
    });
  }
  
  selectedEggType.value = '';
  form.quantity = 1;
  showToast('Added to cart');
}

function removeFromCart(index: number) {
  cart.value.splice(index, 1);
}

async function confirmSale() {
  if (cart.value.length === 0) return;
  
  confirmData.title = 'Konfirmasi Penjualan';
  confirmData.message = `Simpan transaksi sebesar ${formatCurrency(cartTotal.value)}?`;
  confirmData.onConfirm = async () => {
    loading.value = true;
    loadingMsg.value = 'Mempersiapkan data...';
    
    // Snaphots for printing
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
      loadingMsg.value = 'Verifikasi pelanggan...';

      // 1. CRM Resolution
      if (!finalCustomerId && customerSearch.value) {
        // Just use the name for the RPC, it handles creation

      }

      loadingMsg.value = 'Memproses transaksi (Siklus DB)...';
      
      const cleanItems = cart.value.map(item => {
        // Map legacy/UI IDs to canonical DB IDs
        const dbId = normalizeGrade(item.id);

        return {
          inventory_id: dbId,
          packs_sold: Number(item.quantity) || 1,
          override_price: Number(item.price) || 0,
          override_reason: item.overrideReason || null
        };
      });

      const rpcPayload = {
        p_customer_name: (customerSearch.value || 'Guest').trim(),
        p_items: cleanItems,
        p_payment_type: form.paymentStatus || 'tunai',
        p_due_date: form.paymentStatus === 'piutang' ? (form.dueDate || new Date().toISOString().split('T')[0]) : null
      };


      const { data: rpcResult, error: rpcError } = await withTimeout(
        supabase.rpc('create_sale_v2', rpcPayload),
        15000, 'create-sale-rpc'
      );
      
      if (rpcError) {
          console.error('RPC Execution Error:', rpcError);
          // provide cleaner error message to user
          const msg = rpcError.message?.includes('unique') ? 'Nama pelanggan sudah ada di database.' : rpcError.message;
          throw new Error(msg);
      }
      if (rpcResult?.error) {
        showToast(rpcResult.error, 'error');
        return;
      }

      printInvoice(cartSnapshot, totalSnapshot, rpcResult.invoice_number);

      // Reset
      showPreview.value = false;
      cart.value = [];
      customerSearch.value = '';
      customerPhone.value = '';
      selectedCustomerId.value = null;
      fetchData();
      showToast('Transaksi Berhasil!');
    } catch (e: any) {
      showToast('Gagal memproses transaksi', 'error');
    } finally {
      loading.value = false;
    }
  };
  showConfirmModal.value = true;
}

function printInvoice(customItems: any[], customTotal: number, invoiceNumber: string) {
  const invoiceData = {
    invoiceNo: invoiceNumber,
    date: new Date().toLocaleDateString('id-ID'),
    customerName: customerSearch.value || 'Guest',
    customerPhone: customerPhone.value,
    items: customItems,
    grandTotal: customTotal
  };
  const html = generateInvoiceHTML(invoiceData);
  const printWindow = window.open('', '_blank');
  if (printWindow) {
    printWindow.document.write(html);
    printWindow.document.close();
    setTimeout(() => printWindow.print(), 500);
  }
}

const vOutsideClick = {
  mounted(el: any, binding: any) {
    el.clickOutsideEvent = (event: Event) => {
      if (!(el === event.target || el.contains(event.target))) binding.value();
    };
    document.addEventListener('click', el.clickOutsideEvent);
  },
  unmounted(el: any) {
    document.removeEventListener('click', el.clickOutsideEvent);
  },
};

onMounted(safeFetchData);
</script>

<style scoped>
.sales-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
  padding-bottom: 100px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
}

.brand-tag {
  color: #f59e0b;
  letter-spacing: 0.25em;
  font-size: 0.7rem;
  font-weight: 800;
  margin-bottom: 8px;
  font-family: var(--font-ui);
  text-transform: uppercase;
  opacity: 0.9;
}

.hero-font {
  font-family: var(--font-headline);
  font-size: 2.8rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1.1;
}

.white-title { 
  color: white; 
}

@media (max-width: 1024px) {
  .hero-font {
    font-size: 2.2rem;
  }
}

/* ━━━ STOCK INDICATOR BAR (ELITE REDESIGN) ━━━ */
.stock-bar {
  display: flex;
  gap: 8px;
  padding: 6px 12px;
  border-radius: 100px;
  background: rgba(255, 255, 255, 0.02);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.05);
  box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.02);
}

.stock-chip {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 16px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid transparent;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.chip-icon {
  font-size: 14px;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
}

.chip-label {
  letter-spacing: 0.02em;
  opacity: 0.85;
}

.chip-val {
  font-family: 'DM Mono', monospace;
  font-weight: 700;
  font-size: 13px;
  letter-spacing: -0.02em;
  padding: 2px 8px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 6px;
  min-width: 24px;
  text-align: center;
}

/* Product Themes */
.stock-chip.hero { 
  background: rgba(245, 158, 11, 0.03); 
  color: #f59e0b; 
  border-color: rgba(245, 158, 11, 0.1);
}

.stock-chip.salted_egg { 
  background: rgba(56, 189, 248, 0.03); 
  color: #38bdf8; 
  border-color: rgba(56, 189, 248, 0.1);
}

/* ━━━ STATUS THEMES ━━━ */
.status-safe {
  background: rgba(16, 185, 129, 0.05) !important;
  color: #10b981 !important;
  border-color: rgba(16, 185, 129, 0.2) !important;
}

.status-low {
  background: rgba(245, 158, 11, 0.05) !important;
  color: #f59e0b !important;
  border-color: rgba(245, 158, 11, 0.2) !important;
}

.status-critical {
  background: rgba(239, 68, 68, 0.08) !important;
  color: #f87171 !important;
  border-color: rgba(239, 68, 68, 0.3) !important;
}

/* OUT OF STOCK BREATHING GLOW */
.out-of-stock-pulse {
  background: rgba(239, 68, 68, 0.06) !important;
  color: #f87171 !important;
  border-color: rgba(239, 68, 68, 0.4) !important;
  animation: breathing-glow 3s infinite ease-in-out;
}

.out-of-stock-pulse .chip-val {
  background: rgba(239, 68, 68, 0.15) !important;
  color: white !important;
}

@keyframes breathing-glow {
  0% { 
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.1);
    border-color: rgba(239, 68, 68, 0.3);
  }
  50% { 
    box-shadow: 0 0 15px 0 rgba(239, 68, 68, 0.2);
    border-color: rgba(239, 68, 68, 0.6);
  }
  100% { 
    box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.1);
    border-color: rgba(239, 68, 68, 0.3);
  }
}

/* LAYOUT */
.sales-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
  align-items: start;
}

.form-area {
  padding: 40px;
}

.step-indicator {
  font-size: 10px;
  font-weight: 800;
  color: #f59e0b;
  letter-spacing: 0.1em;
  margin-bottom: 16px;
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.field-col label {
  display: block;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--color-text-dim);
  margin-bottom: 8px;
}

.premium-input {
  width: 100%;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid var(--glass-border);
  padding: 14px 18px;
  border-radius: 12px;
  color: white;
  transition: all 0.3s ease;
}

.premium-input:focus {
  border-color: #f59e0b;
  background: rgba(255, 255, 255, 0.07);
  outline: none;
}

/* PKG GRID */
.pkg-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.pkg-card-v2 {
  background: #1a1a20;
  border: 1px solid var(--glass-border);
  border-radius: 16px;
  padding: 20px;
  cursor: pointer;
  position: relative;
  transition: all 0.3s ease;
  overflow: hidden;
}

.pkg-card-v2:hover:not(.out-of-stock) {
  background: #23232a;
}

.pkg-name { font-weight: 800; font-size: 0.9rem; color: #666; }
.pkg-available { font-size: 0.75rem; margin: 4px 0; font-weight: 600; }
.pkg-price { font-weight: 800; font-size: 1.1rem; color: white; margin-top: 12px; }

/* Grade Specific Themes */
.pkg-card-v2.hero_size .pkg-name { color: #f59e0b; }
.pkg-card-v2.hero_size .pkg-available { color: rgba(245, 158, 11, 0.7); }
.pkg-card-v2.hero_size.active { border-color: #f59e0b; box-shadow: 0 0 20px rgba(245, 158, 11, 0.15); }

.pkg-card-v2.standard_size .pkg-name { color: #8b5cf6; }
.pkg-card-v2.standard_size .pkg-available { color: rgba(139, 92, 246, 0.7); }
.pkg-card-v2.standard_size.active { border-color: #8b5cf6; box-shadow: 0 0 20px rgba(139, 92, 246, 0.15); }

.pkg-card-v2.small_size .pkg-name { color: #38bdf8; }
.pkg-card-v2.small_size .pkg-available { color: rgba(56, 189, 248, 0.7); }
.pkg-card-v2.small_size.active { border-color: #38bdf8; box-shadow: 0 0 20px rgba(56, 189, 248, 0.15); }

.pkg-card-v2.out-of-stock {
  opacity: 0.4;
  cursor: not-allowed;
}

.pkg-status-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  background: #ef4444;
  color: white;
  font-size: 9px;
  font-weight: 900;
  padding: 2px 6px;
  border-radius: 4px;
}

/* STEP 3 */
.qty-payment-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  align-items: center;
}

.stepper {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
}

.step-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.step-btn:hover:not(:disabled) { background: rgba(245, 158, 11, 0.1); }
.gold { color: #f59e0b; }

.step-input {
  background: transparent;
  border: none;
  color: white;
  font-weight: 800;
  font-size: 1.2rem;
  text-align: center;
  width: 60px;
}

.mono-total {
  font-family: 'JetBrains Mono', monospace;
  font-size: 24px;
  font-weight: 700;
  color: #f59e0b;
}

/* TOGGLE V2 */
.toggle-group-v2 {
  display: flex;
  gap: 12px;
  margin-top: 12px;
}

.toggle-v2 {
  flex: 1;
  padding: 14px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  color: var(--color-text-dim);
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
}

.toggle-v2.active {
  border-color: #f59e0b;
  color: white;
  background: rgba(245, 158, 11, 0.05);
}

.t-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: 1px solid #666;
}

.t-dot.filled {
  background: #f59e0b;
  border-color: #f59e0b;
  box-shadow: 0 0 10px #f59e0b;
}

/* DUE DATE ALERT */
.due-date-alert {
  background: rgba(245, 158, 11, 0.03);
  border: 1px dashed rgba(245, 158, 11, 0.2);
  padding: 24px;
  border-radius: 20px;
}

.alert-title { 
  font-size: 14px; 
  font-weight: 800; 
  color: #f59e0b; 
  margin-bottom: 16px; 
  display: flex;
  align-items: center;
  gap: 10px;
}

.alert-hint { 
  font-size: 11px; 
  color: rgba(255,255,255,0.4); 
  margin-top: 12px; 
}

.premium-input-date {
  width: 100%;
  background: #000;
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 14px 18px;
  border-radius: 12px;
  color: white;
  font-family: 'DM Mono', monospace;
  font-size: 1.1rem;
  font-weight: 600;
  outline: none;
  transition: all 0.3s ease;
  cursor: pointer;
}

.premium-input-date:focus {
  border-color: #f59e0b;
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.1);
}

/* Customizing the native calendar icon */
.premium-input-date::-webkit-calendar-picker-indicator {
  filter: invert(1);
  opacity: 0.5;
  cursor: pointer;
  transition: opacity 0.2s;
}

.premium-input-date::-webkit-calendar-picker-indicator:hover {
  opacity: 1;
}

/* CART SUMMARY V2 */
.cart-summary-v2 {
  padding: 32px;
  background: rgba(245, 158, 11, 0.02) !important;
}

.cs-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
.cs-count { font-size: 12px; font-weight: 800; color: #f59e0b; opacity: 0.8; }

.cs-items { display: flex; flex-direction: column; gap: 12px; }
.cs-line { display: flex; justify-content: space-between; align-items: center; font-size: 0.9rem; }
.cs-name { color: var(--color-text-dim); }
.cs-price { font-weight: 700; color: white; }
.cs-remove { background: none; border: none; color: #ef4444; font-size: 20px; cursor: pointer; padding: 0 8px; }

.cs-divider { height: 1px; background: rgba(255, 255, 255, 0.05); margin: 24px 0; }

.cs-totals { display: flex; flex-direction: column; gap: 8px; }
.cs-row { display: flex; justify-content: space-between; font-weight: 700; }
.cs-row.muted { opacity: 0.5; font-size: 0.8rem; }
.cs-row.profit { margin-top: 4px; border-top: 1px solid rgba(255,255,255,0.03); padding-top: 8px; }

/* INVOICE PREVIEW */
.preview-area {
  min-height: 600px;
  display: flex;
  flex-direction: column;
}

.empty-state-v2 {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  color: var(--color-text-dim);
}

.receipt-icon { margin-bottom: 24px; opacity: 0.1; }

.invoice-v2-paper {
  background: #111116 !important;
  padding: 40px;
  border-radius: 4px !important;
  border: 1px solid rgba(255, 255, 255, 0.05) !important;
}

.inv-v2-header { display: flex; justify-content: space-between; }
.gold-text { color: #f59e0b; }
.tagline { font-size: 10px; letter-spacing: 0.1em; opacity: 0.5; font-weight: 800; }
.inv-meta { text-align: right; font-size: 0.75rem; color: var(--color-text-dim); line-height: 1.6; }

.inv-v2-client label { font-size: 10px; font-weight: 800; color: #666; }
.inv-v2-client h3 { color: white; margin-top: 4px; }

.p-badge {
  font-size: 10px;
  font-weight: 800;
  padding: 4px 10px;
  border-radius: 4px;
  margin-right: 8px;
}
.p-badge.tunai { background: rgba(34, 197, 94, 0.1); color: #22c55e; }
.p-badge.piutang { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }

.due-badge { font-size: 10px; color: #666; font-weight: 600; }

.inv-v2-table { width: 100%; border-collapse: collapse; }
.inv-v2-table th { text-align: left; font-size: 10px; color: #666; border-bottom: 2px solid #222; padding-bottom: 12px; }
.inv-v2-table td { padding: 12px 0; border-bottom: 1px solid #222; font-size: 13px; color: #ccc; }

.inv-v2-footer { display: flex; justify-content: space-between; align-items: flex-end; }
.total-big label { font-size: 10px; font-weight: 800; color: #666; }
.total-big .val { font-size: 32px; font-weight: 900; color: #f59e0b; }
.profit-mini { text-align: right; }
.profit-mini label { font-size: 9px; font-weight: 800; color: #444; display: block; }
.success-text { color: #22c55e; font-weight: 700; }

/* UTILS */
.btn-gold-primary {
  background: #f59e0b;
  color: #000;
  border: none;
  padding: 16px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.btn-gold-primary:hover:not(:disabled) { background: #d97706; transform: translateY(-2px); }
.btn-gold-primary:disabled { opacity: 0.3; cursor: not-allowed; }

.btn-ghost {
  background: transparent;
  border: 1px solid var(--glass-border);
  color: white;
  padding: 14px;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
}

.btn-ghost:hover:not(:disabled) { background: rgba(255,255,255,0.05); }

.preview-actions { display: flex; gap: 16px; }

.search-input-wrapper {
  position: relative;
}

.search-results-menu {
  position: absolute;
  top: 100%;
  left: 0;
  width: 100%;
  z-index: 100;
  background: #111;
  border: 1px solid #333;
  margin-top: 5px;
  max-height: 200px;
  overflow-y: auto;
}

.result-item { padding: 12px; cursor: pointer; border-bottom: 1px solid #222; }
.result-item:hover { background: #222; }
.r-name { display: block; font-weight: 700; color: white; }
.r-phone { font-size: 11px; opacity: 0.5; }

.animate-pop { animation: pop 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
@keyframes pop {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

.slide-fade-enter-active { transition: all 0.3s ease-out; }
.slide-fade-enter-from { transform: translateY(20px); opacity: 0; }

.mt-32 { margin-top: 32px; }
.mt-24 { margin-top: 24px; }
.mt-16 { margin-top: 16px; }
.mt-12 { margin-top: 12px; }
.mt-40 { margin-top: 40px; }
.flex-1 { flex: 1; }
.text-right { text-align: right; }
.text-center { text-align: center; }
.spin { animation: spin 1s linear infinite; }

.skeleton-wrap { width: 100%; border: 1px dashed var(--glass-border); border-radius: 20px; }
.loading-hint { font-size: 0.8rem; font-weight: 700; color: #f59e0b; animation: pulse 1.5s infinite; }
@keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }

@keyframes spin { from {transform: rotate(0deg);} to {transform: rotate(360deg);} }

@media (max-width: 1024px) {
  .sales-grid { grid-template-columns: 1fr; gap: 24px; }
  .form-area { padding: 20px; }
  .field-row { grid-template-columns: 1fr; }
  .pkg-grid-3 { grid-template-columns: 1fr; }
  .qty-payment-row { grid-template-columns: 1fr; gap: 16px; }
  .preview-area { padding: 16px; min-height: auto; }
  .mobile-hidden { display: none; }
  
  .invoice-v2-paper { padding: 20px; }
  .invoice-v2-paper .inv-v2-header { flex-direction: column; gap: 12px; }
  .inv-meta { text-align: left; }
  .total-big .val { font-size: 24px; }
}

/* 📱 MOBILE STOCK NAV */
.mobile-stock-nav {
  display: flex;
  gap: 12px;
  padding: 12px;
  margin: -20px -20px 20px -20px;
}

.stock-chip-mini {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.05);
  font-family: var(--font-mono);
  font-size: 11px;
}

.stock-chip-mini.hero_size { color: var(--gold); }
.stock-chip-mini.standard_size { color: var(--violet); }
.stock-chip-mini.small_size { color: var(--sky); }
.stock-chip-mini.oos { opacity: 0.3; text-decoration: line-through; }

/* 📱 MOBILE STICKY ACTIONS */
.mobile-sticky-actions {
  position: fixed;
  bottom: 80px; /* Above BottomNav */
  left: 20px;
  right: 20px;
  background: rgba(20, 20, 24, 0.95);
  backdrop-filter: blur(10px);
  border: 1px solid var(--gold-active);
  padding: 16px;
  border-radius: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
  z-index: 100;
  animation: slideUp 0.3s ease-out;
}

.msa-info {
  display: flex;
  flex-direction: column;
}

.msa-label {
  font-size: 9px;
  font-weight: 800;
  color: var(--muted);
}

.msa-val {
  font-size: 1.1rem;
  font-weight: 900;
  color: var(--gold);
}

@keyframes slideUp {
  from { transform: translateY(100%); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

/* ─── RETRY BANNER ──────────────────────── */
.retry-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  margin-bottom: 16px;
  border-radius: 12px;
  background: rgba(245, 158, 11, 0.08);
  border: 1px solid rgba(245, 158, 11, 0.25);
  color: #fbbf24;
  font-size: 0.85rem;
  font-weight: 600;
}

.retry-dot {
  width: 8px;
  height: 8px;
  background: #f59e0b;
  border-radius: 50%;
  flex-shrink: 0;
}

/* ─── FETCH ERROR CARD ──────────────────── */
.fetch-error-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 48px 32px;
  border-radius: 16px;
  border: 1px solid rgba(239, 68, 68, 0.3);
  background: rgba(239, 68, 68, 0.05);
  margin-bottom: 24px;
}

.fec-icon { font-size: 3rem; margin-bottom: 16px; }
.fec-title { font-size: 1.2rem; font-weight: 700; color: #f87171; margin-bottom: 8px; }
.fec-desc { color: var(--muted); font-size: 0.85rem; max-width: 300px; }
.fec-hint { color: #64748b; font-size: 0.75rem; font-style: italic; }

.animate-fade-in { animation: fadeIn 0.4s ease forwards; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.animate-pop { animation: popIn 0.3s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.pulse { animation: pulse-ring 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite; }
@keyframes pulse-ring {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
