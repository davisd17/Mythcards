import { test, expect, Page, Browser, chromium } from '@playwright/test';
import { spawn, ChildProcess } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { state, character } from './mythcards';

// Two players, two browsers, one online match (LLD-network-match.md 8.5). The relay server
// runs under `wrangler dev` with fresh storage; the test web build reads its address from
// ?server=. Each player has its own browser context, so each keeps its own saved seat, as
// two phones would. Every move is a real click; the other page only ever sees it through
// the server.

const SERVER_PORT = 8788;
const SERVER = `http://127.0.0.1:${SERVER_PORT}`;
const TURNS = 6;

type Ui = { buttons: { text: string; center: { x: number; y: number }; disabled: boolean }[];
  tiles: Record<string, { x: number; y: number }>; prompt: string; popup: boolean; setup: boolean;
  online: { code?: string; seat?: string; applied?: number; desynced?: boolean; outbox?: number };
  online_menu: boolean };

let wrangler: ChildProcess | null = null;
let storage = '';

test.beforeAll(async () => {
  test.setTimeout(120_000);
  storage = mkdtempSync(join(tmpdir(), 'mythcards-wrangler-'));
  wrangler = spawn('npx', ['wrangler', 'dev', '--ip', '127.0.0.1', '--port', String(SERVER_PORT), '--persist-to', storage],
    { cwd: join(__dirname, '..', '..', 'server'), shell: true, env: { ...process.env, WRANGLER_SEND_METRICS: 'false', CI: '1' } });
  let output = '';
  wrangler.stdout?.on('data', (d) => { output += d; });
  wrangler.stderr?.on('data', (d) => { output += d; });
  for (let i = 0; i < 120; i++) {
    try {
      const r = await fetch(`${SERVER}/rooms/NOROOM/log`);
      if (r.status === 401 || r.status === 404) return;
    } catch { /* not up yet */ }
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`wrangler dev did not start:\n${output}`);
});

test.afterAll(async () => {
  if (wrangler?.pid) {
    // npx under a shell leaves workerd running unless the whole tree goes.
    if (process.platform === 'win32') spawn('taskkill', ['/pid', String(wrangler.pid), '/T', '/F']);
    else wrangler.kill('SIGTERM');
  }
  await new Promise((r) => setTimeout(r, 1000));
  try { rmSync(storage, { recursive: true, force: true }); } catch { /* workerd may still hold a file */ }
});

async function ui(page: Page): Promise<Ui> {
  return page.evaluate(() => JSON.parse((window as any).mythcards_ui()));
}

async function open(browser: Browser, query: string, baseURL: string): Promise<Page> {
  const context = await browser.newContext({ viewport: { width: 405, height: 720 }, baseURL });
  const page = await context.newPage();
  page.on('console', (m) => { if (m.type() === 'error') console.log(`[${query ? 'B' : 'A'}] ${m.text()}`); });
  const started = Date.now();
  await page.goto(`/?server=${encodeURIComponent(SERVER)}${query}`);
  await page.waitForFunction(() => (window as any).mythcards_ready === true, null, { timeout: 240_000 });
  console.log(`[${query ? 'B' : 'A'}] ready in ${Math.round((Date.now() - started) / 1000)} s`);
  await page.waitForTimeout(500);
  return page;
}

