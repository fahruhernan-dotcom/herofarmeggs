<template>
  <div class="waha-terminal">

    <!-- HEADER -->
    <div class="waha-header">
      <div>
        <p class="waha-eyebrow">TACTICAL COMM</p>
        <h1 class="waha-title">WhatsApp Terminal</h1>
        <p class="waha-sub">Secure communication powered by WAHA Engine</p>
      </div>
      <div class="status-badge" :class="'status-' + status">
        <span class="status-dot"></span>
        <span class="status-text">{{ statusLabel }}</span>
      </div>
    </div>

    <!-- CORS ERROR STATE -->
    <div v-if="status === 'CORS_ERROR'" class="error-card">
      <p class="error-icon">🚫</p>
      <h3 class="error-title">Koneksi Diblokir (CORS)</h3>
      <p class="error-sub">
        Browser memblokir koneksi ke WAHA server.<br>
        Tambahkan <code>WHATSAPP_CORS_ORIGIN=*</code> di environment WAHA lalu restart.
      </p>
      <div class="error-code">
        WAHA_BASE = {{ WAHA_BASE }}<br>
        SESSION   = {{ SESSION }}
      </div>
      <button class="btn-retry" @click="checkStatus">🔄 Coba Lagi</button>
    </div>

    <!-- QR CODE STATE -->
    <div v-else-if="status === 'SCAN_QR_CODE'" class="qr-card">
      <p class="qr-title">📱 Scan QR Code</p>
      <div class="qr-frame">
        <img v-if="qrCode" :src="qrCode" class="qr-image" alt="QR Code" />
        <div v-else class="qr-loading">Memuat QR Code...</div>
      </div>
      <p class="qr-sub">Buka WhatsApp → Perangkat Tertaut → Tautkan Perangkat</p>
      <button class="btn-retry" @click="checkStatus">🔄 Refresh QR</button>
    </div>

    <!-- MAIN TERMINAL (when WORKING) -->
    <div v-else-if="status === 'WORKING'" class="terminal-layout">

      <!-- LEFT: Chat List -->
      <div class="chat-sidebar">

        <!-- Search -->
        <div class="search-box">
          <span class="search-icon-el">🔍</span>
          <input
            v-model="searchQuery"
            class="search-input"
            placeholder="Cari kontak..."
          />
        </div>

        <!-- Loading -->
        <div v-if="isLoadingChats" class="chat-loading">
          <div class="spinner"></div>
          <span>Memuat chat...</span>
        </div>

        <!-- Empty -->
        <div v-else-if="filteredChats.length === 0" class="chat-empty">
          <p>👻</p>
          <p>Tidak ada chat ditemukan</p>
        </div>

        <!-- Chat list -->
        <div v-else class="chat-list">
          <div
            v-for="chat in filteredChats"
            :key="chat.id"
            class="chat-item"
            :class="{ active: selectedChat?.id === chat.id }"
            @click="selectChat(chat)"
          >
            <div class="chat-avatar">{{ getChatAvatar(chat) }}</div>
            <div class="chat-info">
              <div class="chat-name-row">
                <span class="chat-name">{{ getChatName(chat) }}</span>
                <span class="chat-time">{{ formatChatTime(chat.lastMessage?.timestamp) }}</span>
              </div>
              <p class="chat-preview">{{ chat.lastMessage?.body ?? '...' }}</p>
            </div>
            <div v-if="chat.unreadCount && chat.unreadCount > 0" class="unread-badge">
              {{ chat.unreadCount }}
            </div>
          </div>
        </div>

        <!-- Engine info -->
        <div class="engine-info">
          <p>&gt; Engine: {{ WAHA_BASE }}</p>
          <p>&gt; Session: {{ SESSION }}</p>
          <p>&gt; Status: {{ status }}</p>
        </div>
        <button class="btn-retry" @click="checkStatus">🔄 Retry Signal</button>
      </div>

      <!-- RIGHT: Message Panel -->
      <div class="message-panel">

        <!-- No chat selected -->
        <div v-if="!selectedChat" class="standby-state">
          <div class="standby-icon">((o))</div>
          <h3 class="standby-title">Signal Hub Standby</h3>
          <p class="standby-sub">Pilih kontak untuk memulai komunikasi.</p>
        </div>

        <!-- Chat open -->
        <template v-else>

          <!-- Chat header -->
          <div class="msg-header">
            <div class="msg-avatar">{{ getChatAvatar(selectedChat) }}</div>
            <div>
              <p class="msg-name">{{ getChatName(selectedChat) }}</p>
              <p class="msg-phone">{{ selectedChat.id?.replace('@c.us','') }}</p>
            </div>
          </div>

          <!-- Messages -->
          <div class="messages-list" ref="msgListRef">
            <div v-if="isLoadingMsgs" class="msg-loading">Memuat pesan...</div>
            <div
              v-else
              v-for="msg in messages"
              :key="msg.id"
              class="msg-bubble"
              :class="msg.fromMe ? 'sent' : 'received'"
            >
              <p class="msg-body">{{ msg.body }}</p>
              <span class="msg-time">{{ formatTime(msg.timestamp) }}</span>
            </div>
          </div>

          <!-- Input -->
          <div class="msg-input-row">
            <input
              v-model="newMessage"
              class="msg-input"
              placeholder="Ketik pesan..."
              @keydown.enter="sendMessage"
            />
            <button class="btn-send" @click="sendMessage" :disabled="!newMessage.trim()">
              ➤
            </button>
          </div>

        </template>
      </div>
    </div>

    <!-- LOADING / STOPPED STATE -->
    <div v-else class="standby-full">
      <div class="standby-icon">((o))</div>
      <p class="standby-sub">{{ status === 'LOADING' ? 'Menghubungkan ke WAHA...' : 'WAHA Session: ' + status }}</p>
      <button class="btn-retry" @click="checkStatus">🔄 Retry</button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue';
