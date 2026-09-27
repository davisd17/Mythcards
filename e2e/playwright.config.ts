import { defineConfig } from '@playwright/test';

// Drives build/web (made by tools/export_web.ps1) through TestBridge's window hooks.
// tools/run_e2e.ps1 exports, installs, and runs this in one step.
const PORT = 8061;

export default defineConfig({
  testDir: './tests',
  timeout: 180_000,
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: `http://localhost:${PORT}/`,
    viewport: { width: 405, height: 720 },  // phone portrait
    launchOptions: {
      // Headless has no GPU; SwiftShader gives Godot a WebGL 2 context.
      args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
    },
  },
  webServer: {
    command: `powershell -NoProfile -ExecutionPolicy Bypass -File ../tools/serve_web.ps1 -Port ${PORT}`,
    url: `http://localhost:${PORT}/`,
    reuseExistingServer: true,
    timeout: 30_000,
  },
});
