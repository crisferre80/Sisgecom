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