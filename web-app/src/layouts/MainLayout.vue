<template>
  <div class="dashboard-layout">
    <!-- 🌌 AURORA BACKGROUND -->
    <div class="aurora-static"></div>

    <!-- Persistent Sidebar Navigation (CardNav Implementation) -->
    <aside class="sidebar">
      <CardNav 
        :items="navCards" 
        class="main-card-nav"
      />

      <div class="sidebar-footer glass-panel">
        <div class="user-info">
          <div class="pfp"></div>
          <div class="user-details">
            <p class="user-name">{{ authStore.profile?.full_name || authStore.user?.email?.split('@')[0] || 'Loading...' }}</p>
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
          <component :is="Component" :key="$route.fullPath" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useAuthStore } from '../stores/auth';
import { useRouter } from 'vue-router';
import CardNav from '../components/animations/CardNav.vue';
import { 
  LayoutDashboardIcon, 
  PackageIcon, 
  ShoppingCartIcon, 
  UsersIcon, 
  LogOutIcon,
  ClipboardListIcon,
  TruckIcon,
  SettingsIcon,
  InstagramIcon
} from 'lucide-vue-next';

const authStore = useAuthStore();
const router = useRouter();

const navCards = computed(() => {
  const sections = [
    {
      label: 'Operations',
      links: [
        { label: 'Dashboard', path: '/', icon: LayoutDashboardIcon },
        { label: 'Inventory', path: '/stock', icon: PackageIcon }
      ]
    },
    {
      label: 'Revenue',
      links: [
        { label: 'New Order', path: '/sales', icon: ShoppingCartIcon },
        { label: 'Order List', path: '/orders', icon: ClipboardListIcon },
        { label: 'CRM Database', path: '/customers', icon: UsersIcon },
        { label: 'Suppliers', path: '/suppliers', icon: TruckIcon }
      ]
    }
  ];

  // Admin Only Sections
  if (authStore.isAdmin) {
    sections.push({
      label: 'Management',
      links: [
        { label: 'Team Members', path: '/employees', icon: UsersIcon }
      ]
    });
  }

  sections.push({
    label: 'Creative',
    links: [
      { label: 'Instagram Content', path: 'https://drive.google.com/drive/u/7/folders/1SXW4vNSc6ju2w7PRnp70Fh-Q75OAfMWx?usp=sharing', icon: InstagramIcon }
    ]
  });

  sections.push({
    label: 'Account',
    links: [
      { label: 'My Profile', path: '/profile', icon: SettingsIcon }
    ]
  });

  return sections;
});

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
  width: 320px;
  height: calc(100vh - 32px);
  display: flex;
  flex-direction: column;
  gap: 16px;
  z-index: 10;
  flex-shrink: 0;
  overflow-y: auto;
  scrollbar-width: none; /* Hide for clean look */
}
.sidebar::-webkit-scrollbar { display: none; }

.main-card-nav {
  flex: 1;
}

.sidebar-footer {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 24px;
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
  gap: 12px;
  padding: 14px;
  background: rgba(255, 62, 62, 0.05);
  border: 1px solid rgba(255, 62, 62, 0.15);
  color: var(--color-error);
  border-radius: var(--radius-md);
  cursor: pointer;
  font-family: var(--font-headline);
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  font-size: 0.75rem;
  transition: var(--transition-smooth);
}

.btn-logout:hover {
  background: rgba(255, 62, 62, 0.1);
  border-color: rgba(255, 62, 62, 0.3);
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(255, 62, 62, 0.1);
}

/* WORKSPACE */
.workspace {
  flex: 1;
  display: flex;
  flex-direction: column;
  z-index: 10;
  overflow-y: auto;
  padding: 40px;
  scroll-behavior: smooth;
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
