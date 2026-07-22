-- Drop the old product branding that was baked into the client-company field.
-- Supersedes 20260325140000_rename_project_muhimmat_altawseel.sql.
--
-- IMPORTANT: system_settings.project_name_* is the CLIENT COMPANY name (set per
-- deployment by an admin from Project Settings) — NOT the software's name.
-- The software/product name («وصلة / Wasla») lives in the frontend code and is
-- used as the fallback when the company name is blank. So this migration only
-- CLEARS the stale company value; it must NOT write the product name here.

ALTER TABLE public.system_settings
  ALTER COLUMN project_name_ar SET DEFAULT '',
  ALTER COLUMN project_name_en SET DEFAULT '';

UPDATE public.system_settings
SET
  project_name_ar = '',
  project_name_en = '',
  updated_at = now();

-- The default salary-slip template header carried an old hardcoded brand. The
-- payslip header represents the issuing company, which is now blank by default,
-- so strip the stale brand and let the admin set it from the template editor.
UPDATE public.salary_slip_templates
SET header_html = REPLACE(header_html, 'Muhimmat Delivery', '')
WHERE header_html LIKE '%Muhimmat Delivery%';
