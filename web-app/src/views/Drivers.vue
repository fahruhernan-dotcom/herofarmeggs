<template>
  <div class="drivers-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">LOGISTICS COMMAND</h4>
        <h1 class="hero-font">Driver Registry</h1>
        <p class="text-dim">Fleet management and delivery operations.</p>
      </div>
      <div class="header-actions">
        <div class="search-box glass-panel">
          <SearchIcon class="icon-xs" />
          <input type="text" v-model="searchQuery" placeholder="Search driver..." />
        </div>
        <button class="btn-primary-glow" @click="showAddModal = true">
          <TruckIcon class="icon-sm" />
          <span>RECRUIT NEW DRIVER</span>
        </button>
      </div>
    </header>

    <!-- LOGISTICS STATS -->
    <section class="stats-hub-tactical">
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon purple"><TruckIcon /></div>
        <div class="s-info">
          <span class="s-label">Total Fleet</span>
          <span class="s-value">{{ drivers.length }}</span>
        </div>
      </div>
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon orange"><PackageIcon /></div>
        <div class="s-info">
          <span class="s-label">Active Deliveries</span>
          <span class="s-value">{{ activeDeliveriesCount }}</span>
        </div>
      </div>
      <div class="stat-card-tactical glass-panel">
        <div class="s-icon green"><CheckCircleIcon /></div>
        <div class="s-info">
          <span class="s-label">Completion Rate</span>
          <span class="s-value">98.5%</span>
        </div>
      </div>
    </section>

    <div class="drivers-grid">
      <div v-for="driver in filteredDrivers" :key="driver.id" class="driver-card glass-panel" :class="{ 'inactive': !driver.is_active }">
        <div class="card-glow"></div>
        
        <div class="driver-header">
           <div class="avatar-fleet">
             <TruckIcon class="icon-sm" />
           </div>
           <div class="driver-info">
             <h3>{{ driver.full_name }}</h3>
             <p class="vehicle-tag">{{ driver.vehicle_info || 'No vehicle data' }}</p>
           </div>
           <div class="status-indicator" :class="{ 'active': driver.is_active }"></div>
        </div>

        <div class="driver-details card-row-mini">
          <div class="d-item">
            <span class="d-label">PHONE</span>
            <span class="d-value">{{ driver.phone || 'N/A' }}</span>
          </div>
          <div class="d-item">
            <span class="d-label">LICENSE</span>
            <span class="d-value">{{ driver.license_number || 'N/A' }}</span>
          </div>
        </div>

        <div class="card-actions">
           <button class="btn-action-terminal" @click="editDriver(driver)">
             <SettingsIcon class="icon-xs" />
             CONFIGURE
           </button>
           <button class="btn-action-terminal" @click="viewAssignments(driver)">
             <ListIcon class="icon-xs" />
             ASSIGNMENTS
           </button>
        </div>
      </div>

      <div v-if="drivers.length === 0" class="empty-state glass-panel">
        <TruckIcon class="empty-icon" />
        <h3>Waiting for driver recruitment</h3>
        <p>Start your fleet by adding your first tactical driver.</p>
      </div>
    </div>

    <!-- ADD/EDIT DRIVER MODAL -->
    <Teleport to="body">
      <div v-if="showAddModal" class="modal-overlay" @click.self="showAddModal = false">
        <div class="modal-card glass-panel animate-pop">
           <h2 class="hero-font">{{ editingDriver ? 'Configure Driver' : 'Recruit Driver' }}</h2>
           <p class="text-dim">Update tactical logistics personnel profile.</p>

           <form @submit.prevent="handleSave" class="modal-form">
              <div class="form-grid">
                <div class="form-group-tactical full-width">
                  <label>Full Name</label>
                  <div class="input-terminal">
                    <UserIcon class="icon-xs" />
                    <input type="text" v-model="form.full_name" required />
                  </div>
                </div>
                <div class="form-group-tactical">
                  <label>Phone / WhatsApp</label>
                  <div class="input-terminal">
                    <PhoneIcon class="icon-xs" />
                    <input type="text" v-model="form.phone" />
                  </div>
                </div>
                <div class="form-group-tactical">
                  <label>License (SIM)</label>
                  <div class="input-terminal">
                    <CreditCardIcon class="icon-xs" />
                    <input type="text" v-model="form.license_number" />
                  </div>
                </div>
                <div class="form-group-tactical full-width">
                  <label>Vehicle Information (Plate / Type)</label>
                  <div class="input-terminal">
                    <TruckIcon class="icon-xs" />
                    <input type="text" v-model="form.vehicle_info" placeholder="W 1234 ABC - Gran Max" />
                  </div>
                </div>
                <div class="form-group-tactical full-width">
                  <label>Emergency Contact</label>
                  <div class="input-terminal">
                    <ShieldIcon class="icon-xs" />
                    <input type="text" v-model="form.emergency_contact" />
                  </div>
                </div>
              </div>

              <div class="modal-actions">
                <button type="button" class="btn-secondary-tactical" @click="showAddModal = false">ABORT</button>
                <button type="submit" class="btn-primary-glow" :disabled="saving">
                  {{ saving ? 'SYNCING ARCHIVE...' : 'SAVE DRIVER DATA' }}
                </button>
              </div>
           </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, reactive } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  TruckIcon, 
  SearchIcon, 
  PackageIcon, 
  CheckCircleIcon, 
  UserIcon, 
  PhoneIcon, 
  CreditCardIcon, 
  ShieldIcon,
  SettingsIcon,
  ListIcon
} from 'lucide-vue-next';

