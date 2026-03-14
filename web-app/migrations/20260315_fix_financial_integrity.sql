
-- ==============================================================================
-- MIGRATION: 20260315_fix_financial_integrity.sql
-- DESCRIPTION: 
-- 1. Fix create_sale_v2 to use correct inventory columns (hpp_per_pack).
-- 2. Create create_supply_purchase RPC for RestockSuppliesSlideOver.vue.
-- ==============================================================================

-- 1. Fix create_sale_v2 RPC
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
    invoice_number, customer_id, customer_name, payment_type,
    total_revenue, total_hpp, gross_profit, margin_pct, 
    payment_status, total_price, fulfillment_status, stock_reserved
  )
  VALUES (
    v_invoice_no, v_customer_id, p_customer_name, p_payment_type,
    0, 0, 0, 0,
    CASE WHEN p_payment_type = 'tunai' THEN 'paid' ELSE 'pending' END,
    0, 'processing', true
  )
  RETURNING id INTO v_sale_id;

  -- Process Items
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    v_eggs_out := (item->>'packs_sold')::INTEGER * COALESCE(v_inv.pack_size, 10);
    v_price := COALESCE((item->>'override_price')::DECIMAL, v_inv.base_price_per_pack, 0);
    
    -- FIX: Use correct column 'hpp_per_pack'
    v_actual_hpp_per_pack := COALESCE(v_inv.hpp_per_pack, 0);

    INSERT INTO sale_items (
      sale_id, inventory_id, grade, packs_sold, eggs_out, 
      price_per_pack, hpp_per_pack, revenue, hpp_total, gross_profit,
      egg_type, quantity, unit_price, subtotal, unit_cost, price_at_sale
    )
    VALUES (
      v_sale_id, v_inv.id, COALESCE(v_inv.grade, v_inv.id),
      (item->>'packs_sold')::INTEGER, v_eggs_out,
      v_price, v_actual_hpp_per_pack,
      (item->>'packs_sold')::INTEGER * v_price,
      (item->>'packs_sold')::INTEGER * v_actual_hpp_per_pack,
      (item->>'packs_sold')::INTEGER * (v_price - v_actual_hpp_per_pack),
      v_inv.id, (item->>'packs_sold')::INTEGER, v_price,
      (item->>'packs_sold')::INTEGER * v_price,
      v_actual_hpp_per_pack, v_price
    );

    -- Update Inventory
    UPDATE inventory SET
      current_stock = current_stock - v_eggs_out,
      updated_at = NOW()
    WHERE id = v_inv.id;

    -- Update Supplies
    UPDATE inventory SET current_stock = GREATEST(0, current_stock - (item->>'packs_sold')::INTEGER), updated_at = NOW() 
    WHERE id IN ('packaging_standard', 'sticker_label', 'mini_card');

    -- Logs
    INSERT INTO stock_logs (inventory_id, log_type, change, notes)
    VALUES (v_inv.id, 'sale_out', -v_eggs_out, 'Sale ' || v_invoice_no);

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
      total_amount, remaining, due_date, status)
    VALUES (v_sale_id, v_customer_id, p_customer_name, v_invoice_no,
            v_revenue, v_revenue, p_due_date, 'belum_bayar');

    UPDATE customers SET total_piutang = COALESCE(total_piutang, 0) + v_revenue
    WHERE id = v_customer_id;
  ELSE
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('income', 'Penjualan Telur', v_revenue,
            'Penjualan tunai: ' || v_invoice_no, 'sale', v_sale_id);
  END IF;

  RETURN jsonb_build_object(
    'success', true, 
    'sale_id', v_sale_id,
    'invoice_number', v_invoice_no
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Create create_supply_purchase RPC
CREATE OR REPLACE FUNCTION create_supply_purchase(
  p_supplier_id UUID,
  p_inventory_id TEXT,
  p_qty INTEGER,
  p_price_per_unit DECIMAL,
  p_shipping_cost DECIMAL DEFAULT 0,
  p_amount_paid DECIMAL DEFAULT 0,
  p_damaged_qty INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_total_cost DECIMAL := (p_qty * p_price_per_unit) + p_shipping_cost;
  v_remaining DECIMAL := v_total_cost - p_amount_paid;
  v_usable_qty INTEGER := p_qty - p_damaged_qty;
  v_effective_cost DECIMAL := v_total_cost / GREATEST(v_usable_qty, 1);
  v_purchase_id UUID;
  v_supplier_name TEXT;
  v_status TEXT;
BEGIN
  SELECT name INTO v_supplier_name FROM suppliers WHERE id = p_supplier_id;
  IF v_supplier_name IS NULL THEN
    RETURN jsonb_build_object('error', 'Supplier tidak ditemukan.');
  END IF;

  v_status := CASE WHEN v_remaining <= 0 THEN 'lunas'
                   WHEN p_amount_paid > 0 THEN 'cicilan'
                   ELSE 'utang' END;

  -- Record Purchase
  INSERT INTO purchases (supplier_id, total_eggs_bought, price_per_egg,
    total_cost, amount_paid, remaining_debt, status, product_id, notes)
  VALUES (p_supplier_id, p_qty, p_price_per_unit,
          v_total_cost, p_amount_paid, v_remaining, v_status, p_inventory_id, 'Restock Supply')
  RETURNING id INTO v_purchase_id;

  -- Record Debt if exists
  IF v_remaining > 0 THEN
    INSERT INTO utang_supplier (supplier_id, purchase_id, supplier_name,
      total_amount, paid_amount, remaining, status)
    VALUES (p_supplier_id, v_purchase_id, v_supplier_name,
            v_total_cost, p_amount_paid, v_remaining, 'aktif');

    UPDATE suppliers SET total_outstanding_debt = COALESCE(total_outstanding_debt, 0) + v_remaining
    WHERE id = p_supplier_id;
  END IF;

  -- Finance Entry (Expense)
  INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
  VALUES ('expense', 'Pembelian Supply', v_total_cost,
          'Beli ' || p_qty || ' unit ' || p_inventory_id || ' dari ' || v_supplier_name,
          'purchase', v_purchase_id);

  -- Update Inventory Stock & Effective Cost
  UPDATE inventory SET 
    current_stock = current_stock + v_usable_qty,
    cost_per_egg = v_effective_cost, -- For supplies, cost_per_egg is used as unit cost in calculations
    updated_at = NOW()
  WHERE id = p_inventory_id;

  -- Log
  INSERT INTO stock_logs (inventory_id, log_type, change, notes)
  VALUES (p_inventory_id, 'arrival', v_usable_qty, 'Restock from ' || v_supplier_name);

  RETURN jsonb_build_object(
    'success', true,
    'purchase_id', v_purchase_id,
    'total_cost', v_total_cost,
    'remaining_debt', v_remaining
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
