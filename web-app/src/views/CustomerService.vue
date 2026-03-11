<template>
  <div class="company-settings-page animate-in">
    <header class="header">
      <div class="header-left">
        <div class="brand-badge pulsate">CENTRAL OVERRIDE</div>
        <h1 class="hero-title">Automation HUB</h1>
        <p class="subtitle">Neural link status and tactical automation parameters.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary-glow" @click="handleSave" :disabled="saving">
           <div v-if="saving" class="loader-xs mr-8"></div>
           {{ saving ? 'SINKRONISASI...' : 'TERAPKAN PERUBAHAN' }}
        </button>
      </div>
    </header>

    <div class="settings-dashboard">
       <div class="main-column">
          <!-- 🛸 WAHA CONNECTIVITY -->
          <section class="settings-card glass-panel">
            <div class="card-glow purple"></div>
            <div class="card-header">
              <div class="icon-hexagon purple"><CpuIcon /></div>
              <div class="header-text">
                <h3>WhatsApp Engine (WAHA)</h3>
                <p>Main transmission gateway for tactical messaging.</p>
              </div>
              <button class="tool-btn ms-auto" @click="testWaha" :disabled="testingWaha">
                <FlaskConicalIcon class="icon-xs" :class="{'spin': testingWaha}" />
              </button>
            </div>

            <div class="form-matrix">
              <div class="matrix-input full">
                <label>WAHA Instance Endpoint</label>
                <div class="input-glow-wrap">
                  <GlobeIcon class="icon-tiny" />
                  <input type="text" v-model="waha.base_url" placeholder="http://43.x.x.x:3000" />
                </div>
              </div>
              <div class="matrix-input">
                <label>Session Identity</label>
                <div class="input-glow-wrap">
                  <UserIcon class="icon-tiny" />
                  <input type="text" v-model="waha.session_name" />
                </div>
              </div>
              <div class="matrix-input">
                <label>Authentication Token</label>
                <div class="input-glow-wrap">
                  <KeyIcon class="icon-tiny" />
                  <input type="password" v-model="waha.api_key" placeholder="••••••••" />
                </div>
              </div>

              <div class="active-status-bar" :class="waha.is_active ? 'online' : 'offline'">
                 <div class="status-content">
                    <ZapIcon v-if="waha.is_active" class="icon-xs" />
                    <ZapOffIcon v-else class="icon-xs" />
                    <span>{{ waha.is_active ? 'TRANSMISSION LINK ESTABLISHED' : 'LINK OFFLINE / TRUNCATED' }}</span>
                 </div>
                 <div class="status-deco"></div>
              </div>
            </div>
          </section>

          <!-- 🛰️ N8N AUTOMATION ENGINE -->
          <section class="settings-card glass-panel">
            <div class="card-glow blue"></div>
            <div class="card-header">
              <div class="icon-hexagon blue"><LinkIcon /></div>
              <div class="header-text">
                <h3>Neural Engine (n8n)</h3>
                <p>Workflow orchestration for complex business logic.</p>
              </div>
              <button class="tool-btn ms-auto" @click="testN8n" :disabled="testingN8n">
                <FlaskConicalIcon class="icon-xs" :class="{'spin': testingN8n}" />
              </button>
            </div>

            <div class="form-matrix">
              <div class="matrix-input full">
                <label>Automation Webhook Hook</label>
                <div class="input-glow-wrap">
                  <AnchorIcon class="icon-tiny" />
                  <input type="text" v-model="waha.n8n_webhook_url" placeholder="https://n8n.your-domain.com/webhook/..." />
                </div>
              </div>
            </div>
          </section>

          <!-- 🛡️ LOGS: RECENT TRANSMISSIONS -->
          <section class="settings-card glass-panel full-width no-padding">
             <div class="card-header pad-header">
                <div class="icon-hexagon green"><HistoryIcon /></div>
                <div class="header-text">
                  <h3>Transmission Log</h3>
                  <p>Encrypted record of recent outbound signals.</p>
                </div>
                <div class="header-tabs">
                  <button :class="{ active: logSource === 'online' }" @click="logSource = 'online'; fetchLogs()">CLOUD</button>
                  <button :class="{ active: logSource === 'local' }" @click="logSource = 'local'; fetchLogs()">LOCAL</button>
                </div>
                <button class="tool-btn ml-12" @click="fetchLogs">
                  <RefreshCcwIcon class="icon-xs" />
                </button>
             </div>

             <div class="terminal-log-viewer scroll-v">
                <table v-if="logs.length">
                  <thead>
                    <tr>
                      <th>TXID / TIMESTAMP</th>
                      <th>RECIPIENT</th>
                      <th>DATA PAYLOAD</th>
                      <th>RESULT</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="log in logs" :key="log.id" class="log-row">
                      <td class="td-ts">{{ formatTime(log.created_at) }}</td>
                      <td class="td-phone">{{ log.phone }}</td>
                      <td class="td-msg">{{ log.message }}</td>
                      <td class="td-status">
                         <div class="status-tag" :class="log.status">{{ log.status.toUpperCase() }}</div>
                      </td>
                    </tr>
                  </tbody>
                </table>
                <div v-else class="empty-terminal-state">
                   <div class="terminal-text-dim">--- NO RECORDS FOUND IN BUFFER ---</div>
                </div>
             </div>
          </section>
       </div>

       <aside class="side-column">
          <!-- ⚙️ NOTIFICATION OVERRIDES -->
          <section class="settings-card glass-panel small">
             <div class="card-header">
               <div class="icon-hexagon orange"><BellIcon /></div>
               <h3>Global Alerts</h3>
             </div>

             <div class="tactical-switches">
                <div class="switch-card">
                   <div class="switch-label">
                     <h4>Order Alert</h4>
                     <p>Auto-confirm sales</p>
                   </div>
                   <CustomToggle v-model="waha.notify_on_new_order" />
                </div>
                <div class="switch-card">
                   <div class="switch-label">
                     <h4>Logistics Link</h4>
                     <p>Driver pickup sync</p>
                   </div>
                   <CustomToggle v-model="waha.notify_on_delivery" />
                </div>
             </div>
          </section>

          <!-- 🗄️ SAFE BRIDGE (LOCAL DB) -->
          <section class="settings-card glass-panel small">
            <div class="card-header">
              <div class="icon-hexagon green"><DatabaseIcon /></div>
              <h3>Safe Bridge</h3>
            </div>
            <div class="form-matrix compact">
               <div class="matrix-input full">
                 <label>Endpoint</label>
                 <div class="input-glow-wrap">
                   <input type="text" v-model="waha.local_supabase_url" placeholder="Local API URL" />
                 </div>
               </div>
               <div class="matrix-input full">
                 <label>Secret Key</label>
                 <div class="input-glow-wrap">
                    <input type="password" v-model="waha.local_supabase_key" placeholder="••••••••" />
                 </div>
               </div>
            </div>
          </section>

          <!-- 🤖 BOT DRAFTS -->
          <section v-if="localSupabase" class="settings-card glass-panel small">
             <div class="card-header">
                <div class="icon-hexagon (yellow)"><ZapIcon /></div>
                <h3>Bot Drafts</h3>
                <button class="tool-btn ms-auto" @click="fetchBotDrafts">
                  <RefreshCcwIcon class="icon-xs" />
                </button>
             </div>
             <div class="draft-list scroll-v">
                <div v-for="draft in botDrafts" :key="draft.id" class="draft-item">
                   <div class="draft-info">
                      <span class="draft-cust">{{ draft.customer_name || 'Anonymous' }}</span>
                      <span class="draft-meta">{{ draft.egg_grade }} | {{ draft.packs }} Pack</span>
                   </div>
                   <button class="btn-confirm-mini" @click="handleConfirmDraft(draft)">OK</button>
                </div>
                <div v-if="!botDrafts.length" class="empty-draft-text">No active drafts.</div>
             </div>
          </section>
       </aside>
    </div>

    <!-- ⚡ FEEDBACK TOASTS -->
    <Teleport to="body">
       <TransitionGroup name="toast">
          <div v-for="toast in toasts" :key="toast.id" class="tactical-toast" :class="toast.type">
             <div class="toast-indicator"></div>
             <div class="toast-body">
                <h5 class="toast-title">{{ toast.title }}</h5>
                <p class="toast-msg">{{ toast.message }}</p>
             </div>
             <button @click="removeToast(toast.id)" class="toast-close">×</button>
          </div>
       </TransitionGroup>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  GlobeIcon, 
  KeyIcon, 
  CpuIcon, 
  ZapIcon, 
  ZapOffIcon,
  LinkIcon,
  FlaskConicalIcon,
  DatabaseIcon,
  HistoryIcon,
  RefreshCcwIcon,
  UserIcon,
  AnchorIcon,
  BellIcon
} from 'lucide-vue-next';
import CustomToggle from '../components/CustomToggle.vue';

