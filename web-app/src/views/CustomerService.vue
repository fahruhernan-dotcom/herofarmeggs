<template>
  <div class="company-settings-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">CUSTOMER SERVICES</h4>
        <h1 class="hero-font">Automation HUB</h1>
        <p class="text-dim">Update WAHA connectivity and notification parameters.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary-glow" @click="handleSave" :disabled="saving">
           {{ saving ? 'UPDATING WAHA...' : 'SYNC CHANGES' }}
        </button>
      </div>
    </header>

    <div class="settings-grid">
       <!-- WAHA CONNECTIVITY -->
       <section class="settings-card glass-panel">
         <div class="card-header">
           <div class="icon-wrap purple"><CpuIcon /></div>
           <h3>WAHA Connectivity</h3>
           <button class="btn-ghost ms-auto" @click="testWaha" :disabled="testingWaha">
             <FlaskConicalIcon class="icon-xs" :class="{'spin': testingWaha}" />
           </button>
         </div>

         <div class="form-grid">
           <div class="form-group-tactical full-width">
             <label>WAHA Instance Base URL</label>
             <div class="input-terminal">
               <GlobeIcon class="icon-xs" />
               <input type="text" v-model="waha.base_url" placeholder="http://localhost:3000" />
             </div>
           </div>
           <div class="form-group-tactical">
             <label>Session Name</label>
             <div class="input-terminal">
               <input type="text" v-model="waha.session_name" />
             </div>
           </div>
           <div class="form-group-tactical">
             <label>API Key (X-Api-Key)</label>
             <div class="input-terminal">
               <KeyIcon class="icon-xs" />
               <input type="password" v-model="waha.api_key" placeholder="••••••••" />
             </div>
           </div>

           <div class="status-banner glass-panel" :class="waha.is_active ? 'connected' : 'disconnected'">
              <ZapIcon v-if="waha.is_active" class="icon-xs" />
              <ZapOffIcon v-else class="icon-xs" />
              <span>{{ waha.is_active ? 'WAHA TERMINAL ACTIVE' : 'CONNECTION OFFLINE' }}</span>
           </div>
         </div>
       </section>

       <!-- N8N AUTOMATION ENGINE -->
       <section class="settings-card glass-panel">
         <div class="card-header">
           <div class="icon-wrap blue"><LinkIcon /></div>
           <h3>n8n Engine</h3>
           <button class="btn-ghost ms-auto" @click="testN8n" :disabled="testingN8n">
             <FlaskConicalIcon class="icon-xs" :class="{'spin': testingN8n}" />
           </button>
         </div>

         <div class="form-grid">
           <div class="form-group-tactical full-width">
             <label>n8n Webhook URL</label>
             <div class="input-terminal">
               <GlobeIcon class="icon-xs" />
               <input type="text" v-model="waha.n8n_webhook_url" placeholder="http://localhost:5678/webhook/..." />
             </div>
           </div>
           <p class="text-xs text-dim full-width">
             Used to trigger automation workflows for orders and delivery.
           </p>
         </div>
       </section>

       <!-- LOCAL AUTOMATION DB (SAFE BRIDGE) -->
       <section class="settings-card glass-panel">
         <div class="card-header">
           <div class="icon-wrap green"><DatabaseIcon /></div>
           <h3>Local Automation DB</h3>
         </div>

         <div class="form-grid">
           <div class="form-group-tactical full-width">
             <label>Local Supabase URL</label>
             <div class="input-terminal">
               <GlobeIcon class="icon-xs" />
               <input type="text" v-model="waha.local_supabase_url" placeholder="http://localhost:54321" />
             </div>
           </div>
           <div class="form-group-tactical full-width">
             <label>Local Service Key</label>
             <div class="input-terminal">
               <KeyIcon class="icon-xs" />
               <input type="password" v-model="waha.local_supabase_key" placeholder="••••••••" />
             </div>
           </div>
         </div>
       </section>

       <!-- NOTIFICATION PARAMETERS -->
       <section class="settings-card glass-panel">
          <div class="card-header">
            <div class="icon-wrap orange"><MessageSquareIcon /></div>
            <h3>Notification HUB</h3>
          </div>

          <div class="automation-toggles">
            <div class="toggle-row">
               <div class="info">
                 <h4>New Order Confirmation</h4>
                 <p class="text-dim">Auto-send summary via WA on new sales.</p>
               </div>
               <CustomToggle v-model="waha.notify_on_new_order" />
            </div>
            <div class="toggle-row">
               <div class="info">
                 <h4>Logistics Updates</h4>
                 <p class="text-dim">Notify customer when driver picks up eggs.</p>
               </div>
               <CustomToggle v-model="waha.notify_on_delivery" />
            </div>
          </div>
       </section>

       <!-- MESSAGE ARCHIVE -->
       <section class="settings-card glass-panel full-width">
          <div class="card-header">
             <div class="icon-wrap green"><HistoryIcon /></div>
             <div class="flex-column">
               <h3>Message Archive</h3>
               <p class="text-xs text-dim">Recent outbound tactical communications.</p>
               <div class="flex-row gap-8 mt-4">
                 <button class="pill-btn" :class="{ active: logSource === 'online' }" @click="logSource = 'online'; fetchLogs()">ONLINE</button>
                 <button class="pill-btn" :class="{ active: logSource === 'local' }" @click="logSource = 'local'; fetchLogs()">LOCAL</button>
               </div>
             </div>
             <button class="btn-refresh ms-auto" @click="fetchLogs">
               <RefreshCcwIcon class="icon-xs" />
             </button>
          </div>

          <div class="mini-log-table scroll-y">
             <table v-if="logs.length">
               <thead>
                 <tr>
                   <th>TIMESTAMP</th>
                   <th>RECIPIENT</th>
                   <th>CONTENT PREVIEW</th>
                   <th>STATUS</th>
                 </tr>
               </thead>
               <tbody>
                 <tr v-for="log in logs" :key="log.id">
                   <td class="text-mono">{{ formatTime(log.created_at) }}</td>
                   <td>{{ log.phone }}</td>
                   <td class="preview-text">{{ log.message }}</td>
                   <td>
                     <span class="status-pill-mini" :class="log.status">{{ log.status.toUpperCase() }}</span>
                   </td>
                 </tr>
               </tbody>
             </table>
             <div v-else class="empty-mini-state">
                No recent messages in the buffer.
             </div>
          </div>
       </section>
        <!-- BOT DRAFTS (LOCAL) -->
        <section v-if="localSupabase" class="settings-card glass-panel full-width">
           <div class="card-header">
              <div class="icon-wrap orange"><MessageSquareIcon /></div>
              <div class="flex-column">
                <h3>Bot Order Drafts</h3>
                <p class="text-xs text-dim">Pending orders captured from WhatsApp chat.</p>
              </div>
              <button class="btn-refresh ms-auto" @click="fetchBotDrafts">
                <RefreshCcwIcon class="icon-xs" />
              </button>
           </div>
           
           <div class="mini-log-table scroll-y">
              <table v-if="botDrafts.length">
                <thead>
                  <tr>
                    <th>CUSTOMER</th>
                    <th>GRADE</th>
                    <th>PACKS</th>
                    <th>STATUS</th>
                    <th>ACTION</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="draft in botDrafts" :key="draft.id">
                    <td>{{ draft.customer_name || draft.phone }}</td>
                    <td><span class="grade-pill">{{ draft.egg_grade }}</span></td>
                    <td>{{ draft.packs }}</td>
                    <td><span class="status-pill-mini pending">{{ draft.status.toUpperCase() }}</span></td>
                    <td>
                      <button class="btn-action-mini" @click="handleConfirmDraft(draft)">CONFIRM</button>
                    </td>
                  </tr>
                </tbody>
              </table>
              <div v-else class="empty-mini-state">
                 No pending drafts from the bot.
              </div>
           </div>
        </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  GlobeIcon, 
  KeyIcon, 
  MessageSquareIcon, 
  CpuIcon, 
  ZapIcon, 
  ZapOffIcon,
  LinkIcon,
  FlaskConicalIcon,
  DatabaseIcon,
  HistoryIcon,
  RefreshCcwIcon
} from 'lucide-vue-next';
import CustomToggle from '../components/CustomToggle.vue';

