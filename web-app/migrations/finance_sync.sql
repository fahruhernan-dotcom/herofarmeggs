-- Migration: Finance & Stock Consistency (Phase 8 Completion)
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql

-- 1. Snapshot COGS at sale time
ALTER TABLE sale_items 
ADD COLUMN IF NOT EXISTS unit_cost NUMERIC DEFAULT 0;

-- 2. Create the Customer Totals Sync function (RPC)
-- This ensures Task 3 of Phase 6 is complete and called by Void flow
CREATE OR REPLACE FUNCTION sync_customer_totals(target_customer_id UUID)
RETURNS void AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
