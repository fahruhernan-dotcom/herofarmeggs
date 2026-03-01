-- Migration: Enhance Price Tracking
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)

-- 1. Add unit_price to stock_logs to track purchase costs
ALTER TABLE stock_logs 
ADD COLUMN IF NOT EXISTS unit_price NUMERIC DEFAULT 0;

-- 2. Ensure sale_items has unit_price and subtotal for snapshotting
-- (Assuming they already exist based on my audit, but ADD IF NOT EXISTS for safety)
ALTER TABLE sale_items 
ADD COLUMN IF NOT EXISTS unit_price NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS subtotal NUMERIC DEFAULT 0;

-- 3. Verify that inventory has cost_per_egg and base_price_per_pack
-- (These are used for HPP calculations)
ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS cost_per_egg NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS base_price_per_pack NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS cost_price NUMERIC DEFAULT 0;
