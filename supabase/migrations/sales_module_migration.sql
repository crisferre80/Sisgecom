-- =====================================================
-- MIGRACIÓN DEL MÓDULO DE VENTAS - VERSIÓN SEGURA
-- Para copiar y pegar en Supabase SQL Editor
-- =====================================================

-- Crear extensiones necesarias (si no existen)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- LIMPIEZA PREVIA (manejo de conflictos)
-- =====================================================

-- Solo crear un bloque de limpieza si hay problemas
DO $$
BEGIN
    -- Este bloque maneja conflictos potenciales
    RAISE NOTICE 'Iniciando migración del módulo de ventas...';
    RAISE NOTICE 'Se manejarán automáticamente cualquier conflicto de funciones o triggers existentes.';
END $$;

-- =====================================================
-- TABLAS DEL MÓDULO DE VENTAS
-- =====================================================

-- Tabla de productos (si no existe)
CREATE TABLE IF NOT EXISTS public.products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode varchar(100) UNIQUE NOT NULL,
    name varchar(255) NOT NULL,
    description text,
    price decimal(10,2) NOT NULL CHECK (price >= 0),
    quantity integer NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    min_stock integer NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
    category varchar(100) NOT NULL,
    supplier varchar(255),
    date_added timestamptz DEFAULT now(),
    last_updated timestamptz DEFAULT now(),
    is_active boolean DEFAULT true,
    created_by uuid,
    updated_by uuid
);

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code varchar(50) UNIQUE,
    first_name varchar(100) NOT NULL,
    last_name varchar(100),
    email varchar(255),
    phone varchar(20),
    address text,
    city varchar(100),
    postal_code varchar(10),
    country varchar(50) DEFAULT 'España',
    tax_id varchar(50), -- NIF/CIF
    customer_type varchar(20) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business')),
    credit_limit decimal(10,2) DEFAULT 0,
    discount_percentage decimal(5,2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    is_active boolean DEFAULT true,
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by uuid,
    updated_by uuid
);

