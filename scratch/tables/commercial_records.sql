CREATE TABLE IF NOT EXISTS public.commercial_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT commercial_records_name_not_blank CHECK (btrim(name) <> '')
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_commercial_records_name_ci
  ON public.commercial_records (lower(btrim(name)));
ALTER TABLE public.commercial_records ENABLE ROW LEVEL SECURITY;