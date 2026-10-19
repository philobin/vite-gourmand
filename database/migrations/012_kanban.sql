-- 012_kanban.sql
-- Kanban board columns for order management

CREATE TABLE IF NOT EXISTS public.kanban_columns (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  mapped_status TEXT,
  color         TEXT,
  position      INTEGER DEFAULT 0,
  is_active     BOOLEAN DEFAULT true,
  created_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.kanban_columns ENABLE ROW LEVEL SECURITY;
