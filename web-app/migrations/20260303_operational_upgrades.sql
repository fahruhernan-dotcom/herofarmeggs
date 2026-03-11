-- Migration: Operational Upgrades 20260303
-- Feature 1: Stock Take, Feature 2: Price History, Feature 3: Price Overrides

-- ━━━ FEATURE 1: STOCK TAKE WORKFLOW ━━━
CREATE TABLE IF NOT EXISTS stock_takes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conducted_at TIMESTAMPTZ DEFAULT NOW(),
  conducted_by TEXT NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','completed')),
  total_discrepancies INTEGER DEFAULT 0,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS stock_take_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_take_id UUID REFERENCES stock_takes(id) ON DELETE CASCADE,
  inventory_id TEXT REFERENCES inventory(id),
  system_qty INTEGER NOT NULL,
  counted_qty INTEGER,
  difference INTEGER,
  adjusted BOOLEAN DEFAULT false
);

-- ━━━ FEATURE 2: PRICE HISTORY ━━━
CREATE TABLE IF NOT EXISTS price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id TEXT REFERENCES inventory(id),
  price_type TEXT NOT NULL CHECK (price_type IN ('selling', 'hpp', 'cost_per_egg', 'packaging')),
  old_price DECIMAL(15,2),
  new_price DECIMAL(15,2),
  changed_by TEXT,
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  reason TEXT
);

-- Trigger to track price changes automatically
CREATE OR REPLACE FUNCTION track_inventory_price_changes()
RETURNS TRIGGER AS $$
DECLARE
  v_changed_by TEXT;
BEGIN
  -- We'll try to get the user from the current session or a special variable if provided
  -- For now, we assume 'System' if not detectable, but we can update it from the frontend
  v_changed_by := COALESCE(current_setting('app.current_user', true), 'System');

  IF NEW.base_price_per_pack IS DISTINCT FROM OLD.base_price_per_pack THEN
    INSERT INTO price_history(inventory_id, price_type, old_price, new_price, changed_by)
    VALUES (NEW.id, 'selling', OLD.base_price_per_pack, NEW.base_price_per_pack, v_changed_by);
  END IF;

  IF NEW.hpp_per_pack IS DISTINCT FROM OLD.hpp_per_pack THEN
    INSERT INTO price_history(inventory_id, price_type, old_price, new_price, changed_by)
    VALUES (NEW.id, 'hpp', OLD.hpp_per_pack, NEW.hpp_per_pack, v_changed_by);
  END IF;

  IF NEW.cost_per_egg IS DISTINCT FROM OLD.cost_per_egg THEN
    INSERT INTO price_history(inventory_id, price_type, old_price, new_price, changed_by)
    VALUES (NEW.id, 'cost_per_egg', OLD.cost_per_egg, NEW.cost_per_egg, v_changed_by);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_track_price_changes ON inventory;
CREATE TRIGGER trg_track_price_changes
AFTER UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION track_inventory_price_changes();

-- ━━━ FEATURE 3: PRICE OVERRIDES ━━━
CREATE TABLE IF NOT EXISTS price_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id),
  inventory_id TEXT REFERENCES inventory(id),
  product_name TEXT,
  original_price DECIMAL(15,2),
  override_price DECIMAL(15,2),
  discount_amount DECIMAL(15,2),
  discount_pct DECIMAL(5,2),
  override_by TEXT,
  override_at TIMESTAMPTZ DEFAULT NOW(),
  reason TEXT
);
