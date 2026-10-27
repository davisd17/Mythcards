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
  if (text === 'Auto-place the rest') {
    const viewport = page.viewportSize()!;
    await page.mouse.move(viewport.width - 40, viewport.height - 50);
    await page.mouse.wheel(0, -2000);
    await page.waitForTimeout(150);
  }
  let layout = await ui(page);
  let b = layout.buttons.find((x) => x.text === text && !x.disabled);
  expect(b, `button "${text}" among ${layout.buttons.map((x) => x.text).join(' | ')}`).toBeTruthy();
  const viewport = page.viewportSize()!;
  for (let i = 0; i < 12 && b!.center.y > viewport.height - 20; i++) {
    await page.mouse.move(Math.min(b!.center.x, viewport.width - 20), viewport.height - 40);
    await page.mouse.wheel(0, 100);
    await page.waitForTimeout(100);
    layout = await ui(page);
    b = layout.buttons.find((x) => x.text === text && !x.disabled);
  }
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
  await page.screenshot({ path: 'test-results/screen-0-new-match.png' });
  // A fixed seed: the same cards and coin flip every run (Player 2 goes first).
  await page.evaluate((seed) => (window as any).mythcards_seed_next(seed), Number(process.env.HOTSEAT_SEED ?? 2));
  await clickButton(page, 'Hotseat: play both sides');
  expect((await ui(page)).setup).toBe(true);
  await page.screenshot({ path: 'test-results/screen-1-setup.png' });

  // Place the Hero by hand, the rest automatically, for both players.
  await clickButton(page, 'Dr. Mikhail Orlov');
  await clickTile(page, 3, 0);
  await clickButton(page, 'Auto-place the rest');
  await clickButton(page, 'Done placing');
  await clickButton(page, 'Auto-place the rest');
  await clickButton(page, 'Done placing');
  let s = await state(page);
  expect(s.phase).toBe('in_progress');
  expect(character(s, 'p1_r-mikhail-orlov').position).toEqual({ x: 3, y: 0 });
  await page.screenshot({ path: 'test-results/screen-2-card-drawn.png' });

  await answerChoices(page);
  s = await state(page);
  expect(s.pending_choice?.pick ?? null).toBeFalsy();
  // A coin flip picks who goes first (BR-018A). If Player 2 won it, pass that turn so the
  // script below starts on Player 1's turn (then a full 4 AP, not the 2-AP first turn).
  expect(s.active_player_id).toBe(s.first_player_id);
  const p1First = s.first_player_id === 'p1';
  if (!p1First) {
    await clickButton(page, 'End turn');
    await answerChoices(page);
    s = await state(page);
    expect(s.active_player_id).toBe('p1');
  }

  // Select a back-row character with a clear path and move it straight up 2 tiles. (A
  // drawn card can send one off the board or drop an object in the way, and with the coin
  // flip two cards may come out first.)
  const blocked = (x: number, y: number) =>
    s.players.p1.characters.concat(s.players.p2.characters).some((c: any) => c.position.x === x && c.position.y === y)
    || s.objects.some((o: any) => o.position.x === x && o.position.y === y);
  const mover = ['p1_r-reactor-worker', 'p1_r-yuri-volkov', 'p1_r-elena-morozova', 'p1_r-zoya-miranova']
    .map((id) => character(s, id))
    .find((c: any) => c.position.y === 0 && !blocked(c.position.x, 1) && !blocked(c.position.x, 2))!;
  expect(mover, 'a character with a clear path').toBeTruthy();
  const gymnast = mover;
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
  expect(character(s, mover.instance_id).position).toEqual({ x: gymnast.position.x, y: gymnast.position.y + 2 });
  expect(s.players.p1.pool_ap_remaining).toBe(p1First ? 1 : 3);

  await clickButton(page, 'End turn');
  s = await state(page);
  expect(s.active_player_id).toBe('p2');
  await page.screenshot({ path: 'test-results/screen-4-p2-turn.png' });

  // Player 2 uses an ability by clicks: Meret-Anu gives Iset-Nara a Memory marker.
  await answerChoices(page);
  s = await state(page);
  const queen = character(s, 'p2_a-flood-survivor-meret-anu');
  const architect = character(s, 'p2_a-flood-survivor-iset-nara');
  await clickTile(page, queen.position.x, queen.position.y);
  await expect(page.getByRole('button', { name: /^Outfit:/ })).toHaveCount(0);
  await page.screenshot({ path: 'test-results/screen-5-full-roster.png' });
  await clickButton(page, 'Memory Discipline');
  expect((await ui(page)).prompt).toContain('which ally gains Memory?');
  await page.screenshot({ path: 'test-results/screen-6-ability-prompt.png' });
  await clickTile(page, architect.position.x, architect.position.y);
  s = await state(page);
  expect(character(s, 'p2_a-flood-survivor-iset-nara').status_effects.map((e: any) => e.type)).toContain('memory');
  for (const viewport of [{ width: 360, height: 640 }, { width: 1280, height: 720 }]) {
    await page.setViewportSize(viewport);
    await page.waitForTimeout(300);
    await page.screenshot({ path: `test-results/readability-${viewport.width}.png` });
    const layout = await ui(page);
    for (const tile of Object.values(layout.tiles)) {
      expect(tile.x).toBeGreaterThanOrEqual(0);
      expect(tile.x).toBeLessThan(viewport.width);
      expect(tile.y).toBeGreaterThanOrEqual(0);
      expect(tile.y).toBeLessThan(viewport.height);
    }
  }
});

