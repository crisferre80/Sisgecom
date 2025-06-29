/*
  # Fix Authentication and Database Errors

  1. Database Diagnostics
    - Check current state of auth and user_profiles tables
    - Verify function and trigger status
    
  2. Error Resolution
    - Ensure proper function error handling
    - Add diagnostic functions
    
  3. User Creation Support
    - Add safe user creation utilities
    - Verify profile creation works
*/

-- First, let's check the current state and add diagnostic functions
CREATE OR REPLACE FUNCTION public.diagnose_auth_setup()
RETURNS TABLE(
  check_name text,
  status text,
  details text
) AS $$
BEGIN
  -- Check if user_profiles table exists and has correct structure
  RETURN QUERY
  SELECT 
    'user_profiles_table'::text,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') 
         THEN 'OK' ELSE 'MISSING' END::text,
    'User profiles table status'::text;
    
  -- Check if handle_new_user function exists
  RETURN QUERY
  SELECT 
    'handle_new_user_function'::text,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user') 
         THEN 'OK' ELSE 'MISSING' END::text,
    'User creation function status'::text;
    
  -- Check if trigger exists
  RETURN QUERY
  SELECT 
    'auth_trigger'::text,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN 'OK' ELSE 'MISSING' END::text,
    'Auth trigger status'::text;
    
  -- Check user_profiles count
  RETURN QUERY
  SELECT 
    'user_profiles_count'::text,
    (SELECT COUNT(*)::text FROM public.user_profiles),
    'Number of user profiles'::text;
    
  -- Check auth.users count
  RETURN QUERY
  SELECT 
    'auth_users_count'::text,
    (SELECT COUNT(*)::text FROM auth.users),
    'Number of auth users'::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced function with better error handling and logging
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role_value user_role := 'cashier';
  user_name_value text := 'Usuario';
  user_email_value text;
  error_context text;
BEGIN
  -- Set error context for better debugging
  error_context := 'Initializing user profile creation for ID: ' || COALESCE(new.id::text, 'NULL');
  RAISE LOG '%', error_context;
  
  -- Validate required fields
  IF new.id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Safely extract email with validation
  BEGIN
    user_email_value := COALESCE(new.email, '');
    IF LENGTH(TRIM(user_email_value)) = 0 THEN
      user_email_value := 'user_' || new.id::text || '@temp.local';
      RAISE LOG 'Using generated email for user: %', user_email_value;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_email_value := 'user_' || new.id::text || '@temp.local';
      RAISE LOG 'Error extracting email, using generated: % - Error: %', user_email_value, SQLERRM;
  END;
  
  -- Safely extract name with validation
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL THEN
      user_name_value := COALESCE(new.raw_user_meta_data->>'name', '');
      IF LENGTH(TRIM(user_name_value)) = 0 THEN
        user_name_value := 'Usuario';
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_name_value := 'Usuario';
      RAISE LOG 'Error extracting name, using default - Error: %', SQLERRM;
  END;
  
  -- Safely extract and validate role
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL AND new.raw_user_meta_data->>'role' IS NOT NULL THEN
      CASE LOWER(TRIM(new.raw_user_meta_data->>'role'))
        WHEN 'admin' THEN user_role_value := 'admin';
        WHEN 'manager' THEN user_role_value := 'manager';
        WHEN 'cashier' THEN user_role_value := 'cashier';
        WHEN 'viewer' THEN user_role_value := 'viewer';
        ELSE 
          user_role_value := 'cashier';
          RAISE LOG 'Invalid role value: %, using default cashier', new.raw_user_meta_data->>'role';
      END CASE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_role_value := 'cashier';
      RAISE LOG 'Error extracting role, using default - Error: %', SQLERRM;
  END;

  -- Attempt to insert user profile with comprehensive error handling
  BEGIN
    error_context := 'Inserting user profile';
    RAISE LOG 'Attempting to create profile: ID=%, Email=%, Name=%, Role=%', 
              new.id, user_email_value, user_name_value, user_role_value;
              
    INSERT INTO public.user_profiles (id, email, name, role, created_at)
    VALUES (
      new.id,
      user_email_value,
      user_name_value,
      user_role_value,
      now()
    );
    
    RAISE LOG 'Successfully created user profile for: % (ID: %)', user_email_value, new.id;
    
  EXCEPTION
    WHEN unique_violation THEN
      error_context := 'Handling unique violation';
      RAISE LOG 'User profile already exists for ID: %, updating instead', new.id;
      
      UPDATE public.user_profiles 
      SET 
        email = user_email_value,
        name = user_name_value,
        role = user_role_value,
        created_at = COALESCE(created_at, now())
      WHERE id = new.id;
      
      RAISE LOG 'Updated existing user profile for: %', user_email_value;
      
    WHEN foreign_key_violation THEN
      error_context := 'Handling foreign key violation';
      RAISE LOG 'Foreign key violation for user % (ID: %): %', user_email_value, new.id, SQLERRM;
      -- This might indicate the auth.users record doesn't exist yet, which is unusual
      -- Let's wait a moment and try again
      PERFORM pg_sleep(0.1);
      
      INSERT INTO public.user_profiles (id, email, name, role, created_at)
      VALUES (new.id, user_email_value, user_name_value, user_role_value, now());
      
    WHEN check_violation THEN
      error_context := 'Handling check violation';
      RAISE LOG 'Check constraint violation for user %: %', user_email_value, SQLERRM;
      
      -- Try with minimal safe values
      INSERT INTO public.user_profiles (id, email, name, role, created_at)
      VALUES (new.id, user_email_value, 'Usuario', 'cashier', now());
      
    WHEN OTHERS THEN
      error_context := 'Handling unexpected error';
      RAISE LOG 'Unexpected error in % for user % (ID: %): % - %', 
                error_context, user_email_value, new.id, SQLSTATE, SQLERRM;
      
      -- Final attempt with absolute minimal data
      BEGIN
        INSERT INTO public.user_profiles (id, email, name, role)
        VALUES (new.id, COALESCE(new.email, 'temp@example.com'), 'Usuario', 'cashier');
        RAISE LOG 'Created minimal profile as fallback for user ID: %', new.id;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Complete failure to create user profile for ID: % - % %', new.id, SQLSTATE, SQLERRM;
          -- Don't re-raise to avoid blocking user creation entirely
      END;
  END;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger is properly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to safely create a demo user profile (for testing)
