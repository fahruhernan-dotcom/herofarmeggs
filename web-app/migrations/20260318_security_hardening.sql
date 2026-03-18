-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — SECURITY HARDENING MIGRATION
-- Date: 2026-03-18
-- Addresses: RLS Disabled, Mutable Search Paths, Permissive Policies
-- ═══════════════════════════════════════════════════════════════

-- 1. ENABLE ROW LEVEL SECURITY ON CORE TABLES
-- ─────────────────────────────────────────
DO $$ 
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'inventory', 'suppliers', 'employees', 'wa_bot_drafts', 'customers', 
    'finance_entries', 'stock_takes', 'stock_take_items', 'sale_items', 
    'sales', 'stock_logs'
  ] LOOP
    EXECUTE format('ALTER TABLE IF EXISTS %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- 2. REFIX PERMISSIVE POLICIES (Allow All for Authenticated -> Admin Only for DML)
-- ─────────────────────────────────────────
-- We define a helper to drop and recreate policies with proper admin checks
DO $$ 
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'bank_accounts', 'bank_transactions', 'notifications', 
    'scheduled_reports', 'team_members', 'wa_templates', 'waha_config'
  ] LOOP
    -- Drop the permissive policy if it exists (including extra ones caught by linter)
    EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admin only for config" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admin only templates" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Allow all access to bank_accounts" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Allow all access to bank_transactions" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Akses Admin Waha" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Allow all for admin" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Authenticated users can read" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admins can manage" ON %I', t);

    -- Create Select for Authenticated
    EXECUTE format('CREATE POLICY "Authenticated users can read" ON %I FOR SELECT TO authenticated USING (true)', t);
    
    -- Create Admin Only for All (DML)
    EXECUTE format('CREATE POLICY "Admins can manage" ON %I FOR ALL TO authenticated USING (
      EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = ''admin''
      )
    )', t);
  END LOOP;
END $$;

-- 3. HARDEN ALL RPC FUNCTIONS (Set search_path for ALL public functions)
-- ─────────────────────────────────────────
-- This prevents search_path injection attacks by forcing "public" for all functions.
-- We iterate through all functions in the public schema to ensure complete coverage.
DO $$ 
DECLARE
  func_record RECORD;
BEGIN
  FOR func_record IN 
    SELECT n.nspname as schema_name, p.proname as function_name, pg_get_function_identity_arguments(p.oid) as identity_arguments
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
  LOOP
    BEGIN
      EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public', 
                     func_record.schema_name, func_record.function_name, func_record.identity_arguments);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Could not alter function %.%: %', func_record.schema_name, func_record.function_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- Also handle any specific common tables that had policies but RLS disabled
ALTER TABLE IF EXISTS public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.suppliers ENABLE ROW LEVEL SECURITY;

-- Default Policies for Core Tables if they didn't have any
DO $$ 
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'inventory', 'suppliers', 'customers', 'sales', 'sale_items', 'stock_logs', 'finance_entries'
  ] LOOP
    -- Ensure we drop before recreate to avoid "already exists" errors
    EXECUTE format('DROP POLICY IF EXISTS "Authenticated users can read" ON %I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Admins can manage" ON %I', t);

    EXECUTE format('CREATE POLICY "Authenticated users can read" ON %I FOR SELECT TO authenticated USING (true)', t);
    EXECUTE format('CREATE POLICY "Admins can manage" ON %I FOR ALL TO authenticated USING (
      EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = ''admin''
      )
    )', t);
  END LOOP;
END $$;