-- Tabla principal de ventas
CREATE TABLE IF NOT EXISTS public.sales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number varchar(50) UNIQUE NOT NULL,
    customer_id uuid REFERENCES public.customers(id),
    customer_name varchar(255), -- Para ventas sin cliente registrado
    customer_email varchar(255),
    sale_date timestamptz DEFAULT now(),
    subtotal decimal(10,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    tax_amount decimal(10,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount decimal(10,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount decimal(10,2) NOT NULL CHECK (total_amount >= 0),
    payment_method varchar(50) NOT NULL DEFAULT 'cash',
    payment_status varchar(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'partial', 'completed', 'refunded')),
    sale_status varchar(20) DEFAULT 'draft' CHECK (sale_status IN ('draft', 'confirmed', 'delivered', 'cancelled')),
    notes text,
    invoice_generated boolean DEFAULT false,
    invoice_number varchar(50),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by uuid NOT NULL, -- Usuario que creó la venta
    updated_by uuid
);

-- Tabla de items de venta
CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id uuid REFERENCES public.products(id),
    product_barcode varchar(100), -- Para productos eliminados
    product_name varchar(255) NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price decimal(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_percentage decimal(5,2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount decimal(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    tax_rate decimal(5,2) DEFAULT 21.00, -- IVA estándar en España
    tax_amount decimal(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    line_total decimal(10,2) NOT NULL CHECK (line_total >= 0),
    created_at timestamptz DEFAULT now()
);

-- Tabla de pagos de ventas
CREATE TABLE IF NOT EXISTS public.sale_payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    payment_method varchar(50) NOT NULL,
    amount decimal(10,2) NOT NULL CHECK (amount > 0),
    payment_date timestamptz DEFAULT now(),
    transaction_reference varchar(255),
    notes text,
    created_at timestamptz DEFAULT now(),
    created_by uuid NOT NULL
);

-- Tabla de devoluciones
CREATE TABLE IF NOT EXISTS public.sale_returns (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    original_sale_id uuid NOT NULL REFERENCES public.sales(id),
    return_number varchar(50) UNIQUE NOT NULL,
    return_date timestamptz DEFAULT now(),
    return_reason varchar(50) NOT NULL,
    return_type varchar(20) DEFAULT 'full' CHECK (return_type IN ('full', 'partial')),
    total_refund decimal(10,2) NOT NULL CHECK (total_refund >= 0),
    refund_method varchar(50) NOT NULL,
    status varchar(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'completed', 'rejected')),
    notes text,
    created_at timestamptz DEFAULT now(),
    created_by uuid NOT NULL,
    approved_by uuid,
    approved_at timestamptz
);

-- Tabla de items devueltos
CREATE TABLE IF NOT EXISTS public.sale_return_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id uuid NOT NULL REFERENCES public.sale_returns(id) ON DELETE CASCADE,
    original_sale_item_id uuid NOT NULL REFERENCES public.sale_items(id),
    product_id uuid REFERENCES public.products(id),
    product_name varchar(255) NOT NULL,
    quantity_returned integer NOT NULL CHECK (quantity_returned > 0),
    unit_price decimal(10,2) NOT NULL,
    refund_amount decimal(10,2) NOT NULL CHECK (refund_amount >= 0),
    condition varchar(50) DEFAULT 'good' CHECK (condition IN ('good', 'damaged', 'defective')),
    restock boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- =====================================================
-- TRIGGERS Y FUNCIONES
-- =====================================================

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

-- Función para generar número de venta
-- Primero eliminar si existe con tipo diferente
DROP FUNCTION IF EXISTS public.generate_sale_number();

CREATE OR REPLACE FUNCTION public.generate_sale_number()
RETURNS varchar(50)
LANGUAGE plpgsql
AS $$
DECLARE
    year_str varchar(4);
    sequence_num integer;
    sale_number varchar(50);
BEGIN
    year_str := EXTRACT(YEAR FROM now())::varchar;
    
    -- Obtener el siguiente número de secuencia para el año actual
    SELECT COALESCE(MAX(CAST(SUBSTRING(sale_number FROM 6) AS integer)), 0) + 1
    INTO sequence_num
    FROM public.sales
    WHERE sale_number LIKE year_str || '-%';
    
    sale_number := year_str || '-' || LPAD(sequence_num::varchar, 6, '0');
    
    RETURN sale_number;
END;
$$;

-- Función para calcular totales de venta
CREATE OR REPLACE FUNCTION public.calculate_sale_totals()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    sale_subtotal decimal(10,2) := 0;
    sale_tax_amount decimal(10,2) := 0;
    sale_total decimal(10,2) := 0;
BEGIN
    -- Calcular totales basados en los items
    SELECT 
        COALESCE(SUM(line_total - tax_amount), 0),
        COALESCE(SUM(tax_amount), 0),
        COALESCE(SUM(line_total), 0)
    INTO sale_subtotal, sale_tax_amount, sale_total
    FROM public.sale_items
    WHERE sale_id = COALESCE(NEW.sale_id, OLD.sale_id);
    
    -- Actualizar la venta
    UPDATE public.sales
    SET 
        subtotal = sale_subtotal,
        tax_amount = sale_tax_amount,
        total_amount = sale_total - COALESCE(discount_amount, 0),
        updated_at = now()
    WHERE id = COALESCE(NEW.sale_id, OLD.sale_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Función para actualizar stock después de venta
CREATE OR REPLACE FUNCTION public.update_product_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Reducir stock al agregar item de venta
        UPDATE public.products
        SET 
            quantity = quantity - NEW.quantity,
            last_updated = now()
        WHERE id = NEW.product_id AND NEW.product_id IS NOT NULL;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Restaurar stock al eliminar item de venta
        UPDATE public.products
        SET 
            quantity = quantity + OLD.quantity,
            last_updated = now()
        WHERE id = OLD.product_id AND OLD.product_id IS NOT NULL;
        
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Ajustar stock al modificar cantidad
        UPDATE public.products
        SET 
            quantity = quantity + OLD.quantity - NEW.quantity,
            last_updated = now()
        WHERE id = NEW.product_id AND NEW.product_id IS NOT NULL;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Triggers
-- Eliminar triggers existentes si ya existen
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS update_sales_updated_at ON public.sales;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_sales_updated_at
    BEFORE UPDATE ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Trigger para generar número de venta automáticamente
-- Primero eliminar función si existe
DROP FUNCTION IF EXISTS public.auto_generate_sale_number() CASCADE;

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

DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;
CREATE TRIGGER auto_generate_sale_number_trigger
    BEFORE INSERT ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.auto_generate_sale_number();

-- Triggers para calcular totales
-- Eliminar triggers existentes
DROP TRIGGER IF EXISTS calculate_sale_totals_insert ON public.sale_items;
DROP TRIGGER IF EXISTS calculate_sale_totals_update ON public.sale_items;
DROP TRIGGER IF EXISTS calculate_sale_totals_delete ON public.sale_items;

CREATE TRIGGER calculate_sale_totals_insert
    AFTER INSERT ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

CREATE TRIGGER calculate_sale_totals_update
    AFTER UPDATE ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

CREATE TRIGGER calculate_sale_totals_delete
    AFTER DELETE ON public.sale_items
    FOR EACH ROW EXECUTE FUNCTION public.calculate_sale_totals();

-- Triggers para actualizar stock (solo si la venta está confirmada)
-- NOTA: Este trigger se crea al final después de verificar que las tablas existen
-- Eliminar función existente si existe
DROP FUNCTION IF EXISTS public.update_stock_on_sale_confirm() CASCADE;

-- Crear la función pero no el trigger aún
CREATE OR REPLACE FUNCTION public.update_stock_on_sale_confirm()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Solo actualizar stock cuando la venta se confirma
    IF COALESCE(OLD.sale_status, 'draft') = 'draft' AND NEW.sale_status = 'confirmed' THEN
        -- Reducir stock de todos los productos de la venta
        UPDATE public.products p
        SET 
            quantity = p.quantity - si.quantity,
            last_updated = now()
        FROM public.sale_items si
        WHERE si.sale_id = NEW.id 
        AND si.product_id = p.id 
        AND si.product_id IS NOT NULL;
        
    ELSIF COALESCE(OLD.sale_status, 'draft') = 'confirmed' AND NEW.sale_status = 'cancelled' THEN
        -- Restaurar stock si se cancela una venta confirmada
        UPDATE public.products p
        SET 
            quantity = p.quantity + si.quantity,
            last_updated = now()
        FROM public.sale_items si
        WHERE si.sale_id = NEW.id 
        AND si.product_id = p.id 
        AND si.product_id IS NOT NULL;
    END IF;
    
    RETURN NEW;
END;
$$;

-- El trigger se creará al final del script

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para productos
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);

-- Índices para clientes
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_is_active ON public.customers(is_active);

-- Índices para ventas
CREATE INDEX IF NOT EXISTS idx_sales_sale_number ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON public.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_created_by ON public.sales(created_by);
CREATE INDEX IF NOT EXISTS idx_sales_status ON public.sales(sale_status);
CREATE INDEX IF NOT EXISTS idx_sales_payment_status ON public.sales(payment_status);

-- Índices para items de venta
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON public.sale_items(product_id);

-- Índices para pagos
CREATE INDEX IF NOT EXISTS idx_sale_payments_sale_id ON public.sale_payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_payments_payment_date ON public.sale_payments(payment_date);

-- Índices para devoluciones
CREATE INDEX IF NOT EXISTS idx_sale_returns_original_sale_id ON public.sale_returns(original_sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_returns_return_date ON public.sale_returns(return_date);
CREATE INDEX IF NOT EXISTS idx_sale_returns_status ON public.sale_returns(status);

-- =====================================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_return_items ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si ya existen
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver productos" ON public.products;
DROP POLICY IF EXISTS "Usuarios con permisos pueden crear productos" ON public.products;
DROP POLICY IF EXISTS "Usuarios con permisos pueden actualizar productos" ON public.products;

-- Políticas para productos
CREATE POLICY "Usuarios autenticados pueden ver productos" ON public.products
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios con permisos pueden crear productos" ON public.products
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios con permisos pueden actualizar productos" ON public.products
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Eliminar políticas de clientes si existen
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver clientes" ON public.customers;
DROP POLICY IF EXISTS "Usuarios con permisos pueden gestionar clientes" ON public.customers;

-- Políticas para clientes
CREATE POLICY "Usuarios autenticados pueden ver clientes" ON public.customers
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Usuarios con permisos pueden gestionar clientes" ON public.customers
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Eliminar políticas de ventas si existen
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias ventas o todas si son admin" ON public.sales;
DROP POLICY IF EXISTS "Usuarios pueden crear ventas" ON public.sales;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias ventas" ON public.sales;

-- Políticas para ventas
CREATE POLICY "Usuarios pueden ver sus propias ventas o todas si son admin" ON public.sales
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND (
            created_by = auth.uid() OR 
            public.is_admin()
        )
    );

CREATE POLICY "Usuarios pueden crear ventas" ON public.sales
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

CREATE POLICY "Usuarios pueden actualizar sus propias ventas" ON public.sales
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND (
            created_by = auth.uid() OR 
            public.is_admin()
        )
    );

-- Eliminar políticas de items de venta si existen
DROP POLICY IF EXISTS "Items de venta visibles según venta" ON public.sale_items;
DROP POLICY IF EXISTS "Usuarios pueden gestionar items de sus ventas" ON public.sale_items;

-- Políticas para items de venta
CREATE POLICY "Items de venta visibles según venta" ON public.sale_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sales s 
            WHERE s.id = sale_items.sale_id 
            AND (s.created_by = auth.uid() OR public.is_admin())
        )
    );

