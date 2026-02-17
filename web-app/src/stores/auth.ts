import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
    const user = ref<User | null>(null)
    const session = ref<Session | null>(null)
    const loading = ref(true)

    async function initialize() {
        loading.value = true
        const { data } = await supabase.auth.getSession()
        session.value = data.session
        user.value = data.session?.user ?? null
        loading.value = false

        supabase.auth.onAuthStateChange((_event, newSession) => {
            session.value = newSession
            user.value = newSession?.user ?? null
        })
    }

    async function signOut() {
        await supabase.auth.signOut()
        user.value = null
        session.value = null
    }

    return { user, session, loading, initialize, signOut }
})
