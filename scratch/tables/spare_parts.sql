CREATE TABLE IF NOT EXISTS public.spare_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  part_number TEXT,
  stock_quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
  min_stock_alert NUMERIC(10, 2) DEFAULT 5,
  unit TEXT DEFAULT 'قطعة',
  unit_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,
  supplier TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260328221000_fleet_maintenance_logs_and_parts.sql
﻿-- Replace legacy maintenance_logs with fleet maintenance + line-item parts.
BEGIN;
CREATE TABLE IF NOT EXISTS public.spare_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  part_number TEXT,
  stock_quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
  min_stock_alert NUMERIC(10, 2) DEFAULT 5,
  unit TEXT DEFAULT 'قطعة',
  unit_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,
  supplier TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;
COMMIT;
NOTIFY pgrst, 'reload schema';

-- FILE: 20260329143000_supervisor_targets_and_assignments.sql
﻿-- Supervisor monthly targets + rider assignments (single-org safe).
BEGIN;