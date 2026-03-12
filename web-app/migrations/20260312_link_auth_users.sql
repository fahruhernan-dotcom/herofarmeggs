-- 1. Add auth_user_id column to team_members if it doesn't exist
ALTER TABLE team_members 
ADD COLUMN IF NOT EXISTS auth_user_id UUID 
REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. Update existing rows to link auth_user_id based on email
UPDATE team_members tm
SET auth_user_id = au.id
FROM auth.users au
WHERE au.email = tm.email
AND tm.auth_user_id IS NULL;

-- 3. Update RLS on team_members to allow users to read their own data
DROP POLICY IF EXISTS auth_read ON team_members;
CREATE POLICY auth_read ON team_members 
FOR SELECT USING (
  auth.role() = 'authenticated' OR auth_user_id = auth.uid() OR id = auth.uid()
);
