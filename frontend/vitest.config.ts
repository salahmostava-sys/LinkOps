import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./vitest.setup.ts'],
      // Exclude Playwright E2E specs — they must run via `playwright test`, not vitest
      exclude: [
        '**/node_modules/**',
        '**/dist/**',
        'e2e/**',
      ],
      env: {
        // Dummy Supabase credentials so client.ts doesn't throw during module init in tests.
        // Real network calls are always blocked by vi.mock('@services/supabase/client').
        VITE_SUPABASE_URL: 'https://test.supabase.co',
        VITE_SUPABASE_PUBLISHABLE_KEY: 'test-anon-key',
      },
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html', 'lcov'],
        exclude: [
          'node_modules/',
          'vitest.setup.ts',
          '**/*.d.ts',
          '**/*.config.*',
          '**/mockData',
          '**/__mocks__',
          '**/__tests__',
          '**/types.ts',
        ],
        thresholds: {
          statements: 50,
          branches: 50,
          functions: 50,
          lines: 50,
        },
      },
    },
  })
);
