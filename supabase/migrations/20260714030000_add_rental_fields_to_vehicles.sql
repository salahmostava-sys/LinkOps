-- Add rental tracking fields to vehicles.
-- Needed only when status = 'rental'.

ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS rental_start_date    DATE           NULL,
  ADD COLUMN IF NOT EXISTS rental_monthly_amount NUMERIC(12, 2) NULL;

ALTER TABLE public.vehicles
  ADD CONSTRAINT vehicles_rental_amount_check
    CHECK (rental_monthly_amount IS NULL OR rental_monthly_amount >= 0);

COMMENT ON COLUMN public.vehicles.rental_start_date     IS 'Date the vehicle rental agreement started. Used to compute monthly due-date reminders.';
COMMENT ON COLUMN public.vehicles.rental_monthly_amount IS 'Monthly rental cost in SAR. NULL for non-rental vehicles.';
