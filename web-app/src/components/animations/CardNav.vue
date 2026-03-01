<template>
  <div :class="['card-nav-container', className]" ref="containerRef">
    <nav 
      ref="navRef" 
      :class="['card-nav', { 'open': isExpanded }]" 
    >
      <!-- Top Bar / Header -->
      <div class="card-nav-top">
        <div
          :class="['hamburger-menu', { 'open': isHamburgerOpen }]"
          @click="toggleMenu"
          role="button"
          :aria-label="isExpanded ? 'Close menu' : 'Open menu'"
          tabindex="0"
        >
          <div class="hamburger-line" />
          <div class="hamburger-line" />
        </div>

        <div class="logo-container">
          <span class="logo-text hero-font">HERO FARM</span>
        </div>

        <div class="status-indicator">
          <span class="dot pulse"></span>
          LIVE
        </div>
      </div>

      <!-- Expandable Content -->
      <div class="card-nav-content" ref="contentRef">
        <div
          v-for="(item, idx) in items"
          :key="`${item.label}-${idx}`"
          class="nav-card"
          :style="{ backgroundColor: item.bgColor }"
        >
          <div class="nav-card-label">{{ item.label }}</div>
          <div class="nav-card-links">
            <template v-if="item.links && item.links.length > 0">
              <a 
                v-for="(lnk, i) in item.links" 
                :key="`${lnk.label}-${i}`" 
                class="nav-card-link" 
                href="#"
                @click.prevent="navigate(lnk.path)"
              >
                <component :is="lnk.icon" class="nav-card-link-icon" v-if="lnk.icon" />
                <ArrowUpRightIcon class="nav-card-link-icon" v-else />
                {{ lnk.label }}
              </a>
            </template>
          </div>
        </div>
      </div>
    </nav>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue';
import { gsap } from 'gsap';
import { ArrowUpRightIcon } from 'lucide-vue-next';
import { useRouter } from 'vue-router';

const props = withDefaults(defineProps<{
  items: any[];
  className?: string;
  ease?: string;
}>(), {
  className: '',
  ease: 'power3.out'
});

const isHamburgerOpen = ref(true);
const isExpanded = ref(true);
const navRef = ref<HTMLElement | null>(null);
const contentRef = ref<HTMLElement | null>(null);
const cardsRef = ref<HTMLElement[]>([]);
const tlRef = ref<gsap.core.Timeline | null>(null);
const router = useRouter();

const navigate = (path: string) => {
  if (path) {
    if (path.startsWith('http')) {
      window.open(path, '_blank');
    } else {
      // If navigating to the same path, add a refresh timestamp to force the :key to change
      if (router.currentRoute.value.path === path) {
        router.replace({ path, query: { refresh: Date.now() } });
      } else {
        router.push(path);
      }
    }
  }
};

const calculateHeight = () => {
  if (!contentRef.value) return 600;
  const topBarHeight = 80;
  const padding = 32;
  return topBarHeight + contentRef.value.scrollHeight + padding;
};

const createTimeline = () => {
  const navEl = navRef.value;
  if (!navEl) return null;

  const cards = getCards();
  const tl = gsap.timeline({ paused: true });

  tl.to(navEl, {
    height: calculateHeight,
    duration: 0.5,
    ease: props.ease
  });

  tl.to(cards, { 
    y: 0, 
    opacity: 1, 
    duration: 0.4, 
    ease: props.ease, 
    stagger: 0.1 
  }, '-=0.2');

  return tl;
};

const toggleMenu = () => {
  if (!tlRef.value) return;
  
  if (!isExpanded.value) {
    isExpanded.value = true;
    isHamburgerOpen.value = true;
    tlRef.value.play();
  } else {
    isHamburgerOpen.value = false;
    tlRef.value.reverse().eventCallback('onReverseComplete', () => {
      isExpanded.value = false;
    });
  }
};