import { supabase } from '../lib/supabase';

// ── TYPES ──
interface Chat {
  id: string;
  name?: string;
  unreadCount?: number;
  lastMessage?: { body: string; timestamp: number };
}
interface Message {
  id: string;
  body: string;
  timestamp: number;
  fromMe: boolean;
}

// ── CONFIG (fetched from Supabase, with hardcoded fallback) ──
const WAHA_BASE_DEFAULT = 'http://43.133.137.52:3000';
const SESSION_DEFAULT   = 'default';
const WAHA_KEY_DEFAULT  = 'f84052ca69ad4216a7c784274016b3f0';

const WAHA_BASE = ref(WAHA_BASE_DEFAULT);
const SESSION   = ref(SESSION_DEFAULT);
let   WAHA_KEY  = WAHA_KEY_DEFAULT;

function wahaHeaders() {
  return {
    'Content-Type': 'application/json',
    ...(WAHA_KEY ? { 'X-Api-Key': WAHA_KEY } : {})
  };
}

// ── REACTIVE STATE ──
const status         = ref('LOADING');
const chats          = ref<Chat[]>([]);
const selectedChat   = ref<Chat | null>(null);
const messages       = ref<Message[]>([]);
const newMessage     = ref('');
const searchQuery    = ref('');
const isLoadingChats = ref(false);
const isLoadingMsgs  = ref(false);
const qrCode         = ref<string | null>(null);
const msgListRef     = ref<HTMLElement | null>(null);
let   pollingTimer: ReturnType<typeof setInterval> | null = null;

// ── COMPUTED ──
const filteredChats = computed(() => {
  if (!searchQuery.value) return chats.value;
  const q = searchQuery.value.toLowerCase();
  return chats.value.filter(c =>
    (c.name ?? c.id ?? '').toLowerCase().includes(q)
  );
});

const statusLabel = computed(() => {
  const map: Record<string, string> = {
    LOADING:       'Connecting...',
    WORKING:       'WORKING',
    STOPPED:       'STOPPED',
    FAILED:        'FAILED',
    CORS_ERROR:    'CORS BLOCKED',
    SCAN_QR_CODE:  'SCAN QR',
  };
  return map[status.value] ?? status.value;
});

