import { http, HttpResponse } from 'msw';

const REST_ENDPOINT = '*/rest/v1/*';

export const handlers = [
  // Mock Supabase Auth
  http.post('*/auth/v1/token', () => {
    return HttpResponse.json({
      access_token: 'mock-access-token',
      refresh_token: 'mock-refresh-token',
      user: { id: 'mock-user-id', email: 'mock@example.com' },
    });
  }),
  
  http.get('*/auth/v1/user', () => {
    return HttpResponse.json({
      id: 'mock-user-id',
      email: 'mock@example.com',
    });
  }),

  // Mock Supabase PostgREST
  http.get(REST_ENDPOINT, () => {
    return HttpResponse.json([
      { id: 1, name: 'Mock Data' }
    ]);
  }),

  http.post(REST_ENDPOINT, () => {
    return HttpResponse.json({ success: true }, { status: 201 });
  }),

  http.patch(REST_ENDPOINT, () => {
    return HttpResponse.json({ success: true }, { status: 200 });
  }),

  http.delete(REST_ENDPOINT, () => {
    return HttpResponse.json(null, { status: 204 });
  }),
];
