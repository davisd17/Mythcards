# Board Figures

Board figures are transparent, normalized 512 x 768 sprites. Every figure shares the
same foot baseline so the board can scale outfits without changing gameplay position,
selection, or hit testing.

`wardrobe.json` is presentation data only. The default outfit must always be included.
Alternate outfits may later require an entitlement, but outfit ownership and selection
must never change character stats, abilities, board footprint, or match state.

The default set covers the 14 playtest characters: the Closed City team and the Flood
Survivors team (designer decision 2026-10-07; see LLD-closed-city-flood-roster.md).
Each folder is named by the character's card id, so a figure always belongs to the
character whose rules it shows.

| Type | Closed City | Flood Survivors |
| --- | --- | --- |
| Common | Reactor Worker / Nikolai Yegorov | Stone-Line Laborer |
| Mount | VERA-7 | Ahesu, the Stone-Current Serpent |
| Warrior | Major Yuri Volkov | Naia of the Black Sarcophagus |
| Leader | Irina Vasilievna Karpova | Queen Meret-Anu |
| Hero | Dr. Mikhail Orlov | Sahu-Ren, Last Memory-Keeper |
| Specialist | Dr. Elena Morozova | Iset-Nara |
| Mystic | Zoya Miranova | Thalassa-Nekh |

Folder ids: `r-reactor-worker`, `r-vera-7`, `r-yuri-volkov`, `r-irina-karpova`,
`r-mikhail-orlov`, `r-elena-morozova`, `r-zoya-miranova`; `a-flood-survivor-stone-line-laborer`,
`-ahesu`, `-naia`, `-meret-anu`, `-sahu-ren`, `-iset-nara`, `-thalassa-nekh`. The original 14
characters have no figures and show their card art on the board.
