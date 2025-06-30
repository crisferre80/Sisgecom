-- Migración robusta para gestión de usuarios
-- Maneja tanto el caso donde auth.users existe como donde no existe

-- Primero verificamos si auth.users existe y manejamos los errores
DO $$
DECLARE
    auth_users_exists boolean := false;
    auth_users_has_id boolean := false;
BEGIN
    -- Verificar si auth.users existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) INTO auth_users_exists;
    
    RAISE NOTICE 'auth.users existe: %', auth_users_exists;
    
    -- Si existe, verificar si tiene columna id
    IF auth_users_exists THEN
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'auth' 
            AND table_name = 'users' 
            AND column_name = 'id'
        ) INTO auth_users_has_id;
        
        RAISE NOTICE 'auth.users tiene columna id: %', auth_users_has_id;
    END IF;
    
    -- Crear tabla auth.users si no existe (modo demo)
    IF NOT auth_users_exists THEN
        RAISE NOTICE 'Creando tabla auth.users en modo demo';
        
        CREATE SCHEMA IF NOT EXISTS auth;
        
        CREATE TABLE auth.users (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            email varchar(255) UNIQUE NOT NULL,
            encrypted_password varchar(255),
            email_confirmed_at timestamptz,
            invited_at timestamptz,
            confirmation_token varchar(255),
            confirmation_sent_at timestamptz,
            recovery_token varchar(255),
            recovery_sent_at timestamptz,
            email_change_token varchar(255),
            email_change varchar(255),
            email_change_sent_at timestamptz,
            last_sign_in_at timestamptz,
            raw_app_meta_data jsonb,
            raw_user_meta_data jsonb,
            is_super_admin boolean,
            created_at timestamptz DEFAULT now(),
            updated_at timestamptz DEFAULT now(),
            phone varchar(15),
            phone_confirmed_at timestamptz,
            phone_change varchar(15),
            phone_change_token varchar(255),
            phone_change_sent_at timestamptz,
            confirmed_at timestamptz GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
            email_change_confirm_status smallint DEFAULT 0,
            banned_until timestamptz,
            reauthentication_token varchar(255),
            reauthentication_sent_at timestamptz,
            is_sso_user boolean NOT NULL DEFAULT false,
            deleted_at timestamptz,
            is_anonymous boolean NOT NULL DEFAULT false
        );
        
        -- Habilitar RLS en auth.users
        ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
        
        -- Política básica para auth.users
        CREATE POLICY "Users can view own profile" ON auth.users
            FOR SELECT USING (auth.uid() = id);
        
        auth_users_exists := true;
        auth_users_has_id := true;
    END IF;
END $$;

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabla de perfiles de usuario (extiende auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    first_name varchar(50),
    last_name varchar(50),
    phone varchar(20),
    avatar_url text,
    date_of_birth date,
    address text,
    city varchar(100),
    country varchar(100),
    timezone varchar(50) DEFAULT 'UTC',
    language varchar(10) DEFAULT 'es',
    theme varchar(20) DEFAULT 'light',
    notifications_enabled boolean DEFAULT true,
    email_notifications boolean DEFAULT true,
    push_notifications boolean DEFAULT true,
    two_factor_enabled boolean DEFAULT false,
    last_login_at timestamptz,
    last_ip_address inet,
    login_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    email_verified boolean DEFAULT false,
    phone_verified boolean DEFAULT false,
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

-- Tabla de asignación de roles a usuarios
CREATE TABLE IF NOT EXISTS public.user_role_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    role_id uuid NOT NULL REFERENCES public.user_roles(id) ON DELETE CASCADE,
    assigned_by uuid,
    assigned_at timestamptz DEFAULT now(),
    expires_at timestamptz,
    is_active boolean DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- Tabla de permisos
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(100) UNIQUE NOT NULL,
    description text,
    category varchar(50),
    created_at timestamptz DEFAULT now()
);

-- Tabla de asignación de permisos a usuarios
CREATE TABLE IF NOT EXISTS public.user_permission_assignments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    permission_id uuid NOT NULL REFERENCES public.user_permissions(id) ON DELETE CASCADE,
    granted_by uuid,
    granted_at timestamptz DEFAULT now(),
    expires_at timestamptz,
    is_active boolean DEFAULT true,
    UNIQUE(user_id, permission_id)
);

-- Tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    session_token text UNIQUE NOT NULL,
    device_info jsonb,
    ip_address inet,
    user_agent text,
    location jsonb,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    last_activity_at timestamptz DEFAULT now(),
    expires_at timestamptz
);

