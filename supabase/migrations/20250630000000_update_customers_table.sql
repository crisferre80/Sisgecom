-- Migración para actualizar la tabla customers con todos los campos necesarios
-- Fecha: 2025-06-30

-- Primero, verificar si las columnas existen antes de agregarlas
DO $$
BEGIN
    -- Agregar customer_code si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='customer_code') THEN
        ALTER TABLE customers ADD COLUMN customer_code VARCHAR(50) UNIQUE;
    END IF;

    -- Agregar first_name si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='first_name') THEN
        ALTER TABLE customers ADD COLUMN first_name VARCHAR(255);
    END IF;

    -- Agregar last_name si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='last_name') THEN
        ALTER TABLE customers ADD COLUMN last_name VARCHAR(255);
    END IF;

    -- Agregar city si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='city') THEN
        ALTER TABLE customers ADD COLUMN city VARCHAR(255);
    END IF;

    -- Agregar postal_code si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='postal_code') THEN
        ALTER TABLE customers ADD COLUMN postal_code VARCHAR(20);
    END IF;

    -- Agregar country si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='country') THEN
        ALTER TABLE customers ADD COLUMN country VARCHAR(255) DEFAULT 'España';
    END IF;

    -- Agregar tax_id si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='tax_id') THEN
        ALTER TABLE customers ADD COLUMN tax_id VARCHAR(50);
    END IF;

    -- Agregar customer_type si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='customer_type') THEN
        ALTER TABLE customers ADD COLUMN customer_type VARCHAR(20) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business'));
    END IF;

    -- Agregar credit_limit si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='credit_limit') THEN
        ALTER TABLE customers ADD COLUMN credit_limit DECIMAL(10,2) DEFAULT 0.00;
    END IF;

    -- Agregar discount_percentage si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='discount_percentage') THEN
        ALTER TABLE customers ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0.00;
    END IF;

    -- Agregar is_active si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='is_active') THEN
        ALTER TABLE customers ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;

    -- Agregar notes si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='notes') THEN
        ALTER TABLE customers ADD COLUMN notes TEXT;
    END IF;

    -- Agregar updated_at si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='updated_at') THEN
        ALTER TABLE customers ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Agregar created_by si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='created_by') THEN
        ALTER TABLE customers ADD COLUMN created_by UUID REFERENCES auth.users(id);
    END IF;

    -- Agregar updated_by si no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='updated_by') THEN
        ALTER TABLE customers ADD COLUMN updated_by UUID REFERENCES auth.users(id);
    END IF;
END
$$;

-- Migrar datos existentes de la columna 'name' a 'first_name' si existen datos
UPDATE customers 
SET first_name = name 
WHERE first_name IS NULL AND name IS NOT NULL;

-- Hacer first_name NOT NULL después de migrar los datos
ALTER TABLE customers ALTER COLUMN first_name SET NOT NULL;

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_is_active ON customers(is_active);
CREATE INDEX IF NOT EXISTS idx_customers_customer_type ON customers(customer_type);

-- Actualizar la función de timestamp automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear trigger para updated_at
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Habilitar RLS (Row Level Security)
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view all customers" ON customers;
DROP POLICY IF EXISTS "Users can insert customers" ON customers;
DROP POLICY IF EXISTS "Users can update customers" ON customers;
DROP POLICY IF EXISTS "Users can delete customers" ON customers;

-- Política para permitir que los usuarios autenticados vean todos los clientes
CREATE POLICY "Users can view all customers" ON customers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Política para permitir que los usuarios autenticados inserten clientes
CREATE POLICY "Users can insert customers" ON customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Política para permitir que los usuarios autenticados actualicen clientes
CREATE POLICY "Users can update customers" ON customers
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Política para permitir que los usuarios autenticados eliminen clientes
CREATE POLICY "Users can delete customers" ON customers
    FOR DELETE USING (auth.role() = 'authenticated');
