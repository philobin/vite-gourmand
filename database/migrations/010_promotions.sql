-- 010_promotions.sql
-- Promotions and user-promotion assignments (discounts already in 006)

CREATE TABLE IF NOT EXISTS public.promotions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  short_text  TEXT,
  type        TEXT DEFAULT 'banner',
  image_url   TEXT,
  link_url    TEXT,
  link_label  TEXT,
  badge_text  TEXT,
  bg_color    TEXT DEFAULT '#722F37',
  text_color  TEXT DEFAULT '#FFFFFF',
  discount_id UUID REFERENCES public.discounts(id) ON DELETE SET NULL,
  priority    INTEGER DEFAULT 0,
  is_active   BOOLEAN DEFAULT true,
  is_public   BOOLEAN DEFAULT true,
  start_date  TIMESTAMPTZ,
  end_date    TIMESTAMPTZ,
  created_by  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_promotions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  promotion_id UUID NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
  is_seen      BOOLEAN DEFAULT false,
  is_used      BOOLEAN DEFAULT false,
  used_at      TIMESTAMPTZ,
  assigned_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, promotion_id)
);

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_promotions ENABLE ROW LEVEL SECURITY;
