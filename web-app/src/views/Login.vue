<template>
  <div class="login-container">
    <!-- 🌌 FUTURISTIC BACKGROUND ANIMATION -->
    <DarkVeil 
      :hueShift="25" 
      :warpAmount="0.4" 
      :speed="0.8" 
      :noiseIntensity="0.015" 
    />

    <div class="login-card-wrapper">
      <!-- Outer Glow Effect -->
      <div class="card-outer-glow"></div>
      
      <!-- 📛 3D LANYARD AUTH TRANSITION -->
      <transition name="lanyard-fade">
        <Lanyard 
          v-if="showLanyard" 
          :userName="email.split('@')[0]" 
          userRole="AUTHORIZED ADMIN"
          @authorized="handleAuthorized"
        />
      </transition>

      <transition name="card-auth">
        <div class="glass-panel login-card" v-if="!showLanyard">
          <div class="card-header">
            <div class="header-glow"></div>
            <h4 class="brand-tag">SECURITY FOUNDATION</h4>
            <h1 class="hero-font main-title">{{ isSignUp ? 'CREATE ADMIN' : 'HERO FARM' }}</h1>
            <p class="subtitle">{{ isSignUp ? 'Initialize your elite access.' : 'Access the hub of premium standards.' }}</p>
          </div>

          <form @submit.prevent="handleSubmit" class="login-form">
            <div class="input-group">
              <label for="email">IDENTIFIER</label>
              <div class="input-wrapper">
                <input 
                  type="email" 
                  id="email" 
                  v-model="email" 
                  placeholder="admin@herofarm.com"
                  required
                  autocomplete="off"
                />
                <div class="input-border"></div>
              </div>
            </div>

            <div class="input-group">
              <label for="password">SECURITY KEY</label>
              <div class="input-wrapper">
                <input 
                  type="password" 
                  id="password" 
                  v-model="password" 
                  placeholder="••••••••"
                  required
                />
                <div class="input-border"></div>
              </div>
            </div>

            <div v-if="errorMsg" class="error-message">
              <span class="error-dot"></span>
              {{ errorMsg }}
            </div>
            <div v-if="successMsg" class="success-message">
              <span class="success-dot"></span>
              {{ successMsg }}
            </div>

            <button type="submit" class="btn-primary-premium" :disabled="loading">
              <div class="btn-content">
                <span v-if="!loading">{{ isSignUp ? 'AUTHORIZE REGISTRATION' : 'ACCESS HUB' }}</span>
                <span v-else class="loader-dots">
                  <span>.</span><span>.</span><span>.</span>
                </span>
              </div>
              <div class="btn-shine"></div>
            </button>

            <div class="toggle-mode">
              <button type="button" @click="isSignUp = !isSignUp" class="btn-link">
                {{ isSignUp ? 'LOG IN TO EXISTING NODE' : 'INITIALIZE NEW ADMIN PROFILE' }}
              </button>
            </div>
          </form>
        </div>
      </transition>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { supabase } from '../lib/supabase';
import { useRouter } from 'vue-router';
import DarkVeil from '../components/animations/DarkVeil.vue';
import Lanyard from '../components/animations/Lanyard.vue';

const email = ref('');
const password = ref('');
const isSignUp = ref(false);
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');
const showLanyard = ref(false);
const router = useRouter();

async function handleSubmit() {
  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  
  if (isSignUp.value) {
    const { error } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
    });
    if (error) {
      errorMsg.value = error.message;
    } else {
      successMsg.value = 'Registration successful! You can now login.';
      isSignUp.value = false;
    }
  } else {
    // 🔍 AUTHENTICATION ATTEMPT
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });

    if (error) {
      errorMsg.value = error.message;
    } else {
      console.log('Auth Success: Waiting for Identity Authorization...');
      showLanyard.value = true;
      // No more automatic redirect here!
    }
  }
  
  loading.value = false;
}

function handleAuthorized() {
  console.log('Final Authorization Received: Redirecting to Hub...');
  router.push('/');
}
</script>


<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  background: transparent;
  overflow: hidden;
}

.login-card-wrapper {
  position: relative;
  z-index: 10;
  width: 100%;
  max-width: 460px;
  padding: 20px;
}

.card-outer-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 110%;
  height: 110%;
  background: radial-gradient(circle, rgba(255, 140, 0, 0.08) 0%, transparent 70%);
  z-index: -1;
  pointer-events: none;
}

.login-card {
  padding: 56px;
  background: rgba(8, 8, 8, 0.5);
  backdrop-filter: blur(40px) saturate(200%);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 
    0 40px 120px -20px rgba(0, 0, 0, 0.8),
    inset 0 0 20px rgba(255, 255, 255, 0.02);
  border-radius: 32px;
}

.card-header {
  text-align: center;
  margin-bottom: 48px;
  position: relative;
}

