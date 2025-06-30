-- Migración para agregar campos de perfil de usuario y bucket de avatares
-- 20250630130000_user_profile_avatar.sql

-- Agregar campos adicionales a la tabla users para el perfil
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS country VARCHAR(100),
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS last_login TIMESTAMP WITH TIME ZONE;

-- Crear bucket para avatares de usuario
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Política de acceso público para lectura de avatares
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-avatars');

-- Política para que los usuarios puedan subir su propio avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Política para que los usuarios puedan actualizar su propio avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Política para que los usuarios puedan eliminar su propio avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Función para actualizar last_login automáticamente
CREATE OR REPLACE FUNCTION update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users 
  SET last_login = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para actualizar last_login cuando se crea una nueva sesión
CREATE TRIGGER update_last_login_on_session
  AFTER INSERT ON auth.sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_last_login();

-- Comentarios para documentar los campos
COMMENT ON COLUMN users.first_name IS 'Nombre del usuario';
COMMENT ON COLUMN users.last_name IS 'Apellido del usuario';
COMMENT ON COLUMN users.phone IS 'Número de teléfono del usuario';
COMMENT ON COLUMN users.address IS 'Dirección del usuario';
COMMENT ON COLUMN users.city IS 'Ciudad del usuario';
COMMENT ON COLUMN users.country IS 'País del usuario';
COMMENT ON COLUMN users.avatar_url IS 'URL del avatar del usuario en Supabase Storage';
COMMENT ON COLUMN users.last_login IS 'Último inicio de sesión del usuario';
