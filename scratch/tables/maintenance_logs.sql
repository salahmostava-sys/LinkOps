CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type public.maintenance_type NOT NULL DEFAULT 'routine',
  description TEXT,
  cost NUMERIC(10,2) DEFAULT 0,
  paid_by TEXT DEFAULT 'company',
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'completed',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_logs ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.maintenance_logs ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.maintenance_logs ADD CONSTRAINT maintenance_logs_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_mileage_company_id_fkey') THEN
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
  maintenance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  type TEXT NOT NULL
    CHECK (type IN (
      'غيار زيت', 'صيانة دورية', 'إطارات', 'بطارية', 'فرامل', 'أعطال', 'أخرى'
    )),
  odometer_reading NUMERIC(10, 0),
  total_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'مكتملة'
    CHECK (status IN ('مكتملة', 'جارية', 'ملغاة')),
  notes TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_logs
  DROP CONSTRAINT IF EXISTS maintenance_logs_created_by_fkey;
ALTER TABLE public.maintenance_logs
  ADD CONSTRAINT maintenance_logs_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;