<template>
  <div class="notif-wrapper" ref="bellRef">
    <!-- Bell Button -->
    <button 
      class="bell-btn" 
      @click.stop="togglePanel" 
      :class="{ 'has-unread': unreadCount > 0 }"
      aria-label="Notifications"
    >
      <BellIcon :size="20" class="bell-icon" />
      <span v-if="unreadCount > 0" class="bell-badge">
        {{ unreadCount > 99 ? '99+' : unreadCount }}
      </span>
    </button>

    <!-- Dropdown Panel (Teleport to body for z-index safety) -->
    <Teleport to="body">
      <Transition name="notif-dropdown">
        <div
          v-if="isOpen"
          class="notif-dropdown-panel glass-panel"
          ref="panelRef"
          :style="dropdownPosition"
          @click.stop
        >
          <header class="panel-header">
            <div class="header-left">
              <h3 class="hero-font text-white">Notifikasi</h3>
              <span v-if="unreadCount > 0" class="unread-pill">{{ unreadCount }} Baru</span>
            </div>
            <button 
              v-if="unreadCount > 0" 
              class="mark-all-btn" 
              @click="notifStore.markAllAsRead()"
            >
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
            <!-- LOADING STATE -->
            <div v-if="notifStore.isLoading && notifStore.notifications.length === 0" class="notif-loading">
              <div v-for="i in 5" :key="i" class="notif-skeleton">
                <div class="skeleton-dot"></div>
                <div class="skeleton-content">
                  <div class="skeleton-line w-60"></div>
                  <div class="skeleton-line w-40"></div>
                </div>
              </div>
            </div>

            <!-- EMPTY STATE -->
            <div v-else-if="filteredNotifications.length === 0" class="empty-state">
              <BellOffIcon :size="48" class="empty-icon" />
              <p class="hero-font">Semua beres!</p>
              <p class="text-dim">Tidak ada notifikasi saat ini.</p>
            </div>
            
            <!-- LIST -->
            <div 
              v-else
              v-for="notif in filteredNotifications" 
              :key="notif.id"
              class="notif-item"
              :class="{ 'is-unread': !notif.is_read }"
              :style="{
                background: !notif.is_read ? notifStore.getSeverityConfig(notif.severity).bg : 'transparent',
                borderLeft: `3px solid ${!notif.is_read ? notifStore.getSeverityConfig(notif.severity).dot : 'transparent'}`
              }"
              @click="handleNotifClick(notif)"
            >
              <div 
                class="notif-dot" 
                :style="{ background: notifStore.getSeverityConfig(notif.severity).dot }"
                v-if="!notif.is_read"
              ></div>
              <div class="notif-dot-placeholder" v-else></div>
              
              <div class="notif-content">
                <div class="notif-top">
                  <span class="notif-title">{{ notifStore.getSeverityConfig(notif.severity).icon }} {{ notif.title }}</span>
                  <span class="notif-time">{{ formatTimeAgo(notif.created_at) }}</span>
                </div>
                <p class="notif-message">{{ notif.message }}</p>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  BellIcon, 
  BellOffIcon
} from 'lucide-vue-next';
import { useNotificationStore } from '../stores/notificationStore';
import type { Notification } from '../stores/notificationStore';

const router = useRouter();
const notifStore = useNotificationStore();

const isOpen = ref(false);
const bellRef = ref<HTMLElement | null>(null);
const panelRef = ref<HTMLElement | null>(null);
const activeFilter = ref('all');

const unreadCount = computed(() => notifStore.unreadCount);

const filterTabs = [
  { id: 'all', label: 'Semua' },
  { id: 'unread', label: 'Belum Dibaca' },
  { id: 'stock', label: 'Stok' },
  { id: 'sales', label: 'Penjualan' }
];

const filteredNotifications = computed(() => {
  let list = notifStore.allNotifications;
  
  if (activeFilter.value === 'unread') {
    list = list.filter((n: Notification) => !n.is_read);
  } else if (activeFilter.value === 'stock') {
    list = list.filter((n: Notification) => n.entity_type === 'inventory' || n.type?.includes('stock'));
  } else if (activeFilter.value === 'sales') {
    list = list.filter((n: Notification) => n.entity_type === 'sale' || n.type === 'new_sale');
  }
  
  return list;
});

const dropdownPosition = computed(() => {
  if (!bellRef.value) return {};
  const rect = bellRef.value.getBoundingClientRect();
  const isMobile = window.innerWidth <= 768;
  
  if (isMobile) return {}; // Mobile styles handled by CSS

  return {
    position: 'fixed',
    top: `${rect.bottom + 8}px`,
    right: `${window.innerWidth - rect.right}px`,
    zIndex: 9999
  };
});

function togglePanel() {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    notifStore.fetchNotifications();
  }
}

