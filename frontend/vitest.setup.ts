import '@testing-library/jest-dom/vitest';
import '@app/i18n';
import { cleanup } from '@testing-library/react';
import { beforeAll, afterEach, afterAll } from 'vitest';
import { server } from './tests/mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }));

// Cleanup after each test
afterEach(() => {
  cleanup();
  server.resetHandlers();
});

afterAll(() => server.close());
