-- 009_reviews.sql
-- Reviews (renamed from Back/'s "Publish" table) with moderation + images

CREATE TABLE IF NOT EXISTS public.reviews (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id      UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  note          SMALLINT NOT NULL CHECK (note BETWEEN 1 AND 5),
  description   TEXT,
  status        TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  moderated_by  UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  moderated_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.review_images (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id   UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
  image_url   TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_images ENABLE ROW LEVEL SECURITY;
