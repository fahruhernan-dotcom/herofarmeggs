-- ─────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM MIGRATION
-- ─────────────────────────────────────────────────────────

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  severity    TEXT DEFAULT 'info' CHECK (severity IN ('info','success','warning','danger')),
  entity_type TEXT,        -- 'sale', 'purchase', 'piutang', 'utang', 'stock', 'grading'
  entity_id   UUID,        -- FK to related record
  is_read     BOOLEAN DEFAULT false,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now(),
  created_by  TEXT DEFAULT 'system'
);

-- REPAIR BLOCK: Add missing columns if table existed in broken state
DO $$ 
BEGIN 
  -- Add severity
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='severity') THEN
    ALTER TABLE notifications ADD COLUMN severity TEXT DEFAULT 'info' CHECK (severity IN ('info','success','warning','danger'));
  END IF;
  
  -- Add entity_type
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='entity_type') THEN
    ALTER TABLE notifications ADD COLUMN entity_type TEXT;
  END IF;

  -- Add entity_id
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='entity_id') THEN
    ALTER TABLE notifications ADD COLUMN entity_id UUID;
  END IF;
END $$;

-- Indices
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for authenticated" ON notifications;
CREATE POLICY "Allow all for authenticated" ON notifications
  FOR ALL USING (true) WITH CHECK (true);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ─────────────────────────────────────────
-- TRIGGER 1: Low stock alerts
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_low_stock()
RETURNS TRIGGER AS $$
DECLARE
  grade_label TEXT;
  max_packs INT;
BEGIN
  IF NEW.current_stock >= OLD.current_stock THEN
    RETURN NEW;
  END IF;

  grade_label := CASE NEW.id
    WHEN 'hero'   THEN 'Hero'
    WHEN 'salted_egg' THEN 'Salted Egg'
    ELSE NEW.label
  END;

  max_packs := FLOOR(NEW.current_stock / 10);

  IF NEW.current_stock <= 0 THEN
    INSERT INTO notifications (type, title, message, severity, entity_type, entity_id)
    VALUES (
      'stock_empty',
      '🚨 Stok ' || grade_label || ' HABIS',
      'Stok telur ' || grade_label || ' mencapai 0 butir. Segera lakukan pembelian.',
      'danger',
      'inventory',
      NULL -- inventory IDs are TEXT, entity_id is UUID. Keep as NULL or handle if needed.
    );
  ELSIF NEW.current_stock <= COALESCE(NEW.safety_stock, 20) THEN
    INSERT INTO notifications (type, title, message, severity, entity_type, entity_id)
    VALUES (
      'stock_low',
      '⚠️ Stok ' || grade_label || ' Menipis',
      'Sisa ' || NEW.current_stock || ' butir (' || max_packs || ' pack). Di bawah safety stock.',
      'warning',
      'inventory',
      NULL
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_low_stock ON inventory;
CREATE TRIGGER trigger_low_stock
  AFTER UPDATE OF current_stock ON inventory
  FOR EACH ROW EXECUTE FUNCTION notify_low_stock();

-- ─────────────────────────────────────────
-- TRIGGER 2: New Sale
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_new_sale()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (type, title, message, severity, entity_type, entity_id, created_by)
  VALUES (
    'new_sale',
    '💰 Penjualan Baru: ' || NEW.invoice_number,
    'Order ke ' || COALESCE(NEW.customer_name, 'Walk-in') ||
    ' senilai Rp ' || TO_CHAR(NEW.total_revenue, 'FM999,999,999') ||
    CASE WHEN NEW.payment_type = 'piutang' THEN ' (TEMPO)' ELSE ' (TUNAI)' END,
    CASE WHEN NEW.payment_type = 'piutang' THEN 'warning' ELSE 'success' END,
    'sale',
    NEW.id,
    NEW.created_by
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_new_sale ON sales;
CREATE TRIGGER trigger_new_sale
  AFTER INSERT ON sales
  FOR EACH ROW EXECUTE FUNCTION notify_new_sale();

-- ─────────────────────────────────────────
-- TRIGGER 3: New Purchase
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_new_purchase()
RETURNS TRIGGER AS $$
DECLARE
  supplier_name TEXT;
BEGIN
  SELECT name INTO supplier_name FROM suppliers WHERE id = NEW.supplier_id;

  IF NEW.remaining_debt > 0 THEN
    INSERT INTO notifications (type, title, message, severity, entity_type, entity_id)
    VALUES (
      'new_utang',
      '📦 Pembelian Baru + Utang',
      'Beli ' || NEW.total_eggs_bought || ' butir dari ' || COALESCE(supplier_name, 'Supplier') ||
      '. Utang: Rp ' || TO_CHAR(NEW.remaining_debt, 'FM999,999,999'),
      'warning',
      'purchase',
      NEW.id
    );
  ELSE
    INSERT INTO notifications (type, title, message, severity, entity_type, entity_id)
    VALUES (
      'new_purchase',
      '📦 Pembelian Baru (LUNAS)',
      'Beli ' || NEW.total_eggs_bought || ' butir dari ' || COALESCE(supplier_name, 'Supplier') ||
      ' senilai Rp ' || TO_CHAR(NEW.total_cost, 'FM999,999,999'),
      'success',
      'purchase',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_new_purchase ON purchases;
CREATE TRIGGER trigger_new_purchase
  AFTER INSERT ON purchases
  FOR EACH ROW EXECUTE FUNCTION notify_new_purchase();

-- ─────────────────────────────────────────
-- Trigger 4: Grading Complete
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_grading_complete()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (type, title, message, severity, entity_type, entity_id)
  VALUES (
    'grading_complete',
    '✅ Grading Selesai',
    'Total: ' || (COALESCE(NEW.hero_qty,0) + COALESCE(NEW.salted_egg_qty,0)) || ' butir tergrading.',
    'success',
    'grading',
    NEW.id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_grading_complete ON gradings;
CREATE TRIGGER trigger_grading_complete
  AFTER INSERT ON gradings
  FOR EACH ROW EXECUTE FUNCTION notify_grading_complete();

-- ─────────────────────────────────────────
-- RPC Functions
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION mark_notification_read(notif_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true, read_at = now()
  WHERE id = notif_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true, read_at = now()
  WHERE is_read = false;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────
-- TEST SEED DATA
-- ─────────────────────────────────────────
INSERT INTO notifications (type, title, message, severity, entity_type, is_read) VALUES
  ('stock_low',        '⚠️ Stok Hero Menipis',        'Sisa 15 butir. Di bawah safety stock.',               'warning', 'inventory', false),
  ('new_sale',         '💰 Penjualan Baru: INV-TEST',  'Order ke Walk-in senilai Rp 75.000 (TUNAI)',           'success', 'sale',      false);
