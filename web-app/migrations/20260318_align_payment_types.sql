-- ═══════════════════════════════════════════════════════════════
-- HERO FARM — PAYMENT TYPE ALIGNMENT
-- Date: 2026-03-18
-- Focus: Support Tunai, Transfer, and Piutang in create_sale_v2
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION create_sale_v2(
  p_customer_name TEXT, 
  p_payment_type TEXT, 
  p_items JSONB, 
  p_due_date DATE DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_sale_id UUID;
  v_customer_id UUID;
  v_invoice_no TEXT;
  item JSONB;
  v_inv RECORD;
  v_revenue DECIMAL := 0;
  v_hpp_total DECIMAL := 0;
  v_eggs_out INTEGER;
  v_price DECIMAL;
  v_actual_hpp_per_pack DECIMAL;
  v_status TEXT;
BEGIN
  -- 1. Determine Status
  v_status := CASE 
    WHEN p_payment_type = 'tunai' THEN 'paid'
    WHEN p_payment_type = 'transfer' THEN 'pending'
    WHEN p_payment_type = 'piutang' THEN 'piutang'
    ELSE 'pending'
  END;

  -- 2. CRM Resolution (Find or Create Customer)
  SELECT id INTO v_customer_id FROM customers WHERE name = p_customer_name LIMIT 1;
  IF v_customer_id IS NULL THEN
    INSERT INTO customers (name, total_spent) VALUES (p_customer_name, 0) RETURNING id INTO v_customer_id;
  END IF;

  -- 3. Generate Invoice Number
  v_invoice_no := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6));

  -- 4. Initial Sale Header
  INSERT INTO sales (
    customer_id, invoice_number, total_price, payment_status, 
    total_paid, fulfillment_status, stock_reserved
  )
  VALUES (
    v_customer_id, v_invoice_no, 0, v_status, 
    CASE WHEN v_status = 'paid' THEN 0 ELSE 0 END, -- total_paid will be updated later or kept 0 until reconciled
    'processing', true
  )
  RETURNING id INTO v_sale_id;

  -- 5. Process Items
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    v_eggs_out := (item->>'packs_sold')::INTEGER * COALESCE(v_inv.pack_size, 10);
    v_price := COALESCE((item->>'override_price')::DECIMAL, v_inv.base_price_per_pack, 0);
    v_actual_hpp_per_pack := COALESCE(v_inv.hpp_per_pack, 0);

    INSERT INTO sale_items (
      sale_id, inventory_id, grade, quantity, unit_price, subtotal, unit_cost
    )
    VALUES (
      v_sale_id, v_inv.id, COALESCE(v_inv.grade, v_inv.id),
      (item->>'packs_sold')::INTEGER, v_price,
      (item->>'packs_sold')::INTEGER * v_price,
      v_actual_hpp_per_pack
    );

    -- Update Inventory
    UPDATE inventory SET current_stock = current_stock - v_eggs_out, updated_at = NOW() WHERE id = v_inv.id;
    
    -- Update Supplies (Standard decrement)
    UPDATE inventory SET current_stock = GREATEST(0, current_stock - (item->>'packs_sold')::INTEGER), updated_at = NOW() 
    WHERE id IN ('packaging_standard', 'sticker_label', 'mini_card');

    -- Stock Log
    INSERT INTO stock_logs (inventory_id, log_type, change, notes)
    VALUES (v_inv.id, 'sale_out', -v_eggs_out, 'Sale ' || v_invoice_no);

    v_revenue := v_revenue + ((item->>'packs_sold')::INTEGER * v_price);
    v_hpp_total := v_hpp_total + ((item->>'packs_sold')::INTEGER * v_actual_hpp_per_pack);
  END LOOP;

  -- 6. Final Header Update
  UPDATE sales SET
    total_revenue = v_revenue,
    total_hpp = v_hpp_total,
    gross_profit = v_revenue - v_hpp_total,
    margin_pct = CASE WHEN v_revenue > 0 THEN ((v_revenue - v_hpp_total) / v_revenue) * 100 ELSE 0 END,
    total_price = v_revenue
  WHERE id = v_sale_id;

  -- 7. Integration
  IF v_status = 'piutang' THEN
    INSERT INTO piutang (sale_id, customer_id, customer_name, invoice_no, total_amount, remaining, due_date, status)
    VALUES (v_sale_id, v_customer_id, p_customer_name, v_invoice_no, v_revenue, v_revenue, p_due_date, 'belum_bayar');

    UPDATE customers SET total_piutang = COALESCE(total_piutang, 0) + v_revenue WHERE id = v_customer_id;
  ELSIF v_status = 'paid' THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('income', 'Penjualan Telur', v_revenue, 'Penjualan tunai: ' || v_invoice_no, 'sale', v_sale_id);
    
    UPDATE sales SET total_paid = v_revenue WHERE id = v_sale_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true, 
    'sale_id', v_sale_id,
    'invoice_number', v_invoice_no,
    'status', v_status
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
