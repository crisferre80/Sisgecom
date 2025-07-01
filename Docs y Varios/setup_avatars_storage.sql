-- =====================================================
-- SCRIPT PARA CONFIGURAR STORAGE DE AVATARES - VERSIÓN SIMPLIFICADA
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Crear el bucket user-avatars si no existe
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-avatars',
    'user-avatars',
    true,
    2097152, -- 2MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- NOTA: Las políticas de storage.objects deben configurarse desde el Dashboard de Supabase
-- No se pueden crear desde SQL debido a restricciones de permisos

-- 2. Verificar que user_profiles existe y tiene las columnas necesarias
DO $$
BEGIN
    -- Verificar si la tabla user_profiles existe
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        RAISE NOTICE 'Creando tabla user_profiles...';
        
        CREATE TABLE public.user_profiles (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            first_name varchar(50),
            last_name varchar(50),
            full_name varchar(100),
            phone varchar(20),
            address text,
            city varchar(50),
            country varchar(50),
            avatar_url text,
            is_active boolean DEFAULT true,
            email_verified boolean DEFAULT false,
            last_login_at timestamptz,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
        
        -- Habilitar RLS
        ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
        
        -- Crear políticas
        CREATE POLICY "Users can view their own profile" ON public.user_profiles
        FOR SELECT 
        TO authenticated 
        USING (auth.uid() = id);

        CREATE POLICY "Users can update their own profile" ON public.user_profiles
        FOR UPDATE 
        TO authenticated 
        USING (auth.uid() = id);

        CREATE POLICY "Users can insert their own profile" ON public.user_profiles
        FOR INSERT 
        TO authenticated 
        WITH CHECK (auth.uid() = id);
        
    ELSE
        RAISE NOTICE 'Tabla user_profiles ya existe';
        
        -- Verificar y agregar columnas que podrían faltar
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'first_name'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN first_name varchar(50);
            RAISE NOTICE 'Columna first_name agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'last_name'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN last_name varchar(50);
            RAISE NOTICE 'Columna last_name agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'avatar_url'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN avatar_url text;
            RAISE NOTICE 'Columna avatar_url agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'full_name'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN full_name varchar(100);
            RAISE NOTICE 'Columna full_name agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'phone'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN phone varchar(20);
            RAISE NOTICE 'Columna phone agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'address'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN address text;
            RAISE NOTICE 'Columna address agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'city'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN city varchar(50);
            RAISE NOTICE 'Columna city agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'country'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN country varchar(50);
            RAISE NOTICE 'Columna country agregada a user_profiles';
        END IF;
        
        -- Verificar columnas adicionales que podrían ser necesarias
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'updated_at'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN updated_at timestamptz DEFAULT now();
            RAISE NOTICE 'Columna updated_at agregada a user_profiles';
        END IF;
        
        IF NOT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_profiles' 
            AND column_name = 'created_at'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN created_at timestamptz DEFAULT now();
            RAISE NOTICE 'Columna created_at agregada a user_profiles';
        END IF;
    END IF;
    
    -- Forzar actualización del esquema cache de PostgREST
    NOTIFY pgrst, 'reload schema';
    
    -- Mensaje final de configuración completada
    RAISE NOTICE 'Configuración de storage de avatares completada exitosamente';
END $$;

-- 3. Crear trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS handle_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 4. Verificación final
SELECT 
    'Bucket user-avatars configurado' as status,
    public as is_public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'user-avatars';

SELECT 
    'Tabla user_profiles verificada' as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'user_profiles';

-- =====================================================
-- CONFIGURACIÓN MANUAL DE POLÍTICAS DE STORAGE
-- (Debe hacerse desde el Dashboard de Supabase)
-- =====================================================

/*
IMPORTANTE: Después de ejecutar este script, debes configurar las políticas 
de storage manualmente desde el Dashboard de Supabase:

1. Ve a Storage > user-avatars > Configuration > Policies
2. Crea las siguientes políticas:

POLÍTICA 1: "Allow public read"
- Operation: SELECT
- Target roles: public
- USING expression: bucket_id = 'user-avatars'

POLÍTICA 2: "Allow authenticated upload"
- Operation: INSERT  
- Target roles: authenticated
- WITH CHECK expression: bucket_id = 'user-avatars'

POLÍTICA 3: "Allow authenticated update"
- Operation: UPDATE
- Target roles: authenticated  
- USING expression: bucket_id = 'user-avatars'

POLÍTICA 4: "Allow authenticated delete"
- Operation: DELETE
- Target roles: authenticated
- USING expression: bucket_id = 'user-avatars'

Alternativamente, puedes hacer el bucket completamente público desde:
Storage > user-avatars > Configuration > "Make public"
*/
