import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://cjpqkrlpdvdipbxrrubx.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqcHFrcmxwZHZkaXBieHJydWJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyOTk1NzUsImV4cCI6MjA4Njg3NTU3NX0.UzHRPm_oTLPbsbfBogTnV0cEUvTP3AhQe2C5fDZaDd0'
const supabase = createClient(supabaseUrl, supabaseKey)

async function checkConfig() {
  const { data, error } = await supabase.from('waha_config').select('*')
  if (error) {
    console.error('Error fetching waha_config:', error)
  } else {
    console.log('Current waha_config:', JSON.stringify(data, null, 2))
  }
}

checkConfig()