const localSupabase = ref<any>(null);
const botDrafts = ref<any[]>([]);
const logSource = ref('online');

const waha = reactive({
  id: '',
  base_url: '',
  session_name: 'default',
  api_key: '',
  is_active: false,
  notify_on_new_order: true,
  notify_on_delivery: true,
  n8n_webhook_url: '',
  local_supabase_url: '',
  local_supabase_key: ''
});

const testingWaha = ref(false);
const testingN8n = ref(false);

const logs = ref<any[]>([]);
const saving = ref(false);
let refreshTimer: any = null;

function formatTime(dateStr: string) {
  if (!dateStr) return '--:--';
  return new Date(dateStr).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

async function testWaha() {
  testingWaha.value = true;
  try {
    const response = await fetch(`${waha.base_url}/api/sessions`, {
      headers: waha.api_key ? { 'X-Api-Key': waha.api_key } : {}
    });
    waha.is_active = response.ok;
    if (response.ok) alert('✅ WAHA Terminal is reachable.');
    else alert(`❌ WAHA responded with error: ${response.status} ${response.statusText}`);
  } catch (err) {
    waha.is_active = false;
    alert('❌ Could not reach WAHA. Is it running?');
  } finally {
    testingWaha.value = false;
  }
}

async function testN8n() {
  if (!waha.n8n_webhook_url) {
    alert('Please enter a webhook URL first.');
    return;
  }
  testingN8n.value = true;
  try {
    const response = await fetch(waha.n8n_webhook_url, { 
      method: 'POST',
      body: JSON.stringify({ test: true }),
      headers: { 'Content-Type': 'application/json' }
    });
    if (response.ok) alert('✅ n8n Webhook is live.');
    else alert('❌ n8n responded with error.');
  } catch (err) {
    alert('❌ Could not reach n8n. Is it running and public?');
  } finally {
    testingN8n.value = false;
  }
}

async function fetchLogs() {
  const client = (logSource.value === 'local' && localSupabase.value) ? localSupabase.value : supabase;
  try {
    const { data } = await client
      .from('wa_message_log')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);
    if (data) logs.value = data;
  } catch (err) {
    console.error('Failed to fetch logs from ' + logSource.value, err);
  }
}

