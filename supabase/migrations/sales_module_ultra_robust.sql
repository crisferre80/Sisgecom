-- ===================================================================
-- MIGRACIÓN MÓDULO DE VENTAS - VERSIÓN ULTRA ROBUSTA
-- Sistema de Gestión Comercial - Sin errores de columnas
-- ===================================================================

-- LIMPIAR VISTAS ANTERIORES SI EXISTEN
DROP VIEW IF EXISTS public.today_sales;
DROP VIEW IF EXISTS public.low_stock_products;
DROP VIEW IF EXISTS public.sales_with_customer;

-- EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABLAS PRINCIPALES
-- =================

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

-- Tabla de ventas
CREATE TABLE IF NOT EXISTS public.sales (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_number varchar(50) UNIQUE,
    customer_id uuid REFERENCES public.customers(id),
    user_id uuid NOT NULL,
    sale_date timestamp with time zone DEFAULT now(),
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
CREATE INDEX IF NOT EXISTS idx_sales_date ON public.sales(sale_date);
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
SECURITY DEFINER
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Función para generar número de venta secuencial
CREATE OR REPLACE FUNCTION public.generate_sale_number()
RETURNS varchar(50)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_number integer;
    formatted_number varchar(50);
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
END;
$$;

-- Función para generar número de devolución
CREATE OR REPLACE FUNCTION public.generate_return_number()
RETURNS varchar(50)
LANGUAGE plpgsql
SECURITY DEFINER
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
END;
$$;

-- Función para calcular totales de venta
CREATE OR REPLACE FUNCTION public.calculate_sale_totals()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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
END;
$$;

-- Función para manejar cambios de stock cuando se confirma/cancela una venta
CREATE OR REPLACE FUNCTION public.handle_stock_on_sale_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    old_status varchar(20);
    new_status varchar(20);
BEGIN
    -- Solo procesar si es UPDATE y hay cambio de estado
    IF TG_OP = 'UPDATE' THEN
        old_status := COALESCE(OLD.sale_status, 'draft');
        new_status := NEW.sale_status;
        
        -- Confirmar venta: reducir stock
        IF old_status != 'confirmed' AND new_status = 'confirmed' THEN
            UPDATE public.products p
            SET 
                quantity = p.quantity - si.quantity,
                last_updated = now()
            FROM public.sale_items si
            WHERE si.sale_id = NEW.id 
            AND si.product_id = p.id 
            AND si.product_id IS NOT NULL
            AND p.quantity >= si.quantity; -- Solo si hay stock suficiente
            
        -- Cancelar venta confirmada: restaurar stock
        ELSIF old_status = 'confirmed' AND new_status = 'cancelled' THEN
            UPDATE public.products p
            SET 
                quantity = p.quantity + si.quantity,
                last_updated = now()
            FROM public.sale_items si
            WHERE si.sale_id = NEW.id 
            AND si.product_id = p.id 
            AND si.product_id IS NOT NULL;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Funciones para auto-generar números
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
END $$;

-- Crear políticas uniformes para todos los usuarios autenticados
-- Productos
CREATE POLICY "authenticated_users_products_select" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_products_insert" ON public.products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_products_update" ON public.products FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_products_delete" ON public.products FOR DELETE USING (auth.role() = 'authenticated');

-- Clientes
CREATE POLICY "authenticated_users_customers_select" ON public.customers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_customers_insert" ON public.customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_customers_update" ON public.customers FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_customers_delete" ON public.customers FOR DELETE USING (auth.role() = 'authenticated');

-- Ventas
CREATE POLICY "authenticated_users_sales_select" ON public.sales FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sales_insert" ON public.sales FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sales_update" ON public.sales FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sales_delete" ON public.sales FOR DELETE USING (auth.role() = 'authenticated');

-- Items de venta
CREATE POLICY "authenticated_users_sale_items_select" ON public.sale_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_items_insert" ON public.sale_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_items_update" ON public.sale_items FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_items_delete" ON public.sale_items FOR DELETE USING (auth.role() = 'authenticated');

-- Pagos
CREATE POLICY "authenticated_users_sale_payments_select" ON public.sale_payments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_payments_insert" ON public.sale_payments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_payments_update" ON public.sale_payments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_payments_delete" ON public.sale_payments FOR DELETE USING (auth.role() = 'authenticated');

-- Devoluciones
CREATE POLICY "authenticated_users_sale_returns_select" ON public.sale_returns FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_returns_insert" ON public.sale_returns FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_returns_update" ON public.sale_returns FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_returns_delete" ON public.sale_returns FOR DELETE USING (auth.role() = 'authenticated');

-- Items de devolución
CREATE POLICY "authenticated_users_sale_return_items_select" ON public.sale_return_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_return_items_insert" ON public.sale_return_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_return_items_update" ON public.sale_return_items FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_users_sale_return_items_delete" ON public.sale_return_items FOR DELETE USING (auth.role() = 'authenticated');

-- VISTAS ÚTILES Y SEGURAS
-- =======================

-- Vista de ventas con información del cliente (con campos explícitos)
CREATE OR REPLACE VIEW public.sales_with_customer AS
SELECT 
    s.id,
    s.sale_number,
    s.customer_id,
    s.user_id,
    s.sale_date,
    s.sale_status,
    s.subtotal,
    s.tax_amount,
    s.discount_amount,
    s.total_amount,
    s.payment_status,
    s.notes,
    s.created_at,
    s.updated_at,
    c.name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone,
    c.address as customer_address,
    c.city as customer_city,
    c.tax_id as customer_tax_id
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id;

-- Vista de productos con stock bajo
CREATE OR REPLACE VIEW public.low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.price,
    p.cost,
    p.quantity,
    p.min_stock,
    p.category,
    p.barcode,
    p.is_active,
    p.created_at,
    p.last_updated,
    (p.quantity::float / NULLIF(p.min_stock, 0)) as stock_ratio
FROM public.products p
WHERE p.is_active = true 
AND p.quantity <= p.min_stock
AND p.min_stock > 0
ORDER BY p.quantity ASC, (p.quantity::float / NULLIF(p.min_stock, 0)) ASC;

-- Vista de ventas del día actual
CREATE OR REPLACE VIEW public.today_sales AS
SELECT 
    s.id,
    s.sale_number,
    s.customer_id,
    s.user_id,
    s.sale_date,
    s.sale_status,
    s.subtotal,
    s.tax_amount,
    s.discount_amount,
    s.total_amount,
    s.payment_status,
    s.notes,
    s.created_at,
    s.updated_at,
    c.name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id
WHERE DATE(s.sale_date) = CURRENT_DATE
ORDER BY s.sale_date DESC;

-- Vista de estadísticas diarias
CREATE OR REPLACE VIEW public.daily_sales_stats AS
SELECT 
    DATE(sale_date) as date,
    COUNT(*) as total_sales,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(CASE WHEN sale_status = 'confirmed' THEN total_amount ELSE 0 END) as confirmed_revenue,
    SUM(CASE WHEN sale_status = 'draft' THEN total_amount ELSE 0 END) as pending_revenue,
    AVG(CASE WHEN sale_status = 'confirmed' THEN total_amount ELSE NULL END) as avg_sale_amount
FROM public.sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(sale_date)
ORDER BY date DESC;

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
    functions_count integer;
    triggers_count integer;
    policies_count integer;
BEGIN
    -- Contar elementos creados
    SELECT COUNT(*) INTO products_count FROM public.products;
    SELECT COUNT(*) INTO customers_count FROM public.customers;
    
    SELECT COUNT(*) INTO functions_count 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name LIKE '%sale%' OR routine_name LIKE '%generate%' OR routine_name LIKE '%update_updated_at%';
    
    SELECT COUNT(*) INTO triggers_count 
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public';
    
    SELECT COUNT(*) INTO policies_count 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('products', 'customers', 'sales', 'sale_items', 'sale_payments', 'sale_returns', 'sale_return_items');

    RAISE NOTICE '========================================';
    RAISE NOTICE 'MÓDULO DE VENTAS INSTALADO EXITOSAMENTE';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'TABLAS CREADAS:';
    RAISE NOTICE '- products (Productos)';
    RAISE NOTICE '- customers (Clientes)'; 
    RAISE NOTICE '- sales (Ventas)';
    RAISE NOTICE '- sale_items (Items de venta)';
    RAISE NOTICE '- sale_payments (Pagos)';
    RAISE NOTICE '- sale_returns (Devoluciones)';
    RAISE NOTICE '- sale_return_items (Items devueltos)';
    RAISE NOTICE '';
    RAISE NOTICE 'VISTAS CREADAS:';
    RAISE NOTICE '- sales_with_customer';
    RAISE NOTICE '- low_stock_products';
    RAISE NOTICE '- today_sales';
    RAISE NOTICE '- daily_sales_stats';
    RAISE NOTICE '';
    RAISE NOTICE 'ESTADÍSTICAS:';
    RAISE NOTICE '- Productos de ejemplo: %', products_count;
    RAISE NOTICE '- Clientes de ejemplo: %', customers_count;
    RAISE NOTICE '- Funciones creadas: %', functions_count;
    RAISE NOTICE '- Triggers activos: %', triggers_count;
    RAISE NOTICE '- Políticas RLS: %', policies_count;
    RAISE NOTICE '';
    RAISE NOTICE 'CARACTERÍSTICAS ACTIVAS:';
    RAISE NOTICE '✓ Numeración automática de ventas (VEN-YYYY-000001)';
    RAISE NOTICE '✓ Cálculo automático de totales';
    RAISE NOTICE '✓ Control de stock al confirmar/cancelar ventas';
    RAISE NOTICE '✓ Seguridad RLS habilitada';
    RAISE NOTICE '✓ Índices optimizados';
    RAISE NOTICE '✓ Vistas para reportes';
    RAISE NOTICE '';
    RAISE NOTICE 'El módulo está listo para usar!';
    RAISE NOTICE '========================================';
END $$;
