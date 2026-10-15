# Pilot Art Prompts

Mode: built-in ImageGen; reference: `game/assets/figures/r-yuri-volkov/default.png`.

## Initial Four-Pose Sheet

Use case: identity-preserve. Asset: production sprite sheet for MythCards Godot board attack animation.
Reference image is the exact Yuri Volkov default board figure; preserve this same man's face, short dark hair, worn olive quilted containment/cosmonaut suit, reinforced boots and gloves, pressure collar, teal chest instrument, red shoulder patch, rifle, helmet and material rendering. Same realistic painted miniature style and frontal lighting with red left rim. No text.
Create ONE precisely aligned 2-column by 2-row animation sheet. Four equal portrait cells, each 512x768, total 1024x1536 if possible. TRUE TRANSPARENT BACKGROUND. No separators, labels or guides.
Order: upper left READY, upper right WIND-UP, lower left STRIKE, lower right RECOVER.
Each is the same man in a complete head-to-toe three-quarter view attacking screen-right with a rifle. Keep his feet identical and planted in exactly the SAME place within each cell: boot contact baseline y756, stance centered x256. His head is around y110 and boots around y750 matching reference. Same head/body scale in all cells, never individually fit each pose to its bounds. Safe area local x24..488 and y18..756, including weapon and muzzle flash. Keep muzzle within safe area with foreshortening and bent elbows, not a long off-canvas barrel.
Ready: raises rifle diagonally across chest toward right, alert eyes on target.
Wind-up: conspicuous anticipation, torso coils slightly back LEFT, knees bend, rifle pulled closer ready to shoulder, visibly different silhouette from ready.
Strike: rifle braced at shoulder pointing RIGHT, trigger hand and supporting hand correctly placed, strong compact forward extension, small contained amber muzzle flash at barrel tip, slight recoil.
Recover: lowers rifle to right diagonal toward resting position, shoulders settle. Eyes still right.
For logical continuity helmet is secured against left hip by a short harness throughout ALL four frames, freeing both hands to operate rifle. Never duplicate helmet. Same gloves, sleeves and body anatomy all four poses. Never change weapons, outfit or person. No scenery, floor, cast shadow, base, border, opaque background or extra figures. Full feet and gun visible every cell. Leg stance, scale and local canvas position must remain consistent. Distinct silhouettes readable at 80 px height. Draw four held key poses not four copies.

## Safe-Area Correction

Preserve the sheet's four figures, faces, poses, scale, boot locations, outfit and
lighting. Foreshorten the strike rifle so its muzzle ends around local x440 and the
entire attached flash ends before x480. Slightly foreshorten the other barrels as
needed to stay inside each cell's x24..488 safe area. Retain screen-right attack
direction, true transparency, equal cells, and no background, floor or annotations.

## Six-Frame Expansion

Mode: built-in ImageGen. Each additional pose uses the two adjacent registered pilot
frames as identity and pose references. Preserve the man, suit, rifle and planted feet.

### raise

Use case: identity-preserve. Edit a transparent production animation sprite of Major Yuri Volkov. Preserve exact man, face, olive quilted hazard suit, rifle design, boots, hip-mounted helmet, teal chest instrument, red shoulder patch, lighting and painted realistic style. One complete figure, three-quarter facing screen-right, actual transparent background, no text, no floor, no shadow. Keep canvas aspect 512x768; body centered x256; boot baseline y756, head near y130; same leg placement and scale as references. Safe area x24..488, y18..756, all rifle parts included. Change upper body and arms only, preserving planted feet. No muzzle flash, extra props or extra people. Image 1 is the READY pose. Image 2 is the BRACED/AIM pose. Produce the intermediate RAISE pose, exactly halfway between these two: rifle lifted to chest level, barrel pointing diagonally up toward screen-right at about 15 degrees above horizontal, stock not yet fully seated at shoulder. Both gloved hands on rifle, elbows separated and bending as it rises, face watching right with cheek not on stock. Torso only slightly crouched. This is a transitional raise, not already aiming, not low-ready. Keep rifle muzzle inside right margin.

### recoil

Use case: identity-preserve. Edit a transparent production animation sprite of Major Yuri Volkov. Preserve exact man, face, olive quilted hazard suit, rifle design, boots, hip-mounted helmet, teal chest instrument, red shoulder patch, lighting and painted realistic style. One complete figure, three-quarter facing screen-right, actual transparent background, no text, no floor, no shadow. Keep canvas aspect 512x768; body centered x256; boot baseline y756, head near y130; same leg placement and scale as references. Safe area x24..488, y18..756, all rifle parts included. Change upper body and arms only, preserving planted feet. No muzzle flash, extra props or extra people. Image 1 is the FIRE pose. Image 2 is the final RECOVER pose. Produce the intermediate RECOIL pose directly after firing: rifle still at shoulder height but pulled back toward left shoulder, muzzle lifted 12 degrees above horizontal, elbows flex, upper torso recoils subtly backward to screen-left. Cheek lifts slightly from stock. Both hands remain correctly gripping rifle. Knees and feet remain planted matching image 1. NO muzzle flash, only a tiny transparent wisp attached to muzzle if needed. This must look like recoil after a shot, clearly different from aiming and lowered recovery.
