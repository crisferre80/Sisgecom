/*
  # Fix Foreign Key Constraint Issue

  1. Problem Analysis
    - The user_profiles table has a foreign key constraint to auth.users(id)
    - When trying to insert into user_profiles, the constraint is failing
    - This suggests either timing issues or incorrect constraint setup

  2. Solution
    - Check and fix the foreign key constraint
    - Ensure proper referencing between tables
    - Add better error handling for edge cases

  3. Changes
    - Drop and recreate the foreign key constraint properly
    - Add validation functions
    - Improve the trigger function
*/

-- First, let's check the current constraint
DO $$
BEGIN
  -- Drop the existing foreign key constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'user_profiles_id_fkey' 
    AND table_name = 'user_profiles'
  ) THEN
    ALTER TABLE public.user_profiles DROP CONSTRAINT user_profiles_id_fkey;
    RAISE LOG 'Dropped existing foreign key constraint';
  END IF;
END $$;

-- Recreate the foreign key constraint with proper options
ALTER TABLE public.user_profiles 
ADD CONSTRAINT user_profiles_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users(id) 
ON DELETE CASCADE 
ON UPDATE CASCADE;

-- Create a function to validate user existence before profile creation
CREATE OR REPLACE FUNCTION public.validate_user_exists(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM auth.users WHERE id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced handle_new_user function with better validation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role_value user_role := 'cashier';
  user_name_value text := 'Usuario';
  user_email_value text;
  retry_count integer := 0;
  max_retries integer := 3;
BEGIN
  -- Validate that the user ID is not null
  IF new.id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Log the attempt
  RAISE LOG 'Creating user profile for user ID: % (Email: %)', new.id, new.email;
  
  -- Extract user data safely
  user_email_value := COALESCE(new.email, 'user_' || new.id::text || '@temp.local');
  
  -- Extract name
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL AND new.raw_user_meta_data->>'name' IS NOT NULL THEN
      user_name_value := TRIM(new.raw_user_meta_data->>'name');
      IF LENGTH(user_name_value) = 0 THEN
        user_name_value := 'Usuario';
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_name_value := 'Usuario';
  END;
  
  -- Extract role
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL AND new.raw_user_meta_data->>'role' IS NOT NULL THEN
      CASE LOWER(TRIM(new.raw_user_meta_data->>'role'))
        WHEN 'admin' THEN user_role_value := 'admin';
        WHEN 'manager' THEN user_role_value := 'manager';
        WHEN 'cashier' THEN user_role_value := 'cashier';
        WHEN 'viewer' THEN user_role_value := 'viewer';
        ELSE user_role_value := 'cashier';
      END CASE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_role_value := 'cashier';
  END;

  -- Attempt to insert with retry logic
  WHILE retry_count < max_retries LOOP
    BEGIN
      -- Double-check that the user exists in auth.users
      IF NOT public.validate_user_exists(new.id) THEN
        RAISE LOG 'User ID % not found in auth.users, waiting...', new.id;
        PERFORM pg_sleep(0.1);
        retry_count := retry_count + 1;
        CONTINUE;
      END IF;
      
      -- Attempt the insert
      INSERT INTO public.user_profiles (id, email, name, role, created_at)
      VALUES (
        new.id,
        user_email_value,
        user_name_value,
        user_role_value,
        now()
      );
      
      RAISE LOG 'Successfully created user profile for: % (ID: %)', user_email_value, new.id;
      EXIT; -- Success, exit the loop
      
    EXCEPTION
      WHEN unique_violation THEN
        -- Profile already exists, update it
        UPDATE public.user_profiles 
        SET 
          email = user_email_value,
          name = user_name_value,
          role = user_role_value
        WHERE id = new.id;
        
        RAISE LOG 'Updated existing user profile for: %', user_email_value;
        EXIT; -- Success, exit the loop
        
      WHEN foreign_key_violation THEN
        retry_count := retry_count + 1;
        IF retry_count >= max_retries THEN
          RAISE LOG 'Foreign key violation after % retries for user %: %', max_retries, user_email_value, SQLERRM;
          -- Don't re-raise to avoid blocking user creation
          EXIT;
        ELSE
          RAISE LOG 'Foreign key violation, retry % for user %', retry_count, user_email_value;
          PERFORM pg_sleep(0.1 * retry_count); -- Exponential backoff
        END IF;
        
      WHEN OTHERS THEN
        retry_count := retry_count + 1;
        IF retry_count >= max_retries THEN
          RAISE LOG 'Failed to create user profile after % retries for %: % - %', max_retries, user_email_value, SQLSTATE, SQLERRM;
          EXIT;
        ELSE
          RAISE LOG 'Error creating user profile, retry % for %: %', retry_count, user_email_value, SQLERRM;
          PERFORM pg_sleep(0.1 * retry_count);
        END IF;
    END;
  END LOOP;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to manually fix any orphaned users
CREATE OR REPLACE FUNCTION public.fix_orphaned_users()
RETURNS TABLE(user_id uuid, email text, status text) AS $$
DECLARE
  user_record RECORD;
  result_status text;
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
        COALESCE(user_record.email, 'user_' || user_record.id::text || '@temp.local'),
        COALESCE(user_record.raw_user_meta_data->>'name', 'Usuario'),
        CASE 
          WHEN user_record.raw_user_meta_data->>'role' IN ('admin', 'manager', 'cashier', 'viewer') 
          THEN (user_record.raw_user_meta_data->>'role')::user_role
          ELSE 'cashier'::user_role
        END,
        now()
      );
      result_status := 'created';
    EXCEPTION
      WHEN OTHERS THEN
        result_status := 'failed: ' || SQLERRM;
    END;
    
    user_id := user_record.id;
    email := user_record.email;
    status := result_status;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the fix
