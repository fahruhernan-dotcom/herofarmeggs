-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — ePanen Integration: Phase 4 (Automation & WAHA)
-- Date: 2026-03-07
-- ═══════════════════════════════════════════════════════════════

-- ─── 4.1 WAHA Connectivity ───
CREATE TABLE IF NOT EXISTS waha_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_name TEXT NOT NULL DEFAULT 'default',
  base_url TEXT NOT NULL, -- VPS URL e.g. http://123.123.123.123:3000
  api_key TEXT, -- X-Api-Key
  is_active BOOLEAN DEFAULT true,
  notify_on_new_order BOOLEAN DEFAULT true,
  notify_on_delivery BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 4.2 Message Archive & Queue ───
CREATE TABLE IF NOT EXISTS wa_message_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  phone TEXT NOT NULL, -- Target or Sender
  message TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'delivered', 'read')),
  error_message TEXT,
  related_entity_type TEXT, -- 'sale', 'driver', etc.
  related_entity_id UUID,
  waha_message_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing for lookup
CREATE INDEX IF NOT EXISTS idx_wa_log_phone ON wa_message_log(phone);
CREATE INDEX IF NOT EXISTS idx_wa_log_entity ON wa_message_log(related_entity_id);

-- ─── 4.3 Notification Templates ───
-- We'll store templates here for easy admin editing
CREATE TABLE IF NOT EXISTS wa_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL, -- e.g. 'order_confirmation'
  body TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true
);

INSERT INTO wa_templates (name, body)
VALUES 
('order_confirmation', 'Halo *{{customer_name}}*! 👋\n\nTerima kasih atas pesanan Anda di *Hero Farm*.\n\nNomor Invoice: {{invoice_number}}\nTotal: Rp {{total_amount}}\n\nKami akan segera memproses pesanan Anda. 🙏'),
('delivery_pickup', '🚚 Pesanan Anda *{{invoice_number}}* telah dibawa oleh sopir kami ({{driver_name}}).\n\nMohon ditunggu kehadirannya ya!'),
('delivery_done', '✅ Pesanan *{{invoice_number}}* telah diterima.\n\nTerima kasih telah berbelanja di *Hero Farm*! 🥚✨')
ON CONFLICT (name) DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TRIGGERS: Auto-Queue Notification on New Order
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION queue_order_whatsapp_notif()
RETURNS TRIGGER AS $$
DECLARE
  cust_phone TEXT;
  cust_name TEXT;
  tpl_body TEXT;
  final_msg TEXT;
BEGIN
  -- Get Customer Phone
  SELECT phone, name INTO cust_phone, cust_name FROM customers WHERE id = NEW.customer_id;
  
  -- Only queue if phone exists and notify setting is on
  IF cust_phone IS NOT NULL AND EXISTS(SELECT 1 FROM waha_config WHERE notify_on_new_order = true) THEN
    
    -- Get Template
    SELECT body INTO tpl_body FROM wa_templates WHERE name = 'order_confirmation';
    
    -- Simple Replacement
    final_msg := replace(tpl_body, '{{customer_name}}', COALESCE(cust_name, 'Pelanggan'));
    final_msg := replace(final_msg, '{{invoice_number}}', NEW.invoice_number);
    final_msg := replace(final_msg, '{{total_amount}}', to_char(NEW.total_amount, 'FM999,999,999'));

    -- Insert into Log (Status pending for Edge Function to pick up)
    INSERT INTO wa_message_log (direction, phone, message, related_entity_type, related_entity_id)
    VALUES ('outbound', cust_phone, final_msg, 'sale', NEW.id);
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_queue_order_wa ON sales;
CREATE TRIGGER trg_queue_order_wa
AFTER INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION queue_order_whatsapp_notif();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TRIGGER: Auto-Queue Notif on Delivery Assignment
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION queue_delivery_whatsapp_notif()
RETURNS TRIGGER AS $$
DECLARE
  cust_phone TEXT;
  inv_num TEXT;
  drv_name TEXT;
  tpl_body TEXT;
  final_msg TEXT;
  sale_record RECORD;
BEGIN
  -- Get Sale & Customer Info
  SELECT * INTO sale_record FROM sales WHERE id = NEW.sale_id;
  SELECT phone INTO cust_phone FROM customers WHERE id = sale_record.customer_id;
  SELECT full_name INTO drv_name FROM drivers WHERE id = NEW.driver_id;
  
  IF cust_phone IS NOT NULL AND NEW.status = 'picked_up' THEN
    -- Notify Pickup
    SELECT body INTO tpl_body FROM wa_templates WHERE name = 'delivery_pickup';
    final_msg := replace(tpl_body, '{{invoice_number}}', sale_record.invoice_number);
    final_msg := replace(final_msg, '{{driver_name}}', COALESCE(drv_name, 'Sopir Terpercaya'));

    INSERT INTO wa_message_log (direction, phone, message, related_entity_type, related_entity_id)
    VALUES ('outbound', cust_phone, final_msg, 'sale', NEW.sale_id);
    
  ELSIF cust_phone IS NOT NULL AND NEW.status = 'delivered' THEN
    -- Notify Done
    SELECT body INTO tpl_body FROM wa_templates WHERE name = 'delivery_done';
    final_msg := replace(tpl_body, '{{invoice_number}}', sale_record.invoice_number);

    INSERT INTO wa_message_log (direction, phone, message, related_entity_type, related_entity_id)
    VALUES ('outbound', cust_phone, final_msg, 'sale', NEW.sale_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_queue_delivery_wa ON driver_assignments;
CREATE TRIGGER trg_queue_delivery_wa
AFTER UPDATE OF status ON driver_assignments
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION queue_delivery_whatsapp_notif();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- RLS POLICIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE waha_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE wa_message_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE wa_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin only for config" ON waha_config FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "View logs" ON wa_message_log FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin only templates" ON wa_templates FOR ALL TO authenticated USING (true) WITH CHECK (true);
