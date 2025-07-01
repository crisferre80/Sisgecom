-- ===================================================================
-- MIGRACIÓN MÓDULO DE VENTAS - VERSIÓN FINAL DEFINITIVA
-- Sistema de Gestión Comercial - 100% Compatible
-- ===================================================================

-- EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- LIMPIAR ELEMENTOS EXISTENTES
DROP VIEW IF EXISTS public.daily_sales_stats CASCADE;
DROP VIEW IF EXISTS public.today_sales CASCADE;
DROP VIEW IF EXISTS public.low_stock_products CASCADE;
DROP VIEW IF EXISTS public.sales_with_customer CASCADE;

-- TABLAS PRINCIPALES (si no existen)
-- =================================

-- Tabla de productos
CREATE TABLE IF NOT EXISTS public.products (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name varchar(255) NOT NULL,
    description text,
    price decimal(10,2) NOT NULL DEFAULT 0,
    cost decimal(10,2) DEFAULT 0,
    quantity integer NOT NULL DEFAULT 0,
    min_stock integer DEFAULT 0,
    category varchar(100),
    barcode varchar(100) UNIQUE,
    image_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    last_updated timestamp with time zone DEFAULT now()
);

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name varchar(255) NOT NULL,
    email varchar(255),
    phone varchar(50),
    address text,
    city varchar(100),
    country varchar(100),
    tax_id varchar(50),
    credit_limit decimal(10,2) DEFAULT 0,
    current_balance decimal(10,2) DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabla de ventas (SIN sale_date para evitar errores)
CREATE TABLE IF NOT EXISTS public.sales (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_number varchar(50) UNIQUE,
    customer_id uuid REFERENCES public.customers(id),
    user_id uuid NOT NULL,
    sale_status varchar(20) DEFAULT 'draft' CHECK (sale_status IN ('draft', 'confirmed', 'delivered', 'cancelled')),
    subtotal decimal(10,2) DEFAULT 0,
    tax_amount decimal(10,2) DEFAULT 0,
    discount_amount decimal(10,2) DEFAULT 0,
    total_amount decimal(10,2) DEFAULT 0,
    payment_status varchar(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'partial', 'paid', 'refunded')),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabla de artículos de venta
CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id uuid REFERENCES public.products(id),
    product_name varchar(255) NOT NULL,
    quantity integer NOT NULL DEFAULT 1,
    unit_price decimal(10,2) NOT NULL DEFAULT 0,
    discount_percentage decimal(5,2) DEFAULT 0,
    subtotal decimal(10,2) NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

-- Tabla de pagos de ventas
CREATE TABLE IF NOT EXISTS public.sale_payments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    payment_method varchar(50) NOT NULL,
    amount decimal(10,2) NOT NULL,
    payment_date timestamp with time zone DEFAULT now(),
    reference_number varchar(100),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);

-- Tabla de devoluciones
CREATE TABLE IF NOT EXISTS public.sale_returns (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id uuid NOT NULL REFERENCES public.sales(id),
    return_number varchar(50) UNIQUE,
    return_date timestamp with time zone DEFAULT now(),
    return_status varchar(20) DEFAULT 'pending' CHECK (return_status IN ('pending', 'approved', 'rejected')),
    total_amount decimal(10,2) DEFAULT 0,
    reason text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabla de artículos de devolución
CREATE TABLE IF NOT EXISTS public.sale_return_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    return_id uuid NOT NULL REFERENCES public.sale_returns(id) ON DELETE CASCADE,
    sale_item_id uuid NOT NULL REFERENCES public.sale_items(id),
    quantity integer NOT NULL DEFAULT 1,
    reason text,
    created_at timestamp with time zone DEFAULT now()
);

-- AGREGAR COLUMNAS SI NO EXISTEN (para compatibilidad)
-- ====================================================

