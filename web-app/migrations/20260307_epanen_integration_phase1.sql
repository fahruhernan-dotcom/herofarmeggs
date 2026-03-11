-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — ePanen Integration: Phase 1 & 2
-- Date: 2026-03-07
-- Source: Adapted from ePanen (panendigital) reference codebase
-- Safe to re-run (IF NOT EXISTS / CREATE OR REPLACE)
-- ═══════════════════════════════════════════════════════════════

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PHASE 1: QUICK WINS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── 1.1 Activities / Audit Trail ───
-- Tracks all important actions: status changes, CRUD operations, logins
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL DEFAULT 'order',
    -- 'order', 'inventory', 'customer', 'supplier', 'employee', 'finance', 'system'
  entity_id UUID,
  action TEXT NOT NULL,
    -- 'created', 'updated', 'deleted', 'status_changed', 'login', 'logout', 'voided'
  details JSONB DEFAULT '{}',
    -- Flexible JSON: { "from": "pending", "to": "paid", "field": "status" }
  actor_name TEXT,
    -- Name of the user who performed the action
  actor_id UUID,
    -- auth.uid() of the actor (nullable for system actions)
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast queries by entity
CREATE INDEX IF NOT EXISTS idx_activities_entity
  ON activities(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activities_created
  ON activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_action
  ON activities(action);

-- ─── 1.2 Company Settings ───
-- Single-row table for business profile configuration
CREATE TABLE IF NOT EXISTS company_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL DEFAULT 'Hero Farm',
  brand_name TEXT NOT NULL DEFAULT 'Hero Farm Eggs',
  tagline TEXT DEFAULT 'Telur Bebek Premium',
  address TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  npwp TEXT DEFAULT '',
  -- Bank info for invoices
  bank_name TEXT DEFAULT '',
  bank_account TEXT DEFAULT '',
  bank_holder TEXT DEFAULT '',
  -- Operational
  operating_hours TEXT DEFAULT 'Senin-Sabtu 08:00-17:00',
  delivery_area TEXT DEFAULT '',
  -- Branding
  logo_url TEXT,
  primary_color TEXT NOT NULL DEFAULT '#16a34a',
  accent_color TEXT NOT NULL DEFAULT '#22c55e',
  -- Meta
  updated_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default company settings (only if empty)
INSERT INTO company_settings (company_name, brand_name, tagline)
SELECT 'Hero Farm', 'Hero Farm Eggs', 'Telur Bebek Premium'
WHERE NOT EXISTS (SELECT 1 FROM company_settings);

-- ─── 1.3 Tax Settings ───
-- Configurable tax rate (PPN) for invoices
CREATE TABLE IF NOT EXISTS tax_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate DECIMAL(5,2) NOT NULL DEFAULT 0,
    -- PPN rate in %, e.g. 11 for 11%
  description TEXT DEFAULT 'PPN',
  is_active BOOLEAN DEFAULT true,
  updated_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tax rate change history
CREATE TABLE IF NOT EXISTS tax_rate_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  old_rate DECIMAL(5,2) NOT NULL,
  new_rate DECIMAL(5,2) NOT NULL,
  notes TEXT,
  changed_by UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default tax setting (0% = no tax)
INSERT INTO tax_settings (rate, description)
SELECT 0, 'PPN'
WHERE NOT EXISTS (SELECT 1 FROM tax_settings);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PHASE 2: EMPLOYEE ENHANCEMENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── 2.1 Staff Positions ───
CREATE TABLE IF NOT EXISTS staff_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed common positions for egg farm
INSERT INTO staff_positions (name, sort_order)
SELECT * FROM (VALUES
  ('Pemilik', 1),
  ('Manajer', 2),
  ('Operator Sortir', 3),
  ('Petugas Kandang', 4),
  ('Driver Pengiriman', 5),
  ('Admin Keuangan', 6),
  ('Sales', 7)
) AS v(name, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM staff_positions);

-- ─── 2.2 Staff Contracts ───
CREATE TABLE IF NOT EXISTS staff_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL,
    -- References employees in your existing employee management
  contract_type TEXT NOT NULL DEFAULT 'permanent'
    CHECK (contract_type IN ('permanent', 'contract', 'freelance', 'probation')),
  contract_number TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  document_url TEXT,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 2.3 Staff Allowances ───
CREATE TABLE IF NOT EXISTS staff_allowances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL,
  name TEXT NOT NULL,
    -- 'Transport', 'Makan', 'Komunikasi', 'Lembur', etc.
  amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── 2.4 Payroll Records ───
CREATE TABLE IF NOT EXISTS payroll_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL,
  employee_name TEXT NOT NULL,
  period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
  period_year INTEGER NOT NULL CHECK (period_year >= 2024),
  -- Compensation breakdown
  base_salary DECIMAL(15,2) NOT NULL DEFAULT 0,
  bonus DECIMAL(15,2) NOT NULL DEFAULT 0,
  bonus_note TEXT,
  deductions DECIMAL(15,2) NOT NULL DEFAULT 0,
  deduction_note TEXT,
  allowances JSONB DEFAULT '[]'::JSONB,
    -- Array of { "name": "Transport", "amount": 50000 }
  total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  -- Status
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'approved', 'paid', 'cancelled')),
  notes TEXT,
  slip_url TEXT,
  -- Payment tracking
  paid_at TIMESTAMPTZ,
  paid_by UUID,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Prevent duplicate payroll for same employee/period
  UNIQUE (employee_id, period_month, period_year)
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── Auto-log sale activities ───
CREATE OR REPLACE FUNCTION log_sale_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO activities (entity_type, entity_id, action, details)
    VALUES ('order', NEW.id, 'created',
      jsonb_build_object(
        'invoice_number', NEW.invoice_number,
        'customer_name', COALESCE(NEW.customer_name, ''),
        'total', COALESCE(NEW.total_revenue, NEW.total_price, 0)
      ));
  ELSIF TG_OP = 'UPDATE' AND OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
    INSERT INTO activities (entity_type, entity_id, action, details)
    VALUES ('order', NEW.id, 'status_changed',
      jsonb_build_object(
        'from', OLD.payment_status,
        'to', NEW.payment_status,
        'invoice_number', NEW.invoice_number
      ));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_sale_activity ON sales;
