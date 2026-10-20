import { test, expect, Page } from '@playwright/test';
import { boot, resolvePending, state, character } from './mythcards';

// docs/UI_STYLE_GUIDE.md section 10: the QA size matrix. Each size boots a match, selects a
// character, opens the menu and the full card, and screenshots each step. With
// RESPONSIVE_TAG=before|after the files land in test-results/responsive/.
// Measurements need ui_snapshot()'s `rect` and `role` fields (style guide phase 1); a build
// without them only gets screenshots.

const SIZES = [
  [360, 640], [390, 844], [405, 720], [768, 1024], [844, 390], [1280, 720], [1920, 1080],
];
const TAG = process.env.RESPONSIVE_TAG ?? 'after';

type Button = { text: string; center: { x: number; y: number }; disabled: boolean;
  rect?: { x: number; y: number; w: number; h: number }; role?: string; clipped?: boolean };

async function ui(page: Page): Promise<{ buttons: Button[]; tiles: Record<string, { x: number; y: number }>;
  popup: boolean; board?: { x: number; y: number; w: number; h: number }; mode?: string }> {
  return page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
}

async function closePopups(page: Page): Promise<void> {
  for (let i = 0; i < 6; i++) {
    const layout = await ui(page);
    if (!layout.popup) return;
    const b = layout.buttons.find((x) => x.text === 'Continue' || x.text === 'Close');
    if (!b) return;
    await page.mouse.click(b.center.x, b.center.y);
    await page.waitForTimeout(150);
  }
}

// The contract checks that apply to whatever is on screen right now.
function checkContract(layout: Awaited<ReturnType<typeof ui>>, vp: { width: number; height: number }, where: string): void {
  // A button its list has scrolled out of view is checked once it is scrolled back.
  const measured = layout.buttons.filter((b) => b.rect && b.role && !b.clipped);
  if (measured.length === 0) return;
  for (const b of measured) {
    const r = b.rect!;
    expect.soft(r.w, `${where}: "${b.text}" (${b.role}) is at least 44 px wide`).toBeGreaterThanOrEqual(43.5);
    expect.soft(r.h, `${where}: "${b.text}" (${b.role}) is at least 44 px tall`).toBeGreaterThanOrEqual(43.5);
    expect.soft(r.x >= -1 && r.y >= -1 && r.x + r.w <= vp.width + 1, `${where}: "${b.text}" is on screen horizontally`).toBe(true);
  }
  // Same-role commands share one height, and action-grid siblings one width.
  for (const role of ['command', 'choice', 'icon']) {
    const hs = measured.filter((b) => b.role === role).map((b) => b.rect!.h);
    if (hs.length > 1) expect.soft(Math.max(...hs) - Math.min(...hs), `${where}: ${role} heights ${hs}`).toBeLessThanOrEqual(1);
  }
  for (const role of ['action', 'option']) {
    const ws = measured.filter((b) => b.role === `command:${role}` || b.role === `choice:${role}`).map((b) => b.rect!.w);
    if (ws.length > 1) expect.soft(Math.max(...ws) - Math.min(...ws), `${where}: ${role} widths ${ws}`).toBeLessThanOrEqual(1);
  }
  if (layout.board) {
    expect.soft(Math.abs(layout.board.w - layout.board.h), `${where}: the board is square`).toBeLessThanOrEqual(1.5);
  }
}

for (const [width, height] of SIZES) {
  const name = `${width}x${height}`;
  test(`responsive HUD ${name}`, async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (m) => { if (m.type() === 'error' || /SCRIPT ERROR/.test(m.text())) errors.push(m.text()); });
    page.on('pageerror', (e) => errors.push(String(e)));
    const vp = { width, height };
    await page.setViewportSize(vp);
    await boot(page, 42);
    await resolvePending(page);
    await page.waitForTimeout(400);
    await closePopups(page);
    const shot = (step: string) => page.screenshot({ path: `test-results/responsive/${TAG}-${name}-${step}.png` });

    // A selected character: its summary and action buttons.
    const s = await state(page);
    const yuri = character(s, 'p1_r-yuri-volkov');
    let layout = await ui(page);
    const tile = layout.tiles[`${yuri.position.x},${yuri.position.y}`];
    await page.mouse.click(tile.x, tile.y);
    await page.waitForTimeout(300);
    layout = await ui(page);
    await shot('selected');
    checkContract(layout, vp, `${name} selected`);
    if (layout.buttons.some((b) => b.rect)) {
      expect(layout.buttons.find((b) => b.text === 'End turn'), 'End turn is reachable').toBeTruthy();
      expect(layout.buttons.filter((b) => b.role === 'command:action').length, 'the actions show').toBeGreaterThan(0);
    }

    // The menu.
    const menu = layout.buttons.find((b) => b.text === 'Menu');
    if (menu) {
      await page.mouse.click(menu.center.x, menu.center.y);
      await page.waitForTimeout(250);
      layout = await ui(page);
      await shot('menu');
      checkContract(layout, vp, `${name} menu`);
      const close = layout.buttons.filter((b) => b.text === 'Close').pop();
      if (close) await page.mouse.click(close.center.x, close.center.y);
      await page.waitForTimeout(200);
    }

    // The full card from the summary.
    layout = await ui(page);
    const summary = (layout as any).summary;
    if (summary && summary.x >= 0) {
      await page.mouse.click(summary.x, summary.y);
      await page.waitForTimeout(300);
      await shot('card');
      checkContract(await ui(page), vp, `${name} card`);
    }
    expect(errors, 'no script errors').toEqual([]);
  });
}
