<template>
  <div class="whatsapp-terminal">
    <header class="header animate-in">
      <div class="header-left">
        <div class="brand-badge">TACTICAL COMM</div>
        <h1 class="hero-title">WhatsApp Terminal</h1>
        <p class="subtitle">Secure communication portal powered by WAHA Engine</p>
      </div>
      <div class="header-status">
        <div class="connectivity-chip" :class="{ active: waStatus === 'CONNECTED' || waStatus === 'WORKING', warning: waStatus === 'SCAN_QR_CODE' }">
          <div class="indicator-dot"></div>
          <ZapIcon v-if="waStatus === 'CONNECTED' || waStatus === 'WORKING'" class="icon-xs" />
          <GhostIcon v-else-if="waStatus === 'SCAN_QR_CODE'" class="icon-xs" />
          <ZapOffIcon v-else class="icon-xs" />
          <span>{{ waStatus === 'DISCONNECTED' ? 'CHECKING...' : waStatus }}</span>
        </div>
      </div>
    </header>

    <div class="terminal-main-layout animate-in">
      <!-- 📱 SIDEBAR: Conversations -->
      <aside class="sidebar-pnl glass-panel">
        <div class="search-container">
          <div class="search-input-wrap">
            <SearchIcon class="search-icon" />
            <input type="text" v-model="searchQuery" placeholder="Search operatives..." />
          </div>
        </div>
        
        <div class="chats-directory scroll-v">
          <div 
            v-for="chat in filteredChats" 
            :key="chat.id"
            class="chat-tile"
            :class="{ active: selectedChat?.id === chat.id }"
            @click="selectChat(chat)"
          >
            <div class="avatar-hexagon">
              <span class="avatar-text">{{ chat.name?.charAt(0) || '?' }}</span>
            </div>
            <div class="tile-content">
              <div class="tile-top">
                <span class="oper-name">{{ chat.name || chat.id.split('@')[0] }}</span>
                <span class="oper-time">{{ formatTime(chat.lastMessage?.timestamp) }}</span>
              </div>
              <div class="tile-bottom">
                <p class="msg-preview">{{ chat.lastMessage?.body || 'No messages received' }}</p>
                <div v-if="chat.unreadCount" class="unread-count">{{ chat.unreadCount }}</div>
              </div>
            </div>
          </div>
          
        <div v-if="chats.length === 0 && !loading" class="empty-directory">
          <div class="ghost-box">
            <GhostIcon class="icon-md" />
            <p>No active transmissions found.</p>
          </div>
          
          <!-- DEBUG CONSOLE -->
          <div class="debug-console">
            <div class="debug-line">> Engine: {{ wahaConfig.base_url }}</div>
            <div class="debug-line">> Status: {{ waStatus }}</div>
            <div class="debug-line" v-if="debugError" style="color: #ff4d4d">> Error: {{ debugError }}</div>
          </div>

          <button class="btn-ghost-glow mt-12" @click="fetchChats">
            <RefreshCcwIcon class="icon-xs" />
            Retry Signal
          </button>
        </div>
        </div>
      </aside>

      <!-- 🖥️ CHAT OPERATOR: Messages -->
      <main class="message-operator glass-panel">
        <template v-if="selectedChat">
          <div class="operator-header">
            <div class="oper-profile">
              <div class="avatar-hexagon small">
                <span>{{ selectedChat.name?.charAt(0) || '?' }}</span>
              </div>
              <div class="oper-meta">
                <h3>{{ selectedChat.name || selectedChat.id.split('@')[0] }}</h3>
                <span class="phone-id">{{ selectedChat.id }}</span>
              </div>
            </div>
            <div class="header-actions">
               <button class="tool-btn" @click="fetchMessages(selectedChat.id)">
                 <RefreshCwIcon class="icon-xs" />
               </button>
            </div>
          </div>

          <div class="comms-log scroll-v" ref="msgContainer">
            <div 
              v-for="msg in messages" 
              :key="msg.id"
              class="log-bubble"
              :class="msg.fromMe ? 'outbound' : 'inbound'"
            >
              <div class="bubble-body">
                <p>{{ msg.body }}</p>
                <div class="bubble-footer">
                  <span class="ts">{{ formatTime(msg.timestamp) }}</span>
                  <CheckCheckIcon v-if="msg.fromMe" class="icon-tiny" />
                </div>
              </div>
            </div>
            
            <div v-if="messages.length === 0" class="log-empty">
              <div class="terminal-prompt">Waiting for transmission...</div>
            </div>
          </div>

          <div class="input-operator">
            <div class="operator-input-tray glass-panel">
              <input 
                type="text" 
                v-model="newMessage" 
                placeholder="Compose secure message..." 
                @keyup.enter="sendMessage"
                :disabled="sending"
              />
              <button class="btn-fire" @click="sendMessage" :disabled="!newMessage || sending">
                <SendIcon v-if="!sending" class="icon-sm" />
                <div v-else class="loader-xs"></div>
              </button>
            </div>
          </div>
        </template>
        
        <div v-else class="waiting-state">
          <div v-if="waStatus === 'SCAN_QR_CODE'" class="auth-box animate-in">
            <div class="qr-container">
              <img v-if="qrCode" :src="qrCode" alt="Scan QR Code" class="qr-image" />
              <div v-else class="qr-loader">
                <RadioIcon class="pulse-icon" />
              </div>
            </div>
            <h2 class="hero-font">Scan to Authenticate</h2>
            <p class="text-dim">Open WhatsApp on your phone and link this device.</p>
          </div>

          <div v-else-if="waStatus === 'STOPPED' || waStatus === 'OFFLINE'" class="auth-box animate-in">
             <div class="neon-icon">
                <ZapOffIcon class="pulse-icon red" />
             </div>
             <h2 class="hero-font">Terminal Offline</h2>
             <p class="text-dim">Engine is not running or session is stopped.</p>
             <button class="btn-fire mt-24" @click="startSession">
               <ZapIcon class="icon-sm mr-8" />
               START TRANSMISSION
             </button>
          </div>

          <div v-else class="neutral-state animate-in">
            <div class="neon-icon">
              <RadioIcon class="pulse-icon" />
            </div>
            <h2 class="hero-font">Signal Hub Standby</h2>
            <p class="text-dim">Select an operative link to begin tactical communication.</p>
          </div>
          <div class="grid-deco"></div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue';
