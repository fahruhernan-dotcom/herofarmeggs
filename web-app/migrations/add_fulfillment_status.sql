-- Migration: Add fulfillment_status column to sales table
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)

-- 1. Add the fulfillment_status column
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS fulfillment_status TEXT DEFAULT 'processing';

-- 2. Update existing orders to have a default fulfillment status
UPDATE sales 
SET fulfillment_status = 'delivered' 
WHERE fulfillment_status IS NULL AND payment_status = 'paid';

UPDATE sales 
SET fulfillment_status = 'processing' 
WHERE fulfillment_status IS NULL;

-- Done! Valid values for fulfillment_status: 'processing', 'on_delivery', 'delivered'
-- Valid values for payment_status: 'pending', 'paid', 'cancelled'
