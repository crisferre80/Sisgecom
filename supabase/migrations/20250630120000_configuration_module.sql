-- Configuration Module Migration
-- This migration creates all the necessary tables for the configuration module

-- Company Settings Table
CREATE TABLE IF NOT EXISTS company_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL,
    company_email VARCHAR(255) NOT NULL,
    company_phone VARCHAR(50),
    company_address TEXT,
    company_city VARCHAR(100),
    company_postal_code VARCHAR(20),
    company_country VARCHAR(100),
    tax_id VARCHAR(50),
    logo_url TEXT,
    website VARCHAR(255),
    default_currency VARCHAR(3) DEFAULT 'USD',
    default_tax_rate DECIMAL(5,2) DEFAULT 0.00,
    invoice_prefix VARCHAR(10) DEFAULT 'INV-',
    invoice_counter INTEGER DEFAULT 1,
    receipt_prefix VARCHAR(10) DEFAULT 'REC-',
    receipt_counter INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- System Settings Table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(255) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    category VARCHAR(50) DEFAULT 'general' CHECK (category IN ('general', 'inventory', 'sales', 'payments', 'notifications', 'security')),
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES auth.users(id)
);

-- Notification Templates Table
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name VARCHAR(255) NOT NULL,
    template_type VARCHAR(20) NOT NULL CHECK (template_type IN ('email', 'sms', 'whatsapp', 'system')),
    event_trigger VARCHAR(100) NOT NULL,
    subject VARCHAR(255),
    content TEXT NOT NULL,
    variables TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- Backup Configurations Table
CREATE TABLE IF NOT EXISTS backup_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_name VARCHAR(255) NOT NULL,
    backup_type VARCHAR(20) NOT NULL CHECK (backup_type IN ('full', 'incremental', 'differential')),
    schedule_type VARCHAR(20) NOT NULL CHECK (schedule_type IN ('manual', 'daily', 'weekly', 'monthly')),
    schedule_time TIME,
    schedule_day VARCHAR(10),
    retention_days INTEGER DEFAULT 30,
    storage_location VARCHAR(20) DEFAULT 'local' CHECK (storage_location IN ('local', 'cloud', 'both')),
    is_active BOOLEAN DEFAULT false,
    last_backup TIMESTAMP WITH TIME ZONE,
    next_backup TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id)
);

-- Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    user_email VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Inventory Alerts Table
CREATE TABLE IF NOT EXISTS inventory_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    alert_type VARCHAR(20) NOT NULL CHECK (alert_type IN ('low_stock', 'out_of_stock', 'expired', 'expiring_soon')),
    alert_level VARCHAR(10) DEFAULT 'warning' CHECK (alert_level IN ('info', 'warning', 'critical')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES auth.users(id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(setting_key);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_notification_templates_active ON notification_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_inventory_alerts_product ON inventory_alerts(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_alerts_unresolved ON inventory_alerts(is_resolved) WHERE is_resolved = false;
CREATE INDEX IF NOT EXISTS idx_inventory_alerts_type ON inventory_alerts(alert_type);

-- RLS Policies
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE backup_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_alerts ENABLE ROW LEVEL SECURITY;

-- Company Settings Policies
CREATE POLICY "Company settings are viewable by authenticated users" ON company_settings
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Company settings are editable by admin users" ON company_settings
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- System Settings Policies
CREATE POLICY "Public system settings are viewable by authenticated users" ON system_settings
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        (is_public = true OR EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        ))
    );

CREATE POLICY "System settings are editable by admin users" ON system_settings
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Notification Templates Policies
CREATE POLICY "Notification templates are viewable by authenticated users" ON notification_templates
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Notification templates are manageable by admin users" ON notification_templates
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Backup Configurations Policies
CREATE POLICY "Backup configurations are manageable by admin users" ON backup_configurations
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Audit Logs Policies
CREATE POLICY "Audit logs are viewable by admin users" ON audit_logs
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

CREATE POLICY "Audit logs are insertable by authenticated users" ON audit_logs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Inventory Alerts Policies
CREATE POLICY "Inventory alerts are viewable by authenticated users" ON inventory_alerts
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Inventory alerts are manageable by users with inventory access" ON inventory_alerts
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND (
                role = 'admin' OR
                'inventory_manage' = ANY(permissions) OR
                'inventory_view' = ANY(permissions)
            )
        )
    );

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, setting_type, description, category, is_public, updated_by) VALUES
    ('low_stock_threshold', '10', 'number', 'Cantidad mínima de stock para generar alerta', 'inventory', true, (SELECT id FROM auth.users LIMIT 1)),
    ('auto_generate_alerts', 'true', 'boolean', 'Generar alertas automáticamente', 'inventory', true, (SELECT id FROM auth.users LIMIT 1)),
    ('session_timeout', '3600', 'number', 'Tiempo de sesión en segundos', 'security', false, (SELECT id FROM auth.users LIMIT 1)),
    ('max_login_attempts', '5', 'number', 'Máximo número de intentos de login', 'security', false, (SELECT id FROM auth.users LIMIT 1)),
    ('email_notifications', 'true', 'boolean', 'Habilitar notificaciones por email', 'notifications', true, (SELECT id FROM auth.users LIMIT 1)),
    ('sms_notifications', 'false', 'boolean', 'Habilitar notificaciones por SMS', 'notifications', true, (SELECT id FROM auth.users LIMIT 1))
