<template>
  <nav class="bottom-nav">
    <router-link to="/dashboard" class="nav-item">
      <LayoutDashboardIcon class="icon" />
      <span class="label">Home</span>
    </router-link>

    <router-link to="/sales" class="nav-item">
      <ClipboardListIcon class="icon" />
      <span class="label">Orders</span>
    </router-link>

    <router-link to="/sales/new" class="nav-item primary-action">
      <div class="primary-icon-wrap">
        <PlusCircleIcon class="icon-plus" />
      </div>
      <span class="label">New Order</span>
    </router-link>

    <router-link to="/stock" class="nav-item">
      <PackageIcon class="icon" />
      <span class="label">Stock</span>
    </router-link>

    <button class="nav-item btn-more" @click="$emit('open-drawer')">
      <MenuIcon class="icon" />
      <span class="label">More</span>
    </button>
  </nav>
</template>

<script setup lang="ts">
import { 
  LayoutDashboardIcon, 
  ClipboardListIcon, 
  PlusCircleIcon, 
  PackageIcon, 
  MenuIcon 
} from 'lucide-vue-next';

defineEmits(['open-drawer']);
</script>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 64px;
  background: rgba(8, 8, 9, 0.98);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  display: flex;
  justify-content: space-around;
  align-items: center;
  z-index: 2000;
  padding-bottom: env(safe-area-inset-bottom);
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #64748b;
  text-decoration: none;
  gap: 4px;
  flex: 1;
  background: none;
  border: none;
  padding: 0;
}

.icon {
  width: 22px;
  height: 22px;
  transition: all 0.2s;
}

.label {
  font-size: 10px;
  font-weight: 500;
  transition: all 0.2s;
}

.router-link-active {
  color: #f59e0b;
}

.primary-action {
  position: relative;
  margin-top: -32px;
}

.primary-icon-wrap {
  width: 52px;
  height: 52px;
  background: #f59e0b;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 16px rgba(245, 158, 11, 0.4);
  color: #fff;
  border: 4px solid #080809;
}

.icon-plus {
  width: 28px;
  height: 28px;
}

.primary-action .label {
  margin-top: 4px;
}

.btn-more {
  cursor: pointer;
}
</style>
