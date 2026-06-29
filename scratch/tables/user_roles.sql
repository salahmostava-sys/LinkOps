ALTER TABLE public.user_roles
  ADD COLUMN IF NOT EXISTS role_id UUID;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_roles_role_id_fkey'
      AND conrelid = 'public.user_roles'::regclass
  ) THEN
    ALTER TABLE public.user_roles
      ADD CONSTRAINT user_roles_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;
  END IF;
END $$;
UPDATE public.user_roles ur
SET role_id = r.id
FROM public.roles r
WHERE ur.role_id IS NULL
  AND lower(r.title) = lower(ur.role::text);
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_roles_user_role_id
  ON public.user_roles(user_id, role_id)
  WHERE role_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id
  ON public.user_roles(role_id);

-- FILE: 20260325001000_attendance_checkin_checkout_metrics.sql
ALTER TABLE public.user_roles ADD COLUMN IF NOT EXISTS company_id uuid;
ALTER TABLE public.user_roles ALTER COLUMN company_id SET DEFAULT public.jwt_company_id();
    ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.trade_registers(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_permissions_company_id_fkey') THEN
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.user_roles           ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;