-- NEW REGISTER STAFF RPC (as requested)
-- NOTE: This version inserts into 'team_members' table.
-- If this table does not exist, you must create it first.

CREATE OR REPLACE FUNCTION register_new_staff(
  p_full_name    TEXT,
  p_email        TEXT,
  p_phone        TEXT,
  p_position     TEXT,
  p_role         TEXT DEFAULT 'staff'
)
RETURNS JSON AS $$
DECLARE
  new_id UUID := gen_random_uuid();
BEGIN
  -- We assume team_members table exists with columns: id, full_name, email, phone, position, role, status, created_at
  INSERT INTO team_members (id, full_name, email, phone, position, role, status, created_at)
  VALUES (new_id, p_full_name, p_email, p_phone, p_position, p_role, 'active', now());
  
  RETURN json_build_object('success', true, 'id', new_id);
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
