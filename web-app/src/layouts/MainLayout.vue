<template>
  <div class="dashboard-layout">
    <!-- 🌌 AURORA BACKGROUND -->
    <div class="aurora-static"></div>

    <!-- Persistent Sidebar Navigation -->
    <aside class="sidebar glass-panel">
      <div class="sidebar-header">
        <div class="logo-text hero-font">HERO FARM</div>
        <div class="badge">OWNER HUB</div>
      </div>
      
      <div class="nav-container-wrapper">
        <GooeyNav :items="navLinks" />
      </div>

      <div class="sidebar-footer">
        <div class="user-info">
          <div class="pfp"></div>
          <div class="user-details">
            <p class="user-name">Owner</p>
            <p class="user-email text-dim">{{ authStore.user?.email }}</p>
          </div>
        </div>
        <button @click="handleLogout" class="btn-logout">
          <LogOutIcon class="icon" />
          <span>Logout System</span>
        </button>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="workspace">
      <router-view v-slot="{ Component }">
        <transition name="fade-slide" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import GooeyNav from '../components/animations/GooeyNav.vue';
import { 
  LayoutDashboardIcon, 
  PackageIcon, 
  ShoppingCartIcon, 
  UsersIcon, 
  LogOutIcon 
} from 'lucide-vue-next';

const authStore = useAuthStore();
const router = useRouter();

const navLinks = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboardIcon },
  { path: '/stock', label: 'Inventory', icon: PackageIcon },
  { path: '/sales', label: 'Sales Trace', icon: ShoppingCartIcon },
  { path: '/customers', label: 'CRM Base', icon: UsersIcon },
];

async function handleLogout() {
  await authStore.signOut();
  router.push('/login');
}
</script>

<style scoped>
.dashboard-layout {
  display: flex;
  min-height: 100vh;
  background-color: var(--color-bg);
  color: var(--color-text);
  padding: 16px;
  gap: 16px;
}

.aurora-static {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at 20% 20%, rgba(255, 140, 0, 0.03), transparent 50%),
              radial-gradient(circle at 80% 80%, rgba(255, 140, 0, 0.03), transparent 50%);
  z-index: 0;
}

/* SIDEBAR */
.sidebar {
  width: 300px;
  display: flex;
  flex-direction: column;
  padding: 32px 24px;
  z-index: 10;
  flex-shrink: 0;
}

.sidebar-header {
  margin-bottom: 48px;
}

.logo-text {
  font-size: 1.8rem;
  letter-spacing: -0.05em;
  color: var(--color-primary);
  line-height: 1;
}

.badge {
  display: inline-block;
  font-size: 0.65rem;
  font-weight: 800;
  padding: 4px 8px;
  background: rgba(255, 140, 0, 0.1);
  color: var(--color-primary);
  border-radius: 4px;
  margin-top: 8px;
  letter-spacing: 0.1em;
}

.nav-container-wrapper {
  flex: 1;
}

.sidebar-footer {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.pfp {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(45deg, var(--color-primary), #FF4D00);
}

.user-name { font-weight: 600; font-size: 0.9rem; }
.user-email { font-size: 0.75rem; color: var(--color-text-dim); }

.btn-logout {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  background: rgba(255, 62, 62, 0.05);
  border: 1px solid rgba(255, 62, 62, 0.1);
  color: var(--color-error);
  border-radius: var(--radius-md);
  cursor: pointer;
  font-family: var(--font-headline);
  font-weight: 600;
  transition: var(--transition-smooth);
}

.btn-logout:hover {
  background: rgba(255, 62, 62, 0.1);
  transform: translateY(-2px);
}

/* WORKSPACE */
.workspace {
  flex: 1;
  display: flex;
  flex-direction: column;
  z-index: 10;
  overflow-y: auto;
  padding: 16px;
}

/* Page Transitions */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>
