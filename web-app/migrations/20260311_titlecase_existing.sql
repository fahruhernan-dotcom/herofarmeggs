-- ==============================================================================
-- MIGRATION: 20260311_titlecase_existing.sql
-- DESCRIPTION: Standardizes all relevant string columns to Title Case
-- using PostgreSQL's native INITCAP() function.
-- ==============================================================================

-- 1. TITLE CASE 'sales' TABLE
UPDATE sales
SET 
  customer_name = INITCAP(customer_name)
WHERE customer_name IS NOT NULL;

-- 2. TITLE CASE 'suppliers' TABLE
-- Note: 'price_list' is JSONB, so we can't easily INITCAP inside JSON arrays natively 
-- without complex jsonb functions. Best to just handle the top-level string columns.
UPDATE suppliers
SET 
  name = INITCAP(name),
  contact_person = INITCAP(contact_person),
  address = INITCAP(address)
WHERE name IS NOT NULL OR contact_person IS NOT NULL OR address IS NOT NULL;

-- 3. TITLE CASE 'purchases' TABLE
UPDATE purchases
SET 
  notes = INITCAP(notes)
WHERE notes IS NOT NULL;

-- 4. TITLE CASE 'stock_logs' TABLE
UPDATE stock_logs
SET 
  notes = INITCAP(notes)
WHERE notes IS NOT NULL;

-- 5. TITLE CASE 'stock_opname' TABLE
UPDATE stock_opname
SET 
  conducted_by = INITCAP(conducted_by)
WHERE conducted_by IS NOT NULL;

-- 6. TITLE CASE 'grading_history' TABLE (if exists)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'grading_history') THEN
    UPDATE grading_history SET notes = INITCAP(notes) WHERE notes IS NOT NULL;
  END IF;
END $$;
