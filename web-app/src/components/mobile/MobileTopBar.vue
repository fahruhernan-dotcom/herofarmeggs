<template>
  <header class="mobile-top-bar glass-panel">
    <div class="header-left">
      <button class="btn-icon" @click="$emit('toggle-drawer')">
        <MenuIcon v-if="!isBack" class="icon" />
        <ArrowLeftIcon v-else class="icon" />
      </button>
    </div>

    <div class="header-center">
      <h1 class="page-title">{{ title }}</h1>
    </div>

    <div class="header-right">
      <div class="notification-box">
        <BellIcon class="icon" />
        <span class="live-dot"></span>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { MenuIcon, BellIcon, ArrowLeftIcon } from 'lucide-vue-next';

defineEmits(['toggle-drawer']);

const route = useRoute();

const isBack = computed(() => route.path.split('/').length > 2);

const title = computed(() => {
  const titles: Record<string, string> = {
    '/': 'Dashboard',
    '/dashboard': 'Dashboard',
    '/inventory': 'Manajemen Stok',
    '/stock': 'Manajemen Stok',
    '/sales/new': 'Order Baru',
    '/sales': 'Order List',
    '/customers': 'CRM Database',
    '/suppliers': 'Suppliers',
    '/financial': 'Financial'
  };
  return titles[route.path] || 'Hero Farm';
});
</script>

<style scoped>
.mobile-top-bar {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 56px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 16px;
  z-index: 2000;
  background: rgba(8, 8, 9, 0.9);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 0 !important;
}

.page-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: #fff;
  margin: 0;
}

.btn-icon {
  background: none;
  border: none;
  color: #64748b;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.icon {
  width: 22px;
  height: 22px;
}

.notification-box {
  position: relative;
}

.live-dot {
  position: absolute;
  top: 2px;
  right: 2px;
  width: 8px;
  height: 8px;
  background: #f59e0b;
  border-radius: 50%;
  border: 2px solid #080809;
}
</style>
