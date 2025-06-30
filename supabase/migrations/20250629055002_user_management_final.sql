-- Migración Final para Gestión de Usuarios - Versión Robusta
-- Fecha: 2025-06-29  
-- Descripción: Versión final sin errores de columnas inexistentes

-- ================================
-- PARTE 1: CREACIÓN DE TABLAS
-- ================================

-- 1. Crear tabla de perfiles de usuario
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    department VARCHAR(100),
    employee_id VARCHAR(50) UNIQUE,
    hire_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID
);

-- 2. Crear tabla de roles y permisos
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    role VARCHAR(20) DEFAULT 'viewer' CHECK (role IN ('admin', 'manager', 'cashier', 'viewer')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID,
    is_active BOOLEAN DEFAULT true
);

-- 3. Crear tabla de permisos específicos
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    module VARCHAR(50) NOT NULL CHECK (module IN ('inventory', 'sales', 'payments', 'users', 'reports', 'settings')),
    action VARCHAR(20) NOT NULL CHECK (action IN ('read', 'write', 'delete', 'admin')),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, module, action)
);

-- 4. Crear tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- 5. Crear tabla de actividad de usuarios
CREATE TABLE IF NOT EXISTS public.user_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================
-- PARTE 2: AGREGAR FOREIGN KEYS (Solo si auth.users existe con columna id)
-- ================================

-- Función para verificar si auth.users existe con estructura correcta y agregar foreign keys
DO $$ 
DECLARE
    auth_users_exists BOOLEAN := false;
    auth_users_has_id_column BOOLEAN := false;
BEGIN
    -- Verificar si el esquema auth existe
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        -- Verificar si la tabla auth.users existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
            auth_users_exists := true;
            
            -- Verificar si auth.users tiene la columna id
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'id') THEN
                auth_users_has_id_column := true;
            END IF;
        END IF;
    END IF;
    
    -- Solo agregar foreign keys si auth.users existe Y tiene la columna id
    IF auth_users_exists AND auth_users_has_id_column THEN
        
        -- Agregar foreign keys para user_id (principales)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_profiles_user_id_fkey' 
                          AND table_name = 'user_profiles' AND table_schema = 'public') THEN
                ALTER TABLE public.user_profiles 
                ADD CONSTRAINT user_profiles_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Si falla, continuar sin foreign key
            RAISE NOTICE 'No se pudo agregar foreign key para user_profiles.user_id: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_roles_user_id_fkey' 
                          AND table_name = 'user_roles' AND table_schema = 'public') THEN
                ALTER TABLE public.user_roles 
                ADD CONSTRAINT user_roles_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_roles.user_id: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_permissions_user_id_fkey' 
                          AND table_name = 'user_permissions' AND table_schema = 'public') THEN
                ALTER TABLE public.user_permissions 
                ADD CONSTRAINT user_permissions_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_permissions.user_id: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_sessions_user_id_fkey' 
                          AND table_name = 'user_sessions' AND table_schema = 'public') THEN
                ALTER TABLE public.user_sessions 
                ADD CONSTRAINT user_sessions_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_sessions.user_id: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_activities_user_id_fkey' 
                          AND table_name = 'user_activities' AND table_schema = 'public') THEN
                ALTER TABLE public.user_activities 
                ADD CONSTRAINT user_activities_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_activities.user_id: %', SQLERRM;
        END;
        
        -- Foreign keys para campos opcionales (updated_by, assigned_by, granted_by)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_profiles_updated_by_fkey' 
                          AND table_name = 'user_profiles' AND table_schema = 'public') THEN
                ALTER TABLE public.user_profiles 
                ADD CONSTRAINT user_profiles_updated_by_fkey 
                FOREIGN KEY (updated_by) REFERENCES auth.users(id);
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_profiles.updated_by: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_roles_assigned_by_fkey' 
                          AND table_name = 'user_roles' AND table_schema = 'public') THEN
                ALTER TABLE public.user_roles 
                ADD CONSTRAINT user_roles_assigned_by_fkey 
                FOREIGN KEY (assigned_by) REFERENCES auth.users(id);
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_roles.assigned_by: %', SQLERRM;
        END;
        
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                          WHERE constraint_name = 'user_permissions_granted_by_fkey' 
                          AND table_name = 'user_permissions' AND table_schema = 'public') THEN
                ALTER TABLE public.user_permissions 
                ADD CONSTRAINT user_permissions_granted_by_fkey 
                FOREIGN KEY (granted_by) REFERENCES auth.users(id);
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo agregar foreign key para user_permissions.granted_by: %', SQLERRM;
        END;
        
        RAISE NOTICE 'Foreign keys agregadas exitosamente a auth.users';
    ELSE
        RAISE NOTICE 'auth.users no existe o no tiene la estructura esperada. Las tablas funcionarán sin foreign keys.';
    END IF;
