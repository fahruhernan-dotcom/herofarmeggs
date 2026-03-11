<template>
  <div class="whatsapp-terminal">
    <header class="header">
      <div class="header-left">
        <h4 class="brand-tag">TACTICAL COMM</h4>
        <h1 class="hero-font">WhatsApp Terminal</h1>
        <p class="text-dim">Direct communication link via WAHA Engine.</p>
      </div>
      <div class="header-status">
        <div v-if="loading" class="loading-spinner"></div>
        <div v-else class="status-indicator" :class="{ connected: waStatus === 'CONNECTED' }">
          <ZapIcon class="icon-xs" />
          <span>{{ waStatus }}</span>
        </div>
      </div>
    </header>

    <div class="terminal-container glass-panel">
      <!-- SIDEBAR: CHAT LIST -->
      <aside class="chat-list-sidebar">
        <div class="search-box">
          <SearchIcon class="icon-xs" />
          <input type="text" v-model="searchQuery" placeholder="Search chats..." />
        </div>
        
        <div class="chats-scroller">
          <div 
            v-for="chat in filteredChats" 
            :key="chat.id"
            class="chat-item"
            :class="{ active: selectedChat?.id === chat.id }"
            @click="selectChat(chat)"
          >
            <div class="chat-avatar">
              {{ chat.name?.charAt(0) || '?' }}
            </div>
            <div class="chat-info">
              <div class="chat-name-row">
                <span class="chat-name">{{ chat.name || chat.id.split('@')[0] }}</span>
                <span class="chat-time">{{ formatTime(chat.lastMessage?.timestamp) }}</span>
              </div>
              <p class="chat-preview">{{ chat.lastMessage?.body || 'No messages' }}</p>
            </div>
          </div>
          
          <div v-if="chats.length === 0 && !loading" class="empty-chats">
            <p>No active chats found.</p>
            <button class="btn-primary-mini" @click="fetchChats">Refresh</button>
          </div>
        </div>
      </aside>

      <!-- MAIN AREA: MESSAGES -->
      <main class="chat-window">
        <template v-if="selectedChat">
          <div class="chat-header">
            <div class="chat-header-info">
              <h3>{{ selectedChat.name || selectedChat.id.split('@')[0] }}</h3>
              <p class="chat-status">{{ selectedChat.id }}</p>
            </div>
          </div>

          <div class="messages-scroller" ref="msgContainer">
            <div 
              v-for="msg in messages" 
              :key="msg.id"
              class="message-bubble"
              :class="msg.fromMe ? 'sent' : 'received'"
            >
              <div class="message-content">
                <p>{{ msg.body }}</p>
                <span class="message-time">{{ formatTime(msg.timestamp) }}</span>
              </div>
            </div>
            <div v-if="messages.length === 0" class="empty-messages">
              Start a conversation...
            </div>
          </div>

          <div class="message-input-area">
            <input 
              type="text" 
              v-model="newMessage" 
              placeholder="Type a message..." 
              @keyup.enter="sendMessage"
              :disabled="sending"
            />
            <button class="btn-send" @click="sendMessage" :disabled="!newMessage || sending">
              <SendIcon v-if="!sending" class="icon-sm" />
              <div v-else class="spinner-xs"></div>
            </button>
          </div>
        </template>
        
        <div v-else class="no-chat-selected">
          <div class="placeholder-icon">
            <MessageSquareIcon />
          </div>
          <h2>Tactical Messaging Hub</h2>
          <p>Select a contact from the sidebar to start communicating.</p>
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
  MessageSquareIcon 
} from 'lucide-vue-next';

// --- Types ---
interface Chat {
  id: string;
  name?: string;
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
const chats = ref<Chat[]>([]);
const selectedChat = ref<Chat | null>(null);
const messages = ref<Message[]>([]);
const newMessage = ref('');
const searchQuery = ref('');
const msgContainer = ref<HTMLElement | null>(null);

let wahaConfig = {
  base_url: '',
  api_key: '',
  session_name: 'default'
};

let pollInterval: any = null;

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
  const { data } = await supabase.from('waha_config').select('*').limit(1).single();
  if (data) {
    wahaConfig = {
      base_url: data.base_url || 'http://localhost:3000',
      api_key: data.api_key || '',
      session_name: data.session_name || 'default'
    };
  }
}

