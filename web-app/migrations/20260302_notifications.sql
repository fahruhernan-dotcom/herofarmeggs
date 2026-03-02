-- Migration: Notifications System 20260302
-- Table for in-app notifications with Realtime enabled.

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  link TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger for Stock Levels
CREATE OR REPLACE FUNCTION notify_stock_level()
RETURNS TRIGGER AS $$
BEGIN
  -- Critical Stock (<= 20)
  IF NEW.current_stock <= 20 AND (OLD.current_stock > 20 OR OLD.current_stock IS NULL) THEN
    INSERT INTO notifications (type, title, message, link)
    VALUES ('critical_stock', '🔴 Stok Kritis!', NEW.label || ': ' || NEW.current_stock || ' unit tersisa', '/stock');
  -- Low Stock (21 - 25)
  ELSIF (NEW.current_stock > 20 AND NEW.current_stock <= 25) AND (OLD.current_stock > 25 OR OLD.current_stock IS NULL) THEN
    INSERT INTO notifications (type, title, message, link)
    VALUES ('low_stock', '⚠️ Stok Menipis', NEW.label || ': ' || NEW.current_stock || ' unit', '/stock');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_stock_level ON inventory;
CREATE TRIGGER trg_notify_stock_level
AFTER UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION notify_stock_level();
