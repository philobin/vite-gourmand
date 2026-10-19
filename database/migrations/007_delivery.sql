-- 007_delivery.sql
-- Delivery assignments and tracking

CREATE TABLE IF NOT EXISTS public.delivery_assignments (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id           UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_person_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vehicle_type       TEXT,
  status             TEXT DEFAULT 'assigned'
                     CHECK (status IN ('assigned', 'picked_up', 'in_transit', 'delivered', 'failed')),
  assigned_at        TIMESTAMPTZ DEFAULT now(),
  picked_up_at       TIMESTAMPTZ,
  delivered_at       TIMESTAMPTZ,
  delivery_notes     TEXT,
  proof_photo_url    TEXT,
  client_rating      SMALLINT CHECK (client_rating BETWEEN 1 AND 5),
  UNIQUE (order_id)
);

ALTER TABLE public.delivery_assignments ENABLE ROW LEVEL SECURITY;
