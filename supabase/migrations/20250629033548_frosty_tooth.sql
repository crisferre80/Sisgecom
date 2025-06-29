/*
  # Create Products Table

  1. New Tables
    - `products`
      - `id` (uuid, primary key)
      - `barcode` (text, unique, not null)
      - `name` (text, not null)
      - `price` (decimal, not null)
      - `quantity` (integer, not null, default 0)
      - `min_stock` (integer, not null, default 5)
      - `category` (text, not null)
      - `supplier` (text, not null)
      - `description` (text, optional)
      - `date_added` (timestamp, default now)
      - `last_updated` (timestamp, default now)

  2. Security
    - Enable RLS on `products` table
    - Add policy for authenticated users to read all products
    - Add policy for authenticated users to insert/update/delete products
*/

CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode text UNIQUE NOT NULL,
  name text NOT NULL,
  price decimal(10,2) NOT NULL,
  quantity integer NOT NULL DEFAULT 0,
  min_stock integer NOT NULL DEFAULT 5,
  category text NOT NULL,
  supplier text NOT NULL,
  description text,
  date_added timestamptz DEFAULT now(),
  last_updated timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all products"
  ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert products"
  ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update products"
  ON products
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Users can delete products"
  ON products
  FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_low_stock ON products(quantity, min_stock);