/*
  # Fix User Signup Database Error

  1. Changes
    - Update `handle_new_user` function to handle invalid role casting gracefully
    - Add exception handling to prevent database errors during user signup
    - Ensure role defaults to 'cashier' if metadata role is invalid

  2. Security
    - Maintains existing RLS policies
    - No changes to security model
*/

-- Updated function to handle role casting errors gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  user_role_value user_role := 'cashier';
BEGIN
  -- Safely extract and cast the role, defaulting to 'cashier' if invalid
  BEGIN
    IF new.raw_user_meta_data->>'role' IS NOT NULL THEN
      user_role_value := (new.raw_user_meta_data->>'role')::user_role;
    END IF;
  EXCEPTION
    WHEN invalid_text_representation THEN
      user_role_value := 'cashier';
    WHEN OTHERS THEN
      user_role_value := 'cashier';
  END;

  INSERT INTO public.user_profiles (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', 'Usuario'),
    user_role_value
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;