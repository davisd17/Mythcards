# Tarot Area Deck Framework

Review status: draft for review

Purpose: each major story area or sub-area can eventually become a complete physical tarot deck. The game cards may still function as characters, relics, and events, but the art direction should also map each piece to a tarot archetype so a collectible deck can be printed, sold, and used as a tarot deck.

## Core Rule

Each area tarot deck should contain exactly one representative artwork for each classic tarot archetype:

- 22 Major Arcana
- 56 Minor Arcana
- 4 suits with Ace through 10, Page, Knight, Queen, and King

No area deck should duplicate a tarot archetype unless one version is explicitly marked as an alternate. No tarot archetype should remain unassigned in a finished physical deck.

## Art Direction Rule

Every finished card illustration should answer two questions:

- What is this card in MythCards?
- What tarot archetype is it secretly or openly embodying?

The artwork does not need to mimic public-domain tarot compositions exactly. It should preserve the archetypal meaning while translating the image into the area's world.

Example:
- The Tower in Closed City should not be a medieval tower. It can be the reactor opening inward.
- The Chariot in Flood Survivors can be Ahesu carrying riders through a living stone-current route.
- The Hermit can be a memory-keeper, remote viewer, sealed archivist, or lone survivor depending on area.

## Suggested Suit Translation

These suit meanings should stay consistent across all area decks, but each area can visually rename or style them.

| Tarot Suit | Core Meaning | MythCards Translation |
| --- | --- | --- |
| Wands | will, action, fire, ambition, impulse | command, movement, desire, active force |
| Cups | emotion, memory, love, grief, spirit | relationships, dreams, water, intimacy, psychic feeling |
| Swords | conflict, truth, thought, violence, decision | forbidden knowledge, containment, judgment, tactical conflict |
| Pentacles | matter, body, craft, wealth, relics, place | relics, stonework, machinery, survival systems, physical resources |

Area-specific suit styling:
- Closed City Wands: signal rods, warning lights, authority badges, reactor flame.
- Closed City Cups: dream monitors, sleep-lab vessels, signal water, intimate confessions.
- Closed City Swords: containment blades, redacted files, command orders, diagnostic truth.
- Closed City Pentacles: reactor parts, keys, helmets, notebooks, industrial relics.
- Flood Survivor Wands: ley-staffs, living causeways, royal command, serpent routes.
- Flood Survivor Cups: black water, memory bowls, burial rites, drowned love.
- Flood Survivor Swords: tomb oaths, erased names, judgment, guarded truth.
- Flood Survivor Pentacles: basalt stones, tablets, sarcophagi, vault instruments, pearls.

## Tracking Files

Structured mapping draft:

`data/cards/review_drafts/tarot_area_mapping.json`

Use that file to track:
- canonical tarot archetype names
- which MythCards card currently maps to each archetype
- whether the mapping is proposed, approved, alternate, or needs new art
- whether existing artwork should be audited or regenerated

## Existing Art Audit Rules

When reviewing existing card art, classify each asset as:

- `matches_tarot`: the current image already expresses the mapped tarot archetype.
- `minor_adjustment`: the image mostly works, but future variants should strengthen tarot symbols.
- `needs_regeneration`: the image is good as game art but does not carry the tarot archetype clearly enough.
- `unmapped`: the card has no tarot archetype yet.

Useful audit questions:
- Is the archetype readable without text?
- Does the image still belong unmistakably to its area?
- Does the character/event/relic still work as a MythCards asset?
- Is the tarot symbolism integrated into the world rather than pasted on?
- Does the deck avoid duplicate archetypes unless explicitly marked as alternates?

## Current Direction

Closed City should feel like a Soviet occult-science tarot: reactor rooms, signal arrays, dream monitors, military containment, hidden patronage, forbidden intimacy, redacted evidence, and the first physical cards.

Flood Survivors should feel like a drowned Atlantean/Egyptian mystery tarot: black water, ley stones, sealed vaults, memory rites, the Emerald Tablet, the Black Sarcophagus, hidden bloodlines, angelic judgment, and forbidden survivor truth.
