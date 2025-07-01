-- =====================================================
-- MIGRACIÓN DE GESTIÓN DE USUARIOS - VERSIÓN SIMPLIFICADA
-- Para copiar y pegar en Supabase SQL Editor
-- =====================================================

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Verificar si auth.users existe, si no, crear una versión demo
DO $$
DECLARE
    auth_users_exists boolean := false;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' AND table_name = 'users'
    ) INTO auth_users_exists;
    
    IF NOT auth_users_exists THEN
        RAISE NOTICE 'Creando tabla auth.users en modo demo';
        CREATE SCHEMA IF NOT EXISTS auth;
        CREATE TABLE auth.users (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            email varchar(255) UNIQUE NOT NULL,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now()
        );
        ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Tabla de perfiles de usuario (con verificación de columnas)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email varchar(255),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Agregar columnas si no existen
DO $$
BEGIN
    -- Verificar y agregar columnas una por una
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='email') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email varchar(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='full_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN full_name varchar(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='first_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN first_name varchar(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='last_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN last_name varchar(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='phone') THEN
        ALTER TABLE public.user_profiles ADD COLUMN phone varchar(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='address') THEN
        ALTER TABLE public.user_profiles ADD COLUMN address text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='city') THEN
        ALTER TABLE public.user_profiles ADD COLUMN city varchar(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='country') THEN
        ALTER TABLE public.user_profiles ADD COLUMN country varchar(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='role') THEN
        ALTER TABLE public.user_profiles ADD COLUMN role varchar(50) DEFAULT 'employee';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='avatar_url') THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar_url text;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='is_active') THEN
        ALTER TABLE public.user_profiles ADD COLUMN is_active boolean DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='email_verified') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email_verified boolean DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_profiles' AND column_name='last_login') THEN
        ALTER TABLE public.user_profiles ADD COLUMN last_login timestamptz;
    END IF;
END $$;

-- Agregar restricción de email único si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'user_profiles_email_key') THEN
        ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_email_key UNIQUE (email);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'La restricción de email único ya existe o hubo un error: %', SQLERRM;
END $$;

-- Tabla de roles
CREATE TABLE IF NOT EXISTS public.user_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(50) UNIQUE NOT NULL,
    description text,
    permissions jsonb DEFAULT '[]'::jsonb,
    is_system_role boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tabla de asignación de roles
CREATE TABLE IF NOT EXISTS public.user_role_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES public.user_roles(id) ON DELETE CASCADE,
    assigned_at timestamptz DEFAULT now(),
    is_active boolean DEFAULT true,
    UNIQUE(user_profile_id, role_id)
);

-- Tabla de sesiones
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_token text UNIQUE NOT NULL,
    device_info jsonb,
    ip_address inet,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    expires_at timestamptz
);

-- Tabla de actividades
CREATE TABLE IF NOT EXISTS public.user_activities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    activity_type varchar(50) NOT NULL,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now()
);

-- Insertar roles por defecto
INSERT INTO public.user_roles (name, description, permissions, is_system_role) VALUES
    ('admin', 'Administrador del sistema', '["all"]'::jsonb, true),
    ('manager', 'Gerente', '["read", "write", "manage_inventory"]'::jsonb, true),
    ('employee', 'Empleado', '["read", "write"]'::jsonb, true),
    ('viewer', 'Solo lectura', '["read"]'::jsonb, true)
ON CONFLICT (name) DO NOTHING;

-- Agregar claves foráneas con manejo de errores
DO $$
BEGIN
    -- Ya no necesitamos FK a auth.users porque user_profiles es independiente
    RAISE NOTICE 'user_profiles es independiente, no necesita FK a auth.users';
END $$;

-- Habilitar RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- Función para verificar si es admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_uuid uuid;
    is_user_admin boolean := false;
BEGIN
    BEGIN
        user_uuid := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        RETURN false;
    END;
    
    IF user_uuid IS NULL THEN
        RETURN false;
    END IF;
    
    SELECT EXISTS(
        SELECT 1 
        FROM public.user_profiles up
        WHERE up.id = user_uuid 
        AND up.role = 'admin' 
        AND up.is_active = true
    ) INTO is_user_admin;
    
    RETURN is_user_admin;
    
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$;

-- Políticas RLS básicas (eliminar si existen antes de crear)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Admins can insert profiles" ON public.user_profiles;
CREATE POLICY "Admins can insert profiles" ON public.user_profiles
    FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Everyone can view roles" ON public.user_roles;
CREATE POLICY "Everyone can view roles" ON public.user_roles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view own role assignments" ON public.user_role_assignments;
CREATE POLICY "Users can view own role assignments" ON public.user_role_assignments
    FOR SELECT USING (auth.uid() = user_profile_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can view own sessions" ON public.user_sessions;
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_profile_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can view own activities" ON public.user_activities;
CREATE POLICY "Users can view own activities" ON public.user_activities
    FOR SELECT USING (auth.uid() = user_profile_id OR public.is_admin());

-- Función para obtener estadísticas de usuarios
CREATE OR REPLACE FUNCTION public.get_user_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'total_users', (SELECT COUNT(*) FROM public.user_profiles WHERE is_active = true),
        'admin_users', (SELECT COUNT(*) FROM public.user_profiles WHERE role = 'admin' AND is_active = true),
        'active_users', (SELECT COUNT(*) FROM public.user_profiles WHERE is_active = true),
        'recent_users', (SELECT COUNT(*) FROM public.user_profiles WHERE created_at >= CURRENT_DATE - INTERVAL '7 days')
    ) INTO result;
    
    RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'total_users', 0,
        'admin_users', 0,
        'active_users', 0,
        'recent_users', 0
    );
END;
$$;

-- Vista simplificada para usuarios completos
CREATE OR REPLACE VIEW public.users_complete AS
SELECT 
    up.id,
    up.email,
    up.full_name,
    up.first_name,
    up.last_name,
    up.phone,
    up.address,
    up.city,
    up.country,
    up.role,
    up.avatar_url,
    up.is_active,
    up.email_verified,
    up.last_login,
    up.created_at,
    up.updated_at
FROM public.user_profiles up;

-- Trigger para updated_at (con manejo de errores)
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Eliminar triggers si existen y crear nuevos
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_profile_id ON public.user_role_assignments(user_profile_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id ON public.user_role_assignments(role_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_profile_id ON public.user_sessions(user_profile_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON public.user_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_activities_user_profile_id ON public.user_activities(user_profile_id);

-- Comentarios
COMMENT ON TABLE public.user_profiles IS 'Perfiles de usuario que extienden auth.users';
COMMENT ON TABLE public.user_roles IS 'Roles del sistema con permisos asociados';
COMMENT ON TABLE public.user_role_assignments IS 'Asignación de roles a usuarios';
COMMENT ON TABLE public.user_sessions IS 'Sesiones activas de usuarios';
COMMENT ON TABLE public.user_activities IS 'Log de actividades de usuarios';

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '=== MIGRACIÓN DE GESTIÓN DE USUARIOS COMPLETADA ===';
    RAISE NOTICE 'Tablas creadas: user_profiles, user_roles, user_role_assignments, user_sessions, user_activities';
    RAISE NOTICE 'Roles por defecto: admin, manager, employee, viewer';
    RAISE NOTICE 'RLS habilitado con políticas básicas';
    RAISE NOTICE 'Vista users_complete creada';
    RAISE NOTICE 'Función is_admin() creada';
    RAISE NOTICE 'Índices y triggers configurados';
END $$;