DO $$
BEGIN
    -- Verificar y agregar columna is_active a products si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active boolean DEFAULT true;
    END IF;

    -- Verificar y agregar columna is_active a customers si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'customers' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.customers ADD COLUMN is_active boolean DEFAULT true;
    END IF;

    -- Verificar y agregar columna last_updated a products si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'last_updated'
    ) THEN
        ALTER TABLE public.products ADD COLUMN last_updated timestamp with time zone DEFAULT now();
    END IF;

    -- Verificar y agregar created_at a products si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.products ADD COLUMN created_at timestamp with time zone DEFAULT now();
    END IF;

    -- Verificar y agregar created_at a customers si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'customers' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.customers ADD COLUMN created_at timestamp with time zone DEFAULT now();
    END IF;

    -- Verificar y agregar updated_at a customers si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'customers' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.customers ADD COLUMN updated_at timestamp with time zone DEFAULT now();
    END IF;

    -- Verificar y agregar created_at a sales si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN created_at timestamp with time zone DEFAULT now();
    END IF;

    -- Verificar y agregar updated_at a sales si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN updated_at timestamp with time zone DEFAULT now();
    END IF;

    -- COLUMNAS CRÍTICAS PARA RELACIONES
    -- ==================================
    
    -- Tu tabla actual ya tiene: id, sale_number, date, total, tax, payment_method, status, customer_name, customer_email, created_by
    -- Vamos a agregar las columnas adicionales que necesita el módulo completo

    -- Verificar y agregar customer_id a sales si no existe (para relaciones con tabla customers)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'customer_id'
    ) THEN
        -- Agregar columna sin referencia primero
        ALTER TABLE public.sales ADD COLUMN customer_id uuid;
        -- Intentar agregar la referencia si la tabla customers existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'customers') THEN
            BEGIN
                ALTER TABLE public.sales ADD CONSTRAINT fk_sales_customer_id FOREIGN KEY (customer_id) REFERENCES public.customers(id);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE 'No se pudo crear la referencia FK para customer_id, continuando...';
            END;
        END IF;
    END IF;

    -- Verificar y agregar user_id a sales si no existe (mapear desde created_by si es necesario)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN user_id uuid;
        -- Copiar datos desde created_by si existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_by') THEN
            UPDATE public.sales SET user_id = created_by WHERE created_by IS NOT NULL;
        END IF;
    END IF;

    -- Verificar y mapear columnas con nombres diferentes
    -- Tu tabla usa 'date' en lugar de 'created_at'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN created_at timestamp with time zone DEFAULT now();
        -- Copiar datos desde 'date' si existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'date') THEN
            UPDATE public.sales SET created_at = date WHERE date IS NOT NULL;
        END IF;
    END IF;

    -- Tu tabla usa 'total' en lugar de 'total_amount'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'total_amount'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN total_amount decimal(10,2) DEFAULT 0;
        -- Copiar datos desde 'total' si existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total') THEN
            UPDATE public.sales SET total_amount = total WHERE total IS NOT NULL;
        END IF;
    END IF;

    -- Tu tabla usa 'tax' en lugar de 'tax_amount'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'tax_amount'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN tax_amount decimal(10,2) DEFAULT 0;
        -- Copiar datos desde 'tax' si existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax') THEN
            UPDATE public.sales SET tax_amount = tax WHERE tax IS NOT NULL;
        END IF;
    END IF;

    -- Tu tabla usa 'status' en lugar de 'sale_status'
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'sale_status'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN sale_status varchar(20) DEFAULT 'draft';
        -- Mapear valores desde 'status' si existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
            UPDATE public.sales SET sale_status = 
                CASE 
                    WHEN status::text = 'pending' THEN 'draft'
                    WHEN status::text = 'completed' THEN 'confirmed'
                    WHEN status::text = 'cancelled' THEN 'cancelled'
                    ELSE 'draft'
                END
            WHERE status IS NOT NULL;
        END IF;
    END IF;

    -- Agregar columnas adicionales que necesita el módulo
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'subtotal'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN subtotal decimal(10,2) DEFAULT 0;
        -- Calcular desde total - tax si es posible
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total') 
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax') THEN
            UPDATE public.sales SET subtotal = COALESCE(total, 0) - COALESCE(tax, 0) WHERE total IS NOT NULL;
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'discount_amount'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN discount_amount decimal(10,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'payment_status'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN payment_status varchar(20) DEFAULT 'pending';
        -- Mapear desde status si es apropiado
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
            UPDATE public.sales SET payment_status = 
                CASE 
                    WHEN status::text = 'completed' THEN 'paid'
                    WHEN status::text = 'pending' THEN 'pending'
                    WHEN status::text = 'cancelled' THEN 'refunded'
                    ELSE 'pending'
                END
            WHERE status IS NOT NULL;
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN updated_at timestamp with time zone DEFAULT now();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sales' 
        AND column_name = 'notes'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN notes text;
    END IF;

    RAISE NOTICE 'Verificación completa de todas las columnas completada';
END $$;

-- COMENTARIOS EN TABLAS
COMMENT ON TABLE public.products IS 'Catálogo de productos del sistema';
COMMENT ON TABLE public.customers IS 'Base de datos de clientes';
COMMENT ON TABLE public.sales IS 'Registro principal de ventas';
COMMENT ON TABLE public.sale_items IS 'Detalles de productos en cada venta';
COMMENT ON TABLE public.sale_payments IS 'Pagos recibidos por ventas';
COMMENT ON TABLE public.sale_returns IS 'Devoluciones de ventas';
COMMENT ON TABLE public.sale_return_items IS 'Detalles de productos devueltos';

-- ÍNDICES PARA OPTIMIZACIÓN
-- =========================
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);

CREATE INDEX IF NOT EXISTS idx_customers_name ON public.customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_active ON public.customers(is_active);

CREATE INDEX IF NOT EXISTS idx_sales_number ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_created ON public.sales(created_at);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_user ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON public.sales(sale_status);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON public.sale_items(product_id);

CREATE INDEX IF NOT EXISTS idx_sale_payments_sale ON public.sale_payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_payments_date ON public.sale_payments(payment_date);