CREATE TRIGGER trg_log_sale_activity
AFTER INSERT OR UPDATE ON sales
FOR EACH ROW
EXECUTE FUNCTION log_sale_activity();

-- ─── Auto-log inventory changes ───
CREATE OR REPLACE FUNCTION log_inventory_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.current_stock IS DISTINCT FROM NEW.current_stock THEN
    INSERT INTO activities (entity_type, entity_id, action, details)
    VALUES ('inventory', NULL, 'stock_changed',
      jsonb_build_object(
        'inventory_id', NEW.id,
        'grade', COALESCE(NEW.grade, NEW.id),
        'from', OLD.current_stock,
        'to', NEW.current_stock,
        'diff', NEW.current_stock - OLD.current_stock
      ));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_inventory_activity ON inventory;
CREATE TRIGGER trg_log_inventory_activity
AFTER UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION log_inventory_activity();

-- ─── Auto-track tax rate changes ───
CREATE OR REPLACE FUNCTION track_tax_rate_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.rate IS DISTINCT FROM NEW.rate THEN
    INSERT INTO tax_rate_history (old_rate, new_rate, changed_by)
    VALUES (OLD.rate, NEW.rate, NEW.updated_by);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_track_tax_rate ON tax_settings;
CREATE TRIGGER trg_track_tax_rate
AFTER UPDATE ON tax_settings
FOR EACH ROW
EXECUTE FUNCTION track_tax_rate_change();

-- ─── Auto-update updated_at ───
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_company_settings_updated ON company_settings;
CREATE TRIGGER trg_company_settings_updated
BEFORE UPDATE ON company_settings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_tax_settings_updated ON tax_settings;
CREATE TRIGGER trg_tax_settings_updated
BEFORE UPDATE ON tax_settings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROW LEVEL SECURITY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rate_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_allowances ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_records ENABLE ROW LEVEL SECURITY;

-- Allow all access for authenticated users (matching existing Herofarm pattern)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'activities', 'company_settings', 'tax_settings', 'tax_rate_history',
    'staff_positions', 'staff_contracts', 'staff_allowances', 'payroll_records'
  ] LOOP
    EXECUTE format(
      'CREATE POLICY IF NOT EXISTS "Allow all for authenticated" ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t
    );
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
