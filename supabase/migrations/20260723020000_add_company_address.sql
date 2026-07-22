-- Company (establishment) postal address, shown in the footer of printed
-- documents (payslips, reports). Part of the client company's official identity.

ALTER TABLE public.trade_registers
  ADD COLUMN IF NOT EXISTS address text;

COMMENT ON COLUMN public.trade_registers.address IS 'Company address shown in printed-document footers.';
