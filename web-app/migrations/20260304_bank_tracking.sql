-- ━━━ FEATURE 1: BANK ACCOUNT TRACKING ━━━

CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_name TEXT NOT NULL,
  account_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  account_type TEXT DEFAULT 'tabungan' CHECK (account_type IN ('tabungan','giro','deposito')),
  current_balance DECIMAL(15,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bank_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE CASCADE,
  transaction_type TEXT CHECK (transaction_type IN ('masuk','keluar')),
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  transaction_date DATE DEFAULT CURRENT_DATE,
  reference_type TEXT,   -- 'sale', 'restock', 'manual'
  reference_id UUID,
  balance_after DECIMAL(15,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access to bank_accounts" ON bank_accounts FOR ALL USING (true);
CREATE POLICY "Allow all access to bank_transactions" ON bank_transactions FOR ALL USING (true);
