<template>
  <div class="orders-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">LOGISTICS & REVENUE</h4>
        <h1 class="hero-font">Order Management</h1>
        <p class="text-dim">Track every sale and manage order fulfilling statuses.</p>
      </div>
      <div class="header-actions">
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
        <div class="s-trend pos">+12% vs last week</div>
      </div>
      <div class="summary-card glass-panel">
        <span class="s-label">Active Orders</span>
        <span class="s-value">{{ orders.length }}</span>
        <p class="s-subtext">Across all categories</p>
      </div>
      <div class="summary-card glass-panel">
        <span class="s-label">Avg. Order Value</span>
        <span class="s-value">Rp {{ avgOrderValue.toLocaleString() }}</span>
      </div>
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
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="order in filteredOrders" :key="order.id" class="order-row">
              <td class="order-id">#INV-{{ order.id.toString().slice(-6).toUpperCase() }}</td>
              <td class="customer-info">
                <div class="cust-name">{{ order.customers?.name || 'Guest Customer' }}</div>
                <div class="cust-phone text-dim">{{ order.customers?.phone || '-' }}</div>
              </td>
              <td class="date">{{ formatDate(order.created_at) }}</td>
              <td class="items-cell">
                <span class="items-count">{{ order.sale_items?.length || 0 }} Type(s)</span>
              </td>
              <td class="amount">Rp {{ (order.total_price || 0).toLocaleString() }}</td>
              <td>
                <span class="status-badge" :class="order.payment_status">
                  {{ order.payment_status }}
                </span>
              </td>
              <td class="actions">
                <button class="btn-icon" title="View Details" @click="viewOrderDetails(order)">
                  <EyeIcon class="icon-sm" />
                </button>
                <button class="btn-icon" title="Print Invoice">
                  <PrinterIcon class="icon-sm" />
                </button>
              </td>
            </tr>
            <tr v-if="orders.length === 0">
              <td colspan="7" class="empty-state">No orders found. Enter a new sale to see it here.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <!-- ORDER DETAIL MODAL -->
    <Teleport to="body">
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

            <div class="customer-details-box glass-panel">
              <label>BILLING TO</label>
              <h3>{{ selectedOrder.customers?.name || 'Guest Customer' }}</h3>
              <p class="text-dim">{{ selectedOrder.customers?.phone || 'No phone provided' }}</p>
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
                  <td class="item-label">{{ formatEggType(item.egg_type) }}</td>
                  <td>{{ item.quantity }} Pack</td>
                  <td>Rp {{ item.unit_price.toLocaleString() }}</td>
                  <td class="item-subtotal">Rp {{ item.subtotal.toLocaleString() }}</td>
                </tr>
              </tbody>
              <tfoot>
                <tr class="total-row">
                  <td colspan="3">Grand Total</td>
                  <td class="grand-total">Rp {{ (selectedOrder.total_price || 0).toLocaleString() }}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <div class="modal-actions">
            <button class="btn-secondary" @click="selectedOrder = null">Close</button>
            <button class="btn-primary">
              <PrinterIcon class="icon" />
              <span>REPRINT INVOICE</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  PlusIcon, 
  SearchIcon, 
  EyeIcon, 
  PrinterIcon
} from 'lucide-vue-next';

const orders = ref<any[]>([]);
const searchQuery = ref('');
const selectedOrder = ref<any>(null);

async function fetchOrders() {
  const { data, error } = await supabase
    .from('sales')
    .select(`
      id,
      total_price,
      payment_status,
      created_at,
      customers!sales_customer_id_fkey (
        name, 
        whatsapp_number, 
        address
      ),
      sale_items (*)
    `)
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Fetch Orders Error:', error);
    alert('DB Error: ' + error.message);
  }
  if (data) orders.value = data;
}

const filteredOrders = computed(() => {
  if (!searchQuery.value) return orders.value;
  const q = searchQuery.value.toLowerCase();
  return orders.value.filter(o => 
    o.id.toString().includes(q) || 
    (o.customers?.name && o.customers.name.toLowerCase().includes(q))
  );
});

const totalRevenue = computed(() => {
  return orders.value.reduce((acc, curr) => acc + (curr.total_price || 0), 0);
});

const avgOrderValue = computed(() => {
  if (orders.value.length === 0) return 0;
  return Math.round(totalRevenue.value / orders.value.length);
});

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
}

function formatEggType(type: string) {
  if (type === 'hero_size') return 'Hero Size (>65g)';
  if (type === 'standard_size') return 'Standard Size';
  if (type === 'salted_egg') return 'Telur Asin';
  return type;
}

function viewOrderDetails(order: any) {
  selectedOrder.value = order;
}

onMounted(fetchOrders);
</script>

<style scoped>
.orders-page {
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

.stats-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.summary-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.s-label { font-size: 0.75rem; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.05em; }
.s-value { font-size: 1.8rem; font-weight: 800; color: white; }
.s-trend { font-size: 0.75rem; font-weight: 700; }
.s-trend.pos { color: var(--color-success); }
.s-subtext { font-size: 0.75rem; color: var(--color-text-dim); }

.orders-list {
  padding: 32px;
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
  padding: 16px;
  font-size: 0.75rem;
  color: var(--color-text-dim);
  text-transform: uppercase;
  border-bottom: 1px solid var(--glass-border);
}

.premium-table td {
  padding: 16px;
  font-size: 0.9rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.order-id { font-family: 'JetBrains Mono', monospace; font-weight: 700; color: var(--color-primary); }
.cust-name { font-weight: 700; }
.cust-phone { font-size: 0.8rem; }
.amount { font-weight: 800; }

.status-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 0.7rem;
  font-weight: 800;
  text-transform: uppercase;
}
.status-badge.paid { background: rgba(0, 255, 157, 0.1); color: var(--color-success); }
.status-badge.pending { background: rgba(255, 140, 0, 0.1); color: var(--color-primary); }

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
  font-style: italic;
}

/* MODAL DETAILS */
.details-modal {
  max-width: 600px;
  width: 100%;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.close-btn {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 2rem;
  cursor: pointer;
}

.invoice-header-mini {
  display: flex;
  justify-content: space-between;
  margin-bottom: 24px;
}

.invoice-header-mini .label { font-size: 0.65rem; text-transform: uppercase; color: var(--color-text-dim); }
.invoice-header-mini .value { font-weight: 800; font-size: 1.1rem; }

.customer-details-box {
  padding: 24px;
  margin-bottom: 32px;
}

.customer-details-box label { font-size: 0.65rem; color: var(--color-primary); font-weight: 800; }
.customer-details-box h3 { margin: 8px 0 4px 0; font-size: 1.3rem; }

.items-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 32px;
}

.items-table th {
  text-align: left;
  padding: 12px;
  font-size: 0.7rem;
  color: var(--color-text-dim);
  border-bottom: 1px solid var(--glass-border);
}

.items-table td { padding: 16px 12px; border-bottom: 1px solid rgba(255,255,255,0.03); }
.item-label { font-weight: 700; }
.item-subtotal { font-weight: 800; text-align: right; }

.total-row td { padding: 24px 12px; font-weight: 700; color: var(--color-text-dim); }
.grand-total { font-size: 1.8rem; font-weight: 900; color: var(--color-primary); text-align: right; }

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
}

.animate-pop {
  animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes popIn {
  from { opacity: 0; transform: scale(0.95) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
