-- Migration: Advanced ERP Integrity v1
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

-- 1. Extend Sales table for Void/Reservation/Cancel logic
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS stock_reserved BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- 2. Price Overrides Audit Table (Ensure references match inventory_id)
-- Already defined in 20260303_operational_upgrades.sql, 
-- but we make sure any logic here uses the correct naming.

-- 3. Price History Tracking Table 
-- Already defined in 20260303_operational_upgrades.sql

-- 4. Soft Delete for Core Entities
ALTER TABLE suppliers 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 5. Customer Sync RPC (Integrity Logic)
-- Use this to fix total_spent and total_orders based on actual PAID sales
CREATE OR REPLACE FUNCTION sync_customer_totals(target_customer_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE customers
    SET 
        total_spent = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM sales
            WHERE customer_id = target_customer_id AND payment_status = 'paid'
        ),
        total_orders = (
            SELECT COALESCE(COUNT(*), 0)
            FROM sales
            WHERE customer_id = target_customer_id AND payment_status = 'paid'
        ),
        updated_at = now()
    WHERE id = target_customer_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Optional: Status helper (if needed for better indexing)
-- CREATE INDEX IF NOT EXISTS idx_sales_customer_paid ON sales(customer_id, payment_status) WHERE payment_status = 'paid';