CREATE POLICY "Usuarios pueden gestionar items de sus ventas" ON public.sale_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sales s 
            WHERE s.id = sale_items.sale_id 
            AND (s.created_by = auth.uid() OR public.is_admin())
        )
    );

-- Eliminar políticas de pagos si existen
DROP POLICY IF EXISTS "Pagos visibles según venta" ON public.sale_payments;
DROP POLICY IF EXISTS "Usuarios pueden gestionar pagos de sus ventas" ON public.sale_payments;

-- Políticas similares para pagos y devoluciones
CREATE POLICY "Pagos visibles según venta" ON public.sale_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sales s 
            WHERE s.id = sale_payments.sale_id 
            AND (s.created_by = auth.uid() OR public.is_admin())
        )
    );

CREATE POLICY "Usuarios pueden gestionar pagos de sus ventas" ON public.sale_payments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sales s 
            WHERE s.id = sale_payments.sale_id 
            AND (s.created_by = auth.uid() OR public.is_admin())
        ) OR created_by = auth.uid()
    );

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de ventas completas con detalles del cliente
CREATE OR REPLACE VIEW public.sales_complete AS
SELECT 
    s.*,
    c.first_name || ' ' || COALESCE(c.last_name, '') as customer_full_name,
    c.email as customer_email_registered,
    c.phone as customer_phone,
    up.first_name || ' ' || COALESCE(up.last_name, '') as created_by_name,
    COUNT(si.id) as items_count,
    CASE 
        WHEN COUNT(sp.id) > 0 THEN 'partial_paid'
        WHEN s.payment_status = 'completed' THEN 'paid'
        ELSE 'unpaid'
    END as payment_summary
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id
LEFT JOIN public.user_profiles up ON s.created_by = up.user_id
LEFT JOIN public.sale_items si ON s.id = si.sale_id
LEFT JOIN public.sale_payments sp ON s.id = sp.sale_id
GROUP BY s.id, c.id, up.id;

