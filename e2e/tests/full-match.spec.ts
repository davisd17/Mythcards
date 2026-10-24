import { test, expect } from '@playwright/test';
import { boot, playMatch } from './mythcards';

// HLD 13 step 15: a full match driven only through window.mythcards_dispatch_action,
// played to a win by a simple greedy bot, checking board invariants every turn.
// The loop runs inside the page (one evaluate) because it makes thousands of calls.

for (const seed of [42, 7, 2026]) {
  test(`greedy bots play a full match to a win (seed ${seed})`, async ({ page }) => {
    await boot(page, seed);
    const summary = await page.evaluate(playMatch, { maxTurns: 400 });
    console.log(`seed ${seed}:`, JSON.stringify(summary));
    expect(summary.violations).toEqual([]);
    expect(summary.phase, `still going after ${summary.turns} turns`).toBe('ended');
    expect(['hero_capture', 'army_defeat', 'ember_delivery']).toContain(summary.winCondition);
    expect(summary.actions).toBeGreaterThan(0);
  });
}
