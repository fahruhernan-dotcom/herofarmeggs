-- ═══════════════════════════════════════════════════════════════
-- HERO FARM TERMINAL — EVOLUTION MIGRATION
-- Date: 2026-03-03
-- Approach: ADD new tables + ALTER existing tables + 9 RPC functions
-- Safe to re-run (IF NOT EXISTS / CREATE OR REPLACE)
-- ═══════════════════════════════════════════════════════════════

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 1: ALTER EXISTING TABLES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── suppliers: add payment_terms & outstanding debt ───
ALTER TABLE suppliers
  ADD COLUMN IF NOT EXISTS payment_terms TEXT DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS total_outstanding_debt DECIMAL(15,2) DEFAULT 0;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_suppliers_payment_terms') THEN
    ALTER TABLE suppliers ADD CONSTRAINT chk_suppliers_payment_terms
      CHECK (payment_terms IN ('cash','net7','net14','net30'));
  END IF;
END $$;

-- ─── inventory: add grading columns ───
ALTER TABLE inventory
  ADD COLUMN IF NOT EXISTS grade TEXT,
  ADD COLUMN IF NOT EXISTS size_rule TEXT,
  ADD COLUMN IF NOT EXISTS pack_size INTEGER DEFAULT 10,
  ADD COLUMN IF NOT EXISTS retail_price_per_pack DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS hpp_per_egg DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS hpp_per_pack DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS margin_pct DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS safety_stock INTEGER DEFAULT 20,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Seed grade data onto existing inventory rows (safe to re-run)
UPDATE inventory SET grade = 'Hero',   size_rule = '>65g',   retail_price_per_pack = COALESCE(base_price_per_pack, 35000), hpp_per_egg = COALESCE(cost_per_egg, 2600) WHERE id = 'hero'   AND grade IS NULL;
UPDATE inventory SET grade = 'Medium', size_rule = '55-65g', retail_price_per_pack = COALESCE(base_price_per_pack, 27000), hpp_per_egg = COALESCE(cost_per_egg, 2600) WHERE id = 'medium' AND grade IS NULL;
UPDATE inventory SET grade = 'Small',  size_rule = '<55g',   retail_price_per_pack = COALESCE(base_price_per_pack, 20000), hpp_per_egg = COALESCE(cost_per_egg, 2600) WHERE id = 'small'  AND grade IS NULL;

-- ─── sales: add structured columns ───
ALTER TABLE sales
  ADD COLUMN IF NOT EXISTS invoice_number TEXT,
  ADD COLUMN IF NOT EXISTS customer_name TEXT,
  ADD COLUMN IF NOT EXISTS payment_type TEXT DEFAULT 'tunai',
  ADD COLUMN IF NOT EXISTS total_revenue DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS total_hpp DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS gross_profit DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS margin_pct DECIMAL(5,2);