onMounted(() => {
  nextTick(() => {
    // Clear the array and let it repopulate
    cardsRef.value = [];
    
    if (navRef.value) {
      if (isExpanded.value) {
        gsap.set(navRef.value, { height: 'auto' });
        // repopulate cardsRef by forcing a re-render or just mapping the children
        const cards = Array.from(contentRef.value?.children || []) as HTMLElement[];
        if (cards.length) {
          gsap.set(cards, { y: 0, opacity: 1 });
        }
      } else {
        gsap.set(navRef.value, { height: 80 });
      }
    }

    tlRef.value = createTimeline();
    if (isExpanded.value && tlRef.value) {
      tlRef.value.progress(1);
    }
  });
});

onUnmounted(() => {
  if (tlRef.value) tlRef.value.kill();
});

// Capture card elements manually to be more reliable in v-for
const getCards = () => {
  if (!contentRef.value) return [];
  return Array.from(contentRef.value.querySelectorAll('.nav-card')) as HTMLElement[];
};

watch(() => props.items, () => {
  nextTick(() => {
    if (tlRef.value) tlRef.value.kill();
    
    const cards = getCards();
    
    if (isExpanded.value) {
      // If open, just ensure everything is visible and height fits
      if (navRef.value) {
        gsap.to(navRef.value, { 
          height: 'auto', 
          duration: 0.3, 
          ease: 'power2.out' 
        });
      }
      if (cards.length) {
        gsap.set(cards, { y: 0, opacity: 1, clearProps: 'all' });
      }
      // Re-init timeline for future toggles
      tlRef.value = createTimeline();
      if (tlRef.value) tlRef.value.progress(1);
    } else {
      // If closed, keep it closed
      if (navRef.value) gsap.set(navRef.value, { height: 80 });
      if (cards.length) gsap.set(cards, { y: 30, opacity: 0 });
      tlRef.value = createTimeline();
    }
  });
}, { deep: true });
</script>

<style scoped>
.card-nav-container {
  width: 100%;
}

.card-nav {
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  overflow: hidden;
}

.card-nav-top {
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
}

.hamburger-menu {
  width: 24px;
  height: 14px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  cursor: pointer;
  color: white;
}

.hamburger-line {
  width: 100%;
  height: 1.5px;
  background-color: currentColor;
  transition: transform 0.3s ease;
}

.hamburger-menu.open .hamburger-line:first-child {
  transform: translateY(6px) rotate(45deg);
}

.hamburger-menu.open .hamburger-line:last-child {
  transform: translateY(-6.5px) rotate(-45deg);
}

.logo-container {
  flex: 1;
  display: flex;
  justify-content: center;
}

.logo-text {
  font-size: 1.1rem;
  font-weight: 800;
  color: var(--color-primary);
  letter-spacing: 0.1rem;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.6rem;
  font-weight: 800;
  color: var(--color-success);
  letter-spacing: 0.1em;
}

.dot {
  width: 6px;
  height: 6px;
  background: var(--color-success);
  border-radius: 50%;
}

.pulse {
  animation: pulse-glow 2s infinite;
}

@keyframes pulse-glow {
  0% { box-shadow: 0 0 0 0 rgba(0, 255, 157, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(0, 255, 157, 0); }
  100% { box-shadow: 0 0 0 0 rgba(0, 255, 157, 0); }
}

.card-nav-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 16px 20px 16px;
}

.nav-card {
  padding: 24px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: all 0.3s ease;
}

.nav-card:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 140, 0, 0.3);
  transform: translateY(-4px);
}

.nav-card-label {
  font-size: 0.6rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: var(--color-text-dim);
  margin-bottom: 12px;
}

.nav-card-links {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.nav-card-link {
  display: flex;
  align-items: center;
  gap: 12px;
  text-decoration: none;
  color: white;
  font-weight: 700;
  font-size: 1.2rem;
  transition: opacity 0.2s ease;
}

.nav-card-link:hover {
  opacity: 0.7;
}

.nav-card-link-icon {
  width: 20px;
  height: 20px;
  color: var(--color-primary);
}
</style>
