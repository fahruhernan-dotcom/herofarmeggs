<template>
  <div class="orders-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">LOGISTICS & REVENUE</h4>
        <h1 class="hero-font">Order Management</h1>
        <p class="text-dim">Track every sale and manage order fulfilling statuses.</p>
      </div>
      <div class="header-actions">
        <div class="date-filters glass-panel">
          <button 
            v-for="d in ['today', 'week', 'month', 'all']" 
            :key="d"
            class="filter-btn"
            :class="{ active: dateFilter === d }"
            @click="dateFilter = d"
          >
            {{ d === 'all' ? 'All Time' : d.charAt(0).toUpperCase() + d.slice(1) }}
          </button>
        </div>
        <router-link to="/sales" class="btn-primary">
          <PlusIcon class="icon" />
          <span>NEW ORDER ENTRY</span>
        </router-link>
      </div>
    </header>

    <!-- STATS SUMMARY -->
    <div class="stats-summary">
      <div class="summary-card glass-panel">
        <span class="s-label">Total Revenue</span>
        <span class="s-value">Rp {{ totalRevenue.toLocaleString() }}</span>
        <div class="s-trend pos" v-if="paidOrders.length > 0">{{ paidOrders.length }} paid order(s)</div>
      </div>
      <div class="summary-card glass-panel">
        <span class="s-label">Shown Orders</span>
        <span class="s-value">{{ baseDateFilteredOrders.length }}</span>
        <p class="s-subtext">Within selected filter</p>
      </div>
      <div class="summary-card glass-panel">
        <span class="s-label">Avg. Order Value</span>
        <span class="s-value">Rp {{ avgOrderValue.toLocaleString() }}</span>
      </div>
      <div class="summary-card glass-panel highlight-pending" v-if="pendingCount > 0">
        <span class="s-label">Needs Attention</span>
        <span class="s-value warn-value">{{ pendingCount }}</span>
        <p class="s-subtext warn-sub">Pending / On Delivery</p>
      </div>
    </div>

    <!-- STATUS FILTER TABS -->
    <div class="status-filter-bar">
      <button
        v-for="tab in statusTabs"
        :key="tab.value"
        class="filter-tab"
        :class="{ active: activeFilter === tab.value, [tab.value]: true }"
        @click="activeFilter = tab.value"
      >
        <component :is="tab.icon" class="tab-icon" />
        <span class="tab-label">{{ tab.label }}</span>
        <span class="tab-count" v-if="tab.count > 0">{{ tab.count }}</span>
      </button>
    </div>

    <!-- ORDERS TABLE -->
    <section class="orders-list glass-panel">
      <div class="list-header">
        <h3 class="panel-title">Order History</h3>
        <div class="filters">
          <div class="search-box">
            <SearchIcon class="search-icon" />
            <input type="text" v-model="searchQuery" placeholder="Search invoices..." />
          </div>
        </div>
      </div>

      <div class="table-container">
        <table class="premium-table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Items</th>
              <th>Total Amount</th>
              <th>Payment</th>
              <th>Fulfillment</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="order in filteredOrders" :key="order.id" class="order-row" :class="{ 'is-voided': order.payment_status === 'voided' }">
              <td class="order-id">
                <span v-if="order.payment_status === 'voided'" class="void-watermark">VOID</span>
                #INV-{{ order.id.toString().slice(-6).toUpperCase() }}
              </td>
              <td class="customer-info">
                <div class="cust-name">{{ order.customers?.name || 'Guest Customer' }}</div>
                <div class="cust-phone text-dim">{{ order.customers?.whatsapp_number || '-' }}</div>
              </td>
              <td class="date">{{ formatDate(order.created_at) }}</td>
              <td class="items-cell">
                <span class="items-count">{{ order.sale_items?.length || 0 }} Type(s)</span>
              </td>
              <td class="amount">Rp {{ (order.total_price || 0).toLocaleString() }}</td>
              <td>
                <button
                  class="status-badge-btn"
                  :class="order.payment_status"
                  @click="openStatusMenu(order, 'payment')"
                >
                  <span class="badge-dot"></span>
                  {{ formatStatusLabel(order.payment_status) }}
                  <ChevronDownIcon class="badge-chevron" />
                </button>
              </td>
              <td>
                <button
                  class="status-badge-btn"
                  :class="order.fulfillment_status || 'processing'"
                  @click="openStatusMenu(order, 'fulfillment')"
                >
                  <span class="badge-dot"></span>
                  {{ formatStatusLabel(order.fulfillment_status || 'processing') }}
                  <ChevronDownIcon class="badge-chevron" />
                </button>
              </td>
              <td class="actions">
                <button class="btn-icon" title="View Details" @click="viewOrderDetails(order)">
                  <EyeIcon class="icon-sm" />
                </button>
                <button class="btn-icon" title="Print Invoice" @click="printFromOrder(order)">
                  <PrinterIcon class="icon-sm" />
                </button>
              </td>
            </tr>
            <tr v-if="filteredOrders.length === 0">
              <td colspan="8" class="empty-state">
                <div class="empty-inner">
                  <PackageIcon class="empty-icon" />
                  <p>No orders found matching your criteria.</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- STATUS CHANGE DROPDOWN (Teleported) -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="statusMenu.show" class="status-dropdown-overlay" @click.self="closeStatusMenu">
          <div
            class="status-dropdown glass-panel"
            :style="{ top: statusMenu.y + 'px', left: statusMenu.x + 'px' }"
          >
            <div class="dropdown-header">
              <span class="dropdown-title">
                {{ statusMenu.type === 'payment' ? 'Payment Status' : 'Fulfillment Status' }}
              </span>
            </div>
            <div class="dropdown-options">
              <button
                v-for="opt in currentStatusOptions"
                :key="opt.value"
                class="dropdown-option"
                :class="{ active: currentStatusValue === opt.value, [opt.value]: true }"
                @click="updateStatus(opt.value)"
              >
                <span class="option-dot" :class="opt.value"></span>
                <div class="option-content">
                  <span class="option-label">{{ opt.label }}</span>
                  <span class="option-desc">{{ opt.description }}</span>
                </div>
                <CheckIcon v-if="currentStatusValue === opt.value" class="option-check" />
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ORDER DETAIL MODAL -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="selectedOrder" class="modal-overlay" @click.self="selectedOrder = null">
          <div class="modal-card glass-panel animate-pop details-modal">
            <div class="modal-header">
              <h2 class="hero-font">Order Details</h2>
              <button class="close-btn" @click="selectedOrder = null">&times;</button>
            </div>

            <div class="modal-body">
              <div class="invoice-header-mini">
                <div class="meta">
                  <p class="label">Invoice ID</p>
                  <p class="value">#INV-{{ selectedOrder.id.toString().slice(-6).toUpperCase() }}</p>
                </div>
                <div class="meta text-right">
                  <p class="label">Placed On</p>
                  <p class="value">{{ new Date(selectedOrder.created_at).toLocaleString('id-ID') }}</p>
                </div>
              </div>

              <!-- Status Cards in Modal -->
              <div class="modal-status-row">
                <div class="modal-status-card" :class="selectedOrder.payment_status">
                  <span class="msc-label">Payment</span>
                  <div class="msc-badge">
                    <span class="badge-dot"></span>
                    {{ formatStatusLabel(selectedOrder.payment_status) }}
                  </div>
                </div>
                <div class="modal-status-card" :class="selectedOrder.fulfillment_status || 'processing'">
                  <span class="msc-label">Fulfillment</span>
                  <div class="msc-badge">
                    <span class="badge-dot"></span>
                    {{ formatStatusLabel(selectedOrder.fulfillment_status || 'processing') }}
                  </div>
                </div>
              </div>

              <div class="customer-details-box glass-panel">
                <label>BILLING TO</label>
                <h3>{{ selectedOrder.customers?.name || 'Guest Customer' }}</h3>
                <p class="text-dim">{{ selectedOrder.customers?.whatsapp_number || 'No phone provided' }}</p>
                <p class="text-dim">{{ selectedOrder.customers?.address || 'No address provided' }}</p>
              </div>

              <table class="items-table">
                <thead>
                  <tr>
                    <th>Product</th>
                    <th>Qty</th>
                    <th>Unit Price</th>
                    <th>Subtotal</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in selectedOrder.sale_items" :key="item.id">
                    <td class="item-label">
                      {{ formatEggType(item.egg_type) }}
                      <span v-if="hasPriceOverride(selectedOrder, item.egg_type)" class="override-badge" title="Price manually overridden">★ EDITED</span>
                    </td>
                    <td>{{ item.quantity }} Pack</td>
                    <td>
                      <div class="price-stack">
                        <span class="actual-price">Rp {{ (item.unit_price || 0).toLocaleString() }}</span>
                        <span v-if="hasPriceOverride(selectedOrder, item.egg_type)" class="original-price strike">
                          Rp {{ getOriginalPrice(selectedOrder, item.egg_type).toLocaleString() }}
                        </span>
                      </div>
                    </td>
                    <td class="item-subtotal">Rp {{ (item.subtotal || 0).toLocaleString() }}</td>
                  </tr>
                </tbody>
                <tfoot>
                  <tr class="total-row">
                    <td colspan="3">Grand Total</td>
                    <td class="grand-total">Rp {{ (selectedOrder.total_price || 0).toLocaleString() }}</td>
                  </tr>
                </tfoot>
              </table>

              <!-- VOIDED WATERMARK IN MODAL -->
              <div v-if="selectedOrder.payment_status === 'voided'" class="void-banner-modal">
                <BanIcon class="icon-md" />
                <span>THIS TRANSACTION HAS BEEN VOIDED</span>
              </div>

              <!-- Quick Status Update in Modal -->
              <div class="modal-quick-actions" v-if="selectedOrder.payment_status !== 'voided'">
                <h4 class="quick-title">Quick Status Update</h4>
                <div class="quick-btns-row">
                  <button
                    v-for="opt in paymentOptions"
                    :key="'p-' + opt.value"
                    class="quick-status-btn"
                    :class="{ active: selectedOrder.payment_status === opt.value, [opt.value]: true }"
                    @click="quickUpdateStatus(selectedOrder, 'payment_status', opt.value)"
                  >
                    <component :is="opt.icon" class="qs-icon" />
                    {{ opt.label }}
                  </button>
                </div>
                <div class="quick-btns-row mt-12">
                  <button
                    v-for="opt in fulfillmentOptions"
                    :key="'f-' + opt.value"
                    class="quick-status-btn"
                    :class="{ active: (selectedOrder.fulfillment_status || 'processing') === opt.value, [opt.value]: true }"
                    @click="quickUpdateStatus(selectedOrder, 'fulfillment_status', opt.value)"
                  >
                    <component :is="opt.icon" class="qs-icon" />
                    {{ opt.label }}
                  </button>
                </div>
              </div>

              <!-- VOID ACTION (ADMIN ONLY) -->
              <div class="void-action-section" v-if="authStore.profile?.role === 'admin' && selectedOrder.payment_status !== 'voided'">
                <button class="btn-void" @click="handleVoid(selectedOrder)" :disabled="updatingStatus">
                  <LockIcon v-if="!updatingStatus" class="icon-sm" />
                  <Loader2Icon v-else class="icon-sm spin" />
                  <span>VOID TRANSACTION</span>
                </button>
                <p class="void-hint">Restores stock and subtracts from customer total spent.</p>
              </div>
            </div>

            <div class="modal-actions">
              <button class="btn-secondary" @click="selectedOrder = null">Close</button>
              <button class="btn-primary" @click="printFromOrder(selectedOrder)">
                <PrinterIcon class="icon" />
                <span>REPRINT INVOICE</span>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- TOAST NOTIFICATION -->
    <Teleport to="body">
      <Transition name="toast-slide">
        <div v-if="toast.show" class="toast-notification" :class="toast.type">
          <CheckCircle2Icon v-if="toast.type === 'success'" class="toast-icon" />
          <AlertCircleIcon v-if="toast.type === 'error'" class="toast-icon" />
          <div class="toast-content">
            <span class="toast-title">{{ toast.title }}</span>
            <span class="toast-msg">{{ toast.message }}</span>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, markRaw } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { generateInvoiceHTML } from '../utils/invoiceTemplate';
