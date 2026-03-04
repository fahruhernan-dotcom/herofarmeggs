<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="show" class="drawer-overlay" @click="$emit('close')"></div>
    </Transition>

    <Transition name="slide">
      <aside v-if="show" class="mobile-drawer glass-panel">
        <div class="drawer-header">
          <div class="logo-area">
            <span class="hero-text hero-font">HERO FARM</span>
            <span class="live-dot"></span>
          </div>
          <button class="btn-close" @click="$emit('close')">
            <XIcon class="icon" />
          </button>
        </div>

        <div class="drawer-body">
          <div v-for="group in menuGroups" :key="group.title" class="menu-group">
            <h3 class="group-title">{{ group.title }}</h3>
            <nav class="group-nav">
              <template v-for="item in group.items" :key="item.path">
                <router-link
                  v-if="!item.path.startsWith('http')"
                  :to="item.path"
                  class="nav-item"
                  @click="$emit('close')"
                >
                  <component :is="item.icon" class="nav-icon" />
                  <span class="nav-label">{{ item.label }}</span>
                </router-link>
                <a
                  v-else
                  :href="item.path"
                  target="_blank"
                  class="nav-item"
                  @click="$emit('close')"
                >
                  <component :is="item.icon" class="nav-icon" />
                  <span class="nav-label">{{ item.label }}</span>
                </a>
              </template>
            </nav>
          </div>
        </div>
      </aside>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { 
  XIcon, 
  LayoutDashboardIcon, 
  PackageIcon, 
  PlusCircleIcon, 
  ClipboardListIcon, 
  UsersIcon, 
  TruckIcon, 
  WalletIcon, 
  UserCircleIcon,
  InstagramIcon
} from 'lucide-vue-next';

defineProps<{ show: boolean }>();
defineEmits(['close']);

const menuGroups = [
  {
    title: 'OPERATIONS',
    items: [
      { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboardIcon },
      { path: '/stock', label: 'Inventory Matrix', icon: PackageIcon },
    ]
  },
  {
    title: 'REVENUE',
    items: [
      { path: '/sales/new', label: 'New Order', icon: PlusCircleIcon },
      { path: '/sales', label: 'Order List', icon: ClipboardListIcon },
      { path: '/customers', label: 'CRM Database', icon: UsersIcon },
      { path: '/suppliers', label: 'Suppliers', icon: TruckIcon },
    ]
  },
  {
    title: 'MANAGEMENT',
    items: [
      { path: '/financial', label: 'Financial Terminal', icon: WalletIcon },
      { path: '/employees', label: 'Team Members', icon: UserCircleIcon },
    ]
  },
  {
    title: 'CREATIVE',
    items: [
      { path: 'https://drive.google.com/drive/u/7/folders/1SXW4vNSc6ju2w7PRnp70Fh-Q75OAfMWx?usp=sharing', label: 'Instagram Content', icon: InstagramIcon },
    ]
  }
];
</script>

<style scoped>
.drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(4px);
  z-index: 2100;
}

.mobile-drawer {
  position: fixed;
  top: 0;
  left: 0;
  width: 280px;
  max-width: 85vw;
  height: 100vh;
  z-index: 2200;
  background: #080809;
  border-right: 1px solid rgba(255, 255, 255, 0.06);
  display: flex;
  flex-direction: column;
  box-shadow: 20px 0 50px rgba(0,0,0,0.5);
  border-radius: 0 !important;
}

.drawer-header {
  height: 64px;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-text {
  font-size: 1.2rem;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.live-dot {
  width: 6px;
  height: 6px;
  background: #f59e0b;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

.btn-close {
  background: none;
  border: none;
  color: #475569;
}

.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: 24px 0;
}

.menu-group {
  margin-bottom: 24px;
}

.group-title {
  padding: 0 24px;
  font-size: 0.65rem;
  font-weight: 800;
  color: #475569;
  letter-spacing: 0.15em;
  margin-bottom: 12px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 24px;
  color: #94a3b8;
  text-decoration: none;
  transition: all 0.2s ease;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.03);
  color: #fff;
}

.router-link-active {
  background: rgba(245, 158, 11, 0.08);
  color: #f59e0b !important;
  border-left: 3px solid #f59e0b;
  padding-left: 21px;
}

.nav-icon {
  width: 20px;
  height: 20px;
}

.nav-label {
  font-size: 0.95rem;
  font-weight: 500;
}

/* Transitions */
.slide-enter-active, .slide-leave-active {
  transition: transform 0.3s ease-out;
}
.slide-enter-from, .slide-leave-to {
  transform: translateX(-100%);
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.5); opacity: 0.5; }
  100% { transform: scale(1); opacity: 1; }
}
</style>
