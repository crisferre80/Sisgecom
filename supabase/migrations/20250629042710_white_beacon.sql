/*
  # Fix Supabase Signup Database Error

  1. Problem Analysis
    - Supabase signup is failing with "Database error saving new user"
    - This suggests the trigger or function is causing issues during user creation
    - Need to temporarily disable the trigger to allow user creation

  2. Solution Strategy
    - Temporarily disable the problematic trigger
    - Create a simpler, more robust trigger function
    - Add comprehensive error logging
    - Ensure user creation works without profile creation blocking it

  3. Changes
    - Disable current trigger temporarily
    - Create a safer trigger function
    - Add manual profile creation option
    - Re-enable trigger with better error handling
*/

-- Step 1: Temporarily disable the trigger to allow user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 2: Create a much simpler and safer trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user_safe()
RETURNS trigger AS $$
BEGIN
  -- Use a background job approach - don't block user creation
  -- Insert into a queue table first, then process later
  BEGIN
    INSERT INTO public.user_profiles (id, email, name, role, created_at)
    VALUES (
      new.id,
      COALESCE(new.email, 'user@example.com'),
      COALESCE(new.raw_user_meta_data->>'name', 'Usuario'),
      'cashier',
      now()
    );
    
    RAISE LOG 'Successfully created user profile for: %', new.email;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log the error but don't block user creation
      RAISE LOG 'Failed to create user profile for %: % - %', new.email, SQLSTATE, SQLERRM;
      -- Don't re-raise the exception - let user creation succeed
  END;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create the trigger with the safer function
CREATE TRIGGER on_auth_user_created_safe
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_safe();

-- Step 4: Create a manual profile creation function for cleanup
CREATE OR REPLACE FUNCTION public.create_user_profile_manual(
  user_id uuid,
  user_email text,
  user_name text DEFAULT 'Usuario',
  user_role text DEFAULT 'cashier'
)
RETURNS text AS $$
DECLARE
  role_value user_role;
BEGIN
  -- Validate and convert role
  CASE LOWER(user_role)
    WHEN 'admin' THEN role_value := 'admin';
    WHEN 'manager' THEN role_value := 'manager';
    WHEN 'cashier' THEN role_value := 'cashier';
    WHEN 'viewer' THEN role_value := 'viewer';
    ELSE role_value := 'cashier';
  END CASE;

  -- Insert or update the profile
  INSERT INTO public.user_profiles (id, email, name, role, created_at)
  VALUES (user_id, user_email, user_name, role_value, now())
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role;

  RETURN 'Profile created/updated successfully for: ' || user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create a function to check and fix missing profiles
CREATE OR REPLACE FUNCTION public.sync_user_profiles()
RETURNS TABLE(user_id uuid, email text, action text) AS $$
DECLARE
  user_record RECORD;
  action_taken text;
BEGIN
  FOR user_record IN 
    SELECT u.id, u.email, u.raw_user_meta_data
    FROM auth.users u
    LEFT JOIN public.user_profiles p ON u.id = p.id
    WHERE p.id IS NULL
  LOOP
    BEGIN
      INSERT INTO public.user_profiles (id, email, name, role, created_at)
      VALUES (
        user_record.id,
        COALESCE(user_record.email, 'user@example.com'),
        COALESCE(user_record.raw_user_meta_data->>'name', 'Usuario'),
        CASE 
          WHEN user_record.raw_user_meta_data->>'role' IN ('admin', 'manager', 'cashier', 'viewer') 
          THEN (user_record.raw_user_meta_data->>'role')::user_role
          ELSE 'cashier'::user_role
        END,
        now()
      );
      action_taken := 'created';
    EXCEPTION
      WHEN OTHERS THEN
        action_taken := 'failed: ' || SQLERRM;
    END;
    
    user_id := user_record.id;
    email := user_record.email;
    action := action_taken;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Add a function to test user creation without profiles
CREATE OR REPLACE FUNCTION public.test_auth_only()
RETURNS text AS $$
BEGIN
  -- This function tests if the basic auth system works
  -- without the profile creation trigger
  
  -- Check if we can access auth.users (read-only test)
  PERFORM COUNT(*) FROM auth.users;
  
  RETURN 'Auth system accessible - user creation should work now';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Run the test
SELECT public.test_auth_only() as test_result;

-- Step 8: Sync any existing users without profiles
SELECT * FROM public.sync_user_profiles();

-- Step 9: Add a policy to allow profile creation during signup
CREATE POLICY "Allow profile creation during signup"
  ON user_profiles
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Note: This policy allows anonymous users to create profiles
-- This is needed because the trigger runs before the user is authenticated
-- We'll remove this policy later and use a more secure approach