-- ==============================================================================
-- MIGRATION: 20260311_direct_stock_purchase.sql
-- DESCRIPTION: Modifies the purchase process to immediately update stock
-- without a grading step, supporting only 'Telur Hero' and 'Salted Egg'.
-- ==============================================================================

-- 1. Add product_id to purchases
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS product_id TEXT REFERENCES inventory(id) DEFAULT 'hero';

-- 2. Redefine create_purchase_with_utang
CREATE OR REPLACE FUNCTION create_purchase_with_utang(
  p_supplier_id UUID,
  p_total_eggs INTEGER,
  p_price_per_egg DECIMAL,
  p_amount_paid DECIMAL DEFAULT 0,
  p_notes TEXT DEFAULT NULL,
  p_product_id TEXT DEFAULT 'hero'
) RETURNS JSONB AS $$
DECLARE
  v_total_cost DECIMAL := p_total_eggs * p_price_per_egg;
  v_remaining DECIMAL := v_total_cost - p_amount_paid;
  v_purchase_id UUID;
  v_supplier_name TEXT;
  v_status TEXT;
  v_product_label TEXT;
BEGIN
  SELECT name INTO v_supplier_name FROM suppliers WHERE id = p_supplier_id;
  IF v_supplier_name IS NULL THEN
    RETURN jsonb_build_object('error', 'Supplier tidak ditemukan.');
  END IF;

  v_status := CASE WHEN v_remaining <= 0 THEN 'lunas'
                   WHEN p_amount_paid > 0 THEN 'cicilan'
                   ELSE 'utang' END;

  INSERT INTO purchases (supplier_id, total_eggs_bought, price_per_egg,
    total_cost, amount_paid, remaining_debt, status, notes, product_id)
  VALUES (p_supplier_id, p_total_eggs, p_price_per_egg,
          v_total_cost, p_amount_paid, v_remaining, v_status, p_notes, p_product_id)
  RETURNING id INTO v_purchase_id;

  IF v_remaining > 0 THEN
    INSERT INTO utang_supplier (supplier_id, purchase_id, supplier_name,
      total_amount, paid_amount, remaining, status)
    VALUES (p_supplier_id, v_purchase_id, v_supplier_name,
            v_total_cost, p_amount_paid, v_remaining, 'aktif');

    UPDATE suppliers SET total_outstanding_debt = COALESCE(total_outstanding_debt, 0) + v_remaining
    WHERE id = p_supplier_id;
  END IF;

  INSERT INTO finance_entries (entry_type, category, amount, description,
    reference_type, reference_id)
  VALUES ('expense', 'Pembelian Telur', v_total_cost,
          'Beli ' || p_total_eggs || ' butir dari ' || v_supplier_name,
          'purchase', v_purchase_id);

  IF p_product_id = 'hero' THEN v_product_label := 'Telur Hero';
  ELSIF p_product_id = 'salted_egg' THEN v_product_label := 'Salted Egg';
  ELSE v_product_label := p_product_id; END IF;

  INSERT INTO notifications (type, title, message, link)
  VALUES ('purchase_created', 'Pembelian Baru Dicatat',
          p_total_eggs || ' butir (' || v_product_label || ') dari ' || v_supplier_name ||
          ' — Utang Rp ' || v_remaining, '/stock');

  -- DIRECT STOCK UPDATE
  UPDATE inventory SET current_stock = current_stock + p_total_eggs, hpp_per_egg = p_price_per_egg, updated_at = NOW() WHERE id = p_product_id;
  
  INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
  VALUES (p_product_id, 'arrival', p_total_eggs, v_purchase_id, 'Pembelian langsung (Tanpa Sortir)');
  
  PERFORM recalculate_hpp(p_product_id);
  PERFORM check_safety_stock();

  RETURN jsonb_build_object(
    'success', true,
    'purchase_id', v_purchase_id,
    'total_cost', v_total_cost,
    'remaining_debt', v_remaining
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