const localSupabase = ref<any>(null);
const botDrafts = ref<any[]>([]);
const logSource = ref('online');
const toasts = ref<any[]>([]);

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

function addToast(title: string, message: string, type: 'success' | 'error' | 'info' = 'info') {
  const id = Date.now();
  toasts.value.push({ id, title, message, type });
  setTimeout(() => removeToast(id), 5000);
}

function removeToast(id: number) {
  toasts.value = toasts.value.filter(t => t.id !== id);
}

function formatTime(dateStr: string) {
  if (!dateStr) return '--:--';
  return new Date(dateStr).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

async function testWaha() {
  testingWaha.value = true;
  try {
    const response = await fetch(`${waha.base_url}/api/sessions`, {
      headers: waha.api_key ? { 'X-Api-Key': waha.api_key } : {}
    });
    waha.is_active = response.ok;
    if (response.ok) addToast('OPERATIONAL STATUS', 'WAHA Engine is reachable and responsive.', 'success');
    else addToast('COMMUNICATION ERROR', `Engine returned code ${response.status}: ${response.statusText}`, 'error');
  } catch (err) {
    waha.is_active = false;
    addToast('NETWORK TIMEOUT', 'Could not establish link with WAHA. Check endpoint URL.', 'error');
  } finally {
    testingWaha.value = false;
  }
}

async function testN8n() {
  if (!waha.n8n_webhook_url) {
    addToast('INPUT REQUIRED', 'Neural Webhook URL cannot be null.', 'error');
    return;
  }
  testingN8n.value = true;
  try {
    const response = await fetch(waha.n8n_webhook_url, { 
      method: 'POST',
      body: JSON.stringify({ test: true }),
      headers: { 'Content-Type': 'application/json' }
    });
    if (response.ok) addToast('AUTOMATION LIVE', 'n8n Neural Hub confirmed the handshake.', 'success');
    else addToast('INTEGRATION FAILED', 'n8n instance rejected the test payload.', 'error');
  } catch (err) {
    addToast('SIGNAL LOSS', 'Target n8n endpoint is unreachable.', 'error');
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
      .limit(20);
    if (data) logs.value = data;
  } catch (err) {
    console.error('Failed to fetch logs', err);
  }
}

async function fetchBotDrafts() {
  if (!localSupabase.value) return;
  const { data } = await localSupabase.value
    .from('wa_bot_drafts')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(10);
  if (data) botDrafts.value = data;
}

async function handleConfirmDraft(draft: any) {
  try {
    const { data: invData } = await supabase
      .from('inventory')
      .select('id, base_price_per_pack')
      .eq('grade', draft.egg_grade)
      .single();
    
    if (!invData) throw new Error(`Grade ${draft.egg_grade} unknown.`);

    const totalPrice = draft.total_est || (invData.base_price_per_pack * draft.packs);

    const { error: onlineError } = await supabase.from('sales').insert({
      customer_name: draft.customer_name,
      total_price: totalPrice,
      status: 'pending_payment',
      payment_status: 'unpaid',
      order_type: 'retail'
    });
    if (onlineError) throw onlineError;

    const { error: localError } = await localSupabase.value
      .from('wa_bot_drafts')
      .update({ status: 'confirmed' })
      .eq('id', draft.id);
    if (localError) throw localError;

    addToast('SUCCESS', 'Draft converted to official order.', 'success');
    fetchBotDrafts();
  } catch (err: any) {
    addToast('CONFIRMATION FAILED', err.message, 'error');
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
    // If id is empty string, remove it so Supabase can generate one or handle upsert
    if (!wahaUpdate.id) delete (wahaUpdate as any).id;
    
    const { error: wahaError } = await supabase
      .from('waha_config')
      .upsert(wahaUpdate);
      
    if (wahaError) throw wahaError;

    addToast('SYSTEM UPDATED', 'Parameters pushed to cloud storage.', 'success');
  } catch (err: any) {
    addToast('SYNC FAILED', err.message, 'error');
  } finally {
    saving.value = false;
  }
}

onMounted(() => {
  fetchSettings();
  refreshTimer = setInterval(fetchLogs, 10000);
});

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer);
});
</script>

