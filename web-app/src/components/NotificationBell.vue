<template>
  <div class="notification-container" v-click-outside="closePanel">
    <!-- Bell Button -->
    <button class="bell-btn" @click="togglePanel" :class="{ 'has-unread': unreadCount > 0 }">
      <BellIcon :size="20" class="bell-icon" />
      <span v-if="unreadCount > 0" class="unread-badge">
        {{ unreadCount > 9 ? '9+' : unreadCount }}
      </span>
    </button>

    <!-- Slide-over Panel -->
    <Transition name="slide-right">
      <div v-if="isPanelOpen" class="notification-panel glass-panel">
        <header class="panel-header">
          <div class="header-left">
            <h3 class="hero-font">Notifikasi</h3>
            <span v-if="unreadCount > 0" class="unread-pill">{{ unreadCount }} Unread</span>
          </div>
          <button v-if="unreadCount > 0" class="mark-all-btn" @click="markAllRead">
            Tandai semua dibaca
          </button>
        </header>

        <!-- Filter Tabs -->
        <div class="filter-tabs">
          <button 
            v-for="tab in filterTabs" 
            :key="tab.id"
            class="filter-tab"
            :class="{ active: activeFilter === tab.id }"
            @click="activeFilter = tab.id"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- Notification List -->
        <div class="notif-list custom-scrollbar">
          <div v-if="filteredNotifications.length === 0" class="empty-state">
            <BellOffIcon :size="48" class="empty-icon" />
            <p>Semua beres! Tidak ada notifikasi.</p>
          </div>
          
          <div 
            v-for="notif in filteredNotifications" 
            :key="notif.id"
            class="notif-item"
            :class="{ 'is-unread': !notif.is_read }"
            @click="handleNotifClick(notif)"
          >
            <div class="notif-icon-circle" :class="notif.type">
              <component :is="getIcon(notif.type)" :size="18" />
            </div>
            
            <div class="notif-content">
              <div class="notif-top">
                <span class="notif-title">{{ notif.title }}</span>
                <span class="notif-time">{{ formatTimeAgo(notif.created_at) }}</span>
              </div>
              <p class="notif-message">{{ notif.message }}</p>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  BellIcon, 
  BellOffIcon,
  AlertTriangleIcon,
  AlertOctagonIcon,
  ShoppingCartIcon,
  CheckCircleIcon,
  XCircleIcon,
  PackageIcon,
  ShieldIcon
} from 'lucide-vue-next';
import { useNotificationStore } from '../stores/notificationStore';
import type { Notification } from '../stores/notificationStore';

const router = useRouter();
const notifStore = useNotificationStore();

const isPanelOpen = ref(false);
const activeFilter = ref('all');

const unreadCount = computed(() => notifStore.unreadCount);

const filterTabs = [
  { id: 'all', label: 'All' },
  { id: 'unread', label: 'Unread' },
  { id: 'stock', label: 'Stok' },
  { id: 'sales', label: 'Penjualan' },
  { id: 'system', label: 'Sistem' }
];

const filteredNotifications = computed(() => {
  let list = notifStore.notifications;
  
  if (activeFilter.value === 'unread') {
    list = list.filter(n => !n.is_read);
  } else if (activeFilter.value === 'stock') {
    list = list.filter(n => n.type === 'low_stock' || n.type === 'critical_stock');
  } else if (activeFilter.value === 'sales') {
    list = list.filter(n => ['sale_created', 'sale_paid', 'sale_voided'].includes(n.type));
  } else if (activeFilter.value === 'system') {
    list = list.filter(n => n.type === 'system_alert');
  }
  
  return list;
});

function togglePanel() {
  isPanelOpen.value = !isPanelOpen.value;
  if (isPanelOpen.value) {
    notifStore.fetchNotifications();
  }
}

function closePanel() {
  isPanelOpen.value = false;
}

function markAllRead() {
  notifStore.markAllRead();
}

async function handleNotifClick(notif: Notification) {
  if (!notif.is_read) {
    await notifStore.markOneRead(notif.id);
  }
  
  if (notif.link) {
    router.push(notif.link);
    isPanelOpen.value = false;
  }
}

function getIcon(type: string) {
  switch (type) {
    case 'low_stock': return AlertTriangleIcon;
    case 'critical_stock': return AlertOctagonIcon;
    case 'sale_created': return ShoppingCartIcon;
    case 'sale_paid': return CheckCircleIcon;
    case 'sale_voided': return XCircleIcon;
    case 'restock_done': return PackageIcon;
    case 'system_alert': return ShieldIcon;
    default: return BellIcon;
  }
}

