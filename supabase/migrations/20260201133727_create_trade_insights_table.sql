/*
  # Create trade insights table

  1. New Tables
    - `trade_insights`
      - `id` (uuid, primary key) - Unique identifier for each trade insight
      - `symbol` (text) - Stock ticker symbol (e.g., AAPL, TSLA)
      - `action` (text) - Trade action: buy, sell, or hold
      - `price` (decimal) - Current/target price
      - `reasoning` (text) - Analysis and reasoning for the trade
      - `confidence` (text) - Confidence level: high, medium, low
      - `metadata` (jsonb) - Additional data from Make.com workflow
      - `created_at` (timestamptz) - Timestamp when insight was created
      
  2. Security
    - Enable RLS on `trade_insights` table
    - Add policy for public read access (anyone can view trade insights)
    - Add policy for authenticated insert (only authenticated users can add insights)
*/

CREATE TABLE IF NOT EXISTS trade_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  symbol text NOT NULL,
  action text NOT NULL CHECK (action IN ('buy', 'sell', 'hold')),
  price decimal(10, 2) NOT NULL,
  reasoning text NOT NULL,
  confidence text NOT NULL DEFAULT 'medium' CHECK (confidence IN ('high', 'medium', 'low')),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE trade_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view trade insights"
  ON trade_insights
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert trade insights"
  ON trade_insights
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_trade_insights_created_at ON trade_insights(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trade_insights_symbol ON trade_insights(symbol);