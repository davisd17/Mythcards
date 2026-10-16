---
name: mythcards-guidebook
description: Draft and revise MythCards tarot guidebook entries that combine clear story information with practical tarot interpretation. Use for guidebook passages and their structured lore records.
---

# MythCards Guidebook

Work within the established concise format in `data/cards/review_drafts/tarot_guidebook_content_standard.md`, resolved from the MythCards repository root. Approved Russian entries are in `data/cards/review_drafts/russian_tarot_guidebook.json`.

## Story And Reader Value

- Give the reader meaningful story information: who is involved, what happens, why it happens, and what opportunity, consequence, or choice follows. Choose the details that matter rather than trying to answer every question.
- Assume the reader has not read the chat. Explain necessary connections between people, relics, places, and eras in plain language.
- Use atmosphere to support concrete information. A growl, mysterious response, or lyrical reference to an ancient rite is insufficient unless it clarifies the story.
- Preserve uncertainty about motives and hidden identities while making the observable event understandable. Do not hide basic causality behind vague mysteries.
- Weave relationships, attraction, grief, loyalty, and conflicting desires into existing narrative sections when established and relevant. Do not invent ties merely to fill a field.
- Keep legends inside the story world. Avoid introductory phrases such as "Inspired by" in reader-facing lore. Preserve cultural-source information separately in research or provenance records.

## Tarot Guidance

- Interpret the traditional tarot archetype through the subject, then connect it to an ordinary human decision or experience. Do more than explain why the artwork fits the mapping.
- Let the reader understand how to use the card: what to notice, reconsider, accept, or begin. Avoid requiring the reader to identify with supernatural circumstances.
- Write natural first-person affirmations people can comfortably say and relate to, such as "I trust that healing is possible" or "I have the courage to begin." Avoid grand declarations, lore terminology, and elaborate moral positions.
- End with one simple, usable When Drawn sentence. Keep established headings and the concise rhythm of approved entries.

## Continuity And Approval

- Verify mappings against the master tracker: `outputs/019f2e9a-7504-7ee0-9b75-0d4456667415/russian_tarot_deck_tracker.xlsx`, sheet `Russian tarot`. Older mapping JSON may be stale.
- Consult the subject's existing narrative before drafting. The Russian timeline is documented in `data/cards/review_drafts/russian_story_timeline.md`: Winter Front and meteor in 1942; Closed City and main Far North story in 1982.
- Radio Snow Speaks / Three of Wands is the Russian deck's only fourth-wall break. Elena addresses the person drawing it directly and ambiguously; preserve that exception without extending it to other cards.
- When reviewing one card at a time, save the approved entry before presenting the next. Treat the next preview as unapproved until the user accepts it.
- Keep relationships and hidden_threads structured in JSON but woven into the existing visible prose. Use empty arrays when appropriate.
- Validate edited JSON. Do not change card mappings, generate artwork, or publish to GitHub merely because a guidebook entry is approved.

## Accepted Passage Example

Event: After Pavel arrives in the Far North carrying the Sky-Hide Mirror, the aurora opens a passage above an old ritual path. His escape from the Closed City has brought the convergence to a place already altered by the meteor forty years earlier. For the village and the circus, the opening offers a first chance to deliberately cross into the realities they have only glimpsed in dreams.

Interpretation: The Ace of Wands marks the moment possibility becomes something you can act upon. The passage offers discovery, but no promise of a safe destination. This card asks you to notice what awakens your curiosity or desire, then give it a practical beginning. You do not need the whole journey planned to take a thoughtful first step.