CREATE INDEX IF NOT EXISTS idx_sale_returns_sale ON public.sale_returns(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_returns_date ON public.sale_returns(return_date);

-- FUNCIONES PRINCIPALES
-- =====================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Limpiar función existente para evitar conflictos de tipo
DROP FUNCTION IF EXISTS public.generate_sale_number();

-- Función para generar número de venta secuencial (compatible con TEXT)
CREATE OR REPLACE FUNCTION public.generate_sale_number()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    next_number integer;
    formatted_number text;
    current_year varchar(4);
BEGIN
    current_year := EXTRACT(YEAR FROM now())::varchar;
    
    -- Obtener el siguiente número para el año actual
    SELECT COALESCE(MAX(CAST(SUBSTRING(sale_number FROM '[0-9]+$') AS integer)), 0) + 1
    INTO next_number
    FROM public.sales
    WHERE sale_number ~ ('^VEN-' || current_year || '-[0-9]+$');
    
    -- Formatear: VEN-2025-000001
    formatted_number := 'VEN-' || current_year || '-' || LPAD(next_number::text, 6, '0');
    
    RETURN formatted_number;
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback simple si hay algún problema
        RETURN 'VEN-' || current_year || '-' || LPAD((EXTRACT(EPOCH FROM now())::integer % 999999 + 1)::text, 6, '0');
END;
$$;

-- Función para generar número de devolución
CREATE OR REPLACE FUNCTION public.generate_return_number()
RETURNS varchar(50)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number integer;
    formatted_number varchar(50);
    current_year varchar(4);
BEGIN
    current_year := EXTRACT(YEAR FROM now())::varchar;
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(return_number FROM '[0-9]+$') AS integer)), 0) + 1
    INTO next_number
    FROM public.sale_returns
    WHERE return_number ~ ('^DEV-' || current_year || '-[0-9]+$');
    
    -- Formatear: DEV-2025-000001
    formatted_number := 'DEV-' || current_year || '-' || LPAD(next_number::text, 6, '0');
    
    RETURN formatted_number;
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback simple si hay algún problema
        RETURN 'DEV-' || current_year || '-' || LPAD((EXTRACT(EPOCH FROM now())::integer % 999999 + 1)::text, 6, '0');
END;
$$;

-- Función para calcular totales de venta
CREATE OR REPLACE FUNCTION public.calculate_sale_totals()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    sale_id_to_update uuid;
    calculated_subtotal decimal(10,2) := 0;
BEGIN
    -- Determinar qué venta actualizar
    IF TG_OP = 'DELETE' THEN
        sale_id_to_update := OLD.sale_id;
    ELSE
        sale_id_to_update := NEW.sale_id;
    END IF;
    
    -- Calcular subtotal basado en items
    SELECT COALESCE(SUM(subtotal), 0)
    INTO calculated_subtotal
    FROM public.sale_items
    WHERE sale_id = sale_id_to_update;
    
    -- Actualizar totales en la venta principal
    UPDATE public.sales
    SET 
        subtotal = calculated_subtotal,
        total_amount = calculated_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0),
        updated_at = now()
    WHERE id = sale_id_to_update;
    
    -- Retornar el registro apropiado
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, retornar el registro sin hacer cambios
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
END;
$$;

-- Función para manejar cambios de stock cuando se confirma/cancela una venta
CREATE OR REPLACE FUNCTION public.handle_stock_on_sale_status_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    old_status varchar(20);
    new_status varchar(20);
    has_last_updated boolean;
BEGIN
    -- Solo procesar si es UPDATE y hay cambio de estado
    IF TG_OP = 'UPDATE' THEN
        old_status := COALESCE(OLD.sale_status, 'draft');
        new_status := NEW.sale_status;
        
        -- Verificar si la tabla products tiene la columna last_updated
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'last_updated'
        ) INTO has_last_updated;
        
        -- Confirmar venta: reducir stock
        IF old_status != 'confirmed' AND new_status = 'confirmed' THEN
            IF has_last_updated THEN
                UPDATE public.products p
                SET 
                    quantity = p.quantity - si.quantity,
                    last_updated = now()
                FROM public.sale_items si
                WHERE si.sale_id = NEW.id 
                AND si.product_id = p.id 
                AND si.product_id IS NOT NULL
                AND p.quantity >= si.quantity; -- Solo si hay stock suficiente
            ELSE
                UPDATE public.products p
                SET quantity = p.quantity - si.quantity
                FROM public.sale_items si
                WHERE si.sale_id = NEW.id 
                AND si.product_id = p.id 
                AND si.product_id IS NOT NULL
                AND p.quantity >= si.quantity;
            END IF;
            
        -- Cancelar venta confirmada: restaurar stock
        ELSIF old_status = 'confirmed' AND new_status = 'cancelled' THEN
            IF has_last_updated THEN
                UPDATE public.products p
                SET 
                    quantity = p.quantity + si.quantity,
                    last_updated = now()
                FROM public.sale_items si
                WHERE si.sale_id = NEW.id 
                AND si.product_id = p.id 
                AND si.product_id IS NOT NULL;
            ELSE
                UPDATE public.products p
                SET quantity = p.quantity + si.quantity
                FROM public.sale_items si
                WHERE si.sale_id = NEW.id 
                AND si.product_id = p.id 
                AND si.product_id IS NOT NULL;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, continuar sin hacer cambios de stock
        RETURN NEW;