test('play Closed City against the AI with clicks', async ({ page }) => {
  await page.goto('/');
  await page.waitForFunction(() => (window as any).mythcards_ready === true, null, { timeout: 90_000 });
  await page.waitForTimeout(500);
  // A fixed seed: the same cards and coin flip every run (the AI goes first).
  await page.evaluate((seed) => (window as any).mythcards_seed_next(seed), Number(process.env.AI_SEED ?? 2));
  await clickButton(page, 'Play Closed City vs the AI');
  await clickButton(page, 'Auto-place the rest');
  await clickButton(page, 'Done placing');
  let s = await state(page);
  expect(s.phase).toBe('in_progress');
  expect(s.players.p2.characters.every((c: any) => c.position.y === 6)).toBe(true);   // the AI deployed
  // The AI plays its turn on a timer, one visible step at a time, then hands back.
  const handBack = (turn: number) => page.waitForFunction((t) => {
    const st = JSON.parse((window as any).mythcards_get_state());
    return st.active_player_id === 'p1' && st.turn_number >= t;
  }, turn, { timeout: 60_000 });
  // A coin flip picks who goes first (BR-018A): if the AI won it, it plays turn 1 first.
  const p1First = s.first_player_id === 'p1';
  if (!p1First) {
    await handBack(2);
    await page.waitForTimeout(500);   // the card we draw pops up just after the hand-back
    while ((await ui(page)).popup) await clickButton(page, 'Continue');
  }
  await answerChoices(page);
  // The AI's turn can box our Hero in; the warning pops up at once (playtest 2026-10-26).
  const trapped = (await ui(page)).buttons.some((b) => b.text === 'Keep playing');
  if (trapped) await clickButton(page, 'Keep playing');
  await clickButton(page, 'End turn');
  if (trapped) {
    // Ending the turn now loses, and the game asks first.
    await clickButton(page, 'End turn and lose');
    expect((await state(page)).win_condition).toBe('hero_capture');
    return;
  }
  await handBack(p1First ? 3 : 4);
  await page.screenshot({ path: 'test-results/screen-7-after-ai-turn.png' });
  while ((await ui(page)).popup) await clickButton(page, 'Continue');   // cards the AI drew, then ours
  await clickButton(page, 'Log');
  await page.screenshot({ path: 'test-results/screen-8-log.png' });
  s = await state(page);
  expect(s.active_player_id).toBe('p1');
});
