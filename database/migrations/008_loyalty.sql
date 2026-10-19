-- 008_loyalty.sql
-- Loyalty program: accounts and transactions

CREATE TABLE IF NOT EXISTS public.loyalty_accounts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_earned     INTEGER DEFAULT 0,
  total_spent      INTEGER DEFAULT 0,
  balance          INTEGER DEFAULT 0,
  last_activity_at TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loyalty_account_id UUID NOT NULL REFERENCES public.loyalty_accounts(id) ON DELETE CASCADE,
  order_id           UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  points             INTEGER NOT NULL,
  type               TEXT NOT NULL CHECK (type IN ('earn', 'redeem', 'expire', 'bonus')),
  description        TEXT,
  created_at         TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.loyalty_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
