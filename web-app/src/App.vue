<template>
  <div id="app" style="overflow: hidden; max-width: 100vw; width: 100%;">
    <router-view :key="$route.fullPath"></router-view>
    <ToastContainer />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue';
import ToastContainer from './components/ui/ToastContainer.vue';
import { useNotificationStore } from './stores/notificationStore';

const notifStore = useNotificationStore();

onMounted(() => {
  notifStore.init();
});

onUnmounted(() => {
  notifStore.unsubscribeRealtime();
});
</script>

<style>
@import './assets/styles/design-system.css';
</style>
