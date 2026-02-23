<template>
  <div class="employees-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">HUMAN RESOURCES</h4>
        <h1 class="hero-font">Team Management</h1>
        <p class="text-dim">Grant access levels and manage employee profiles.</p>
      </div>
      <div class="header-actions">
        <button class="btn-primary" @click="showRegisterModal = true">
          <UserPlusIcon class="icon" />
          <span>CREATE NEW MEMBER</span>
        </button>
      </div>
    </header>

    <div class="employees-grid">
      <div v-for="staff in team" :key="staff.id" class="staff-card glass-panel" :class="{ 'admin-border': staff.role === 'admin' }">
        <div class="card-header">
          <div class="staff-avatar">
            {{ (staff.full_name || staff.email || 'U').charAt(0).toUpperCase() }}
          </div>
          <div class="info">
            <h3 class="name">{{ staff.full_name || staff.email.split('@')[0] }}</h3>
            <span class="role-badge" :class="staff.role">{{ staff.role.toUpperCase() }}</span>
          </div>
        </div>
        
        <div class="card-body">
          <div class="detail-item">
            <span class="label">Identifier</span>
            <span class="value">{{ staff.email }}</span>
          </div>
          <div class="detail-item">
            <span class="label">Access Status</span>
            <span class="value" :class="staff.is_active ? 'text-success' : 'text-error'">
              {{ staff.is_active ? 'Active Access' : 'Suspended' }}
            </span>
          </div>
        </div>

        <div class="card-footer" v-if="staff.id !== authStore.user?.id">
          <div class="toggle-group">
            <label class="switch-label">Admin Rights</label>
            <button class="btn-toggle" @click="toggleRole(staff)" :class="{ active: staff.role === 'admin' }">
              {{ staff.role === 'admin' ? 'Remove Admin' : 'Make Admin' }}
            </button>
          </div>
          <button class="btn-danger-lite" @click="toggleStatus(staff)">
            {{ staff.is_active ? 'Deactivate' : 'Reactivate' }}
          </button>
        </div>
      </div>

      <div v-if="team.length === 0" class="empty-state glass-panel">
        <UsersIcon class="empty-icon" />
        <h3>Waiting for registrations</h3>
        <p>Use the button above to manually register your team members.</p>
      </div>
    </div>

    <!-- REGISTER NEW MEMBER MODAL -->
    <Teleport to="body">
      <div v-if="showRegisterModal" class="modal-overlay" @click.self="showRegisterModal = false">
        <div class="modal-card glass-panel animate-pop">
          <h2 class="hero-font">Initialize Profile</h2>
          <p class="text-dim">Set up access for a new team member. They will use these credentials to login.</p>

          <form @submit.prevent="handleRegister" class="modal-form">
            <div class="form-group">
              <label>Full Name</label>
              <input type="text" v-model="regForm.full_name" placeholder="e.g. Ahmad Sujadi" required />
            </div>

            <div class="form-group">
              <label>Email Identifier</label>
              <input type="email" v-model="regForm.email" placeholder="staff@herofarm.com" required />
            </div>

            <div class="form-group">
              <label>Temporary Password</label>
              <input type="text" v-model="regForm.password" placeholder="minimal 6 characters" required />
            </div>

            <div class="form-group">
              <CustomDropdown 
                v-model="regForm.role" 
                :options="roleOptions" 
                label="Initial Role" 
                placeholder="Select access level..."
              />
            </div>

            <div v-if="regError" class="error-text">{{ regError }}</div>

            <div class="modal-actions">
              <button type="button" class="btn-secondary" @click="showRegisterModal = false">Cancel</button>
              <button type="submit" class="btn-primary" :disabled="submitting">
                {{ submitting ? 'CREATING...' : 'CREATE ACCOUNT' }}
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
import { useAuthStore } from '../stores/auth';
import CustomDropdown from '../components/ui/CustomDropdown.vue';
import { UsersIcon, UserPlusIcon } from 'lucide-vue-next';

const authStore = useAuthStore();
const team = ref<any[]>([]);
const showRegisterModal = ref(false);
const submitting = ref(false);
const regError = ref('');

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
    .select('*')
    .order('full_name');
  
  if (data) team.value = data;
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
  const newRole = staff.role === 'admin' ? 'staff' : 'admin';
  const { error } = await supabase
    .from('profiles')
    .update({ role: newRole })
    .eq('id', staff.id);
  
  if (!error) fetchTeam();
}

async function toggleStatus(staff: any) {
  const { error } = await supabase
    .from('profiles')
    .update({ is_active: !staff.is_active })
    .eq('id', staff.id);
  
  if (!error) fetchTeam();
}

onMounted(fetchTeam);
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
  align-items: flex-end;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  margin-bottom: 8px;
}

.employees-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 24px;
}

.staff-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  border: 1px solid var(--glass-border);
}

.admin-border {
  border-color: var(--color-primary);
  background: rgba(255, 140, 0, 0.03);
}

.card-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.staff-avatar {
  width: 52px;
  height: 52px;
  background: var(--glass-border);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 1.2rem;
  border: 2px solid var(--color-primary);
}

.name { font-size: 1.1rem; color: white; margin-bottom: 4px; }

.role-badge {
  font-size: 0.65rem;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 800;
}

.role-badge.admin { background: var(--color-primary); color: white; }
.role-badge.staff { background: var(--glass-border); color: var(--color-text-dim); }

.card-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: var(--radius-md);
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.detail-item .label { font-size: 0.7rem; color: var(--color-text-dim); }
.detail-item .value { font-size: 0.85rem; font-weight: 600; }

.text-success { color: var(--color-success); }
.text-error { color: var(--color-error); }

.card-footer {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 16px;
  border-top: 1px solid var(--glass-border);
}

.toggle-group {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.switch-label { font-size: 0.8rem; font-weight: 600; }

.btn-toggle {
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--glass-border);
  background: transparent;
  color: white;
  font-size: 0.75rem;
  cursor: pointer;
  transition: var(--transition-smooth);
}

.btn-toggle.active {
  background: var(--color-primary);
  border-color: var(--color-primary);
}

.btn-danger-lite {
  background: rgba(255, 62, 62, 0.05);
  border: 1px solid rgba(255, 62, 62, 0.2);
  color: #ff3e3e;
  padding: 8px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
}

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

.modal-card { width: 100%; max-width: 550px; padding: 40px; }

.modal-form { margin-top: 24px; display: flex; flex-direction: column; gap: 20px; }

.form-group { display: flex; flex-direction: column; gap: 8px; }
.form-group label { font-size: 0.8rem; font-weight: 700; color: var(--color-text-dim); text-transform: uppercase; }
.form-group input, .form-group select {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--glass-border);
  padding: 12px;
  border-radius: var(--radius-sm);
  color: white;
  font-family: var(--font-body);
}

.modal-actions { display: flex; justify-content: flex-end; gap: 16px; margin-top: 12px; }

.btn-secondary { background: transparent; border: 1px solid var(--glass-border); color: white; padding: 12px 24px; border-radius: var(--radius-sm); cursor: pointer; }

.error-text { color: var(--color-error); font-size: 0.85rem; font-weight: 600; }

.animate-pop { animation: popIn 0.4s cubic-bezier(0.23, 1, 0.32, 1); }
@keyframes popIn {
  from { opacity: 0; transform: scale(0.9) translateY(20px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
</style>