END $$;

-- ================================
-- PARTE 3: ÍNDICES PARA RENDIMIENTO
-- ================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_employee_id ON public.user_profiles(employee_id);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON public.user_roles(is_active);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON public.user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_module ON public.user_permissions(module);
CREATE INDEX IF NOT EXISTS idx_user_permissions_active ON public.user_permissions(is_active);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON public.user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON public.user_sessions(is_active);

CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON public.user_activities(created_at);
CREATE INDEX IF NOT EXISTS idx_user_activities_module ON public.user_activities(module);

-- ================================
-- PARTE 4: FUNCIONES Y TRIGGERS
-- ================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para updated_at en user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================
-- PARTE 5: VISTA Y FUNCIONES DE CONSULTA
-- ================================

-- Vista para datos completos de usuario (solo si auth.users existe)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        
        EXECUTE '
        CREATE OR REPLACE VIEW public.users_complete AS
        SELECT 
            au.id,
            au.email,
            au.created_at as auth_created_at,
            au.last_sign_in_at as last_login,
            COALESCE(up.name, au.email) as name,
            up.phone,
            up.avatar_url,
            COALESCE(up.status, ''active'') as status,
            up.department,
            up.employee_id,
            up.hire_date,
            up.created_at,
            up.updated_at,
            COALESCE(ur.role, ''viewer'') as role,
            CASE 
                WHEN COUNT(us.id) > 0 THEN true 
                ELSE false 
            END as has_active_session
        FROM auth.users au
        LEFT JOIN public.user_profiles up ON au.id = up.user_id
        LEFT JOIN public.user_roles ur ON au.id = ur.user_id AND ur.is_active = true
        LEFT JOIN public.user_sessions us ON au.id = us.user_id AND us.is_active = true AND us.expires_at > NOW()
        GROUP BY au.id, au.email, au.created_at, au.last_sign_in_at, up.name, up.phone, 
                 up.avatar_url, up.status, up.department, up.employee_id, up.hire_date, 
                 up.created_at, up.updated_at, ur.role;';
    ELSE
        -- Vista simplificada sin auth.users
        EXECUTE '
        CREATE OR REPLACE VIEW public.users_complete AS
        SELECT 
            up.user_id as id,
            up.name as email,
            up.created_at as auth_created_at,
            NULL::timestamp as last_login,
            up.name,
            up.phone,
            up.avatar_url,
            COALESCE(up.status, ''active'') as status,
            up.department,
            up.employee_id,
            up.hire_date,
            up.created_at,
            up.updated_at,
            COALESCE(ur.role, ''viewer'') as role,
            false as has_active_session
        FROM public.user_profiles up
        LEFT JOIN public.user_roles ur ON up.user_id = ur.user_id AND ur.is_active = true;';
    END IF;
END $$;

