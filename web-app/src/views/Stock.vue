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

    <div class="stock-grid">
      <div v-for="item in inventory" :key="item.id" class="stock-card glass-panel" :class="item.id">
        <div class="card-bg-icon">
          <PackageIcon v-if="item.id === 'standard_size'" />
          <ZapIcon v-else />
        </div>
        <div class="card-content">
          <div class="top">
            <span class="label">{{ item.label }}</span>
            <div class="status-indicator" :class="getStockStatus(item.current_stock)"></div>
          </div>
          <div class="main">
            <h2 class="stock-value">{{ item.current_stock }} <small>butir</small></h2>
            <p class="price-tag">Target Retail: Rp {{ item.base_price_per_pack.toLocaleString() }}</p>
          </div>
          <div class="footer">
            <div class="mini-stat">
              <span class="ms-label">Safety Stock</span>
              <span class="ms-value">50</span>
            </div>
            <button class="btn-lite" @click="quickAdjust(item.id)">Quick Adjust</button>
          </div>
        </div>
      </div>
    </div>

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
                {{ log.change > 0 ? '+' : '' }}{{ log.change }}
              </td>
              <td class="notes">{{ log.notes || '-' }}</td>
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
              <label>Egg Type</label>
              <select v-model="form.egg_type" required>
                <option value="hero_size">Hero Size (>65g)</option>
                <option value="standard_size">Standard Size</option>
              </select>
            </div>

            <div class="form-group">
              <label>Operation Type</label>
              <select v-model="form.log_type" required>
                <option value="arrival">Stock Arrival (+)</option>
                <option value="sorting_waste">Sorting Waste (-)</option>
                <option value="manual_adjustment">Manual Fix</option>
              </select>
            </div>

            <div class="form-group">
              <label>Amount (Butir)</label>
              <input type="number" v-model.number="form.change" placeholder="e.g. 100" required />
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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue';
import { supabase } from '../lib/supabase';
import { PlusIcon, PackageIcon, ZapIcon } from 'lucide-vue-next';

const inventory = ref<any[]>([]);
const logs = ref<any[]>([]);
const showAdjustmentModal = ref(false);
const submitting = ref(false);

const form = reactive({
  egg_type: 'hero_size',
  log_type: 'arrival',
  change: 0,
  notes: ''
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
}

function getStockStatus(stock: number) {
  if (stock < 20) return 'critical';
  if (stock < 50) return 'low';
  return 'healthy';
}

function formatTime(date: string) {
  return new Date(date).toLocaleString('id-ID', { 
    day: '2-digit', 
    month: 'short', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}

function quickAdjust(type: string) {
    form.egg_type = type;
    showAdjustmentModal.value = true;
}

async function submitAdjustment() {
  submitting.value = true;
  
  // 1. Determine direction
  let finalChange = form.change;
  if (form.log_type === 'sorting_waste' && finalChange > 0) {
    finalChange = -finalChange;
  }

  // 2. Insert Log
  const { error: logError } = await supabase.from('stock_logs').insert({
    egg_type: form.egg_type,
    change: finalChange,
    log_type: form.log_type,
    notes: form.notes
  });

  if (!logError) {
    // 3. Update Inventory (Atomic increment in real DB is better, but this works for internal use)
    const currentItem = inventory.value.find(i => i.id === form.egg_type);
    const newStock = (currentItem?.current_stock ?? 0) + finalChange;
    
    await supabase.from('inventory')
      .update({ current_stock: newStock, updated_at: new Date() })
      .eq('id', form.egg_type);

    showAdjustmentModal.value = false;
    form.change = 0;
    form.notes = '';
    fetchData();
  }

  submitting.value = false;
}

onMounted(() => {
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

.stock-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 24px;
}

.stock-card {
  height: 220px;
  padding: 32px;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.card-bg-icon {
  position: absolute;
  right: -20px;
  bottom: -20px;
  font-size: 120px;
  color: rgba(255, 255, 255, 0.03);
  z-index: 1;
}

.card-bg-icon svg {
  width: 150px;
  height: 150px;
}

.card-content {
  position: relative;
  z-index: 2;
  height: 100%;
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
  font-weight: 700;
  letter-spacing: 0.1em;
  font-size: 0.8rem;
  color: var(--color-text-dim);
}

.status-indicator {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.status-indicator.healthy { background: var(--color-success); box-shadow: 0 0 10px var(--color-success); }
.status-indicator.low { background: #FFD700; box-shadow: 0 0 10px #FFD700; }
.status-indicator.critical { background: var(--color-error); box-shadow: 0 0 10px var(--color-error); }

.stock-value {
  font-size: 3.5rem;
  font-weight: 800;
  line-height: 1;
}

.stock-value small { font-size: 1.2rem; color: var(--color-text-dim); }

.price-tag {
  color: var(--color-primary);
  font-size: 0.9rem;
  font-weight: 600;
  margin-top: 8px;
}

.footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid var(--glass-border);
  padding-top: 16px;
}

.mini-stat { display: flex; flex-direction: column; }
.ms-label { font-size: 0.65rem; color: var(--color-text-dim); text-transform: uppercase; }
.ms-value { font-weight: 700; font-size: 0.9rem; }

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
  align-items: center;
  z-index: 1000;
}

.modal-card {
  width: 100%;
  max-width: 500px;
  padding: 40px;
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

@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
