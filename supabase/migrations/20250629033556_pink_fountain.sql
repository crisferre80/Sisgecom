/*
  # Create Sales Table

  1. New Tables
    - `sales`
      - `id` (uuid, primary key)
      - `sale_number` (text, unique, not null)
      - `date` (timestamp, default now)
      - `total` (decimal, not null)
      - `tax` (decimal, default 0)
      - `payment_method` (text, not null)
      - `status` (enum: pending, completed, cancelled)
      - `customer_name` (text, optional)
      - `customer_email` (text, optional)
      - `created_by` (uuid, references auth.users)

  2. Security
    - Enable RLS on `sales` table
    - Add policies for authenticated users
*/

CREATE TYPE sale_status AS ENUM ('pending', 'completed', 'cancelled');

CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_number text UNIQUE NOT NULL,
  date timestamptz DEFAULT now(),
  total decimal(10,2) NOT NULL,
  tax decimal(10,2) DEFAULT 0,
  payment_method text NOT NULL,
  status sale_status DEFAULT 'pending',
  customer_name text,
  customer_email text,
  created_by uuid REFERENCES auth.users(id)
);

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all sales"
  ON sales
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert sales"
  ON sales
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update sales"
  ON sales
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status);
CREATE INDEX IF NOT EXISTS idx_sales_created_by ON sales(created_by);