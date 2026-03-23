-- ============================================================
-- SENTINEL v3 — Supabase Database Schema
-- Run this entire file in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ── PROFILES TABLE ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id                 UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username           TEXT,
  email              TEXT,
  marketing_consent  BOOLEAN DEFAULT FALSE,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- ── RECORDINGS TABLE ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.recordings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  date        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duration    INTEGER DEFAULT 0,
  has_uap     BOOLEAN DEFAULT FALSE,
  lat         TEXT,
  lon         TEXT,
  alt         TEXT,
  az          INTEGER,
  el          INTEGER,
  manifest    JSONB,
  tag_objs    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────
-- Users can only see and modify their own data

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- Profiles: users manage their own row
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Recordings: users manage their own recordings
CREATE POLICY "Users can view own recordings"
  ON public.recordings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recordings"
  ON public.recordings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recordings"
  ON public.recordings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own recordings"
  ON public.recordings FOR DELETE
  USING (auth.uid() = user_id);

-- ── AUTO-CREATE PROFILE ON SIGNUP ───────────────────────────
-- Trigger: when a new auth.users row is created, auto-insert a profiles row
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, marketing_consent)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'marketing_consent')::boolean, false)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS recordings_user_id_idx ON public.recordings(user_id);
CREATE INDEX IF NOT EXISTS recordings_date_idx    ON public.recordings(date DESC);
CREATE INDEX IF NOT EXISTS recordings_has_uap_idx ON public.recordings(has_uap);

-- ── MARKETING CONSENT VIEW (for admin export) ────────────────
-- Useful if you want to export consented emails for Nexior-Gray campaigns
CREATE OR REPLACE VIEW public.marketing_subscribers AS
  SELECT id, email, username, created_at
  FROM   public.profiles
  WHERE  marketing_consent = TRUE;

-- NOTE: To access this view for email campaigns, query it via the
-- Supabase service-role key (never expose that key in the frontend).

-- ============================================================
-- DONE. Next steps:
-- 1. In Supabase Dashboard → Auth → Providers → enable Google
-- 2. Add your Google OAuth Client ID + Secret
-- 3. Set Site URL to your Netlify URL
-- 4. Copy your Project URL and anon key into Netlify env vars
-- ============================================================
