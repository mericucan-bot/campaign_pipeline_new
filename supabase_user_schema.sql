-- Kampanya Radari user data schema
-- Run this after supabase_schema.sql.
-- This file is additive and safe to run more than once.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  plan TEXT NOT NULL DEFAULT 'free',
  plan_status TEXT NOT NULL DEFAULT 'active',
  trial_ends_at TIMESTAMPTZ,
  premium_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT profiles_plan_check CHECK (plan IN ('free', 'trial', 'premium')),
  CONSTRAINT profiles_plan_status_check CHECK (plan_status IN ('active', 'past_due', 'canceled'))
);

CREATE TABLE IF NOT EXISTS user_cards (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bank TEXT NOT NULL,
  bank_label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, bank)
);

CREATE TABLE IF NOT EXISTS user_favorites (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, campaign_id)
);

CREATE TABLE IF NOT EXISTS campaign_participations (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  did_join BOOLEAN NOT NULL DEFAULT FALSE,
  spent_amount NUMERIC NOT NULL DEFAULT 0 CHECK (spent_amount >= 0),
  earned_amount NUMERIC NOT NULL DEFAULT 0 CHECK (earned_amount >= 0),
  reward_expires_at DATE,
  reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, campaign_id)
);

CREATE TABLE IF NOT EXISTS subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  product_id TEXT NOT NULL,
  transaction_id TEXT,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT subscription_events_platform_check CHECK (platform IN ('ios', 'android', 'web'))
);

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS plan_status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ;
ALTER TABLE campaign_participations ADD COLUMN IF NOT EXISTS reward_expires_at DATE;
ALTER TABLE campaign_participations ADD COLUMN IF NOT EXISTS reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards (user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites (user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_campaign_id ON user_favorites (campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_participations_user_id ON campaign_participations (user_id);
CREATE INDEX IF NOT EXISTS idx_campaign_participations_campaign_id ON campaign_participations (campaign_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON subscription_events (user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_transaction_id ON subscription_events (transaction_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_campaign_participations_updated_at ON campaign_participations;
CREATE TRIGGER set_campaign_participations_updated_at
BEFORE UPDATE ON campaign_participations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION handle_new_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user_profile();

ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'campaigns'
      AND policyname = 'public read active campaigns'
  ) THEN
    CREATE POLICY "public read active campaigns"
    ON campaigns
    FOR SELECT
    TO anon, authenticated
    USING (is_active = TRUE);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'users insert own free profile'
  ) THEN
    CREATE POLICY "users insert own free profile"
    ON profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id AND plan = 'free' AND plan_status = 'active');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'users read own profile'
  ) THEN
    CREATE POLICY "users read own profile"
    ON profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'users update own profile'
  ) THEN
    CREATE POLICY "users update own profile"
    ON profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id AND plan = 'free' AND plan_status = 'active');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_cards'
      AND policyname = 'users manage own cards'
  ) THEN
    CREATE POLICY "users manage own cards"
    ON user_cards
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'subscription_events'
      AND policyname = 'users read own subscription events'
  ) THEN
    CREATE POLICY "users read own subscription events"
    ON subscription_events
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_favorites'
      AND policyname = 'users manage own favorites'
  ) THEN
    CREATE POLICY "users manage own favorites"
    ON user_favorites
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'campaign_participations'
      AND policyname = 'users manage own participations'
  ) THEN
    CREATE POLICY "users manage own participations"
    ON campaign_participations
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
