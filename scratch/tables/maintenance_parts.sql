CREATE TABLE IF NOT EXISTS public.maintenance_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  maintenance_log_id UUID NOT NULL REFERENCES public.maintenance_logs(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES public.spare_parts(id) ON DELETE RESTRICT,
  quantity_used NUMERIC(10, 2) NOT NULL,
  cost_at_time NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_vehicle_id ON public.maintenance_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_logs_maintenance_date ON public.maintenance_logs(maintenance_date DESC);
CREATE INDEX IF NOT EXISTS idx_maintenance_parts_log_id ON public.maintenance_parts(maintenance_log_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_parts_part_id ON public.maintenance_parts(part_id);
ALTER TABLE public.maintenance_parts ENABLE ROW LEVEL SECURITY;
COMMIT;

-- FILE: 20260328222000_fleet_maintenance_triggers.sql
BEGIN;
COMMIT;

-- FILE: 20260329123000_ensure_spare_parts_exists.sql
﻿-- Ensure fleet spare parts table exists on environments that missed prior migration.