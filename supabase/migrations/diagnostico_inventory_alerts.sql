-- Script de diagnóstico para verificar el estado de las tablas de inventario

-- Verificar si la tabla inventory_alerts existe
SELECT 
    table_name, 
    table_type,
    is_insertable_into
FROM information_schema.tables 
WHERE table_name = 'inventory_alerts'
    AND table_schema = 'public';

-- Verificar si la tabla products existe (requerida para la FK)
SELECT 
    table_name, 
    table_type,
    is_insertable_into
FROM information_schema.tables 
WHERE table_name = 'products'
    AND table_schema = 'public';

-- Si las tablas existen, verificar las columnas de inventory_alerts
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'inventory_alerts'
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar si hay datos en inventory_alerts
SELECT COUNT(*) as total_alerts FROM inventory_alerts;

-- Verificar las políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'inventory_alerts';

-- Verificar si el usuario tiene permisos
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'inventory_alerts'
    AND table_schema = 'public';

-- Verificar las funciones relacionadas con alertas
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%inventory_alert%'
    AND routine_schema = 'public';

-- Mensaje de estado
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inventory_alerts') 
        THEN 'Tabla inventory_alerts existe'
        ELSE 'ERROR: Tabla inventory_alerts NO existe'
    END as status;