<style scoped>
.company-settings-page { display: flex; flex-direction: column; gap: 40px; }
.header { display: flex; justify-content: space-between; align-items: flex-end; }
.brand-badge { color: var(--color-primary); letter-spacing: 0.3em; font-size: 0.7rem; font-weight: 900; margin-bottom: 8px; }
.hero-title { font-size: 2.8rem; font-weight: 900; line-height: 1; }
.subtitle { color: var(--color-text-dim); font-size: 1rem; opacity: 0.7; }

.settings-dashboard { display: grid; grid-template-columns: 1fr 340px; gap: 24px; }
.main-column { display: flex; flex-direction: column; gap: 24px; }
.side-column { display: flex; flex-direction: column; gap: 24px; }

.settings-card { 
  position: relative; overflow: hidden; padding: 0;
  border: 1px solid rgba(255, 255, 255, 0.05) !important;
}
.settings-card.no-padding { padding: 0; }
.settings-card.small { padding: 24px; }

.card- glow { 
  position: absolute; top: -50px; right: -50px; width: 140px; height: 140px; 
  filter: blur(60px); opacity: 0.1; z-index: 0; pointer-events: none;
}
.card-glow.purple { background: #bb86fc; }
.card-glow.blue { background: #00d2ff; }

.card-header { position: relative; z-index: 1; padding: 24px 32px; display: flex; align-items: center; gap: 20px; }
.pad-header { padding: 24px 32px; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }

.icon-hexagon {
  width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;
  background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08);
  clip-path: polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);
  color: white;
}
.icon-hexagon.purple { color: #bb86fc; border-color: rgba(187, 134, 252, 0.3); }
.icon-hexagon.blue { color: #00d2ff; border-color: rgba(0, 210, 255, 0.3); }
.icon-hexagon.orange { color: #ff8c00; border-color: rgba(255, 140, 0, 0.3); }
.icon-hexagon.green { color: #00ff9d; border-color: rgba(0, 255, 157, 0.3); }

.header-text h3 { font-size: 1.1rem; font-weight: 800; color: white; margin-bottom: 2px; }
.header-text p { font-size: 0.75rem; color: var(--color-text-dim); }

.form-matrix { padding: 0 32px 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 24px; position: relative; z-index: 1; }
.form-matrix.compact { padding: 0; gap: 16px; margin-top: 20px; }

.matrix-input { display: flex; flex-direction: column; gap: 8px; }
.matrix-input.full { grid-column: span 2; }
.matrix-input label { font-size: 0.65rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.1em; }

.input-glow-wrap {
  background: rgba(0, 0, 0, 0.4); border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px; padding: 12px 18px; display: flex; align-items: center; gap: 12px;
  transition: all 0.3s;
}
.input-glow-wrap:focus-within { border-color: var(--color-primary); box-shadow: 0 0 15px rgba(255, 140, 0, 0.1); }
.input-glow-wrap input { background: transparent; border: none; color: white; font-size: 0.95rem; width: 100%; }
.input-glow-wrap input:focus { outline: none; }

.active-status-bar {
  grid-column: span 2; position: relative; padding: 16px 24px; border-radius: 12px;
  display: flex; align-items: center; font-weight: 900; font-size: 0.75rem; overflow: hidden;
}
.active-status-bar.online { background: rgba(0, 255, 157, 0.04); color: #00ff9d; }
.active-status-bar.offline { background: rgba(255, 255, 255, 0.02); color: var(--color-text-dim); }

.status-content { position: relative; z-index: 1; display: flex; align-items: center; gap: 12px; }
.status-deco { position: absolute; left: 0; top: 0; height: 100%; width: 4px; background: currentColor; }

.terminal-log-viewer { max-height: 400px; padding: 0 32px 32px; }
.terminal-log-viewer table { width: 100%; border-collapse: collapse; }
.terminal-log-viewer th { text-align: left; font-size: 0.65rem; color: var(--color-text-dim); padding: 20px 0 12px; border-bottom: 2px solid rgba(255, 255, 255, 0.03); }
.terminal-log-viewer td { padding: 16px 0; border-bottom: 1px solid rgba(255, 255, 255, 0.02); vertical-align: middle; }

.td-ts { font-family: var(--font-mono); font-size: 0.7rem; color: var(--color-text-dim); width: 140px; }
.td-phone { font-weight: 700; color: white; width: 140px; }
.td-msg { color: var(--color-text-dim); font-size: 0.85rem; max-width: 400px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; padding-right: 20px; }

.status-tag { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 0.6rem; font-weight: 900; }
.status-tag.sent { background: rgba(0, 255, 157, 0.1); color: #00ff9d; }

.tactical-switches { display: flex; flex-direction: column; gap: 16px; margin-top: 20px; }
.switch-card { 
  display: flex; justify-content: space-between; align-items: center; 
  background: rgba(255, 255, 255, 0.02); padding: 16px; border-radius: 16px; 
}
.switch-label h4 { font-size: 0.85rem; font-weight: 800; color: white; margin-bottom: 2px; }
.switch-label p { font-size: 0.7rem; color: var(--color-text-dim); }

.draft-item { display: flex; justify-content: space-between; align-items: center; padding: 14px 0; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.draft-cust { display: block; font-weight: 700; color: white; font-size: 0.85rem; }
.draft-meta { font-size: 0.7rem; color: var(--color-text-dim); }

.header-tabs { display: flex; background: rgba(0, 0, 0, 0.2); padding: 4px; border-radius: 10px; }
.header-tabs button { background: transparent; border: none; color: var(--color-text-dim); padding: 6px 14px; border-radius: 8px; font-size: 0.65rem; font-weight: 900; cursor: pointer; transition: all 0.3s; }
.header-tabs button.active { background: white; color: black; }

.tactical-toast { 
  position: fixed; bottom: 32px; right: 32px; width: 340px; 
  background: #111; border: 1px solid rgba(255, 255, 255, 0.1); 
  border-radius: 16px; padding: 20px; display: flex; gap: 16px; z-index: 9999;
  box-shadow: 0 20px 50px rgba(0,0,0,0.5);
}
.toast-indicator { width: 4px; border-radius: 2px; flex-shrink: 0; }
.tactical-toast.success .toast-indicator { background: #00ff9d; }
.tactical-toast.error .toast-indicator { background: #ff4d4d; }
.toast-title { font-size: 0.75rem; font-weight: 900; color: white; letter-spacing: 0.1em; margin-bottom: 4px; }
.toast-msg { font-size: 0.85rem; color: var(--color-text-dim); }
.toast-close { background: transparent; border: none; color: white; font-size: 1.2rem; cursor: pointer; }

.animate-in { animation: slide-up 0.5s ease-out; }
@keyframes slide-up { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

.tool-btn {
  background: rgba(255, 255, 255, 0.04); border: 1px solid rgba(255, 255, 255, 0.08); 
  color: var(--color-text-dim); padding: 10px; border-radius: 12px; cursor: pointer; transition: all 0.3s;
}
.tool-btn:hover { color: white; background: rgba(255, 255, 255, 0.1); transform: rotate(15deg); }
.spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

.ml-12 { margin-left: 12px; }
.mr-8 { margin-right: 8px; }
.loader-xs { width: 14px; height: 14px; border: 2px solid rgba(0,0,0,0.1); border-top-color: black; border-radius: 50%; animation: spin 0.6s linear infinite; }
</style>