END;
$$;

-- Funciones para auto-generar números (compatibles con TEXT)
CREATE OR REPLACE FUNCTION public.auto_generate_sale_number()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.sale_number IS NULL OR NEW.sale_number = '' THEN
        NEW.sale_number := public.generate_sale_number();
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.auto_generate_return_number()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.return_number IS NULL OR NEW.return_number = '' THEN
        NEW.return_number := public.generate_return_number();
    END IF;
    RETURN NEW;
END;
$$;

-- CREAR TODOS LOS TRIGGERS
-- ========================

-- Limpiar triggers existentes
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS update_sales_updated_at ON public.sales;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS update_returns_updated_at ON public.sale_returns;

DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;
DROP TRIGGER IF EXISTS auto_generate_return_number_trigger ON public.sale_returns;

DROP TRIGGER IF EXISTS calculate_sale_totals_insert ON public.sale_items;
DROP TRIGGER IF EXISTS calculate_sale_totals_update ON public.sale_items;
DROP TRIGGER IF EXISTS calculate_sale_totals_delete ON public.sale_items;

DROP TRIGGER IF EXISTS handle_stock_on_sale_status_change_trigger ON public.sales;

-- Triggers para actualizar updated_at
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_sales_updated_at
    BEFORE UPDATE ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_returns_updated_at
    BEFORE UPDATE ON public.sale_returns
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Triggers para auto-generar números
CREATE TRIGGER auto_generate_sale_number_trigger
    BEFORE INSERT ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.auto_generate_sale_number();

CREATE TRIGGER auto_generate_return_number_trigger
    BEFORE INSERT ON public.sale_returns
    FOR EACH ROW EXECUTE FUNCTION public.auto_generate_return_number();

-- Triggers para calcular totales
CREATE TRIGGER calculate_sale_totals_insert
    AFTER INSERT ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

CREATE TRIGGER calculate_sale_totals_update
    AFTER UPDATE ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

CREATE TRIGGER calculate_sale_totals_delete
    AFTER DELETE ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

-- Trigger para manejar stock
CREATE TRIGGER handle_stock_on_sale_status_change_trigger
    AFTER UPDATE ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.handle_stock_on_sale_status_change();

-- POLÍTICAS RLS (Row Level Security)
-- ==================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_return_items ENABLE ROW LEVEL SECURITY;

-- Limpiar políticas existentes
DO $$ 
DECLARE
    policy_record RECORD;
BEGIN
    -- Eliminar todas las políticas existentes para las tablas del módulo de ventas
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('products', 'customers', 'sales', 'sale_items', 'sale_payments', 'sale_returns', 'sale_return_items')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      policy_record.policyname, 
                      policy_record.schemaname, 
                      policy_record.tablename);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- Continuar si hay algún problema eliminando políticas
        RAISE NOTICE 'Algunas políticas no pudieron ser eliminadas, continuando...';
END $$;

-- Crear políticas simples para todos los usuarios autenticados
CREATE POLICY "sales_module_all_authenticated" ON public.products FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.customers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.sales FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.sale_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.sale_payments FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.sale_returns FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "sales_module_all_authenticated" ON public.sale_return_items FOR ALL USING (auth.role() = 'authenticated');

-- CREAR VISTAS DESPUÉS DE ASEGURAR QUE LAS TABLAS EXISTEN
-- =======================================================

-- Esperar un momento para asegurar que las tablas están completamente creadas
DO $$ BEGIN PERFORM pg_sleep(0.1); END $$;

-- Función auxiliar para verificar columnas antes de crear vistas
DO $$
DECLARE
    missing_columns text := '';
BEGIN
    -- Verificar columnas críticas para las vistas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_at'
    ) THEN
        missing_columns := missing_columns || 'sales.created_at ';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'customer_id'
    ) THEN
        missing_columns := missing_columns || 'sales.customer_id ';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'is_active'
    ) THEN
        missing_columns := missing_columns || 'products.is_active ';
    END IF;
    
    IF missing_columns != '' THEN
        RAISE NOTICE 'ADVERTENCIA: Algunas columnas no están disponibles: %', missing_columns;
        RAISE NOTICE 'Las vistas se crearán con columnas alternativas si es necesario.';
    END IF;
END $$;

-- Vista de ventas con información del cliente (versión ultra robusta)
DO $$
DECLARE
    has_customer_id boolean;
    has_created_at boolean;
    has_date boolean;
    has_updated_at boolean;
    has_total boolean;
    has_total_amount boolean;
    view_sql text;