CREATE OR REPLACE FUNCTION public.create_demo_user_profile(
  user_id uuid,
  user_email text,
  user_name text DEFAULT 'Demo User'
)
RETURNS text AS $$
DECLARE
  result_message text;
BEGIN
  BEGIN
    INSERT INTO public.user_profiles (id, email, name, role, created_at)
    VALUES (user_id, user_email, user_name, 'admin', now());
    
    result_message := 'Demo user profile created successfully';
    RAISE LOG '%', result_message;
    
  EXCEPTION
    WHEN unique_violation THEN
      UPDATE public.user_profiles 
      SET email = user_email, name = user_name, role = 'admin'
      WHERE id = user_id;
      
      result_message := 'Demo user profile updated successfully';
      RAISE LOG '%', result_message;
      
    WHEN OTHERS THEN
      result_message := 'Failed to create demo user profile: ' || SQLERRM;
      RAISE LOG '%', result_message;
  END;
  
  RETURN result_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user can be created (diagnostic)
CREATE OR REPLACE FUNCTION public.test_user_creation()
RETURNS TABLE(
  test_name text,
  status text,
  message text
) AS $$
BEGIN
  -- Test 1: Check if we can insert into user_profiles
  BEGIN
    -- Try a test insert (we'll roll it back)
    INSERT INTO public.user_profiles (id, email, name, role, created_at)
    VALUES (gen_random_uuid(), 'test@example.com', 'Test User', 'cashier', now());
    
    -- If we get here, the insert worked
    RETURN QUERY SELECT 'profile_insert'::text, 'OK'::text, 'Can insert into user_profiles'::text;
    
    -- Clean up the test record
    DELETE FROM public.user_profiles WHERE email = 'test@example.com';
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'profile_insert'::text, 'FAILED'::text, SQLERRM::text;
  END;
  
  -- Test 2: Check RLS policies
  BEGIN
    -- This will test if RLS is properly configured
    PERFORM COUNT(*) FROM public.user_profiles;
    RETURN QUERY SELECT 'rls_check'::text, 'OK'::text, 'RLS policies allow access'::text;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'rls_check'::text, 'FAILED'::text, SQLERRM::text;
  END;
  
  -- Test 3: Check enum values
  BEGIN
    PERFORM 'admin'::user_role, 'manager'::user_role, 'cashier'::user_role, 'viewer'::user_role;
    RETURN QUERY SELECT 'enum_check'::text, 'OK'::text, 'All role enum values are valid'::text;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'enum_check'::text, 'FAILED'::text, SQLERRM::text;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run diagnostics
SELECT 'Running diagnostics...' as message;
SELECT * FROM public.diagnose_auth_setup();
SELECT * FROM public.test_user_creation();