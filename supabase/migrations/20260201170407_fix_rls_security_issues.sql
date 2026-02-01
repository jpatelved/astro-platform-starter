/*
  # Fix RLS Security and Performance Issues

  1. Performance Optimizations
    - Update all RLS policies to use `(select auth.uid())` instead of `auth.uid()`
    - This prevents re-evaluation of auth functions for each row
  
  2. Remove Duplicate Policies
    - Remove old "Anyone can view trade insights" policy (public access)
    - Remove old "Authenticated users can insert trade insights" policy
    - These conflict with new admin-only policies
  
  3. Function Security
    - Fix `handle_new_user` function to have immutable search path
    - Set search_path explicitly to prevent security vulnerabilities
  
  4. Security Notes
    - Trade insights now require authentication to view
    - Only admins can insert/update/delete trade insights
    - User profiles are protected with proper RLS
    - All auth function calls are optimized for performance
*/

DROP POLICY IF EXISTS "Anyone can view trade insights" ON trade_insights;
DROP POLICY IF EXISTS "Authenticated users can insert trade insights" ON trade_insights;

DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;
CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Admins can read all profiles" ON user_profiles;
CREATE POLICY "Admins can read all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK (
    (select auth.uid()) = id 
    AND role = (SELECT role FROM user_profiles WHERE id = (select auth.uid()))
  );

DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;
CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = id AND role = 'user');

DROP POLICY IF EXISTS "Authenticated users can view trade insights" ON trade_insights;
CREATE POLICY "Authenticated users can view trade insights"
  ON trade_insights FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can insert trade insights" ON trade_insights;
CREATE POLICY "Admins can insert trade insights"
  ON trade_insights FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update trade insights" ON trade_insights;
CREATE POLICY "Admins can update trade insights"
  ON trade_insights FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can delete trade insights" ON trade_insights;
CREATE POLICY "Admins can delete trade insights"
  ON trade_insights FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role = 'admin'
    )
  );

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'user');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