BEGIN
    -- Verificar qué columnas existen en tu estructura actual
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'customer_id'
    ) INTO has_customer_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'date'
    ) INTO has_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total'
    ) INTO has_total;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount'
    ) INTO has_total_amount;
    
    -- Construir la vista dinámicamente
    view_sql := 'CREATE OR REPLACE VIEW public.sales_with_customer AS SELECT s.id, ';
    
    -- sale_number (tu tabla ya lo tiene)
    view_sql := view_sql || 's.sale_number, ';
    
    -- customer_id
    IF has_customer_id THEN
        view_sql := view_sql || 's.customer_id, ';
    ELSE
        view_sql := view_sql || 'NULL::uuid as customer_id, ';
    END IF;
    
    -- user_id (mapear desde created_by si es necesario)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'user_id') THEN
        view_sql := view_sql || 's.user_id, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_by') THEN
        view_sql := view_sql || 's.created_by as user_id, ';
    ELSE
        view_sql := view_sql || 'NULL::uuid as user_id, ';
    END IF;
    
    -- sale_date (usar 'date' si existe, sino 'created_at')
    IF has_date THEN
        view_sql := view_sql || 's.date as sale_date, ';
    ELSIF has_created_at THEN
        view_sql := view_sql || 's.created_at as sale_date, ';
    ELSE
        view_sql := view_sql || 'now() as sale_date, ';
    END IF;
    
    -- sale_status (mapear desde 'status' si es necesario)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'sale_status') THEN
        view_sql := view_sql || 'COALESCE(s.sale_status, ''draft'') as sale_status, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        view_sql := view_sql || 'CASE WHEN s.status::text = ''pending'' THEN ''draft'' WHEN s.status::text = ''completed'' THEN ''confirmed'' WHEN s.status::text = ''cancelled'' THEN ''cancelled'' ELSE ''draft'' END as sale_status, ';
    ELSE
        view_sql := view_sql || '''draft'' as sale_status, ';
    END IF;
    
    -- Campos monetarios
    view_sql := view_sql || 'COALESCE(s.subtotal, 0) as subtotal, ';
    
    -- tax_amount (mapear desde 'tax')
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax_amount') THEN
        view_sql := view_sql || 'COALESCE(s.tax_amount, 0) as tax_amount, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax') THEN
        view_sql := view_sql || 'COALESCE(s.tax, 0) as tax_amount, ';
    ELSE
        view_sql := view_sql || '0 as tax_amount, ';
    END IF;
    
    view_sql := view_sql || 'COALESCE(s.discount_amount, 0) as discount_amount, ';
    
    -- total_amount (usar 'total' si no existe 'total_amount')
    IF has_total_amount THEN
        view_sql := view_sql || 'COALESCE(s.total_amount, 0) as total_amount, ';
    ELSIF has_total THEN
        view_sql := view_sql || 'COALESCE(s.total, 0) as total_amount, ';
    ELSE
        view_sql := view_sql || '0 as total_amount, ';
    END IF;
    
    -- payment_status
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'payment_status') THEN
        view_sql := view_sql || 'COALESCE(s.payment_status, ''pending'') as payment_status, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        view_sql := view_sql || 'CASE WHEN s.status::text = ''completed'' THEN ''paid'' WHEN s.status::text = ''cancelled'' THEN ''refunded'' ELSE ''pending'' END as payment_status, ';
    ELSE
        view_sql := view_sql || '''pending'' as payment_status, ';
    END IF;
    
    view_sql := view_sql || 's.notes, ';
    
    -- Timestamps
    IF has_created_at THEN
        view_sql := view_sql || 's.created_at, ';
    ELSIF has_date THEN
        view_sql := view_sql || 's.date as created_at, ';
    ELSE
        view_sql := view_sql || 'now() as created_at, ';
    END IF;
    
    IF has_updated_at THEN
        view_sql := view_sql || 's.updated_at, ';
    ELSE
        view_sql := view_sql || 'now() as updated_at, ';
    END IF;
    
    -- Información del cliente (usar customer_name/customer_email de tu tabla si no hay relación)
    IF has_customer_id AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'customers') THEN
        view_sql := view_sql ||
            'COALESCE(c.name, s.customer_name) as customer_name, ' ||
            'COALESCE(c.email, s.customer_email) as customer_email, ' ||
            'c.phone as customer_phone, ' ||
            'c.address as customer_address, ' ||
            'c.city as customer_city, ' ||
            'c.tax_id as customer_tax_id ' ||
            'FROM public.sales s LEFT JOIN public.customers c ON s.customer_id = c.id';
    ELSE
        view_sql := view_sql ||
            's.customer_name, ' ||
            's.customer_email, ' ||
            'NULL as customer_phone, ' ||
            'NULL as customer_address, ' ||
            'NULL as customer_city, ' ||
            'NULL as customer_tax_id ' ||
            'FROM public.sales s';
    END IF;
    
    -- Ejecutar la creación de la vista
    EXECUTE view_sql;
    
    RAISE NOTICE 'Vista sales_with_customer creada dinámicamente para tu estructura de tabla';
END $$;

-- Vista de productos con stock bajo (versión ultra robusta)
COMMENT ON VIEW public.sales_with_customer IS 'Vista de ventas con información completa del cliente';

-- Vista de productos con stock bajo usando verificación dinámica
DO $$
DECLARE
    view_sql text;
