<template>
  <div class="profile-page">
    <header class="header-premium desktop-only">
      <div class="hp-left">
        <h4 class="m-profile-tag">AKUN</h4>
        <h1 class="hero-font-premium">Pengaturan Akun</h1>
      </div>
      <div class="hp-right">
        <div class="status-badge-compact">
          <span class="dot online pulse"></span>
          <span class="status-text">Online</span>
        </div>
      </div>
    </header>

    <!-- NEW MOBILE HEADER -->
    <div class="mobile-profile-header mobile-only">
      <h4 class="m-profile-tag">AKUN SAYA</h4>
    </div>

    <div class="profile-grid-premium">
      <!-- ROW 1: SUMMARY (Desktop Only) -->
      <section class="profile-summary-card glass-panel-premium desktop-only">
        <div class="summary-left">
          <div class="avatar-wrapper-premium">
            <UserIcon class="avatar-icon-premium" />
            <div class="status-dot-premium"></div>
          </div>
          <div class="user-main-info">
            <h2 class="user-name-premium">{{ authStore.profile?.full_name || 'Anonymous User' }}</h2>
            <p class="user-email-premium">{{ authStore.user?.email }}</p>
          </div>
        </div>
        <div class="summary-right">
          <div class="role-badges-premium">
            <span class="badge-premium admin">{{ authStore.profile?.role?.toUpperCase() || 'STAFF' }}</span>
            <span class="badge-premium verified">VERIFIED</span>
          </div>
          <div class="login-meta-premium">
            <span>Member sejak {{ new Date(authStore.user?.created_at || '').toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) }}</span>
            <span class="meta-sep">•</span>
            <span>Login terakhir: {{ new Date(authStore.user?.last_sign_in_at || '').toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) }}</span>
          </div>
        </div>
      </section>

      <!-- MOBILE PANEL WRAPPER (EXISTING) -->
      <section class="identity-panel glass-panel mobile-only">
        <!-- MOBILE COMPACT IDENTITY -->
        <div class="m-identity-card mobile-only">
          <div class="m-pfp-wrapper">
            <div class="m-pfp-avatar">
              <UserIcon class="m-pfp-icon" />
              <div class="m-status-dot"></div>
            </div>
          </div>
          <div class="m-user-info">
            <h2 class="m-user-name">{{ authStore.profile?.full_name || 'Anonymous User' }}</h2>
            <div class="m-role-badges">
              <span class="m-badge admin">{{ authStore.profile?.role?.toUpperCase() || 'STAFF' }}</span>
              <span class="m-badge verified">VERIFIED</span>
            </div>
            <p class="m-user-email">{{ authStore.user?.email }}</p>
          </div>
        </div>
      </section>

      <!-- ROW 2: FORMS GRID -->
      <div class="forms-grid-desktop-container">
        <!-- IDENTITY FORM -->
        <section class="form-card-premium glass-panel-premium identity-panel glass-panel">
          <div class="card-header-premium">
            <UserIcon class="icon-sm" style="color: #3ab0ff;" />
            <h3>Identitas</h3>
          </div>
          
          <form @submit.prevent="handleUpdateProfile" class="form-premium">
            <div class="form-group-premium">
              <label class="label-premium tactical-label">Nama Lengkap</label>
              <div class="input-wrapper-premium">
                <Edit3Icon class="i-icon" />
                <input 
                  type="text" 
                  v-model="profileForm.fullName" 
                  placeholder="Enter your name" 
                  class="input-premium profile-input"
                  required
                />
              </div>
            </div>

            <Transition name="fade">
              <div v-if="profileMsg.error" class="tactical-msg error">
                <div class="msg-accent"></div>
                <AlertCircleIcon class="msg-icon" /> <span>{{ profileMsg.error }}</span>
              </div>
            </Transition>

            <Transition name="fade">
              <div v-if="profileMsg.success" class="tactical-msg success">
                <div class="msg-accent"></div>
                <CheckCircleIcon class="msg-icon" /> <span>{{ profileMsg.success }}</span>
              </div>
            </Transition>

            <div class="actions-premium">
              <button type="submit" class="btn-premium secondary profile-btn" :disabled="profileLoading">
                <span>{{ profileLoading ? 'SIMPAN...' : 'Simpan' }}</span>
              </button>
            </div>
          </form>
        </section>

        <!-- SECURITY FORM -->
        <section class="form-card-premium glass-panel-premium identity-panel glass-panel">
          <div class="card-header-premium">
            <LockIcon class="icon-sm" style="color: var(--color-primary);" />
            <h3>Keamanan</h3>
          </div>
          
          <form @submit.prevent="handleUpdatePassword" class="form-premium">
            <div class="form-group-premium">
              <label class="label-premium tactical-label old-pwd-label">Password Lama</label>
              <div class="input-wrapper-premium">
                <KeyIcon class="i-icon" />
                <input 
                  :type="pwdState.showOld ? 'text' : 'password'" 
                  v-model="pwdForm.oldPassword" 
                  class="input-premium profile-input"
                  required
                />
                <button type="button" class="i-eye-btn" @click="pwdState.showOld = !pwdState.showOld">
                  <EyeIcon v-if="!pwdState.showOld" class="i-icon-xs" />
                  <EyeOffIcon v-else class="i-icon-xs" />
                </button>
              </div>
            </div>

            <div class="form-grid-2">
              <div class="form-group-premium">
                <label class="label-premium tactical-label new-pwd-label">Password Baru</label>
                <div class="input-wrapper-premium">
                  <ShieldIcon class="i-icon" />
                  <input 
                    :type="pwdState.showNew ? 'text' : 'password'" 
                    v-model="pwdForm.newPassword" 
                    placeholder="Min. 6..." 
                    class="input-premium profile-input"
                    required
                  />
                  <button type="button" class="i-eye-btn" @click="pwdState.showNew = !pwdState.showNew">
                    <EyeIcon v-if="!pwdState.showNew" class="i-icon-xs" />
                    <EyeOffIcon v-else class="i-icon-xs" />
                  </button>
                </div>
              </div>

              <div class="form-group-premium">
                <label class="label-premium tactical-label confirm-pwd-label">Konfirmasi</label>
                <div class="input-wrapper-premium">
                  <CheckIcon class="i-icon" />
                  <input 
                    :type="pwdState.showConfirm ? 'text' : 'password'" 
                    v-model="pwdForm.confirmPassword" 
                    class="input-premium profile-input"
                    required
                  />
                  <button type="button" class="i-eye-btn" @click="pwdState.showConfirm = !pwdState.showConfirm">
                    <EyeIcon v-if="!pwdState.showConfirm" class="i-icon-xs" />
                    <EyeOffIcon v-else class="i-icon-xs" />
                  </button>
                </div>
              </div>
            </div>

            <div class="strength-meter-compact" v-if="pwdForm.newPassword">
              <div class="meter-bar" :style="{ width: strengthWidth, backgroundColor: strengthColor }"></div>
            </div>

            <div class="actions-premium">
              <button type="submit" class="btn-premium profile-btn" :disabled="loading || !isFormValid">
                <span>{{ loading ? 'ENCRYPTING...' : 'Update Password' }}</span>
              </button>
            </div>
          </form>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { useAuthStore } from '../stores/auth';