async function clickButton(page: Page, text: string): Promise<void> {
  if (text === 'Auto-place the rest') {
    const viewport = page.viewportSize()!;
    await page.mouse.move(viewport.width - 40, viewport.height - 50);
    await page.mouse.wheel(0, -2000);
    await page.waitForTimeout(150);
  }
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

async function until(page: Page, what: string, check: (s: any, u: Ui) => boolean, timeout = 30_000): Promise<void> {
  const end = Date.now() + timeout;
  let s: any, u: Ui | undefined;
  while (Date.now() < end) {
    s = await state(page);
    u = await ui(page);
    if (check(s, u)) return;
    await page.waitForTimeout(250);
  }
  throw new Error(`timed out waiting for ${what}; prompt: ${u?.prompt}; online: ${JSON.stringify(u?.online)}`);
}

// Closes card popups, then answers a pending choice that belongs to this page's seat with
// its first option, by clicking. Returns false if the choice belongs to the other seat.
async function answerChoices(page: Page, seat: string): Promise<boolean> {
  for (let i = 0; i < 8; i++) {
    if ((await ui(page)).popup) { await clickButton(page, 'Continue'); continue; }
    const s = await state(page);
    const spec = s.pending_choice;
    if (!spec || !spec.pick) return true;
    if ((s.decision_player_id ?? s.active_player_id) !== seat) return false;
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
  return true;
}

// One move forward by clicks: the first of this seat's characters that can step toward the
// other side. Returns the moved character's id and where it went, or null.
async function stepForward(page: Page, seat: string): Promise<{ id: string; to: any } | null> {
  const dir = seat === 'p1' ? 1 : -1;
  const before = await state(page);
  for (const c of before.players[seat].characters) {
    if (c.defeated || !c.position) continue;
    const to = { x: c.position.x, y: c.position.y + dir };
    if (to.y < 0 || to.y > 6) continue;
    await clickTile(page, c.position.x, c.position.y);
    await clickTile(page, to.x, to.y);
    const after = await state(page);
    const moved = character(after, c.instance_id);
    if (moved && moved.position.x === to.x && moved.position.y === to.y) return { id: c.instance_id, to };
    // Not a legal step: tap the piece again to drop the selection, then try the next.
    if (after.players[seat].pool_ap_remaining === before.players[seat].pool_ap_remaining) {
      await clickTile(page, c.position.x, c.position.y);
    }
  }
  return null;
}

test('two players play an online match through the relay server', async ({ browser, baseURL, launchOptions }) => {
  test.setTimeout(420_000);
  // Each player gets a browser process of its own: two Godot web builds in one process
  // crash its renderer, and two phones wouldn't share one either.
  const second = await chromium.launch(launchOptions);
  try {
    await play(browser, second, baseURL!);
  } finally {
    await second.close();
  }
});

async function play(first: Browser, second: Browser, baseURL: string): Promise<void> {

  // A creates as Closed City and gets the code.
  const a = await open(first, '', baseURL);
  await clickButton(a, 'Play a friend online');
  await clickButton(a, 'Create as Closed City');
  await until(a, 'the room code', (_s, u) => !!u.online.code);
  const code = (await ui(a)).online.code!;
  expect(code).toMatch(/^[A-HJKMNP-Z]{6}$/);
  await a.screenshot({ path: 'test-results/online-0-created.png' });
  await clickButton(a, 'Continue to deployment');
  expect((await ui(a)).setup).toBe(true);

  // B follows the invite link: the code is filled in, B taps Join.
  const b = await open(second, `&room=${code}`, baseURL);
  expect((await ui(b)).online_menu).toBe(true);
  await clickButton(b, 'Join');
  await until(b, 'B in setup', (_s, u) => u.online.seat === 'p2' && u.setup && !u.online_menu);

  // Both deploy; neither sees the other's formation until both are in.
  await clickButton(a, 'Auto-place the rest');
  await clickButton(a, 'Done placing');
  await until(a, 'A waiting', (_s, u) => u.prompt.includes('Waiting for your friend'));
  await clickButton(b, 'Auto-place the rest');
  await clickButton(b, 'Done placing');
  for (const p of [a, b]) await until(p, 'the match to start', (s, u) => s.phase === 'in_progress' && !u.setup);
  await b.screenshot({ path: 'test-results/online-1-started.png' });

  const pages: Record<string, Page> = { p1: a, p2: b };
  let lastMove: { id: string; to: any } | null = null;
  for (let turn = 0; turn < TURNS; turn++) {
    const seat = turn % 2 === 0 ? 'p1' : 'p2';
    const other = seat === 'p1' ? 'p2' : 'p1';
    const me = pages[seat];
    await until(me, `${seat}'s turn ${turn + 1}`, (s) => s.active_player_id === seat, 45_000);
    // A drawn card's choice can belong to either seat; each answers its own.
    for (let i = 0; i < 4 && !(await answerChoices(me, seat)); i++) {
      await until(pages[other], `${other} to see its choice`, (s) => !!s.pending_choice?.pick, 45_000);
      await answerChoices(pages[other], other);
      await until(me, `${seat} to get the answer`, (s) => !s.pending_choice?.pick, 45_000);
    }
    const moved = await stepForward(me, seat);
    if (moved) lastMove = moved;
    await answerChoices(me, seat);
    await clickButton(me, 'End turn');
    await until(me, 'the end of turn to send', (_s, u) => u.online.outbox === 0);
  }
  expect(lastMove, 'at least one move was made').not.toBeNull();

  // Both boards agree, and B shows A's or B's last move as it happened on the mover's page.
  const aUi = await ui(a);
  await until(b, 'B to catch up', (_s, u) => u.online.applied === aUi.online.applied, 45_000);
  const sa = await state(a);
  const sb = await state(b);
  expect(sb).toEqual(sa);
  expect(character(sb, lastMove!.id).position).toEqual(lastMove!.to);
  expect((await ui(a)).online.desynced).toBe(false);
  expect((await ui(b)).online.desynced).toBe(false);
  await b.screenshot({ path: 'test-results/online-2-after-six-turns.png' });

  // B reloads: the saved seat reopens the match from the log, in the same state.
  await b.waitForTimeout(2000);   // user:// reaches IndexedDB on Godot's periodic sync
  await b.goto(`/?server=${encodeURIComponent(SERVER)}&room=${code}`);
  await b.waitForFunction(() => (window as any).mythcards_ready === true, null, { timeout: 90_000 });
  await until(b, 'B to reopen the match', (s, u) => u.online.code === code && s.phase === 'in_progress' && !u.online_menu, 45_000);
  expect(await state(b)).toEqual(sa);
  await b.screenshot({ path: 'test-results/online-3-reloaded.png' });
}