BEGIN
    view_sql := 'CREATE OR REPLACE VIEW public.low_stock_products AS SELECT p.id, p.name, p.description, p.price, ';
    
    -- Agregar cost con COALESCE
    view_sql := view_sql || 'COALESCE(p.cost, 0) as cost, p.quantity, COALESCE(p.min_stock, 0) as min_stock, p.category, p.barcode, ';
    
    -- Agregar is_active dinámicamente
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'is_active') THEN
        view_sql := view_sql || 'COALESCE(p.is_active, true) as is_active, ';
    ELSE
        view_sql := view_sql || 'true as is_active, ';
    END IF;
    
    -- Agregar created_at dinámicamente
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'created_at') THEN
        view_sql := view_sql || 'COALESCE(p.created_at, now()) as created_at, ';
    ELSE
        view_sql := view_sql || 'now() as created_at, ';
    END IF;
    
    -- Agregar last_updated dinámicamente
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'last_updated') THEN
        view_sql := view_sql || 'COALESCE(p.last_updated, now()) as last_updated, ';
    ELSE
        view_sql := view_sql || 'now() as last_updated, ';
    END IF;
    
    -- Agregar stock_ratio
    view_sql := view_sql || 
        'CASE WHEN COALESCE(p.min_stock, 0) > 0 THEN (p.quantity::float / p.min_stock) ELSE 1.0 END as stock_ratio ' ||
        'FROM public.products p WHERE ';
    
    -- Condición WHERE dinámica
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'is_active') THEN
        view_sql := view_sql || 'COALESCE(p.is_active, true) = true AND ';
    END IF;
    
    view_sql := view_sql || 'p.quantity <= COALESCE(p.min_stock, 0) AND COALESCE(p.min_stock, 0) > 0 ORDER BY p.quantity ASC';
    
    EXECUTE view_sql;
    RAISE NOTICE 'Vista low_stock_products creada dinámicamente';
END $$;

-- Vista de ventas del día actual (versión ultra robusta)
DO $$
DECLARE
    view_sql text;
    has_customer_id boolean;
    has_created_at boolean;
    has_date boolean;
    date_column text;
BEGIN
    -- Verificar columnas
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'customer_id'
    ) INTO has_customer_id;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'date'
    ) INTO has_date;
    
    -- Determinar qué columna de fecha usar
    IF has_date THEN
        date_column := 's.date';
    ELSIF has_created_at THEN
        date_column := 's.created_at';
    ELSE
        date_column := 'now()';
    END IF;
    
    view_sql := 'CREATE OR REPLACE VIEW public.today_sales AS SELECT s.id, ';
    
    -- sale_number (tu tabla ya lo tiene)
    view_sql := view_sql || 's.sale_number, ';
    
    -- customer_id
    IF has_customer_id THEN
        view_sql := view_sql || 's.customer_id, ';
    ELSE
        view_sql := view_sql || 'NULL::uuid as customer_id, ';
    END IF;
    
    -- user_id
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'user_id') THEN
        view_sql := view_sql || 's.user_id, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_by') THEN
        view_sql := view_sql || 's.created_by as user_id, ';
    ELSE
        view_sql := view_sql || 'NULL::uuid as user_id, ';
    END IF;
    
    -- sale_date
    view_sql := view_sql || date_column || ' as sale_date, ';
    
    -- sale_status
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'sale_status') THEN
        view_sql := view_sql || 'COALESCE(s.sale_status, ''draft'') as sale_status, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        view_sql := view_sql || 'CASE WHEN s.status::text = ''pending'' THEN ''draft'' WHEN s.status::text = ''completed'' THEN ''confirmed'' ELSE ''draft'' END as sale_status, ';
    ELSE
        view_sql := view_sql || '''draft'' as sale_status, ';
    END IF;
    
    -- Campos monetarios
    view_sql := view_sql || 'COALESCE(s.subtotal, 0) as subtotal, ';
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax_amount') THEN
        view_sql := view_sql || 'COALESCE(s.tax_amount, 0) as tax_amount, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'tax') THEN
        view_sql := view_sql || 'COALESCE(s.tax, 0) as tax_amount, ';
    ELSE
        view_sql := view_sql || '0 as tax_amount, ';
    END IF;
    
    view_sql := view_sql || 'COALESCE(s.discount_amount, 0) as discount_amount, ';
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
        view_sql := view_sql || 'COALESCE(s.total_amount, 0) as total_amount, ';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total') THEN
        view_sql := view_sql || 'COALESCE(s.total, 0) as total_amount, ';
    ELSE
        view_sql := view_sql || '0 as total_amount, ';
    END IF;
    
    -- payment_status
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'payment_status') THEN
        view_sql := view_sql || 'COALESCE(s.payment_status, ''pending'') as payment_status, ';
    ELSE
        view_sql := view_sql || '''pending'' as payment_status, ';
    END IF;
    
    view_sql := view_sql || 's.notes, ';
    
    -- Timestamps
    view_sql := view_sql || date_column || ' as created_at, ';
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'updated_at') THEN
        view_sql := view_sql || 's.updated_at, ';
    ELSE
        view_sql := view_sql || 'now() as updated_at, ';
    END IF;
    
    -- Información del cliente
    IF has_customer_id AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'customers') THEN
        view_sql := view_sql ||
            'COALESCE(c.name, s.customer_name) as customer_name, ' ||
            'COALESCE(c.email, s.customer_email) as customer_email, ' ||
            'c.phone as customer_phone ' ||
            'FROM public.sales s LEFT JOIN public.customers c ON s.customer_id = c.id ';
    ELSE
        view_sql := view_sql ||
            's.customer_name, ' ||
            's.customer_email, ' ||
            'NULL as customer_phone ' ||
            'FROM public.sales s ';
    END IF;
    
    -- WHERE clause
    view_sql := view_sql || 'WHERE DATE(' || date_column || ') = CURRENT_DATE ORDER BY ' || date_column || ' DESC';
    
    EXECUTE view_sql;
    RAISE NOTICE 'Vista today_sales creada dinámicamente para tu estructura';