async function checkStatus() {
  try {
    const res = await fetch(`${wahaConfig.base_url}/api/sessions`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    if (res.ok) {
      const data = await res.json();
      const session = data.find((s: any) => s.name === wahaConfig.session_name);
      waStatus.value = session?.status || 'UNKNOWN';
    } else {
      waStatus.value = 'OFFLINE';
    }
  } catch (err) {
    waStatus.value = 'OFFLINE';
  }
}

async function fetchChats() {
  if (waStatus.value !== 'CONNECTED') return;
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
    const res = await fetch(`${wahaConfig.base_url}/api/messages?session=${wahaConfig.session_name}&chatId=${chatId}&limit=20`, {
      headers: wahaConfig.api_key ? { 'X-Api-Key': wahaConfig.api_key } : {}
    });
    if (res.ok) {
      messages.value = await res.json();
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
      // Add message locally for instant feedback
      messages.value.push({
        id: Date.now().toString(),
        body: body,
        timestamp: Math.floor(Date.now() / 1000),
        fromMe: true
      });
      scrollToBottom();
    } else {
      alert('Failed to send message.');
    }
  } catch (err) {
    alert('Network error sending message.');
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
  if (waStatus.value === 'CONNECTED') {
    await fetchChats();
  } else {
    loading.value = false;
  }

  // Poll for status and new messages
  pollInterval = setInterval(async () => {
    await checkStatus();
    if (selectedChat.value) {
      await fetchMessages(selectedChat.value.id);
    }
  }, 5000);
});

onUnmounted(() => {
  if (pollInterval) clearInterval(pollInterval);
});
</script>

<style scoped>
.whatsapp-terminal {
  display: flex;
  flex-direction: column;
  gap: 24px;
  height: calc(100vh - 120px);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.05);
  font-size: 0.75rem;
  font-weight: 800;
  color: var(--color-text-dim);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.status-indicator.connected {
  color: #00ff9d;
  background: rgba(0, 255, 157, 0.1);
  border-color: rgba(0, 255, 157, 0.2);
}

.terminal-container {
  flex: 1;
  display: flex;
  overflow: hidden;
  border-radius: 24px;
  background: rgba(10, 10, 10, 0.4);
}

/* SIDEBAR */
.chat-list-sidebar {
  width: 320px;
  border-right: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  flex-direction: column;
}

.search-box {
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(0, 0, 0, 0.2);
}

.search-box input {
  background: transparent;
  border: none;
  color: white;
  font-size: 0.9rem;
  width: 100%;
}

.search-box input:focus { outline: none; }

.chats-scroller {
  flex: 1;
  overflow-y: auto;
}

.chat-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  cursor: pointer;
  transition: all 0.2s;
  border-bottom: 1px solid rgba(255, 255, 255, 0.02);
}

.chat-item:hover { background: rgba(255, 255, 255, 0.03); }
.chat-item.active { background: rgba(255, 140, 0, 0.05); border-left: 3px solid var(--color-primary); }

.chat-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #333, #111);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  color: var(--color-primary);
  flex-shrink: 0;
}

.chat-info {
  flex: 1;
  min-width: 0;
}

.chat-name-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 4px;
}

.chat-name { font-weight: 700; color: white; font-size: 0.95rem; }
.chat-time { font-size: 0.7rem; color: var(--color-text-dim); }

.chat-preview {
  font-size: 0.8rem;
  color: var(--color-text-dim);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* MAIN CHAT WINDOW */
.chat-window {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.2);
}

.chat-header {
  padding: 16px 24px;
  background: rgba(0, 0, 0, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.chat-header h3 { font-size: 1.1rem; color: white; }
.chat-status { font-size: 0.75rem; color: var(--color-text-dim); }

.messages-scroller {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message-bubble {
  max-width: 70%;
  padding: 10px 16px;
  border-radius: 12px;
  position: relative;
}

.message-bubble.sent {
  align-self: flex-end;
  background: var(--color-primary);
  color: black;
  border-bottom-right-radius: 2px;
}

.message-bubble.received {
  align-self: flex-start;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border-bottom-left-radius: 2px;
}

.message-content p { margin: 0; font-size: 0.9rem; line-height: 1.4; }
.message-time { 
  display: block; 
  text-align: right; 
  font-size: 0.65rem; 
  opacity: 0.6; 
  margin-top: 4px; 
}

.message-input-area {
  padding: 20px;
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  gap: 12px;
  align-items: center;
}

.message-input-area input {
  flex: 1;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 12px 20px;
  border-radius: 100px;
  color: white;
  font-size: 0.9rem;
}

.message-input-area input:focus { outline: none; border-color: var(--color-primary); }

.btn-send {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--color-primary);
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-send:hover:not(:disabled) { transform: scale(1.1); filter: brightness(1.2); }
.btn-send:disabled { opacity: 0.5; cursor: not-allowed; }

.no-chat-selected {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: var(--color-text-dim);
  gap: 16px;
}

.placeholder-icon {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background: rgba(255, 140, 0, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-primary);
}

.placeholder-icon svg { width: 48px; height: 48px; }

.loading-spinner {
  width: 24px;
  height: 24px;
  border: 3px solid rgba(255, 255, 255, 0.1);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.spinner-xs {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(0, 0, 0, 0.2);
  border-top-color: black;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }
</style>
