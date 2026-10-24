import { createRequire } from 'node:module';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
const require = createRequire(import.meta.url);
const sharp = require(process.env.SHARP_MODULE || 'C:/Users/Drew/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const repo = path.resolve('../..');
const fronts = process.argv[2] || 'D:/MythCards-working-images/card-fronts/russian-tarot-deck';
await mkdir('dist/assets', { recursive: true });
const selections = ['00-the-fool', '01-the-magician', '02-the-high-priestess', '03-the-empress', '07-the-chariot', '09-the-hermit', '17-the-star', '18-the-moon'];
for (const name of selections) {
  await sharp(path.join(fronts, name + '.png')).resize({ width: 700 }).webp({ quality: 86 }).toFile(`dist/assets/${name}.webp`);
}
const images = {
  'gameplay': 'e2e/test-results/readability-1280.png',
  'gameplay-mobile': 'e2e/test-results/screen-3-selected.png',
  'aurora': 'assets/events/far-north-aurora-opens-like-a-door-ace-of-wands-event-art.png',
  'closed-city': 'assets/events/closed-city-incident-the-tower-event-art.png',
  'atlantis': 'assets/characters/queen-meret-anu-keeper-of-the-buried-tide-character-card-art-pristine.png',
  'card-back': 'assets/card-backs/mythcards-russian-tarot-card-back-approved.png'
};
for (const [name, file] of Object.entries(images)) {
  await sharp(path.join(repo, file)).resize({ width: ['aurora', 'gameplay'].includes(name) ? 1600 : 850, withoutEnlargement: true }).webp({ quality: 85 }).toFile(`dist/assets/${name}.webp`);
}
const guidebook = JSON.parse(await readFile(path.join(repo, 'data/cards/review_drafts/russian_tarot_guidebook.json'), 'utf8'));
const numbers = [0, 1, 2, 3, 7, 9, 17, 18];
const cards = numbers.map((index, i) => {
  const entry = guidebook.entries[index];
  if (entry.review_status !== 'approved') throw new Error(`Unapproved guidebook entry: ${entry.tarot_name}`);
  return { title: entry.tarot_name, number: entry.tarot_number, name: entry.mythcards_name, area: entry.sub_area, keywords: entry.upright_keywords, narrative: entry.narrative, reading: entry.when_drawn, image: `assets/${selections[i]}.webp` };
});
await writeFile('dist/cards.json', JSON.stringify(cards, null, 2) + '\n');
console.log(`Prepared ${cards.length} card previews and ${Object.keys(images).length} editorial images.`);