async function fetchBotDrafts() {
  if (!localSupabase.value) return;
  const { data } = await localSupabase.value
    .from('wa_bot_drafts')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(5);
  if (data) botDrafts.value = data;
}

async function handleConfirmDraft(draft: any) {
  if (!confirm(`Konfirmasi pesanan ${draft.egg_grade} (${draft.packs} pack) untuk ${draft.customer_name || draft.phone}?`)) return;
  
  try {
    // 1. Ambil data inventory berdasarkan grade (untuk mendapatkan ID telur)
    const { data: invData } = await supabase
      .from('inventory')
      .select('id, base_price_per_pack')
      .eq('grade', draft.egg_grade)
      .single();
    
    if (!invData) throw new Error(`Grade ${draft.egg_grade} tidak ditemukan di inventory.`);

    const saleId = draft.id; // Gunakan ID draft agar sinkron
    const totalPrice = draft.total_est || (invData.base_price_per_pack * draft.packs);

    // 2. Masukkan ke tabel SALES Online
    const { error: onlineError } = await supabase.from('sales').insert({
      id: saleId,
      customer_name: draft.customer_name,
      total_price: totalPrice,
      status: 'pending_payment',
      payment_status: 'unpaid',
      order_type: 'retail',
      created_at: draft.created_at
    });
    if (onlineError) throw onlineError;

    // 3. Masukkan ke tabel SALE_ITEMS Online (Penting untuk Stok & HPP)
    const { error: itemError } = await supabase.from('sale_items').insert({
      sale_id: saleId,
      inventory_id: invData.id,
      egg_type: invData.id,
      grade: draft.egg_grade,
      quantity: draft.packs * 10, // Asumsi 1 pack = 10 butir (sesuai schema pack_size)
      packs_sold: draft.packs,
      price_at_sale: invData.base_price_per_pack,
      subtotal: totalPrice
    });
    if (itemError) throw itemError;

    // 4. Update status di Local DB
    const { error: localError } = await localSupabase.value
      .from('wa_bot_drafts')
      .update({ status: 'confirmed' })
      .eq('id', draft.id);
    if (localError) throw localError;

    alert('✅ Pesanan Resmi Berhasil Dibuat & Stok Terpotong!');
    fetchBotDrafts();
  } catch (err: any) {
    alert('❌ Gagal konfirmasi: ' + err.message);
  }
}

async function initLocalClient() {
  if (waha.local_supabase_url && waha.local_supabase_key) {
    try {
      const { createClient } = await import('@supabase/supabase-js');
      localSupabase.value = createClient(waha.local_supabase_url, waha.local_supabase_key);
      fetchBotDrafts();
    } catch (err) {
      console.error('Local Supabase Init Error:', err);
    }
  }
}

async function fetchSettings() {
  // Fetch WAHA
  const { data: wahaData } = await supabase.from('waha_config').select('*').limit(1).single();
  if (wahaData) {
    Object.assign(waha, wahaData);
    initLocalClient();
  }
  
  fetchLogs();
}

async function handleSave() {
  saving.value = true;
  try {
    const wahaUpdate = { ...waha };
    delete (wahaUpdate as any).id; // Remove ID from payload
    const { error: wahaError } = await supabase
      .from('waha_config')
      .update(wahaUpdate)
      .eq('id', waha.id);
    if (wahaError) throw wahaError;

    alert('✅ Automation parameters synchronized.');
  } catch (err: any) {
    alert('❌ Synchronization failed: ' + err.message);
  } finally {
    saving.value = false;
  }
}

onMounted(() => {
  fetchSettings();
  // Auto-refresh logs every 10 seconds for real-time feedback
  refreshTimer = setInterval(fetchLogs, 10000);
});

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer);
});
</script>

<style scoped>
.company-settings-page { display: flex; flex-direction: column; gap: 32px; }
.header { display: flex; justify-content: space-between; align-items: center; }

