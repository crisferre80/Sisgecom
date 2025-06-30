export interface Product {
  id?: string;
  barcode: string;
  name: string;
  description?: string;
  price: number;
  quantity: number;
  min_stock: number;
  category: string;
  supplier?: string;
  date_added: string;
  last_updated: string;
  is_active?: boolean;
  created_by?: string;
  updated_by?: string;
}

export interface Customer {
  id?: string;
  customer_code?: string;
  first_name: string;
  last_name?: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  postal_code?: string;
  country?: string;
  tax_id?: string;
  customer_type: 'individual' | 'business';
  credit_limit?: number;
  discount_percentage?: number;
  is_active: boolean;
  notes?: string;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface Sale {
  id?: string;
  sale_number: string;
  customer_id?: string;
  customer_name?: string;
  customer_email?: string;
  sale_date: string;
  subtotal: number;
  tax_amount: number;
  discount_amount: number;
  total_amount: number;
  payment_method: string;
  payment_status: 'pending' | 'partial' | 'completed' | 'refunded';
  sale_status: 'draft' | 'confirmed' | 'delivered' | 'cancelled';
  notes?: string;
  invoice_generated: boolean;
  invoice_number?: string;
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by?: string;
  items?: SaleItem[];
  customer?: Customer;
  // Campos calculados de la vista
  customer_full_name?: string;
  customer_email_registered?: string;
  customer_phone?: string;
  created_by_name?: string;
  items_count?: number;
  payment_summary?: string;
}

export interface SaleItem {
  id?: string;
  sale_id?: string;
  product_id?: string;
  product_barcode?: string;
  product_name: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
  discount_amount: number;
  tax_rate: number;
  tax_amount: number;
  line_total: number;
  created_at?: string;
  product?: Product;
}

export interface SalePayment {
  id?: string;
  sale_id: string;
  payment_method: string;
  amount: number;
  payment_date: string;
  transaction_reference?: string;
  notes?: string;
  created_at: string;
  created_by: string;
}

export interface SaleReturn {
  id?: string;
  original_sale_id: string;
  return_number: string;
  return_date: string;
  return_reason: string;
  return_type: 'full' | 'partial';
  total_refund: number;
  refund_method: string;
  status: 'pending' | 'approved' | 'completed' | 'rejected';
  notes?: string;
  created_at: string;
  created_by: string;
  approved_by?: string;
  approved_at?: string;
  items?: SaleReturnItem[];
}

export interface SaleReturnItem {
  id?: string;
  return_id: string;
  original_sale_item_id: string;
  product_id?: string;
  product_name: string;
  quantity_returned: number;
  unit_price: number;
  refund_amount: number;
  condition: 'good' | 'damaged' | 'defective';
  restock: boolean;
  created_at: string;
}

export interface Transaction {
  id?: string;
  sale_id: string;
  transaction_id: string;
  amount: number;
  currency: string;
  payment_method: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  gateway_response?: Record<string, unknown>;
  date: string;
  verified: boolean;
}

// Configuration Types
export interface CompanySettings {
  id?: string;
  company_name: string;
  company_email: string;
  company_phone: string;
  company_address: string;
  company_city: string;
  company_postal_code: string;
  company_country: string;
  tax_id: string;
  logo_url?: string;
  website?: string;
  default_currency: string;
  default_tax_rate: number;
  invoice_prefix: string;
  invoice_counter: number;
  receipt_prefix: string;
  receipt_counter: number;
  updated_at: string;
  updated_by: string;
}

export interface SystemSettings {
  id?: string;
  setting_key: string;
  setting_value: string;
  setting_type: 'string' | 'number' | 'boolean' | 'json';
  description?: string;
  category: 'general' | 'inventory' | 'sales' | 'payments' | 'notifications' | 'security';
  is_public: boolean;
  updated_at: string;
  updated_by: string;
}

export interface NotificationTemplate {
  id?: string;
  template_name: string;
  template_type: 'email' | 'sms' | 'whatsapp' | 'system';
  event_trigger: string;
  subject?: string;
  content: string;
  variables: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
  created_by: string;
  updated_by?: string;
}

export interface BackupConfiguration {
  id?: string;
  backup_name: string;
  backup_type: 'full' | 'incremental' | 'differential';
  schedule_type: 'manual' | 'daily' | 'weekly' | 'monthly';
  schedule_time?: string;
  schedule_day?: string;
  retention_days: number;
  storage_location: 'local' | 'cloud' | 'both';
  is_active: boolean;
  last_backup?: string;
  next_backup?: string;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface AuditLog {
  id?: string;
  user_id?: string;
  user_email: string;
  action: string;
  entity_type: string;
  entity_id?: string;
  old_values?: Record<string, unknown>;
  new_values?: Record<string, unknown>;
  ip_address?: string;
  user_agent?: string;
  timestamp: string;
  details?: string;
}

export interface InventoryAlert {
  id?: string;
  product_id: string;
  alert_type: 'low_stock' | 'out_of_stock' | 'expired' | 'expiring_soon';
  alert_level: 'info' | 'warning' | 'critical';
  message: string;
  is_read: boolean;
  is_resolved: boolean;
  created_at: string;
  resolved_at?: string;
  resolved_by?: string;
  product?: Product;
}