function handleClickOutside(e: MouseEvent) {
  if (
    isOpen.value &&
    panelRef.value &&
    !panelRef.value.contains(e.target as Node) &&
    bellRef.value &&
    !bellRef.value.contains(e.target as Node)
  ) {
    isOpen.value = false;
  }
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') isOpen.value = false;
}

async function handleNotifClick(notif: Notification) {
  if (!notif.is_read) {
    await notifStore.markAsRead(notif.id);
  }
  
  const routes: Record<string, string> = {
    sale:     '/sales',
    purchase: '/stock',
    piutang:  '/financial?tab=piutang',
    utang:    '/financial?tab=utang',
    inventory:'/stock',
    grading:  '/stock'
  };
  
  const targetPath = notif.entity_type ? routes[notif.entity_type] : null;
  if (targetPath) {
    router.push(targetPath);
    isOpen.value = false;
  }
}

function formatTimeAgo(dateStr: string) {
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return 'Baru saja';
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
  if (diffInSeconds < 60) return 'Baru saja';
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} menit lalu`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} jam lalu`;
  if (diffInSeconds < 172800) return 'Kemarin';
  return date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });
}

onMounted(async () => {
  document.addEventListener('click', handleClickOutside);
  document.addEventListener('keydown', handleKeydown);
  
  if (notifStore.notifications.length === 0) {
    await notifStore.init();
  }
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
  document.removeEventListener('keydown', handleKeydown);
});
</script>

<style scoped>
.notif-wrapper {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.bell-btn {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  cursor: pointer;
  color: rgba(255, 255, 255, 0.6);
  transition: all 0.2s cubic-bezier(0.23, 1, 0.32, 1);
}

.bell-btn:hover {
  color: white;
  background: rgba(255, 255, 255, 0.08);
  transform: translateY(-1px);
}

.bell-btn.has-unread .bell-icon {
  color: var(--gold);
}

.bell-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  background: #ef4444;
  color: white;
  font-size: 9px;
  font-weight: 800;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #080809;
  pointer-events: none;
  box-shadow: 0 0 10px rgba(239, 68, 68, 0.3);
}

.notif-dropdown-panel {
  width: 400px;
  max-height: 580px;
  background: #0d0d12;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.04);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  backdrop-filter: blur(20px);
}

.panel-header {
  padding: 20px 24px;
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
  color: var(--gold);
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.mark-all-btn {
  background: none;
  border: none;
  color: var(--gold);
  font-size: 11px;
  font-weight: 700;
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
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.01);
  border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.filter-tab {
  background: transparent;
  border: 1px solid transparent;
  color: rgba(255, 255, 255, 0.4);
  padding: 4px 12px;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-tab:hover {
  color: white;
  background: rgba(255, 255, 255, 0.03);
}

.filter-tab.active {
  background: rgba(245, 158, 11, 0.1);
  color: var(--gold);
  border-color: rgba(245, 158, 11, 0.2);
}

.notif-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
}

/* Mobile: full width bottom sheet */
@media (max-width: 768px) {
  .notif-dropdown-panel {
    position: fixed !important;
    top: auto !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    width: 100% !important;
    max-height: 80vh !important;
    border-radius: 24px 24px 0 0 !important;
  }
}

.notif-item {
  display: flex;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.23, 1, 0.32, 1);
  margin-bottom: 4px;
  position: relative;
}

.notif-item:hover {
  background: rgba(255, 255, 255, 0.04) !important;
}

.notif-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
  margin-top: 6px;
}

.notif-dot-placeholder {
  width: 6px;
}

.notif-content {
  flex: 1;
  min-width: 0;
}

.notif-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2px;
}

.notif-title {
  font-size: 13.5px;
  font-weight: 700;
  color: white;
}

.notif-time {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.3);
}

.notif-message {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  line-height: 1.5;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 24px;
}

.empty-icon {
  margin-bottom: 12px;
  opacity: 0.15;
}

/* Skeleton */
.notif-skeleton {
  display: flex;
  gap: 12px;
  padding: 16px;
  align-items: center;
}
.skeleton-dot {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.05);
}
.skeleton-content { flex: 1; }
.skeleton-line {
  height: 10px;
  border-radius: 5px;
  background: rgba(255, 255, 255, 0.05);
  margin-bottom: 6px;
}
.skeleton-line.w-60 { width: 60%; }
.skeleton-line.w-40 { width: 40%; }

/* Transition */
.notif-dropdown-enter-active {
  transition: opacity 200ms ease, transform 200ms cubic-bezier(0.16, 1, 0.3, 1);
}
.notif-dropdown-leave-active {
  transition: opacity 150ms ease, transform 150ms ease;
}
.notif-dropdown-enter-from {
  opacity: 0;
  transform: translateY(-8px) scale(0.98);
}
.notif-dropdown-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.99);
}
</style>
