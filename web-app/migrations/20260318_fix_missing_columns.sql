-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — SCHEMA FIX: MISSING COLUMNS
-- Date: 2026-03-18
-- Addresses: Missing created_by in notifications and sales tables
-- ═══════════════════════════════════════════════════════════════

-- 1. FIX NOTIFICATIONS TABLE
-- The trigger notify_new_sale() attempts to insert into this column.
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS created_by TEXT DEFAULT 'system';

-- 2. FIX SALES TABLE
-- The trigger notify_new_sale() references NEW.created_by, so this column must exist.
ALTER TABLE sales ADD COLUMN IF NOT EXISTS created_by TEXT DEFAULT 'system';

-- 3. ENSURE RLS IS STILL ACTIVE ON NEW COLUMNS (Already handled by previous migration, but safe to keep)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
