-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — SECURITY & STABILITY POLISH
-- Date: 2026-03-18
-- Focus: Fix search_path, missing columns, and RLS refinement
-- ═══════════════════════════════════════════════════════════════

-- 1. SEARCH PATH REFINEMENT
-- Hardening search_path to just 'public' can break extensions (gen_random_uuid) or auth helpers.
-- We broaden it to include 'extensions' and 'auth' while still blocking injection.
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
      EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public, extensions, auth', 
                     func_record.schema_name, func_record.function_name, func_record.identity_arguments);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Could not alter function %.%: %', func_record.schema_name, func_record.function_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- 2. NOTIFICATIONS & SALES COLUMN REPAIR (Final check)
-- Ensuring created_by exists and is correctly type-cast
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='created_by') THEN
    ALTER TABLE notifications ADD COLUMN created_by TEXT DEFAULT 'system';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='sales' AND column_name='created_by') THEN
    ALTER TABLE sales ADD COLUMN created_by TEXT DEFAULT 'system';
  END IF;
END $$;

-- 3. TEAM MEMBERS RLS REFINEMENT
-- Ensure RLS is enabled and policies are robust
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Drop and Recreate for absolute certainty
DROP POLICY IF EXISTS "Authenticated users can read" ON team_members;
DROP POLICY IF EXISTS "Admins can manage" ON team_members;
DROP POLICY IF EXISTS auth_read ON team_members;
DROP POLICY IF EXISTS admin_all ON team_members;

CREATE POLICY "Authenticated users can read" ON team_members 
  FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Admins can manage" ON team_members 
  FOR ALL TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 4. PROFILES RLS (Often overlooked but crucial for the EXISTS check above)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can read profiles" ON profiles;

CREATE POLICY "Authenticated users can read profiles" ON profiles
  FOR SELECT TO authenticated
  USING (true);

-- 5. STAFF POSITIONS (Needed for Employees.vue)
ALTER TABLE staff_positions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can read positions" ON staff_positions;
CREATE POLICY "Authenticated users can read positions" ON staff_positions
  FOR SELECT TO authenticated
  USING (true);
