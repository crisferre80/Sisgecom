-- ===================================================================
-- MIGRACIÓN MÓDULO DE VENTAS - VERSIÓN FINAL CORREGIDA
-- Sistema de Gestión Comercial
-- ===================================================================

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

-- ÍNDICES
-- =======
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_customers_name ON public.customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_sales_number ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_date ON public.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_user ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON public.sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_sale_payments_sale ON public.sale_payments(sale_id);

-- FUNCIONES Y TRIGGERS
-- ====================

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
CREATE OR REPLACE FUNCTION public.generate_sale_number()
RETURNS varchar
LANGUAGE plpgsql
AS $$
DECLARE
    next_number integer;
    formatted_number varchar(50);
BEGIN
    -- Obtener el siguiente número
    SELECT COALESCE(MAX(CAST(SUBSTRING(sale_number FROM '[0-9]+') AS integer)), 0) + 1
    INTO next_number
    FROM public.sales
    WHERE sale_number ~ '^VEN-[0-9]+$';
    
    -- Formatear el número
    formatted_number := 'VEN-' || LPAD(next_number::text, 6, '0');
    
    RETURN formatted_number;
END;
$$;

-- Función para calcular totales de venta
CREATE OR REPLACE FUNCTION public.calculate_sale_totals()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    sale_id_to_update uuid;
    calculated_subtotal decimal(10,2);
    calculated_total decimal(10,2);
BEGIN
    -- Determinar qué venta actualizar
    IF TG_OP = 'DELETE' THEN
        sale_id_to_update := OLD.sale_id;
    ELSE
        sale_id_to_update := NEW.sale_id;
    END IF;
    
    -- Calcular subtotal
    SELECT COALESCE(SUM(subtotal), 0)
    INTO calculated_subtotal
    FROM public.sale_items
    WHERE sale_id = sale_id_to_update;
    
    -- Actualizar totales en la venta
    UPDATE public.sales
    SET 
        subtotal = calculated_subtotal,
        total_amount = calculated_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0),
        updated_at = now()
    WHERE id = sale_id_to_update;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- Función para actualizar stock cuando se confirma una venta
CREATE OR REPLACE FUNCTION public.update_stock_on_sale_confirm()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar si es una actualización de estado
    IF TG_OP = 'UPDATE' THEN
        -- Solo actualizar stock cuando la venta se confirma
        IF COALESCE(OLD.sale_status, 'draft') != 'confirmed' AND NEW.sale_status = 'confirmed' THEN
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
    END IF;
    
    RETURN NEW;
END;
$$;

-- Función para generar número de devolución
CREATE OR REPLACE FUNCTION public.generate_return_number()
RETURNS varchar
LANGUAGE plpgsql
AS $$
DECLARE
    next_number integer;
    formatted_number varchar(50);
BEGIN
    -- Obtener el siguiente número
    SELECT COALESCE(MAX(CAST(SUBSTRING(return_number FROM '[0-9]+') AS integer)), 0) + 1
    INTO next_number
    FROM public.sale_returns
    WHERE return_number ~ '^DEV-[0-9]+$';
    
    -- Formatear el número
    formatted_number := 'DEV-' || LPAD(next_number::text, 6, '0');
    
    RETURN formatted_number;
END;
$$;

-- Función para auto-generar número de venta
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

-- Función para auto-generar número de devolución
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

-- CREAR TRIGGERS
-- ==============

-- Triggers para updated_at
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS update_sales_updated_at ON public.sales;
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
DROP TRIGGER IF EXISTS update_returns_updated_at ON public.sale_returns;

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

-- Trigger para generar número de venta automáticamente
DROP TRIGGER IF EXISTS auto_generate_sale_number_trigger ON public.sales;
CREATE TRIGGER auto_generate_sale_number_trigger
    BEFORE INSERT ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.auto_generate_sale_number();

-- Trigger para generar número de devolución automáticamente
DROP TRIGGER IF EXISTS auto_generate_return_number_trigger ON public.sale_returns;
CREATE TRIGGER auto_generate_return_number_trigger
    BEFORE INSERT ON public.sale_returns
    FOR EACH ROW EXECUTE FUNCTION public.auto_generate_return_number();

-- Triggers para calcular totales
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

-- Trigger para actualizar stock cuando se confirma una venta
DROP TRIGGER IF EXISTS update_stock_on_sale_confirm_trigger ON public.sales;
CREATE TRIGGER update_stock_on_sale_confirm_trigger
    AFTER UPDATE ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_sale_confirm();

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

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "Users can view all products" ON public.products;
DROP POLICY IF EXISTS "Users can insert products" ON public.products;
DROP POLICY IF EXISTS "Users can update products" ON public.products;
DROP POLICY IF EXISTS "Users can delete products" ON public.products;

DROP POLICY IF EXISTS "Users can view all customers" ON public.customers;
DROP POLICY IF EXISTS "Users can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Users can update customers" ON public.customers;
DROP POLICY IF EXISTS "Users can delete customers" ON public.customers;

DROP POLICY IF EXISTS "Users can view all sales" ON public.sales;
DROP POLICY IF EXISTS "Users can insert sales" ON public.sales;
DROP POLICY IF EXISTS "Users can update sales" ON public.sales;
DROP POLICY IF EXISTS "Users can delete sales" ON public.sales;

