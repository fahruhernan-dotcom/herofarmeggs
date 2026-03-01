import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
    const user = ref<User | null>(null)
    const session = ref<Session | null>(null)
    const profile = ref<any | null>(null)
    const loading = ref(true)

    async function fetchProfile(userId: string) {
        const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single()

        if (data) {
            profile.value = data
        }
    }

    async function initialize() {
        loading.value = true
        const { data } = await supabase.auth.getSession()
        session.value = data.session
        user.value = data.session?.user ?? null

        if (user.value) {
            await fetchProfile(user.value.id)
        }

        loading.value = false

        supabase.auth.onAuthStateChange(async (_event, newSession) => {
            session.value = newSession
            user.value = newSession?.user ?? null
            if (user.value) {
                await fetchProfile(user.value.id)
            } else {
                profile.value = null
            }
        })
    }

    async function signOut() {
        await supabase.auth.signOut()
        user.value = null
        session.value = null
        profile.value = null
    }

    const isAdmin = computed(() => {
        // Super Admin hardcode
        if (user.value?.email === 'fahruhernansakti@gmail.com') return true;
        return profile.value?.role === 'admin';
    });

    return { user, session, profile, loading, initialize, signOut, isAdmin, fetchProfile }
})