-- Tabla de actividad de usuarios
CREATE TABLE IF NOT EXISTS public.user_activities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    activity_type varchar(50) NOT NULL,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamptz DEFAULT now()
);

-- Tabla de configuraciones de usuario
CREATE TABLE IF NOT EXISTS public.user_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE,
    settings jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Insertar roles por defecto
INSERT INTO public.user_roles (name, description, permissions, is_system_role) VALUES
    ('admin', 'Administrador del sistema', '["all"]'::jsonb, true),
    ('manager', 'Gerente', '["read", "write", "manage_inventory", "view_reports"]'::jsonb, true),
    ('employee', 'Empleado', '["read", "write"]'::jsonb, true),
    ('viewer', 'Solo lectura', '["read"]'::jsonb, true)
ON CONFLICT (name) DO NOTHING;

-- Insertar permisos por defecto
INSERT INTO public.user_permissions (name, description, category) VALUES
    ('read', 'Leer datos', 'general'),
    ('write', 'Escribir datos', 'general'),
    ('delete', 'Eliminar datos', 'general'),
    ('manage_users', 'Gestionar usuarios', 'admin'),
    ('manage_inventory', 'Gestionar inventario', 'inventory'),
    ('view_reports', 'Ver reportes', 'reports'),
    ('manage_settings', 'Gestionar configuraciones', 'admin')
ON CONFLICT (name) DO NOTHING;

-- Ahora intentamos agregar las claves foráneas con manejo de errores
DO $$
DECLARE
    auth_users_exists boolean := false;
