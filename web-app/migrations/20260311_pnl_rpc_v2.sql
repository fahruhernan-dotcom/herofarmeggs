-- Centralized P&L Summary RPC
-- This RPC calculates comprehensive financial metrics for a given date range.

CREATE OR REPLACE FUNCTION get_pnl_summary(start_date DATE, end_date DATE)
RETURNS TABLE (
  total_revenue DECIMAL,
  total_cogs DECIMAL,
  gross_profit DECIMAL,
  margin_pct DECIMAL,
  total_piutang_active DECIMAL,
  total_utang_active DECIMAL,
  inventory_asset_value DECIMAL
) AS $$
DECLARE
  v_rev DECIMAL;
  v_cogs DECIMAL;
  v_piu DECIMAL;
  v_utang DECIMAL;
  v_stock_val DECIMAL;
BEGIN
  -- 1. Revenue & COGS from Paid Sales
  SELECT 
    COALESCE(SUM(total_revenue), 0),
    COALESCE(SUM(total_hpp), 0)
  INTO v_rev, v_cogs
  FROM sales
  WHERE created_at::DATE BETWEEN start_date AND end_date
    AND payment_status = 'paid'
    AND voided_at IS NULL;

  -- 2. Active Piutang (Total remaining, not limited by date)
  SELECT COALESCE(SUM(remaining), 0)
  INTO v_piu
  FROM piutang
  WHERE status != 'lunas';

  -- 3. Active Utang (Total remaining, not limited by date)
  SELECT COALESCE(SUM(remaining), 0)
  INTO v_utang
  FROM utang_supplier
  WHERE status != 'lunas';

  -- 4. Inventory Value (Current snapshot)
  SELECT COALESCE(SUM(current_stock * COALESCE(cost_price, hpp_per_pack, 0) / 10), 0)
  INTO v_stock_val
  FROM inventory
  WHERE id IN ('hero', 'salted_egg');

  RETURN QUERY SELECT 
    v_rev, 
    v_cogs, 
    (v_rev - v_cogs),
    CASE WHEN v_rev > 0 THEN ((v_rev - v_cogs) / v_rev) * 100 ELSE 0 END,
    v_piu,
    v_utang,
    v_stock_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
