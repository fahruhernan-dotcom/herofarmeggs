<template>
  <div class="activity-log-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">TACTICAL AUDIT TRAIL</h4>
        <h1 class="hero-font">Activity Stream</h1>
        <p class="text-dim">Real-time log of all system operations and user actions.</p>
      </div>
      <div class="header-actions">
        <div class="filter-group glass-panel">
          <FilterIcon class="icon-xs" />
          <select v-model="filterType" class="select-terminal">
            <option value="all">ALL ENTITIES</option>
            <option value="order">ORDERS</option>
            <option value="inventory">INVENTORY</option>
            <option value="employee">PERSONNEL</option>
            <option value="whatsapp_queued">WHATSAPP BOT</option>
            <option value="system">LOGISTICS / SYSTEM</option>
          </select>
        </div>
        <button class="btn-refresh" @click="fetchLogs" :disabled="loading">
          <RefreshCcwIcon class="icon-sm" :class="{ 'spinning': loading }" />
        </button>
      </div>
    </header>

    <div class="log-container glass-panel">
      <div class="log-stream">
        <div v-for="log in logs" :key="log.id" class="log-item" :class="log.entity_type">
          <div class="log-time-column">
            <span class="time">{{ formatTime(log.created_at) }}</span>
            <span class="date">{{ formatDate(log.created_at) }}</span>
          </div>

          <div class="log-icon-column">
            <div class="icon-circle">
              <component :is="getIcon(log.entity_type)" class="icon-xs" />
            </div>
            <div class="vertical-line"></div>
          </div>

          <div class="log-content-column">
            <div class="log-header">
              <span class="entity-badge">{{ log.entity_type.toUpperCase() }}</span>
              <span class="action-text">{{ formatAction(log.action) }}</span>
              <span class="actor" v-if="log.actor_name">BY {{ log.actor_name }}</span>
            </div>
            
            <div class="log-details">
              <p v-if="log.entity_type === 'order'" class="highlight">
                Invoice: {{ log.details.invoice_number }} — {{ log.details.customer_name }}
              </p>
              <p v-if="log.entity_type === 'inventory'" class="highlight">
                {{ log.details.grade }}: {{ log.details.from }} → {{ log.details.to }} 
                ({{ log.details.diff > 0 ? '+' : '' }}{{ log.details.diff }})
              </p>
              <div v-if="log.action === 'whatsapp_queued'" class="wa-log-details">
                <div class="wa-meta">
                   <span class="wa-phone">{{ log.details.phone }}</span>
                   <span class="wa-status-pill" :class="log.details.status">{{ log.details.status?.toUpperCase() }}</span>
                </div>
                <p class="wa-preview">{{ log.details.preview }}</p>
              </div>
              <div class="json-peek" v-if="Object.keys(log.details).length > 0 && log.action !== 'whatsapp_queued'">
                 <pre>{{ formatDetails(log.details) }}</pre>
              </div>
            </div>
          </div>
        </div>

        <div v-if="logs.length === 0 && !loading" class="empty-state">
           <ActivityIcon class="icon-xl opacity-10" />
           <p>No tactical logs detected in the current stream.</p>
        </div>

        <div v-if="loading" class="loading-state">
           <div class="spinner"></div>
           <p>Synchronizing archive data...</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  FilterIcon, 
  RefreshCcwIcon, 
  ShoppingCartIcon, 
  PackageIcon, 
  UsersIcon, 
  TerminalIcon,
  ActivityIcon,
  TruckIcon
} from 'lucide-vue-next';

const logs = ref<any[]>([]);
const loading = ref(false);
const filterType = ref('all');

async function fetchLogs() {
  loading.value = true;
  try {
    let query = supabase
      .from('activities')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100);

    if (filterType.value !== 'all') {
      query = query.eq('entity_type', filterType.value);
    }

    const { data, error } = await query;
    if (error) throw error;
    logs.value = data || [];
  } catch (err: any) {
    console.error('Log sync failed:', err);
  } finally {
    loading.value = false;
  }
}

function getIcon(type: string) {
  switch (type) {
    case 'order': return ShoppingCartIcon;
    case 'inventory': return PackageIcon;
    case 'employee': return UsersIcon;
    case 'system': return TruckIcon;
    default: return TerminalIcon;
  }
}

function formatTime(dateStr: string) {
  return new Date(dateStr).toLocaleTimeString('id-ID', { hour12: false, hour: '2-digit', minute: '2-digit' });
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });
}

function formatAction(action: string) {
  return action.replace(/_/g, ' ').toUpperCase();
}

function formatDetails(details: any) {
  // Filter out redundant fields for display
  const display = { ...details };
  delete display.invoice_number;
  delete display.customer_name;
  delete display.grade;
  delete display.from;
  delete display.to;
  delete display.diff;
  delete display.phone;
  delete display.status;
  delete display.preview;
  
  if (Object.keys(display).length === 0) return '';
  return JSON.stringify(display, null, 2);
}