import {
  PlusIcon,
  SearchIcon,
  EyeIcon,
  PrinterIcon,
  ChevronDownIcon,
  CheckIcon,
  PackageIcon,
  ListIcon,
  ClockIcon,
  CheckCircle2Icon,
  TruckIcon,
  AlertCircleIcon,
  BanIcon,
  CircleCheckBigIcon,
  WalletIcon,
  TimerIcon,
  LockIcon,
  Loader2Icon
} from 'lucide-vue-next';

const authStore = useAuthStore();

// ─── STATE ─────────────────────────
const orders = ref<any[]>([]);
const searchQuery = ref('');
const selectedOrder = ref<any>(null);
const activeFilter = ref('all');
const dateFilter = ref('month'); // Default to this month for performance/relevance
const updatingStatus = ref(false);

// Status menu state
const statusMenu = ref({
  show: false,
  order: null as any,
  type: '' as 'payment' | 'fulfillment',
  x: 0,
  y: 0
});

// Toast notification
const toast = ref({
  show: false,
  title: '',
  message: '',
  type: 'success' as 'success' | 'error'
});

// ─── STATUS OPTIONS ─────────────────
const paymentOptions = [
  {
    value: 'pending',
    label: 'Pending',
    description: 'Payment not yet received',
    icon: markRaw(ClockIcon)
  },
  {
    value: 'paid',
    label: 'Paid',
    description: 'Payment confirmed',
    icon: markRaw(CheckCircle2Icon)
  },
  {
    value: 'cancelled',
    label: 'Cancelled',
    description: 'Order cancelled',
    icon: markRaw(BanIcon)
  }
];

