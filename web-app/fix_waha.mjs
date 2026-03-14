import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://cjpqkrlpdvdipbxrrubx.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqcHFrcmxwZHZkaXBieHJydWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyOTk1NzUsImV4cCI6MjA4Njg3NTU3NX0.UzHRPm_oTLPbsbfBogTnV0cEUvTP3AhQe2C5fDZaDd0'
const supabase = createClient(supabaseUrl, supabaseKey)

async function updateConfig() {
  console.log('Attemping to update waha_config...')
  const { data, error } = await supabase
    .from('waha_config')
    .update({ base_url: 'https://herofarm.web.id/waha-api' })
    .match({ session_name: 'default' })
  
  if (error) {
    console.error('Update Error:', error)
  } else {
    console.log('Success! Database updated.')
  }
}

updateConfig()
