-- Ø¥Ù‚ÙØ§Ù„ Ø¬Ø¯ÙˆÙ„ÙŠ hr_performance_reviews Ùˆ leave_requests Ø¨Ø§Ù„ÙƒØ§Ù…Ù„
-- Ø§Ù„Ù…ÙŠØ²Ø© Ø§ØªÙ„ØºØª Ù…Ù† Ø§Ù„ÙƒÙˆØ¯ (commit 4d7bcfb)ØŒ Ù„ÙƒÙ† Ø§Ù„Ø¬Ø¯ÙˆÙ„ÙŠÙ† ÙƒØ§Ù†ÙˆØ§ Ù„Ø³Ù‡ Ù…Ø¹Ø±Ù‘Ø¶ÙŠÙ†
-- Ù„Ù„Ù‚Ø±Ø§Ø¡Ø© Ø§Ù„Ø¹Ø§Ù…Ø© (RLS policy Ø¨Ø´Ø±Ø· true Ø¹Ù„Ù‰ Ø¯ÙˆØ± public â€” Ø£ÙŠ Ø´Ø®Øµ Ø¨Ø¯ÙˆÙ†
-- ØªØ³Ø¬ÙŠÙ„ Ø¯Ø®ÙˆÙ„ Ø£ØµÙ„Ø§Ù‹ ÙƒØ§Ù† ÙŠÙ‚Ø¯Ø± ÙŠÙ‚Ø±Ø£ ÙƒÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ÙÙŠÙ‡Ù… Ø¹Ø¨Ø± API Ù…Ø¨Ø§Ø´Ø±Ø©).
--
-- Ù‡Ø°Ø§ Ø§Ù„Ù…Ù„Ù ÙŠÙ‚ÙÙ„ Ø§Ù„ÙˆØµÙˆÙ„ Ø¨Ø§Ù„ÙƒØ§Ù…Ù„ (Ù„Ø§ SELECT ÙˆÙ„Ø§ Ø£ÙŠ Ø¹Ù…Ù„ÙŠØ©) Ø¨Ø¯Ù„ Ø­Ø°Ù
-- Ø§Ù„Ø¬Ø¯ÙˆÙ„ÙŠÙ† Ù†Ù‡Ø§Ø¦ÙŠÙ‹Ø§ØŒ Ø­ÙØ§Ø¸Ù‹Ø§ Ø¹Ù„Ù‰ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù‚Ø¯ÙŠÙ…Ø© Ù„Ùˆ Ø§Ø­ØªØ¬ØªÙˆÙ‡Ø§ Ù„Ø§Ø­Ù‚Ù‹Ø§
-- (ØªÙ‚Ø±ÙŠØ± ØªØ§Ø±ÙŠØ®ÙŠØŒ Ø£Ø±Ø´ÙŠÙØŒ Ø¥Ù„Ø®). Ù„Ùˆ Ù‚Ø±Ø±ØªÙˆØ§ Ù…Ø³ØªÙ‚Ø¨Ù„Ù‹Ø§ Ø¥Ù†ÙƒÙ… Ù…Ø´ Ù…Ø­ØªØ§Ø¬ÙŠÙ†
-- Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø¯ÙŠ Ø¥Ø·Ù„Ø§Ù‚Ù‹Ø§ØŒ Ù…Ù…ÙƒÙ† Ù†Ø¹Ù…Ù„ ØªØ±Ø­ÙŠÙ„Ø© ØªØ§Ù†ÙŠØ© ØªØ¹Ù…Ù„ DROP TABLE.

BEGIN;

-- hr_performance_reviews: Ø­Ø°Ù ÙƒÙ„ Ø§Ù„Ø³ÙŠØ§Ø³Ø§Øª Ø§Ù„Ø­Ø§Ù„ÙŠØ© (Ø§Ù„Ù…ÙƒØ±Ø±Ø© ÙˆØ§Ù„Ø£ØµÙ„ÙŠØ©)
DROP POLICY IF EXISTS "hr_reviews_select" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "unified_select_policy" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "hr_reviews_insert" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "unified_insert_policy" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "hr_reviews_update" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "unified_update_policy" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "hr_reviews_delete" ON public.hr_performance_reviews;
DROP POLICY IF EXISTS "unified_delete_policy" ON public.hr_performance_reviews;
-- Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø£ÙŠ policy Ø¨Ø¯ÙŠÙ„ Ø¨Ø¹Ø¯ Ø§Ù„Ø­Ø°Ù = RLS ÙŠØ±ÙØ¶ ÙƒÙ„ Ø´ÙŠØ¡ Ø¨Ø´ÙƒÙ„ Ø§ÙØªØ±Ø§Ø¶ÙŠ (fail-closed)

-- leave_requests: Ù†ÙØ³ Ø§Ù„Ø´ÙŠØ¡
DROP POLICY IF EXISTS "leave_requests_select" ON public.leave_requests;
DROP POLICY IF EXISTS "unified_select_policy" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_insert" ON public.leave_requests;
DROP POLICY IF EXISTS "unified_insert_policy" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_update" ON public.leave_requests;
DROP POLICY IF EXISTS "unified_update_policy" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_delete" ON public.leave_requests;
DROP POLICY IF EXISTS "unified_delete_policy" ON public.leave_requests;

NOTIFY pgrst, 'reload schema';

COMMIT;