const fulfillmentOptions = [
  {
    value: 'processing',
    label: 'Processing',
    description: 'Order is being prepared',
    icon: markRaw(TimerIcon)
  },
  {
    value: 'on_delivery',
    label: 'On Delivery',
    description: 'Out for delivery',
    icon: markRaw(TruckIcon)
  },
  {
    value: 'delivered',
    label: 'Delivered',
    description: 'Successfully delivered',
    icon: markRaw(CircleCheckBigIcon)
  }
];

const eggTypeLabels: Record<string, string> = {
  'hero_size': 'Hero Premium Size (Pack)',
  'standard_size': 'Hero Standard Size (Pack)',
  'salted_egg': 'Hero Salted Eggs (Pack)',
  'packaging_standard': 'Packaging Box',
  'sticker_label': 'Sticker Label',
  'mini_card': 'Hero Mini Card'
};

function formatEggType(type: string) {
  return eggTypeLabels[type] || type;
}

// ─── COMPUTED ───────────────────────
const baseDateFilteredOrders = computed(() => {
  let result = orders.value;

  // Filter by date
  if (dateFilter.value !== 'all') {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    result = result.filter(o => {
      // ALWAYS include pending or on-delivery orders regardless of date
      const isImportant = o.payment_status === 'pending' || (o.fulfillment_status || 'processing') === 'on_delivery';
      if (isImportant) return true;

      const orderDate = new Date(o.created_at);
      if (dateFilter.value === 'today') {
        return orderDate >= startOfToday;
      } else if (dateFilter.value === 'week') {
        const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
        startOfWeek.setHours(0,0,0,0);
        return orderDate >= startOfWeek;
      } else if (dateFilter.value === 'month') {
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        return orderDate >= startOfMonth;
      }
      return true;
    });
  }
  return result;
});

const statusTabs = computed(() => {
  const source = baseDateFilteredOrders.value;
  return [
    { value: 'all', label: 'All Orders', icon: markRaw(ListIcon), count: source.length },
    { value: 'pending', label: 'Pending', icon: markRaw(ClockIcon), count: source.filter(o => o.payment_status === 'pending').length },
    { value: 'paid', label: 'Paid', icon: markRaw(WalletIcon), count: source.filter(o => o.payment_status === 'paid').length },
    { value: 'on_delivery', label: 'On Delivery', icon: markRaw(TruckIcon), count: source.filter(o => (o.fulfillment_status || 'processing') === 'on_delivery').length },
    { value: 'delivered', label: 'Delivered', icon: markRaw(CircleCheckBigIcon), count: source.filter(o => (o.fulfillment_status || 'processing') === 'delivered').length },
    { value: 'cancelled', label: 'Cancelled', icon: markRaw(BanIcon), count: source.filter(o => o.payment_status === 'cancelled').length }
  ];
});

const filteredOrders = computed(() => {
  let result = baseDateFilteredOrders.value;

  // Filter by status tab
  if (activeFilter.value !== 'all') {
    if (['pending', 'paid', 'cancelled'].includes(activeFilter.value)) {
      result = result.filter(o => o.payment_status === activeFilter.value);
    } else if (activeFilter.value === 'on_delivery') {
      result = result.filter(o => (o.fulfillment_status || 'processing') === 'on_delivery');
    } else if (activeFilter.value === 'delivered') {
      result = result.filter(o => (o.fulfillment_status || 'processing') === 'delivered');
    }
  }

  // Filter by search
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter(o =>
      o.id.toString().includes(q) ||
      (o.customers?.name && o.customers.name.toLowerCase().includes(q))
    );
  }

  return result;
});