-- Vista de productos con stock bajo
CREATE OR REPLACE VIEW public.products_low_stock AS
SELECT *
FROM public.products
WHERE quantity <= min_stock
AND is_active = true
ORDER BY (quantity::float / NULLIF(min_stock, 0)) ASC;

-- Vista de estadísticas de ventas diarias
CREATE OR REPLACE VIEW public.daily_sales_stats AS
SELECT 
    DATE(sale_date) as sale_date,
    COUNT(*) as total_sales,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as average_sale,
    COUNT(DISTINCT customer_id) as unique_customers
FROM public.sales
WHERE sale_status = 'confirmed'
GROUP BY DATE(sale_date)
ORDER BY sale_date DESC;

-- =====================================================
-- DATOS DE EJEMPLO
-- =====================================================

-- Insertar categorías de productos comunes
INSERT INTO public.products (barcode, name, description, price, quantity, min_stock, category, supplier, created_by) VALUES
    ('1234567890123', 'Producto Demo 1', 'Producto de demostración', 10.50, 100, 10, 'Electrónicos', 'Proveedor A', auth.uid()),
    ('2345678901234', 'Producto Demo 2', 'Otro producto de demostración', 25.00, 50, 5, 'Ropa', 'Proveedor B', auth.uid()),
    ('3456789012345', 'Producto Demo 3', 'Tercer producto demo', 5.75, 200, 20, 'Alimentación', 'Proveedor C', auth.uid())
