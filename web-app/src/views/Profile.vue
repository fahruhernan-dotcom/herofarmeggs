<template>
  <div class="profile-page">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">SECURE TERMINAL</h4>
        <h1 class="hero-font">Security Clearance</h1>
        <p class="text-dim">Validate identity and update system access credentials.</p>
      </div>
    </header>

    <div class="profile-grid">
      <!-- LEFT: IDENTITY CARD -->
      <section class="identity-panel glass-panel">
        <div class="identity-card-inner">
          <div class="pfp-container">
            <div class="pfp-glow"></div>
            <UserIcon class="icon-lg pfp-icon" />
            <div class="status-dot online"></div>
          </div>
          <div class="user-meta">
            <h2 class="name">{{ authStore.profile?.full_name || 'Anonymous User' }}</h2>
            <p class="email text-dim">{{ authStore.user?.email }}</p>
            <div class="role-pills">
              <span class="role-pill">{{ authStore.profile?.role?.toUpperCase() || 'STAFF' }}</span>
              <span class="role-pill secured"><ShieldCheckIcon class="icon-xs" /> VERIFIED</span>
            </div>
          </div>
        </div>
        
        <div class="account-stats">
          <div class="stat-item">
            <span class="s-label">Member Since</span>
            <span class="s-val">{{ new Date(authStore.user?.created_at || '').toLocaleDateString() }}</span>
          </div>
          <div class="stat-item">
            <span class="s-label">Last Login</span>
            <span class="s-val">{{ new Date(authStore.user?.last_sign_in_at || '').toLocaleTimeString() }}</span>
          </div>
        </div>
      </section>

      <!-- RIGHT: SECURITY TERMINAL -->
      <section class="security-terminal glass-panel">
        <div class="terminal-header">
          <div class="t-line"></div>
          <h3 class="panel-title"><LockIcon class="icon-sm" /> Update Credentials</h3>
        </div>
        
        <form @submit.prevent="handleUpdatePassword" class="security-form">
          <!-- OLD PASSWORD -->
          <div class="form-group">
            <label class="tactical-label">Current Authentication (Old Password)</label>
            <div class="password-field">
              <KeyIcon class="field-icon" />
              <input 
                :type="pwdState.showOld ? 'text' : 'password'" 
                v-model="pwdForm.oldPassword" 
                placeholder="Required for verification" 
                class="premium-input"
                required
              />
              <button type="button" class="eye-btn" @click="pwdState.showOld = !pwdState.showOld">
                <EyeIcon v-if="!pwdState.showOld" class="icon-xs" />
                <EyeOffIcon v-else class="icon-xs" />
              </button>
            </div>
          </div>

          <div class="divider-line"></div>

          <!-- NEW PASSWORD -->
          <div class="form-row">
            <div class="form-group">
              <label class="tactical-label">New Access Key</label>
              <div class="password-field">
                <ShieldIcon class="field-icon" />
                <input 
                  :type="pwdState.showNew ? 'text' : 'password'" 
                  v-model="pwdForm.newPassword" 
                  placeholder="Min. 6 characters" 
                  class="premium-input"
                  required
                />
                <button type="button" class="eye-btn" @click="pwdState.showNew = !pwdState.showNew">
                  <EyeIcon v-if="!pwdState.showNew" class="icon-xs" />
                  <EyeOffIcon v-else class="icon-xs" />
                </button>
              </div>
            </div>

            <div class="form-group">
              <label class="tactical-label">Confirm New Key</label>
              <div class="password-field">
                <CheckIcon class="field-icon" />
                <input 
                  :type="pwdState.showConfirm ? 'text' : 'password'" 
                  v-model="pwdForm.confirmPassword" 
                  placeholder="Repeat new key" 
                  class="premium-input"
                  required
                />
                <button type="button" class="eye-btn" @click="pwdState.showConfirm = !pwdState.showConfirm">
                  <EyeIcon v-if="!pwdState.showConfirm" class="icon-xs" />
                  <EyeOffIcon v-else class="icon-xs" />
                </button>
              </div>
            </div>
          </div>

          <!-- STRENGTH INDICATOR -->
          <div class="strength-meter" v-if="pwdForm.newPassword">
            <div class="meter-bar" :style="{ width: strengthWidth, backgroundColor: strengthColor }"></div>
            <span class="meter-label" :style="{ color: strengthColor }">{{ strengthText }}</span>
          </div>

          <Transition name="fade">
            <div v-if="msg.error" class="tactical-msg error">
              <div class="msg-accent"></div>
              <AlertCircleIcon class="msg-icon" /> <span>{{ msg.error }}</span>
            </div>
          </Transition>

          <Transition name="fade">
            <div v-if="msg.success" class="tactical-msg success">
              <div class="msg-accent"></div>
              <CheckCircleIcon class="msg-icon" /> <span>{{ msg.success }}</span>
            </div>
          </Transition>

          <div class="form-actions">
            <button type="submit" class="btn-tactical-glow" :disabled="loading || !isFormValid">
              <ZapIcon v-if="!loading" class="icon-sm" />
              <div v-else class="spinner-sm"></div>
              <span>{{ loading ? 'ENCRYPTING & SAVING...' : 'UPDATE SECURITY ACCESS' }}</span>
            </button>
          </div>
        </form>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { useAuthStore } from '../stores/auth';
