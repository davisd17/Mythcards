import { test, expect } from '@playwright/test';
import { boot, playMatch } from './mythcards';

// docs/art-specs/ember-claim/SPEC.md 3: a real defeat in the web build plays the claimer's
// claim (wisp, poses, line), and the claim clears by about 1.9 s after impact.
test('a defeat plays the claimer\'s Ember claim', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', message => {
    if (message.type() === 'error' || /SCRIPT ERROR|ERROR:/.test(message.text())) errors.push(message.text());
  });
  page.on('pageerror', error => errors.push(String(error)));
  await boot(page, 42);
  const summary = await page.evaluate(playMatch, { maxTurns: 200, stopAtClaim: true });
  expect(summary.claimer, `no Ember claimed in ${summary.turns} turns`).not.toBe('');
  const ui = async () => page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
  expect((await ui()).claims).toEqual([summary.claimer]);
  const started = Date.now();
  for (let i = 0; i < 4; i++) {   // a drawn-card popup would hide the board
    const layout = await ui();
    if (!layout.popup) break;
    const button = layout.buttons.find((b: any) => b.text === 'Continue' || b.text === 'Close');
    if (!button) break;
    await page.mouse.click(button.center.x, button.center.y);
  }
  // impact (up to ~0.33 s) + landing 0.5 s + into the hold
  await page.waitForTimeout(Math.max(0, 950 - (Date.now() - started)));
  await page.screenshot({ path: 'test-results/ember-claim-hold.png' });
  const board = (await ui()).board;
  await page.screenshot({ path: 'test-results/ember-claim-hold-board.png',
    clip: { x: board.x, y: board.y, width: board.w, height: board.h } });
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'test-results/ember-claim-line.png' });
  await page.waitForTimeout(1200);
  expect((await ui()).claims).toEqual([]);
  expect(errors).toEqual([]);
});
