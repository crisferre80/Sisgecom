-- Script para resolver conflicto de función generate_sale_number
-- ERROR: 42P13: cannot change return type of existing function

-- Eliminar todas las funciones relacionadas con generate_sale_number
DROP FUNCTION IF EXISTS public.generate_sale_number() CASCADE;
DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;

-- Eliminar triggers relacionados
DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;

-- Verificar que las funciones fueron eliminadas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'generate_sale_number' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) THEN
        RAISE NOTICE 'Función generate_sale_number eliminada exitosamente';
    ELSE
        RAISE WARNING 'La función generate_sale_number aún existe';
    END IF;
END $$;

-- Mensaje final
SELECT 'Limpieza de funciones completada - Ahora puede aplicar las migraciones' as status;
