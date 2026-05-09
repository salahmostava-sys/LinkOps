import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { getCorsHeaders, handleCorsPreflight } from '../_shared/cors.ts';

const isUuid = (value: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);

const VALID_ROLES = new Set(['admin', 'hr', 'finance', 'operations', 'viewer']);

const isValidRole = (value: string): value is 'admin' | 'hr' | 'finance' | 'operations' | 'viewer' =>
  VALID_ROLES.has(value);

const logInfo = (message: string, meta: Record<string, unknown> = {}) => {
  console.log(JSON.stringify({ level: 'info', message, ...meta, ts: new Date().toISOString() }));
};

const logError = (message: string, meta: Record<string, unknown> = {}) => {
  console.error(JSON.stringify({ level: 'error', message, ...meta, ts: new Date().toISOString() }));
};

function getSafeErrorMessage(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (typeof err === 'string') return err;
  try {
    return JSON.stringify(err);
  } catch {
    return 'Unknown error';
  }
}

async function handleCreateUser(supabaseAdmin: any, payload: any, requestId: string) {
  const normalizedEmail = String(payload.email ?? '').trim().toLowerCase();
  const normalizedName = String(payload.name ?? '').trim();
  const normalizedRole = String(payload.role ?? 'viewer').trim();

  if (!normalizedEmail || !normalizedEmail.includes('@')) throw new Error('Invalid email');
  if (!payload.password || String(payload.password).length < 8) throw new Error('Password must be at least 8 characters');
  if (!normalizedName) throw new Error('name is required');
  if (!isValidRole(normalizedRole)) throw new Error('Invalid role');

  let createdUserId: string | null = null;
  try {
    const { data: createdUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: normalizedEmail,
      password: payload.password,
      email_confirm: true,
      user_metadata: { name: normalizedName },
    });
    if (createError) throw createError;

    createdUserId = createdUser.user?.id ?? null;
    if (!createdUserId) throw new Error('User creation returned no user id');

    const { error: profileError } = await supabaseAdmin.from('profiles')
      .update({ email: normalizedEmail, name: normalizedName, is_active: true })
      .eq('id', createdUserId);
    if (profileError) throw profileError;

    const { error: clearRolesError } = await supabaseAdmin.from('user_roles')
      .delete().eq('user_id', createdUserId);
    if (clearRolesError) throw clearRolesError;

    const { error: insertRoleError } = await supabaseAdmin.from('user_roles')
      .insert({ user_id: createdUserId, role: normalizedRole });
    if (insertRoleError) throw insertRoleError;
    } catch (createUserFlowError) {
      if (createdUserId) {
        await supabaseAdmin.auth.admin.deleteUser(createdUserId).catch((cleanupError: unknown) => {
          logError('Failed to cleanup partially created user', {
            request_id: requestId, target_user_id: createdUserId,
            error: getSafeErrorMessage(cleanupError),
          });
        });
      }
      throw createUserFlowError;
    }
  return createdUserId;
}

async function handleRevokeSession(supabaseAdmin: any, userId: string) {
  const authSchema = supabaseAdmin.schema('auth');
  const { error: refreshTokensError } = await authSchema.from('refresh_tokens').delete().eq('user_id', userId);
  if (refreshTokensError) throw refreshTokensError;
  const { error: sessionsError } = await authSchema.from('sessions').delete().eq('user_id', userId);
  if (sessionsError) throw sessionsError;
}

async function verifyAdminCaller(req: Request) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw new Error('Not authenticated');

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) throw new Error('Missing Supabase env vars');

  const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader } } });
  const { data: { user: callerUser } } = await supabaseClient.auth.getUser();
  if (!callerUser) throw new Error('Not authenticated');

  const { data: roleData } = await supabaseClient.from('user_roles').select('role').eq('user_id', callerUser.id).maybeSingle();
  if (roleData?.role !== 'admin') throw new Error('Only admins can update users');

  return callerUser;
}

