import assert from 'node:assert/strict';
import test from 'node:test';

import {
  validateAdminRequest,
  validateAiAnalyticsRequest,
  validateAiChatRequest,
  validateGroqRequest,
  validateSalaryRequest,
} from './requestValidation.js';

const userId = '8d3f7444-7e9c-4f11-87aa-d92726b2dede';

test('salary validation preserves all supported request modes', () => {
  assert.equal(validateSalaryRequest({
    mode: 'employee',
    month_year: '2026-07',
    employee_id: userId,
    payment_method: 'cash',
    manual_deduction: 0,
    manual_deduction_note: null,
  }).ok, true);
  assert.equal(validateSalaryRequest({
    mode: 'month',
    month_year: '2026-07',
    payment_method: 'bank',
  }).ok, true);
  assert.equal(validateSalaryRequest({
    mode: 'month_preview',
    month_year: '2026-07',
  }).ok, true);
});

test('salary validation rejects invalid identifiers, months and amounts', () => {
  const result = validateSalaryRequest({
    mode: 'employee',
    month_year: '2026-13',
    employee_id: 'not-a-uuid',
    manual_deduction: -1,
  });
  assert.equal(result.ok, false);
});

test('admin validation normalizes create-user fields and rejects weak passwords', () => {
  const valid = validateAdminRequest({
    action: 'create_user',
    email: '  USER@Example.COM ',
    password: 'strong-pass-123',
    name: '  Test User ',
    role: 'viewer',
  });
  assert.equal(valid.ok, true);
  assert.equal(valid.value.email, 'user@example.com');
  assert.equal(valid.value.name, 'Test User');

  const invalid = validateAdminRequest({
    action: 'update_password',
    user_id: userId,
    password: 'short',
  });
  assert.equal(invalid.ok, false);
});

test('admin validation preserves empty optional password and requires boolean status', () => {
  assert.equal(validateAdminRequest({
    action: 'update_user',
    user_id: userId,
    password: '',
    name: 'Updated User',
  }).ok, true);
  assert.equal(validateAdminRequest({
    action: 'update_user',
    user_id: userId,
    is_active: 'false',
  }).ok, false);
});

test('chat validation limits message shape, count and generation ranges', () => {
  assert.equal(validateGroqRequest({
    messages: [{ role: 'user', content: 'Hello' }],
    temperature: 0.5,
    max_tokens: 512,
  }).ok, true);
  assert.equal(validateGroqRequest({
    messages: [{ role: 'user', content: 'Hello' }],
    temperature: 5,
  }).ok, false);
  assert.equal(validateAiChatRequest({
    messages: [{ role: 'unknown', content: 'Hello' }],
  }).ok, false);
});

test('analytics validation allows known paths and rejects invalid payloads', () => {
  assert.equal(validateAiAnalyticsRequest({
    path: '/predict-salary',
    payload: { current_orders: 100, days_passed: 10 },
  }).ok, true);
  assert.equal(validateAiAnalyticsRequest({
    path: '/unknown',
    payload: {},
  }).ok, false);
  assert.equal(validateAiAnalyticsRequest({
    path: '/predict-salary',
    payload: [],
  }).ok, false);
});
