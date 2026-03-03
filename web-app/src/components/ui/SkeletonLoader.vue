<template>
  <div class="skeleton-shimmer" :style="styles"></div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  width?: string;
  height?: string;
  radius?: string;
}>();

const styles = computed(() => ({
  width: props.width || '100%',
  height: props.height || '20px',
  borderRadius: props.radius || '8px'
}));
</script>

<style scoped>
.skeleton-shimmer {
  background: rgba(255, 255, 255, 0.05);
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0,
    rgba(255, 255, 255, 0.05) 20%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 80%,
    rgba(255, 255, 255, 0) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite linear;
  backdrop-filter: blur(4px);
}

@keyframes shimmer {
  0% { background-position: -100% 0; }
  100% { background-position: 100% 0; }
}
</style>