-- ─── customers: add financial tracking ───
ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS total_spent DECIMAL(15,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_piutang DECIMAL(15,2) DEFAULT 0;

-- ─── sale_items: add grade columns ───
ALTER TABLE sale_items
  ADD COLUMN IF NOT EXISTS inventory_id TEXT,
  ADD COLUMN IF NOT EXISTS grade TEXT,
  ADD COLUMN IF NOT EXISTS packs_sold INTEGER,
  ADD COLUMN IF NOT EXISTS eggs_out INTEGER,
  ADD COLUMN IF NOT EXISTS price_per_pack DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS hpp_per_pack DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS revenue DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS hpp_total DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS gross_profit DECIMAL(15,2);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 2: NEW TABLES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── purchases (Pembelian Telur dari Supplier) ───
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_date DATE DEFAULT CURRENT_DATE,
  supplier_id UUID REFERENCES suppliers(id),
  total_eggs_bought INTEGER NOT NULL,
  price_per_egg DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(15,2) NOT NULL,
  amount_paid DECIMAL(15,2) DEFAULT 0,
  remaining_debt DECIMAL(15,2),
  status TEXT DEFAULT 'utang'
    CHECK (status IN ('utang','cicilan','lunas')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── gradings (Sortir Telur setelah Pembelian) ───
CREATE TABLE IF NOT EXISTS gradings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID REFERENCES purchases(id),
  hero_qty INTEGER DEFAULT 0,
  medium_qty INTEGER DEFAULT 0,
  small_qty INTEGER DEFAULT 0,
  total_graded INTEGER,
  graded_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT
);

-- ─── piutang (Customer Receivables) ───
CREATE TABLE IF NOT EXISTS piutang (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID REFERENCES sales(id),
  customer_id UUID REFERENCES customers(id),
  customer_name TEXT NOT NULL,
  invoice_no TEXT NOT NULL,
  total_amount DECIMAL(15,2) NOT NULL,
  paid_amount DECIMAL(15,2) DEFAULT 0,
  remaining DECIMAL(15,2),
  due_date DATE,
  status TEXT DEFAULT 'belum_bayar'
    CHECK (status IN ('belum_bayar','sebagian','lunas')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS piutang_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  piutang_id UUID REFERENCES piutang(id) ON DELETE CASCADE,
  payment_date DATE DEFAULT CURRENT_DATE,
  amount DECIMAL(15,2) NOT NULL,
  method TEXT DEFAULT 'cash' CHECK (method IN ('cash','transfer')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── utang_supplier (Supplier Payables) ───
CREATE TABLE IF NOT EXISTS utang_supplier (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID REFERENCES suppliers(id),
  purchase_id UUID REFERENCES purchases(id),
  supplier_name TEXT NOT NULL,
  total_amount DECIMAL(15,2) NOT NULL,
  paid_amount DECIMAL(15,2) DEFAULT 0,
  remaining DECIMAL(15,2),
  due_date DATE,
  status TEXT DEFAULT 'aktif'
    CHECK (status IN ('aktif','jatuh_tempo','lunas')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS utang_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utang_id UUID REFERENCES utang_supplier(id) ON DELETE CASCADE,
  payment_date DATE DEFAULT CURRENT_DATE,
  amount DECIMAL(15,2) NOT NULL,
  method TEXT DEFAULT 'transfer' CHECK (method IN ('cash','transfer')),
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── stock_opname (Structured) ───
CREATE TABLE IF NOT EXISTS stock_opname (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  opname_date DATE DEFAULT CURRENT_DATE,
  conducted_by TEXT NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','completed')),
  total_difference INTEGER DEFAULT 0,
  shrinkage_loss DECIMAL(15,2) DEFAULT 0,
  notes TEXT,
  approved_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_opname_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  opname_id UUID REFERENCES stock_opname(id) ON DELETE CASCADE,
  inventory_id TEXT REFERENCES inventory(id),
  grade TEXT NOT NULL,
  system_count INTEGER NOT NULL,
  physical_count INTEGER,
  difference INTEGER,
  status TEXT,
  adjustment_reason TEXT,
  shrinkage_value DECIMAL(15,2)
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 3: RPC FUNCTIONS (9 total)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── FUNCTION 1: HPP Calculation ───
CREATE OR REPLACE FUNCTION recalculate_hpp(p_inventory_id TEXT)
RETURNS VOID AS $$
DECLARE
  v_hpp_per_egg DECIMAL(10,2);
  v_pack_size INTEGER;
  v_retail DECIMAL(10,2);
  v_hpp_pack DECIMAL(10,2);
  v_margin DECIMAL(5,2);
BEGIN
  SELECT hpp_per_egg, pack_size, retail_price_per_pack
  INTO v_hpp_per_egg, v_pack_size, v_retail
  FROM inventory WHERE id = p_inventory_id;

  v_hpp_pack := v_pack_size * v_hpp_per_egg * 1.073;
  v_margin := CASE WHEN v_retail > 0 THEN ((v_retail - v_hpp_pack) / v_retail) * 100 ELSE 0 END;

  UPDATE inventory SET
    hpp_per_pack = v_hpp_pack,
    margin_pct = v_margin,
    updated_at = NOW()
  WHERE id = p_inventory_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run initial HPP calculation
SELECT recalculate_hpp('hero');
SELECT recalculate_hpp('medium');
SELECT recalculate_hpp('small');

-- ─── FUNCTION 2: Create Purchase + Auto-Create Utang ───
CREATE OR REPLACE FUNCTION create_purchase_with_utang(
  p_supplier_id UUID,
  p_total_eggs INTEGER,
  p_price_per_egg DECIMAL,
  p_amount_paid DECIMAL DEFAULT 0,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_total_cost DECIMAL := p_total_eggs * p_price_per_egg;
  v_remaining DECIMAL := v_total_cost - p_amount_paid;
  v_purchase_id UUID;
  v_supplier_name TEXT;
  v_status TEXT;
BEGIN
  SELECT name INTO v_supplier_name FROM suppliers WHERE id = p_supplier_id;
  IF v_supplier_name IS NULL THEN
    RETURN jsonb_build_object('error', 'Supplier tidak ditemukan.');
  END IF;

  v_status := CASE WHEN v_remaining = 0 THEN 'lunas'
                   WHEN p_amount_paid > 0 THEN 'cicilan'
                   ELSE 'utang' END;

  INSERT INTO purchases (supplier_id, total_eggs_bought, price_per_egg,
    total_cost, amount_paid, remaining_debt, status, notes)
  VALUES (p_supplier_id, p_total_eggs, p_price_per_egg,
          v_total_cost, p_amount_paid, v_remaining, v_status, p_notes)
  RETURNING id INTO v_purchase_id;

  IF v_remaining > 0 THEN
    INSERT INTO utang_supplier (supplier_id, purchase_id, supplier_name,
      total_amount, paid_amount, remaining, status)
    VALUES (p_supplier_id, v_purchase_id, v_supplier_name,
            v_total_cost, p_amount_paid, v_remaining, 'aktif');

    UPDATE suppliers SET total_outstanding_debt = total_outstanding_debt + v_remaining
    WHERE id = p_supplier_id;
  END IF;

  INSERT INTO finance_entries (entry_type, category, amount, description,
    reference_type, reference_id)
  VALUES ('expense', 'Pembelian Telur', v_total_cost,
          'Beli ' || p_total_eggs || ' butir dari ' || v_supplier_name,
          'purchase', v_purchase_id);

  INSERT INTO notifications (type, title, message, link)
  VALUES ('purchase_created', 'Pembelian Baru Dicatat',
          p_total_eggs || ' butir dari ' || v_supplier_name ||
          ' — Utang Rp ' || v_remaining, '/inventory');

  RETURN jsonb_build_object(
    'success', true,
    'purchase_id', v_purchase_id,
    'total_cost', v_total_cost,
    'remaining_debt', v_remaining
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 3: Create Grading + Update Inventory Stock ───
CREATE OR REPLACE FUNCTION create_grading(
  p_purchase_id UUID,
  p_hero_qty INTEGER,
  p_medium_qty INTEGER,
  p_small_qty INTEGER,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_expected INTEGER;
  v_total_graded INTEGER := p_hero_qty + p_medium_qty + p_small_qty;
  v_grading_id UUID;
  v_new_hpp DECIMAL;
BEGIN
  SELECT total_eggs_bought INTO v_expected FROM purchases WHERE id = p_purchase_id;

  IF v_expected IS NULL THEN
    RETURN jsonb_build_object('error', 'Purchase tidak ditemukan.');
  END IF;

  IF v_total_graded != v_expected THEN
    RETURN jsonb_build_object(
      'error', 'Total telur di-grading (' || v_total_graded ||
               ') tidak cocok dengan jumlah dibeli (' || v_expected || ')'
    );
  END IF;

  INSERT INTO gradings (purchase_id, hero_qty, medium_qty, small_qty, total_graded, notes)
  VALUES (p_purchase_id, p_hero_qty, p_medium_qty, p_small_qty, v_total_graded, p_notes)
  RETURNING id INTO v_grading_id;

  IF p_hero_qty > 0 THEN
    UPDATE inventory SET current_stock = current_stock + p_hero_qty, updated_at = NOW() WHERE id = 'hero';
    INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
    VALUES ('hero', 'grading_in', p_hero_qty, v_grading_id, 'Grading masuk');
  END IF;

  IF p_medium_qty > 0 THEN
    UPDATE inventory SET current_stock = current_stock + p_medium_qty, updated_at = NOW() WHERE id = 'medium';
    INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
    VALUES ('medium', 'grading_in', p_medium_qty, v_grading_id, 'Grading masuk');
  END IF;

  IF p_small_qty > 0 THEN
    UPDATE inventory SET current_stock = current_stock + p_small_qty, updated_at = NOW() WHERE id = 'small';
    INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
    VALUES ('small', 'grading_in', p_small_qty, v_grading_id, 'Grading masuk');
  END IF;

  SELECT price_per_egg INTO v_new_hpp FROM purchases WHERE id = p_purchase_id;
  UPDATE inventory SET hpp_per_egg = v_new_hpp WHERE id IN ('hero','medium','small');
  PERFORM recalculate_hpp('hero');
  PERFORM recalculate_hpp('medium');
  PERFORM recalculate_hpp('small');

  PERFORM check_safety_stock();

  RETURN jsonb_build_object('success', true, 'grading_id', v_grading_id,
    'hero_added', p_hero_qty, 'medium_added', p_medium_qty, 'small_added', p_small_qty);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 4: Safety Stock Check ───
CREATE OR REPLACE FUNCTION check_safety_stock()
RETURNS VOID AS $$
DECLARE
  v_item RECORD;
BEGIN
  FOR v_item IN SELECT * FROM inventory WHERE id IN ('hero','medium','small') LOOP
    IF v_item.current_stock <= COALESCE(v_item.safety_stock, 20) THEN
      INSERT INTO notifications (type, title, message, link)
      SELECT 'critical_stock', '🔴 Stok Kritis: ' || COALESCE(v_item.grade, v_item.id),
             v_item.current_stock || ' butir tersisa (safety: ' || COALESCE(v_item.safety_stock, 20) || ')',
             '/inventory'
      WHERE NOT EXISTS (
        SELECT 1 FROM notifications
        WHERE type = 'critical_stock'
        AND message LIKE '%' || COALESCE(v_item.grade, v_item.id) || '%'
        AND created_at::DATE = CURRENT_DATE
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 5: Create Sale (Atomic) ───
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
BEGIN
  IF p_payment_type = 'piutang' AND p_due_date IS NULL THEN
    RETURN jsonb_build_object('error', 'Transaksi piutang harus memiliki tanggal jatuh tempo.');
  END IF;

  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    v_max_packs := FLOOR(v_inv.current_stock::DECIMAL / COALESCE(v_inv.pack_size, 10));

    IF (item->>'packs_sold')::INTEGER > v_max_packs THEN
      RETURN jsonb_build_object(
        'error', 'Stok ' || COALESCE(v_inv.grade, v_inv.id) || ' tidak cukup. ' ||
                 'Tersedia: ' || v_max_packs || ' pack (' ||
                 v_inv.current_stock || ' butir), diminta: ' || (item->>'packs_sold') || ' pack.'
      );
    END IF;
  END LOOP;

  v_invoice_no := 'EP-' || TO_CHAR(NOW(), 'YYYYMMDD') ||
    LPAD(((SELECT COUNT(*) FROM sales WHERE created_at::DATE = CURRENT_DATE) + 1)::TEXT, 3, '0');

  INSERT INTO customers (name) VALUES (p_customer_name)
  ON CONFLICT (name) DO NOTHING;
  SELECT id INTO v_customer_id FROM customers WHERE name = p_customer_name;

  INSERT INTO sales (invoice_number, customer_id, customer_name, payment_type,
    total_revenue, total_hpp, gross_profit, margin_pct, payment_status, total_price, fulfillment_status)
  VALUES (v_invoice_no, v_customer_id, p_customer_name, p_payment_type,
          0, 0, 0, 0,
          CASE WHEN p_payment_type = 'tunai' THEN 'paid' ELSE 'pending' END,
          0, 'processing')
  RETURNING id INTO v_sale_id;

  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_inv FROM inventory WHERE id = (item->>'inventory_id');
    v_eggs_out := (item->>'packs_sold')::INTEGER * COALESCE(v_inv.pack_size, 10);
    v_price := COALESCE((item->>'override_price')::DECIMAL, v_inv.retail_price_per_pack, v_inv.base_price_per_pack);

    INSERT INTO sale_items (sale_id, inventory_id, grade, packs_sold, eggs_out,
      price_per_pack, hpp_per_pack, revenue, hpp_total, gross_profit,
      egg_type, quantity, unit_price, subtotal, unit_cost)
    VALUES (v_sale_id, v_inv.id, COALESCE(v_inv.grade, v_inv.id),
            (item->>'packs_sold')::INTEGER, v_eggs_out,
            v_price, COALESCE(v_inv.hpp_per_pack, 0),
            (item->>'packs_sold')::INTEGER * v_price,
            (item->>'packs_sold')::INTEGER * COALESCE(v_inv.hpp_per_pack, 0),
            (item->>'packs_sold')::INTEGER * (v_price - COALESCE(v_inv.hpp_per_pack, 0)),
            v_inv.id, (item->>'packs_sold')::INTEGER, v_price,
            (item->>'packs_sold')::INTEGER * v_price,
            COALESCE(v_inv.hpp_per_pack, 0));

    IF v_price != COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack) THEN
      INSERT INTO price_overrides (sale_id, inventory_id, original_price, override_price,
        discount_amount, discount_pct, reason, product_name)
      VALUES (v_sale_id, v_inv.id,
              COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack), v_price,
              COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack) - v_price,
              ((COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack) - v_price) /
               COALESCE(v_inv.retail_price_per_pack, v_inv.base_price_per_pack)) * 100,
              COALESCE(item->>'override_reason', 'Tidak ada keterangan'),
              COALESCE(v_inv.grade, v_inv.id));
    END IF;

    UPDATE inventory SET
      current_stock = current_stock - v_eggs_out,
      updated_at = NOW()
    WHERE id = v_inv.id;

    INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
    VALUES (v_inv.id, 'sale_out', -v_eggs_out, v_sale_id, 'Sale: ' || v_invoice_no);

    v_revenue := v_revenue + ((item->>'packs_sold')::INTEGER * v_price);
    v_hpp_total := v_hpp_total + ((item->>'packs_sold')::INTEGER * COALESCE(v_inv.hpp_per_pack, 0));
  END LOOP;

  UPDATE sales SET
    total_revenue = v_revenue,
    total_hpp = v_hpp_total,
    gross_profit = v_revenue - v_hpp_total,
    margin_pct = CASE WHEN v_revenue > 0 THEN ((v_revenue - v_hpp_total) / v_revenue) * 100 ELSE 0 END,
    total_price = v_revenue
  WHERE id = v_sale_id;

  IF p_payment_type = 'piutang' THEN
    INSERT INTO piutang (sale_id, customer_id, customer_name, invoice_no,
      total_amount, remaining, due_date)
    VALUES (v_sale_id, v_customer_id, p_customer_name, v_invoice_no,
            v_revenue, v_revenue, p_due_date);

    UPDATE customers SET total_piutang = COALESCE(total_piutang, 0) + v_revenue
    WHERE id = v_customer_id;
  END IF;

  UPDATE customers SET
    total_orders = COALESCE(total_orders, 0) + 1,
    total_spent = CASE WHEN p_payment_type = 'tunai'
                  THEN COALESCE(total_spent, 0) + v_revenue ELSE COALESCE(total_spent, 0) END
  WHERE id = v_customer_id;

  IF p_payment_type = 'tunai' THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('income', 'Penjualan Telur', v_revenue,
            'Penjualan tunai: ' || v_invoice_no, 'sale', v_sale_id);
  END IF;

  INSERT INTO notifications (type, title, message, link)
  VALUES (CASE WHEN p_payment_type = 'tunai' THEN 'sale_tunai' ELSE 'sale_piutang' END,
          CASE WHEN p_payment_type = 'tunai' THEN '✅ Penjualan Tunai'
               ELSE '⏳ Penjualan Piutang' END,
          v_invoice_no || ' — ' || p_customer_name || ' — Rp ' || v_revenue,
          '/sales');

  PERFORM check_safety_stock();

  RETURN jsonb_build_object(
    'success', true, 'sale_id', v_sale_id,
    'invoice_number', v_invoice_no,
    'total_revenue', v_revenue,
    'gross_profit', v_revenue - v_hpp_total
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 6: Void Sale (Updated) ───
CREATE OR REPLACE FUNCTION void_sale_v2(
  p_sale_id UUID, p_voided_by TEXT, p_reason TEXT
) RETURNS JSONB AS $$
DECLARE
  v_sale RECORD;
  v_item RECORD;
BEGIN
  SELECT * INTO v_sale FROM sales WHERE id = p_sale_id;
  IF v_sale IS NULL THEN
    RETURN jsonb_build_object('error', 'Transaksi tidak ditemukan.');
  END IF;
  IF v_sale.voided_at IS NOT NULL OR v_sale.payment_status = 'voided' THEN
    RETURN jsonb_build_object('error', 'Transaksi ini sudah di-void.');
  END IF;

  FOR v_item IN SELECT * FROM sale_items WHERE sale_id = p_sale_id LOOP
    UPDATE inventory SET current_stock = current_stock + COALESCE(v_item.eggs_out, v_item.quantity * 10)
    WHERE id = COALESCE(v_item.inventory_id, v_item.egg_type);

    INSERT INTO stock_logs (inventory_id, log_type, quantity_change, reference_id, note)
    VALUES (COALESCE(v_item.inventory_id, v_item.egg_type), 'void_return',
            COALESCE(v_item.eggs_out, v_item.quantity * 10), p_sale_id, 'Void: ' || p_reason);
  END LOOP;

  UPDATE sales SET
    voided_at = NOW(),
    voided_by = p_voided_by,
    void_reason = p_reason,
    payment_status = 'voided'
  WHERE id = p_sale_id;

  -- Void piutang if exists
  UPDATE piutang SET status = 'lunas', paid_amount = total_amount, remaining = 0
  WHERE sale_id = p_sale_id AND status != 'lunas';

  IF v_sale.customer_id IS NOT NULL THEN
    UPDATE customers SET
      total_piutang = GREATEST(0, COALESCE(total_piutang, 0) - COALESCE(v_sale.total_revenue, v_sale.total_price, 0))
    WHERE id = v_sale.customer_id;
  END IF;

  IF v_sale.payment_status = 'paid' OR v_sale.payment_type = 'tunai' THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('expense', 'Void Penjualan', COALESCE(v_sale.total_revenue, v_sale.total_price),
            'Void: ' || COALESCE(v_sale.invoice_number, v_sale.id::TEXT) || ' — ' || p_reason,
            'void', p_sale_id);
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 7: Collect Piutang Payment ───
CREATE OR REPLACE FUNCTION collect_piutang(
  p_piutang_id UUID, p_amount DECIMAL, p_method TEXT, p_note TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_p piutang%ROWTYPE;
  v_new_paid DECIMAL;
  v_new_remaining DECIMAL;
  v_new_status TEXT;
BEGIN
  SELECT * INTO v_p FROM piutang WHERE id = p_piutang_id;
  IF v_p IS NULL THEN RETURN jsonb_build_object('error', 'Piutang tidak ditemukan.'); END IF;
  IF v_p.remaining <= 0 THEN RETURN jsonb_build_object('error', 'Piutang ini sudah lunas.'); END IF;
  IF p_amount > v_p.remaining THEN
    RETURN jsonb_build_object('error', 'Pembayaran melebihi sisa piutang: Rp ' || v_p.remaining);
  END IF;

  INSERT INTO piutang_payments (piutang_id, amount, method, note) VALUES (p_piutang_id, p_amount, p_method, p_note);
  v_new_paid := v_p.paid_amount + p_amount;
  v_new_remaining := v_p.total_amount - v_new_paid;
  v_new_status := CASE WHEN v_new_remaining = 0 THEN 'lunas'
                       WHEN v_new_paid > 0 THEN 'sebagian' ELSE 'belum_bayar' END;

  UPDATE piutang SET paid_amount = v_new_paid, remaining = v_new_remaining, status = v_new_status WHERE id = p_piutang_id;
  UPDATE customers SET
    total_piutang = GREATEST(0, COALESCE(total_piutang, 0) - p_amount),
    total_spent = COALESCE(total_spent, 0) + p_amount
  WHERE id = v_p.customer_id;

  -- Update associated sale to paid if fully collected
  IF v_new_remaining = 0 THEN
    UPDATE sales SET payment_status = 'paid' WHERE id = v_p.sale_id;
  END IF;

  INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
  VALUES ('income', 'Pembayaran Piutang', p_amount,
          'Bayar piutang: ' || v_p.invoice_no || ' dari ' || v_p.customer_name,
          'piutang_payment', p_piutang_id);

  RETURN jsonb_build_object('success', true, 'new_remaining', v_new_remaining, 'new_status', v_new_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 8: Pay Utang Supplier ───
CREATE OR REPLACE FUNCTION pay_utang_supplier(
  p_utang_id UUID, p_amount DECIMAL, p_method TEXT, p_note TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_u utang_supplier%ROWTYPE;
  v_new_paid DECIMAL;
  v_new_remaining DECIMAL;
  v_new_status TEXT;
BEGIN
  SELECT * INTO v_u FROM utang_supplier WHERE id = p_utang_id;
  IF v_u IS NULL THEN RETURN jsonb_build_object('error', 'Utang tidak ditemukan.'); END IF;
  IF v_u.remaining <= 0 THEN RETURN jsonb_build_object('error', 'Utang ini sudah lunas.'); END IF;
  IF p_amount > v_u.remaining THEN
    RETURN jsonb_build_object('error', 'Pembayaran melebihi sisa utang: Rp ' || v_u.remaining);
  END IF;

  INSERT INTO utang_payments (utang_id, amount, method, note) VALUES (p_utang_id, p_amount, p_method, p_note);
  v_new_paid := v_u.paid_amount + p_amount;
  v_new_remaining := v_u.total_amount - v_new_paid;
  v_new_status := CASE WHEN v_new_remaining = 0 THEN 'lunas' ELSE 'aktif' END;

  UPDATE utang_supplier SET paid_amount = v_new_paid, remaining = v_new_remaining, status = v_new_status WHERE id = p_utang_id;
  UPDATE purchases SET amount_paid = v_new_paid, remaining_debt = v_new_remaining,
    status = CASE WHEN v_new_remaining = 0 THEN 'lunas' WHEN v_new_paid > 0 THEN 'cicilan' ELSE 'utang' END
  WHERE id = v_u.purchase_id;
  UPDATE suppliers SET total_outstanding_debt = GREATEST(0, total_outstanding_debt - p_amount) WHERE id = v_u.supplier_id;

  INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
  VALUES ('expense', 'Pembayaran ke Supplier', p_amount,
          'Bayar utang: ' || v_u.supplier_name, 'utang_payment', p_utang_id);

  RETURN jsonb_build_object('success', true, 'new_remaining', v_new_remaining);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── FUNCTION 9: Dashboard KPI Query ───
CREATE OR REPLACE FUNCTION get_dashboard_kpis()
RETURNS JSONB AS $$
DECLARE
  v_total_revenue DECIMAL;
  v_total_hpp DECIMAL;
  v_gross_profit DECIMAL;
  v_total_utang DECIMAL;
  v_total_piutang DECIMAL;
  v_total_purchase_cost DECIMAL;
  v_net_position DECIMAL;
BEGIN
  SELECT COALESCE(SUM(COALESCE(total_revenue, total_price, 0)), 0),
         COALESCE(SUM(COALESCE(total_hpp, 0)), 0)
  INTO v_total_revenue, v_total_hpp
  FROM sales WHERE voided_at IS NULL AND payment_status != 'voided';

  v_gross_profit := v_total_revenue - v_total_hpp;

  SELECT COALESCE(SUM(remaining), 0) INTO v_total_utang
  FROM utang_supplier WHERE status != 'lunas';

  SELECT COALESCE(SUM(remaining), 0) INTO v_total_piutang
  FROM piutang WHERE status != 'lunas';

  SELECT COALESCE(SUM(total_cost), 0) INTO v_total_purchase_cost FROM purchases;

  v_net_position := v_total_revenue - v_total_purchase_cost;

  RETURN jsonb_build_object(
    'total_revenue', v_total_revenue,
    'total_hpp', v_total_hpp,
    'gross_profit', v_gross_profit,
    'overall_margin', CASE WHEN v_total_revenue > 0 THEN (v_gross_profit / v_total_revenue) * 100 ELSE 0 END,
    'total_utang_aktif', v_total_utang,
    'total_piutang_aktif', v_total_piutang,
    'total_purchase_cost', v_total_purchase_cost,
    'net_position', v_net_position,
    'modal_belum_kembali', CASE WHEN v_net_position < 0 THEN ABS(v_net_position) ELSE 0 END,
    'is_profitable', v_net_position >= 0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 4: ADD COLUMNS TO stock_logs FOR NEW LOG TYPES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE stock_logs
  ADD COLUMN IF NOT EXISTS inventory_id TEXT,
  ADD COLUMN IF NOT EXISTS quantity_change INTEGER,
  ADD COLUMN IF NOT EXISTS reference_id UUID,
  ADD COLUMN IF NOT EXISTS note TEXT;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 5: DISABLE RLS ON NEW TABLES (match existing setup)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE gradings ENABLE ROW LEVEL SECURITY;
ALTER TABLE piutang ENABLE ROW LEVEL SECURITY;
ALTER TABLE piutang_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE utang_supplier ENABLE ROW LEVEL SECURITY;
ALTER TABLE utang_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_opname_items ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users (matching existing pattern)
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['purchases','gradings','piutang','piutang_payments','utang_supplier','utang_payments','stock_opname','stock_opname_items'] LOOP
    EXECUTE format('CREATE POLICY IF NOT EXISTS "Allow all for authenticated" ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  -- Ignore if policies already exist
  NULL;
END $$;