.header-glow {
  position: absolute;
  top: -30px;
  left: 50%;
  transform: translateX(-50%);
  width: 140px;
  height: 50px;
  background: var(--color-primary);
  filter: blur(60px);
  opacity: 0.25;
}

.brand-tag {
  color: var(--color-primary);
  letter-spacing: 5px;
  font-size: 0.7rem;
  font-weight: 800;
  margin-bottom: 16px;
  text-transform: uppercase;
  opacity: 0.8;
}

.main-title {
  font-size: 3rem;
  font-weight: 900;
  line-height: 0.9;
  margin-bottom: 16px;
  letter-spacing: -3px;
  background: linear-gradient(to bottom, #fff 40%, rgba(255,255,255,0.6));
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.subtitle {
  color: var(--color-text-dim);
  font-size: 0.95rem;
  font-weight: 500;
  max-width: 250px;
  margin: 0 auto;
  line-height: 1.5;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.input-group label {
  font-size: 0.65rem;
  font-weight: 800;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 3px;
  margin-left: 4px;
}

.input-wrapper {
  position: relative;
}

.input-group input {
  width: 100%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 18px 24px;
  border-radius: 16px;
  color: white;
  font-size: 1.05rem;
  font-family: var(--font-body);
  transition: all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
  box-sizing: border-box;
}

.input-border {
  position: absolute;
  bottom: 0;
  left: 50%;
  width: 0;
  height: 1px;
  background: var(--color-primary);
  transition: all 0.4s ease;
  transform: translateX(-50%);
  opacity: 0;
}

.input-group input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.07);
  border-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5);
}

.input-group input:focus + .input-border {
  width: 80%;
  opacity: 1;
}

.error-message, .success-message {
  font-size: 0.8rem;
  padding: 16px 20px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  gap: 12px;
  animation: shake 0.4s cubic-bezier(.36,.07,.19,.97) both;
}

.error-message {
  color: #FF6B6B;
  background: rgba(255, 107, 107, 0.08);
  border: 1px solid rgba(255, 107, 107, 0.15);
}

.success-message {
  color: #00FFB2;
  background: rgba(0, 255, 178, 0.08);
  border: 1px solid rgba(0, 255, 178, 0.15);
}

.error-dot { width: 6px; height: 6px; background: #FF6B6B; border-radius: 50%; box-shadow: 0 0 10px #FF6B6B; }
.success-dot { width: 6px; height: 6px; background: #00FFB2; border-radius: 50%; box-shadow: 0 0 10px #00FFB2; }

@keyframes shake {
  10%, 90% { transform: translate3d(-1px, 0, 0); }
  20%, 80% { transform: translate3d(2px, 0, 0); }
  30%, 50%, 70% { transform: translate3d(-3px, 0, 0); }
  40%, 60% { transform: translate3d(3px, 0, 0); }
}

.btn-primary-premium {
  position: relative;
  width: 100%;
  height: 64px;
  border-radius: 18px;
  border: none;
  background: linear-gradient(135deg, var(--color-primary), #FF4D00);
  color: white;
  font-size: 0.9rem;
  font-weight: 800;
  letter-spacing: 3px;
  cursor: pointer;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  box-shadow: 0 20px 40px -10px rgba(255, 140, 0, 0.4);
}

.btn-primary-premium:hover {
  transform: translateY(-4px) scale(1.02);
  box-shadow: 0 25px 50px -12px rgba(255, 140, 0, 0.6);
}

.btn-shine {
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    120deg,
    transparent,
    rgba(255, 255, 255, 0.3),
    transparent
  );
  transition: all 0.6s ease;
}

.btn-primary-premium:hover .btn-shine {
  left: 100%;
}

.loader-dots span {
  animation: loading-dot 1s infinite;
  display: inline-block;
  font-size: 1.5rem;
  line-height: 0;
}

.loader-dots span:nth-child(2) { animation-delay: 0.2s; }
.loader-dots span:nth-child(3) { animation-delay: 0.4s; }

@keyframes loading-dot {
  0% { transform: translateY(0); opacity: 0.2; }
  50% { transform: translateY(-5px); opacity: 1; }
  100% { transform: translateY(0); opacity: 0.2; }
}

.toggle-mode {
  text-align: center;
}

.btn-link {
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  font-size: 0.75rem;
  font-weight: 800;
  letter-spacing: 2px;
  cursor: pointer;
  opacity: 0.6;
  transition: all 0.3s ease;
}

.btn-link:hover {
  color: white;
  opacity: 1;
}

/* 🎭 AUTH TRANSITIONS - MORPH EFFECT */
.card-auth-leave-active {
  transition: all 0.6s cubic-bezier(0.19, 1, 0.22, 1);
}

.card-auth-leave-to {
  opacity: 0;
  transform: translateY(-20px) scale(0.85);
  filter: blur(40px) brightness(2);
}

.lanyard-fade-enter-active {
  transition: opacity 1.2s ease-out;
  transition-delay: 0.2s;
}

.lanyard-fade-enter-from {
  opacity: 0;
}
</style>
