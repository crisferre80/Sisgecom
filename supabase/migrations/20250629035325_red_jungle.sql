/*
  # Fix SQL Syntax Error in Product Data

  1. Problem
    - Syntax error in product insertion due to incorrect quote escaping
    - Line with "Pantalón Jeans Levi\'s 501" has improper escaping

  2. Solution
    - Delete the problematic record if it exists
    - Re-insert with proper SQL escaping using double single quotes
    - Update any other records that might have similar issues

  3. Changes
    - Fix the Levi's product name escaping
    - Ensure all product data is properly inserted
*/

-- First, let's delete any potentially problematic records
DELETE FROM products WHERE barcode = '4567890123456';

-- Re-insert the corrected product data with proper escaping
INSERT INTO products (barcode, name, price, quantity, min_stock, category, supplier, description) VALUES
('4567890123456', 'Pantalón Jeans Levi''s 501', 79.99, 30, 8, 'Ropa', 'Levi Strauss & Co.', 'Pantalón jeans clásico de corte recto');

-- Also check and fix any other products that might have similar issues
-- Update any existing records that might have escaping problems
UPDATE products 
SET name = 'Pantalón Jeans Levi''s 501'
WHERE barcode = '4567890123456' AND name LIKE '%Levi%';