import { supabase } from '../lib/supabase';
import { 
  SearchIcon, 
  SendIcon, 
  ZapIcon, 
  ZapOffIcon,
  RadioIcon,
  RefreshCcwIcon,
  RefreshCwIcon,
  GhostIcon,
  CheckCheckIcon
} from 'lucide-vue-next';

// --- Types ---
interface Chat {
  id: string;
  name?: string;
  unreadCount?: number;
  lastMessage?: {
    body: string;
    timestamp: number;
  };
}

interface Message {
  id: string;
  body: string;
  timestamp: number;
  fromMe: boolean;
}

// --- State ---
const loading = ref(true);
const sending = ref(false);
const waStatus = ref('DISCONNECTED');
const qrCode = ref(''); // New state for QR code
const chats = ref<Chat[]>([]);
const selectedChat = ref<Chat | null>(null);
const messages = ref<Message[]>([]);
const newMessage = ref('');
const searchQuery = ref('');
const debugError = ref(''); // Added for diagnostics
const msgContainer = ref<HTMLElement | null>(null);

let wahaConfig = {
  base_url: '',
  api_key: '',
  session_name: 'default'
};

let pollInterval: any = null;
let messageSubscription: any = null;

// --- Computed ---
const filteredChats = computed(() => {
  if (!searchQuery.value) return chats.value;
  const q = searchQuery.value.toLowerCase();
  return chats.value.filter(c => 
    (c.name?.toLowerCase().includes(q)) || 
    (c.id.toLowerCase().includes(q))
  );
});

// --- Methods ---
async function fetchConfig() {
  try {
    const { data, error } = await supabase.from('waha_config').select('*').limit(1).single();
    if (error) throw error;
    if (data) {
      wahaConfig = {
        base_url: data.base_url || 'http://localhost:3000',
        api_key: data.api_key || '',
        session_name: data.session_name || 'default'
      };
    }
  } catch (err) {
    console.warn('Using default WAHA config (DB record not found)');
    // Keep defaults
    wahaConfig = {
      base_url: 'http://43.133.137.52:3000', // Hardcoded as safety net
      api_key: 'f84052ca69ad4216a7c784274016b3f0',
      session_name: 'default'
    };
  }
}