const drivers = ref<any[]>([]);
const searchQuery = ref('');
const showAddModal = ref(false);
const editingDriver = ref<any>(null);
const saving = ref(false);
const activeDeliveriesCount = ref(0);

const form = reactive({
  full_name: '',
  phone: '',
  license_number: '',
  vehicle_info: '',
  emergency_contact: '',
  is_active: true
});

async function fetchDrivers() {
  const { data } = await supabase
    .from('drivers')
    .select('*')
    .order('full_name');
  drivers.value = data || [];
}

async function fetchStats() {
  const { count } = await supabase
    .from('driver_assignments')
    .select('*', { count: 'exact', head: true })
    .in('status', ['assigned', 'picked_up', 'in_transit']);
  activeDeliveriesCount.value = count || 0;
}

const filteredDrivers = computed(() => {
  if (!searchQuery.value) return drivers.value;
  const q = searchQuery.value.toLowerCase();
  return drivers.value.filter(d => 
    d.full_name.toLowerCase().includes(q) || 
    (d.vehicle_info || '').toLowerCase().includes(q)
  );
});

function editDriver(driver: any) {
  editingDriver.value = driver;
  form.full_name = driver.full_name;
  form.phone = driver.phone;
  form.license_number = driver.license_number;
  form.vehicle_info = driver.vehicle_info;
  form.emergency_contact = driver.emergency_contact;
  form.is_active = driver.is_active;
  showAddModal.value = true;
}

async function handleSave() {
  saving.value = true;
  try {
    if (editingDriver.value) {
      const { error } = await supabase
        .from('drivers')
        .update(form)
        .eq('id', editingDriver.value.id);
      if (error) throw error;
    } else {
      const { error } = await supabase
        .from('drivers')
        .insert(form);
      if (error) throw error;
    }
    showAddModal.value = false;
    editingDriver.value = null;
    fetchDrivers();
  } catch (err: any) {
    alert('Failed to save driver: ' + err.message);
  } finally {
    saving.value = false;
  }
}

function viewAssignments(driver: any) {
  alert('Assignment portal for ' + driver.full_name + ' is under development.');
}

onMounted(() => {
  fetchDrivers();
  fetchStats();
});
</script>

<style scoped>
.drivers-page { display: flex; flex-direction: column; gap: 32px; }
.header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; gap: 16px; align-items: center; }

.search-box {
  display: flex; align-items: center; gap: 12px; padding: 10px 20px;
  background: rgba(255, 255, 255, 0.03); border-radius: 14px; width: 300px;
}
.search-box input { background: transparent; border: none; color: white; width: 100%; font-size: 0.85rem; }
.search-box input:focus { outline: none; }