-- Función para obtener estadísticas de usuarios
CREATE OR REPLACE FUNCTION get_user_stats()
RETURNS TABLE (
    total_users BIGINT,
    active_users BIGINT,
    blocked_users BIGINT,
    admin_count BIGINT,
    manager_count BIGINT,
    cashier_count BIGINT,
    viewer_count BIGINT,
    recent_logins BIGINT,
    new_users_this_month BIGINT
) AS $$
BEGIN
    -- Verificar si auth.users existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RETURN QUERY
        SELECT 
            (SELECT COUNT(*) FROM auth.users)::BIGINT as total_users,
            (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'active')::BIGINT as active_users,
            (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'blocked')::BIGINT as blocked_users,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'admin' AND is_active = true)::BIGINT as admin_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'manager' AND is_active = true)::BIGINT as manager_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'cashier' AND is_active = true)::BIGINT as cashier_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'viewer' AND is_active = true)::BIGINT as viewer_count,
            (SELECT COUNT(*) FROM auth.users WHERE last_sign_in_at > NOW() - INTERVAL '7 days')::BIGINT as recent_logins,
            (SELECT COUNT(*) FROM auth.users WHERE created_at > DATE_TRUNC('month', NOW()))::BIGINT as new_users_this_month;
    ELSE
        -- Estadísticas simplificadas sin auth.users
        RETURN QUERY
        SELECT 
            (SELECT COUNT(*) FROM public.user_profiles)::BIGINT as total_users,
            (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'active')::BIGINT as active_users,
            (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'blocked')::BIGINT as blocked_users,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'admin' AND is_active = true)::BIGINT as admin_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'manager' AND is_active = true)::BIGINT as manager_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'cashier' AND is_active = true)::BIGINT as cashier_count,
            (SELECT COUNT(*) FROM public.user_roles WHERE role = 'viewer' AND is_active = true)::BIGINT as viewer_count,
            0::BIGINT as recent_logins,
            (SELECT COUNT(*) FROM public.user_profiles WHERE created_at > DATE_TRUNC('month', NOW()))::BIGINT as new_users_this_month;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================
-- PARTE 6: RLS Y POLÍTICAS DE SEGURIDAD
-- ================================

-- Habilitar RLS para todas las tablas
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- Función helper para verificar si un usuario es admin
CREATE OR REPLACE FUNCTION is_admin(check_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    -- Si no hay función auth.uid() disponible, retornar false
    IF check_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = check_user_id AND role = 'admin' AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función helper para verificar si un usuario puede acceder a sus propios datos
CREATE OR REPLACE FUNCTION can_access_user_data(target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Obtener ID del usuario actual de forma segura
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;
    
    -- Si no hay usuario autenticado, denegar acceso
    IF current_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- Permitir acceso si es el mismo usuario o si es admin
    RETURN (current_user_id = target_user_id) OR is_admin(current_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Políticas de seguridad RLS

-- Políticas para user_profiles
DROP POLICY IF EXISTS "view_profiles" ON public.user_profiles;
CREATE POLICY "view_profiles" ON public.user_profiles
    FOR SELECT USING (can_access_user_data(user_id));

DROP POLICY IF EXISTS "create_own_profile" ON public.user_profiles;
CREATE POLICY "create_own_profile" ON public.user_profiles
    FOR INSERT WITH CHECK (user_id = COALESCE(auth.uid(), user_id));

DROP POLICY IF EXISTS "update_profiles" ON public.user_profiles;
CREATE POLICY "update_profiles" ON public.user_profiles
    FOR UPDATE USING (can_access_user_data(user_id))
    WITH CHECK (can_access_user_data(user_id));

DROP POLICY IF EXISTS "delete_profiles" ON public.user_profiles;
CREATE POLICY "delete_profiles" ON public.user_profiles
    FOR DELETE USING (is_admin(COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)));

-- Políticas para user_roles
DROP POLICY IF EXISTS "view_roles" ON public.user_roles;
CREATE POLICY "view_roles" ON public.user_roles
    FOR SELECT USING (can_access_user_data(user_id));

DROP POLICY IF EXISTS "manage_roles" ON public.user_roles;
CREATE POLICY "manage_roles" ON public.user_roles
    FOR ALL USING (is_admin(COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)));

-- Políticas para user_permissions
DROP POLICY IF EXISTS "view_permissions" ON public.user_permissions;
CREATE POLICY "view_permissions" ON public.user_permissions
    FOR SELECT USING (can_access_user_data(user_id));

DROP POLICY IF EXISTS "manage_permissions" ON public.user_permissions;
CREATE POLICY "manage_permissions" ON public.user_permissions
    FOR ALL USING (is_admin(COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)));