async function checkRateLimit(supabaseAdmin: any, callerUserId: string, targetUserId?: string, requestId?: string) {
  const rateKey = `admin-update-user:${callerUserId}`;
  const { data: rateRows, error: rateError } = await supabaseAdmin.rpc('enforce_rate_limit', {
    p_key: rateKey,
    p_limit: 10,
    p_window_seconds: 60,
  } as Record<string, unknown>);
  if (rateError) throw rateError;

  const rate = Array.isArray(rateRows)
    ? (rateRows[0] as { allowed?: boolean; remaining?: number } | undefined)
    : undefined;

  if (!rate?.allowed) {
    logError('Rate limit exceeded', { request_id: requestId, admin_user_id: callerUserId, target_user_id: targetUserId });
    const err = new Error('Too many requests. Please retry shortly.');
    (err as any).status = 429;
    throw err;
  }
  return rate;
}

async function routeAdminAction(
  action: string,
  supabaseAdmin: any,
  payload: { user_id?: string; email?: string; name?: string; role?: string; password?: string; callerUserId: string },
  requestId: string,
) {
  if (action === 'create_user') {
    const createdUserId = await handleCreateUser(supabaseAdmin, { email: payload.email, name: payload.name, role: payload.role, password: payload.password }, requestId);
    return { user_id: createdUserId };
  }
  if (!payload.user_id) throw new Error('user_id is required');
  if (!isUuid(payload.user_id)) throw new Error('Invalid user_id');

  if (action === 'delete_user') {
    if (payload.user_id === payload.callerUserId) throw new Error('You cannot delete your own account');
    const { error } = await supabaseAdmin.auth.admin.deleteUser(payload.user_id);
    if (error) throw error;
  } else if (action === 'revoke_session') {
    await handleRevokeSession(supabaseAdmin, payload.user_id);
  } else if (action === 'update_password') {
    if (!payload.password) throw new Error('password is required for update_password');
    const { error } = await supabaseAdmin.auth.admin.updateUserById(payload.user_id, { password: payload.password });
    if (error) throw error;
  } else {
    throw new Error('Unsupported action');
  }
  return { user_id: payload.user_id };
}

function resolveErrorStatus(rawMessage: string): number {
  const lowerMessage = rawMessage.toLowerCase();
  if (lowerMessage.includes('only admins') || lowerMessage.includes('not authenticated')) return 403;
  if (lowerMessage.includes('user_id is required') || lowerMessage.includes('invalid user_id')) return 404;
  const clientErrorPatterns = ['invalid', 'required', 'must be', 'cannot delete', 'too many requests', 'action is required'];
  if (clientErrorPatterns.some((p) => lowerMessage.includes(p))) return 400;
  return 500;
}

Deno.serve(async (req) => {
  const requestOrigin = req.headers.get('origin');
  if (req.method === 'OPTIONS') return handleCorsPreflight(requestOrigin);

  const requestId = crypto.randomUUID();

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { headers: { ...getCorsHeaders(requestOrigin), 'Content-Type': 'application/json' }, status: 405 });
    }

    const callerUser = await verifyAdminCaller(req);

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !supabaseServiceRoleKey) throw new Error('Missing admin env vars');
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    const payload = await req.json();
    const { user_id, password, email, name, role, action } = payload;
    let normalizedAction = action;
    if (!normalizedAction && password) {
      normalizedAction = 'update_password';
    }
    
    if (!normalizedAction) throw new Error('action is required');
    if (normalizedAction === 'create_user') {
      // create_user does not require user_id
    } else {
      if (!user_id) throw new Error('user_id is required');
      if (!isUuid(user_id)) throw new Error('Invalid user_id');
    }

    const rate = await checkRateLimit(supabaseAdmin, callerUser.id, user_id, requestId);

    logInfo('Admin update user request accepted', {
      request_id: requestId, admin_user_id: callerUser.id, target_user_id: user_id, remaining: rate.remaining ?? null,
    });

    await routeAdminAction(normalizedAction, supabaseAdmin, { user_id, email, name, role, password, callerUserId: callerUser.id }, requestId);

    return new Response(JSON.stringify({ success: true }), { headers: { ...getCorsHeaders(requestOrigin), 'Content-Type': 'application/json' }, status: 200 });
  } catch (err: unknown) {
    const rawMessage = getSafeErrorMessage(err);
    logError('Admin update user request failed', { request_id: requestId, error: rawMessage });

    const status = (err as any).status ?? resolveErrorStatus(rawMessage);

    const safeMessage = status !== 500 ? rawMessage : 'Internal server error';

    return new Response(JSON.stringify({ error: safeMessage }), {
      headers: { ...getCorsHeaders(requestOrigin), 'Content-Type': 'application/json' },
      status,
    });
  }
});
