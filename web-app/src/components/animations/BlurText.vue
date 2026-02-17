<template>
  <div ref="textContainer" class="blur-text-container" :class="{ 'is-in-view': isInView }">
    <span 
      v-for="(word, index) in words" 
      :key="index" 
      class="blur-word" 
      :style="{ transitionDelay: `${index * delay}ms` }"
    >
      {{ word }}&nbsp;
    </span>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';

const props = defineProps<{
  text: string;
  delay?: number;
}>();

const delay = props.delay || 100;
const words = computed(() => props.text.split(' '));
const textContainer = ref<HTMLElement | null>(null);
const isInView = ref(false);

onMounted(() => {
  const observer = new IntersectionObserver(
    ([entry]) => {
      if (entry.isIntersecting) {
        isInView.value = true;
        observer.unobserve(entry.target);
      }
    },
    { threshold: 0.1 }
  );

  if (textContainer.value) {
    observer.observe(textContainer.value);
  }
});
</script>

<style scoped>
.blur-text-container {
  display: flex;
  flex-wrap: wrap;
}

.blur-word {
  opacity: 0;
  filter: blur(10px);
  transform: translateY(10px);
  transition: opacity 0.8s ease, filter 0.8s ease, transform 0.8s ease;
  display: inline-block;
}

.is-in-view .blur-word {
  opacity: 1;
  filter: blur(0);
  transform: translateY(0);
}
</style>
