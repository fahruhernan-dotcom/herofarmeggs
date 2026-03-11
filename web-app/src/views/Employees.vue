<template>
  <div class="employees-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">PERSONNEL COMMAND</h4>
        <h1 class="hero-font">Team Registry</h1>
        <p class="text-dim">Operational clearance and personnel management.</p>
      </div>
      <div class="header-actions">
        <div class="search-box glass-panel">
          <SearchIcon class="icon-xs" />
          <input type="text" v-model="searchQuery" placeholder="Search operative..." />
        </div>
        <button class="btn-primary-glow" @click="showRegisterModal = true">
          <UserPlusIcon class="icon-sm" />
          <span>INITIALIZE NEW OPERATIVE</span>
        </button>
      </div>
    </header>

    <!-- PERSONNEL STATS HUB -->
    <section class="stats-hub-tactical">
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon purple"><UsersIcon /></div>
        <div class="s-info">
          <span class="s-label">Total Personnel</span>
          <span class="s-value">{{ team.length }}</span>
        </div>
      </div>
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon orange"><ShieldCheckIcon /></div>
        <div class="s-info">
          <span class="s-label">Admins Clearanced</span>
          <span class="s-value">{{ team.filter(t => t.role === 'admin').length }}</span>
        </div>
      </div>
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon green"><ActivityIcon /></div>
        <div class="s-info">
          <span class="s-label">Active Operatives</span>
          <span class="s-value">{{ team.filter(t => t.is_active).length }}</span>
        </div>
      </div>
    </section>

    <div class="employees-grid">
      <div v-for="staff in filteredTeam" :key="staff.id" class="staff-card-tactical glass-panel" :class="{ 'admin-clearance': staff.role === 'admin', 'owner-card': isSuperAdmin(staff) }">
        <div class="card-glow-effect"></div>

        <!-- SUPER ADMIN PROTECTED BADGE -->
        <div v-if="isSuperAdmin(staff)" class="owner-badge">
          <ShieldCheckIcon class="icon-xs" />
          <span>OWNER · PROTECTED</span>
        </div>

        <div class="staff-header-tactical">
          <div class="avatar-terminal">
            <span class="avatar-text">{{ (staff.full_name || staff.email).charAt(0).toUpperCase() }}</span>
            <div class="presence-indicator" :class="{ 'online': staff.is_active }"></div>
          </div>
          <div class="staff-title">
            <h3 class="name">{{ staff.full_name || 'Classified Unit' }}</h3>
            <p class="email-tag">{{ staff.email }}</p>
          </div>
        </div>
        
        <div class="card-clearance-info">
          <div class="clearance-pill" :class="staff.role">
            <ShieldIcon v-if="staff.role === 'admin'" class="icon-xs" />
            <span class="label">{{ staff.role.toUpperCase() }} LEVEL</span>
          </div>
          <div class="position-badge glass-panel text-xs">
            {{ staff.staff_positions?.name || 'OPERATIVE' }}
          </div>
          <div class="status-pill-tactical" :class="staff.is_active ? 'active' : 'suspended'">
            {{ staff.is_active ? 'OPERATIONAL' : 'SUSPENDED' }}
          </div>
        </div>

        <!-- NEW: PERSONNEL LEDGER ACTION -->
        <button class="btn-ledger-access" @click="openPersonnelLedger(staff)">
          <BookTextIcon class="icon-xs" />
          <span>PERSONNEL LEDGER</span>
          <ArrowRightIcon class="icon-xs ms-auto" />
        </button>

        <!-- ACTIONS: Hidden for Super Admin card, visible for others -->
        <div class="card-actions-terminal" v-if="!isSuperAdmin(staff) && authStore.isAdmin">
          <div class="action-group">
            <label>Security Clearance</label>
            <div class="action-btns">
              <button 
                class="btn-action" 
                :class="{ 'active': staff.role === 'admin' }"
                @click="toggleRole(staff)"
              >
                <ShieldAlertIcon v-if="staff.role !== 'admin'" class="icon-xs" />
                <ShieldOffIcon v-else class="icon-xs" />
                {{ staff.role === 'admin' ? 'Revoke Admin' : 'Grant Admin' }}
              </button>
              <button 
                class="btn-action danger" 
                @click="toggleStatus(staff)"
              >
                <ZapOffIcon v-if="staff.is_active" class="icon-xs" />
                <ZapIcon v-else class="icon-xs" />
                {{ staff.is_active ? 'Suspend Access' : 'Restore Access' }}
              </button>
            </div>
          </div>
          <button class="btn-action danger full-width" @click="confirmDelete(staff)">
            <Trash2Icon class="icon-xs" />
            Delete Account Permanently
          </button>
        </div>
      </div>

      <div v-if="team.length === 0" class="empty-state glass-panel">
        <UsersIcon class="empty-icon" />
        <h3>Waiting for registrations</h3>
        <p>Use the button above to manually register your team members.</p>
      </div>
    </div>

    <!-- DELETE CONFIRMATION MODAL -->
    <Teleport to="body">
      <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
        <div class="modal-card glass-panel animate-pop delete-modal">
          <div class="delete-icon-wrap">
            <Trash2Icon class="delete-icon" />
          </div>
          <h2 class="hero-font">Terminate Account</h2>
          <p class="text-dim">You are about to permanently remove <strong>{{ deleteTarget?.full_name || deleteTarget?.email }}</strong> from the system. This action cannot be undone.</p>
          
          <div class="delete-info-box">
            <div class="info-row">
              <span class="info-label">Email</span>
              <span class="info-value">{{ deleteTarget?.email }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Role</span>
              <span class="info-value">{{ deleteTarget?.role?.toUpperCase() }}</span>
            </div>
          </div>

          <div class="modal-actions">
            <button class="btn-secondary-tactical" @click="showDeleteModal = false">ABORT</button>
            <button class="btn-delete-confirm" :disabled="deleting" @click="executeDelete">
              <Trash2Icon v-if="!deleting" class="icon-xs" />
              <div v-else class="spinner-sm"></div>
              {{ deleting ? 'TERMINATING...' : 'CONFIRM TERMINATION' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- REGISTER NEW MEMBER MODAL -->
    <Teleport to="body">
      <div v-if="showRegisterModal" class="modal-overlay" @click.self="showRegisterModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Initialize Profile</h2>
          <p class="text-dim">Set up access for a new team member. They will use these credentials to login.</p>

          <form @submit.prevent="handleRegister" class="modal-form">
            <div class="form-group-tactical">
              <label>Full Name</label>
              <div class="input-terminal">
                <UserIcon class="icon-xs" />
                <input type="text" v-model="regForm.full_name" placeholder="e.g. Ahmad Sujadi" required />
              </div>
            </div>

            <div class="form-group-tactical">
              <label>Email Identifier</label>
              <div class="input-terminal">
                <MailIcon class="icon-xs" />
                <input type="email" v-model="regForm.email" placeholder="staff@herofarm.com" required />
              </div>
            </div>

            <div class="form-group-tactical">
              <label>Temporary Password</label>
              <div class="input-terminal">
                <KeyIcon class="icon-xs" />
                <input type="text" v-model="regForm.password" placeholder="minimal 6 characters" required />
              </div>
            </div>

            <div class="form-group-tactical">
              <label>Clearance Level</label>
              <CustomDropdown 
                v-model="regForm.role" 
                :options="roleOptions" 
                placeholder="Select access level..."
              />
            </div>

            <div v-if="regError" class="error-text">{{ regError }}</div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary-tactical" @click="showRegisterModal = false">ABORT</button>
              <button type="submit" class="btn-primary-glow" :disabled="submitting">
                {{ submitting ? 'INITIALIZING...' : 'AUTHORIZE ACCOUNT' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- PERSONNEL LEDGER MODAL (PHASE 2) -->
    <Teleport to="body">
      <div v-if="showLedgerModal" class="modal-overlay" @click.self="showLedgerModal = false">
        <div class="modal-card ledger-modal glass-panel animate-pop">
          <div class="ledger-header">
            <div class="staff-header-tactical">
              <div class="avatar-terminal">
                <span class="avatar-text">{{ (activeOperative?.full_name || activeOperative?.email).charAt(0).toUpperCase() }}</span>
              </div>
              <div class="staff-title">
                <h2 class="hero-font">{{ activeOperative?.full_name || 'Personnel Profile' }}</h2>
                <p class="text-dim">{{ activeOperative?.email }}</p>
              </div>
            </div>
            <button class="btn-close" @click="showLedgerModal = false">✕</button>
          </div>

          <!-- TACTICAL TABS -->
          <div class="tabs-tactical">
            <button 
              v-for="tab in ['OVERVIEW', 'CONTRACT', 'FINANCE', 'PAYROLL']" 
              :key="tab"
              class="tab-btn" 
              :class="{ 'active': activeLedgerTab === tab }"
              @click="activeLedgerTab = tab"
            >
              {{ tab }}
            </button>
          </div>

          <div class="ledger-content scroll-y">
            <!-- TAB: OVERVIEW -->
            <div v-if="activeLedgerTab === 'OVERVIEW'" class="tab-pane animate-fade">
              <div class="form-grid">
                <div class="form-group-tactical">
                  <label>Service Position</label>
                  <CustomDropdown 
                    v-model="activeOperative.position_id" 
                    :options="staffPositions.map(p => ({ label: p.name, value: p.id }))"
                    placeholder="Select position..."
                  />
                </div>
                <div class="form-group-tactical">
                  <label>Employment Status</label>
                  <CustomDropdown 
                    v-model="activeOperative.employment_status" 
                    :options="[
                      { label: 'Active Service', value: 'active' },
                      { label: 'On Leave', value: 'on_leave' },
                      { label: 'Inactive / Record Only', value: 'inactive' },
                      { label: 'Terminated', value: 'terminated' }
                    ]"
                  />
                </div>
                <div class="form-group-tactical">
                  <label>Base Monthly Salary</label>
                  <div class="input-terminal">
                    <DollarSignIcon class="icon-xs" />
                    <input type="number" v-model="activeOperative.salary" placeholder="0" />
                  </div>
                </div>
                <div class="form-group-tactical">
                  <label>Start of Operations</label>
                  <div class="input-terminal">
                    <ActivityIcon class="icon-xs" />
                    <input type="date" v-model="activeOperative.start_date" />
                  </div>
                </div>
              </div>
            </div>

            <!-- TAB: CONTRACT -->
            <div v-if="activeLedgerTab === 'CONTRACT'" class="tab-pane animate-fade">
              <div class="contract-status-box glass-panel" v-if="!activeOperative.contract">
                <InfoIcon class="icon-sm" />
                <span>No active electronic contract found for this operative.</span>
                <button class="btn-action-small">AUTHORIZE CONTRACT</button>
              </div>
              <div v-else class="contract-details card-row">
                 <FileTextIcon />
                 <div class="info">
                   <p class="label">PERMANENT CONTRACT</p>
                   <p class="value">CN-2026-03948</p>
                 </div>
                 <button class="btn-icon-terminal">VIEW</button>
              </div>
            </div>

            <!-- TAB: FINANCE (Allowances & Bank) -->
            <div v-if="activeLedgerTab === 'FINANCE'" class="tab-pane animate-fade">
              <h4 class="section-title">BANKING INFRASTRUCTURE</h4>
              <div class="form-grid">
                <div class="form-group-tactical">
                  <label>Bank Institution</label>
                  <div class="input-terminal">
                    <CreditCardIcon class="icon-xs" />
                    <input type="text" v-model="activeOperative.bank_name" placeholder="e.g. BCA, BRI" />
                  </div>
                </div>
                <div class="form-group-tactical">
                  <label>Account Number</label>
                  <div class="input-terminal">
                    <CreditCardIcon class="icon-xs" />
                    <input type="text" v-model="activeOperative.bank_account" placeholder="Account identifier" />
                  </div>
                </div>
                <div class="form-group-tactical full-width">
                  <label>Account Holder Name</label>
                  <div class="input-terminal">
                    <UserIcon class="icon-xs" />
                    <input type="text" v-model="activeOperative.bank_holder" placeholder="Matches bank records" />
                  </div>
                </div>
              </div>

              <h4 class="section-title mt-24">TACTICAL ALLOWANCES</h4>
              <div class="allowance-list">
                <div class="allowance-item glass-panel">
                  <span>Transport Allowance</span>
                  <span class="text-green">Rp 250,000</span>
                  <button class="btn-icon-danger">✕</button>
                </div>
                <button class="btn-add-allowance">
                  <PlusIcon class="icon-xs" />
                  <span>ADD ALLOWANCE</span>
                </button>
              </div>
            </div>

            <!-- TAB: PAYROLL -->
            <div v-if="activeLedgerTab === 'PAYROLL'" class="tab-pane animate-fade">
              <div class="payroll-action-summary glass-panel mb-24">
                <div class="p-info">
                  <p class="p-label">Next Processing Date</p>
                  <p class="p-value">April 01, 2026</p>
                </div>
                <button class="btn-primary-glow">GENERATE SLIP</button>
              </div>

              <h4 class="section-title">COMPENSATION HISTORY</h4>
              <div class="history-list">
                 <div class="history-item glass-panel">
                   <div class="h-date">MAR 2026</div>
                   <div class="h-status paid">PAID</div>
                   <div class="h-amount">Rp {{ formatNumber(activeOperative.salary) }}</div>
                   <button class="btn-icon-terminal">SLIP</button>
                 </div>
              </div>
            </div>
          </div>

          <div class="modal-actions-ledger">
            <div class="status-msg" v-if="saveStatus">{{ saveStatus }}</div>
            <button class="btn-secondary-tactical" @click="showLedgerModal = false">DISMISS</button>
            <button class="btn-primary-glow" @click="savePersonnelData" :disabled="saving">
              {{ saving ? 'UPDATING ARCHIVE...' : 'SYNC LEDGER DATA' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, reactive, computed, watch } from 'vue';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../stores/auth';
import { useRoute } from 'vue-router';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import { 
  UsersIcon, 
  UserPlusIcon, 
  ShieldCheckIcon, 
  ActivityIcon, 
  SearchIcon,
  ShieldIcon,
  ShieldAlertIcon,
  ShieldOffIcon,
  ZapIcon,
  ZapOffIcon,
  KeyIcon,
  MailIcon,
  UserIcon,
  Trash2Icon,
  BookTextIcon,
  ArrowRightIcon,
  DollarSignIcon,
  InfoIcon,
  CreditCardIcon,
  PlusIcon,
  FileTextIcon
} from 'lucide-vue-next';

const authStore = useAuthStore();

const SUPER_ADMIN_EMAIL = 'fahruhernansakti@gmail.com';
function isSuperAdmin(staff: any) {
  // Check by email if available
  if (staff.email === SUPER_ADMIN_EMAIL) return true;
  // Check by matching logged-in Super Admin's user ID
  if (authStore.user?.email === SUPER_ADMIN_EMAIL && staff.id === authStore.user?.id) return true;
  return false;
}

const team = ref<any[]>([]);
const searchQuery = ref('');
const showRegisterModal = ref(false);
const showDeleteModal = ref(false);
const deleteTarget = ref<any>(null);
const deleting = ref(false);
const submitting = ref(false);
const regError = ref('');

// Personnel Ledger View
const showLedgerModal = ref(false);
const activeOperative = ref<any>(null);
const staffPositions = ref<any[]>([]);
const activeLedgerTab = ref('OVERVIEW');
const saving = ref(false);
const saveStatus = ref('');

function formatNumber(num: number) {
  return new Intl.NumberFormat('id-ID').format(num || 0);
}

const filteredTeam = computed(() => {
  if (!searchQuery.value) return team.value;
  const q = searchQuery.value.toLowerCase();
  return team.value.filter(t => 
    (t.full_name?.toLowerCase() || '').includes(q) || 
    t.email.toLowerCase().includes(q)
  );
});

const regForm = reactive({
  full_name: '',
  email: '',
  password: '',
  role: 'staff'
});

const roleOptions = [
  { label: 'Staff (Limited Access)', value: 'staff' },
  { label: 'Admin (Full Access)', value: 'admin' }
];

async function fetchTeam() {
  const { data } = await supabase
    .from('profiles')
    .select('*, staff_positions(*)')
    .order('full_name');
  
  if (data) team.value = data;
}

async function fetchPositions() {
  const { data } = await supabase
    .from('staff_positions')
    .select('*')
    .eq('is_active', true)
    .order('sort_order', { ascending: true });
  
  if (data) staffPositions.value = data;
}

function openPersonnelLedger(staff: any) {
  activeOperative.value = { ...staff };
  activeLedgerTab.value = 'OVERVIEW';
  showLedgerModal.value = true;
}

async function savePersonnelData() {
  if (!activeOperative.value) return;
  saving.value = true;
  saveStatus.value = '';

  try {
    const { error } = await supabase
      .from('profiles')
      .update({
        position_id: activeOperative.value.position_id,
        salary: activeOperative.value.salary,
        bank_name: activeOperative.value.bank_name,
        bank_account: activeOperative.value.bank_account,
        bank_holder: activeOperative.value.bank_holder,
        employment_status: activeOperative.value.employment_status,
        start_date: activeOperative.value.start_date
      })
      .eq('id', activeOperative.value.id);

    if (error) throw error;
    
    saveStatus.value = '✅ Ledger synchronized successfully.';
    fetchTeam();
    
    setTimeout(() => {
      saveStatus.value = '';
    }, 3000);
  } catch (err: any) {
    saveStatus.value = '❌ Error: ' + err.message;
  } finally {
    saving.value = false;
  }
}

async function handleRegister() {
  submitting.value = true;
  regError.value = '';

  try {
    // We use an RPC call because regular signup would log the current admin out.
    // This requires a database function 'register_new_staff' to be created first.
    const { error } = await supabase.rpc('register_new_staff', {
      new_email: regForm.email,
      new_password: regForm.password,
      new_full_name: regForm.full_name,
      new_role: regForm.role
    });

    if (error) throw error;

    alert('Success! Team member ' + regForm.full_name + ' has been registered.');
    showRegisterModal.value = false;
    
    // Reset form
    regForm.full_name = '';
    regForm.email = '';
    regForm.password = '';
    regForm.role = 'staff';

    fetchTeam();
  } catch (err: any) {
    console.error('Registration Error:', err);
    regError.value = 'Gagal daftar: ' + (err.message || 'Cek SQL Editor Anda.');
  } finally {
    submitting.value = false;
  }
}

async function toggleRole(staff: any) {
  if (isSuperAdmin(staff)) return alert('⛔ Cannot modify Owner account.');
  const newRole = staff.role === 'admin' ? 'staff' : 'admin';
  const { error } = await supabase
    .from('profiles')
    .update({ role: newRole })
    .eq('id', staff.id);
  
  if (!error) fetchTeam();
}

async function toggleStatus(staff: any) {
  if (isSuperAdmin(staff)) return alert('⛔ Cannot modify Owner account.');
  const { error } = await supabase
    .from('profiles')
    .update({ is_active: !staff.is_active })
    .eq('id', staff.id);
  
  if (!error) fetchTeam();
}

function confirmDelete(staff: any) {
  if (isSuperAdmin(staff)) return alert('⛔ Owner account is permanently protected.');
  deleteTarget.value = staff;
  showDeleteModal.value = true;
}

async function executeDelete() {
  if (!deleteTarget.value || isSuperAdmin(deleteTarget.value)) return;
  deleting.value = true;
  try {
    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', deleteTarget.value.id);
    
    if (error) throw error;
    
    showDeleteModal.value = false;
    deleteTarget.value = null;
    fetchTeam();
  } catch (err: any) {
    alert('Delete failed: ' + (err.message || 'Unknown error'));
  } finally {
    deleting.value = false;
  }
}

const route = useRoute();
onMounted(() => {
  fetchTeam();
  fetchPositions();
});

onUnmounted(() => {
});

// Force refresh when route changes
watch(() => route.path, () => {
  fetchTeam();
});
</script>

<style scoped>
.employees-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 16px;
  align-items: center;
}

.search-box {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 14px;
  width: 300px;
}

.search-box input {
  background: transparent;
  border: none;
  color: white;
  font-size: 0.85rem;
  width: 100%;
}

.search-box input:focus { outline: none; }

/* STATS HUB TACTICAL */
.stats-hub-tactical {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.stat-card-tactical {
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 20px;
  position: relative;
  overflow: hidden;
}

.s-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.05);
}

.s-icon svg { width: 24px; height: 24px; }
.s-icon.purple { color: #bb86fc; background: rgba(187, 134, 252, 0.1); }
.s-icon.orange { color: #ff8c00; background: rgba(255, 140, 0, 0.1); }
.s-icon.green { color: #00ff9d; background: rgba(0, 255, 157, 0.1); }

.s-info { display: flex; flex-direction: column; }
.s-label { font-size: 0.7rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.1em; }
.s-value { font-size: 1.5rem; font-weight: 900; color: white; }

/* STAFF CARD TACTICAL */
.employees-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 24px;
}

.staff-card-tactical {
  padding: 32px;
  position: relative;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);
  display: flex;
  flex-direction: column;
  gap: 24px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.staff-card-tactical:hover {
  transform: translateY(-5px);
  border-color: rgba(255, 255, 255, 0.15);
  background: rgba(255, 255, 255, 0.03);
}

.admin-clearance {
  border-color: rgba(255, 140, 0, 0.2);
  background: linear-gradient(135deg, rgba(255, 140, 0, 0.03), transparent);
}

.card-glow-effect {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background: radial-gradient(circle at top right, rgba(255,255,255,0.03), transparent 70%);
  pointer-events: none;
}

.staff-header-tactical {
  display: flex;
  align-items: center;
  gap: 20px;
}

.avatar-terminal {
  position: relative;
  width: 64px;
  height: 64px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--glass-border);
}

.avatar-text { font-size: 1.5rem; font-weight: 900; color: white; }

.presence-indicator {
  position: absolute;
  top: -4px; right: -4px;
  width: 12px; height: 12px;
  border-radius: 50%;
  background: #333;
  border: 2px solid #0a0a0a;
}

.presence-indicator.online {
  background: var(--color-success);
  box-shadow: 0 0 10px var(--color-success);
}

.staff-title .name { font-size: 1.2rem; font-weight: 800; color: white; margin-bottom: 4px; }
.email-tag { font-size: 0.8rem; color: var(--color-text-dim); font-family: 'JetBrains Mono', monospace; }

.card-clearance-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
}

.clearance-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.65rem;
  font-weight: 900;
  color: var(--color-text-dim);
}

.clearance-pill.admin { color: var(--color-primary); }

.status-pill-tactical {
  font-size: 0.6rem;
  font-weight: 950;
  padding: 4px 10px;
  border-radius: 6px;
  letter-spacing: 0.05em;
}

.status-pill-tactical.active { background: rgba(0, 255, 157, 0.1); color: #00ff9d; }
.status-pill-tactical.suspended { background: rgba(255, 66, 66, 0.1); color: #ff4242; }

.card-actions-terminal {
  padding-top: 16px;
  border-top: 1px solid rgba(255,255,255,0.05);
}

.action-group label {
  font-size: 0.6rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  margin-bottom: 12px;
  display: block;
}

.action-btns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.btn-action {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 10px;
  border-radius: 10px;
  font-size: 0.75rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-action:hover { background: rgba(255, 255, 255, 0.08); }
.btn-action.active { border-color: var(--color-primary); color: var(--color-primary); background: rgba(255, 140, 0, 0.05); }

.btn-action.danger { color: #ff6b6b; border-color: rgba(255, 107, 107, 0.1); }
.btn-action.danger:hover { background: rgba(255, 107, 107, 0.1); }

/* MODAL TACTICAL */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(12px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-card {
  width: 100%;
  max-width: 500px;
  padding: 48px;
  border-radius: 32px;
  position: relative;
}

.modal-card h2 { margin-bottom: 8px; font-size: 2rem; }

.modal-form { margin-top: 32px; display: flex; flex-direction: column; gap: 24px; }

.form-group-tactical { display: flex; flex-direction: column; gap: 10px; }
.form-group-tactical label { font-size: 0.7rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; letter-spacing: 0.1em; }

.input-terminal {
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid var(--glass-border);
  padding: 14px 18px;
  border-radius: 14px;
  transition: all 0.3s ease;
}

.input-terminal:focus-within { border-color: var(--color-primary); box-shadow: 0 0 20px rgba(255, 140, 0, 0.1); }

.input-terminal input { background: transparent; border: none; color: white; width: 100%; font-size: 0.95rem; }
.input-terminal input:focus { outline: none; }
.input-terminal svg { color: var(--color-primary); opacity: 0.5; }

.modal-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }

.btn-primary-glow {
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 14px 24px;
  border-radius: 14px;
  font-weight: 900;
  font-size: 0.85rem;
  letter-spacing: 0.05em;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 10px 30px rgba(255, 140, 0, 0.2);
}

.btn-primary-glow:hover { transform: translateY(-2px); box-shadow: 0 15px 40px rgba(255, 140, 0, 0.3); }

.btn-secondary-tactical {
  background: transparent;
  border: 1px solid var(--glass-border);
  color: white;
  padding: 14px 24px;
  border-radius: 14px;
  font-weight: 800;
  cursor: pointer;
}

.animate-pop { animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

/* OWNER PROTECTION */
.owner-card {
  border-color: rgba(0, 255, 157, 0.2) !important;
  background: linear-gradient(135deg, rgba(0, 255, 157, 0.02), transparent) !important;
}

.owner-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.6rem;
  font-weight: 950;
  letter-spacing: 0.12em;
  color: #00ff9d;
  padding: 6px 14px;
  background: rgba(0, 255, 157, 0.06);
  border: 1px solid rgba(0, 255, 157, 0.15);
  border-radius: 8px;
  width: fit-content;
}

.btn-action.full-width {
  grid-column: 1 / -1;
  margin-top: 8px;
  background: rgba(255, 66, 66, 0.05);
  border-color: rgba(255, 66, 66, 0.15);
}

/* DELETE MODAL */
.delete-modal {
  text-align: center;
}

.delete-icon-wrap {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: rgba(255, 66, 66, 0.1);
  border: 1px solid rgba(255, 66, 66, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
}

.delete-icon {
  width: 28px;
  height: 28px;
  color: #ff4242;
}

.delete-info-box {
  background: rgba(0, 0, 0, 0.3);
  border-radius: 14px;
  padding: 16px 20px;
  margin: 20px 0;
  text-align: left;
}

.info-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
}

.info-row + .info-row {
  border-top: 1px solid rgba(255,255,255,0.05);
}

.info-label { font-size: 0.7rem; color: var(--color-text-dim); font-weight: 700; }
.info-value { font-size: 0.8rem; color: white; font-weight: 800; }

.btn-delete-confirm {
  background: #ff4242;
  color: white;
  border: none;
  padding: 14px 24px;
  border-radius: 14px;
  font-weight: 900;
  font-size: 0.8rem;
  letter-spacing: 0.05em;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 10px 30px rgba(255, 66, 66, 0.2);
}

.btn-delete-confirm:hover { transform: translateY(-2px); box-shadow: 0 15px 40px rgba(255, 66, 66, 0.3); }
.btn-delete-confirm:disabled { opacity: 0.4; cursor: not-allowed; }

.spinner-sm {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.2);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.error-text { color: #ff4242; font-size: 0.85rem; font-weight: 700; }

.empty-state {
  grid-column: 1 / -1;
  padding: 60px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}

.empty-icon { width: 48px; height: 48px; opacity: 0.1; }

/* NEW UI ELEMENTS: Personnel Ledger & Position */
.position-badge {
  padding: 4px 10px;
  border-radius: 6px;
  color: var(--color-primary);
  font-weight: 800;
  letter-spacing: 0.05em;
  background: rgba(255, 140, 0, 0.05);
}

.btn-ledger-access {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  border-radius: 12px;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 700;
  font-size: 0.85rem;
}

.btn-ledger-access:hover {
  background: rgba(255, 255, 255, 0.07);
  border-color: rgba(255, 255, 255, 0.2);
  transform: translateX(4px);
}

/* LEDGER MODAL */
.ledger-modal {
  max-width: 800px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.ledger-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.btn-close {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 1.2rem;
  cursor: pointer;
  padding: 8px;
}

.tabs-tactical {
  display: flex;
  gap: 8px;
  padding: 4px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
}

.tab-btn {
  flex: 1;
  padding: 10px;
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

.ledger-content {
  max-height: 50vh;
  min-height: 300px;
  padding-right: 12px;
}

.section-title {
  font-size: 0.75rem;
  font-weight: 900;
  color: var(--color-primary);
  letter-spacing: 0.15em;
  margin-bottom: 20px;
  padding-bottom: 8px;
  border-bottom: 1px solid rgba(255, 140, 0, 0.1);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.full-width { grid-column: 1 / -1; }

.card-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 16px;
  border: 1px solid var(--glass-border);
}

.contract-status-box {
  padding: 32px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  color: var(--color-text-dim);
}

.btn-action-small {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 0.7rem;
  font-weight: 700;
  cursor: pointer;
}

.allowance-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.allowance-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 20px;
}

.btn-add-allowance {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px;
  border: 1px dashed rgba(255, 255, 255, 0.1);
  background: transparent;
  color: var(--color-text-dim);
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  font-size: 0.75rem;
  width: 100%;
}

.btn-add-allowance:hover {
  background: rgba(255, 255, 255, 0.02);
  color: white;
}

.payroll-action-summary {
  padding: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, rgba(255, 140, 0, 0.05), transparent);
}

.p-label { font-size: 0.7rem; color: var(--color-text-dim); font-weight: 700; }
.p-value { font-size: 1.1rem; color: white; font-weight: 900; margin-top: 4px; }

.history-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
}

.h-date { flex: 1; font-weight: 800; font-family: 'JetBrains Mono', monospace; }
.h-status.paid { color: #00ff9d; font-size: 0.65rem; font-weight: 900; background: rgba(0, 255, 157, 0.1); padding: 4px 10px; border-radius: 6px; }
.h-amount { font-weight: 950; min-width: 120px; text-align: right; }

.btn-icon-terminal {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  color: white;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
}

.modal-actions-ledger {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 20px;
  padding-top: 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}

.status-msg {
  flex: 1;
  font-size: 0.85rem;
  font-weight: 700;
}

.mt-24 { margin-top: 24px; }
.mb-24 { margin-bottom: 24px; }
.ms-auto { margin-left: auto; }
.text-green { color: #00ff9d; font-weight: 800; }

.scroll-y { overflow-y: auto; }
.scroll-y::-webkit-scrollbar { width: 6px; }
.scroll-y::-webkit-scrollbar-thumb { background: rgba(255, 140, 0, 0.2); border-radius: 10px; }

.animate-fade { animation: fadeIn 0.4s ease; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
</style>
