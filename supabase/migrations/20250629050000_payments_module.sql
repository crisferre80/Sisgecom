-- Crear tabla de clientes
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20) NOT NULL,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_payment TIMESTAMP WITH TIME ZONE,
  total_debt DECIMAL(10,2) DEFAULT 0.00,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked'))
);

-- Crear tabla de billeteras virtuales
CREATE TABLE IF NOT EXISTS virtual_wallets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  wallet_type VARCHAR(50) NOT NULL CHECK (wallet_type IN ('mercado_pago', 'yape', 'plin', 'tunki', 'banco_digital', 'otro')),
  wallet_identifier VARCHAR(255) NOT NULL,
  alias VARCHAR(100),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de pagos
CREATE TABLE IF NOT EXISTS payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  customer_name VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('efectivo', 'tarjeta', 'transferencia', 'billetera_virtual')),
  wallet_type VARCHAR(50),
  transaction_reference VARCHAR(255),
  status VARCHAR(20) DEFAULT 'pendiente' CHECK (status IN ('pendiente', 'pagado', 'vencido', 'cancelado')),
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  paid_date TIMESTAMP WITH TIME ZONE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  payment_proof TEXT,
  notes TEXT
);

-- Crear tabla de recordatorios de pago
CREATE TABLE IF NOT EXISTS payment_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  reminder_type VARCHAR(20) NOT NULL CHECK (reminder_type IN ('whatsapp', 'email', 'sms')),
  message TEXT NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'enviado' CHECK (status IN ('enviado', 'entregado', 'leido', 'fallido')),
  response TEXT
);

-- Crear tabla de contactos de WhatsApp
CREATE TABLE IF NOT EXISTS whatsapp_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  last_message_sent TIMESTAMP WITH TIME ZONE,
  message_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_due_date ON payments(due_date);
CREATE INDEX IF NOT EXISTS idx_virtual_wallets_customer_id ON virtual_wallets(customer_id);
CREATE INDEX IF NOT EXISTS idx_payment_reminders_payment_id ON payment_reminders(payment_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_contacts_customer_id ON whatsapp_contacts(customer_id);

-- Crear función para actualizar el campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear triggers para actualizar updated_at
DROP TRIGGER IF EXISTS update_virtual_wallets_updated_at ON virtual_wallets;
CREATE TRIGGER update_virtual_wallets_updated_at 
  BEFORE UPDATE ON virtual_wallets 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at 
  BEFORE UPDATE ON payments 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para actualizar la deuda total del cliente
CREATE OR REPLACE FUNCTION update_customer_debt()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE customers 
  SET total_debt = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM payments 
    WHERE customer_id = COALESCE(NEW.customer_id, OLD.customer_id) 
    AND status = 'pendiente'
  )
  WHERE id = COALESCE(NEW.customer_id, OLD.customer_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Crear trigger para actualizar deuda del cliente
DROP TRIGGER IF EXISTS update_customer_debt_trigger ON payments;
CREATE TRIGGER update_customer_debt_trigger
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_customer_debt();

-- Insertar algunos datos de ejemplo para testing
INSERT INTO customers (name, phone, email, status) VALUES
  ('Juan Pérez', '+51987654321', 'juan.perez@email.com', 'active'),
  ('María García', '+51976543210', 'maria.garcia@email.com', 'active'),
  ('Carlos López', '+51965432109', 'carlos.lopez@email.com', 'active'),
  ('Ana Torres', '+51954321098', 'ana.torres@email.com', 'active')
ON CONFLICT DO NOTHING;

-- Insertar billeteras virtuales de ejemplo
INSERT INTO virtual_wallets (customer_id, wallet_type, wallet_identifier, alias, is_verified)
SELECT 
  c.id,
  'yape',
  c.phone,
  'Yape Principal',
  true
FROM customers c
WHERE c.name IN ('Juan Pérez', 'María García')
ON CONFLICT DO NOTHING;

INSERT INTO virtual_wallets (customer_id, wallet_type, wallet_identifier, alias, is_verified)
SELECT 
  c.id,
  'plin',
  c.phone,
  'Plin Personal',
  true
FROM customers c
WHERE c.name IN ('Carlos López', 'Ana Torres')
ON CONFLICT DO NOTHING;
