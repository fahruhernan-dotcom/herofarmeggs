-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — RLS PERMISSION FIX: PROFILE UPDATES
-- Date: 2026-03-18
-- Focus: Allow users to update their own profile/team record
-- ═══════════════════════════════════════════════════════════════

-- 1. PROFILES TABLE PERMISSIONS
-- Users must be able to update their own row.
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 2. TEAM_MEMBERS TABLE PERMISSIONS
-- Users must be able to update their own record (matching by auth_user_id or email).
-- We also keep the "Admins can manage" policy for full control.
DROP POLICY IF EXISTS "Users can update own team record" ON team_members;
CREATE POLICY "Users can update own team record" ON team_members
  FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid() OR (auth.jwt() ->> 'email') = email)
  WITH CHECK (auth_user_id = auth.uid() OR (auth.jwt() ->> 'email') = email);

-- 3. ENSURE SELECT IS STILL PUBLIC FOR TEAM/PROFILES (So UI can load them)
-- These were added in the previous script but we ensure they exist.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Authenticated users can read profiles') THEN
    CREATE POLICY "Authenticated users can read profiles" ON profiles FOR SELECT TO authenticated USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'team_members' AND policyname = 'Authenticated users can read') THEN
    CREATE POLICY "Authenticated users can read" ON team_members FOR SELECT TO authenticated USING (true);
  END IF;
END $$;