ON CONFLICT (barcode) DO NOTHING;

-- Insertar cliente de ejemplo
INSERT INTO public.customers (customer_code, first_name, last_name, email, phone, customer_type, created_by) VALUES
    ('CUST001', 'Cliente', 'Demo', 'cliente@demo.com', '+34600000000', 'individual', auth.uid())
ON CONFLICT (customer_code) DO NOTHING;

-- =====================================================
-- COMENTARIOS EN TABLAS
-- =====================================================

COMMENT ON TABLE public.products IS 'Catálogo de productos del sistema';
COMMENT ON TABLE public.customers IS 'Base de datos de clientes';
COMMENT ON TABLE public.sales IS 'Registro principal de ventas';
COMMENT ON TABLE public.sale_items IS 'Detalle de productos vendidos en cada venta';
COMMENT ON TABLE public.sale_payments IS 'Registro de pagos recibidos por ventas';
COMMENT ON TABLE public.sale_returns IS 'Registro de devoluciones de ventas';
COMMENT ON TABLE public.sale_return_items IS 'Detalle de productos devueltos';

-- =====================================================
-- TRIGGERS FINALES (después de crear todas las tablas)
-- =====================================================

-- Ahora crear el trigger de stock después de que todas las tablas existan
DO $$
BEGIN
    -- Verificar que la tabla sales existe y tiene la columna sale_status
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' 
        AND column_name = 'sale_status' 
        AND table_schema = 'public'
    ) THEN
        -- Crear el trigger de stock
        DROP TRIGGER IF EXISTS update_stock_on_sale_status_change ON public.sales;
        EXECUTE 'CREATE TRIGGER update_stock_on_sale_status_change
            AFTER UPDATE OF sale_status ON public.sales
            FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_sale_confirm()';
        
        RAISE NOTICE 'Trigger de control de stock creado exitosamente';
    ELSE
        RAISE NOTICE 'La tabla sales o columna sale_status no existe, trigger de stock omitido';
    END IF;
END $$;

-- =====================================================
-- MENSAJE FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== MÓDULO DE VENTAS IMPLEMENTADO EXITOSAMENTE ===';
    RAISE NOTICE 'Tablas creadas:';
    RAISE NOTICE '- products: Catálogo de productos';
    RAISE NOTICE '- customers: Base de datos de clientes';
    RAISE NOTICE '- sales: Ventas principales';
    RAISE NOTICE '- sale_items: Items de venta';
    RAISE NOTICE '- sale_payments: Pagos de ventas';
    RAISE NOTICE '- sale_returns: Devoluciones';
    RAISE NOTICE '- sale_return_items: Items devueltos';
    RAISE NOTICE '';
    RAISE NOTICE 'Características implementadas:';
    RAISE NOTICE '- Numeración automática de ventas';
    RAISE NOTICE '- Cálculo automático de totales';
    RAISE NOTICE '- Control de stock automático';
    RAISE NOTICE '- Sistema de devoluciones';
    RAISE NOTICE '- Políticas de seguridad RLS';
    RAISE NOTICE '- Vistas para reportes';
    RAISE NOTICE '- Índices para optimización';
    RAISE NOTICE '';
    RAISE NOTICE 'Próximo paso: Implementar componentes React para la interfaz de usuario';
END $$;
