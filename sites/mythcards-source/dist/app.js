const gallery = document.querySelector('#gallery');
const dialog = document.querySelector('#card-dialog');
const privacy = document.querySelector('#privacy-dialog');
let cards = [];
let selected = 0;
let showingBack = false;
let returnFocus;
const get = (id) => document.getElementById(id);
get('year').textContent = new Date().getFullYear();

function updatePreview() {
  const card = cards[selected];
  get('dialog-image').src = showingBack ? 'assets/card-back.webp' : card.image;
  get('dialog-image').alt = showingBack ? 'Dreams of the North tarot card back' : `${card.title}: ${card.name}`;
  get('dialog-title').textContent = card.title;
  get('dialog-area').textContent = `${card.number} / ${card.area}`;
  get('dialog-name').textContent = card.name;
  get('dialog-keywords').textContent = card.keywords.join(' / ');
  get('dialog-narrative').textContent = card.narrative;
  get('dialog-reading').textContent = card.reading;
  get('flip').textContent = showingBack ? 'Card front' : 'Card back';
  get('flip').setAttribute('aria-label', showingBack ? 'Show card front' : 'Show card back');
}
function move(delta) { selected = (selected + delta + cards.length) % cards.length; showingBack = false; updatePreview(); }
get('card-close').addEventListener('click', () => dialog.close());
get('previous').addEventListener('click', () => move(-1));
get('next').addEventListener('click', () => move(1));
get('flip').addEventListener('click', () => { showingBack = !showingBack; updatePreview(); });
dialog.addEventListener('close', () => returnFocus?.focus());
dialog.addEventListener('keydown', (event) => {
  if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') { event.preventDefault(); move(event.key === 'ArrowRight' ? 1 : -1); }
});
for (const modal of [dialog, privacy]) modal.addEventListener('click', (event) => {
  const bounds = modal.getBoundingClientRect();
  if (event.target === modal && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) modal.close();
});
get('privacy-open').addEventListener('click', () => privacy.showModal());
get('privacy-close').addEventListener('click', () => privacy.close());

const characterTabs = [...document.querySelectorAll('.character-tabs [role="tab"]')];
function selectCharacter(tab, focus = false) {
  for (const item of characterTabs) {
    const active = item === tab;
    item.setAttribute('aria-selected', String(active));
    item.tabIndex = active ? 0 : -1;
    get(item.getAttribute('aria-controls')).hidden = !active;
  }
  if (focus) tab.focus();
}
for (const [index, tab] of characterTabs.entries()) {
  tab.addEventListener('click', () => selectCharacter(tab));
  tab.addEventListener('keydown', event => {
    let next = index;
    if (event.key === 'ArrowRight') next = (index + 1) % characterTabs.length;
    else if (event.key === 'ArrowLeft') next = (index + characterTabs.length - 1) % characterTabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = characterTabs.length - 1;
    else return;
    event.preventDefault();
    selectCharacter(characterTabs[next], true);
  });
}

const profileDialog = get('profile-dialog');
let profileReturnFocus;
for (const link of document.querySelectorAll('.profile-art-open')) {
  link.addEventListener('click', event => {
    event.preventDefault();
    profileReturnFocus = link;
    const source = link.querySelector('img');
    get('profile-dialog-image').src = source.src;
    get('profile-dialog-image').alt = source.alt;
    get('profile-dialog-title').textContent = link.closest('.character-panel').querySelector('h4').textContent;
    profileDialog.showModal();
    get('profile-close').focus();
  });
}
get('profile-close').addEventListener('click', () => profileDialog.close());
profileDialog.addEventListener('close', () => profileReturnFocus?.focus());
profileDialog.addEventListener('click', event => {
  const bounds = profileDialog.getBoundingClientRect();
  if (event.target === profileDialog && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) profileDialog.close();
});

try {
  const response = await fetch('cards.json');
  if (!response.ok) throw new Error(`Cards: ${response.status}`);
  cards = await response.json();
  for (const [index, card] of cards.entries()) {
    const button = document.createElement('button');
    button.className = 'card-tile';
    button.setAttribute('aria-label', `View ${card.title}`);
    const imageWrap = document.createElement('div');
    imageWrap.className = 'card-image';
    const img = new Image(700, 1200);
    img.src = card.image;
    img.alt = `${card.title}, ${card.name}`;
    img.loading = 'lazy';
    imageWrap.append(img);
    const label = document.createElement('span');
    label.className = 'card-label';
    const title = document.createElement('span');
    title.textContent = card.title;
    const arrow = document.createElement('span');
    arrow.textContent = '\u2197';
    arrow.setAttribute('aria-hidden', 'true');
    label.append(title, arrow);
    const area = document.createElement('span');
    area.className = 'card-area';
    area.textContent = `${card.number} / ${card.area}`;
    button.append(imageWrap, label, area);
    button.addEventListener('click', () => {
      selected = index; showingBack = false; returnFocus = button;
      updatePreview(); dialog.showModal(); get('card-close').focus();
    });
    gallery.append(button);
  }
} catch {
  get('gallery-error').hidden = false;
} finally { gallery.setAttribute('aria-busy', 'false'); }