BEGIN
    -- Verificar si auth.users existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) INTO auth_users_exists;
    
    IF auth_users_exists THEN
        BEGIN
            -- Agregar FK para user_profiles.user_id
            ALTER TABLE public.user_profiles 
            ADD CONSTRAINT fk_user_profiles_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_profiles.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_profiles.user_id: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_role_assignments.user_id
            ALTER TABLE public.user_role_assignments 
            ADD CONSTRAINT fk_user_role_assignments_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_role_assignments.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_role_assignments.user_id: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_role_assignments.assigned_by
            ALTER TABLE public.user_role_assignments 
            ADD CONSTRAINT fk_user_role_assignments_assigned_by 
            FOREIGN KEY (assigned_by) REFERENCES auth.users(id) ON DELETE SET NULL;
            
            RAISE NOTICE 'FK agregada para user_role_assignments.assigned_by';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_role_assignments.assigned_by: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_permission_assignments.user_id
            ALTER TABLE public.user_permission_assignments 
            ADD CONSTRAINT fk_user_permission_assignments_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_permission_assignments.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_permission_assignments.user_id: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_permission_assignments.granted_by
            ALTER TABLE public.user_permission_assignments 
            ADD CONSTRAINT fk_user_permission_assignments_granted_by 
            FOREIGN KEY (granted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
            
            RAISE NOTICE 'FK agregada para user_permission_assignments.granted_by';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_permission_assignments.granted_by: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_sessions.user_id
            ALTER TABLE public.user_sessions 
            ADD CONSTRAINT fk_user_sessions_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_sessions.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_sessions.user_id: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_activities.user_id
            ALTER TABLE public.user_activities 
            ADD CONSTRAINT fk_user_activities_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_activities.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_activities.user_id: %', SQLERRM;
        END;
        
        BEGIN
            -- Agregar FK para user_settings.user_id
            ALTER TABLE public.user_settings 
            ADD CONSTRAINT fk_user_settings_user_id 
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'FK agregada para user_settings.user_id';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error al agregar FK para user_settings.user_id: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'auth.users no existe, saltando claves foráneas';
    END IF;
END $$;

-- Habilitar RLS en todas las tablas
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permission_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Función auxiliar para verificar si el usuario es admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_uuid uuid;
    is_user_admin boolean := false;
BEGIN
    -- Obtener el UUID del usuario actual de forma segura
    BEGIN
        user_uuid := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        RETURN false;
    END;
    
    -- Si no hay usuario autenticado, no es admin
    IF user_uuid IS NULL THEN
        RETURN false;
    END IF;
    
    -- Verificar si el usuario tiene rol de admin
    SELECT EXISTS(
        SELECT 1 
        FROM public.user_role_assignments ura
        JOIN public.user_roles ur ON ura.role_id = ur.id
        WHERE ura.user_id = user_uuid 
        AND ur.name = 'admin' 
        AND ura.is_active = true
        AND (ura.expires_at IS NULL OR ura.expires_at > now())
    ) INTO is_user_admin;
    
    RETURN is_user_admin;
    
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$;

-- Función auxiliar para verificar permisos de acceso a datos de usuario
CREATE OR REPLACE FUNCTION public.can_access_user_data(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id uuid;
BEGIN
    -- Obtener el ID del usuario actual de forma segura
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        RETURN false;
    END;
    
    -- Si no hay usuario autenticado, no puede acceder
    IF current_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Si es el mismo usuario, puede acceder
    IF current_user_id = target_user_id THEN
        RETURN true;
    END IF;
    
    -- Si es admin, puede acceder
    IF public.is_admin() THEN
        RETURN true;
    END IF;
    
    RETURN false;
    
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$;

-- Políticas RLS para user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (public.can_access_user_data(user_id));

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (public.can_access_user_data(user_id));

CREATE POLICY "Admins can insert profiles" ON public.user_profiles
    FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete profiles" ON public.user_profiles
    FOR DELETE USING (public.is_admin());

-- Políticas RLS para user_roles
CREATE POLICY "Everyone can view roles" ON public.user_roles
    FOR SELECT USING (true);

CREATE POLICY "Only admins can modify roles" ON public.user_roles
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_role_assignments
CREATE POLICY "Users can view own role assignments" ON public.user_role_assignments
    FOR SELECT USING (public.can_access_user_data(user_id));

CREATE POLICY "Admins can manage role assignments" ON public.user_role_assignments
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_permissions
CREATE POLICY "Everyone can view permissions" ON public.user_permissions
    FOR SELECT USING (true);

CREATE POLICY "Only admins can modify permissions" ON public.user_permissions
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_permission_assignments
CREATE POLICY "Users can view own permission assignments" ON public.user_permission_assignments
    FOR SELECT USING (public.can_access_user_data(user_id));

CREATE POLICY "Admins can manage permission assignments" ON public.user_permission_assignments
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_sessions
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (public.can_access_user_data(user_id));

CREATE POLICY "Users can update own sessions" ON public.user_sessions
    FOR UPDATE USING (public.can_access_user_data(user_id));

CREATE POLICY "Users can insert own sessions" ON public.user_sessions
    FOR INSERT WITH CHECK (public.can_access_user_data(user_id));

CREATE POLICY "Admins can manage all sessions" ON public.user_sessions
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_activities
CREATE POLICY "Users can view own activities" ON public.user_activities
    FOR SELECT USING (public.can_access_user_data(user_id));

CREATE POLICY "System can insert activities" ON public.user_activities
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage all activities" ON public.user_activities
    FOR ALL USING (public.is_admin());

-- Políticas RLS para user_settings
CREATE POLICY "Users can manage own settings" ON public.user_settings
    FOR ALL USING (public.can_access_user_data(user_id));

-- Función para obtener el perfil completo del usuario
CREATE OR REPLACE FUNCTION public.get_user_profile(user_uuid uuid DEFAULT NULL)
RETURNS TABLE (
    id uuid,
    email text,
    first_name text,
    last_name text,
    phone text,
    avatar_url text,
    roles text[],
    permissions text[],
    last_login_at timestamptz,
    is_active boolean,
    created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_user_id uuid;
    auth_users_exists boolean := false;
BEGIN
    -- Si no se proporciona user_uuid, usar el usuario actual
    IF user_uuid IS NULL THEN
        target_user_id := auth.uid();
    ELSE
        target_user_id := user_uuid;
    END IF;
    
    -- Verificar si puede acceder a los datos del usuario
    IF NOT public.can_access_user_data(target_user_id) THEN
        RAISE EXCEPTION 'No tienes permisos para acceder a este perfil de usuario';
    END IF;
    
    -- Verificar si auth.users existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) INTO auth_users_exists;
    
    -- Retornar datos según si auth.users existe o no
    IF auth_users_exists THEN
        RETURN QUERY
        SELECT 
            up.id,
            au.email::text,
            up.first_name::text,
            up.last_name::text,
            up.phone::text,
            up.avatar_url::text,
            COALESCE(array_agg(DISTINCT ur.name) FILTER (WHERE ur.name IS NOT NULL), '{}'::text[]) as roles,
            COALESCE(array_agg(DISTINCT uperm.name) FILTER (WHERE uperm.name IS NOT NULL), '{}'::text[]) as permissions,
            up.last_login_at,
            up.is_active,
            up.created_at
        FROM public.user_profiles up
        LEFT JOIN auth.users au ON up.user_id = au.id
        LEFT JOIN public.user_role_assignments ura ON up.user_id = ura.user_id AND ura.is_active = true
        LEFT JOIN public.user_roles ur ON ura.role_id = ur.id
        LEFT JOIN public.user_permission_assignments upa ON up.user_id = upa.user_id AND upa.is_active = true
        LEFT JOIN public.user_permissions uperm ON upa.permission_id = uperm.id
        WHERE up.user_id = target_user_id
        GROUP BY up.id, au.email, up.first_name, up.last_name, up.phone, up.avatar_url, up.last_login_at, up.is_active, up.created_at;
    ELSE
        -- Modo demo sin auth.users
        RETURN QUERY
        SELECT 
            up.id,
            'demo@example.com'::text as email,
            up.first_name::text,
            up.last_name::text,
            up.phone::text,
            up.avatar_url::text,
            COALESCE(array_agg(DISTINCT ur.name) FILTER (WHERE ur.name IS NOT NULL), '{}'::text[]) as roles,
            COALESCE(array_agg(DISTINCT uperm.name) FILTER (WHERE uperm.name IS NOT NULL), '{}'::text[]) as permissions,
            up.last_login_at,
            up.is_active,
            up.created_at
        FROM public.user_profiles up
        LEFT JOIN public.user_role_assignments ura ON up.user_id = ura.user_id AND ura.is_active = true
        LEFT JOIN public.user_roles ur ON ura.role_id = ur.id
        LEFT JOIN public.user_permission_assignments upa ON up.user_id = upa.user_id AND upa.is_active = true
        LEFT JOIN public.user_permissions uperm ON upa.permission_id = uperm.id
        WHERE up.user_id = target_user_id
        GROUP BY up.id, up.first_name, up.last_name, up.phone, up.avatar_url, up.last_login_at, up.is_active, up.created_at;
    END IF;
END;
$$;

-- Vista para usuarios completos (con manejo de auth.users)
DO $$
DECLARE
    auth_users_exists boolean := false;
BEGIN
    -- Verificar si auth.users existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) INTO auth_users_exists;
    
    IF auth_users_exists THEN
        EXECUTE '
        CREATE OR REPLACE VIEW public.users_complete AS
        SELECT 
            up.id,
            up.user_id,
            au.email,
            up.first_name,
            up.last_name,
            up.phone,
            up.avatar_url,
            up.is_active,
            up.last_login_at,
            up.created_at,
            up.updated_at,
            array_agg(DISTINCT ur.name) FILTER (WHERE ur.name IS NOT NULL) as roles,
            array_agg(DISTINCT uperm.name) FILTER (WHERE uperm.name IS NOT NULL) as permissions
        FROM public.user_profiles up
        LEFT JOIN auth.users au ON up.user_id = au.id
        LEFT JOIN public.user_role_assignments ura ON up.user_id = ura.user_id AND ura.is_active = true
        LEFT JOIN public.user_roles ur ON ura.role_id = ur.id
        LEFT JOIN public.user_permission_assignments upa ON up.user_id = upa.user_id AND upa.is_active = true
        LEFT JOIN public.user_permissions uperm ON upa.permission_id = uperm.id
        GROUP BY up.id, up.user_id, au.email, up.first_name, up.last_name, up.phone, up.avatar_url, 
                 up.is_active, up.last_login_at, up.created_at, up.updated_at;
        ';
    ELSE
        EXECUTE '
        CREATE OR REPLACE VIEW public.users_complete AS
        SELECT 
            up.id,
            up.user_id,
            ''demo@example.com''::varchar as email,
            up.first_name,
            up.last_name,
            up.phone,
            up.avatar_url,
            up.is_active,
            up.last_login_at,
            up.created_at,
            up.updated_at,
            array_agg(DISTINCT ur.name) FILTER (WHERE ur.name IS NOT NULL) as roles,
            array_agg(DISTINCT uperm.name) FILTER (WHERE uperm.name IS NOT NULL) as permissions
        FROM public.user_profiles up
        LEFT JOIN public.user_role_assignments ura ON up.user_id = ura.user_id AND ura.is_active = true
        LEFT JOIN public.user_roles ur ON ura.role_id = ur.id
        LEFT JOIN public.user_permission_assignments upa ON up.user_id = upa.user_id AND upa.is_active = true
        LEFT JOIN public.user_permissions uperm ON upa.permission_id = uperm.id
        GROUP BY up.id, up.user_id, up.first_name, up.last_name, up.phone, up.avatar_url, 
                 up.is_active, up.last_login_at, up.created_at, up.updated_at;
        ';
    END IF;
END $$;

-- Función para obtener estadísticas de usuarios
CREATE OR REPLACE FUNCTION public.get_user_stats()
RETURNS TABLE (
    total_users bigint,
    active_users bigint,
    inactive_users bigint,
    verified_users bigint,
    users_with_roles bigint,
    total_sessions bigint,
    active_sessions bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Solo los admins pueden ver estadísticas
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'No tienes permisos para ver las estadísticas de usuarios';
    END IF;
    
    RETURN QUERY
    SELECT 
        (SELECT count(*) FROM public.user_profiles)::bigint as total_users,
        (SELECT count(*) FROM public.user_profiles WHERE is_active = true)::bigint as active_users,
        (SELECT count(*) FROM public.user_profiles WHERE is_active = false)::bigint as inactive_users,
        (SELECT count(*) FROM public.user_profiles WHERE email_verified = true)::bigint as verified_users,
        (SELECT count(DISTINCT user_id) FROM public.user_role_assignments WHERE is_active = true)::bigint as users_with_roles,
        (SELECT count(*) FROM public.user_sessions)::bigint as total_sessions,
        (SELECT count(*) FROM public.user_sessions WHERE is_active = true)::bigint as active_sessions;
END;
$$;

-- Triggers para actualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Aplicar trigger a las tablas que lo necesitan
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email_verified ON public.user_profiles(email_verified);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user_id ON public.user_role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id ON public.user_role_assignments(role_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_is_active ON public.user_role_assignments(is_active);

CREATE INDEX IF NOT EXISTS idx_user_permission_assignments_user_id ON public.user_permission_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_assignments_permission_id ON public.user_permission_assignments(permission_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON public.user_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_token ON public.user_sessions(session_token);

CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_activity_type ON public.user_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON public.user_activities(created_at);

-- Comentarios para documentación
COMMENT ON TABLE public.user_profiles IS 'Perfiles de usuario que extienden auth.users';
COMMENT ON TABLE public.user_roles IS 'Roles del sistema con permisos asociados';
COMMENT ON TABLE public.user_role_assignments IS 'Asignación de roles a usuarios';
COMMENT ON TABLE public.user_permissions IS 'Permisos específicos del sistema';
COMMENT ON TABLE public.user_permission_assignments IS 'Asignación de permisos individuales a usuarios';
COMMENT ON TABLE public.user_sessions IS 'Sesiones activas de usuarios';
COMMENT ON TABLE public.user_activities IS 'Log de actividades de usuarios';
COMMENT ON TABLE public.user_settings IS 'Configuraciones personalizadas de usuarios';

COMMENT ON FUNCTION public.is_admin() IS 'Verifica si el usuario actual tiene rol de administrador';
COMMENT ON FUNCTION public.can_access_user_data(uuid) IS 'Verifica si el usuario actual puede acceder a datos de otro usuario';
COMMENT ON FUNCTION public.get_user_profile(uuid) IS 'Obtiene el perfil completo de un usuario con roles y permisos';
COMMENT ON FUNCTION public.get_user_stats() IS 'Obtiene estadísticas generales de usuarios (solo admins)';

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '=== MIGRACIÓN DE GESTIÓN DE USUARIOS COMPLETADA ===';
    RAISE NOTICE 'Tablas creadas: user_profiles, user_roles, user_role_assignments, user_permissions, user_permission_assignments, user_sessions, user_activities, user_settings';
    RAISE NOTICE 'Funciones creadas: is_admin(), can_access_user_data(), get_user_profile(), get_user_stats()';
    RAISE NOTICE 'Vista creada: users_complete';
    RAISE NOTICE 'RLS habilitado en todas las tablas con políticas de seguridad';
    RAISE NOTICE 'Índices creados para optimizar consultas';
    RAISE NOTICE 'Triggers configurados para updated_at';
    RAISE NOTICE 'Roles por defecto: admin, manager, employee, viewer';
    RAISE NOTICE 'Permisos por defecto: read, write, delete, manage_users, manage_inventory, view_reports, manage_settings';
END $$;
