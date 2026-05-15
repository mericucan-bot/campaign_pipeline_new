-- Kampanya Radari Apple Auth repair
-- Use this if Apple Sign In returns: "Database error saving new user".
-- Run in Supabase SQL Editor with Role: postgres.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  plan TEXT NOT NULL DEFAULT 'free',
  plan_status TEXT NOT NULL DEFAULT 'active',
  trial_ends_at TIMESTAMPTZ,
  premium_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS plan_status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_plan_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_plan_check CHECK (plan IN ('free', 'trial', 'premium'));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_plan_status_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_plan_status_check CHECK (plan_status IN ('active', 'past_due', 'canceled'));

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url, plan, plan_status)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''),
      'Kullanıcı'
    ),
    NEW.raw_user_meta_data->>'avatar_url',
    'free',
    'active'
  )
  ON CONFLICT (id) DO UPDATE
  SET
    display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name),
    avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
    updated_at = NOW();

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.handle_new_user_profile() OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.handle_new_user_profile() TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.handle_new_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user_profile() TO service_role;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_profile();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users insert own free profile" ON public.profiles;
CREATE POLICY "users insert own free profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id AND plan = 'free' AND plan_status = 'active');

DROP POLICY IF EXISTS "users read own profile" ON public.profiles;
CREATE POLICY "users read own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "users update own profile" ON public.profiles;
CREATE POLICY "users update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