watch(filterType, () => fetchLogs());

onMounted(() => {
  fetchLogs();
});
</script>

<style scoped>
.activity-log-page { display: flex; flex-direction: column; gap: 32px; }
.header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; gap: 16px; align-items: center; }

.filter-group { display: flex; align-items: center; gap: 12px; padding: 10px 20px; border-radius: 12px; }
.select-terminal { background: transparent; border: none; color: white; font-size: 0.75rem; font-weight: 800; cursor: pointer; }
.select-terminal:focus { outline: none; }

.btn-refresh {
  width: 44px; height: 44px; display: flex; align-items: center; justify-content: center;
  background: rgba(255, 255, 255, 0.03); border: 1px solid var(--glass-border); border-radius: 12px;
  color: white; cursor: pointer; transition: all 0.3s;
}
.btn-refresh:hover { background: rgba(255,255,255,0.08); transform: rotate(45deg); }
.btn-refresh:disabled { opacity: 0.5; }

.log-container { padding: 40px; border-radius: 24px; min-height: 600px; }
.log-stream { display: flex; flex-direction: column; }

.log-item { display: flex; gap: 16px; min-height: 80px; }

/* TIME COLUMN */
.log-time-column { width: 80px; text-align: right; display: flex; flex-direction: column; gap: 4px; padding-top: 4px; }
.log-time-column .time { font-family: 'JetBrains Mono', monospace; font-size: 0.9rem; font-weight: 800; color: white; }
.log-time-column .date { font-size: 0.65rem; font-weight: 700; color: var(--color-text-dim); text-transform: uppercase; }

/* ICON COLUMN */
.log-icon-column { display: flex; flex-direction: column; align-items: center; }
.icon-circle {
  width: 32px; height: 32px; border-radius: 10px; display: flex; align-items: center; justify-content: center;
  background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); color: var(--color-text-dim);
  z-index: 2;
}
.vertical-line { flex: 1; width: 2px; background: rgba(255, 255, 255, 0.05); margin: 4px 0; }
.log-item:last-child .vertical-line { display: none; }

/* CONTENT COLUMN */
.log-content-column { flex: 1; padding-bottom: 32px; }
.log-header { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }

.entity-badge { font-size: 0.6rem; font-weight: 900; padding: 2px 8px; border-radius: 4px; background: rgba(255, 255, 255, 0.05); color: var(--color-text-dim); }
.action-text { font-size: 0.8rem; font-weight: 800; color: white; letter-spacing: 0.02em; }
.actor { font-size: 0.65rem; opacity: 0.4; font-weight: 700; }

.highlight { font-size: 0.85rem; color: #00ff9d; font-weight: 700; }
.json-peek pre { font-size: 0.7rem; color: var(--color-text-dim); background: rgba(0, 0, 0, 0.2); padding: 12px; border-radius: 8px; margin-top: 8px; font-family: 'JetBrains Mono', monospace; }

/* ENTITY THEMES */
.order .icon-circle { color: #f59e0b; border-color: rgba(245, 158, 11, 0.2); background: rgba(245, 158, 11, 0.05); }
.inventory .icon-circle { color: #bb86fc; border-color: rgba(187, 134, 252, 0.2); background: rgba(187, 134, 252, 0.05); }
.inventory .highlight { color: #bb86fc; }
.employee .icon-circle { color: #00ff9d; border-color: rgba(0, 255, 157, 0.2); background: rgba(0, 255, 157, 0.05); }
.system .icon-circle { color: #60a5fa; border-color: rgba(96, 165, 250, 0.2); background: rgba(96, 165, 250, 0.05); }

.spinning { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

/* WA LOG STYLES */
.wa-log-details { margin-top: 8px; background: rgba(0, 0, 0, 0.2); padding: 12px; border-radius: 12px; border: 1px solid rgba(0, 255, 157, 0.1); }
.wa-meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.wa-phone { font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: #00ff9d; font-weight: 800; }
.wa-status-pill { font-size: 0.6rem; font-weight: 900; padding: 2px 8px; border-radius: 4px; background: rgba(255, 255, 255, 0.05); }
.wa-status-pill.pending { color: #f59e0b; background: rgba(245, 158, 11, 0.1); }
.wa-status-pill.sent { color: #00ff9d; background: rgba(0, 255, 157, 0.1); }
.wa-preview { font-size: 0.8rem; color: var(--color-text-dim); font-style: italic; margin: 0; }

.empty-state, .loading-state { padding: 80px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 20px; color: var(--color-text-dim); }
.spinner { width: 40px; height: 40px; border: 3px solid rgba(255,255,255,0.05); border-top-color: var(--color-primary); border-radius: 50%; animation: spin 0.8s linear infinite; }
</style>
