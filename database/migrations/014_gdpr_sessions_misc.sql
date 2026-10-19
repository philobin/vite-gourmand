-- 014_gdpr_sessions_misc.sql
-- GDPR, user sessions, addresses, password reset, events, time-off

CREATE TABLE IF NOT EXISTS public.data_deletion_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason        TEXT,
  status        TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
  requested_at  TIMESTAMPTZ DEFAULT now(),
  processed_at  TIMESTAMPTZ,
  processed_by  UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.user_consents (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL,
  is_granted   BOOLEAN DEFAULT false,
  granted_at   TIMESTAMPTZ,
  revoked_at   TIMESTAMPTZ,
  ip_address   TEXT
);

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_token TEXT UNIQUE NOT NULL,
  ip_address    TEXT,
  user_agent    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  expires_at    TIMESTAMPTZ,
  is_active     BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.user_addresses (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label          TEXT,
  street_address TEXT NOT NULL,
  city           TEXT NOT NULL,
  postal_code    TEXT,
  country        TEXT DEFAULT 'France',
  latitude       NUMERIC(10,7),
  longitude      NUMERIC(10,7),
  is_default     BOOLEAN DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.password_reset_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token      TEXT UNIQUE NOT NULL,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  start_date  TIMESTAMPTZ NOT NULL,
  end_date    TIMESTAMPTZ,
  all_day     BOOLEAN DEFAULT false,
  event_type  TEXT,
  user_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  order_id    UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  created_by  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.time_off_requests (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  type         TEXT NOT NULL,
  status       TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reason       TEXT,
  decided_by   UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  requested_at TIMESTAMPTZ DEFAULT now(),
  decided_at   TIMESTAMPTZ
);

ALTER TABLE public.data_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_off_requests ENABLE ROW LEVEL SECURITY;
