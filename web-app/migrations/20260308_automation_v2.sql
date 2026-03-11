-- ─── 4.4 Automation Enhancements (n8n & WAHA v2) ───

-- Add missing columns to waha_config
ALTER TABLE waha_config 
ADD COLUMN IF NOT EXISTS n8n_webhook_url TEXT,
ADD COLUMN IF NOT EXISTS automation_server_ip TEXT,
ADD COLUMN IF NOT EXISTS local_supabase_url TEXT,
ADD COLUMN IF NOT EXISTS local_supabase_key TEXT;

-- Ensure we have at least one config row
INSERT INTO waha_config (base_url, session_name)
SELECT 'http://localhost:3000', 'default'
WHERE NOT EXISTS (SELECT 1 FROM waha_config);

-- Update RLS for newly added columns (already handled by BROAD policy but reinforcing)
COMMENT ON COLUMN waha_config.n8n_webhook_url IS 'The n8n entry point for automation workflows.';
COMMENT ON COLUMN waha_config.local_supabase_url IS 'URL for the local/automation Supabase instance.';

-- ─── 4.5 Activity Log Integration ───

-- Trigger to log WA messages to the main activities table
CREATE OR REPLACE FUNCTION log_whatsapp_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.direction = 'outbound' THEN
    INSERT INTO activities (entity_type, entity_id, action, details, actor_name)
    VALUES (
      'system', 
      NEW.id, 
      'whatsapp_queued', 
      jsonb_build_object(
        'phone', NEW.phone,
        'status', NEW.status,
        'preview', CASE WHEN length(NEW.message) > 50 THEN left(NEW.message, 47) || '...' ELSE NEW.message END
      ),
      'Automation Engine'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_wa_activity ON wa_message_log;
CREATE TRIGGER trg_log_wa_activity
AFTER INSERT ON wa_message_log
FOR EACH ROW
EXECUTE FUNCTION log_whatsapp_activity();
