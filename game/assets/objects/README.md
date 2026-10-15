# Placed Object Art

Transparent 512x512 RGBA sprites for the Godot board. The artwork is generated with
built-in ImageGen, then trimmed and uniformly resized onto a common canvas using
`tools/prepare_object_art.py`. Upright objects share a contact baseline at y470;
the flat walkable Leak is centered instead.

| Object | Silhouette and material |
| --- | --- |
| Barricade | Broad reinforced steel blast shield, frost and worn warning red |
| Pylon | Slender pale quartz relay in shell-shaped bronze supports, cyan core |
| Stone | Low uneven carved granite, shell inlay and faint ley seam |
| Vault | Heavy sealed basalt coffer with a bronze-and-ivory lock seal |
| Leak | Flat irregular green fissure, fragmented frozen iron and restrained vapor |

`GameBoardView` renders these above the tile material and below character figures,
with ownership rims and HP pips. Empty HP pips show damage. The Leak has no owner,
HP, or solid-object base. Existing procedural drawing remains the fallback when an
asset is unavailable. Object placement, movement blocking, line of sight, and damage
are still determined by the existing gameplay systems.

Master images, prompts and a large/small-size art proof are stored in
`docs/art-specs/placed-objects/`. Review the 56-pixel samples as well as the full art.
