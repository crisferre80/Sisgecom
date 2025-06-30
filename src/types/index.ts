export interface Product {
  id?: string;
  barcode: string;
  name: string;
  price: number;
  quantity: number;
  min_stock: number;
  category: string;
  supplier: string;
  date_added: string;
  last_updated: string;
  description?: string;
}

export interface Sale {
  id?: string;
  sale_number: string;
  date: string;
  total: number;
  tax: number;
  payment_method: string;
  status: 'pending' | 'completed' | 'cancelled';
  items: SaleItem[];
  customer_name?: string;
  customer_email?: string;
  created_by: string;
}

export interface SaleItem {
  id?: string;
  sale_id?: string;
  product_id: string;
  product_name: string;
  quantity: number;
  unit_price: number;
  total_price: number;
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

export interface User {
  id: string;
  user_id: string; // UUID del usuario en auth.users
  email: string;
  name: string;
  role?: 'admin' | 'manager' | 'cashier' | 'viewer';
  created_at: string;
  last_login?: string;
  auth_created_at?: string; // Fecha de creación en auth.users
  has_active_session?: boolean; // Si tiene sesión activa
  // Campos adicionales para gestión completa
  first_name?: string;
  last_name?: string;
  phone?: string;
  avatar_url?: string;
  status: 'active' | 'inactive' | 'blocked';
  department?: string;
  employee_id?: string;
  hire_date?: string;
  permissions?: UserPermission[];
  updated_at: string;
  updated_by?: string;
}

export interface UserPermission {
  id?: string;
  user_id: string;
  module: 'inventory' | 'sales' | 'payments' | 'users' | 'reports' | 'settings';
  action: 'read' | 'write' | 'delete' | 'admin';
  granted_at: string;
  granted_by: string;
}

export interface UserSession {
  id?: string;
  user_id: string;
  session_token: string;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
  expires_at: string;
  last_activity: string;
}

export interface UserActivity {
  id?: string;
  user_id: string;
  action: string;
  module: string;
  details?: string;
  ip_address?: string;
  created_at: string;
}

export interface UserStats {
  total_users: number;
  active_users: number;
  blocked_users: number;
  admin_count: number;
  manager_count: number;
  cashier_count: number;
  viewer_count: number;
  recent_logins: number;
  new_users_this_month: number;
}

export interface DashboardStats {
  total_products: number;
  low_stock_products: number;
  total_sales_today: number;
  total_revenue_today: number;
  pending_transactions: number;
}

export interface Customer {
  id?: string;
  name: string;
  email?: string;
  phone: string;
  address?: string;
  created_at: string;
  last_payment?: string;
  total_debt: number;
  status: 'active' | 'inactive' | 'blocked';
}

export interface VirtualWallet {
  id?: string;
  customer_id: string;
  wallet_type: 'mercado_pago' | 'yape' | 'plin' | 'tunki' | 'banco_digital' | 'otro';
  wallet_identifier: string; // número de teléfono, email, etc.
  alias?: string;
  is_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface Payment {
  id?: string;
  customer_id: string;
  customer_name: string;
  amount: number;
  payment_method: 'efectivo' | 'tarjeta' | 'transferencia' | 'billetera_virtual';
  wallet_type?: string;
  transaction_reference?: string;
  status: 'pendiente' | 'pagado' | 'vencido' | 'cancelado';
  due_date: string;
  paid_date?: string;
  description: string;
  created_at: string;
  updated_at: string;
  created_by: string;
  payment_proof?: string; // URL del comprobante
  notes?: string;
}

export interface PaymentReminder {
  id?: string;
  payment_id: string;
  customer_id: string;
  reminder_type: 'whatsapp' | 'email' | 'sms';
  message: string;
  sent_at: string;
  status: 'enviado' | 'entregado' | 'leido' | 'fallido';
  response?: string;
}

export interface WhatsAppContact {
  id?: string;
  customer_id: string;
  phone_number: string;
  is_verified: boolean;
  last_message_sent?: string;
  message_count: number;
  created_at: string;
}

export interface PaymentSummary {
  total_pending: number;
  total_paid: number;
  total_overdue: number;
  pending_count: number;
  paid_count: number;
  overdue_count: number;
  this_month_collected: number;
  customers_with_debt: number;
}