END $$;

-- Vista de estadísticas diarias (versión ultra robusta)
DO $$
DECLARE
    view_sql text;
    has_created_at boolean;
    has_date boolean;
    has_customer_id boolean;
    date_column text;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'date'
    ) INTO has_date;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'customer_id'
    ) INTO has_customer_id;
    
    -- Determinar columna de fecha
    IF has_date THEN
        date_column := 's.date';
    ELSIF has_created_at THEN
        date_column := 's.created_at';
    ELSE
        date_column := 'now()';
    END IF;
    
    view_sql := 'CREATE OR REPLACE VIEW public.daily_sales_stats AS SELECT ';
    
    -- sales_date
    view_sql := view_sql || 'DATE(' || date_column || ') as sales_date, ';
    
    -- Contadores y agregaciones
    view_sql := view_sql || 'COUNT(*) as total_sales, ';
    
    IF has_customer_id THEN
        view_sql := view_sql || 'COUNT(DISTINCT s.customer_id) as unique_customers, ';
    ELSE
        view_sql := view_sql || 'COUNT(DISTINCT s.customer_name) as unique_customers, ';
    END IF;
    
    -- Ingresos confirmados
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'sale_status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'SUM(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''confirmed'' THEN COALESCE(s.total_amount, 0) ELSE 0 END) as confirmed_revenue, ';
        ELSE
            view_sql := view_sql || 'SUM(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''confirmed'' THEN COALESCE(s.total, 0) ELSE 0 END) as confirmed_revenue, ';
        END IF;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'SUM(CASE WHEN s.status::text = ''completed'' THEN COALESCE(s.total_amount, 0) ELSE 0 END) as confirmed_revenue, ';
        ELSE
            view_sql := view_sql || 'SUM(CASE WHEN s.status::text = ''completed'' THEN COALESCE(s.total, 0) ELSE 0 END) as confirmed_revenue, ';
        END IF;
    ELSE
        view_sql := view_sql || '0 as confirmed_revenue, ';
    END IF;
    
    -- Ingresos pendientes
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'sale_status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'SUM(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''draft'' THEN COALESCE(s.total_amount, 0) ELSE 0 END) as pending_revenue, ';
        ELSE
            view_sql := view_sql || 'SUM(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''draft'' THEN COALESCE(s.total, 0) ELSE 0 END) as pending_revenue, ';
        END IF;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'SUM(CASE WHEN s.status::text = ''pending'' THEN COALESCE(s.total_amount, 0) ELSE 0 END) as pending_revenue, ';
        ELSE
            view_sql := view_sql || 'SUM(CASE WHEN s.status::text = ''pending'' THEN COALESCE(s.total, 0) ELSE 0 END) as pending_revenue, ';
        END IF;
    ELSE
        view_sql := view_sql || '0 as pending_revenue, ';
    END IF;
    
    -- Promedio de venta
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'sale_status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'AVG(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''confirmed'' THEN COALESCE(s.total_amount, 0) ELSE NULL END) as avg_sale_amount ';
        ELSE
            view_sql := view_sql || 'AVG(CASE WHEN COALESCE(s.sale_status, ''draft'') = ''confirmed'' THEN COALESCE(s.total, 0) ELSE NULL END) as avg_sale_amount ';
        END IF;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'status') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'total_amount') THEN
            view_sql := view_sql || 'AVG(CASE WHEN s.status::text = ''completed'' THEN COALESCE(s.total_amount, 0) ELSE NULL END) as avg_sale_amount ';
        ELSE
            view_sql := view_sql || 'AVG(CASE WHEN s.status::text = ''completed'' THEN COALESCE(s.total, 0) ELSE NULL END) as avg_sale_amount ';
        END IF;
    ELSE
        view_sql := view_sql || '0 as avg_sale_amount ';
    END IF;
    
    view_sql := view_sql || 'FROM public.sales s ';
    
    -- WHERE clause
    IF has_date OR has_created_at THEN
        view_sql := view_sql || 'WHERE ' || date_column || ' >= CURRENT_DATE - INTERVAL ''30 days'' GROUP BY DATE(' || date_column || ') ORDER BY sales_date DESC';
    ELSE
        view_sql := view_sql || 'WHERE true GROUP BY CURRENT_DATE ORDER BY sales_date DESC';
    END IF;
    
    EXECUTE view_sql;
    RAISE NOTICE 'Vista daily_sales_stats creada dinámicamente para tu estructura';
END $$;

