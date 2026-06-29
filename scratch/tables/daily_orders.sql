CREATE TABLE IF NOT EXISTS public.daily_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  app_id UUID NOT NULL REFERENCES public.apps(id),
  orders_count INT NOT NULL DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date, app_id)
);
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'confirmed'
  CHECK (status IN ('draft', 'confirmed', _const_order_cancelled()));
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual';
CREATE INDEX IF NOT EXISTS idx_daily_orders_employee_date ON public.daily_orders(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_orders_app_date ON public.daily_orders(app_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_orders_status ON public.daily_orders(status);
COMMENT ON TABLE public.daily_orders IS 'Orders fact table (platform/app level). platform_id is represented by app_id.';
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'attendance_check_out_after_check_in_chk'
      AND conrelid = 'public.attendance'::regclass
  ) THEN
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.daily_orders
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.daily_orders
      ADD CONSTRAINT daily_orders_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'advances_company_id_fkey'
      AND conrelid = 'public.advances'::regclass
  ) THEN
ALTER TABLE public.daily_orders
  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.daily_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_orders         ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.daily_orders
  ADD COLUMN IF NOT EXISTS import_batch_id UUID REFERENCES public.order_import_batches(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_daily_orders_import_batch_id
  ON public.daily_orders(import_batch_id);
ALTER TABLE public.daily_orders
  DROP CONSTRAINT IF EXISTS daily_orders_created_by_fkey;
ALTER TABLE public.daily_orders
  ADD CONSTRAINT daily_orders_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;