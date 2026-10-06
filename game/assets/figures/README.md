# Board Figures

Board figures are transparent, normalized 512 x 768 sprites. Every figure shares the
same foot baseline so the board can scale outfits without changing gameplay position,
selection, or hit testing.

`wardrobe.json` is presentation data only. The default outfit must always be included.
Alternate outfits may later require an entitlement, but outfit ownership and selection
must never change character stats, abilities, board footprint, or match state.

The default set covers all 14 gameplay roles. The presentation catalog maps the seven
Russian gameplay ids to the Closed City cast and the seven Atlantean gameplay ids to
the Flood Survivors cast. This is intentionally an art-layer mapping: gameplay ids,
stats, abilities, setup rules, and save/test fixtures remain unchanged.

| Gameplay role | Closed City | Flood Survivors |
| --- | --- | --- |
| Common | Reactor Worker / Nikolai Yegorov | Stone-Line Laborer |
| Mount | VERA-7 | Ahesu, the Stone-Current Serpent |
| Warrior | Major Yuri Volkov | Naia of the Black Sarcophagus |
| Leader | Irina Vasilievna Karpova | Queen Meret-Anu |
| Hero | Dr. Mikhail Orlov | Sahu-Ren, Last Memory-Keeper |
| Specialist | Dr. Elena Morozova | Iset-Nara |
| Mystic | Zoya Miranova | Thalassa-Nekh |
