<template>
  <div class="gooey-nav-container" ref="containerRef">
    <nav>
      <ul ref="navRef">
        <li 
          v-for="(item, index) in items" 
          :key="index" 
          :class="{ active: activeIndex === index }"
        >
          <router-link 
            :to="item.path" 
            @click="handleClick($event, index)"
            class="nav-anchor"
          >
            <component :is="item.icon" class="nav-icon" v-if="item.icon" />
            <span class="nav-label">{{ item.label }}</span>
          </router-link>
        </li>
      </ul>
    </nav>
    
    <!-- The Gooey Liquid Blob -->
    <span class="effect filter" ref="filterRef" />
    
    <!-- The "Above-Liquid" Text Overlay -->
    <span class="effect text" ref="textRef"></span>
    
    <!-- Gooey SVG Filter Definition -->
    <svg xmlns="http://www.w3.org/2000/svg" version="1.1" class="gooey-svg-def">
      <defs>
        <filter id="gooey-effect">
          <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur" />
          <feColorMatrix in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 19 -9" result="goo" />
          <feComposite in="SourceGraphic" in2="goo" operator="atop" />
        </filter>
      </defs>
    </svg>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue';
import { useRoute } from 'vue-router';

interface NavItem {
  path: string;
  label: string;
  icon?: any;
}

const props = withDefaults(defineProps<{
  items: NavItem[];
  animationTime?: number;
  particleCount?: number;
  particleDistances?: number[];
  particleR?: number;
  timeVariance?: number;
  colors?: string[];
}>(), {
  animationTime: 600,
  particleCount: 10, // USER REQUESTED: 10
  particleDistances: () => [80, 10],
  particleR: 100, // USER REQUESTED: 100
  timeVariance: 300, // USER REQUESTED: 300
  colors: () => ['var(--color-primary)', '#FF4D00', '#FFBD2E', '#ffffff']
});

const route = useRoute();
const containerRef = ref<HTMLElement | null>(null);
const navRef = ref<HTMLElement | null>(null);
const filterRef = ref<HTMLElement | null>(null);
const textRef = ref<HTMLElement | null>(null);
const activeIndex = ref(0);

const noise = (n = 1) => n / 2 - Math.random() * n;

const getXY = (distance: number, pointIndex: number, totalPoints: number) => {
  const angle = ((360 + noise(8)) / totalPoints) * pointIndex * (Math.PI / 180);
  return [distance * Math.cos(angle), distance * Math.sin(angle)];
};

const createParticle = (i: number, t: number, d: number[], r: number) => {
  let rotate = noise(r / 10);
  return {
    start: getXY(d[0], props.particleCount - i, props.particleCount),
    end: getXY(d[1] + noise(7), props.particleCount - i, props.particleCount),
    time: t,
    scale: 1 + noise(0.2),
    color: props.colors[Math.floor(Math.random() * props.colors.length)],
    rotate: rotate > 0 ? (rotate + r / 20) * 10 : (rotate - r / 20) * 10
  };
};

const makeParticles = (element: HTMLElement) => {
  if (!element) return;
  const d = props.particleDistances;
  const r = props.particleR;
  const baseTime = props.animationTime * 2;

  for (let i = 0; i < props.particleCount; i++) {
    const t = baseTime + noise(props.timeVariance * 2);
    const p = createParticle(i, t, d, r);

    const particle = document.createElement('span');
    const point = document.createElement('span');
    particle.classList.add('particle');
    
    particle.style.setProperty('--start-x', `${p.start[0]}px`);
    particle.style.setProperty('--start-y', `${p.start[1]}px`);
    particle.style.setProperty('--end-x', `${p.end[0]}px`);
    particle.style.setProperty('--end-y', `${p.end[1]}px`);
    particle.style.setProperty('--time', `${p.time}ms`);
    particle.style.setProperty('--scale', `${p.scale}`);
    particle.style.setProperty('--color', p.color);
    particle.style.setProperty('--rotate', `${p.rotate}deg`);

    point.classList.add('point');
    particle.appendChild(point);
    element.appendChild(particle);

    setTimeout(() => {
      if (element.contains(particle)) {
        element.removeChild(particle);
      }
    }, t);
  }
};

const updateEffectPosition = (element: HTMLElement | undefined) => {
  if (!element || !containerRef.value || !filterRef.value || !textRef.value) return;
  
  const containerRect = containerRef.value.getBoundingClientRect();
  const pos = element.getBoundingClientRect();

  const styles = {
    left: `${pos.left - containerRect.left}px`,
    top: `${pos.top - containerRect.top}px`,
    width: `${pos.width}px`,
    height: `${pos.height}px`
  };
  
  Object.assign(filterRef.value.style, styles);
  Object.assign(textRef.value.style, styles);
  
  // Clone the inner text to the floating text effect layer
  const label = element.querySelector('.nav-label');
  if (label) {
    textRef.value.innerText = (label as HTMLElement).innerText;
  }
};

