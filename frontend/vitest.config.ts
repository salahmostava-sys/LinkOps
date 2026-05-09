import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./vitest.setup.ts'],
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
      },
    },
  })
);
