ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp']) -- NOSONAR
ON CONFLICT (id) DO NOTHING;

-- FILE: 20260308075948_985c6682-cdd2-4600-b9e6-5cd61215cebd.sql
﻿
ALTER TABLE public.profiles
ALTER COLUMN is_active SET DEFAULT false;

-- FILE: 20260324140000_pricing_rules.sql
﻿-- Pricing rules for payroll calculation (db-driven)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.profiles
  ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'attendance_company_id_fkey'
      AND conrelid = 'public.attendance'::regclass
  ) THEN