import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, access } from 'node:fs/promises';
const html = await readFile('dist/index.html', 'utf8');
const app = await readFile('dist/app.js', 'utf8');
const readme = await readFile('README.md', 'utf8');
const guide = await readFile('STYLE_GUIDE.md', 'utf8');
const tokens = await readFile('dist/mythcards-tokens.css', 'utf8');
const styles = await readFile('dist/styles.css', 'utf8');
const cards = JSON.parse(await readFile('dist/cards.json', 'utf8'));
test('release is coming soon with no checkout or signup form', () => {
  assert.match(html, /Physical deck coming soon/);
  assert.doesNotMatch(html, /<form|stripe|paypal|Buy now|Add to cart/i);
});
test('every gallery card is unique and has public story content', async () => {
  assert.equal(cards.length, 8);
  assert.equal(new Set(cards.map(card => card.title)).size, cards.length);
  for (const card of cards) {
    assert.ok(card.narrative && card.reading && card.keywords.length);
    assert.equal(card.hidden_threads, undefined);
    await access('dist/' + card.image);
  }
});
test('all referenced local assets exist', async () => {
  const refs = [...html.matchAll(/(?:src|href)="([^"#]+)"/g)].map(match => match[1]).filter(ref => !/^https?:/.test(ref));
  for (const ref of refs) await access('dist/' + ref);
});
test('gallery controls and accessible dialogs are present', () => {
  assert.match(html, /aria-labelledby="dialog-title"/);
  for (const id of ['previous', 'next', 'flip', 'card-close', 'privacy-close']) assert.ok(html.includes(`id="${id}"`));
});
test('the game and lore lead, with an upfront supporting tarot announcement', () => {
  assert.match(html, /<h1 id="hero-title">MythCards\.<\/h1>/);
  assert.ok(html.indexOf('id="game"') < html.indexOf('id="world"'));
  assert.ok(html.indexOf('id="world"') < html.indexOf('id="deck"'));
  assert.ok(html.indexOf('class="deck-announcement"') < html.indexOf('id="game"'));
  assert.ok(html.indexOf('class="deck-announcement"') < html.indexOf('<header'));
  assert.match(html, /Our first release \/ Coming soon/);
  assert.equal([...html.matchAll(/class="deck-announcement"/g)].length, 1);
  assert.match(html, /Development prototype/);
  assert.match(html, /Dreams of the North/);
  assert.doesNotMatch(html, /Russian Tarot|<h3>Atlantean Tarot/);
});

test('approved deck title is consistent across marketing and accessible copy', () => {
  assert.match(html, /<h2 id="deck-title">Dreams of the North<\/h2>/);
  assert.match(html, /aria-label="Dreams of the North tarot card previews"/);
  assert.match(html, /<meta name="description"[^>]+Dreams of the North/);
  assert.match(html, /<meta property="og:description"[^>]+Dreams of the North/);
  assert.match(html, /A MythCards Tarot/);
  assert.match(app, /Dreams of the North tarot card back/);
  assert.match(readme, /\*\*Dreams of the North\*\*/);
  assert.doesNotMatch([html, app, readme].join('\n'), /The Unwaking/i);
});

test('shared MythCards foundations are linked and consumed without palette drift', () => {
  assert.ok(html.indexOf('href="mythcards-tokens.css"') < html.indexOf('href="styles.css"'));
  for (const [name, value] of Object.entries({ink:'#171b19', paper:'#eceee9', muted:'#adb5ad', line:'#424b44', mint:'#b9d2be', oxblood:'#873b43'})) {
    assert.ok(tokens.includes(`--mc-${name}: ${value};`), name);
    assert.ok(styles.includes(`var(--mc-${name})`), name);
  }
  assert.match(tokens, /--mc-control-height: 48px/);
  assert.match(tokens, /--mc-icon-size: 44px/);
  assert.match(guide, /Dreams of the North/);
  assert.match(guide, /Controls with the same role keep the same height/);
  assert.match(readme, /STYLE_GUIDE\.md/);
});

test('lore implies its mysteries instead of listing explicit categories', () => {
  assert.match(html, /Two eras\. Six sub-areas\./);
  assert.match(html, /Infinite ways to survive the impossible\./);
  assert.doesNotMatch(html, /Two ways to survive the impossible/);
  assert.match(html, /Old loyalties meet unfamiliar worlds/);
  assert.doesNotMatch(html, /esoteric traditions|occult mysteries|true mythology/i);
});

test('gameplay uses the uploaded capture without the enlargement crop', () => {
  assert.match(html, /class="gameplay-board-detail"/);
  assert.match(html, /Player-captured MythCards development gameplay/);
  assert.match(html, /A glimpse of the game \/ Closed City/);
  assert.match(html, /src="assets\/gameplay.webp"/);
  assert.doesNotMatch(html, /srcset="assets\/gameplay-mobile.webp"/);
  assert.match(styles, /\.gameplay-board-detail img\{[^}]+width:100%/);
  assert.doesNotMatch(styles, /268\.9076%|84\.4538%|23\.9496%/);
});

test('game introduction stays high level without rules or victory specifics', () => {
  const game = html.slice(html.indexOf('id="game"'), html.indexOf('id="world"'));
  assert.match(game, /Unlikely allies/);
  assert.doesNotMatch(game, /7 &times; 7|Seven characters|Seven roles|Level up|Hunt the opposing Hero|defeat their army|distinct abilities/);
});

test('three canonical profiles have accessible switch and enlargement controls', async () => {
  assert.equal([...html.matchAll(/role="tab" /g)].length, 3);
  assert.equal([...html.matchAll(/role="tabpanel" /g)].length, 3);
  assert.match(html, /role="tablist" aria-label="Featured characters"/);
  for (const key of ['nekh', 'buran', 'zoya']) {
    assert.match(html, new RegExp(`aria-controls="profile-${key}"`));
    await access(`dist/assets/profile-${key}.webp`);
  }
  assert.match(html, /id="profile-dialog" aria-labelledby="profile-dialog-title"/);
  for (const key of ['ArrowRight', 'ArrowLeft', 'Home', 'End']) assert.ok(app.includes(`'${key}'`));
  assert.match(app, /profileReturnFocus\?\.focus/);
  assert.match(styles, /\.character-panel\[hidden\]\{display:none\}/);
});
