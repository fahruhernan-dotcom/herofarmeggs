
import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
dotenv.config({ path: path.resolve(__dirname, '../web-app/.env.local') })

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing Supabase credentials')
    process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function debug() {
    const { data: inventory } = await supabase.from('inventory').select('*').limit(1)
    console.log('--- Inventory Sample ---')
    console.log(inventory?.[0])

    const { data: finance } = await supabase.from('finance_entries').select('*').limit(5)
    console.log('\n--- Finance Entries Sample ---')
    console.log(finance)

    const { data: sales } = await supabase.from('sales').select('*, sale_items(*)').limit(1)
    console.log('\n--- Sales Sample ---')
    console.log(sales?.[0])
}

debug()
