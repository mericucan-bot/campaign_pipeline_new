CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank TEXT NOT NULL,
  bank_label TEXT,
  external_id TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT,
  description TEXT,
  conditions TEXT,
  image_url TEXT,
  url TEXT,
  source_url TEXT,
  category TEXT,
  reward_type TEXT,
  reward_value NUMERIC,
  valid_from TIMESTAMPTZ,
  valid_to DATE,
  opportunity_score INTEGER,
  hash TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  first_seen TIMESTAMPTZ NOT NULL,
  last_seen TIMESTAMPTZ NOT NULL,
  last_updated TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (bank, external_id)
);

CREATE INDEX IF NOT EXISTS idx_campaigns_bank ON campaigns (bank);
CREATE INDEX IF NOT EXISTS idx_campaigns_active ON campaigns (is_active);
CREATE INDEX IF NOT EXISTS idx_campaigns_valid_to ON campaigns (valid_to);

ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS bank_label TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS summary TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS conditions TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS reward_type TEXT;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS reward_value NUMERIC;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS valid_to DATE;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS opportunity_score INTEGER;
