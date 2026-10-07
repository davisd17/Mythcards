import { test, expect, Page } from '@playwright/test';
import { state, character } from './mythcards';

// The game screen driven by real mouse clicks, the way a player taps: TestBridge's
// mythcards_ui() only reports where the buttons and tiles are; every action goes through
// the canvas. Screenshots land in test-results/ for a visual check.

type Ui = { buttons: { text: string; center: { x: number; y: number }; disabled: boolean }[];
  summary: { x: number; y: number };
  tiles: Record<string, { x: number; y: number }>; prompt: string; popup: boolean; setup: boolean };

async function ui(page: Page): Promise<Ui> {
  return page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
}

async function clickButton(page: Page, text: string): Promise<void> {
  const layout = await ui(page);
  const b = layout.buttons.find((x) => x.text === text && !x.disabled);
  expect(b, `button "${text}" among ${layout.buttons.map((x) => x.text).join(' | ')}`).toBeTruthy();
  await page.mouse.click(b!.center.x, b!.center.y);
  await page.waitForTimeout(150);
}

async function clickTile(page: Page, x: number, y: number): Promise<void> {
  const t = (await ui(page)).tiles[`${x},${y}`];
  await page.mouse.click(t.x, t.y);
  await page.waitForTimeout(150);
}

// Answers whatever the prompt bar asks with its first choice, by clicking.
async function answerChoices(page: Page): Promise<void> {
  for (let i = 0; i < 6; i++) {
    const layout = await ui(page);
    if (layout.popup) { await clickButton(page, 'Continue'); continue; }
    const s = await state(page);
    const spec = s.pending_choice;
    if (!spec || !spec.pick) return;
    if (spec.pick === 'option' || (spec.pick === 'character' && spec._picked)) {
      await clickButton(page, spec.options[0].label);
    } else if (spec.pick === 'tiles') {
      for (const t of spec.tiles.slice(0, spec.count)) await clickTile(page, t.x, t.y);
    } else if (spec.pick === 'character' || spec.pick === 'character_tile') {
      const c = character(s, spec.characters[0]);
      await clickTile(page, c.position.x, c.position.y);
      if (spec.pick === 'character' && spec.options?.length) await clickButton(page, spec.options[0].label);
      if (spec.pick === 'character_tile') {
        const to = spec.tiles_by_character[spec.characters[0]]?.[0];
        if (to) await clickTile(page, to.x, to.y);
      }
    }
  }
}

test('deploy, move, and end the turn with clicks only', async ({ page }) => {
  await page.goto('/');
  await page.waitForFunction(() => (window as any).mythcards_ready === true, null, { timeout: 90_000 });
  await page.waitForTimeout(500);
  expect((await ui(page)).setup).toBe(true);
  await page.screenshot({ path: 'test-results/screen-1-setup.png' });

  // Place the Hero by hand, the rest automatically, for both players.
  await clickButton(page, 'Bogatyr Champion');
  await clickTile(page, 3, 0);
  await clickButton(page, 'Auto-place the rest');
  await clickButton(page, 'Done placing');
  await clickButton(page, 'Auto-place the rest');
  await clickButton(page, 'Done placing');
  let s = await state(page);
  expect(s.phase).toBe('in_progress');
  expect(character(s, 'p1_r-hero').position).toEqual({ x: 3, y: 0 });
  await page.screenshot({ path: 'test-results/screen-2-card-drawn.png' });

  await answerChoices(page);
  s = await state(page);
  expect(s.pending_choice?.pick ?? null).toBeFalsy();

  // Select the Gymnast and move it straight up 2 tiles.
  const gymnast = character(s, 'p1_r-gymnast');
  await clickTile(page, gymnast.position.x, gymnast.position.y);
  await page.screenshot({ path: 'test-results/screen-3-selected.png' });

  // The strip under the board opens the full card in a scrollable overlay.
  const strip = (await ui(page)).summary;
  await page.mouse.click(strip.x, strip.y);
  await page.waitForTimeout(150);
  expect((await ui(page)).popup).toBe(true);
  await page.screenshot({ path: 'test-results/screen-3b-full-card.png' });
  await clickButton(page, 'Close');
  expect((await ui(page)).popup).toBe(false);
  await clickTile(page, gymnast.position.x, gymnast.position.y + 2);
  s = await state(page);
  expect(character(s, 'p1_r-gymnast').position).toEqual({ x: gymnast.position.x, y: gymnast.position.y + 2 });
  expect(s.players.p1.pool_ap_remaining).toBe(1);

  await clickButton(page, 'End turn');
  s = await state(page);
  expect(s.active_player_id).toBe('p2');
  await page.screenshot({ path: 'test-results/screen-4-p2-turn.png' });

  // Player 2 uses an ability by clicks: Astral Harmonic shields the Crystal Architect.
  await answerChoices(page);
  s = await state(page);
  const harmonic = character(s, 'p2_a-harmonic');
  const architect = character(s, 'p2_a-architect');
  await clickTile(page, harmonic.position.x, harmonic.position.y);
  await expect(page.getByRole('button', { name: /^Outfit:/ })).toHaveCount(0);
  await page.screenshot({ path: 'test-results/screen-5-full-roster.png' });
  await clickButton(page, 'Resonance Shield');
  expect((await ui(page)).prompt).toContain('Shield which ally?');
  await page.screenshot({ path: 'test-results/screen-6-ability-prompt.png' });
  await clickTile(page, architect.position.x, architect.position.y);
  s = await state(page);
  expect(character(s, 'p2_a-architect').status_effects.map((e: any) => e.type)).toContain('shield');
});
