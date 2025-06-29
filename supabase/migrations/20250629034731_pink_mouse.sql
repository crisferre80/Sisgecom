/*
  # Setup Demo User Instructions

  This migration provides instructions for setting up the demo user since Supabase Auth
  users cannot be created directly through SQL migrations.

  ## Manual Setup Required:

  1. Go to your Supabase Dashboard: https://supabase.com/dashboard
  2. Navigate to Authentication > Users
  3. Click "Add User" 
  4. Create a user with:
     - Email: admin@demo.com
     - Password: admin123
     - User Metadata: {"name": "Demo Admin", "role": "admin"}

  Alternatively, you can use the Supabase CLI or create a signup endpoint.
  
  ## Automatic Profile Creation
  
  Once the user is created in Auth, the trigger will automatically create
  a profile in the user_profiles table with admin role.
*/

-- This migration serves as documentation only
-- The actual user creation must be done through Supabase Auth
SELECT 'Demo user setup instructions added' as message;