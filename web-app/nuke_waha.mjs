import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'

dotenv.config()

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL'
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY'
const supabase = createClient(supabaseUrl, supabaseKey)

async function nukebase() {
  console.log('--- Database Cleanup ---')
  
  // 1. Delete everything
  const { error: delErr } = await supabase
    .from('waha_config')
    .delete()
    .neq('session_name', 'bogus_entry_to_match_all')
  
  if (delErr) {
    console.error('Delete failed:', delErr)
  } else {
    console.log('1. All old configs DELETED.')
  }

  // 2. Insert the correct one
  const { error: insErr } = await supabase
    .from('waha_config')
    .insert([{
      session_name: 'default',
      base_url: 'https://herofarm.web.id/waha-api',
      api_key: process.env.WAHA_API_KEY || 'YOUR_WAHA_API_KEY'
    }])

  if (insErr) {
    console.error('Insert failed:', insErr)
  } else {
    console.log('2. New HTTPS config INSERTED.')
  }

  console.log('--- Done ---')
  process.exit()
}

nukebase()
