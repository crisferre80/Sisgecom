-- Migración para Gestión de Usuarios
-- Fecha: 2025-06-29
-- Descripción: Crear tablas y funciones para gestión completa de usuarios

-- 1. Modificar tabla auth.users existente (si es necesario)
-- Ya existe en Supabase, pero podemos agregar campos custom

-- 2. Crear tabla de perfiles de usuario
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

-- 3. Crear tabla de roles y permisos
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(20) DEFAULT 'viewer' CHECK (role IN ('admin', 'manager', 'cashier', 'viewer')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true
);

-- 4. Crear tabla de permisos específicos
CREATE TABLE IF NOT EXISTS public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    module VARCHAR(50) NOT NULL CHECK (module IN ('inventory', 'sales', 'payments', 'users', 'reports', 'settings')),
    action VARCHAR(20) NOT NULL CHECK (action IN ('read', 'write', 'delete', 'admin')),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES auth.users(id) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, module, action)
);

-- 5. Crear tabla de sesiones de usuario
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

-- 6. Crear tabla de actividad de usuarios
CREATE TABLE IF NOT EXISTS public.user_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    action VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Crear índices para mejor rendimiento
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

-- 8. Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. Crear triggers para updated_at
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. Crear función para registrar actividades automáticamente
CREATE OR REPLACE FUNCTION log_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo registrar para operaciones específicas y cuando tengamos el campo updated_by
    IF TG_OP = 'INSERT' THEN
        -- Para INSERT, verificar si tenemos created_by
        IF TG_TABLE_NAME = 'user_profiles' AND NEW.updated_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.updated_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        ELSIF TG_TABLE_NAME = 'user_roles' AND NEW.assigned_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.assigned_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        ELSIF TG_TABLE_NAME = 'user_permissions' AND NEW.granted_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.granted_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Para UPDATE, verificar si tenemos updated_by
        IF TG_TABLE_NAME = 'user_profiles' AND NEW.updated_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.updated_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        ELSIF TG_TABLE_NAME = 'user_roles' AND NEW.assigned_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.assigned_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        ELSIF TG_TABLE_NAME = 'user_permissions' AND NEW.granted_by IS NOT NULL THEN
            INSERT INTO public.user_activities (user_id, action, module, details)
            VALUES (
                NEW.granted_by,
                TG_OP || ' ' || TG_TABLE_NAME,
                'users',
                jsonb_build_object('target_user_id', NEW.user_id, 'table', TG_TABLE_NAME)
            );
        END IF;
    END IF;
    
    RETURN NULL;
END;
$$ language 'plpgsql';

-- 11. Crear triggers para log de actividades
CREATE TRIGGER log_user_profiles_activity
    AFTER INSERT OR UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION log_user_activity();

CREATE TRIGGER log_user_roles_activity
    AFTER INSERT OR UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION log_user_activity();

CREATE TRIGGER log_user_permissions_activity
    AFTER INSERT OR UPDATE ON public.user_permissions
    FOR EACH ROW EXECUTE FUNCTION log_user_activity();

-- 12. Crear vista para datos completos de usuario
CREATE OR REPLACE VIEW public.users_complete AS
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created_at,
    au.last_sign_in_at as last_login,
    up.name,
    up.phone,
    up.avatar_url,
    up.status,
    up.department,
    up.employee_id,
    up.hire_date,
    up.created_at,
    up.updated_at,
    ur.role,
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

-- 13. Crear función para obtener estadísticas de usuarios
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
        (SELECT COUNT(*) FROM public.user_profiles WHERE status != 'inactive')::BIGINT as total_users,
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

-- 14. Habilitar RLS (Row Level Security) para las tablas
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- 15. Crear políticas de seguridad RLS
-- Solo admins pueden ver todos los perfiles, otros solo el suyo
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- Solo admins pueden modificar perfiles
CREATE POLICY "Admins can modify user profiles" ON public.user_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- Permitir que usuarios autenticados creen su propio perfil
CREATE POLICY "Users can create own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Solo admins pueden gestionar roles
CREATE POLICY "Admins can manage roles" ON public.user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- Solo admins pueden gestionar permisos
CREATE POLICY "Admins can manage permissions" ON public.user_permissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- Usuarios pueden ver sus propias sesiones, admins pueden ver todas
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- Usuarios pueden ver sus propias actividades, admins pueden ver todas
CREATE POLICY "Users can view own activities" ON public.user_activities
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role = 'admin' AND ur.is_active = true
        )
    );

-- 16. Crear usuario admin por defecto (opcional, comentado por seguridad)
/*
-- Descomentar solo si necesitas crear un usuario admin inicial
INSERT INTO public.user_profiles (user_id, name, status, department, employee_id)
VALUES (
    '00000000-0000-0000-0000-000000000000', -- Reemplazar con UUID real
    'Administrador',
    'active',
    'Administración',
    'ADMIN001'
);

INSERT INTO public.user_roles (user_id, role, assigned_by)
VALUES (
    '00000000-0000-0000-0000-000000000000', -- Reemplazar con UUID real
    'admin',
    '00000000-0000-0000-0000-000000000000'
);
*/

-- Comentarios finales
COMMENT ON TABLE public.user_profiles IS 'Perfiles extendidos de usuarios del sistema';
COMMENT ON TABLE public.user_roles IS 'Roles asignados a los usuarios';
COMMENT ON TABLE public.user_permissions IS 'Permisos específicos por módulo para usuarios';
COMMENT ON TABLE public.user_sessions IS 'Sesiones activas de usuarios';
COMMENT ON TABLE public.user_activities IS 'Log de actividades de usuarios en el sistema';