import { supabase } from '../lib/supabase';
import { 
  UserIcon, 
  EyeIcon, 
  EyeOffIcon, 
  AlertCircleIcon,
  CheckCircleIcon,
  LockIcon,
  KeyIcon,
  ShieldIcon,
  CheckIcon,
  Edit3Icon
} from 'lucide-vue-next';

const authStore = useAuthStore();
const loading = ref(false);
const profileLoading = ref(false);

const profileForm = reactive({
  fullName: ''
});

const profileMsg = reactive({
  error: '',
  success: ''
});

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

onMounted(() => {
  // Sync form with current data
  if (authStore.profile) {
    profileForm.fullName = authStore.profile.full_name || '';
  }
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

async function handleUpdateProfile() {
  if (!profileForm.fullName.trim()) return;
  
  profileLoading.value = true;
  profileMsg.error = '';
  profileMsg.success = '';

  try {
    // 1. Sync with Profiles table (legacy/general)
    const { error: pError } = await supabase
      .from('profiles')
      .update({ full_name: profileForm.fullName })
      .eq('id', authStore.user?.id);

    if (pError) console.warn('Profile fallback sync failed:', pError);

    // 2. Sync with Team Members table (Primary for this app)
    // We try to update by email or auth_user_id to be safe
    const { error: tmError } = await supabase
      .from('team_members')
      .update({ full_name: profileForm.fullName })
      .eq('email', authStore.user?.email);

    if (tmError) throw tmError;

    // Refresh store profile data
    if (authStore.user) await authStore.fetchProfile(authStore.user);
    
    // Sync local form with new data
    if (authStore.profile) {
      profileForm.fullName = authStore.profile.full_name || '';
    }
    
    profileMsg.success = 'Identity database synchronized. Name updated.';
  } catch (err: any) {
    profileMsg.error = err.message || 'Identity synchronization failed.';
  } finally {
    profileLoading.value = false;
  }
}

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
  gap: 24px;
}

/* HEADER PREMIUM */
.header-premium {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 8px;
}

.m-profile-tag {
  font-size: 10px;
  font-weight: 800;
  color: #64748b;
  letter-spacing: 1px;
  margin-bottom: 4px;
}

.hero-font-premium {
  font-size: 22px;
  font-weight: 800;
  color: white;
  letter-spacing: -0.01em;
}

.status-badge-compact {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px;
}

.status-text {
  font-size: 11px;
  font-weight: 700;
  color: #10b981;
}

/* GRID SYSTEM */
.profile-grid-premium {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.forms-grid-desktop-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

/* CARDS COMMON */
.glass-panel-premium {
  background: rgba(15, 23, 42, 0.75);
  border: 1px solid rgba(255, 255, 255, 0.07);
  border-radius: 16px;
  padding: 16px 20px;
  backdrop-filter: blur(10px);
}

/* SUMMARY CARD (ROW 1) */
.profile-summary-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, rgba(250, 204, 21, 0.06) 0%, rgba(15, 23, 42, 0.9) 70%);
  border: 1px solid rgba(250, 204, 21, 0.12);
}

