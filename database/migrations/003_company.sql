-- 003_company.sql
-- Company, ownership, and working hours

CREATE TABLE IF NOT EXISTS public.companies (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  slogan              TEXT,
  description         TEXT,
  first_opening_date  DATE,
  address             TEXT,
  city                TEXT,
  postal_code         TEXT,
  country             TEXT DEFAULT 'France',
  phone               TEXT,
  email               TEXT,
  website             TEXT,
  siret               TEXT UNIQUE,
  logo_url            TEXT,
  is_active           BOOLEAN DEFAULT true,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.working_hours (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day       TEXT UNIQUE NOT NULL,
  opening   TEXT,
  closing   TEXT
);

CREATE TABLE IF NOT EXISTS public.company_owners (
  company_id  UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        TEXT DEFAULT 'owner',
  joined_at   TIMESTAMPTZ DEFAULT now(),
  is_primary  BOOLEAN DEFAULT false,
  PRIMARY KEY (company_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.company_working_hours (
  company_id       UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  working_hours_id UUID NOT NULL REFERENCES public.working_hours(id) ON DELETE CASCADE,
  PRIMARY KEY (company_id, working_hours_id)
);

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_working_hours ENABLE ROW LEVEL SECURITY;