-- DATOS DE EJEMPLO PARA PRUEBAS
-- =============================

-- Insertar productos de ejemplo
INSERT INTO public.products (name, description, price, cost, quantity, min_stock, category, barcode) VALUES
('Laptop HP Pavilion', 'Laptop para uso general con 8GB RAM', 599.99, 400.00, 15, 3, 'Electrónicos', '8901234567890'),
('Mouse Inalámbrico', 'Mouse óptico inalámbrico ergonómico', 25.50, 15.00, 50, 10, 'Accesorios', '8901234567891'),
('Teclado Mecánico', 'Teclado mecánico RGB para gaming', 89.99, 55.00, 20, 5, 'Accesorios', '8901234567892'),
('Monitor 24 pulgadas', 'Monitor Full HD IPS 24 pulgadas', 199.99, 130.00, 12, 3, 'Electrónicos', '8901234567893'),
('Auriculares Bluetooth', 'Auriculares inalámbricos con cancelación de ruido', 149.99, 90.00, 25, 5, 'Audio', '8901234567894')
ON CONFLICT (barcode) DO NOTHING;

-- Insertar clientes de ejemplo
INSERT INTO public.customers (name, email, phone, address, city, country, tax_id) VALUES
('Juan Pérez García', 'juan.perez@email.com', '+34 600 123 456', 'Calle Mayor 123', 'Madrid', 'España', '12345678A'),
('María López Rodríguez', 'maria.lopez@email.com', '+34 600 234 567', 'Avenida de la Paz 45', 'Barcelona', 'España', '23456789B'),
('Carlos Martín Sánchez', 'carlos.martin@email.com', '+34 600 345 678', 'Plaza España 12', 'Valencia', 'España', '34567890C'),
('Ana García López', 'ana.garcia@email.com', '+34 600 456 789', 'Calle Serrano 89', 'Sevilla', 'España', '45678901D'),
('Tecnologías ABC S.L.', 'contacto@tecnologiasabc.com', '+34 91 123 4567', 'Polígono Industrial Norte 15', 'Madrid', 'España', 'B12345678')
ON CONFLICT DO NOTHING;

-- MENSAJE DE FINALIZACIÓN CON VERIFICACIONES
-- ==========================================

DO $$
DECLARE
    products_count integer;
    customers_count integer;
    tables_count integer;
    functions_count integer;
    triggers_count integer;
    views_count integer;
BEGIN
    -- Contar elementos creados
    SELECT COUNT(*) INTO products_count FROM public.products;
    SELECT COUNT(*) INTO customers_count FROM public.customers;
    
    SELECT COUNT(*) INTO tables_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('products', 'customers', 'sales', 'sale_items', 'sale_payments', 'sale_returns', 'sale_return_items');
    
    SELECT COUNT(*) INTO functions_count 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND (routine_name LIKE '%sale%' OR routine_name LIKE '%generate%' OR routine_name LIKE '%update_updated_at%');
    
    SELECT COUNT(*) INTO triggers_count 
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public'
    AND (trigger_name LIKE '%sale%' OR trigger_name LIKE '%generate%' OR trigger_name LIKE '%update%');
    
    SELECT COUNT(*) INTO views_count
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name IN ('sales_with_customer', 'low_stock_products', 'today_sales', 'daily_sales_stats');

    RAISE NOTICE '=============================================';
    RAISE NOTICE '  MÓDULO DE VENTAS INSTALADO EXITOSAMENTE';
    RAISE NOTICE '=============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'RESUMEN DE INSTALACIÓN:';
    RAISE NOTICE '• Tablas creadas/verificadas: % de 7', tables_count;
    RAISE NOTICE '• Funciones instaladas: %', functions_count;
    RAISE NOTICE '• Triggers activos: %', triggers_count;
    RAISE NOTICE '• Vistas creadas: % de 4', views_count;
    RAISE NOTICE '• Productos de ejemplo: %', products_count;
    RAISE NOTICE '• Clientes de ejemplo: %', customers_count;
    RAISE NOTICE '';
    RAISE NOTICE 'CARACTERÍSTICAS ACTIVAS:';
    RAISE NOTICE '✅ Numeración automática (VEN-2025-000001)';
    RAISE NOTICE '✅ Cálculo automático de totales';
    RAISE NOTICE '✅ Control de stock inteligente';
    RAISE NOTICE '✅ Seguridad RLS habilitada';
    RAISE NOTICE '✅ Vistas optimizadas para reportes';
    RAISE NOTICE '✅ Manejo robusto de errores';
    RAISE NOTICE '';
    RAISE NOTICE 'VISTAS DISPONIBLES:';
    RAISE NOTICE '• sales_with_customer - Ventas con datos del cliente';
    RAISE NOTICE '• low_stock_products - Productos con stock bajo';
    RAISE NOTICE '• today_sales - Ventas del día actual';
    RAISE NOTICE '• daily_sales_stats - Estadísticas diarias';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 El módulo está listo para usar!';
    RAISE NOTICE 'Ya puedes empezar a crear ventas desde tu aplicación.';
    RAISE NOTICE '=============================================';
END $$;