// 🛰️ SUPABASE REALTIME BRIDGE
function subscribeToRealtime() {
  if (messageSubscription) return;

  messageSubscription = supabase
    .channel('public:wa_messages')
    .on('postgres_changes', { 
      event: 'INSERT', 
      schema: 'public', 
      table: 'wa_messages' 
    }, (payload) => {
      const msg = payload.new;
      
      const chatIndex = chats.value.findIndex(c => c.id === msg.chat_id);
      if (chatIndex !== -1) {
        const targetChat = chats.value[chatIndex];
        if (targetChat) {
          targetChat.lastMessage = {
            body: msg.body,
            timestamp: msg.timestamp
          };
          chats.value.splice(chatIndex, 1);
          chats.value.unshift(targetChat);
        }
      } else {
        fetchChats();
      }

      if (selectedChat.value && msg.chat_id === selectedChat.value.id) {
        if (!messages.value.find(m => m.id === msg.id)) {
          messages.value.push({
            id: msg.id,
            body: msg.body,
            timestamp: msg.timestamp,
            fromMe: msg.from_me // Fixed mapping from DB snake_case
          });
          scrollToBottom();
        }
      }
    })
    .subscribe();
}

async function checkStatus() {
  try {
    const res = await fetch(`${wahaConfig.base_url}/api/sessions`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    
    if (res.ok) {
      debugError.value = ''; // Clear errors
      const data = await res.json();
      // Find current or first session if default not found
      let session = data.find((s: any) => s.name === wahaConfig.session_name);
      if (!session && data.length > 0) session = data[0]; 

      const newStatus = session?.status || 'OFFLINE';
      
      // AUTO-FETCH logic: Trigger if status is CONNECTED or WORKING
      const isActive = newStatus === 'CONNECTED' || newStatus === 'WORKING';
      if (isActive && (waStatus.value !== newStatus || chats.value.length === 0)) {
        fetchChats();
      }

      waStatus.value = newStatus;
      
      if (waStatus.value === 'SCAN_QR_CODE') {
        fetchQRCode();
      } else {
        qrCode.value = '';
      }
    } else {
      waStatus.value = 'OFFLINE';
      debugError.value = `HTTP Error ${res.status}: ${res.statusText}`;
    }
  } catch (err: any) {
    waStatus.value = 'OFFLINE';
    debugError.value = `Network Error: ${err.message}`;
  }
}

async function startSession() {
  try {
    loading.value = true;
    await fetch(`${wahaConfig.base_url}/api/sessions/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {})
      },
      body: JSON.stringify({ name: wahaConfig.session_name })
    });
    setTimeout(checkStatus, 2000);
  } catch (err) {
    console.error('Failed to start session', err);
  } finally {
    loading.value = false;
  }
}

async function fetchQRCode() {
  try {
    const res = await fetch(`${wahaConfig.base_url}/api/screenshot?session=${wahaConfig.session_name}`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    if (res.ok) {
        const blob = await res.blob();
        qrCode.value = URL.createObjectURL(blob);
    }
  } catch (err) {
    console.error('Failed to fetch QR code', err);
  }
}

async function fetchChats() {
  try {
    const res = await fetch(`${wahaConfig.base_url}/api/chats?session=${wahaConfig.session_name}`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    if (res.ok) {
      chats.value = await res.json();
    }
  } catch (err) {
    console.error('Failed to fetch chats', err);
  } finally {
    loading.value = false;
  }
}

async function fetchMessages(chatId: string) {
  try {
    const res = await fetch(`${wahaConfig.base_url}/api/messages?session=${wahaConfig.session_name}&chatId=${chatId}&limit=50`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    if (res.ok) {
      const data = await res.json();
      messages.value = data.sort((a: any, b: any) => a.timestamp - b.timestamp);
      scrollToBottom();
    }
  } catch (err) {
    console.error('Failed to fetch messages', err);
  }
}

async function selectChat(chat: Chat) {
  selectedChat.value = chat;
  messages.value = [];
  await fetchMessages(chat.id);
}

async function sendMessage() {
  if (!selectedChat.value || !newMessage.value || sending.value) return;
  
  sending.value = true;
  const body = newMessage.value;
  newMessage.value = '';

  try {
    const res = await fetch(`${wahaConfig.base_url}/api/sendText`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {})
      },
      body: JSON.stringify({
        session: wahaConfig.session_name,
        chatId: selectedChat.value.id,
        text: body
      })
    });

    if (res.ok) {
      // Optimistic Update
      messages.value.push({
        id: 'out-' + Date.now(),
        body: body,
        timestamp: Math.floor(Date.now() / 1000),
        fromMe: true
      });
      scrollToBottom();
      setTimeout(fetchChats, 1000);
    }
  } catch (err) {
    alert('Failed to transmit signal.');
  } finally {
    sending.value = false;
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (msgContainer.value) {
      msgContainer.value.scrollTop = msgContainer.value.scrollHeight;
    }
  });
}

function formatTime(ts?: number) {
  if (!ts) return '';
  const date = new Date(ts * 1000);
  return date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
}

onMounted(async () => {
  await fetchConfig();
  await checkStatus();
  
  subscribeToRealtime();

  // Smart polling for status and keeping chats fresh
  pollInterval = setInterval(async () => {
    await checkStatus();
  }, 5000);
});

onUnmounted(() => {
  if (pollInterval) clearInterval(pollInterval);
  if (messageSubscription) supabase.removeChannel(messageSubscription);
});
</script>

<style scoped>
.whatsapp-terminal {
  display: flex;
  flex-direction: column;
  gap: 32px;
  height: calc(100vh - 120px);
  --p-sent: #00ff9d;
  --p-incoming: rgba(255, 255, 255, 0.08);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.brand-badge {
  color: var(--color-primary);
  letter-spacing: 0.3em;
  font-size: 0.7rem;
  font-weight: 900;
  margin-bottom: 8px;
  text-shadow: 0 0 10px rgba(255, 140, 0, 0.3);
}

.hero-title { font-size: 2.5rem; font-weight: 900; line-height: 1.1; margin-bottom: 4px; }
.subtitle { color: var(--color-text-dim); font-size: 0.95rem; }

.connectivity-chip {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.1em;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

.indicator-dot { width: 8px; height: 8px; border-radius: 50%; background: #ff4d4d; box-shadow: 0 0 10px #ff4d4d; }
.connectivity-chip.active { background: rgba(0, 255, 157, 0.05); border-color: rgba(0, 255, 157, 0.2); color: #00ff9d; }
.connectivity-chip.active .indicator-dot { background: #00ff9d; box-shadow: 0 0 15px #00ff9d; }
.connectivity-chip.warning { background: rgba(255, 140, 0, 0.05); border-color: rgba(255, 140, 0, 0.2); color: #ff8c00; }
.connectivity-chip.warning .indicator-dot { background: #ff8c00; box-shadow: 0 0 15px #ff8c00; }

.terminal-main-layout {
  flex: 1;
  display: flex;
  gap: 20px;
  min-height: 0;
}

/* SIDEBAR */
.sidebar-pnl {
  width: 380px;
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.3) !important;
  backdrop-filter: blur(20px) !important;
}

.search-container { padding: 24px; }
.search-input-wrap {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 20px;
  background: rgba(255, 255, 255, 0.04);
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}
.search-input-wrap input { background: transparent; border: none; color: white; width: 100%; font-size: 0.9rem; }
.search-input-wrap input:focus { outline: none; }
.search-icon { color: var(--color-text-dim); }

.chats-directory { flex: 1; display: flex; flex-direction: column; overflow-y: auto; padding: 0 12px 24px; }

.chat-tile {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 18px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.19, 1, 0.22, 1);
  margin-bottom: 4px;
}

.chat-tile:hover { background: rgba(255, 255, 255, 0.03); transform: translateX(4px); }
.chat-tile.active { background: rgba(255, 140, 0, 0.08); border-right: 4px solid var(--color-primary); }

.avatar-hexagon {
  width: 52px; height: 52px;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, #222, #000);
  border: 1px solid rgba(255, 255, 255, 0.08);
  clip-path: polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);
  color: var(--color-primary); font-weight: 800; font-size: 1.2rem;
}

.avatar-hexagon.small { width: 44px; height: 44px; font-size: 1rem; }

.tile-content { flex: 1; min-width: 0; }
.tile-top { display: flex; justify-content: space-between; margin-bottom: 6px; }
.oper-name { font-weight: 700; color: white; font-size: 1rem; }
.oper-time { font-size: 0.7rem; color: var(--color-text-dim); font-family: var(--font-mono); }

.tile-bottom { display: flex; justify-content: space-between; align-items: center; }
.msg-preview { font-size: 0.85rem; color: var(--color-text-dim); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; opacity: 0.8; }

/* CHAT OPERATOR */
.message-operator {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.2) !important;
}

.operator-header {
  padding: 24px 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  display: flex; justify-content: space-between; align-items: center;
  background: rgba(0, 0, 0, 0.2);
}

.oper-profile { display: flex; align-items: center; gap: 20px; }
.oper-meta h3 { font-size: 1.2rem; margin-bottom: 2px; }
.phone-id { font-size: 0.7rem; color: var(--color-text-dim); font-family: var(--font-mono); letter-spacing: 0.05em; }

.comms-log {
  flex: 1;
  overflow-y: auto;
  padding: 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: radial-gradient(circle at center, rgba(255, 140, 0, 0.02), transparent);
}

.log-bubble { max-width: 65%; display: flex; }
.log-bubble.outbound { align-self: flex-end; }
.log-bubble.inbound { align-self: flex-start; }

.bubble-body {
  padding: 14px 20px;
  border-radius: 20px;
  font-size: 1rem;
  line-height: 1.5;
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.outbound .bubble-body { 
  background: linear-gradient(135deg, var(--color-primary), #ff4d00); 
  color: black; 
  border-bottom-right-radius: 4px;
  font-weight: 600;
}
.inbound .bubble-body { 
  background: var(--p-incoming); 
  color: white; 
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-bottom-left-radius: 4px;
}

.bubble-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 6px;
  margin-top: 6px;
  font-size: 0.65rem;
  opacity: 0.6;
}

.input-operator { padding: 32px; }
.operator-input-tray {
  display: flex;
  padding: 8px 12px;
  border-radius: 100px;
  background: rgba(255, 255, 255, 0.04) !important;
  align-items: center;
  transition: all 0.3s;
  border-color: rgba(255, 255, 255, 0.08) !important;
}

.operator-input-tray:focus-within { border-color: var(--color-primary) !important; background: rgba(255, 255, 255, 0.06) !important; }

.operator-input-tray input {
  flex: 1;
  background: transparent;
  border: none;
  color: white;
  padding: 12px 24px;
  font-size: 1rem;
}
.operator-input-tray input:focus { outline: none; }

.btn-fire {
  width: 44px; height: 44px;
  border-radius: 50%;
  background: var(--color-primary);
  border: none;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.btn-fire:hover:not(:disabled) { transform: rotate(-10deg) scale(1.15); box-shadow: 0 0 20px rgba(255, 140, 0, 0.4); }
.btn-fire:disabled { opacity: 0.3; cursor: not-allowed; }

.waiting-sta.empty-directory { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px 20px; text-align: center; }
.ghost-box { opacity: 0.3; margin-bottom: 24px; }

.debug-console {
  width: 100%;
  background: rgba(0, 0, 0, 0.4);
  border-radius: 12px;
  padding: 12px;
  margin: 16px 0;
  font-family: var(--font-mono);
  font-size: 0.7rem;
  text-align: left;
  border: 1px solid rgba(255, 255, 255, 0.05);
}
.debug-line { color: #666; margin-bottom: 4px; overflow-wrap: break-word; }

.waiting-state {
  flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center;
  text-align: center; gap: 24px; position: relative;
}

.auth-box {
  display: flex; flex-direction: column; align-items: center; gap: 20px;
  z-index: 10;
}

.qr-container {
  padding: 12px; background: white; border-radius: 20px;
  box-shadow: 0 0 40px rgba(0, 255, 157, 0.2);
}

.qr-image { width: 260px; height: 260px; border-radius: 12px; }
.qr-loader { width: 260px; height: 260px; display: flex; align-items: center; justify-content: center; }

.neon-icon {
  width: 140px; height: 140px;
  border-radius: 50%;
  background: rgba(255, 140, 0, 0.03);
  display: flex; align-items: center; justify-content: center;
  border: 1px solid rgba(255, 140, 0, 0.1);
  box-shadow: inset 0 0 30px rgba(255, 140, 0, 0.05);
}

.pulse-icon { width: 56px; height: 56px; color: var(--color-primary); animation: glow-pulse 3s infinite; }

.tool-btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: var(--color-text-dim);
  padding: 10px; border-radius: 12px;
  cursor: pointer; transition: all 0.3s;
}
.tool-btn:hover { background: rgba(255, 255, 255, 0.1); color: white; }

.animate-in { animation: slide-up 0.6s cubic-bezier(0.16, 1, 0.3, 1); }

@keyframes slide-up {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes glow-pulse {
  0% { transform: scale(1); opacity: 0.6; }
  50% { transform: scale(1.1); opacity: 1; filter: drop-shadow(0 0 10px var(--color-primary)); }
  100% { transform: scale(1); opacity: 0.6; }
}

.scroll-v { scrollbar-width: thin; scrollbar-color: rgba(255, 255, 255, 0.1) transparent; }
.scroll-v::-webkit-scrollbar { width: 6px; }
.scroll-v::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }

@media (max-width: 1200px) {
  .sidebar-pnl { width: 300px; }
}
</style>
