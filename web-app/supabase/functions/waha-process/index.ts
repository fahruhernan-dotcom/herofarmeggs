import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

    try {
        const supabase = createClient(
            Deno.env.get("SUPABASE_URL")!,
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
        );

        // 1. Get WAHA Config
        const { data: config, error: configError } = await supabase
            .from('waha_config')
            .select('*')
            .eq('is_active', true)
            .single();

        if (configError || !config) {
            throw new Error("WAHA configuration not found or inactive.");
        }

        // 2. Parse Webhook Payload (from wa_message_log insert)
        const payload = await req.json();
        const messageLog = payload.record;

        if (!messageLog || messageLog.direction !== 'outbound' || messageLog.status !== 'pending') {
            return new Response(JSON.stringify({ skipped: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
        }

        console.log(`Processing outbound message to ${messageLog.phone}...`);

        // 3. Prepare WAHA Request
        const wahaUrl = `${config.base_url}/api/sendText`;
        const wahaBody = {
            chatId: messageLog.phone.includes('@') ? messageLog.phone : `${messageLog.phone}@c.us`,
            text: messageLog.message,
            session: config.session_name || 'default'
        };

        // 4. Call WAHA API
        const response = await fetch(wahaUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Api-Key': config.api_key || ''
            },
            body: JSON.stringify(wahaBody)
        });

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || `WAHA API Error: ${response.statusText}`);
        }

        // 5. Update Log Status
        await supabase
            .from('wa_message_log')
            .update({
                status: 'sent',
                waha_message_id: result.id || null
            })
            .eq('id', messageLog.id);

        return new Response(JSON.stringify({ success: true, waha_id: result.id }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

    } catch (err) {
        console.error("WAHA Process Error:", err.message);

        // Attempt to log failure if possible
        try {
            const payload = await req.json();
            const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
            await supabase
                .from('wa_message_log')
                .update({ status: 'failed', error_message: err.message })
                .eq('id', payload.record.id);
        } catch { }

        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
});
