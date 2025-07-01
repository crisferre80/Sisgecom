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

-- Tabla de perfiles de usuario
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    first_name varchar(50),
    last_name varchar(50),
    phone varchar(20),
    avatar_url text,
    is_active boolean DEFAULT true,
    email_verified boolean DEFAULT false,
    last_login_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

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
    user_id uuid NOT NULL,
    role_id uuid NOT NULL REFERENCES public.user_roles(id) ON DELETE CASCADE,
    assigned_at timestamptz DEFAULT now(),
    is_active boolean DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- Tabla de sesiones
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
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
    user_id uuid NOT NULL,
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
    -- FK para user_profiles
    BEGIN
        ALTER TABLE public.user_profiles 
        ADD CONSTRAINT fk_user_profiles_user_id 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FK user_profiles ya existe o error: %', SQLERRM;
    END;
    
    -- FK para user_role_assignments
    BEGIN
        ALTER TABLE public.user_role_assignments 
        ADD CONSTRAINT fk_user_role_assignments_user_id 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FK user_role_assignments ya existe o error: %', SQLERRM;
    END;
    
    -- FK para user_sessions
    BEGIN
        ALTER TABLE public.user_sessions 
        ADD CONSTRAINT fk_user_sessions_user_id 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FK user_sessions ya existe o error: %', SQLERRM;
    END;
    
    -- FK para user_activities
    BEGIN
        ALTER TABLE public.user_activities 
        ADD CONSTRAINT fk_user_activities_user_id 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FK user_activities ya existe o error: %', SQLERRM;
    END;
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
        FROM public.user_role_assignments ura
        JOIN public.user_roles ur ON ura.role_id = ur.id
        WHERE ura.user_id = user_uuid 
        AND ur.name = 'admin' 
        AND ura.is_active = true
    ) INTO is_user_admin;
    
    RETURN is_user_admin;
    
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$;

-- Políticas RLS básicas
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Admins can insert profiles" ON public.user_profiles
    FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Everyone can view roles" ON public.user_roles
    FOR SELECT USING (true);

CREATE POLICY "Users can view own role assignments" ON public.user_role_assignments
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can view own activities" ON public.user_activities
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- Vista simplificada para usuarios completos
CREATE OR REPLACE VIEW public.users_complete AS
SELECT 
    up.id,
    up.user_id,
    COALESCE(au.email, 'demo@example.com') as email,
    up.first_name,
    up.last_name,
    up.phone,
    up.avatar_url,
    up.is_active,
    up.last_login_at,
    up.created_at,
    up.updated_at,
    array_agg(DISTINCT ur.name) FILTER (WHERE ur.name IS NOT NULL) as roles
FROM public.user_profiles up
LEFT JOIN auth.users au ON up.user_id = au.id
LEFT JOIN public.user_role_assignments ura ON up.user_id = ura.user_id AND ura.is_active = true
LEFT JOIN public.user_roles ur ON ura.role_id = ur.id
GROUP BY up.id, up.user_id, au.email, up.first_name, up.last_name, up.phone, 
         up.avatar_url, up.is_active, up.last_login_at, up.created_at, up.updated_at;

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_id ON public.user_role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id ON public.user_role_assignments(role_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON public.user_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);

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