import { supabase } from '../lib/supabase';
import { 
  UserIcon, 
  ShieldCheckIcon, 
  EyeIcon, 
  EyeOffIcon, 
  AlertCircleIcon,
  CheckCircleIcon,
  LockIcon,
  KeyIcon,
  ShieldIcon,
  CheckIcon,
  ZapIcon
} from 'lucide-vue-next';

const authStore = useAuthStore();
const loading = ref(false);

const pwdState = reactive({
  showOld: false,
  showNew: false,
  showConfirm: false
});

const pwdForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
});

const msg = reactive({
  error: '',
  success: ''
});

const isFormValid = computed(() => {
  return pwdForm.oldPassword.length > 0 && 
         pwdForm.newPassword.length >= 6 && 
         pwdForm.newPassword === pwdForm.confirmPassword;
});

const strengthValue = computed(() => {
  const p = pwdForm.newPassword;
  if (!p) return 0;
  let score = 0;
  if (p.length >= 6) score += 20;
  if (p.length >= 10) score += 20;
  if (/[A-Z]/.test(p)) score += 20;
  if (/[0-9]/.test(p)) score += 20;
  if (/[^A-Za-z0-9]/.test(p)) score += 20;
  return score;
});

const strengthWidth = computed(() => `${strengthValue.value}%`);
const strengthColor = computed(() => {
  if (strengthValue.value < 40) return '#ff4242';
  if (strengthValue.value < 80) return '#ffd700';
  return '#00ff9d';
});
const strengthText = computed(() => {
  if (strengthValue.value < 40) return 'WEAK';
  if (strengthValue.value < 80) return 'MEDIUM';
  return 'STRONG';
});

