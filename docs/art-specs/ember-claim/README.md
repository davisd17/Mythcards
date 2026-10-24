# Ember Claim Production Queue

Status: all 14 default-outfit art packages produced and approved as of 2026-10-23. All 14 sound candidates are rendered and wired; listening review and visual/text integration remain pending. VERA-7's proposed more celebratory revision remains a separate follow-up. Thalassa's full Seraph transformation art is a separate review package under `docs/art-specs/form-change/`.

- [Contributor spec](SPEC.md): triggers, timing, files, and draft text.
- [Character briefs](CHARACTER_BRIEFS.md): Gather/Hold/Settle, receiving space,
  prop continuity, sound direction, and exclusions for every playable character.

Approved dialogue is sourced from `data/ember_lines.json` and preserved verbatim.
Art and sound require their own approvals. Make and review one character package
at a time; line approval does not imply audio or in-game approval.

| Order | Character ID | Signature beat | Brief | Art / Audio / Lines / In-game |
| --- | --- | --- | --- | --- |
| 1 | `r-reactor-worker` | Photo over heart | Drafted | Approved / Review candidate / Approved / Audio wired |
| 2 | `r-vera-7` | Sample secured | Drafted | Approved / Review candidate / Approved / Audio wired |
| 3 | `r-yuri-volkov` | Containment check | Drafted | Approved / Review candidate / Approved / Audio wired |
| 4 | `r-irina-karpova` | My opportunity | Drafted | Approved / Review candidate / Approved / Audio wired |
| 5 | `r-mikhail-orlov` | Perfectly calculated | Drafted | Approved / Review candidate / Approved / Audio wired |
| 6 | `r-elena-morozova` | Signal recognized | Drafted | Approved / Review candidate / Approved / Audio wired |
| 7 | `r-zoya-miranova` | Which of us? | Drafted | Approved / Review candidate / Approved / Audio wired |
| 8 | `a-flood-survivor-stone-line-laborer` | A way forward | Drafted | Approved / Review candidate / Approved / Audio wired |
| 9 | `a-flood-survivor-ahesu` | The deep keeps it | Drafted | Approved / Review candidate / Approved / Audio wired |
| 10 | `a-flood-survivor-naia` | Serve life | Drafted | Approved / Review candidate / Approved / Audio wired |
| 11 | `a-flood-survivor-meret-anu` | Because I choose | Drafted | Approved / Review candidate / Approved / Audio wired |
| 12 | `a-flood-survivor-sahu-ren` | A memory carried | Drafted | Approved / Review candidate / Approved / Audio wired |
| 13 | `a-flood-survivor-iset-nara` | Measured passage | Drafted | Approved / Review candidate / Approved / Audio wired |
| 14 | `a-flood-survivor-thalassa-nekh` | Feed us | Drafted | Approved / Review candidate / Approved / Audio wired |

## Package Gate

Each character needs three transparent runtime poses, master sources/prompts,
layered ORA, contact sheet, 120/360/120 ms review GIF, recorded receiving socket,
one compliant `claim.wav` plus source/licence notes, and two approved short lines.
See SPEC for the exact paths and audio format. Big claims reuse the same artwork.

Review art first, sound in context second, lines third. Mark in-game verification
only after normal/big claims are seen in exported web and Windows builds, sound
on/off, with no rule/input delays. Include mirrored placement, mounted ownership,
Level 3, hazards without an Ember, interruption, and the match-ending case.

Current code still emits `spirit_ember_picked_up(character_id)` without the gained
count. The SFX layer now plays per-character stings; normal/big claims share
one sound. Visual packages and line selection remain pending. See
[AUDIO_STATUS.md](AUDIO_STATUS.md) for the exact scope and review limits.

Recommended pilot: Reactor Worker, to establish prop-safe receiving sockets and
the three-pose workflow. Then VERA-7, to check nonhuman registration before the
rest. Default outfits only; do not start a 42-image batch before pilot review.
