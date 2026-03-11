<template>
  <div class="company-settings-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">SYSTEM PARAMETERS</h4>
        <h1 class="hero-font">Internal Configuration</h1>
        <p class="text-dim">Update business profile, branding, and automation parameters.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary-glow" @click="handleSave" :disabled="saving">
           {{ saving ? 'UPDATING CORE...' : 'SYNC CHANGES' }}
        </button>
      </div>
    </header>

    <div class="settings-grid">
      <!-- BUSINESS IDENTITY -->
      <section class="settings-card glass-panel">
        <div class="card-header">
           <div class="icon-wrap purple"><BriefcaseIcon /></div>
           <h3>Business Identity</h3>
        </div>
        
        <div class="form-grid">
           <div class="form-group-tactical full-width">
             <label>Full Registered Name</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.company_name" placeholder="Hero Farm CV" />
             </div>
           </div>
           <div class="form-group-tactical">
             <label>Public Brand Name</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.brand_name" placeholder="Hero Farm Eggs" />
             </div>
           </div>
           <div class="form-group-tactical">
             <label>Tagline</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.tagline" placeholder="Telur Bebek Terpercaya" />
             </div>
           </div>
           <div class="form-group-tactical full-width">
             <label>Business Address</label>
             <div class="input-terminal">
               <textarea v-model="settings.address" rows="3" class="textarea-terminal"></textarea>
             </div>
           </div>
        </div>
      </section>

      <!-- BILLING & TAX -->
      <section class="settings-card glass-panel">
        <div class="card-header">
           <div class="icon-wrap orange"><CreditCardIcon /></div>
           <h3>Billing & Tax</h3>
        </div>

        <div class="form-grid">
           <div class="form-group-tactical">
             <label>Default Tax (PPN %)</label>
             <div class="input-terminal">
               <input type="number" v-model="taxRate" step="0.5" />
               <span class="suffix">%</span>
             </div>
             <p class="help-text">Applied to all new invoices by default.</p>
           </div>
           <div class="form-group-tactical">
             <label>NPWP (Optional)</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.npwp" placeholder="00.000.000.0-000.000" />
             </div>
           </div>
           
           <h4 class="sub-section-title full-width mt-12">Remittance Instructions (Invoice)</h4>
           <div class="form-group-tactical">
             <label>Bank Name</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.bank_name" placeholder="Central Asia (BCA)" />
             </div>
           </div>
           <div class="form-group-tactical">
             <label>Account Number</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.bank_account" placeholder="0001234567" />
             </div>
           </div>
           <div class="form-group-tactical full-width">
             <label>Account Holder</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.bank_holder" placeholder="Fahru Hernan" />
             </div>
           </div>
        </div>
      </section>

      <!-- VISUAL BRANDING -->
      <section class="settings-card glass-panel">
        <div class="card-header">
           <div class="icon-wrap green"><PaletteIcon /></div>
           <h3>Visual Interface</h3>
        </div>

        <div class="form-grid">
           <div class="form-group-tactical full-width">
             <label>Primary Brand Color</label>
             <div class="color-picker-tactical">
                <input type="color" v-model="settings.primary_color" />
                <span class="color-hex">{{ settings.primary_color }}</span>
                <span class="color-preview" :style="{ background: settings.primary_color }"></span>
             </div>
           </div>
           <div class="form-group-tactical full-width">
             <label>Operational Hours</label>
             <div class="input-terminal">
               <input type="text" v-model="settings.operating_hours" placeholder="08.00 - 17.00 WIB" />
             </div>
           </div>
           <div class="form-group-tactical full-width">
             <label>Communication Email</label>
             <div class="input-terminal">
               <input type="email" v-model="settings.email" placeholder="contact@herofarm.com" />
             </div>
           </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  BriefcaseIcon, 
  CreditCardIcon, 
  PaletteIcon
} from 'lucide-vue-next';

const settings = reactive({
  id: '',
  company_name: '',
  brand_name: '',
  tagline: '',
  address: '',
  phone: '',
  email: '',
  npwp: '',
  bank_name: '',
  bank_account: '',
  bank_holder: '',
  operating_hours: '',
  primary_color: '#16a34a'
});

const taxRate = ref(0);
const saving = ref(false);

async function fetchSettings() {
  // Fetch Identity
  const { data: comp } = await supabase.from('company_settings').select('*').limit(1).single();
  if (comp) {
    Object.assign(settings, comp);
  }

  // Fetch Tax
  const { data: tax } = await supabase.from('tax_settings').select('rate').limit(1).single();
  if (tax) {
    taxRate.value = tax.rate;
  }
}

async function handleSave() {
  saving.value = true;
  try {
    // 1. Sync Business Identity
    const { error: compError } = await supabase
      .from('company_settings')
      .update(settings)
      .eq('id', settings.id);
    if (compError) throw compError;

    // 2. Sync Tax
    const { error: taxError } = await supabase
      .from('tax_settings')
      .update({ rate: taxRate.value })
      .eq('is_active', true);
    if (taxError) throw taxError;

    alert('✅ Operational parameters synchronized.');
  } catch (err: any) {
    alert('❌ Synchronization failed: ' + err.message);
  } finally {
    saving.value = false;
  }
}

onMounted(() => {
  fetchSettings();
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
.icon-wrap.orange { color: #ff8c00; background: rgba(255, 140, 0, 0.1); }
.icon-wrap.green { color: #00ff9d; background: rgba(0, 255, 157, 0.1); }

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
.textarea-terminal { background: transparent; border: none; color: white; width: 100%; font-size: 0.9rem; font-family: inherit; resize: none; }
.textarea-terminal:focus { outline: none; }

.suffix { color: var(--color-text-dim); font-size: 0.9rem; font-weight: 800; }
.help-text { font-size: 0.7rem; color: var(--color-text-dim); margin-top: 4px; }

.sub-section-title { font-size: 0.7rem; font-weight: 900; color: var(--color-text-dim); border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 8px; }
.mt-12 { margin-top: 12px; }

.color-picker-tactical {
  display: flex; align-items: center; gap: 16px; padding: 12px; background: rgba(0,0,0,0.2); border-radius: 12px;
}
.color-picker-tactical input { width: 40px; height: 40px; border: none; background: transparent; cursor: pointer; }
.color-hex { font-family: 'JetBrains Mono', monospace; font-size: 0.85rem; font-weight: 700; color: white; }
.color-preview { flex: 1; height: 32px; border-radius: 6px; border: 1px solid rgba(255,255,255,0.1); }

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

/* TACTICAL TABS (REUSED FROM EMPLOYEES) */
.tabs-tactical {
  display: flex;
  gap: 8px;
  padding: 4px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
}

.tab-btn {
  padding: 10px 20px;
  border: none;
  background: transparent;
  color: var(--color-text-dim);
  font-size: 0.7rem;
  font-weight: 800;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.tab-btn.active {
  background: var(--color-primary);
  color: black;
}

/* AUTOMATION SPECIFIC STYLES */
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
.text-xs { font-size: 0.65rem; }
.flex-column { display: flex; flex-direction: column; }
.me-24 { margin-right: 24px; }
</style>