.settings-grid {
  display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px;
}

.settings-card { padding: 32px; display: flex; flex-direction: column; gap: 24px; }
.card-header { display: flex; align-items: center; gap: 16px; margin-bottom: 8px; }
.card-header h3 { font-size: 1.2rem; font-weight: 800; color: white; }

.icon-wrap { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.icon-wrap.purple { color: #bb86fc; background: rgba(187, 134, 252, 0.1); }
.icon-wrap.blue { color: #00d2ff; background: rgba(0, 210, 255, 0.1); }
.icon-wrap.orange { color: #ff8c00; background: rgba(255, 140, 0, 0.1); }
.icon-wrap.green { color: #00ff9d; background: rgba(0, 255, 157, 0.1); }

.btn-ghost {
  background: transparent; border: none; color: var(--color-text-dim);
  padding: 8px; border-radius: 8px; cursor: pointer; transition: all 0.2s;
}
.btn-ghost:hover { background: rgba(255,255,255,0.05); color: white; }
.btn-ghost .spin { animation: spin 1s linear infinite; }

@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  margin-bottom: 8px;
}

.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
.full-width { grid-column: 1 / -1; }

.form-group-tactical { display: flex; flex-direction: column; gap: 8px; }
.form-group-tactical label { font-size: 0.65rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.1em; }

.input-terminal {
  display: flex; align-items: center; gap: 12px; background: rgba(0, 0, 0, 0.3);
  border: 1px solid var(--glass-border); padding: 12px 16px; border-radius: 12px;
}
.input-terminal input { background: transparent; border: none; color: white; width: 100%; font-size: 0.9rem; font-family: inherit; }
.input-terminal input:focus { outline: none; }

@media (max-width: 1200px) {
  .settings-grid { grid-template-columns: 1fr; }
}

.btn-primary-glow {
  background: var(--color-primary); color: black; border: none; padding: 14px 32px;
  border-radius: 14px; font-weight: 900; font-size: 0.85rem; cursor: pointer;
  transition: all 0.3s ease;
}
.btn-primary-glow:hover { transform: translateY(-2px); box-shadow: 0 10px 30px rgba(255, 140, 0, 0.3); }
.btn-primary-glow:disabled { opacity: 0.5; cursor: not-allowed; }

.status-banner {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 24px;
  border-radius: 12px;
  font-weight: 900;
  font-size: 0.75rem;
  letter-spacing: 0.05em;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.status-banner.connected { color: #00ff9d; background: rgba(0, 255, 157, 0.05); }
.status-banner.disconnected { color: var(--color-text-dim); background: rgba(255, 255, 255, 0.02); }

.automation-toggles { display: flex; flex-direction: column; gap: 24px; }
.toggle-row { display: flex; justify-content: space-between; align-items: center; }
.toggle-row h4 { font-size: 0.9rem; font-weight: 800; color: white; margin-bottom: 4px; }
.toggle-row p { font-size: 0.75rem; }

.mini-log-table { max-height: 240px; }
.mini-log-table table { width: 100%; border-collapse: collapse; }
.mini-log-table th { text-align: left; font-size: 0.6rem; color: var(--color-text-dim); padding-bottom: 12px; font-weight: 900; }
.mini-log-table td { padding: 12px 0; border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 0.8rem; }

.text-mono { font-family: 'JetBrains Mono', monospace; font-size: 0.7rem; opacity: 0.6; }
.preview-text { color: var(--color-text-dim); max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.status-pill-mini { font-size: 0.6rem; font-weight: 900; padding: 4px 8px; border-radius: 4px; }
.status-pill-mini.pending { background: rgba(255,255,255,0.05); color: var(--color-text-dim); }
.status-pill-mini.sent { background: rgba(0, 255, 157, 0.1); color: #00ff9d; }

.empty-mini-state { padding: 40px; text-align: center; color: var(--color-text-dim); font-size: 0.8rem; opacity: 0.5; }
.text-xs { font-size: 0.65rem; text-transform: uppercase;}
.pill-btn {
  background: rgba(255,255,255,0.05); border: none; color: var(--color-text-dim);
  padding: 4px 12px; border-radius: 20px; font-size: 0.6rem; font-weight: 900;
  cursor: pointer; transition: all 0.2s;
}
.pill-btn.active { background: var(--color-primary); color: black; }

.grade-pill {
  background: rgba(255, 140, 0, 0.1); color: var(--color-primary);
  padding: 2px 8px; border-radius: 4px; font-weight: 700;
}

.btn-action-mini {
  background: var(--color-primary); color: black; border: none;
  padding: 4px 12px; border-radius: 6px; font-size: 0.65rem; font-weight: 900;
  cursor: pointer;
}

.flex-row { display: flex; align-items: center; }
.gap-8 { gap: 8px; }
.mt-4 { margin-top: 4px; }
</style>