.summary-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.avatar-wrapper-premium {
  position: relative;
  width: 56px;
  height: 56px;
  background: rgba(250, 204, 21, 0.12);
  border: 2px solid rgba(250, 204, 21, 0.25);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.avatar-icon-premium {
  width: 28px;
  height: 28px;
  color: #facc15;
}

.status-dot-premium {
  position: absolute;
  bottom: 2px;
  right: 2px;
  width: 10px;
  height: 10px;
  background: #10b981;
  border: 2px solid #0f172a;
  border-radius: 50%;
}

.user-name-premium {
  font-size: 16px;
  font-weight: 700;
  color: white;
  margin-bottom: 2px;
}

.user-email-premium {
  font-size: 12px;
  color: #94a3b8;
}

.summary-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.role-badges-premium {
  display: flex;
  gap: 8px;
}

.badge-premium {
  font-size: 10px;
  font-weight: 800;
  padding: 4px 10px;
  border-radius: 6px;
  text-transform: uppercase;
}

.badge-premium.admin {
  background: rgba(250, 204, 21, 0.1);
  color: #facc15;
}

.badge-premium.verified {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
}

.login-meta-premium {
  font-size: 11px;
  color: #94a3b8;
  display: flex;
  gap: 6px;
}

.meta-sep { opacity: 0.3; }

/* FORM CARDS (ROW 2) */
.card-header-premium {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.card-header-premium h3 {
  font-size: 13px;
  font-weight: 700;
  color: white;
}

.form-premium {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.label-premium {
  font-size: 10px;
  font-weight: 800;
  color: #64748b;
  text-transform: uppercase;
  margin-bottom: 8px;
  display: block;
}

.input-wrapper-premium {
  position: relative;
}

.i-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  color: #64748b;
  opacity: 0.6;
}

.input-premium {
  width: 100%;
  height: 38px;
  background: rgba(10, 10, 10, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  padding: 0 40px 0 40px;
  color: white;
  font-size: 13px;
  transition: all 0.2s ease;
}

.input-premium:focus {
  border-color: #facc15;
  background: rgba(250, 204, 21, 0.03);
  outline: none;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.i-eye-btn {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: #64748b;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
}

.i-icon-xs {
  width: 13px;
  height: 13px;
}

.i-eye-btn:hover {
  color: white;
}

.strength-meter-compact {
  height: 2px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 2px;
  overflow: hidden;
  margin-top: -12px;
}

.meter-bar {
  height: 100%;
  transition: width 0.3s ease;
}

.actions-premium {
  display: flex;
  justify-content: flex-end;
}

.btn-premium {
  height: 36px;
  padding: 0 24px;
  background: var(--color-primary);
  color: black;
  border: none;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-premium:hover:not(:disabled) {
  transform: translateY(-1px);
  filter: brightness(1.1);
}

.btn-premium:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
}

.pulse { animation: pulse-glow 2s infinite; }

@keyframes pulse-glow {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.5); opacity: 0.5; }
  100% { transform: scale(1); opacity: 1; }
}

.fade-enter-active, .fade-leave-active { transition: opacity 0.3s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

@media (max-width: 1000px) {
  .forms-grid-desktop-container { grid-template-columns: 1fr; }
}
</style>
