/*
  # Create Sale Items Table

  1. New Tables
    - `sale_items`
      - `id` (uuid, primary key)
      - `sale_id` (uuid, references sales)
      - `product_id` (uuid, references products)
      - `product_name` (text, not null)
      - `quantity` (integer, not null)
      - `unit_price` (decimal, not null)
      - `total_price` (decimal, not null)

  2. Security
    - Enable RLS on `sale_items` table
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES sales(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id),
  product_name text NOT NULL,
  quantity integer NOT NULL,
  unit_price decimal(10,2) NOT NULL,
  total_price decimal(10,2) NOT NULL
);

ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all sale items"
  ON sale_items
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert sale items"
  ON sale_items
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update sale items"
  ON sale_items
  FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Users can delete sale items"
  ON sale_items
  FOR DELETE
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id);