ON CONFLICT (setting_key) DO NOTHING;

-- Insert default notification templates
INSERT INTO notification_templates (template_name, template_type, event_trigger, subject, content, variables, created_by, updated_by) VALUES
    ('Alerta de Stock Bajo', 'email', 'low_stock_alert', 'Alerta: Stock Bajo - {{product_name}}', 
     'El producto {{product_name}} ({{product_barcode}}) tiene stock bajo.\nStock actual: {{current_stock}}\nStock mínimo: {{min_stock}}', 
     ARRAY['product_name', 'product_barcode', 'current_stock', 'min_stock'],
     (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
    
    ('Producto Agotado', 'email', 'out_of_stock_alert', 'Alerta: Producto Agotado - {{product_name}}', 
     'El producto {{product_name}} ({{product_barcode}}) se ha agotado.\nEs necesario realizar un reabastecimiento.', 
     ARRAY['product_name', 'product_barcode'],
     (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM auth.users LIMIT 1)),
     
    ('Nueva Venta', 'email', 'new_sale', 'Nueva Venta Registrada - {{sale_number}}', 
     'Se ha registrado una nueva venta.\nNúmero de venta: {{sale_number}}\nCliente: {{customer_name}}\nTotal: {{total_amount}}', 
     ARRAY['sale_number', 'customer_name', 'total_amount'],
     (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM auth.users LIMIT 1))
ON CONFLICT DO NOTHING;

-- Functions for automatic alert generation
CREATE OR REPLACE FUNCTION generate_inventory_alerts()
RETURNS void AS $$
BEGIN
    -- Generate low stock alerts
    INSERT INTO inventory_alerts (product_id, alert_type, alert_level, message)
    SELECT 
        p.id,
        'low_stock',
        CASE 
            WHEN p.quantity = 0 THEN 'critical'
            WHEN p.quantity <= p.min_stock * 0.5 THEN 'critical'
            ELSE 'warning'
        END,
        CASE 
            WHEN p.quantity = 0 THEN 'El producto ' || p.name || ' está agotado'
            ELSE 'El producto ' || p.name || ' tiene stock bajo (' || p.quantity || ' unidades)'
        END
    FROM products p
    WHERE p.quantity <= p.min_stock
    AND p.is_active = true
    AND NOT EXISTS (
        SELECT 1 FROM inventory_alerts ia 
        WHERE ia.product_id = p.id 
        AND ia.alert_type = 'low_stock' 
        AND ia.is_resolved = false
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to generate alerts when product quantity changes
CREATE OR REPLACE FUNCTION check_product_stock_trigger()
RETURNS trigger AS $$
BEGIN
    -- Check if quantity changed and is now below minimum
    IF NEW.quantity <= NEW.min_stock AND (OLD.quantity IS NULL OR OLD.quantity > NEW.min_stock) THEN
        INSERT INTO inventory_alerts (product_id, alert_type, alert_level, message)
        VALUES (
            NEW.id,
            CASE WHEN NEW.quantity = 0 THEN 'out_of_stock' ELSE 'low_stock' END,
            CASE WHEN NEW.quantity = 0 THEN 'critical' ELSE 'warning' END,
            CASE 
                WHEN NEW.quantity = 0 THEN 'El producto ' || NEW.name || ' está agotado'
                ELSE 'El producto ' || NEW.name || ' tiene stock bajo (' || NEW.quantity || ' unidades)'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for product stock changes
DROP TRIGGER IF EXISTS product_stock_check_trigger ON products;
CREATE TRIGGER product_stock_check_trigger
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION check_product_stock_trigger();

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_user_id UUID,
    p_user_email VARCHAR,
    p_action VARCHAR,
    p_entity_type VARCHAR,
    p_entity_id UUID DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_details TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO audit_logs (
        user_id, user_email, action, entity_type, entity_id, 
        old_values, new_values, details, timestamp
    ) VALUES (
        p_user_id, p_user_email, p_action, p_entity_type, p_entity_id,
        p_old_values, p_new_values, p_details, CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;

-- Create initial company settings record if it doesn't exist
INSERT INTO company_settings (
    company_name, company_email, company_phone, company_address,
    company_city, company_country, tax_id, default_currency,
    default_tax_rate, updated_by
) 
SELECT 
    'Mi Empresa', 'contacto@miempresa.com', '', '',
    '', '', '', 'USD', 0.00, id
FROM auth.users 
WHERE NOT EXISTS (SELECT 1 FROM company_settings)
LIMIT 1;
