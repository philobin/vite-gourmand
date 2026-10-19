-- 006_orders.sql
-- Orders, order menus, order tags, order status history

CREATE TABLE IF NOT EXISTS public.discounts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code             TEXT UNIQUE NOT NULL,
  description      TEXT,
  type             TEXT CHECK (type IN ('percentage', 'fixed_amount')),
  value            NUMERIC(10,2) NOT NULL,
  min_order_amount NUMERIC(10,2),
  max_uses         INTEGER,
  current_uses     INTEGER DEFAULT 0,
  valid_from       TIMESTAMPTZ,
  valid_until      TIMESTAMPTZ,
  is_active        BOOLEAN DEFAULT true,
  created_by       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.orders (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number              TEXT UNIQUE NOT NULL,
  user_id                   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_date                TIMESTAMPTZ DEFAULT now(),
  delivery_date             DATE,
  delivery_hour             TEXT,
  delivery_address          TEXT,
  delivery_city             TEXT DEFAULT 'Bordeaux',
  delivery_distance_km      NUMERIC(10,2),
  person_number             INTEGER,
  menu_price                NUMERIC(10,2),
  delivery_price            NUMERIC(10,2),
  discount_id               UUID REFERENCES public.discounts(id) ON DELETE SET NULL,
  discount_percent          NUMERIC(5,2),
  discount_amount           NUMERIC(10,2),
  total_price               NUMERIC(10,2),
  status                    TEXT DEFAULT 'pending',
  material_lending          BOOLEAN DEFAULT false,
  material_returned         BOOLEAN DEFAULT false,
  material_return_deadline  DATE,
  cancellation_reason       TEXT,
  cancellation_contact_mode TEXT,
  special_instructions      TEXT,
  confirmed_at              TIMESTAMPTZ,
  delivered_at              TIMESTAMPTZ,
  cancelled_at              TIMESTAMPTZ,
  created_at                TIMESTAMPTZ DEFAULT now(),
  updated_at                TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_menus (
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_id  UUID NOT NULL REFERENCES public.menus(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  PRIMARY KEY (order_id, menu_id)
);

CREATE TABLE IF NOT EXISTS public.order_tags (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label      TEXT UNIQUE NOT NULL,
  color      TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.order_order_tags (
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  tag_id   UUID NOT NULL REFERENCES public.order_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (order_id, tag_id)
);

CREATE TABLE IF NOT EXISTS public.order_status_history (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id   UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  notes      TEXT,
  changed_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_order_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