// ─── FETCH ──────────────────────────
async function fetchOrders() {
  const { data, error } = await supabase
    .from('sales')
    .select(`
      id,
      total_price,
      payment_status,
      fulfillment_status,
      stock_reserved,
      created_at,
      customers!sales_customer_id_fkey (
        name,
        whatsapp_number,
        address
      ),
      sale_items (*),
      price_overrides (*)
    `)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Fetch Orders Error:', error);
    showToast('Error', 'Failed to load orders: ' + error.message, 'error');
  }
  if (data) orders.value = data || [];
}

const totalRevenue = computed(() => {
  return baseDateFilteredOrders.value
    .filter(o => o.payment_status === 'paid')
    .reduce((acc, curr) => acc + (curr.total_price || 0), 0);
});

const paidOrders = computed(() => baseDateFilteredOrders.value.filter(o => o.payment_status === 'paid'));

const avgOrderValue = computed(() => {
  if (baseDateFilteredOrders.value.length === 0) return 0;
  const total = baseDateFilteredOrders.value.reduce((acc, curr) => acc + (curr.total_price || 0), 0);
  return Math.round(total / baseDateFilteredOrders.value.length);
});

const pendingCount = computed(() => {
  return baseDateFilteredOrders.value.filter(o =>
    o.payment_status === 'pending' ||
    (o.fulfillment_status || 'processing') === 'on_delivery'
  ).length;
});

const currentStatusOptions = computed(() => {
  return statusMenu.value.type === 'payment' ? paymentOptions : fulfillmentOptions;
});

const currentStatusValue = computed(() => {
  if (!statusMenu.value.order) return '';
  if (statusMenu.value.type === 'payment') return statusMenu.value.order.payment_status;
  return statusMenu.value.order.fulfillment_status || 'processing';
});

// ─── METHODS ────────────────────────
function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
}



function formatStatusLabel(status: string) {
  const map: Record<string, string> = {
    pending: 'Pending',
    paid: 'Paid',
    cancelled: 'Cancelled',
    processing: 'Processing',
    on_delivery: 'On Delivery',
    delivered: 'Delivered',
    voided: 'Voided'
  };
  return map[status] || status;
}

function hasPriceOverride(order: any, eggType: string) {
  if (!order || !order.price_overrides) return false;
  return order.price_overrides.some((o: any) => o.product_id === eggType);
}

function getOriginalPrice(order: any, eggType: string) {
  if (!order || !order.price_overrides) return 0;
  const override = order.price_overrides.find((o: any) => o.product_id === eggType);
  return override ? Number(override.original_price) : 0;
}

async function handleCancelOrderStock(order: any) {
  if (!order.stock_reserved) return;

  const items = order.sale_items || [];
  for (const item of items) {
    const quantityInButir = (item.quantity || 0) * 10;
    
    // Increment Egg Stock
    const { data: inv } = await supabase.from('inventory').select('current_stock').eq('id', item.egg_type).single();
    if (inv) {
      await supabase.from('inventory').update({ 
        current_stock: inv.current_stock + quantityInButir 
      }).eq('id', item.egg_type);
    }

    // Log restoration
    await supabase.from('stock_logs').insert({
      egg_type: item.egg_type,
      change: quantityInButir,
      log_type: 'void_return',
      notes: `Stock Restored from Cancelled/Void Order #${order.id.toString().slice(-6).toUpperCase()}`
    });
  }

  // Restore Supply Stock (1 Box, 1 Sticker, 1 Card per pack)
  const totalPacks = items.reduce((sum: number, i: any) => sum + (i.quantity || 0), 0);
  const supplies = ['packaging_standard', 'sticker_label', 'mini_card'];
  for (const sId of supplies) {
    const { data: sInv } = await supabase.from('inventory').select('current_stock').eq('id', sId).single();
    if (sInv) {
      await supabase.from('inventory').update({ 
        current_stock: sInv.current_stock + totalPacks 
      }).eq('id', sId);
    }
  }

  // We do not do the UPDATE to sales table here inside the loop. 
  // We will let the caller update `stock_reserved` and `cancelled_at` together with the status change.
}

async function handleVoid(order: any) {
  if (!confirm('CRITICAL ACTION: This will void the invoice, RESTORE ALL STOCK, and subtract from customer spent. Proceed?')) return;
  
  updatingStatus.value = true;
  try {
    // 1. Mark as Voided
    const { error: voidError } = await supabase
      .from('sales')
      .update({ payment_status: 'voided', stock_reserved: false, cancelled_at: new Date().toISOString() })
      .eq('id', order.id);

    if (voidError) throw voidError;

    // 2. Restore Stock (Eggs & Supplies)
    if (order.stock_reserved) {
      await handleCancelOrderStock(order);
      order.stock_reserved = false;
    }

    // 3. Sync Customer Totals (RPC)
    if (order.customer_id) {
      await supabase.rpc('sync_customer_totals', { target_customer_id: order.customer_id });
    }

    // Refresh data
    await fetchOrders();
    selectedOrder.value = orders.value.find(o => o.id === order.id);

    showToast('Transaction Voided', 'Stock restored and LTV updated.', 'success');
  } catch (err: any) {
    showToast('Void Failed', err.message, 'error');
  } finally {
    updatingStatus.value = false;
  }
}

function viewOrderDetails(order: any) {
  selectedOrder.value = { ...order };
}

function openStatusMenu(order: any, type: 'payment' | 'fulfillment') {
  // Use viewport center for the dropdown
  statusMenu.value = {
    show: true,
    order,
    type,
    x: Math.min(window.innerWidth / 2 - 150, window.innerWidth - 340),
    y: Math.min(window.innerHeight / 2 - 120, window.innerHeight - 300)
  };
}

function closeStatusMenu() {
  statusMenu.value.show = false;
}