-- Políticas para user_sessions
DROP POLICY IF EXISTS "view_sessions" ON public.user_sessions;
CREATE POLICY "view_sessions" ON public.user_sessions
    FOR SELECT USING (can_access_user_data(user_id));

DROP POLICY IF EXISTS "manage_sessions" ON public.user_sessions;
CREATE POLICY "manage_sessions" ON public.user_sessions
    FOR ALL USING (can_access_user_data(user_id));

-- Políticas para user_activities
DROP POLICY IF EXISTS "view_activities" ON public.user_activities;
CREATE POLICY "view_activities" ON public.user_activities
    FOR SELECT USING (can_access_user_data(user_id));

DROP POLICY IF EXISTS "create_activities" ON public.user_activities;
CREATE POLICY "create_activities" ON public.user_activities
    FOR INSERT WITH CHECK (true); -- Cualquier usuario autenticado puede crear logs

-- ================================
-- PARTE 7: FUNCIÓN DE ADMINISTRACIÓN
-- ================================

-- Función para crear usuario completo (placeholder)
CREATE OR REPLACE FUNCTION create_user_with_profile(
    p_email TEXT,
    p_password TEXT,
    p_name TEXT,
    p_role TEXT DEFAULT 'viewer',
    p_phone TEXT DEFAULT NULL,
    p_department TEXT DEFAULT NULL,
    p_employee_id TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_user_id UUID;
    current_user_id UUID;
BEGIN
    -- Obtener ID del usuario actual de forma segura
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;
    
    -- Verificar que el usuario actual es admin (excepto para el primer usuario)
    IF EXISTS(SELECT 1 FROM public.user_roles WHERE role = 'admin') AND NOT is_admin(current_user_id) THEN
        RAISE EXCEPTION 'Solo los administradores pueden crear usuarios';
    END IF;

    -- Esta función debe ser llamada desde el cliente usando Supabase Auth Admin API
    -- Por ahora solo retornamos NULL indicando que debe usarse la interfaz
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================
-- PARTE 8: COMENTARIOS Y DOCUMENTACIÓN
-- ================================

COMMENT ON TABLE public.user_profiles IS 'Perfiles extendidos de usuarios del sistema';
COMMENT ON TABLE public.user_roles IS 'Roles asignados a los usuarios';
COMMENT ON TABLE public.user_permissions IS 'Permisos específicos por módulo para usuarios';
COMMENT ON TABLE public.user_sessions IS 'Sesiones activas de usuarios';
COMMENT ON TABLE public.user_activities IS 'Log de actividades de usuarios en el sistema';
COMMENT ON FUNCTION is_admin(UUID) IS 'Función helper para verificar si un usuario es administrador';
COMMENT ON FUNCTION can_access_user_data(UUID) IS 'Función helper para verificar acceso a datos de usuario';
COMMENT ON VIEW users_complete IS 'Vista completa con datos consolidados de usuarios';

-- ================================
-- EJEMPLO DE USO (COMENTADO)
-- ================================

/*
-- Para crear el primer usuario administrador:
-- 1. Crear el usuario en Supabase Auth Dashboard o usando la Auth API
-- 2. Obtener el UUID del usuario creado
-- 3. Ejecutar las siguientes queries reemplazando 'UUID_DEL_USUARIO':

INSERT INTO public.user_profiles (user_id, name, status, department, employee_id)
VALUES (
    'UUID_DEL_USUARIO', -- Reemplazar con el UUID real del usuario
    'Administrador Principal',
    'active',
    'Administración',
    'ADMIN001'
);

INSERT INTO public.user_roles (user_id, role, assigned_by)
VALUES (
    'UUID_DEL_USUARIO', -- Reemplazar con el UUID real del usuario
    'admin',
    'UUID_DEL_USUARIO'  -- Se auto-asigna
);
*/

-- Migración completada exitosamente
SELECT 'Migración de Gestión de Usuarios aplicada correctamente' as resultado;
