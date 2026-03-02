-- Migration: Database Upgrades 20260302
-- Integrated upgrades for soft delete, server-side validation, finance tracking, and voiding.

-- ━━━ UPGRADE 1: SOFT DELETE ━━━
ALTER TABLE suppliers
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ━━━ UPGRADE 3: FINANCE ENTRIES TABLE ━━━
CREATE TABLE IF NOT EXISTS finance_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_type TEXT NOT NULL CHECK (entry_type IN ('income', 'expense')),
  category TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  entry_date DATE DEFAULT CURRENT_DATE,
  reference_type TEXT,   -- 'sale', 'restock', 'void'
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ━━━ UPGRADE 5: VOID COLUMNS ━━━
ALTER TABLE sales ADD COLUMN IF NOT EXISTS voided_at TIMESTAMPTZ;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS voided_by TEXT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS void_reason TEXT;

-- ━━━ FUNCTIONS & PROCEDURES ━━━

-- Upgrade 4: Customer Sync RPC
CREATE OR REPLACE FUNCTION sync_customer_totals(p_customer_name TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET
    total_spent = COALESCE((
      SELECT SUM(total_price) FROM sales
      WHERE customer_name IN (SELECT name FROM customers WHERE name = p_customer_name) 
      AND payment_status = 'paid'
    ), 0),
    total_orders = COALESCE((
      SELECT COUNT(*) FROM sales
      WHERE customer_name IN (SELECT name FROM customers WHERE name = p_customer_name)
      AND payment_status IN ('paid', 'pending')
    ), 0)
  WHERE name = p_customer_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Adjusted for UUID if possible, but keeping name sync for backward compatibility if needed.
-- However, existing app uses customer_id (UUID). Let's provide a UUID version too.
CREATE OR REPLACE FUNCTION sync_customer_totals_by_id(p_customer_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET
    total_spent = COALESCE((
      SELECT SUM(total_price) FROM sales
      WHERE customer_id = p_customer_id AND payment_status = 'paid'
    ), 0),
    total_orders = COALESCE((
      SELECT COUNT(*) FROM sales
      WHERE customer_id = p_customer_id
      AND payment_status IN ('paid', 'pending', 'voided')
    ), 0)
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upgrade 2: Server-Side Sale (Schema Compatible)
CREATE OR REPLACE FUNCTION validate_and_create_sale(
  p_customer_id UUID,
  p_items JSONB,
  p_payment_status TEXT DEFAULT 'pending'
) RETURNS JSONB AS $$
DECLARE
  item JSONB;
  v_current_stock INTEGER;
  current_pack_stock INTEGER;
  current_sticker_stock INTEGER;
  current_card_stock INTEGER;
  v_sale_id UUID;
  v_invoice_number TEXT;
  item_total_packs INTEGER := 0;
  v_customer_name TEXT;
BEGIN
  -- Get customer name
  SELECT name INTO v_customer_name FROM customers WHERE id = p_customer_id;

  -- 1. Validate egg stock
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    SELECT current_stock INTO v_current_stock
    FROM inventory WHERE id = (item->>'egg_type');

    IF v_current_stock IS NULL THEN
      RETURN jsonb_build_object('error', 'Produk tidak ditemukan: ' || (item->>'label'));
    END IF;

    IF ((item->>'quantity')::INTEGER * 10) > v_current_stock THEN
      RETURN jsonb_build_object(
        'error', 'Stok tidak cukup untuk ' || (item->>'label') ||
        '. Tersedia: ' || FLOOR(v_current_stock / 10) || ' pack, diminta: ' || (item->>'quantity') || ' pack.'
      );
    END IF;
    item_total_packs := item_total_packs + (item->>'quantity')::INTEGER;
  END LOOP;

  -- 2. Validate supply stock
  SELECT current_stock INTO current_pack_stock FROM inventory WHERE id = 'packaging_standard';
  SELECT current_stock INTO current_sticker_stock FROM inventory WHERE id = 'sticker_label';
  SELECT current_stock INTO current_card_stock FROM inventory WHERE id = 'mini_card';

  IF current_pack_stock < item_total_packs THEN
    RETURN jsonb_build_object('error', 'Stok Box tidak cukup. Tersedia: ' || current_pack_stock);
  END IF;
  IF current_sticker_stock < item_total_packs THEN
    RETURN jsonb_build_object('error', 'Stok Stiker tidak cukup. Tersedia: ' || current_sticker_stock);
  END IF;

  -- 3. Create Sale
  INSERT INTO sales (customer_id, payment_status, total_price, fulfillment_status, stock_reserved)
  VALUES (p_customer_id, p_payment_status, 0, 'processing', true)
  RETURNING id INTO v_sale_id;

  -- 4. Insert Items + Deplete Stock
  FOR item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    INSERT INTO sale_items (sale_id, egg_type, quantity, unit_price, subtotal, unit_cost)
    VALUES (v_sale_id, (item->>'egg_type'),
            (item->>'quantity')::INTEGER,
            (item->>'price')::DECIMAL,
            (item->>'subtotal')::DECIMAL,
            (SELECT cost_price FROM inventory WHERE id = (item->>'egg_type')));

    -- Deplete Eggs
    UPDATE inventory SET current_stock = current_stock - ((item->>'quantity')::INTEGER * 10)
    WHERE id = (item->>'egg_type');

    -- Log
    INSERT INTO stock_logs (egg_type, log_type, "change", notes)
    VALUES ((item->>'egg_type'), 'sale', -((item->>'quantity')::INTEGER * 10), 'Sale #' || substring(v_sale_id::text, 1, 8));
  END LOOP;

  -- Deplete supplies
  UPDATE inventory SET current_stock = current_stock - item_total_packs WHERE id = 'packaging_standard';
  UPDATE inventory SET current_stock = current_stock - item_total_packs WHERE id = 'sticker_label';
  UPDATE inventory SET current_stock = current_stock - item_total_packs WHERE id = 'mini_card';

  -- Update total
  UPDATE sales SET total_price = (SELECT SUM(subtotal) FROM sale_items WHERE sale_id = v_sale_id)
  WHERE id = v_sale_id;

  -- Sync customer
  PERFORM sync_customer_totals_by_id(p_customer_id);

  RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upgrade 5: Void Sale (Schema Compatible)
CREATE OR REPLACE FUNCTION void_sale(p_sale_id UUID, p_voided_by TEXT, p_reason TEXT)
RETURNS JSONB AS $$
DECLARE
  v_sale sales%ROWTYPE;
  v_item sale_items%ROWTYPE;
  v_total_packs INTEGER := 0;
BEGIN
  SELECT * INTO v_sale FROM sales WHERE id = p_sale_id;

  IF v_sale.payment_status = 'voided' THEN
    RETURN jsonb_build_object('error', 'Transaksi ini sudah di-void sebelumnya.');
  END IF;

  -- Restore stock
  FOR v_item IN SELECT * FROM sale_items WHERE sale_id = p_sale_id LOOP
    UPDATE inventory SET current_stock = current_stock + (v_item.quantity * 10)
    WHERE id = v_item.egg_type;

    INSERT INTO stock_logs (egg_type, log_type, "change", notes)
    VALUES (v_item.egg_type, 'arrival', (v_item.quantity * 10), 'Void Restore - Sale #' || substring(p_sale_id::text, 1, 8));
    
    v_total_packs := v_total_packs + v_item.quantity;
  END LOOP;

  -- Restore supplies
  UPDATE inventory SET current_stock = current_stock + v_total_packs WHERE id = 'packaging_standard';
  UPDATE inventory SET current_stock = current_stock + v_total_packs WHERE id = 'sticker_label';
  UPDATE inventory SET current_stock = current_stock + v_total_packs WHERE id = 'mini_card';

  -- Mark voided
  UPDATE sales SET
    payment_status = 'voided',
    voided_at = NOW(),
    voided_by = p_voided_by,
    void_reason = p_reason
  WHERE id = p_sale_id;

  -- Finance Reverse
  IF v_sale.payment_status = 'paid' THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('expense', 'Void Transaksi', v_sale.total_price,
            'Void Sale #' || substring(p_sale_id::text, 1, 8) || ': ' || p_reason, 'void', p_sale_id);
  END IF;

  PERFORM sync_customer_totals_by_id(v_sale.customer_id);

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ━━━ TRIGGERS ━━━

-- Sale Paid → Finance Entry
CREATE OR REPLACE FUNCTION auto_finance_from_sale()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.payment_status = 'paid' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'paid') THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('income', 'Penjualan Telur', NEW.total_price,
            'Pembayaran diterima - Sale #' || substring(NEW.id::text, 1, 8), 'sale', NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_finance_from_sale ON sales;
CREATE TRIGGER trg_finance_from_sale
AFTER UPDATE ON sales FOR EACH ROW
EXECUTE FUNCTION auto_finance_from_sale();

-- Stock Restock → Finance Entry
CREATE OR REPLACE FUNCTION auto_finance_from_restock()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.log_type = 'arrival' AND NEW.unit_price > 0 THEN
    INSERT INTO finance_entries (entry_type, category, amount, description, reference_type, reference_id)
    VALUES ('expense', 'Pembelian Stok',
            ABS(NEW."change") * NEW.unit_price,
            'Restock: ' || (SELECT label FROM inventory WHERE id = NEW.egg_type),
            'restock', NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_finance_from_restock ON stock_logs;
CREATE TRIGGER trg_finance_from_restock
AFTER INSERT ON stock_logs FOR EACH ROW
EXECUTE FUNCTION auto_finance_from_restock();
