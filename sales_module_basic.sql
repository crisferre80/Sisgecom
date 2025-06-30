-- =====================================================
-- MIGRACIÓN DEL MÓDULO DE VENTAS - VERSIÓN SIMPLIFICADA
-- Para ejecutar paso a paso si hay conflictos
-- =====================================================

-- PASO 1: Crear tablas básicas
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
    tax_id varchar(50),
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

CREATE TABLE IF NOT EXISTS public.sales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number varchar(50) UNIQUE NOT NULL,
    customer_id uuid REFERENCES public.customers(id),
    customer_name varchar(255),
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
    created_by uuid NOT NULL,
    updated_by uuid
);

CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id uuid REFERENCES public.products(id),
    product_barcode varchar(100),
    product_name varchar(255) NOT NULL,
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price decimal(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_percentage decimal(5,2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount decimal(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    tax_rate decimal(5,2) DEFAULT 21.00,
    tax_amount decimal(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    line_total decimal(10,2) NOT NULL CHECK (line_total >= 0),
    created_at timestamptz DEFAULT now()
);

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

-- PASO 2: Habilitar RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_payments ENABLE ROW LEVEL SECURITY;

-- PASO 3: Crear políticas básicas (solo si no existen)
DO $$
BEGIN
    -- Política para productos
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'products' AND policyname = 'Allow authenticated users to view products') THEN
        EXECUTE 'CREATE POLICY "Allow authenticated users to view products" ON public.products FOR SELECT USING (auth.uid() IS NOT NULL)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'products' AND policyname = 'Allow authenticated users to manage products') THEN
        EXECUTE 'CREATE POLICY "Allow authenticated users to manage products" ON public.products FOR ALL USING (auth.uid() IS NOT NULL)';
    END IF;
    
    -- Política para clientes
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'customers' AND policyname = 'Allow authenticated users to view customers') THEN
        EXECUTE 'CREATE POLICY "Allow authenticated users to view customers" ON public.customers FOR SELECT USING (auth.uid() IS NOT NULL)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'customers' AND policyname = 'Allow authenticated users to manage customers') THEN
        EXECUTE 'CREATE POLICY "Allow authenticated users to manage customers" ON public.customers FOR ALL USING (auth.uid() IS NOT NULL)';
    END IF;
    
    -- Política para ventas
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sales' AND policyname = 'Allow users to view own sales') THEN
        EXECUTE 'CREATE POLICY "Allow users to view own sales" ON public.sales FOR SELECT USING (auth.uid() IS NOT NULL)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sales' AND policyname = 'Allow users to manage own sales') THEN
        EXECUTE 'CREATE POLICY "Allow users to manage own sales" ON public.sales FOR ALL USING (auth.uid() IS NOT NULL)';
    END IF;
    
    -- Política para items de venta
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sale_items' AND policyname = 'Allow users to view sale items') THEN
        EXECUTE 'CREATE POLICY "Allow users to view sale items" ON public.sale_items FOR SELECT USING (auth.uid() IS NOT NULL)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sale_items' AND policyname = 'Allow users to manage sale items') THEN
        EXECUTE 'CREATE POLICY "Allow users to manage sale items" ON public.sale_items FOR ALL USING (auth.uid() IS NOT NULL)';
    END IF;
    
    -- Política para pagos
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sale_payments' AND policyname = 'Allow users to view payments') THEN
        EXECUTE 'CREATE POLICY "Allow users to view payments" ON public.sale_payments FOR SELECT USING (auth.uid() IS NOT NULL)';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'sale_payments' AND policyname = 'Allow users to manage payments') THEN
        EXECUTE 'CREATE POLICY "Allow users to manage payments" ON public.sale_payments FOR ALL USING (auth.uid() IS NOT NULL)';
    END IF;
    
END $$;

-- PASO 4: Crear índices
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_sales_sale_number ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON public.sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON public.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON public.sale_items(product_id);

-- PASO 5: Crear vista básica para ventas
CREATE OR REPLACE VIEW public.sales_basic AS
SELECT 
    s.*,
    c.first_name || ' ' || COALESCE(c.last_name, '') as customer_full_name,
    c.email as customer_email_registered,
    c.phone as customer_phone
FROM public.sales s
LEFT JOIN public.customers c ON s.customer_id = c.id;

-- PASO 6: Insertar datos de ejemplo
INSERT INTO public.products (barcode, name, description, price, quantity, min_stock, category, supplier) VALUES
    ('1234567890123', 'Producto Demo 1', 'Producto de demostración', 10.50, 100, 10, 'Electrónicos', 'Proveedor A'),
    ('2345678901234', 'Producto Demo 2', 'Otro producto de demostración', 25.00, 50, 5, 'Ropa', 'Proveedor B'),
    ('3456789012345', 'Producto Demo 3', 'Tercer producto demo', 5.75, 200, 20, 'Alimentación', 'Proveedor C')
ON CONFLICT (barcode) DO NOTHING;

INSERT INTO public.customers (customer_code, first_name, last_name, email, phone, customer_type) VALUES
    ('CUST001', 'Cliente', 'Demo', 'cliente@demo.com', '+34600000000', 'individual')
ON CONFLICT (customer_code) DO NOTHING;

-- Mensaje final
SELECT 'Módulo de ventas básico instalado correctamente. Las tablas y políticas básicas están listas.' as mensaje;
