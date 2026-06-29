CREATE TABLE IF NOT EXISTS public.attendance_status_configs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  color text NOT NULL DEFAULT '#6366f1',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.attendance_status_configs ENABLE ROW LEVEL SECURITY;

-- FILE: 20260411010000_rls_edge_rate_limits.sql