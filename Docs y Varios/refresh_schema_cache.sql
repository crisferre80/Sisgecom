-- =====================================================
-- SCRIPT PARA REFRESCAR CACHÉ DE ESQUEMA
-- Ejecutar DESPUÉS del script principal si persisten errores
-- =====================================================

-- Refrescar el caché de esquema de PostgREST
NOTIFY pgrst, 'reload schema';

-- Verificar que todas las columnas necesarias existen en user_profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Si alguna columna falta, agregarla manualmente:
-- ALTER TABLE public.user_profiles ADD COLUMN first_name varchar(50);
-- ALTER TABLE public.user_profiles ADD COLUMN last_name varchar(50);
-- ALTER TABLE public.user_profiles ADD COLUMN full_name varchar(100);
-- ALTER TABLE public.user_profiles ADD COLUMN phone varchar(20);
-- ALTER TABLE public.user_profiles ADD COLUMN address text;
-- ALTER TABLE public.user_profiles ADD COLUMN city varchar(50);
-- ALTER TABLE public.user_profiles ADD COLUMN country varchar(50);
-- ALTER TABLE public.user_profiles ADD COLUMN avatar_url text;
-- ALTER TABLE public.user_profiles ADD COLUMN created_at timestamptz DEFAULT now();
-- ALTER TABLE public.user_profiles ADD COLUMN updated_at timestamptz DEFAULT now();

-- Volver a notificar después de cualquier cambio
-- NOTIFY pgrst, 'reload schema';
