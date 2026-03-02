import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '../lib/supabase';

export interface Notification {
    id: string;
    type: 'low_stock' | 'critical_stock' | 'sale_created' | 'sale_paid' | 'sale_voided' | 'restock_done' | 'system_alert';
    title: string;
    message: string | null;
    link: string | null;
    is_read: boolean;
    created_at: string;
}

export const useNotificationStore = defineStore('notifications', () => {
    const notifications = ref<Notification[]>([]);
    const latestCriticalToast = ref<Notification | null>(null);

    const unreadCount = computed(() => notifications.value.filter(n => !n.is_read).length);

    async function fetchNotifications() {
        const { data, error } = await supabase
            .from('notifications')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(50);

        if (!error && data) {
            notifications.value = data as Notification[];
        }
    }

    async function markAllRead() {
        const { error } = await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('is_read', false);

        if (!error) {
            notifications.value = notifications.value.map(n => ({ ...n, is_read: true }));
        }
    }

    async function markOneRead(id: string) {
        const { error } = await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('id', id);

        if (!error) {
            const n = notifications.value.find(n => n.id === id);
            if (n) n.is_read = true;
        }
    }

    function subscribeRealtime() {
        supabase.channel('notifications-channel')
            .on('postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'notifications' },
                (payload) => {
                    const newNotif = payload.new as Notification;
                    notifications.value.unshift(newNotif);

                    if (newNotif.type === 'critical_stock') {
                        latestCriticalToast.value = newNotif;
                    }
                }
            )
            .subscribe();
    }

    function dismissToast() {
        latestCriticalToast.value = null;
    }

    return {
        notifications,
        unreadCount,
        latestCriticalToast,
        fetchNotifications,
        markAllRead,
        markOneRead,
        subscribeRealtime,
        dismissToast
    };
});
