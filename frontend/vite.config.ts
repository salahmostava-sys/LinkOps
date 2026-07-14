import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { visualizer } from "rollup-plugin-visualizer";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const isAnalyze = process.env.ANALYZE === 'true';

export default defineConfig({
  server: {
    host: "0.0.0.0",
    port: 5000,
    allowedHosts: true,
    hmr: {
      overlay: false,
    },
    proxy: {
      "/api/functions": {
        target: "http://localhost:3001",
        changeOrigin: true,
      },
    },
  },
  plugins: [
    react(),
    ...(isAnalyze
      ? [
          visualizer({
            open: true,
            gzipSize: true,
            brotliSize: true,
            filename: 'dist/stats.html',
          }),
        ]
      : []),
  ],
  resolve: {
    dedupe: ["react", "react-dom"],
    alias: {
      "@app": path.resolve(__dirname, "./app"),
      "@services": path.resolve(__dirname, "./services"),
      "@modules": path.resolve(__dirname, "./modules"),
      "@shared": path.resolve(__dirname, "./shared"),
    },
  },
  build: {
    chunkSizeWarningLimit: 600,
  },
});
