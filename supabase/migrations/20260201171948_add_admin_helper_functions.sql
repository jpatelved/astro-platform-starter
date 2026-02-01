/*
  # Admin Helper Functions

  1. New Functions
    - `promote_user_to_admin(user_email text)` - Promotes a user to admin role
    - `demote_admin_to_user(user_email text)` - Demotes an admin to user role
    - `list_all_users()` - Lists all users with their roles (admin only)

  2. Security
    - These functions can only be called by existing admins
    - Functions are SECURITY DEFINER to allow role updates
*/

CREATE OR REPLACE FUNCTION promote_user_to_admin(user_email text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  calling_user_role text;
  affected_rows int;
BEGIN
  SELECT role INTO calling_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF calling_user_role != 'admin' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Only admins can promote users'
    );
  END IF;
  
  UPDATE user_profiles
  SET role = 'admin', updated_at = now()
  WHERE email = user_email;
  
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  
  IF affected_rows = 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'User promoted to admin successfully'
  );
END;
$$;

CREATE OR REPLACE FUNCTION demote_admin_to_user(user_email text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  calling_user_role text;
  affected_rows int;
BEGIN
  SELECT role INTO calling_user_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF calling_user_role != 'admin' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Only admins can demote users'
    );
  END IF;
  
  UPDATE user_profiles
  SET role = 'user', updated_at = now()
  WHERE email = user_email;
  
  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  
  IF affected_rows = 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'User demoted to regular user successfully'
  );
END;
$$;

CREATE OR REPLACE FUNCTION list_all_users()
RETURNS TABLE (
  user_id uuid,
  email text,
  role text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  calling_user_role text;
BEGIN
  SELECT up.role INTO calling_user_role
  FROM user_profiles up
  WHERE up.id = auth.uid();
  
  IF calling_user_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can list all users';
  END IF;
  
  RETURN QUERY
  SELECT 
    user_profiles.id,
    user_profiles.email,
    user_profiles.role,
    user_profiles.created_at
  FROM user_profiles
  ORDER BY user_profiles.created_at DESC;
END;
$$;
