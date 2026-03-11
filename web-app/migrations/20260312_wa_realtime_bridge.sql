-- 1. Create wa_messages table to store history and enable realtime
CREATE TABLE IF NOT EXISTS public.wa_messages (
    id TEXT PRIMARY KEY, -- Using WAHA/WA message ID
    chat_id TEXT NOT NULL,
    session_name TEXT DEFAULT 'default',
    body TEXT,
    from_me BOOLEAN DEFAULT false,
    timestamp BIGINT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable Realtime for this table
ALTER publication supabase_realtime ADD TABLE wa_messages;

-- 3. Policy: Allow authenticated users to read and n8n/admin to write
ALTER TABLE wa_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read messages" ON wa_messages;
CREATE POLICY "Anyone can read messages" ON wa_messages 
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Service role can manage messages" ON wa_messages;
CREATE POLICY "Service role can manage messages" ON wa_messages 
FOR ALL TO service_role USING (true);
