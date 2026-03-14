import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://cjpqkrlpdvdipbxrrubx.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqcHFrcmxwZHZkaXBieHJydWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyOTk1NzUsImV4cCI6MjA4Njg3NTU3NX0.UzHRPm_oTLPbsbfBogTnV0cEUvTP3AhQe2C5fDZaDd0'
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
      api_key: 'f84052ca69ad4216a7c784274016b3f0'
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
