<template>
  <router-view :key="$route.fullPath"></router-view>
  <ToastContainer />
</template>

<script setup lang="ts">
import ToastContainer from './components/ui/ToastContainer.vue';
</script>

<style>
@import './assets/styles/design-system.css';
</style>
