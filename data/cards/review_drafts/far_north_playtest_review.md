# Far North Playtest Review

## Status

Saved from the designer's card-by-card review through 2026-10-31. These are design
records, not a playable Godot team yet. Keep the existing matchup, original
prototype cards, character handlers, and shared deck unchanged until review is
finished and implementation is requested.

## Team Identity

Misfits, circus trust, inherited rites, northern survival, and dramatic bursts of
coordinated activity. Unexpected roles matter: Buran is a fighter-first Mount;
Oleg's strength depends on staying healthy; Nadia restores the troupe's momentum.
Use familiar AP, movement, attacks, healing, and Shields rather than a new resource.

The circus is one thread, not the entire area: the village, meteor, wilderness,
and the connection to the Winter Front remain important.

## Seven Reviewed Characters

Full stats and level text: `far_north_characters.json`.

| Role | Card | Story Identity |
| --- | --- | --- |
| Common | Gymnast | Mila Vetrova |
| Mount | Buran, White Siberian Tiger | Fighter and guardian of old crossings |
| Warrior | Oleg Baranov, Iron Strongman | The village's strongman and living wall |
| Hero | Pavel Sokolov | Displaced survivor carrying the Sky-Hide Mirror |
| Leader | Vera Kargina, Meteor Spear | Village leader and boundary keeper |
| Specialist | Dmitri Voronov, Knife Thrower | Mobile attacker and circus performer |
| Mystic | Nadia Belaya | Healer who finds Pavel in the snow |

Aksinya Morozova remains an alternate Mystic. Belorog remains an alternate Mount.
Village Woodcutter (Tomas Yurin) remains an alternate Common.

## Relic Review

Full effects: `far_north_relics.json`.

1. Circus Convergence Rings: reviewed. The revised team movement connection
   supersedes the earlier Common/Specialist post-attack movement proposal.
2. Sky-Hide Mirror: reviewed.
3. Meteor-Glass Spear: reviewed.
4. Buran's Boundary Harness: latest proposal; saved but awaits explicit card review.
5. Fifth playtest relic: not selected or reviewed yet.

The rings are one of the story's most important relics: inherited through
generations and connecting the Winter Front rite with the Deep North Circus.
Their playtest effect grants one shared extra tile per turn, without extra AP or
attacks, and cannot trigger itself recursively.

## Events and Deck Size

Proposed playtest format follows the existing teams: five unique events, two
copies of each, plus five unique relics (15 cards per side, 30 shared cards).
Far North events have not yet been mechanically drafted or reviewed in this pass.
`far_north_story_relics.json` retains the existing narrative candidates; do not
mistake those story concepts for approved playable effects.

## Implementation Clarifications Still Needed

- Define when Pavel checks adjacency for his Level 1 following movement.
- Confirm Pounce's next-attack bonus expiration, stacking, and movement targeting.
- Specify how optional movement/attack chains are offered without recursion.
- Keep character-AP refresh distinct from shared pool AP; no reviewed character
  AP refresh silently restores the pool.
- Settle ordering when Oleg's push and Meteor-Glass Spear trigger together.
- Finish the fifth relic and all five events before adding the fixed deck lineup.

No new decisions on these details are implied by saving this review.
