-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — RLS PERFORMANCE OPTIMIZATION
-- Date: 2026-03-18
-- Focus: Speed up SELECT queries by removing subqueries from read policies
-- ═══════════════════════════════════════════════════════════════

DO $$ 
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'inventory', 'suppliers', 'customers', 'sales', 'sale_items', 
    'stock_logs', 'finance_entries', 'bank_accounts', 'bank_transactions',
    'notifications', 'scheduled_reports', 'team_members', 'wa_templates', 'waha_config'
  ] LOOP
    -- 1. Ensure RLS is active
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);

    -- 2. Drop existing policies to start fresh
    EXECUTE format('DROP POLICY IF EXISTS "Authenticated users can read" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admins can manage" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admin only for config" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "auth_read" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "admin_all" ON %I', t);

    -- 3. Simple, ultra-fast SELECT policy (No subqueries)
    EXECUTE format('CREATE POLICY "Fast SELECT for authenticated" ON %I FOR SELECT TO authenticated USING (true)', t);

    -- 4. Admin-only DML policies (Write/Delete)
    -- These specific FOR clauses ensure that SELECT operations never evaluate the subquery.
    EXECUTE format('CREATE POLICY "Admin INSERT policy" ON %I FOR INSERT TO authenticated WITH CHECK (
      EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
    )', t);
    EXECUTE format('CREATE POLICY "Admin UPDATE policy" ON %I FOR UPDATE TO authenticated USING (
      EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
    ) WITH CHECK (
      EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
    )', t);
    EXECUTE format('CREATE POLICY "Admin DELETE policy" ON %I FOR DELETE TO authenticated USING (
      EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
    )', t);
  END LOOP;
END $$;