const handleClick = (e: MouseEvent, index: number) => {
  // If clicking same item, just trigger particles for fun
  activeIndex.value = index;
  
  nextTick(() => {
    const liEl = (navRef.value?.querySelectorAll('li')[index]) as HTMLElement;
    updateEffectPosition(liEl);
    
    if (filterRef.value) {
      // Clear old particles if any
      const oldParticles = filterRef.value.querySelectorAll('.particle');
      oldParticles.forEach(p => filterRef.value?.removeChild(p));
      
      // Trigger animation
      filterRef.value.classList.remove('active');
      void filterRef.value.offsetWidth;
      filterRef.value.classList.add('active');
      makeParticles(filterRef.value);
    }

    if (textRef.value) {
      textRef.value.classList.remove('active');
      void textRef.value.offsetWidth;
      textRef.value.classList.add('active');
    }
  });
};

// Sync active state with Router
watch(() => route.path, (newPath) => {
  const index = props.items.findIndex(item => item.path === newPath);
  if (index !== -1) {
    activeIndex.value = index;
    nextTick(() => {
      const activeLi = navRef.value?.querySelectorAll('li')[index] as HTMLElement;
      updateEffectPosition(activeLi);
    });
  }
}, { immediate: true });

let resizeObserver: ResizeObserver;

onMounted(() => {
  // Initial position
  setTimeout(() => {
    const activeLi = navRef.value?.querySelectorAll('li')[activeIndex.value] as HTMLElement;
    updateEffectPosition(activeLi);
    textRef.value?.classList.add('active');
    filterRef.value?.classList.add('active');
  }, 100);

  resizeObserver = new ResizeObserver(() => {
    const currentActiveLi = navRef.value?.querySelectorAll('li')[activeIndex.value] as HTMLElement;
    updateEffectPosition(currentActiveLi);
  });

  if (containerRef.value) {
    resizeObserver.observe(containerRef.value);
  }
});

onUnmounted(() => {
  if (resizeObserver) resizeObserver.disconnect();
});
</script>

<style scoped>
.gooey-nav-container {
  position: relative;
  width: 100%;
  --time: 1200ms; /* Default full cycle time */
}

.gooey-svg-def {
  position: absolute;
  width: 0;
  height: 0;
  pointer-events: none;
}

nav ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

li {
  position: relative;
  z-index: 5; /* Keep real links above the blob background */
}

.nav-anchor {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  text-decoration: none;
  color: var(--color-text-dim);
  border-radius: 16px;
  transition: color 0.4s ease;
  font-weight: 600;
  background: transparent;
}

li.active .nav-anchor {
  color: transparent !important; /* Hide real text, show effect text */
}

li.active .nav-icon {
  color: white;
  opacity: 1;
}

.nav-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  z-index: 10;
  opacity: 0.6;
}

/* EFFECT BLOB (THE LIQUID) */
.effect {
  position: absolute;
  pointer-events: none;
  z-index: 2;
  transition: all 0.5s cubic-bezier(0.165, 0.84, 0.44, 1);
  border-radius: 16px;
}

.effect.filter {
  background: transparent;
  filter: url(#gooey-effect);
}

.effect.filter.active {
  background: var(--color-primary);
  box-shadow: 0 10px 30px -5px rgba(255, 140, 0, 0.4);
}

/* THE FLOATING TEXT (Perfect Aligned) */
.effect.text {
  display: flex;
  align-items: center;
  padding-left: 56px; /* Icon width (20) + gap (16) + left padding (20) */
  color: white;
  font-weight: 700;
  background: transparent;
  opacity: 0;
  z-index: 6;
}

.effect.text.active {
  opacity: 1;
  animation: text-appear 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

@keyframes text-appear {
  from { opacity: 0; transform: translateX(-10px); }
  to { opacity: 1; transform: translateX(0); }
}

/* PARTICLES INTERNAL */
:deep(.particle) {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  pointer-events: none;
}

:deep(.point) {
  position: absolute;
  top: 0;
  left: 0;
  width: 32px;
  height: 32px;
  margin: -16px 0 0 -16px;
  background: var(--color);
  border-radius: 50%;
  transform: translate3d(var(--start-x), var(--start-y), 0) scale(var(--scale));
  animation: particle-move var(--time) ease-out forwards;
}

@keyframes particle-move {
  0% { 
    transform: translate3d(var(--start-x), var(--start-y), 0) scale(var(--scale)); 
    opacity: 1;
  }
  100% { 
    transform: translate3d(var(--end-x), var(--end-y), 0) scale(0); 
    opacity: 0;
  }
}
</style>
