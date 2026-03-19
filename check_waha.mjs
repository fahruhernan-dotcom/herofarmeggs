import { createClient } from '@supabase/supabase-js'

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL'
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY'
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
