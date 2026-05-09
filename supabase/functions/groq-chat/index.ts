/**
 * groq-chat Edge Function
 *
 * Security model (mirrors salary-engine):
 * - Requires a valid Supabase JWT (Authorization: Bearer <token>)
 * - Verifies the caller is an authenticated user (any role)
 * - Rate-limited per user: 20 requests / 60 seconds via enforce_rate_limit RPC
 * - GROQ_API_KEY is never exposed to the browser
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { getCorsHeaders, handleCorsPreflight } from '../_shared/cors.ts';

const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
const GROQ_BASE_URL = 'https://api.groq.com/openai/v1';
const DEFAULT_MODEL = Deno.env.get('GROQ_MODEL') ?? 'llama3-8b-8192';

const jsonResponse = (body: unknown, status: number, origin: string | null) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
  });

const logInfo = (message: string, meta: Record<string, unknown> = {}) => {
  console.log(JSON.stringify({ level: 'info', message, ...meta, ts: new Date().toISOString() }));
};

const logError = (message: string, meta: Record<string, unknown> = {}) => {
  console.error(JSON.stringify({ level: 'error', message, ...meta, ts: new Date().toISOString() }));
};

async function authorizeUser(req: Request, requestOrigin: string | null, requestId: string) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return { errorResp: jsonResponse({ error: 'No authorization header' }, 401, requestOrigin) };

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) {
    logError('Supabase client environment variables not configured', { request_id: requestId });
    return { errorResp: jsonResponse({ error: 'Server misconfiguration' }, 500, requestOrigin) };
  }

  const callerClient = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader } } });
  const { data: { user: callerUser } } = await callerClient.auth.getUser();
  if (!callerUser) return { errorResp: jsonResponse({ error: 'Not authenticated' }, 401, requestOrigin) };

  return { callerUser, supabaseUrl };
}

async function checkRateLimit(supabaseUrl: string, callerUserId: string, requestOrigin: string | null, requestId: string) {
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseServiceRoleKey) {
    logError('SUPABASE_SERVICE_ROLE_KEY not configured', { request_id: requestId });
    return { errorResp: jsonResponse({ error: 'Server misconfiguration' }, 500, requestOrigin) };
  }

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
  const rateLimitKey = `groq-chat:${callerUserId}`;
  const { data: rateLimitRows, error: rateLimitError } = await adminClient.rpc('enforce_rate_limit', {
    p_key: rateLimitKey, p_limit: 20, p_window_seconds: 60,
  } as Record<string, unknown>);

  if (rateLimitError) {
    logError('Rate limit RPC failed', { request_id: requestId, error: rateLimitError.message });
  } else {
    const rate = Array.isArray(rateLimitRows)
      ? (rateLimitRows[0] as { allowed?: boolean; remaining?: number } | undefined)
      : undefined;

    if (rate && !rate.allowed) {
      logError('Rate limit exceeded', { request_id: requestId, user_id: callerUserId });
      return { errorResp: jsonResponse({ error: 'Too many requests. Please retry shortly.' }, 429, requestOrigin) };
    }
  }
  return {};
}

async function callGroqApi(messages: unknown[], model: unknown, temperature: unknown, maxTokens: unknown, requestId: string) {
  const groqResponse = await fetch(`${GROQ_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${GROQ_API_KEY}` },
    body: JSON.stringify({
      model: typeof model === 'string' ? model : DEFAULT_MODEL,
      messages,
      temperature: typeof temperature === 'number' ? temperature : 0.7,
      max_tokens: typeof maxTokens === 'number' ? maxTokens : 1024,
      stream: false,
    }),
  });

  if (!groqResponse.ok) {
    const errText = await groqResponse.text();
    logError('Groq API error', { request_id: requestId, status: groqResponse.status, body: errText });
    return { errorStatus: groqResponse.status };
  }

  const data = await groqResponse.json();
  return { message: data.choices?.[0]?.message?.content ?? '' };
}

Deno.serve(async (req) => {
  const requestOrigin = req.headers.get('origin');
  if (req.method === 'OPTIONS') return handleCorsPreflight(requestOrigin);

  const requestId = crypto.randomUUID();

  try {
    if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405, requestOrigin);

    if (!GROQ_API_KEY) {
      logError('GROQ_API_KEY not configured', { request_id: requestId });
      return jsonResponse({ error: 'AI service is not configured on the server' }, 500, requestOrigin);
    }

    const authRes = await authorizeUser(req, requestOrigin, requestId);
    if (authRes.errorResp) return authRes.errorResp;
    const { callerUser, supabaseUrl } = authRes as { callerUser: any; supabaseUrl: string };

    const rlRes = await checkRateLimit(supabaseUrl, callerUser.id, requestOrigin, requestId);
    if (rlRes.errorResp) return rlRes.errorResp;

    let body: { messages?: unknown; model?: unknown; temperature?: unknown; max_tokens?: unknown };
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON body' }, 400, requestOrigin);
    }

    const { messages, model, temperature, max_tokens } = body;
    if (!Array.isArray(messages) || messages.length === 0) {
      return jsonResponse({ error: 'messages must be a non-empty array' }, 400, requestOrigin);
    }

    logInfo('groq-chat request accepted', { request_id: requestId, user_id: callerUser.id, message_count: messages.length });

    const groqRes = await callGroqApi(messages, model, temperature, max_tokens, requestId);
    if (groqRes.errorStatus) {
      return jsonResponse({ error: `AI service error (${groqRes.errorStatus})` }, 502, requestOrigin);
    }

    return jsonResponse({ message: groqRes.message }, 200, requestOrigin);
  } catch (e) {
    const errMsg = e instanceof Error ? e.message : String(e);
    logError('groq-chat unhandled error', { request_id: requestId, error: errMsg });
    return jsonResponse({ error: 'Internal server error' }, 500, requestOrigin);
  }
});