// ── FETCH CONFIG ──
async function fetchConfig() {
  try {
    const { data } = await supabase.from('waha_config').select('*').limit(1).single();
    if (data) {
      WAHA_BASE.value = data.base_url || WAHA_BASE_DEFAULT;
      SESSION.value   = data.session_name || SESSION_DEFAULT;
      WAHA_KEY        = data.api_key || WAHA_KEY_DEFAULT;
    }
  } catch {
    // Use defaults
  }
}

// ── 1. CHECK SESSION STATUS ──
async function checkStatus() {
  try {
    const res = await fetch(`${WAHA_BASE.value}/api/sessions/${SESSION.value}`, {
      headers: wahaHeaders()
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    status.value = data.status; // 'WORKING' | 'STOPPED' | 'SCAN_QR_CODE' etc.

    if (data.status === 'WORKING') {
      qrCode.value = null;
      await fetchChats();
    } else if (data.status === 'SCAN_QR_CODE') {
      await fetchQR();
    }
  } catch (err: any) {
    console.error('WAHA status error:', err);
    // If it's a network error (CORS or unreachable), show CORS error
    if (err.message === 'Failed to fetch' || err.name === 'TypeError') {
      status.value = 'CORS_ERROR';
    } else {
      status.value = 'FAILED';
    }
  }
}

// ── 2. FETCH QR CODE ──
async function fetchQR() {
  try {
    // Try dedicated QR endpoint first (returns clean QR image)
    const res = await fetch(
      `${WAHA_BASE.value}/api/${SESSION.value}/auth/qr`,
      { headers: wahaHeaders() }
    );
    if (res.ok) {
      const contentType = res.headers.get('content-type') || '';
      if (contentType.includes('image')) {
        const blob = await res.blob();
        qrCode.value = URL.createObjectURL(blob);
      } else {
        // Some WAHA versions return JSON with base64
        const data = await res.json();
        if (data.mimetype && data.data) {
          qrCode.value = `data:${data.mimetype};base64,${data.data}`;
        }
      }
      return;
    }
  } catch { /* fallback below */ }

  // Fallback to screenshot if QR endpoint unavailable
  try {
    const res = await fetch(
      `${WAHA_BASE.value}/api/screenshot?session=${SESSION.value}`,
      { headers: wahaHeaders() }
    );
    if (res.ok) {
      const blob = await res.blob();
      qrCode.value = URL.createObjectURL(blob);
    }
  } catch (err) {
    console.error('QR fetch error:', err);
  }
}

// ── 3. FETCH CHATS ──
async function fetchChats() {
  isLoadingChats.value = true;
  try {
    const res = await fetch(
      `${WAHA_BASE.value}/api/${SESSION.value}/chats?limit=50&offset=0`,
      { headers: wahaHeaders() }
    );
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    chats.value = data ?? [];
  } catch (err) {
    console.error('Chats fetch error:', err);
    chats.value = [];
  } finally {
    isLoadingChats.value = false;
  }
}

// ── 4. FETCH MESSAGES ──
async function fetchMessages(chatId: string) {
  isLoadingMsgs.value = true;
  try {
    const res = await fetch(
      `${WAHA_BASE.value}/api/${SESSION.value}/chats/${encodeURIComponent(chatId)}/messages?limit=30`,
      { headers: wahaHeaders() }
    );
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const rawMessages = data?.messages ?? data ?? [];
    messages.value = rawMessages.reverse().map((m: any) => ({
      id: m.id ?? m._id ?? String(Math.random()),
      body: m.body ?? '',
      timestamp: m.timestamp ?? 0,
      fromMe: m.fromMe ?? m.from_me ?? false
    }));
  } catch (err) {
    console.error('Messages fetch error:', err);
    messages.value = [];
  } finally {
    isLoadingMsgs.value = false;
  }
}

// ── 5. SELECT CHAT ──
async function selectChat(chat: Chat) {
  selectedChat.value = chat;
  await fetchMessages(chat.id);
  await nextTick();
  scrollToBottom();
}

// ── 6. SEND MESSAGE ──
async function sendMessage() {
  const text = newMessage.value.trim();
  if (!text || !selectedChat.value) return;

  const chatId = selectedChat.value.id;
  newMessage.value = '';

  try {
    const res = await fetch(`${WAHA_BASE.value}/api/sendText`, {
      method: 'POST',
      headers: wahaHeaders(),
      body: JSON.stringify({
        session: SESSION.value,
        chatId:  chatId,
        text:    text
      })
    });
    if (!res.ok) throw new Error(`Send failed: ${res.status}`);

    // Optimistic UI
    messages.value.push({
      id:        'out-' + Date.now(),
      body:      text,
      fromMe:    true,
      timestamp: Math.floor(Date.now() / 1000)
    });
    await nextTick();
    scrollToBottom();

    // Refresh from server
    setTimeout(() => fetchMessages(chatId), 1000);
  } catch (err: any) {
    console.error('Send error:', err);
    alert('Gagal kirim pesan: ' + err.message);
    newMessage.value = text;
  }
}

// ── 7. SCROLL ──
function scrollToBottom() {
  if (msgListRef.value) {
    msgListRef.value.scrollTop = msgListRef.value.scrollHeight;
  }
}

// ── 8. POLLING ──
function startPolling() {
  pollingTimer = setInterval(async () => {
    if (selectedChat.value) {
      await fetchMessages(selectedChat.value.id);
    }
    if (status.value === 'WORKING') {
      await fetchChats();
    }
  }, 5000);
}

// ── 9. HELPERS ──
function formatTime(timestamp?: number) {
  if (!timestamp) return '';
  const d = new Date(timestamp * 1000);
  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

function formatChatTime(timestamp?: number) {
  if (!timestamp) return '';
  const d = new Date(timestamp * 1000);
  const now = new Date();
  if (d.toDateString() === now.toDateString()) {
    return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
  }
  return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' });
}

function getChatName(chat: Chat) {
  return chat.name ?? chat.id?.replace('@c.us', '') ?? 'Unknown';
}

function getChatAvatar(chat: Chat) {
  return getChatName(chat).charAt(0).toUpperCase();
}

// ── 10. LIFECYCLE ──
onMounted(async () => {
  await fetchConfig();
  await checkStatus();
  startPolling();
});

onUnmounted(() => {
  if (pollingTimer) clearInterval(pollingTimer);
});
</script>

<style scoped>
.waha-terminal {
  width: 100%;
  height: calc(100vh - 120px);
  display: flex;
  flex-direction: column;
  gap: 0;
}

/* HEADER */
.waha-header {
  display: flex; align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 24px;
}
.waha-eyebrow { font-size: 10px; font-weight: 700; letter-spacing: 2px; color: #f59e0b; text-transform: uppercase; margin: 0 0 6px; }
.waha-title   { font-size: 32px; font-weight: 900; color: white; margin: 0 0 4px; }
.waha-sub     { font-size: 13px; color: rgba(255,255,255,0.40); margin: 0; }

/* STATUS BADGE */
.status-badge {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 16px; border-radius: 20px;
  font-size: 13px; font-weight: 700;
}
.status-badge.status-WORKING    { background: rgba(16,185,129,0.12); border: 1px solid rgba(16,185,129,0.30); color: #10b981; }
.status-badge.status-LOADING    { background: rgba(245,158,11,0.12); border: 1px solid rgba(245,158,11,0.30); color: #f59e0b; }
.status-badge.status-CORS_ERROR { background: rgba(239,68,68,0.12);  border: 1px solid rgba(239,68,68,0.30);  color: #ef4444; }
.status-badge.status-STOPPED    { background: rgba(255,255,255,0.06);border: 1px solid rgba(255,255,255,0.10);color: rgba(255,255,255,0.40); }
.status-badge.status-SCAN_QR_CODE { background: rgba(245,158,11,0.12); border: 1px solid rgba(245,158,11,0.30); color: #f59e0b; }
.status-badge.status-FAILED     { background: rgba(239,68,68,0.12);  border: 1px solid rgba(239,68,68,0.30);  color: #ef4444; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; background: currentColor; }

/* TERMINAL LAYOUT */
.terminal-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 0;
  flex: 1;
  background: #141418;
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  overflow: hidden;
  min-height: 0;
}

/* SIDEBAR */
.chat-sidebar {
  border-right: 1px solid rgba(255,255,255,0.08);
  display: flex; flex-direction: column;
  height: 100%; overflow: hidden;
}

.search-box {
  display: flex; align-items: center; gap: 10px;
  padding: 16px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}
.search-icon-el { font-size: 14px; opacity: 0.4; }
.search-input {
  background: none; border: none; outline: none;
  font-size: 13px; color: white; width: 100%;
}
.search-input::placeholder { color: rgba(255,255,255,0.30); }

.chat-list {
  flex: 1; overflow-y: auto;
}
.chat-list::-webkit-scrollbar { width: 4px; }
.chat-list::-webkit-scrollbar-track { background: transparent; }
.chat-list::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.10); border-radius: 2px; }

.chat-item {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 16px; cursor: pointer;
  border-bottom: 1px solid rgba(255,255,255,0.04);
  transition: background 150ms;
  position: relative;
}
.chat-item:hover  { background: rgba(255,255,255,0.04); }
.chat-item.active { background: rgba(245,158,11,0.08); border-left: 3px solid #f59e0b; }

.chat-avatar {
  width: 40px; height: 40px; border-radius: 50%;
  background: rgba(245,158,11,0.20);
  color: #f59e0b; font-weight: 700; font-size: 16px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.chat-info { flex: 1; min-width: 0; }
.chat-name-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 3px; }
.chat-name    { font-size: 13px; font-weight: 600; color: white; }
.chat-time    { font-size: 10px; color: rgba(255,255,255,0.30); flex-shrink: 0; }
.chat-preview { font-size: 12px; color: rgba(255,255,255,0.35); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin: 0; }
.unread-badge { background: #10b981; color: white; font-size: 10px; font-weight: 700; min-width: 18px; height: 18px; border-radius: 9px; display: flex; align-items: center; justify-content: center; padding: 0 4px; }

.engine-info {
  padding: 12px 16px;
  font-family: 'DM Mono', monospace;
  font-size: 10px;
  color: rgba(255,255,255,0.25);
  border-top: 1px solid rgba(255,255,255,0.06);
  line-height: 1.8;
}
.engine-info p { margin: 0; }

/* MESSAGE PANEL */
.message-panel {
  display: flex; flex-direction: column;
  height: 100%; overflow: hidden;
}

.standby-state, .standby-full {
  flex: 1; display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 12px; text-align: center;
}
.standby-icon { font-size: 60px; color: #f59e0b; opacity: 0.4; font-family: monospace; }
.standby-title { font-size: 18px; font-weight: 700; color: white; margin: 0; }
.standby-sub   { font-size: 13px; color: rgba(255,255,255,0.35); margin: 0; }

.msg-header {
  display: flex; align-items: center; gap: 12px;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
  flex-shrink: 0;
}
.msg-avatar { width: 38px; height: 38px; border-radius: 50%; background: rgba(56,189,248,0.20); color: #38bdf8; font-weight: 700; display: flex; align-items: center; justify-content: center; }
.msg-name   { font-size: 14px; font-weight: 700; color: white; margin: 0 0 2px; }
.msg-phone  { font-size: 11px; color: rgba(255,255,255,0.35); margin: 0; font-family: 'DM Mono', monospace; }

.messages-list {
  flex: 1; overflow-y: auto;
  padding: 20px;
  display: flex; flex-direction: column; gap: 8px;
}
.messages-list::-webkit-scrollbar { width: 4px; }
.messages-list::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.10); border-radius: 2px; }

.msg-bubble {
  max-width: 70%;
  padding: 10px 14px;
  border-radius: 12px;
  display: flex; flex-direction: column; gap: 4px;
}
.msg-bubble.sent     { align-self: flex-end; background: rgba(245,158,11,0.15); border: 1px solid rgba(245,158,11,0.20); }
.msg-bubble.received { align-self: flex-start; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); }
.msg-body { font-size: 13px; color: white; margin: 0; line-height: 1.5; word-break: break-word; }
.msg-time { font-size: 10px; color: rgba(255,255,255,0.30); align-self: flex-end; }

.msg-input-row {
  display: flex; gap: 10px;
  padding: 16px 20px;
  border-top: 1px solid rgba(255,255,255,0.08);
  flex-shrink: 0;
}
.msg-input {
  flex: 1; background: rgba(255,255,255,0.05);
  border: 1px solid rgba(255,255,255,0.10);
  border-radius: 10px; padding: 10px 16px;
  font-size: 13px; color: white; outline: none;
  transition: border-color 150ms;
}
.msg-input:focus { border-color: rgba(245,158,11,0.40); }
.msg-input::placeholder { color: rgba(255,255,255,0.25); }
.btn-send {
  background: #f59e0b; color: #000;
  border: none; border-radius: 10px;
  width: 44px; height: 44px;
  font-size: 16px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: filter 150ms;
  flex-shrink: 0;
}
.btn-send:hover    { filter: brightness(1.10); }
.btn-send:disabled { opacity: 0.4; cursor: not-allowed; }

/* ERROR / QR CARDS */
.error-card, .qr-card {
  background: #141418; border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px; padding: 48px;
  display: flex; flex-direction: column;
  align-items: center; text-align: center; gap: 12px;
}
.error-icon { font-size: 48px; margin: 0; }
.error-title { font-size: 18px; font-weight: 700; color: white; margin: 0; }
.error-sub   { font-size: 13px; color: rgba(255,255,255,0.45); margin: 0; line-height: 1.6; }
.error-sub code { background: rgba(255,255,255,0.08); padding: 2px 6px; border-radius: 4px; color: #f59e0b; font-family: 'DM Mono', monospace; }
.error-code {
  font-family: 'DM Mono', monospace; font-size: 11px;
  color: rgba(255,255,255,0.30); background: rgba(0,0,0,0.30);
  padding: 12px 20px; border-radius: 8px; text-align: left; line-height: 2;
}
.qr-frame {
  padding: 16px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 0 60px rgba(245,158,11,0.15);
}
.qr-image { width: 300px; height: 300px; border-radius: 8px; display: block; }
.qr-title  { font-size: 20px; font-weight: 700; color: white; margin: 0; }
.qr-sub    { font-size: 12px; color: rgba(255,255,255,0.40); margin: 0; }
.qr-loading { color: rgba(255,255,255,0.35); font-size: 13px; }

/* BUTTONS */
.btn-retry {
  background: transparent;
  border: 1px solid rgba(245,158,11,0.35);
  color: #f59e0b; border-radius: 8px;
  padding: 8px 20px; font-size: 12px; font-weight: 600;
  cursor: pointer; transition: background 150ms;
  margin: 8px 16px;
}
.btn-retry:hover { background: rgba(245,158,11,0.08); }

/* MISC */
.chat-loading, .chat-empty, .msg-loading {
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  padding: 40px 20px; gap: 10px;
  font-size: 13px; color: rgba(255,255,255,0.30); text-align: center;
}
.spinner {
  width: 24px; height: 24px; border-radius: 50%;
  border: 2px solid rgba(255,255,255,0.10);
  border-top-color: #f59e0b;
  animation: spin 800ms linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

@media (max-width: 768px) {
  .terminal-layout { grid-template-columns: 1fr; }
  .chat-sidebar { max-height: 300px; }
}
</style>