function formatTimeAgo(dateStr: string) {
  const date = new Date(dateStr);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
  if (diffInSeconds < 60) return 'Just now';
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
  return date.toLocaleDateString();
}

// Custom directive for clicking outside
const vClickOutside = {
  mounted(el: any, binding: any) {
    el.clickOutsideEvent = (event: Event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value();
      }
    };
    document.addEventListener('click', el.clickOutsideEvent);
  },
  unmounted(el: any) {
    document.removeEventListener('click', el.clickOutsideEvent);
  }
};

onMounted(() => {
  notifStore.fetchNotifications();
  notifStore.subscribeRealtime();
});
</script>

<style scoped>
.notification-container {
  position: relative;
}

.bell-btn {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.23, 1, 0.32, 1);
  position: relative;
}

.bell-btn:hover {
  background: rgba(255, 255, 255, 0.08);
  transform: translateY(-2px);
}

.bell-icon {
  color: var(--color-text-dim);
}

.has-unread .bell-icon {
  color: var(--color-primary);
  animation: ring 2s infinite;
}

@keyframes ring {
  0% { transform: rotate(0); }
  5% { transform: rotate(15deg); }
  10% { transform: rotate(-15deg); }
  15% { transform: rotate(10deg); }
  20% { transform: rotate(-10deg); }
  25% { transform: rotate(0); }
  100% { transform: rotate(0); }
}

.unread-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  background: var(--color-error);
  color: white;
  font-size: 10px;
  font-weight: 800;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--color-bg);
}

/* Panel */
.notification-panel {
  position: fixed;
  top: 16px;
  right: 16px;
  bottom: 16px;
  width: 380px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  padding: 0;
  overflow: hidden;
  background: rgba(10, 10, 15, 0.95) !important;
  backdrop-filter: blur(24px) !important;
  border-left: 1px solid rgba(255, 255, 255, 0.08);
}

.panel-header {
  padding: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.unread-pill {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.mark-all-btn {
  background: none;
  border: none;
  color: #f59e0b;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  opacity: 0.8;
  transition: opacity 0.2s;
}

.mark-all-btn:hover {
  opacity: 1;
  text-decoration: underline;
}

.filter-tabs {
  display: flex;
  gap: 8px;
  padding: 16px 24px;
  overflow-x: auto;
  scrollbar-width: none;
}
.filter-tabs::-webkit-scrollbar { display: none; }

.filter-tab {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  color: var(--color-text-dim);
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}

.filter-tab:hover {
  background: rgba(255, 255, 255, 0.08);
}

.filter-tab.active {
  background: var(--color-primary);
  color: white;
  border-color: var(--color-primary);
}

.notif-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 16px 24px;
}

.notif-item {
  display: flex;
  gap: 16px;
  padding: 16px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
  background: transparent;
  margin-bottom: 8px;
}

.notif-item:hover {
  background: rgba(255, 255, 255, 0.03);
}

.notif-item.is-unread {
  border-left: 3px solid #f59e0b;
  background: rgba(245, 158, 11, 0.03);
}

.notif-icon-circle {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.notif-icon-circle.low_stock { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
.notif-icon-circle.critical_stock { 
  background: rgba(239, 68, 68, 0.15); 
  color: #ef4444;
  animation: pulse-red 2s infinite;
}
.notif-icon-circle.sale_created { background: rgba(20, 184, 166, 0.15); color: #14b8a6; }
.notif-icon-circle.sale_paid { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.notif-icon-circle.sale_voided { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.notif-icon-circle.restock_done { background: rgba(59, 130, 246, 0.15); color: #3b82f6; }
.notif-icon-circle.system_alert { background: rgba(139, 92, 246, 0.15); color: #8b5cf6; }

@keyframes pulse-red {
  0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}

.notif-content {
  flex: 1;
  min-width: 0;
}

.notif-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 4px;
}

.notif-title {
  font-size: 14px;
  font-weight: 600;
  color: white;
}

.notif-time {
  font-size: 11px;
  color: var(--color-text-dim);
}

.notif-message {
  font-size: 13px;
  color: var(--color-text-dim);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 24px;
  text-align: center;
  color: var(--color-text-dim);
}

.empty-icon {
  margin-bottom: 16px;
  opacity: 0.2;
}

/* Transitions */
.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.3s cubic-bezier(0.23, 1, 0.32, 1), opacity 0.3s;
}

.slide-right-enter-from,
.slide-right-leave-to {
  transform: translateX(100%);
  opacity: 0;
}
</style>