async function updateStatus(newValue: string) {
  if (updatingStatus.value) return;
  updatingStatus.value = true;

  const order = statusMenu.value.order;
  const field = statusMenu.value.type === 'payment' ? 'payment_status' : 'fulfillment_status';

  try {
    const updatePayload: any = { [field]: newValue };
    
    // Clear reservation if delivered
    if (field === 'fulfillment_status' && newValue === 'delivered') {
      updatePayload.stock_reserved = false;
    }
    
    // Clear reservation and restore stock if cancelled
    if ((field === 'payment_status' && newValue === 'cancelled') || 
        (field === 'fulfillment_status' && newValue === 'cancelled')) {
      updatePayload.stock_reserved = false;
      updatePayload.cancelled_at = new Date().toISOString();
      
      if (order.stock_reserved) {
        await handleCancelOrderStock(order);
        order.stock_reserved = false;
      }
    }

    const { error } = await supabase
      .from('sales')
      .update(updatePayload)
      .eq('id', order.id);

    if (error) throw error;

    // Update local state
    const idx = orders.value.findIndex(o => o.id === order.id);
    if (idx !== -1) {
      orders.value[idx][field] = newValue;
    }

    // Update selectedOrder if it's the same order
    if (selectedOrder.value && selectedOrder.value.id === order.id) {
      selectedOrder.value[field] = newValue;
    }

    showToast(
      'Status Updated',
      `${statusMenu.value.type === 'payment' ? 'Payment' : 'Fulfillment'} → ${formatStatusLabel(newValue)}`,
      'success'
    );
  } catch (e: any) {
    showToast('Update Failed', e.message, 'error');
  } finally {
    updatingStatus.value = false;
    closeStatusMenu();
  }
}

async function quickUpdateStatus(order: any, field: string, newValue: string) {
  if (updatingStatus.value) return;
  updatingStatus.value = true;

  try {
    const updatePayload: any = { [field]: newValue };
    
    // Clear reservation if delivered
    if (field === 'fulfillment_status' && newValue === 'delivered') {
      updatePayload.stock_reserved = false;
    }
    
    // Clear reservation and restore stock if cancelled / voided
    if ((field === 'payment_status' && (newValue === 'cancelled' || newValue === 'voided')) || 
        (field === 'fulfillment_status' && newValue === 'cancelled')) {
      updatePayload.stock_reserved = false;
      updatePayload.cancelled_at = new Date().toISOString();
      
      if (order.stock_reserved) {
        await handleCancelOrderStock(order);
        order.stock_reserved = false;
      }
    }

    const { error } = await supabase
      .from('sales')
      .update(updatePayload)
      .eq('id', order.id);

    if (error) throw error;

    // Update local state
    const idx = orders.value.findIndex(o => o.id === order.id);
    if (idx !== -1) {
      orders.value[idx][field] = newValue;
    }

    // Update the modal view
    if (selectedOrder.value && selectedOrder.value.id === order.id) {
      selectedOrder.value[field] = newValue;
    }

    const typeLabel = field === 'payment_status' ? 'Payment' : 'Fulfillment';
    showToast('Status Updated', `${typeLabel} → ${formatStatusLabel(newValue)}`, 'success');
  } catch (e: any) {
    showToast('Update Failed', e.message, 'error');
  } finally {
    updatingStatus.value = false;
  }
}

function printFromOrder(order: any) {
  const invoiceData = {
    invoiceNo: `EP-${new Date(order.created_at).getFullYear()}${String(new Date(order.created_at).getMonth() + 1).padStart(2, '0')}${String(new Date(order.created_at).getDate()).padStart(2, '0')}${String(order.id).slice(-3).toUpperCase()}`,
    date: new Date(order.created_at).toLocaleDateString('id-ID'),
    customerName: order.customers?.name || 'Guest Customer',
    customerPhone: order.customers?.whatsapp_number || '',
    items: (order.sale_items || []).map((item: any) => ({
      description: formatEggType(item.egg_type),
      quantity: item.quantity,
      unit: 'Pack',
      price: item.unit_price,
      total: item.subtotal
    })),
    grandTotal: order.total_price || 0
  };

  const html = generateInvoiceHTML(invoiceData);
  const printWindow = window.open('', '_blank');
  if (printWindow) {
    printWindow.document.write(html);
    printWindow.document.close();
    setTimeout(() => {
      printWindow.print();
    }, 500);
  }
}

function showToast(title: string, message: string, type: 'success' | 'error') {
  toast.value = { show: true, title, message, type };
  setTimeout(() => {
    toast.value.show = false;
  }, 3000);
}

let refreshInterval: any;

onMounted(() => {
  fetchOrders();
  refreshInterval = setInterval(fetchOrders, 10000);
});

onUnmounted(() => {
  clearInterval(refreshInterval);
});
</script>

<style scoped>
.orders-page {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
  margin-bottom: 32px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 20px;
}

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  margin-bottom: 8px;
}

.text-dim { color: var(--color-text-dim); }

/* ─── STATS ──────────────────── */
.stats-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.summary-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.summary-card.highlight-pending {
  border-color: rgba(255, 140, 0, 0.3);
  background: rgba(255, 140, 0, 0.04);
}

.s-label { font-size: 0.75rem; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.05em; }
.s-value { font-size: 1.8rem; font-weight: 800; color: white; }
.s-trend { font-size: 0.75rem; font-weight: 700; }
.s-trend.pos { color: var(--color-success); }
.s-subtext { font-size: 0.75rem; color: var(--color-text-dim); }
.warn-value { color: var(--color-primary); }
.warn-sub { color: var(--color-primary); opacity: 0.8; }

/* ─── STATUS FILTER TABS ──────── */
.status-filter-bar {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  scrollbar-width: none;
  padding-bottom: 4px;
}

.status-filter-bar::-webkit-scrollbar { display: none; }

.filter-tab {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 12px;
  color: var(--color-text-dim);
  cursor: pointer;
  font-family: var(--font-body);
  font-size: 0.8rem;
  font-weight: 600;
  white-space: nowrap;
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
}

.filter-tab:hover {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.15);
  color: white;
}

.filter-tab.active {
  background: rgba(255, 140, 0, 0.1);
  border-color: rgba(255, 140, 0, 0.4);
  color: var(--color-primary);
}

.filter-tab.active .tab-icon { color: var(--color-primary); }

