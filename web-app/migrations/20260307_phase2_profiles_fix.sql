-- Phase 2 Fix: Adding Employee Financial & Role data to Profiles
-- Run this in your Supabase SQL Editor

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES public.staff_positions(id),
ADD COLUMN IF NOT EXISTS salary DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS bank_account TEXT,
ADD COLUMN IF NOT EXISTS bank_holder TEXT,
ADD COLUMN IF NOT EXISTS employment_status TEXT DEFAULT 'active' CHECK (employment_status IN ('active', 'inactive', 'on_leave', 'terminated')),
ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;

-- Add a default position for everyone (Manager/Owner if not specified)
UPDATE public.profiles p
SET position_id = (SELECT id FROM public.staff_positions LIMIT 1)
WHERE p.position_id IS NULL;
