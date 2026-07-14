-- Persist operational workflow metadata for generated and database alerts.

ALTER TABLE public.alerts
  ADD COLUMN IF NOT EXISTS source_key TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open',
  ADD COLUMN IF NOT EXISTS assigned_to UUID,
  ADD COLUMN IF NOT EXISTS estimated_cost NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS resolution_note TEXT,
  ADD COLUMN IF NOT EXISTS snoozed_until DATE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE public.alerts
SET status = 'resolved'
WHERE is_resolved IS TRUE
  AND status = 'open';

ALTER TABLE public.alerts
  DROP CONSTRAINT IF EXISTS alerts_status_check,
  ADD CONSTRAINT alerts_status_check
    CHECK (status IN ('open', 'in_progress', 'snoozed', 'resolved')),
  DROP CONSTRAINT IF EXISTS alerts_estimated_cost_check,
  ADD CONSTRAINT alerts_estimated_cost_check
    CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
  DROP CONSTRAINT IF EXISTS alerts_assigned_to_fkey,
  ADD CONSTRAINT alerts_assigned_to_fkey
    FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_source_key
  ON public.alerts (source_key);

CREATE INDEX IF NOT EXISTS idx_alerts_workflow_status_due_date
  ON public.alerts (status, due_date)
  WHERE status <> 'resolved';

CREATE INDEX IF NOT EXISTS idx_alerts_assigned_to
  ON public.alerts (assigned_to)
  WHERE assigned_to IS NOT NULL;

DROP TRIGGER IF EXISTS trg_alerts_updated_at ON public.alerts;
CREATE TRIGGER trg_alerts_updated_at
BEFORE UPDATE ON public.alerts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON COLUMN public.alerts.source_key IS
  'Stable key that materializes generated alerts without creating duplicates.';
COMMENT ON COLUMN public.alerts.status IS
  'Operational workflow state: open, in_progress, snoozed, or resolved.';
