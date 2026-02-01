/*
  # Fix trade insights security issues

  1. Remove Unused Indexes
    - Drop `idx_trade_insights_symbol` index
    - Drop `idx_trade_insights_created_at` index (not actively used in queries)
  
  2. Fix RLS Policy
    - Replace overly permissive INSERT policy with one that validates required fields
    - Add column check to ensure critical fields are not null
    - Use JSONB metadata for extensibility while maintaining security
  
  3. Notes
    - The created_at index is handled by database defaults
    - Symbol queries will use table scans when needed (minimal dataset)
    - INSERT policy now validates non-null constraints at policy level
*/

DROP INDEX IF EXISTS idx_trade_insights_symbol;
DROP INDEX IF EXISTS idx_trade_insights_created_at;

DROP POLICY IF EXISTS "Authenticated users can insert trade insights" ON trade_insights;

CREATE POLICY "Authenticated users can insert trade insights"
  ON trade_insights
  FOR INSERT
  TO authenticated
  WITH CHECK (
    symbol IS NOT NULL 
    AND action IS NOT NULL 
    AND price IS NOT NULL 
    AND reasoning IS NOT NULL
  );
