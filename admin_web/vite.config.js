import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// Сборка в backend/static/admin — отдаётся FastAPI на том же порту, что и API
export default defineConfig({
  plugins: [react()],
  base: '/panel/',
  server: {
    proxy: {
      '/auth': 'http://127.0.0.1:8080',
      '/admin': 'http://127.0.0.1:8080',
      '/users': 'http://127.0.0.1:8080',
      '/events': 'http://127.0.0.1:8080',
      '/uploads': 'http://127.0.0.1:8080',
    }
  },
  build: {
    outDir: path.resolve(__dirname, '../backend/static/admin'),
    emptyOutDir: true,
  },
})