.stats-hub-tactical { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.stat-card-tactical { padding: 24px; display: flex; align-items: center; gap: 20px; }
.s-icon { 
  width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; 
  background: rgba(255, 255, 255, 0.05);
}
.s-icon.purple { color: #bb86fc; background: rgba(187, 134, 252, 0.1); }
.s-icon.orange { color: #ff8c00; background: rgba(255, 140, 0, 0.1); }
.s-icon.green { color: #00ff9d; background: rgba(0, 255, 157, 0.1); }
.s-info { display: flex; flex-direction: column; }
.s-label { font-size: 0.7rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; }
.s-value { font-size: 1.5rem; font-weight: 900; color: white; }

.drivers-grid {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px;
}

.driver-card {
  padding: 24px; position: relative; display: flex; flex-direction: column; gap: 20px;
  transition: all 0.3s ease;
}
.driver-card:hover { transform: translateY(-4px); background: rgba(255, 255, 255, 0.05); }
.driver-card.inactive { opacity: 0.5; }

.driver-header { display: flex; align-items: center; gap: 16px; }
.avatar-fleet {
  width: 48px; height: 48px; background: rgba(255, 255, 255, 0.05);
  border-radius: 12px; display: flex; align-items: center; justify-content: center;
  color: var(--color-primary);
}
.driver-info h3 { font-size: 1.1rem; font-weight: 800; color: white; margin-bottom: 2px; }
.vehicle-tag { font-size: 0.75rem; color: var(--color-text-dim); }
.status-indicator { width: 10px; height: 10px; border-radius: 50%; background: #333; margin-left: auto; }
.status-indicator.active { background: #00ff9d; box-shadow: 0 0 10px #00ff9d; }

.card-row-mini { display: flex; gap: 16px; padding: 12px; background: rgba(0, 0, 0, 0.2); border-radius: 12px; }
.d-item { display: flex; flex-direction: column; flex: 1; }
.d-label { font-size: 0.6rem; color: var(--color-text-dim); font-weight: 800; }
.d-value { font-size: 0.8rem; font-weight: 700; color: white; }

.card-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.btn-action-terminal {
  background: rgba(255, 255, 255, 0.03); border: 1px solid var(--glass-border); color: white;
  padding: 10px; border-radius: 10px; font-size: 0.7rem; font-weight: 700; cursor: pointer;
  display: flex; align-items: center; justify-content: center; gap: 8px; transition: all 0.2s;
}
.btn-action-terminal:hover { background: rgba(255, 255, 255, 0.08); }

/* MODALS */
.modal-overlay {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8);
  backdrop-filter: blur(12px); display: flex; justify-content: center; align-items: center; z-index: 1000;
}
.modal-card { width: 100%; max-width: 500px; padding: 40px; border-radius: 24px; position: relative; }
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 24px; }
.full-width { grid-column: 1 / -1; }
.form-group-tactical { display: flex; flex-direction: column; gap: 8px; }
.form-group-tactical label { font-size: 0.65rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; }
.input-terminal {
  display: flex; align-items: center; gap: 12px; background: rgba(0,0,0,0.3);
  border: 1px solid var(--glass-border); padding: 12px 16px; border-radius: 12px;
}
.input-terminal input { background: transparent; border: none; color: white; width: 100%; font-size: 0.9rem; }
.input-terminal input:focus { outline: none; }
.modal-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 32px; }

.btn-primary-glow {
  background: var(--color-primary); color: black; border: none; padding: 14px;
  border-radius: 12px; font-weight: 900; font-size: 0.85rem; cursor: pointer;
  display: flex; align-items: center; justify-content: center; gap: 8px;
}
.btn-secondary-tactical {
  background: transparent; border: 1px solid var(--glass-border); color: white;
  padding: 14px; border-radius: 12px; font-weight: 800; cursor: pointer;
}

.empty-state { grid-column: 1 / -1; padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 16px; }
.empty-icon { font-size: 48px; opacity: 0.1; }

.animate-pop { animation: popIn 0.3s ease-out; }
@keyframes popIn { from { opacity: 0; transform: scale(0.95) translateY(10px); } to { opacity: 1; transform: scale(1) translateY(0); } }
</style>