.tab-icon { width: 16px; height: 16px; }

.tab-count {
  background: rgba(255, 255, 255, 0.1);
  padding: 2px 8px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 800;
  min-width: 24px;
  text-align: center;
}

.filter-tab.active .tab-count {
  background: rgba(255, 140, 0, 0.2);
  color: var(--color-primary);
}

/* ─── ORDERS TABLE ────────────── */
.orders-list {
  padding: 28px;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.panel-title {
  font-size: 1rem;
  letter-spacing: 0.05em;
  color: var(--color-text-dim);
  text-transform: uppercase;
}

.search-box {
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  padding: 8px 16px;
  border-radius: var(--radius-md);
}

.search-icon { width: 16px; height: 16px; color: var(--color-text-dim); }
.search-box input {
  background: transparent;
  border: none;
  color: white;
  font-family: var(--font-body);
  outline: none;
  font-size: 0.9rem;
}

.table-container { overflow-x: auto; }

.premium-table {
  width: 100%;
  border-collapse: collapse;
}

.premium-table th {
  text-align: left;
  padding: 14px 16px;
  font-size: 0.7rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid var(--glass-border);
}

.premium-table td {
  padding: 14px 16px;
  font-size: 0.85rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
  vertical-align: middle;
}

.order-row {
  transition: background 0.2s ease;
}

.order-row:hover {
  background: rgba(255, 255, 255, 0.02);
}

.order-id { font-family: 'JetBrains Mono', monospace; font-weight: 700; color: var(--color-primary); font-size: 0.8rem; }
.cust-name { font-weight: 700; font-size: 0.85rem; }
.cust-phone { font-size: 0.75rem; }
.amount { font-weight: 800; }

/* ─── STATUS BADGE BUTTON ──────── */
.status-badge-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px 12px;
  border-radius: 8px;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  cursor: pointer;
  border: 1px solid transparent;
  transition: all 0.3s ease;
  font-family: var(--font-body);
  white-space: nowrap;
}

.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.badge-chevron {
  width: 12px;
  height: 12px;
  opacity: 0.5;
  transition: opacity 0.2s;
}

.status-badge-btn:hover .badge-chevron { opacity: 1; }

