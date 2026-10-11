import { test, expect, Page } from '@playwright/test';
import { boot, act, state, resolvePending, character } from './mythcards';

// Visual review screenshots (VISUAL_POLISH_PHASE_1.md, LLD-board-visual-phase1.md 8).
// Builds the same board state every run through the bridge, then selects a character
// by a real click: legal moves, an attack target, a Leak, a Stone, and the center.
// Set VISUAL_TAG=before|after to name the files; they land in test-results/visual/.

const VIEWPORTS = [
  { name: 'mobile-405x720', width: 405, height: 720 },
  { name: 'small-360x640', width: 360, height: 640 },
  { name: 'desktop-1280x720', width: 1280, height: 720 },
];
const TAG = process.env.VISUAL_TAG ?? 'after';

async function ui(page: Page): Promise<any> {
  return page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
}

async function closePopups(page: Page): Promise<void> {
  for (let i = 0; i < 6; i++) {
    const layout = await ui(page);
    if (!layout.popup) return;
    const b = layout.buttons.find((x: any) => x.text === 'Continue' || x.text === 'Close');
    await page.mouse.click(b.center.x, b.center.y);
    await page.waitForTimeout(120);
  }
}

for (const vp of VIEWPORTS) {
  test(`board staging screenshot (${vp.name})`, async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (m) => { if (m.type() === 'error' || /SCRIPT ERROR|ERROR:/.test(m.text())) errors.push(m.text()); });
    page.on('pageerror', (e) => errors.push(String(e)));
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await boot(page, 42);
    await resolvePending(page);
    // Player 1: a Leak in front of Orlov, the Reactor Worker steps up.
    expect((await act(page, 'ability', 'p1_r-mikhail-orlov', { ability_id: 'r-mikhail-orlov', target: { x: 3, y: 2 } })).success).toBe(true);
    expect((await act(page, 'move', 'p1_r-reactor-worker', { to: { x: 0, y: 2 } })).success).toBe(true);
    expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
    await resolvePending(page);
    // Player 2: a Stone, and Naia advances into Yuri's lane.
    expect((await act(page, 'ability', 'p2_a-flood-survivor-stone-line-laborer',
      { ability_id: 'a-flood-survivor-stone-line-laborer', target: { x: 0, y: 5 } })).success).toBe(true);
    expect((await act(page, 'move', 'p2_a-flood-survivor-naia', { to: { x: 2, y: 3 } })).success).toBe(true);
    expect((await act(page, 'end_turn', 'p2')).success).toBe(true);
    await resolvePending(page);
    expect((await act(page, 'move', 'p1_r-yuri-volkov', { to: { x: 2, y: 1 } })).success).toBe(true);
    await page.waitForTimeout(300);
    await closePopups(page);
    // Select Major Yuri Volkov with a real click: moves and an attack target on Naia.
    const s = await state(page);
    const yuri = character(s, 'p1_r-yuri-volkov');
    const karpova = character(s, 'p1_r-irina-karpova');
    const tile = (await ui(page)).tiles[`${karpova.position.x},${karpova.position.y}`];
    await page.mouse.click(tile.x, tile.y);
    await page.waitForTimeout(300);
    await page.screenshot({ path: `test-results/visual/${TAG}-${vp.name}-selected.png` });
    const yt = (await ui(page)).tiles[`${yuri.position.x},${yuri.position.y}`];
    await page.mouse.click(yt.x, yt.y);
    await page.waitForTimeout(300);
    await page.screenshot({ path: `test-results/visual/${TAG}-${vp.name}-attack.png` });
    // Phase 2 action feedback: pass both turns so Yuri has AP again, then attack Naia
    // (same signals as a click) and catch the hit mid-animation.
    for (const p of ['p1', 'p2']) {
      expect((await act(page, 'end_turn', p)).success).toBe(true);
      await resolvePending(page);
    }
    await page.waitForTimeout(300);
    await closePopups(page);
    const hit = await act(page, 'attack', 'p1_r-yuri-volkov', { target_id: 'p2_a-flood-survivor-naia' });
    expect(hit.success, JSON.stringify(hit)).toBe(true);
    await page.waitForTimeout(90);
    await page.screenshot({ path: `test-results/visual/${TAG}-${vp.name}-hit.png` });
    // Phase 3: the turn passes (banner and the drawn card's popup), then the card docks.
    await page.waitForTimeout(400);
    expect((await act(page, 'end_turn', 'p1')).success).toBe(true);
    await page.waitForTimeout(350);
    await page.screenshot({ path: `test-results/visual/${TAG}-${vp.name}-turn.png` });
    const cont = (await ui(page)).buttons.find((x: any) => x.text === 'Continue');
    if (cont) {
      await page.mouse.click(cont.center.x, cont.center.y);
      await page.waitForTimeout(200);
      await page.screenshot({ path: `test-results/visual/${TAG}-${vp.name}-dock.png` });
    }
    expect(errors, 'no missing resources or script errors').toEqual([]);
  });
}
