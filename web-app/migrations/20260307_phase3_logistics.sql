-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — ePanen Integration: Phase 3 (Logistics & Geo)
-- Date: 2026-03-07
-- Source: Adapted from ePanen (panendigital) reference codebase
-- Safe to re-run (IF NOT EXISTS / CREATE OR REPLACE)
-- ═══════════════════════════════════════════════════════════════

-- ─── 3.1 Drivers Management ───
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    -- Links to a user account if they have portal access
  full_name TEXT NOT NULL,
  phone TEXT,
  license_number TEXT, -- SIM
  vehicle_info TEXT, -- Plate Number, Type
  emergency_contact TEXT,
  base_commission DECIMAL(15,2) DEFAULT 0, -- Per trip or per egg
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3.2 Delivery Zones ───
-- Defines areas for distance-based shipping or sorting
CREATE TABLE IF NOT EXISTS delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, -- e.g. "Ring 1 (Sidoarjo)", "Malang Raya"
  base_fee DECIMAL(15,2) DEFAULT 0,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default zones
INSERT INTO delivery_zones (name, base_fee, sort_order)
SELECT * FROM (VALUES
  ('Local Delivery (Radius < 5km)', 0, 1),
  ('Outer Ring (5 - 15km)', 15000, 2),
  ('Suburban (15 - 30km)', 35000, 3),
  ('Out of Province', 100000, 4)
) AS v(name, base_fee, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM delivery_zones);

-- ─── 3.3 Driver Assignments ───
-- Links orders to specific drivers and tracks delivery status
CREATE TABLE IF NOT EXISTS driver_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'assigned'
    CHECK (status IN ('assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'returned')),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  picked_up_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failed_reason TEXT,
  proof_of_delivery_url TEXT, -- URL to photo in Supabase Storage
  notes TEXT,
  commission_earned DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 3.4 Driver Earnings / Wallet ───
-- Tracks summary of commissions for drivers
CREATE TABLE IF NOT EXISTS driver_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  period_month INTEGER NOT NULL,
  period_year INTEGER NOT NULL,
  total_deliveries INTEGER DEFAULT 0,
  total_commission DECIMAL(15,2) DEFAULT 0,
  status TEXT DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid')),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (driver_id, period_month, period_year)
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER FUNCTIONS & TRIGGERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── Auto-log Driver Assignments in Activities ───
CREATE OR REPLACE FUNCTION log_driver_assignment_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO activities (entity_type, entity_id, action, details)
  VALUES ('system', NEW.sale_id, 'driver_assigned',
    jsonb_build_object(
      'driver_id', NEW.driver_id,
      'status', NEW.status,
      'assignment_id', NEW.id
    ));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_driver_assignment ON driver_assignments;
CREATE TRIGGER trg_log_driver_assignment
AFTER INSERT ON driver_assignments
FOR EACH ROW
EXECUTE FUNCTION log_driver_assignment_activity();

-- ─── Auto-update Delivery Status in Sales ───
-- We might need a column in sales to track this if it doesn't exist
ALTER TABLE sales ADD COLUMN IF NOT EXISTS delivery_status TEXT DEFAULT 'pending';

CREATE OR REPLACE FUNCTION sync_delivery_status_to_sale()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE sales
  SET delivery_status = NEW.status
  WHERE id = NEW.sale_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_delivery_status ON driver_assignments;
CREATE TRIGGER trg_sync_delivery_status
AFTER INSERT OR UPDATE ON driver_assignments
FOR EACH ROW
EXECUTE FUNCTION sync_delivery_status_to_sale();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROW LEVEL SECURITY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_earnings ENABLE ROW LEVEL SECURITY;

-- Allow all access for authenticated users (Herofarm pattern)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'drivers', 'delivery_zones', 'driver_assignments', 'driver_earnings'
  ] LOOP
    EXECUTE format(
      'CREATE POLICY IF NOT EXISTS "Allow all for authenticated" ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t
    );
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
