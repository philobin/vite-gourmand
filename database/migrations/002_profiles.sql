-- 002_profiles.sql
-- User profiles table — extends auth.users with domain-specific fields
-- GoTrue handles auth (email, password, OAuth); profiles handle business data

CREATE TABLE IF NOT EXISTS public.profiles (
  id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                 TEXT UNIQUE NOT NULL,
  first_name            TEXT,
  last_name             TEXT,
  phone_number          TEXT,
  city                  TEXT,
  country               TEXT DEFAULT 'France',
  postal_code           TEXT,
  app_role              TEXT NOT NULL DEFAULT 'utilisateur'
                        CHECK (app_role IN ('superadmin', 'admin', 'employee', 'utilisateur')),
  is_active             BOOLEAN DEFAULT true,
  is_email_verified     BOOLEAN DEFAULT false,
  is_deleted            BOOLEAN DEFAULT false,
  deleted_at            TIMESTAMPTZ,
  preferred_language    TEXT DEFAULT 'fr',
  gdpr_consent          BOOLEAN DEFAULT false,
  gdpr_consent_date     TIMESTAMPTZ,
  marketing_consent     BOOLEAN DEFAULT false,
  newsletter_consent    BOOLEAN DEFAULT false,
  newsletter_consent_date TIMESTAMPTZ,
  last_login_at         TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Auto-create profile when a user signs up via GoTrue
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
