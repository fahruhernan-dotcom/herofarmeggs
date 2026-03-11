-- ─── RPC 1: get_pnl_summary ───
-- Fixes the Rp 0 issue by joining sales and sale_items correctly,
-- and handles the product-specific breakdown for the "Elite" terminal.

CREATE OR REPLACE FUNCTION get_pnl_summary(start_date DATE, end_date DATE)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_revenue',    COALESCE(SUM(s.total_revenue), 0),
    'total_hpp',        COALESCE(SUM(si.hpp_total), 0),
    'gross_profit',     COALESCE(SUM(s.total_revenue) - SUM(si.hpp_total), 0),
    'gross_margin',     CASE WHEN SUM(s.total_revenue) > 0 
                          THEN ROUND((SUM(s.total_revenue) - SUM(si.hpp_total)) / SUM(s.total_revenue) * 100, 2)
                          ELSE 0 END,
    'total_discount',   COALESCE(SUM(s.discount_amount), 0),
    'active_piutang',   (SELECT COALESCE(SUM(remaining), 0) FROM piutang WHERE status != 'lunas'),
    'nilai_stok',       (
      SELECT COALESCE(SUM(i.current_stock * i.hpp_per_egg), 0)
      FROM inventory i
      WHERE i.id IN ('hero', 'salted_egg')
    ),
    'by_product',       (
      SELECT COALESCE(json_agg(json_build_object(
        'product', si2.inventory_id,
        'revenue', SUM(si2.revenue),
        'hpp',     SUM(si2.hpp_total),
        'qty_sold',SUM(si2.packs_sold)
      )), '[]'::json)
      FROM sale_items si2
      JOIN sales s2 ON s2.id = si2.sale_id
      WHERE s2.created_at::date BETWEEN start_date AND end_date
      AND s2.voided_at IS NULL
      GROUP BY si2.inventory_id
    ),
    'piutang_count', (SELECT COUNT(*) FROM piutang WHERE status != 'lunas'),
    'utang_count', (SELECT COUNT(*) FROM utang_supplier WHERE status != 'lunas'),
    'total_utang', (SELECT COALESCE(SUM(remaining), 0) FROM utang_supplier WHERE status != 'lunas')
  ) INTO result
  FROM sales s
  LEFT JOIN sale_items si ON si.sale_id = s.id
  WHERE s.created_at::date BETWEEN start_date AND end_date
  AND s.voided_at IS NULL;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;
