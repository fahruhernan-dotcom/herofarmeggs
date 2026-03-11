-- FIX: Dashboard KPIs RPC
-- 1. Revenue now falls back to total_price if total_revenue is null
-- 2. Revenue only counts paid sales
-- 3. Net Position calculation uses accurate revenue

CREATE OR REPLACE FUNCTION get_dashboard_kpis()
RETURNS JSONB AS $$
DECLARE
  v_rev DECIMAL := 0; 
  v_profit DECIMAL := 0; 
  v_piu DECIMAL := 0; 
  v_modal DECIMAL := 0;
BEGIN
  -- Revenue & Profit dari Sales (Only Paid)
  SELECT 
    COALESCE(SUM(COALESCE(total_revenue, total_price)), 0), 
    COALESCE(SUM(gross_profit), 0) 
  INTO v_rev, v_profit 
  FROM sales 
  WHERE voided_at IS NULL AND payment_status = 'paid';
  
  -- Piutang (Gabungkan status pending & unpaid)
  SELECT COALESCE(SUM(remaining), 0) 
  INTO v_piu 
  FROM piutang 
  WHERE status IN ('belum_bayar', 'sebagian');

  -- Modal Pembelian
  SELECT COALESCE(SUM(total_cost), 0) 
  INTO v_modal 
  FROM purchases;

  RETURN jsonb_build_object(
    'total_revenue', v_rev,
    'net_profit', v_profit,
    'net_position', (v_rev - v_modal),
    'total_piutang', v_piu,
    'piutang_count', (SELECT COUNT(*) FROM piutang WHERE status IN ('belum_bayar', 'sebagian')),
    'total_utang', (SELECT COALESCE(SUM(remaining), 0) FROM utang_supplier WHERE status != 'lunas'),
    'last_sync', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
