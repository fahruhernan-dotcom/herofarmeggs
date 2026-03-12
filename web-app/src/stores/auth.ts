import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '../lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
    const user = ref<User | null>(null)
    const session = ref<Session | null>(null)
    const profile = ref<any | null>(null)
    const loading = ref(true)
    const skipAuthChange = ref(false)

    async function fetchProfile(userObj: User) {
        // First try to get team_member record using email (which is unique)
        const { data: memberData } = await supabase
            .from('team_members')
            .select('role, position, full_name, is_active:status')
            .eq('email', userObj.email)
            .single()

        if (memberData) {
            // Normalize status to is_active boolean for compatibility
            profile.value = {
                ...memberData,
                is_active: memberData.is_active === 'active'
            }
        } else {
            // Fallback to legacy profiles if team_member not found
            const { data: legacyData } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', userObj.id)
                .single()
            if (legacyData) profile.value = legacyData
        }
    }

    async function initialize() {
        loading.value = true
        const { data } = await supabase.auth.getSession()
        session.value = data.session
        user.value = data.session?.user ?? null

        if (user.value) {
            await fetchProfile(user.value)
        }

        loading.value = false

        supabase.auth.onAuthStateChange(async (_event, newSession) => {
            // Skip auth state changes during staff registration
            if (skipAuthChange.value) return;

            session.value = newSession
            user.value = newSession?.user ?? null
            if (user.value) {
                await fetchProfile(user.value)
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

    return { user, session, profile, loading, initialize, signOut, isAdmin, fetchProfile, skipAuthChange }
})

