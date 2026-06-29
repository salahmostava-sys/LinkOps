CREATE TABLE IF NOT EXISTS public.order_import_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month_year TEXT NOT NULL CHECK (month_year ~ '^\d{4}-\d{2}$'),
  source_type TEXT NOT NULL DEFAULT 'manual'
    CHECK (source_type IN ('manual', 'excel', 'api')),
  file_name TEXT,
  target_app_id UUID REFERENCES public.apps(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT _const_installment_pending()
    CHECK (status IN (_const_installment_pending(), 'completed', 'failed')),
  total_rows INTEGER NOT NULL DEFAULT 0 CHECK (total_rows >= 0),
  imported_rows INTEGER NOT NULL DEFAULT 0 CHECK (imported_rows >= 0),
  skipped_rows INTEGER NOT NULL DEFAULT 0 CHECK (skipped_rows >= 0),
  error_count INTEGER NOT NULL DEFAULT 0 CHECK (error_count >= 0),
  error_summary JSONB NOT NULL DEFAULT '[]'::jsonb,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,
  started_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_order_import_batches_month_year
  ON public.order_import_batches(month_year, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_import_batches_status
  ON public.order_import_batches(status);
ALTER TABLE public.order_import_batches ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.order_import_batches IS
'Audit trail for orders imports and month replacements.';