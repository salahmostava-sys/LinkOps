import { z } from 'zod';

const uuidSchema = z.string().uuid();
const monthSchema = z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/);
const roleSchema = z.enum(['admin', 'hr', 'finance', 'operations', 'viewer']);
const passwordSchema = z.string().min(8).max(128);
const emailSchema = z.string().trim().email().max(254).transform((value) => value.toLowerCase());
const nameSchema = z.string().trim().min(1).max(150);
const noteSchema = z.string().trim().max(500).nullable().optional();
const paymentMethodSchema = z.enum(['cash', 'bank']).default('cash');

const salaryEmployeeSchema = z.object({
  mode: z.literal('employee'),
  month_year: monthSchema,
  employee_id: uuidSchema,
  payment_method: paymentMethodSchema,
  manual_deduction: z.coerce.number().finite().min(0).max(1_000_000).default(0),
  manual_deduction_note: noteSchema,
}).strict();

const salaryMonthSchema = z.object({
  mode: z.literal('month'),
  month_year: monthSchema,
  payment_method: paymentMethodSchema,
}).strict();

const salaryPreviewSchema = z.object({
  mode: z.literal('month_preview'),
  month_year: monthSchema,
}).strict();

const salaryRequestSchema = z.discriminatedUnion('mode', [
  salaryEmployeeSchema,
  salaryMonthSchema,
  salaryPreviewSchema,
]);

const adminRequestSchemas = {
  create_user: z.object({
    action: z.literal('create_user'),
    email: emailSchema,
    password: passwordSchema,
    name: nameSchema,
    role: roleSchema.default('viewer'),
  }).strict(),
  update_user: z.object({
    action: z.literal('update_user'),
    user_id: uuidSchema,
    email: emailSchema.optional(),
    password: z.union([passwordSchema, z.literal('')]).optional(),
    name: nameSchema.optional(),
    role: roleSchema.optional(),
    is_active: z.boolean().optional(),
  }).strict().refine(
    ({ email, password, name, role, is_active }) => (
      email !== undefined
      || password !== undefined
      || name !== undefined
      || role !== undefined
      || is_active !== undefined
    ),
    { message: 'At least one user field is required' },
  ),
  delete_user: z.object({ action: z.literal('delete_user'), user_id: uuidSchema }).strict(),
  revoke_session: z.object({ action: z.literal('revoke_session'), user_id: uuidSchema }).strict(),
  update_password: z.object({
    action: z.literal('update_password'),
    user_id: uuidSchema,
    password: passwordSchema,
  }).strict(),
};

const chatMessageSchema = z.object({
  role: z.enum(['system', 'user', 'assistant', 'tool']),
  content: z.string().max(32_000),
}).passthrough();

const messagesSchema = z.array(chatMessageSchema).min(1).max(100);

const groqRequestSchema = z.object({
  messages: messagesSchema,
  model: z.string().trim().min(1).max(100).regex(/^[A-Za-z0-9._:/-]+$/).optional(),
  temperature: z.number().finite().min(0).max(2).optional(),
  max_tokens: z.number().int().min(1).max(4096).optional(),
}).strict();

const aiChatRequestSchema = z.object({ messages: messagesSchema }).strict();

const analyticsPathSchema = z.enum([
  '/predict-salary',
  '/best-employee',
  '/analyze',
  '/predict-orders',
  '/best-driver',
  '/top-platform',
  '/smart-alerts',
  '/detect-anomalies',
]);

const analyticsRequestSchema = z.object({
  path: analyticsPathSchema,
  payload: z.record(z.unknown()).refine(
    (payload) => JSON.stringify(payload).length <= 1_000_000,
    { message: 'Analytics payload is too large' },
  ),
}).strict();

function formatValidationError(error) {
  const issue = error.issues[0];
  const field = issue?.path?.length ? issue.path.join('.') : 'request';
  return `Invalid ${field}: ${issue?.message ?? 'invalid value'}`;
}

function validate(schema, input) {
  const parsed = schema.safeParse(input);
  if (parsed.success) return { ok: true, value: parsed.data };
  return { ok: false, error: formatValidationError(parsed.error) };
}

export const validateSalaryRequest = (input) => validate(salaryRequestSchema, input);

export function validateAdminRequest(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return { ok: false, error: 'Invalid request: expected an object' };
  }
  const action = input.action || (input.password ? 'update_password' : undefined);
  const schema = adminRequestSchemas[action];
  if (!schema) return { ok: false, error: 'Invalid action: unsupported action' };
  return validate(schema, { ...input, action });
}

export const validateGroqRequest = (input) => validate(groqRequestSchema, input);
export const validateAiChatRequest = (input) => validate(aiChatRequestSchema, input);
export const validateAiAnalyticsRequest = (input) => validate(analyticsRequestSchema, input);
