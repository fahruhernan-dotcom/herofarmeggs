-- Function to register new staff from Admin Dashboard without logging out the admin
-- Requirements:
-- 1. Must be SECURITY DEFINER to bypass the restriction that users can't create other users
-- 2. Should only be callable by admins

CREATE OR REPLACE FUNCTION public.register_new_staff(
    new_email TEXT,
    new_password TEXT,
    new_full_name TEXT,
    new_role TEXT DEFAULT 'staff'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    new_user_id UUID;
    result JSONB;
BEGIN
    -- 1. Check if caller is admin
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Only administrators can register new staff.';
    END IF;

    -- 2. Create the user in auth.users
    new_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        created_at,
        updated_at
    )
    VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        new_email,
        crypt(new_password, gen_salt('bf')),
        now(),
        jsonb_build_object('provider', 'email', 'providers', array['email']),
        jsonb_build_object('full_name', new_full_name),
        false,
        'authenticated',
        'authenticated',
        '',
        '',
        '',
        '',
        now(),
        now()
    );

    -- 3. Create identities record (required for some Supabase features)
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at,
        provider_id
    )
    VALUES (
        gen_random_uuid(),
        new_user_id,
        jsonb_build_object('sub', new_user_id, 'email', new_email),
        'email',
        now(),
        now(),
        now(),
        new_email -- Use email as provider_id for email provider
    );

    -- 4. The profile will be created automatically by the trigger 'on_auth_user_created'
    -- but we need to update the role and full_name correctly since the trigger might use defaults
    UPDATE public.profiles
    SET 
        full_name = new_full_name,
        role = new_role,
        is_active = true
    WHERE id = new_user_id;

    result := jsonb_build_object(
        'success', true,
        'user_id', new_user_id,
        'message', 'Staff registered successfully'
    );

    RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', SQLERRM
    );
END;
$$;
