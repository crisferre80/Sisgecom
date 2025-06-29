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
  gateway_response?: any;
  date: string;
  verified: boolean;
}

export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'cashier' | 'viewer';
  created_at: string;
  last_login?: string;
}

export interface DashboardStats {
  total_products: number;
  low_stock_products: number;
  total_sales_today: number;
  total_revenue_today: number;
  pending_transactions: number;
}