import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL'
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY'
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
