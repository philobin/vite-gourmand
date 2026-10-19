-- 004_reference_data.sql
-- Allergens, diets, themes, ingredients

CREATE TABLE IF NOT EXISTS public.allergens (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT UNIQUE NOT NULL,
  icon_url  TEXT
);

CREATE TABLE IF NOT EXISTS public.diets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  icon_url    TEXT
);

CREATE TABLE IF NOT EXISTS public.themes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT UNIQUE NOT NULL,
  description TEXT,
  icon_url    TEXT
);

CREATE TABLE IF NOT EXISTS public.ingredients (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT UNIQUE NOT NULL,
  unit            TEXT DEFAULT 'kg',
  current_stock   NUMERIC(10,3) DEFAULT 0,
  min_stock_level NUMERIC(10,3) DEFAULT 0,
  cost_per_unit   NUMERIC(10,2),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
