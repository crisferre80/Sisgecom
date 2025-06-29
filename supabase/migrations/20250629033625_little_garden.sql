/*
  # Create Inventory Management Functions

  1. Functions
    - Function to update product stock after sale
    - Function to generate sale numbers
    - Function to get dashboard statistics

  2. Triggers
    - Trigger to update product stock when sale items are inserted
    - Trigger to update last_updated timestamp on products
*/

-- Function to generate unique sale numbers
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS text AS $$
DECLARE
  sale_num text;
  counter integer;
BEGIN
  -- Get today's date in YYYYMMDD format
  sale_num := 'VTA-' || to_char(now(), 'YYYYMMDD') || '-';
  
  -- Get the count of sales today
  SELECT COUNT(*) + 1 INTO counter
  FROM sales
  WHERE date::date = CURRENT_DATE;
  
  -- Pad with zeros to make it 4 digits
  sale_num := sale_num || lpad(counter::text, 4, '0');
  
  RETURN sale_num;
END;
$$ LANGUAGE plpgsql;

-- Function to update product stock
CREATE OR REPLACE FUNCTION update_product_stock()
RETURNS trigger AS $$
BEGIN
  -- Decrease product quantity when sale item is inserted
  IF TG_OP = 'INSERT' THEN
    UPDATE products
    SET quantity = quantity - NEW.quantity,
        last_updated = now()
    WHERE id = NEW.product_id;
    RETURN NEW;
  END IF;
  
  -- Handle updates and deletes if needed
  IF TG_OP = 'UPDATE' THEN
    -- Adjust stock based on quantity difference
    UPDATE products
    SET quantity = quantity - (NEW.quantity - OLD.quantity),
        last_updated = now()
    WHERE id = NEW.product_id;
    RETURN NEW;
  END IF;
  
  IF TG_OP = 'DELETE' THEN
    -- Restore stock when sale item is deleted
    UPDATE products
    SET quantity = quantity + OLD.quantity,
        last_updated = now()
    WHERE id = OLD.product_id;
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update product stock
DROP TRIGGER IF EXISTS trigger_update_product_stock ON sale_items;
CREATE TRIGGER trigger_update_product_stock
  AFTER INSERT OR UPDATE OR DELETE ON sale_items
  FOR EACH ROW EXECUTE FUNCTION update_product_stock();

-- Function to update last_updated timestamp on products
CREATE OR REPLACE FUNCTION update_last_updated()
RETURNS trigger AS $$
BEGIN
  NEW.last_updated = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_updated on products
DROP TRIGGER IF EXISTS trigger_update_products_timestamp ON products;
CREATE TRIGGER trigger_update_products_timestamp
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_last_updated();

-- Function to get dashboard statistics
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'total_products', (SELECT COUNT(*) FROM products),
    'low_stock_products', (SELECT COUNT(*) FROM products WHERE quantity <= min_stock),
    'total_sales_today', (SELECT COUNT(*) FROM sales WHERE date::date = CURRENT_DATE AND status = 'completed'),
    'total_revenue_today', (SELECT COALESCE(SUM(total), 0) FROM sales WHERE date::date = CURRENT_DATE AND status = 'completed'),
    'pending_transactions', (SELECT COUNT(*) FROM transactions WHERE status = 'pending')
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;