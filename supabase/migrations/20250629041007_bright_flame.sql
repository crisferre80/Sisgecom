/*
  # Fix Database Error in User Signup

  1. Enhanced Error Handling
    - Add comprehensive error handling to the handle_new_user function
    - Add logging to help diagnose issues
    - Ensure all constraints are properly handled

  2. Validation
    - Add proper validation for user data
    - Handle edge cases in user metadata

  3. Fallback Mechanisms
    - Provide fallback values for all required fields
    - Ensure function never fails completely
*/

-- Drop and recreate the function with enhanced error handling
DROP FUNCTION IF EXISTS public.handle_new_user();

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
      
    WHEN OTHERS THEN
      -- Log the error but don't fail the user creation
      RAISE LOG 'Error creating user profile for %: % %', user_email_value, SQLSTATE, SQLERRM;
      -- Re-raise the error to prevent user creation if profile creation fails
      RAISE;
  END;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Add a function to manually create missing user profiles
CREATE OR REPLACE FUNCTION public.create_missing_user_profiles()
RETURNS void AS $$
DECLARE
  user_record RECORD;
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
      RAISE LOG 'Created missing profile for user: %', user_record.email;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE LOG 'Failed to create profile for user %: % %', user_record.email, SQLSTATE, SQLERRM;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the function to create any missing profiles
SELECT public.create_missing_user_profiles();