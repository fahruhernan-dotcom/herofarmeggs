import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuthStore } from './auth'

export interface Notification {
    id: string
    type: string
    title: string
    message: string
    severity: 'info' | 'success' | 'warning' | 'danger'
    entity_type: string | null
    entity_id: string | null
    is_read: boolean
    read_at: string | null
    created_at: string
    created_by: string
}

export const useNotificationStore = defineStore('notifications', () => {

    const notifications = ref<Notification[]>([])
    const isLoading = ref(false)
    let realtimeChannel: any = null

    // ── Computed ──────────────────────────────
    const unreadCount = computed(() =>
        notifications.value.filter(n => !n.is_read).length
    )

    const unreadNotifications = computed(() =>
        notifications.value.filter(n => !n.is_read)
            .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    )

    const allNotifications = computed(() =>
        [...notifications.value].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    )

    // ── Severity → styling map ─────────────────
    const severityConfig: Record<string, any> = {
        success: {
            bg: 'rgba(16,185,129,0.08)',
            border: 'rgba(16,185,129,0.20)',
            icon: '✅',
            dot: '#10b981'
        },
        warning: {
            bg: 'rgba(245,158,11,0.08)',
            border: 'rgba(245,158,11,0.20)',
            icon: '⚠️',
            dot: '#f59e0b'
        },
        danger: {
            bg: 'rgba(239,68,68,0.08)',
            border: 'rgba(239,68,68,0.20)',
            icon: '🔴',
            dot: '#ef4444'
        },
        info: {
            bg: 'rgba(56,189,248,0.08)',
            border: 'rgba(56,189,248,0.20)',
            icon: 'ℹ️',
            dot: '#38bdf8'
        }
    }

    function getSeverityConfig(severity: string) {
        return severityConfig[severity] ?? severityConfig.info
    }

    // ── Fetch ──────────────────────────────────
    async function fetchNotifications(limit = 50) {
        isLoading.value = true
        try {
            const { data, error } = await supabase
                .from('notifications')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(limit)

            if (error) throw error
            notifications.value = data ?? []
        } catch (err) {
            console.error('fetchNotifications error:', err)
        } finally {
            isLoading.value = false
        }
    }

    // ── Mark single as read ────────────────────
    async function markAsRead(notifId: string) {
        const notif = notifications.value.find(n => n.id === notifId)
        if (notif && !notif.is_read) {
            // Optimistic update
            notif.is_read = true
            notif.read_at = new Date().toISOString()

            try {
                await supabase.rpc('mark_notification_read', { notif_id: notifId })
            } catch (err) {
                console.error('markAsRead error:', err)
                notif.is_read = false
            }
        }
    }

    // ── Mark all as read ───────────────────────
    async function markAllAsRead() {
        notifications.value.forEach(n => {
            n.is_read = true
            n.read_at = new Date().toISOString()
        })

        try {
            await supabase.rpc('mark_all_notifications_read')
        } catch (err) {
            console.error('markAllAsRead error:', err)
            await fetchNotifications()
        }
    }

    // ── Supabase Realtime ──────────────────────
    function subscribeRealtime() {
        if (realtimeChannel) return

        realtimeChannel = supabase
            .channel('notifications-realtime')
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'notifications'
                },
                (payload: any) => {
                    notifications.value.unshift(payload.new)
                    showBrowserNotification(payload.new)
                }
            )
            .on(
                'postgres_changes',
                {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'notifications'
                },
                (payload: any) => {
                    const index = notifications.value.findIndex(n => n.id === payload.new.id)
                    if (index !== -1) {
                        notifications.value[index] = payload.new
                    }
                }
            )
            .subscribe()
    }

    function unsubscribeRealtime() {
        if (realtimeChannel) {
            supabase.removeChannel(realtimeChannel)
            realtimeChannel = null
        }
    }

    // ── Browser notification ───────────────────
    async function requestBrowserPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            await Notification.requestPermission()
        }
    }

    function showBrowserNotification(notif: Notification) {
        if (
            'Notification' in window &&
            Notification.permission === 'granted' &&
            document.hidden
        ) {
            new Notification(notif.title, {
                body: notif.message,
                icon: '/favicon.ico'
            })
        }
    }

    // ── Watch Auth state ──────────────────────
    // Auto-fetch if user session changes
    const authStore = useAuthStore()
    watch(() => authStore.session, (newSession) => {
        if (newSession) {
            fetchNotifications()
            subscribeRealtime()
        } else {
            notifications.value = []
            unsubscribeRealtime()
        }
    }, { immediate: true })

    // ── Init ───────────────────────────────────
    async function init() {
        if (authStore.session) {
            await fetchNotifications()
            subscribeRealtime()
        }
        requestBrowserPermission()
    }

    return {
        notifications,
        unreadCount,
        unreadNotifications,
        allNotifications,
        isLoading,
        getSeverityConfig,
        fetchNotifications,
        markAsRead,
        markAllAsRead,
        subscribeRealtime,
        unsubscribeRealtime,
        init
    }
})