async function handleUpdatePassword() {
  if (!isFormValid.value) return;
  
  loading.value = true;
  msg.error = '';
  msg.success = '';

  try {
    // 1. Verify Old Password (Supabase method)
    const { error: reauthError } = await supabase.auth.signInWithPassword({
      email: authStore.user?.email || '',
      password: pwdForm.oldPassword,
    });

    if (reauthError) {
      throw new Error('Current password verification failed. Please check your old password.');
    }

    // 2. Update to New Password
    const { error: updateError } = await supabase.auth.updateUser({
      password: pwdForm.newPassword
    });

    if (updateError) throw updateError;

    msg.success = 'Identity re-verified. Access key updated successfully.';
    pwdForm.oldPassword = '';
    pwdForm.newPassword = '';
    pwdForm.confirmPassword = '';
  } catch (err: any) {
    msg.error = err.message || 'Verification Protocol failed.';
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.profile-page {
  display: flex;
  flex-direction: column;
  gap: 32px;
}

.profile-grid {
  display: grid;
  grid-template-columns: 380px 1fr;
  gap: 24px;
}

/* LEFT PANEL: IDENTITY */
.identity-panel {
  padding: 40px;
  display: flex;
  flex-direction: column;
  gap: 40px;
}

.identity-card-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.pfp-container {
  position: relative;
  width: 120px;
  height: 120px;
  margin-bottom: 24px;
}

.pfp-glow {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: var(--color-primary);
  filter: blur(25px);
  opacity: 0.15;
  border-radius: 40px;
}

.pfp-icon {
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--glass-border);
  padding: 30px;
  border-radius: 40px;
  color: var(--color-primary);
  z-index: 1;
  position: relative;
}

.status-dot {
  position: absolute;
  bottom: 5px;
  right: 5px;
  width: 18px;
  height: 18px;
  border: 3px solid #0a0a0a;
  border-radius: 50%;
  z-index: 2;
}

.status-dot.online { 
  background: var(--color-success);
  box-shadow: 0 0 10px var(--color-success);
}

.user-meta .name { 
  font-size: 1.8rem; 
  font-weight: 900; 
  color: white; 
  letter-spacing: -0.02em;
  text-transform: uppercase;
  margin-bottom: 4px;
  font-family: var(--font-headline);
}

.user-meta .email { 
  font-size: 1rem; 
  margin: 0 0 28px 0; 
  opacity: 0.6;
  font-weight: 500;
}

.role-pills { 
  display: flex; 
  gap: 12px; 
  justify-content: center; 
  align-items: center;
}

.role-pill {
  font-size: 0.7rem;
  font-weight: 800;
  padding: 6px 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  color: #a0a0a0;
  letter-spacing: 0.05em;
  display: flex;
  align-items: center;
  gap: 6px;
  text-transform: uppercase;
  transition: all 0.3s ease;
}

.role-pill.secured { 
  color: var(--color-success); 
  border-color: rgba(0, 255, 157, 0.15); 
  background: rgba(0, 255, 157, 0.02);
}

.role-pill svg {
  width: 14px;
  height: 14px;
}

.account-stats {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 24px;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 20px;
}

.stat-item { display: flex; justify-content: space-between; align-items: center; }
.s-label { font-size: 0.7rem; font-weight: 800; color: var(--color-text-dim); text-transform: uppercase; }
.s-val { font-size: 0.8rem; font-weight: 700; color: white; }

/* RIGHT PANEL: SECURITY */
.security-terminal {
  padding: 48px;
  position: relative;
}

.terminal-header {
  margin-bottom: 40px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.t-line { width: 40px; height: 3px; background: var(--color-primary); border-radius: 2px; }
.panel-title { font-size: 1.3rem; font-weight: 800; color: white; display: flex; align-items: center; gap: 10px; }

.security-form { display: flex; flex-direction: column; gap: 32px; max-width: 700px; }

.divider-line { height: 1px; background: linear-gradient(90deg, var(--glass-border), transparent); }

.tactical-label {
  font-size: 0.75rem;
  font-weight: 950;
  color: var(--color-text-dim);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 12px;
  display: block;
}

.password-field { position: relative; }
.field-icon {
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-primary);
  opacity: 0.4;
  width: 18px;
}

.premium-input {
  width: 100%;
  background: rgba(10, 10, 10, 0.4);
  border: 1px solid var(--glass-border);
  padding: 16px 48px 16px 48px;
  border-radius: 15px;
  color: white;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.premium-input:focus {
  border-color: var(--color-primary);
  background: rgba(255, 140, 0, 0.05);
  box-shadow: 0 0 20px rgba(255, 140, 0, 0.05);
  outline: none;
}

.eye-btn {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: var(--color-text-dim);
  cursor: pointer;
}

.eye-btn:hover { color: white; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }

/* STRENGTH METER */
.strength-meter { margin-top: -8px; }
.meter-bar { height: 3px; border-radius: 4px; transition: all 0.5s ease; width: 0; }
.meter-label { font-size: 0.6rem; font-weight: 900; margin-top: 6px; display: block; letter-spacing: 0.1em; }

/* TACTICAL MESSAGES */
.tactical-msg {
  position: relative;
  padding: 16px 20px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 0.85rem;
  font-weight: 700;
  overflow: hidden;
}

.msg-accent { position: absolute; left: 0; top: 0; width: 4px; height: 100%; }

.tactical-msg.error { background: rgba(255, 66, 66, 0.05); border: 1px solid rgba(255, 66, 66, 0.2); color: #ff4242; }
.tactical-msg.error .msg-accent { background: #ff4242; }

.tactical-msg.success { background: rgba(0, 255, 157, 0.05); border: 1px solid rgba(0, 255, 157, 0.2); color: #00ff9d; }
.tactical-msg.success .msg-accent { background: #00ff9d; }

.btn-tactical-glow {
  width: 100%;
  background: var(--color-primary);
  color: black;
  border: none;
  padding: 18px;
  border-radius: 15px;
  font-weight: 900;
  font-size: 0.85rem;
  letter-spacing: 0.1em;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 10px 30px rgba(255, 140, 0, 0.2);
}

.btn-tactical-glow:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 15px 40px rgba(255, 140, 0, 0.3);
}

.btn-tactical-glow:disabled { opacity: 0.3; cursor: not-allowed; }

.spinner-sm {
  width: 18px;
  height: 18px;
  border: 3px solid rgba(0,0,0,0.1);
  border-top-color: black;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

@media (max-width: 1000px) {
  .profile-grid { grid-template-columns: 1fr; }
  .identity-panel { min-height: auto; }
}
</style>
