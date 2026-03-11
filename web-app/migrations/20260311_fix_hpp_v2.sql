-- Standardize Product Names and Fix HPP Calculation in create_sale_v2
-- This migration ensures that product labels are consistent and HPP is accurately recorded during sales.

-- 1. Standardize Product Labels in Inventory
UPDATE inventory SET label = 'Telur Hero', grade = 'HERO' WHERE id = 'hero';
UPDATE inventory SET label = 'Salted Egg', grade = 'SALTED_EGG' WHERE id = 'salted_egg';

-- 2. Update create_sale_v2 RPC
CREATE OR REPLACE FUNCTION create_sale_v2(
  p_customer_name TEXT,
  p_payment_type TEXT,
  p_items JSONB,
  p_due_date DATE DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  item JSONB;
  v_inv RECORD;
  v_max_packs INTEGER;
  v_eggs_out INTEGER;
  v_revenue DECIMAL := 0;
  v_hpp_total DECIMAL := 0;
  v_sale_id UUID;
  v_invoice_no TEXT;
  v_customer_id UUID;
  v_price DECIMAL;
  v_actual_hpp_per_pack DECIMAL;
BEGIN
  -- Basic Validation
  IF p_payment_type = 'piutang' AND p_due_date IS NULL THEN
    RETURN jsonb_build_object('error', 'Transaksi piutang harus memiliki tanggal jatuh tempo.');
  END IF;

  -- Verify and Calculate
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    
    IF v_inv IS NULL THEN
        RETURN jsonb_build_object('error', 'Produk dengan ID ' || (item->>'inventory_id') || ' tidak ditemukan.');
    END IF;

    v_max_packs := FLOOR(v_inv.current_stock::DECIMAL / COALESCE(v_inv.pack_size, 10));

    IF (item->>'packs_sold')::INTEGER > v_max_packs THEN
      RETURN jsonb_build_object(
        'error', 'Stok ' || COALESCE(v_inv.label, v_inv.id) || ' tidak cukup. ' ||
                 'Tersedia: ' || v_max_packs || ' pack, diminta: ' || (item->>'packs_sold') || ' pack.'
      );
    END IF;
  END LOOP;

  -- Generate Invoice Number
  v_invoice_no := 'EP-' || TO_CHAR(NOW(), 'YYYYMMDD') ||
    LPAD(((SELECT COUNT(*) FROM sales WHERE created_at::DATE = CURRENT_DATE) + 1)::TEXT, 3, '0');

  -- CRM Resolution
  INSERT INTO customers (name) VALUES (p_customer_name)
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_customer_id FROM customers WHERE name = p_customer_name;

  -- Create Main Sale Record
  INSERT INTO sales (
    invoice_number, 
    customer_id, 
    customer_name, 
    payment_type,
    total_revenue, 
    total_hpp, 
    gross_profit, 
    margin_pct, 
    payment_status, 
    total_price, 
    fulfillment_status,
    stock_reserved -- Ensure this is tracked
  )
  VALUES (
    v_invoice_no, 
    v_customer_id, 
    p_customer_name, 
    p_payment_type,
    0, 0, 0, 0,
    CASE WHEN p_payment_type = 'tunai' THEN 'paid' ELSE 'pending' END,
    0, 
    'processing',
    true -- We deduct stock immediately in this RPC
  )
  RETURNING id INTO v_sale_id;

  -- Process Items
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    v_eggs_out := (item->>'packs_sold')::INTEGER * COALESCE(v_inv.pack_size, 10);
    v_price := COALESCE((item->>'override_price')::DECIMAL, v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0);
    
    -- IMPORTANT: Calculate current HPP dynamically to ensure accuracy
    -- If cost_price is zero, fall back to hpp_per_pack
    v_actual_hpp_per_pack := COALESCE(v_inv.cost_price, v_inv.hpp_per_pack, 0);

    INSERT INTO sale_items (
      sale_id, 
      inventory_id, 
      grade, 
      packs_sold, 
      eggs_out, 
      price_per_pack, 
      hpp_per_pack, 
      revenue, 
      hpp_total, 
      gross_profit,
      egg_type, -- Legacy compatibility
      quantity, -- Legacy compatibility
      unit_price, -- Legacy compatibility
      subtotal, -- Legacy compatibility
      unit_cost, -- Legacy compatibility
      price_at_sale
    )
    VALUES (
      v_sale_id, 
      v_inv.id, 
      COALESCE(v_inv.grade, v_inv.id),
      (item->>'packs_sold')::INTEGER, 
      v_eggs_out,
      v_price, 
      v_actual_hpp_per_pack,
      (item->>'packs_sold')::INTEGER * v_price,
      (item->>'packs_sold')::INTEGER * v_actual_hpp_per_pack,
      (item->>'packs_sold')::INTEGER * (v_price - v_actual_hpp_per_pack),
      v_inv.id, 
      (item->>'packs_sold')::INTEGER, 
      v_price,
      (item->>'packs_sold')::INTEGER * v_price,
      v_actual_hpp_per_pack, 
      v_price
    );

    -- Price Override Tracking
    IF v_price != COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0) THEN
      INSERT INTO price_overrides (sale_id, inventory_id, original_price, override_price,
        discount_amount, discount_pct, reason, product_name)
      VALUES (v_sale_id, v_inv.id,
              COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0), v_price,
              COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0) - v_price,
              CASE WHEN COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0) > 0 
                   THEN ((COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0) - v_price) /
                         COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack, 0)) * 100
                   ELSE 0 END,
              COALESCE(item->>'override_reason', 'Adjusted by admin'),
              COALESCE(v_inv.label, v_inv.id));
    END IF;

    -- Update Egg Inventory
    UPDATE inventory SET
      current_stock = current_stock - v_eggs_out,
      updated_at = NOW()
    WHERE id = v_inv.id;

    -- Update Supply Inventory (1 Box, 1 Sticker, 1 Card per pack)
    UPDATE inventory SET current_stock = GREATEST(0, current_stock - (item->>'packs_sold')::INTEGER), updated_at = NOW() 
    WHERE id IN ('packaging_standard', 'sticker_label', 'mini_card');

    -- Log Supplies Change
    INSERT INTO stock_logs (inventory_id, log_type, change, notes, created_by)
    SELECT id, 'sale_out', -(item->>'packs_sold')::INTEGER, 'Supplies for ' || v_invoice_no, NULL
    FROM inventory WHERE id IN ('packaging_standard', 'sticker_label', 'mini_card') AND (item->>'packs_sold')::INTEGER > 0;

    -- Log Egg Stock Change
    INSERT INTO stock_logs (inventory_id, log_type, change, notes, created_by)
    VALUES (v_inv.id, 'sale_out', -v_eggs_out, 'Sale ' || v_invoice_no, NULL);

    v_revenue := v_revenue + ((item->>'packs_sold')::INTEGER * v_price);
    v_hpp_total := v_hpp_total + ((item->>'packs_sold')::INTEGER * v_actual_hpp_per_pack);
  END LOOP;

  -- Final Header Update
  UPDATE sales SET
    total_revenue = v_revenue,
    total_hpp = v_hpp_total,
    gross_profit = v_revenue - v_hpp_total,
    margin_pct = CASE WHEN v_revenue > 0 THEN ((v_revenue - v_hpp_total) / v_revenue) * 100 ELSE 0 END,
    total_price = v_revenue
  WHERE id = v_sale_id;

  -- Finance Integration
  IF p_payment_type = 'piutang' THEN
    INSERT INTO piutang (sale_id, customer_id, customer_name, invoice_no,
      total_amount, remaining, due_date)
    VALUES (v_sale_id, v_customer_id, p_customer_name, v_invoice_no,
            v_revenue, v_revenue, p_due_date);

    UPDATE customers SET total_piutang = COALESCE(total_piutang, 0) + v_revenue
    WHERE id = v_customer_id;
  ELSE
    -- Cash Sale (tunai)
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('income', 'Penjualan Telur', v_revenue,
            'Penjualan tunai: ' || v_invoice_no, 'sale', v_sale_id);
  END IF;

  -- Loyalty Update
  UPDATE customers SET
    total_orders = COALESCE(total_orders, 0) + 1,
    total_spent = CASE WHEN p_payment_type = 'tunai'
                  THEN COALESCE(total_spent, 0) + v_revenue ELSE COALESCE(total_spent, 0) END
  WHERE id = v_customer_id;

  -- Notifications
  INSERT INTO notifications (type, title, message, link)
  VALUES (CASE WHEN p_payment_type = 'tunai' THEN 'sale_done' ELSE 'sale_pending' END,
          CASE WHEN p_payment_type = 'tunai' THEN '✅ Penjualan Tunai Berhasil'
               ELSE '⏳ Pesanan Tempo (Piutang)' END,
          v_invoice_no || ' — ' || p_customer_name || ' — Rp ' || v_revenue::TEXT,
          '/sales');

  RETURN jsonb_build_object(
    'success', true, 
    'sale_id', v_sale_id,
    'invoice_number', v_invoice_no,
    'total_revenue', v_revenue,
    'gross_profit', v_revenue - v_hpp_total
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
