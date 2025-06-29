/*
  # Create Transactions Table

  1. New Tables
    - `transactions`
      - `id` (uuid, primary key)
      - `sale_id` (uuid, references sales)
      - `transaction_id` (text, unique, not null)
      - `amount` (decimal, not null)
      - `currency` (text, default 'USD')
      - `payment_method` (text, not null)
      - `status` (enum: pending, completed, failed, refunded)
      - `gateway_response` (jsonb, optional)
      - `date` (timestamp, default now)
      - `verified` (boolean, default false)

  2. Security
    - Enable RLS on `transactions` table
    - Add policies for authenticated users
*/

CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES sales(id),
  transaction_id text UNIQUE NOT NULL,
  amount decimal(10,2) NOT NULL,
  currency text DEFAULT 'USD',
  payment_method text NOT NULL,
  status transaction_status DEFAULT 'pending',
  gateway_response jsonb,
  date timestamptz DEFAULT now(),
  verified boolean DEFAULT false
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all transactions"
  ON transactions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert transactions"
  ON transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update transactions"
  ON transactions
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_sale_id ON transactions(sale_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_id ON transactions(transaction_id);