/* Payment: Pending */
.status-badge-btn.pending {
  background: rgba(255, 170, 0, 0.1);
  color: #FFAA00;
  border-color: rgba(255, 170, 0, 0.2);
}
.status-badge-btn.pending .badge-dot { background: #FFAA00; box-shadow: 0 0 6px #FFAA00; }
.status-badge-btn.pending:hover { background: rgba(255, 170, 0, 0.15); border-color: rgba(255, 170, 0, 0.4); }

/* Payment: Paid */
.status-badge-btn.paid {
  background: rgba(0, 255, 157, 0.08);
  color: var(--color-success);
  border-color: rgba(0, 255, 157, 0.2);
}
.status-badge-btn.paid .badge-dot { background: var(--color-success); box-shadow: 0 0 6px var(--color-success); }
.status-badge-btn.paid:hover { background: rgba(0, 255, 157, 0.12); border-color: rgba(0, 255, 157, 0.35); }

/* Cancelled */
.status-pill.cancelled { background: rgba(255, 66, 66, 0.1); color: var(--color-error); }

/* DATE FILTERS */
.date-filters {
  display: flex;
  padding: 4px;
  gap: 4px;
}

.date-filters .filter-btn {
  padding: 8px 16px;
  font-size: 0.75rem;
  font-weight: 700;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: var(--color-text-dim);
  cursor: pointer;
  transition: all 0.3s ease;
  text-transform: uppercase;
}

.date-filters .filter-btn:hover {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.date-filters .filter-btn.active {
  background: var(--color-primary);
  color: white;
  box-shadow: 0 0 10px rgba(255, 140, 0, 0.3);
}

.spin { animation: spin 1s linear infinite; }
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Cancelled */
.status-badge-btn.cancelled {
  background: rgba(255, 62, 62, 0.08);
  color: var(--color-error);
  border-color: rgba(255, 62, 62, 0.2);
}
.status-badge-btn.cancelled .badge-dot { background: var(--color-error); box-shadow: 0 0 6px var(--color-error); }
.status-badge-btn.cancelled:hover { background: rgba(255, 62, 62, 0.12); border-color: rgba(255, 62, 62, 0.35); }

/* Fulfillment: Processing */
.status-badge-btn.processing {
  background: rgba(100, 149, 237, 0.1);
  color: #6495ED;
  border-color: rgba(100, 149, 237, 0.2);
}
.status-badge-btn.processing .badge-dot { background: #6495ED; box-shadow: 0 0 6px #6495ED; }
.status-badge-btn.processing:hover { background: rgba(100, 149, 237, 0.15); border-color: rgba(100, 149, 237, 0.4); }

/* Fulfillment: On Delivery */
.status-badge-btn.on_delivery {
  background: rgba(255, 140, 0, 0.1);
  color: var(--color-primary);
  border-color: rgba(255, 140, 0, 0.2);
}
.status-badge-btn.on_delivery .badge-dot { background: var(--color-primary); box-shadow: 0 0 6px var(--color-primary); animation: pulse-dot 2s infinite; }
.status-badge-btn.on_delivery:hover { background: rgba(255, 140, 0, 0.15); border-color: rgba(255, 140, 0, 0.4); }

/* Fulfillment: Delivered */
.status-badge-btn.delivered {
  background: rgba(0, 255, 157, 0.08);
  color: var(--color-success);
  border-color: rgba(0, 255, 157, 0.2);
}
.status-badge-btn.delivered .badge-dot { background: var(--color-success); box-shadow: 0 0 6px var(--color-success); }
.status-badge-btn.delivered:hover { background: rgba(0, 255, 157, 0.12); border-color: rgba(0, 255, 157, 0.35); }

@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

/* ─── ACTIONS ──────────────────── */
.actions { display: flex; gap: 8px; }

.btn-icon {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 8px;
  color: var(--color-text-dim);
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-icon:hover {
  background: var(--color-primary-glow);
  color: var(--color-primary);
  border-color: var(--color-primary);
}

.empty-state {
  text-align: center;
  padding: 48px;
  color: var(--color-text-dim);
}

.empty-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.empty-icon {
  width: 48px;
  height: 48px;
  opacity: 0.3;
}

/* ─── STATUS DROPDOWN ──────────── */
.status-dropdown-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(4px);
  z-index: 2000;
  display: flex;
  justify-content: center;
  align-items: center;
}

.status-dropdown {
  position: fixed;
  width: 300px;
  padding: 8px;
  z-index: 2001;
  animation: dropIn 0.25s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes dropIn {
  from { opacity: 0; transform: translateY(-8px) scale(0.96); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.dropdown-header {
  padding: 12px 16px 8px;
}

.dropdown-title {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
}

.dropdown-options {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.dropdown-option {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border: none;
  border-radius: 10px;
  background: transparent;
  color: var(--color-text);
  cursor: pointer;
  transition: all 0.2s ease;
  font-family: var(--font-body);
  text-align: left;
  width: 100%;
}

.dropdown-option:hover {
  background: rgba(255, 255, 255, 0.06);
}

.dropdown-option.active {
  background: rgba(255, 140, 0, 0.08);
  border: 1px solid rgba(255, 140, 0, 0.15);
}

.option-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.option-dot.pending { background: #FFAA00; box-shadow: 0 0 8px rgba(255, 170, 0, 0.5); }
.option-dot.paid { background: var(--color-success); box-shadow: 0 0 8px rgba(0, 255, 157, 0.5); }
.option-dot.cancelled { background: var(--color-error); box-shadow: 0 0 8px rgba(255, 62, 62, 0.5); }
.option-dot.processing { background: #6495ED; box-shadow: 0 0 8px rgba(100, 149, 237, 0.5); }
.option-dot.on_delivery { background: var(--color-primary); box-shadow: 0 0 8px rgba(255, 140, 0, 0.5); }
.option-dot.delivered { background: var(--color-success); box-shadow: 0 0 8px rgba(0, 255, 157, 0.5); }

.option-content {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.option-label { font-weight: 700; font-size: 0.85rem; }
.option-desc { font-size: 0.7rem; color: var(--color-text-dim); }

.option-check {
  width: 16px;
  height: 16px;
  color: var(--color-primary);
}

/* ─── MODAL ────────────────────── */
.details-modal {
  max-width: 650px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  padding: 32px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 28px;
}

.close-btn {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 2rem;
  cursor: pointer;
  transition: color 0.2s;
}

.close-btn:hover { color: white; }

.invoice-header-mini {
  display: flex;
  justify-content: space-between;
  margin-bottom: 20px;
}

.invoice-header-mini .label { font-size: 0.65rem; text-transform: uppercase; color: var(--color-text-dim); }
.invoice-header-mini .value { font-weight: 800; font-size: 1.1rem; }

/* Modal Status Row */
.modal-status-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 20px;
}

.modal-status-card {
  padding: 14px 18px;
  border-radius: 12px;
  border: 1px solid var(--glass-border);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal-status-card.paid { background: rgba(0, 255, 157, 0.04); border-color: rgba(0, 255, 157, 0.15); }
.modal-status-card.pending { background: rgba(255, 170, 0, 0.04); border-color: rgba(255, 170, 0, 0.15); }
.modal-status-card.cancelled { background: rgba(255, 62, 62, 0.04); border-color: rgba(255, 62, 62, 0.15); }
.modal-status-card.processing { background: rgba(100, 149, 237, 0.04); border-color: rgba(100, 149, 237, 0.15); }
.modal-status-card.on_delivery { background: rgba(255, 140, 0, 0.04); border-color: rgba(255, 140, 0, 0.15); }
.modal-status-card.delivered { background: rgba(0, 255, 157, 0.04); border-color: rgba(0, 255, 157, 0.15); }

.msc-label {
  font-size: 0.6rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
  font-weight: 700;
}

.msc-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 800;
  font-size: 0.85rem;
}

.modal-status-card.paid .msc-badge { color: var(--color-success); }
.modal-status-card.paid .msc-badge .badge-dot { background: var(--color-success); box-shadow: 0 0 6px var(--color-success); }
.modal-status-card.pending .msc-badge { color: #FFAA00; }
.modal-status-card.pending .msc-badge .badge-dot { background: #FFAA00; box-shadow: 0 0 6px #FFAA00; }
.modal-status-card.cancelled .msc-badge { color: var(--color-error); }
.modal-status-card.cancelled .msc-badge .badge-dot { background: var(--color-error); box-shadow: 0 0 6px var(--color-error); }
.modal-status-card.processing .msc-badge { color: #6495ED; }
.modal-status-card.processing .msc-badge .badge-dot { background: #6495ED; box-shadow: 0 0 6px #6495ED; }
.modal-status-card.on_delivery .msc-badge { color: var(--color-primary); }
.modal-status-card.on_delivery .msc-badge .badge-dot { background: var(--color-primary); box-shadow: 0 0 6px var(--color-primary); }
.modal-status-card.delivered .msc-badge { color: var(--color-success); }
.modal-status-card.delivered .msc-badge .badge-dot { background: var(--color-success); box-shadow: 0 0 6px var(--color-success); }

.customer-details-box {
  padding: 24px;
  margin-bottom: 24px;
}

.customer-details-box label { font-size: 0.65rem; color: var(--color-primary); font-weight: 800; }
.customer-details-box h3 { margin: 8px 0 4px 0; font-size: 1.3rem; }

.items-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 24px;
}

.items-table th {
  text-align: left;
  padding: 12px;
  font-size: 0.7rem;
  color: var(--color-text-dim);
  border-bottom: 1px solid var(--glass-border);
}

.items-table td { padding: 14px 12px; border-bottom: 1px solid rgba(255,255,255,0.03); }
.item-label { font-weight: 700; }
.item-subtotal { font-weight: 800; text-align: right; }

.override-badge {
  font-size: 0.55rem;
  background: rgba(255, 170, 0, 0.15);
  color: #FFAA00;
  padding: 2px 6px;
  border-radius: 4px;
  margin-left: 8px;
  vertical-align: middle;
  font-weight: 800;
  border: 1px solid rgba(255, 170, 0, 0.3);
}

.price-stack {
  display: flex;
  flex-direction: column;
}

.original-price.strike {
  font-size: 0.65rem;
  color: var(--color-text-dim);
  text-decoration: line-through;
  opacity: 0.7;
}

.total-row td { padding: 20px 12px; font-weight: 700; color: var(--color-text-dim); }
.grand-total { font-size: 1.6rem; font-weight: 900; color: var(--color-primary); text-align: right; }

/* ─── QUICK STATUS UPDATE (Modal) ─── */
.modal-quick-actions {
  margin-top: 8px;
  padding: 20px;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--glass-border);
  border-radius: 14px;
}

.quick-title {
  font-size: 0.7rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-text-dim);
  margin-bottom: 14px;
}

.quick-btns-row {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.mt-12 { margin-top: 12px; }

.quick-status-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border-radius: 10px;
  border: 1px solid var(--glass-border);
  background: rgba(255, 255, 255, 0.03);
  color: var(--color-text-dim);
  font-family: var(--font-body);
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s ease;
}

.quick-status-btn:hover {
  background: rgba(255, 255, 255, 0.06);
  color: white;
  border-color: rgba(255, 255, 255, 0.15);
}

.quick-status-btn.active.pending { background: rgba(255, 170, 0, 0.12); border-color: rgba(255, 170, 0, 0.4); color: #FFAA00; }
.quick-status-btn.active.paid { background: rgba(0, 255, 157, 0.1); border-color: rgba(0, 255, 157, 0.35); color: var(--color-success); }
.quick-status-btn.active.cancelled { background: rgba(255, 62, 62, 0.1); border-color: rgba(255, 62, 62, 0.35); color: var(--color-error); }
.quick-status-btn.active.processing { background: rgba(100, 149, 237, 0.12); border-color: rgba(100, 149, 237, 0.4); color: #6495ED; }
.quick-status-btn.active.on_delivery { background: rgba(255, 140, 0, 0.12); border-color: rgba(255, 140, 0, 0.4); color: var(--color-primary); }
.quick-status-btn.active.delivered { background: rgba(0, 255, 157, 0.1); border-color: rgba(0, 255, 157, 0.35); color: var(--color-success); }

.qs-icon { width: 14px; height: 14px; }

/* ─── MODAL OVERLAY ────────────── */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(10px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 16px;
  margin-top: 24px;
}

.animate-pop {
  animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.95) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

/* ─── TOAST NOTIFICATION ──────── */
.toast-notification {
  position: fixed;
  bottom: 32px;
  right: 32px;
  z-index: 9999;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 24px;
  border-radius: 14px;
  backdrop-filter: blur(20px);
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.4);
  min-width: 280px;
}

.toast-notification.success {
  background: rgba(0, 255, 157, 0.1);
  border: 1px solid rgba(0, 255, 157, 0.25);
}

.toast-notification.error {
  background: rgba(255, 62, 62, 0.1);
  border: 1px solid rgba(255, 62, 62, 0.25);
}

.toast-icon { width: 22px; height: 22px; flex-shrink: 0; }
.toast-notification.success .toast-icon { color: var(--color-success); }
.toast-notification.error .toast-icon { color: var(--color-error); }

.toast-content { display: flex; flex-direction: column; }
.toast-title { font-weight: 800; font-size: 0.85rem; }
.toast-msg { font-size: 0.75rem; color: var(--color-text-dim); }

/* ─── TRANSITIONS ──────────────── */
.fade-enter-active { transition: opacity 0.2s ease, transform 0.2s ease; }
.fade-leave-active { transition: opacity 0.15s ease, transform 0.15s ease; }
.fade-enter-from { opacity: 0; transform: translateY(-4px); }
.fade-leave-to { opacity: 0; transform: translateY(-4px); }

.toast-slide-enter-active { transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1); }
.toast-slide-leave-active { transition: all 0.3s ease; }
.toast-slide-enter-from { opacity: 0; transform: translateX(40px); }
.toast-slide-leave-to { opacity: 0; transform: translateX(40px); }

/* VOIDED STYLES */
.order-row.is-voided td {
  text-decoration: line-through;
  opacity: 0.5;
  color: var(--color-error);
}

.order-row.is-voided .actions {
  text-decoration: none !important;
  opacity: 1 !important;
}

.void-watermark {
  position: absolute;
  font-size: 0.6rem;
  font-weight: 900;
  background: var(--color-error);
  color: white;
  padding: 1px 4px;
  border-radius: 4px;
  transform: rotate(-15deg);
  left: -20px;
  top: -10px;
  pointer-events: none;
}

.void-banner-modal {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: rgba(255, 62, 62, 0.1);
  border: 1px dashed var(--color-error);
  color: var(--color-error);
  padding: 24px;
  border-radius: 12px;
  margin-bottom: 24px;
  font-weight: 800;
  letter-spacing: 0.05em;
}

.void-action-section {
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid var(--glass-border);
  text-align: center;
}

.btn-void {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  background: rgba(255, 66, 66, 0.1);
  border: 1px solid rgba(255, 66, 66, 0.3);
  color: var(--color-error);
  padding: 14px;
  border-radius: 12px;
  font-family: var(--font-body);
  font-weight: 800;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-void:hover:not(:disabled) {
  background: var(--color-error);
  color: white;
  box-shadow: 0 0 20px rgba(255, 66, 66, 0.4);
}

.btn-void:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.void-hint {
  font-size: 0.7rem;
  color: var(--color-text-dim);
  margin-top: 10px;
  font-style: italic;
}
</style>