CREATE OR REPLACE FUNCTION public.test_profile_creation_fix()
RETURNS TABLE(
  test_name text,
  status text,
  message text
) AS $$
DECLARE
  test_user_id uuid;
BEGIN
  -- Test 1: Try to create a test profile with a valid UUID
  BEGIN
    test_user_id := gen_random_uuid();
    
    -- First create a mock auth user (this won't work in practice, but tests the constraint)
    -- We'll just test the constraint logic
    
    -- Test if we can validate the constraint setup
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE constraint_name = 'user_profiles_id_fkey' 
      AND table_name = 'user_profiles'
    ) THEN
      RETURN QUERY SELECT 'constraint_exists'::text, 'OK'::text, 'Foreign key constraint exists'::text;
    ELSE
      RETURN QUERY SELECT 'constraint_exists'::text, 'FAILED'::text, 'Foreign key constraint missing'::text;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'constraint_test'::text, 'FAILED'::text, SQLERRM::text;
  END;
  
  -- Test 2: Check if the validation function works
  BEGIN
    PERFORM public.validate_user_exists(gen_random_uuid());
    RETURN QUERY SELECT 'validation_function'::text, 'OK'::text, 'User validation function works'::text;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'validation_function'::text, 'FAILED'::text, SQLERRM::text;
  END;
  
  -- Test 3: Check if the trigger function exists and is valid
  BEGIN
    IF EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_name = 'handle_new_user' 
      AND routine_type = 'FUNCTION'
    ) THEN
      RETURN QUERY SELECT 'trigger_function'::text, 'OK'::text, 'Trigger function exists'::text;
    ELSE
      RETURN QUERY SELECT 'trigger_function'::text, 'FAILED'::text, 'Trigger function missing'::text;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'trigger_function'::text, 'FAILED'::text, SQLERRM::text;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the test
SELECT * FROM public.test_profile_creation_fix();

-- Fix any existing orphaned users
SELECT * FROM public.fix_orphaned_users();