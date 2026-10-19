-- 013_newsletter.sql
-- Newsletter subscribers and send logs

CREATE TABLE IF NOT EXISTS public.newsletter_subscribers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE NOT NULL,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  first_name      TEXT,
  is_active       BOOLEAN DEFAULT true,
  token           TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  confirmed_at    TIMESTAMPTZ,
  unsubscribed_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.newsletter_send_logs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promotion_id     UUID REFERENCES public.promotions(id) ON DELETE SET NULL,
  recipients_count INTEGER DEFAULT 0,
  sent_at          TIMESTAMPTZ DEFAULT now(),
  sent_by          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status           TEXT DEFAULT 'sent'
);

ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_send_logs ENABLE ROW LEVEL SECURITY;
