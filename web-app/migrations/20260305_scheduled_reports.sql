-- ━━━ FEATURE 2: SCHEDULED REPORT EXPORTS ━━━

CREATE TABLE IF NOT EXISTS scheduled_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL,
  report_name TEXT,
  frequency TEXT CHECK (frequency IN ('daily','weekly','monthly')),
  day_of_week INTEGER,     -- 0=Sunday for weekly
  day_of_month INTEGER,    -- 1-28 for monthly
  send_time TIME DEFAULT '07:00',
  format TEXT DEFAULT 'csv' CHECK (format IN ('csv','json')),
  recipient_email TEXT,
  is_active BOOLEAN DEFAULT true,
  last_sent_at TIMESTAMPTZ,
  next_send_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE scheduled_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access to scheduled_reports" ON scheduled_reports FOR ALL USING (true);
