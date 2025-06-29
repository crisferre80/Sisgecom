/*
  # Fix Function Dependency Error

  1. Drop the trigger that depends on the function
  2. Drop and recreate the function with better error handling
  3. Recreate the trigger
  4. Add comprehensive error handling and logging
*/

-- Drop the trigger first to remove the dependency
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Now we can safely drop and recreate the function
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role_value user_role := 'cashier';
  user_name_value text := 'Usuario';
  user_email_value text;
BEGIN
  -- Log the attempt (for debugging)
  RAISE LOG 'Creating user profile for user ID: %', new.id;
  
  -- Safely extract email
  user_email_value := COALESCE(new.email, 'unknown@example.com');
  
  -- Safely extract name
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL AND new.raw_user_meta_data->>'name' IS NOT NULL THEN
      user_name_value := new.raw_user_meta_data->>'name';
      -- Ensure name is not empty
      IF LENGTH(TRIM(user_name_value)) = 0 THEN
        user_name_value := 'Usuario';
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      user_name_value := 'Usuario';
      RAISE LOG 'Error extracting name, using default: %', SQLERRM;
  END;
  
  -- Safely extract and validate role
  BEGIN
    IF new.raw_user_meta_data IS NOT NULL AND new.raw_user_meta_data->>'role' IS NOT NULL THEN
      -- Check if the role value is valid before casting
      CASE new.raw_user_meta_data->>'role'
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
      RAISE LOG 'Error extracting role, using default: %', SQLERRM;
  END;

  -- Insert the user profile with comprehensive error handling
  BEGIN
    INSERT INTO public.user_profiles (id, email, name, role, created_at)
    VALUES (
      new.id,
      user_email_value,
      user_name_value,
      user_role_value,
      now()
    );
    
    RAISE LOG 'Successfully created user profile for: %', user_email_value;
    
  EXCEPTION
    WHEN unique_violation THEN
      -- User profile already exists, update it instead
      RAISE LOG 'User profile already exists, updating: %', user_email_value;
      UPDATE public.user_profiles 
      SET 
        email = user_email_value,
        name = user_name_value,
        role = user_role_value
      WHERE id = new.id;
      
    WHEN foreign_key_violation THEN
      RAISE LOG 'Foreign key violation for user %: %', user_email_value, SQLERRM;
      -- Don't re-raise, allow user creation to continue
      
    WHEN check_violation THEN
      RAISE LOG 'Check constraint violation for user %: %', user_email_value, SQLERRM;
      -- Try with default values
      INSERT INTO public.user_profiles (id, email, name, role, created_at)
      VALUES (
        new.id,
        user_email_value,
        'Usuario',
        'cashier',
        now()
      );
      
    WHEN OTHERS THEN
      -- Log the error but don't fail the user creation completely
      RAISE LOG 'Unexpected error creating user profile for %: % - %', user_email_value, SQLSTATE, SQLERRM;
      -- Try a minimal insert as last resort
      BEGIN
        INSERT INTO public.user_profiles (id, email, name, role)
        VALUES (new.id, COALESCE(new.email, 'user@example.com'), 'Usuario', 'cashier');
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'Failed to create minimal user profile: % - %', SQLSTATE, SQLERRM;
          -- Don't re-raise to avoid blocking user creation
      END;
  END;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Add a recovery function to handle existing users without profiles
CREATE OR REPLACE FUNCTION public.create_missing_user_profiles()
RETURNS TABLE(user_id uuid, email text, status text) AS $$
DECLARE
  user_record RECORD;
  result_status text;
BEGIN
  -- Find users without profiles and create them
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
        COALESCE(user_record.email, 'unknown@example.com'),
        COALESCE(user_record.raw_user_meta_data->>'name', 'Usuario'),
        CASE 
          WHEN user_record.raw_user_meta_data->>'role' IN ('admin', 'manager', 'cashier', 'viewer') 
          THEN (user_record.raw_user_meta_data->>'role')::user_role
          ELSE 'cashier'::user_role
        END,
        now()
      );
      result_status := 'created';
      RAISE LOG 'Created missing profile for user: %', user_record.email;
    EXCEPTION
      WHEN OTHERS THEN
        result_status := 'failed: ' || SQLERRM;
        RAISE LOG 'Failed to create profile for user %: % %', user_record.email, SQLSTATE, SQLERRM;
    END;
    
    -- Return the result
    user_id := user_record.id;
    email := user_record.email;
    status := result_status;
    RETURN NEXT;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the recovery function to create any missing profiles
SELECT * FROM public.create_missing_user_profiles();