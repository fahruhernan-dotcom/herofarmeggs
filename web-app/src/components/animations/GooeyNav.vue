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
  particleCount: 10,
  particleDistances: () => [80, 10],
  particleR: 100,
  timeVariance: 300,
  colors: () => ['#FF8C00', '#FF4D00', '#FFBD2E', '#ffffff']
});

const route = useRoute();
const containerRef = ref<HTMLElement | null>(null);
const navRef = ref<HTMLElement | null>(null);
const filterRef = ref<HTMLElement | null>(null);
const textRef = ref<HTMLElement | null>(null);
const activeIndex = ref(0);

const noise = (n = 1) => n / 2 - Math.random() * n;

const getXY = (distance: number, pointIndex: number, totalPoints: number) => {
  const safeTotal = Math.max(1, totalPoints);
  const angle = ((360 + noise(8)) / safeTotal) * pointIndex * (Math.PI / 180);
  return [distance * Math.cos(angle), distance * Math.sin(angle)];
};

const createParticle = (i: number, t: number, d: number[], r: number) => {
  const count = Math.max(1, props.particleCount || 10);
  const colors = props.colors.length > 0 ? props.colors : ['#FF8C00', '#ffffff'];
  
  const rotateVal = noise(r / 10);
  const finalRotate = rotateVal > 0 ? (rotateVal + r / 20) * 10 : (rotateVal - r / 20) * 10;
  
  const colorIndex = Math.floor(Math.random() * colors.length);
  const safeColor = colors[colorIndex] || '#FF8C00';

  return {
    start: getXY(d[0] ?? 80, count - i, count),
    end: getXY((d[1] ?? 10) + noise(7), count - i, count),
    time: t,
    scale: 1 + noise(0.2),
    color: safeColor,
    rotate: finalRotate
  };
};

const makeParticles = (element: HTMLElement) => {
  if (!element) return;
  const d = props.particleDistances ?? [80, 10];
  const r = props.particleR ?? 100;
  const baseTime = (props.animationTime || 600) * 2;
  const count = Math.max(1, props.particleCount || 10);
  const timeVar = props.timeVariance || 300;

  for (let i = 0; i < count; i++) {
    const t = baseTime + noise(timeVar * 2);
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
      if (element && element.contains(particle)) {
        element.removeChild(particle);
      }
    }, t);
  }
};

const updateEffectPosition = (element: HTMLElement | null | undefined) => {
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
  
  const label = element.querySelector('.nav-label');
  if (label) {
    textRef.value.innerText = (label as HTMLElement).innerText;
  }
};

const handleClick = (_e: MouseEvent, index: number) => {
  activeIndex.value = index;
  
  nextTick(() => {
    if (!navRef.value) return;
    const items = navRef.value.querySelectorAll('li');
    const liEl = items[index] as HTMLElement;
    updateEffectPosition(liEl);
    
    if (filterRef.value) {
      const oldParticles = filterRef.value.querySelectorAll('.particle');
      oldParticles.forEach(p => filterRef.value?.removeChild(p));
      
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

watch(() => route.path, (newPath) => {
  const index = props.items.findIndex(item => item.path === newPath);
  if (index !== -1) {
    activeIndex.value = index;
    nextTick(() => {
      if (!navRef.value) return;
      const items = navRef.value.querySelectorAll('li');
      const activeLi = items[index] as HTMLElement;
      updateEffectPosition(activeLi);
    });
  }
}, { immediate: true });

let resizeObserver: ResizeObserver | null = null;

onMounted(() => {
  setTimeout(() => {
    if (!navRef.value) return;
    const items = navRef.value.querySelectorAll('li');
    const activeLi = items[activeIndex.value] as HTMLElement;
    updateEffectPosition(activeLi);
    textRef.value?.classList.add('active');
    filterRef.value?.classList.add('active');
  }, 100);

  resizeObserver = new ResizeObserver(() => {
    if (!navRef.value) return;
    const items = navRef.value.querySelectorAll('li');
    const currentActiveLi = items[activeIndex.value] as HTMLElement;
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
  z-index: 5;
}

.nav-anchor {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  text-decoration: none;
  color: var(--color-text-dim);
  border-radius: 16px;
  transition: all 0.5s cubic-bezier(0.165, 0.84, 0.44, 1);
  font-weight: 600;
  background: transparent;
}

li.active .nav-anchor {
  color: transparent !important;
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

.effect.text {
  display: flex;
  align-items: center;
  padding-left: 56px;
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
  transform: translate3d(var(--start-x), var(--start-y), 0) scale(var(--scale)) rotate(var(--rotate));
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
