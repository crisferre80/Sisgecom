-- Migración Corregida para Gestión de Usuarios
-- Fecha: 2025-06-29
-- Descripción: Versión corregida sin errores de dependencias circulares

-- 1. Crear tabla de perfiles de usuario
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    department VARCHAR(100),
    employee_id VARCHAR(50) UNIQUE,
    hire_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id)
);

-- 2. Crear tabla de roles y permisos
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(20) DEFAULT 'viewer' CHECK (role IN ('admin', 'manager', 'cashier', 'viewer')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true
);

-- 3. Crear tabla de permisos específicos
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    module VARCHAR(50) NOT NULL CHECK (module IN ('inventory', 'sales', 'payments', 'users', 'reports', 'settings')),
    action VARCHAR(20) NOT NULL CHECK (action IN ('read', 'write', 'delete', 'admin')),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, module, action)
);

-- 4. Crear tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
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
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    action VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Crear índices para mejor rendimiento
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

-- 7. Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. Crear triggers para updated_at
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Crear vista para datos completos de usuario
CREATE OR REPLACE VIEW public.users_complete AS
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created_at,
    au.last_sign_in_at as last_login,
    COALESCE(up.name, au.email) as name,
    up.phone,
    up.avatar_url,
    COALESCE(up.status, 'active') as status,
    up.department,
    up.employee_id,
    up.hire_date,
    up.created_at,
    up.updated_at,
    COALESCE(ur.role, 'viewer') as role,
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
         up.created_at, up.updated_at, ur.role;

-- 10. Crear función para obtener estadísticas de usuarios
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
END;
$$ LANGUAGE plpgsql;

-- 11. Habilitar RLS (Row Level Security) para las tablas
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- 12. Crear función helper para verificar si un usuario es admin
CREATE OR REPLACE FUNCTION is_admin(check_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = check_user_id AND role = 'admin' AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Crear políticas de seguridad RLS simplificadas
-- Perfiles de usuario
CREATE POLICY "view_profiles" ON public.user_profiles
    FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "create_own_profile" ON public.user_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "update_profiles" ON public.user_profiles
    FOR UPDATE USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "delete_profiles" ON public.user_profiles
    FOR DELETE USING (is_admin());

-- Roles de usuario
CREATE POLICY "view_roles" ON public.user_roles
    FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "manage_roles" ON public.user_roles
    FOR ALL USING (is_admin());

-- Permisos de usuario
CREATE POLICY "view_permissions" ON public.user_permissions
    FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "manage_permissions" ON public.user_permissions
    FOR ALL USING (is_admin());

-- Sesiones de usuario
CREATE POLICY "view_sessions" ON public.user_sessions
    FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "manage_sessions" ON public.user_sessions
    FOR ALL USING (user_id = auth.uid() OR is_admin());

-- Actividades de usuario
CREATE POLICY "view_activities" ON public.user_activities
    FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "create_activities" ON public.user_activities
    FOR INSERT WITH CHECK (true); -- Cualquier usuario autenticado puede crear logs

-- 14. Crear función para crear usuario completo
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
BEGIN
    -- Verificar que el usuario actual es admin (excepto para el primer usuario)
    IF EXISTS(SELECT 1 FROM public.user_roles WHERE role = 'admin') AND NOT is_admin() THEN
        RAISE EXCEPTION 'Solo los administradores pueden crear usuarios';
    END IF;

    -- Esta función debe ser llamada desde el cliente usando Supabase Auth Admin API
    -- Por ahora solo retornamos NULL indicando que debe usarse la interfaz
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. Comentarios finales
COMMENT ON TABLE public.user_profiles IS 'Perfiles extendidos de usuarios del sistema';
COMMENT ON TABLE public.user_roles IS 'Roles asignados a los usuarios';
COMMENT ON TABLE public.user_permissions IS 'Permisos específicos por módulo para usuarios';
COMMENT ON TABLE public.user_sessions IS 'Sesiones activas de usuarios';
COMMENT ON TABLE public.user_activities IS 'Log de actividades de usuarios en el sistema';
COMMENT ON FUNCTION is_admin(UUID) IS 'Función helper para verificar si un usuario es administrador';
COMMENT ON VIEW users_complete IS 'Vista completa con datos consolidados de usuarios';

-- 16. Ejemplo de creación de usuario admin inicial (comentado por seguridad)
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
