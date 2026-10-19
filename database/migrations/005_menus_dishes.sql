-- 005_menus_dishes.sql
-- Menus, dishes, and all related junction/detail tables

CREATE TABLE IF NOT EXISTS public.dishes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  photo_url   TEXT,
  course_type TEXT DEFAULT 'plat',
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dish_allergens (
  dish_id     UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
  allergen_id UUID NOT NULL REFERENCES public.allergens(id) ON DELETE CASCADE,
  PRIMARY KEY (dish_id, allergen_id)
);

CREATE TABLE IF NOT EXISTS public.dish_ingredients (
  dish_id       UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
  quantity      NUMERIC(10,3),
  PRIMARY KEY (dish_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS public.menus (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  description       TEXT,
  conditions        TEXT,
  person_min        INTEGER,
  price_per_person  NUMERIC(10,2),
  remaining_qty     INTEGER,
  status            TEXT DEFAULT 'published',
  diet_id           UUID REFERENCES public.diets(id) ON DELETE SET NULL,
  theme_id          UUID REFERENCES public.themes(id) ON DELETE SET NULL,
  created_by        UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_seasonal       BOOLEAN DEFAULT false,
  available_from    DATE,
  available_until   DATE,
  published_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.menu_images (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  menu_id       UUID NOT NULL REFERENCES public.menus(id) ON DELETE CASCADE,
  image_url     TEXT NOT NULL,
  alt_text      TEXT,
  display_order INTEGER DEFAULT 0,
  is_primary    BOOLEAN DEFAULT false,
  uploaded_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.menu_ingredients (
  menu_id             UUID NOT NULL REFERENCES public.menus(id) ON DELETE CASCADE,
  ingredient_id       UUID NOT NULL REFERENCES public.ingredients(id) ON DELETE CASCADE,
  quantity_per_person NUMERIC(10,3),
  PRIMARY KEY (menu_id, ingredient_id)
);

-- M:N junction: menus <-> dishes
CREATE TABLE IF NOT EXISTS public.menu_dishes (
  menu_id UUID NOT NULL REFERENCES public.menus(id) ON DELETE CASCADE,
  dish_id UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
  PRIMARY KEY (menu_id, dish_id)
);

ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_dishes ENABLE ROW LEVEL SECURITY;