DROP POLICY IF EXISTS "Users can view all sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can insert sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can update sale_items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can delete sale_items" ON public.sale_items;

DROP POLICY IF EXISTS "Users can view all sale_payments" ON public.sale_payments;
DROP POLICY IF EXISTS "Users can insert sale_payments" ON public.sale_payments;
DROP POLICY IF EXISTS "Users can update sale_payments" ON public.sale_payments;
DROP POLICY IF EXISTS "Users can delete sale_payments" ON public.sale_payments;

DROP POLICY IF EXISTS "Users can view all sale_returns" ON public.sale_returns;
DROP POLICY IF EXISTS "Users can insert sale_returns" ON public.sale_returns;
DROP POLICY IF EXISTS "Users can update sale_returns" ON public.sale_returns;
DROP POLICY IF EXISTS "Users can delete sale_returns" ON public.sale_returns;

DROP POLICY IF EXISTS "Users can view all sale_return_items" ON public.sale_return_items;
DROP POLICY IF EXISTS "Users can insert sale_return_items" ON public.sale_return_items;
DROP POLICY IF EXISTS "Users can update sale_return_items" ON public.sale_return_items;
DROP POLICY IF EXISTS "Users can delete sale_return_items" ON public.sale_return_items;

-- Crear políticas para productos
CREATE POLICY "Users can view all products" ON public.products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert products" ON public.products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update products" ON public.products
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete products" ON public.products
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para clientes
CREATE POLICY "Users can view all customers" ON public.customers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert customers" ON public.customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update customers" ON public.customers
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete customers" ON public.customers
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para ventas
CREATE POLICY "Users can view all sales" ON public.sales
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert sales" ON public.sales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update sales" ON public.sales
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete sales" ON public.sales
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para sale_items
CREATE POLICY "Users can view all sale_items" ON public.sale_items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert sale_items" ON public.sale_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update sale_items" ON public.sale_items
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete sale_items" ON public.sale_items
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para sale_payments
CREATE POLICY "Users can view all sale_payments" ON public.sale_payments
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert sale_payments" ON public.sale_payments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update sale_payments" ON public.sale_payments
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete sale_payments" ON public.sale_payments
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para sale_returns
CREATE POLICY "Users can view all sale_returns" ON public.sale_returns
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert sale_returns" ON public.sale_returns
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update sale_returns" ON public.sale_returns
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete sale_returns" ON public.sale_returns
    FOR DELETE USING (auth.role() = 'authenticated');

-- Crear políticas para sale_return_items
CREATE POLICY "Users can view all sale_return_items" ON public.sale_return_items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert sale_return_items" ON public.sale_return_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update sale_return_items" ON public.sale_return_items
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete sale_return_items" ON public.sale_return_items
    FOR DELETE USING (auth.role() = 'authenticated');

-- VISTAS ÚTILES
-- =============

-- Vista de ventas con información del cliente
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
    c.city as customer_city
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id;

-- Vista de productos con stock bajo
CREATE OR REPLACE VIEW public.low_stock_products AS
SELECT *
FROM public.products
WHERE is_active = true 
AND quantity <= min_stock
ORDER BY quantity ASC;

-- Vista de ventas del día
CREATE OR REPLACE VIEW public.today_sales AS
SELECT 
    s.*,
    c.name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id
WHERE DATE(s.sale_date) = CURRENT_DATE
ORDER BY s.sale_date DESC;

-- DATOS DE EJEMPLO
-- ================

-- Insertar productos de ejemplo
INSERT INTO public.products (name, description, price, cost, quantity, min_stock, category, barcode) VALUES
('Producto A', 'Descripción del producto A', 100.00, 60.00, 50, 10, 'Categoría 1', '1234567890'),
('Producto B', 'Descripción del producto B', 200.00, 120.00, 30, 5, 'Categoría 2', '1234567891'),
('Producto C', 'Descripción del producto C', 150.00, 90.00, 25, 8, 'Categoría 1', '1234567892')
ON CONFLICT (barcode) DO NOTHING;

-- Insertar clientes de ejemplo
INSERT INTO public.customers (name, email, phone, address, city) VALUES
('Cliente A', 'clientea@example.com', '123-456-7890', 'Dirección A', 'Ciudad A'),
('Cliente B', 'clienteb@example.com', '123-456-7891', 'Dirección B', 'Ciudad B'),
('Cliente C', 'clientec@example.com', '123-456-7892', 'Dirección C', 'Ciudad C')
ON CONFLICT DO NOTHING;

-- Mensaje de finalización
DO $$
BEGIN
    RAISE NOTICE 'Migración del módulo de ventas completada exitosamente!';
    RAISE NOTICE 'Tablas creadas: products, customers, sales, sale_items, sale_payments, sale_returns, sale_return_items';
    RAISE NOTICE 'Funciones y triggers configurados correctamente';
    RAISE NOTICE 'Políticas RLS habilitadas';
    RAISE NOTICE 'Datos de ejemplo insertados';
END $$;
