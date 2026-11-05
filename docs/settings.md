# Settings, cheats and SRAM

## Unlocking the Level Select

Either of these unlocks LEVEL SELECT and CHEATS on the title screen, and SRAM remembers it:

- the game's own code: hang on a vine in Angel Island Zone and press Left, Left, Left, Right, Right, Right, Up, Up, Up (the same code on a Mushroom Hill pulley then turns DEBUG on);
- the Sonic 1 code on the title screen: Up, Down, Down, Down, Left, Right.

The title shows LEVEL SELECT and CHEATS together on two rows, using the original title menu font. With the unlock, Pause+A in a level returns to the title. CHEATS opens directly from the title; Start returns there too.

C in Level Select cycles SONIC AND TAILS, SONIC ALONE, TAILS ALONE, KNUCKLES ALONE, BLUE KNUCKLES and KNUCKLES AND TAILS. The name matches Sonic 2 (including KNUX AND TAILS) and appears in the lower-right empty row and SRAM remembers the choice. Blue Knuckles is available only here. New save slots and NO SAVE cycle the other five choices. Knuckles and Tails uses Knuckles' route with the normal AI Tails partner, including carrying; save slots remember the team independently of Level Select.

## CHEATS

Up/Down select a row, Left/Right/A/B/C change it and Start returns to the title. Every change is saved at once. Level Select and CHEATS navigation and settings changes are silent.

| Setting | Values | Default | Effect |
|---|---|---|---|
| ALL CHAOS EMERALDS | OFF / ON | OFF | Overlays all seven Chaos Emeralds for Super forms, giant rings, Doomsday and endings. The real earned emeralds are kept. Turning this OFF also turns ALL SUPER EMERALDS OFF. |
| ALL SUPER EMERALDS | OFF / ON | OFF | Overlays all seven Super Emeralds for Hyper Sonic/Knuckles and Tails' form with four Flickies. Turning it ON also turns ALL CHAOS EMERALDS ON. Turning it OFF reveals the real earned Super Emeralds. |
| DEBUG | OFF / ON | OFF | B toggles object placement for player 1 in levels, including Competition, for any of the three characters. Player 2 cannot enter placement. Special Stages keep their own controls. |
| SUPER RINGS | 0 / 10 / 50 | 50 | Rings needed to transform. 0 turns RING DRAIN off. |
| RING DRAIN | OFF / ON | ON | OFF keeps a Super or Hyper form until the act ends. Turning it on at 0 rings sets SUPER RINGS to 10. |
| GOD MODE | OFF / ON | OFF | Prevents damage, drowning and time-over; pits bounce the player back toward solid ground. In Competition only player 1 is protected; player 2 keeps normal damage, air and time limits. |
| SUPER MUSIC | OFF / ON | ON | OFF keeps the current level or boss song during transformations and reversions. Drowning, 1-ups and scripted music keep their normal priority. |

Cheat overlays and new form controls do not apply in title demos. Emerald/ring cheats and Super transformations are disabled in Competition; DEBUG and GOD MODE work there for player 1.

## Super and Hyper controls

With the effective emerald set and enough rings, A+B, A+C or B+C during a jump toggles the form. The second distinct button must be pressed within ten frames. Sonic may hold one jump button and press another; Tails and Knuckles need two fresh presses so holding their flight/glide button does not transform them. A single press retains the normal air ability. A combo containing B takes priority over entering debug placement. With DEBUG ON, press A or C first (or both buttons together); standalone B still enters placement immediately. The old debug A shortcut for reversing gravity is disabled, including in Competition. A retains normal character moves; in placement mode it still cycles the selected object.

The first press may start flight or gliding; the second cancels that new ability and starts the transformation. Later in flight, gliding or climbing the combo only reverts an already Super/Hyper player, retaining the current motion. With seven Chaos Emeralds Tails becomes Super without Flickies; with seven Super Emeralds he gets the original four Flickies.

In debug mode an end sign loads its supporting signpost/monitor graphics even when created without the normal boss controller.

## Debug coordinates

While debug mode is available in a 1-player game, the upper right corner shows the camera X and Y (top row) and the player's X and Y (second row) in hex, then SPR and the number of sprites drawn. SCORE, TIME and RINGS keep their meaning, in object placement too. Levels have no spare video memory, so the overlay borrows the last 11 tiles of the shield art: it hides while the player has a shield, invincibility or a Super form, during the Insta-Shield attack and while the player dies.

## SRAM record

The game keeps its save files in odd-byte SRAM at `$200001`. `Improvements/Settings.asm` keeps one more record in `SRAM_settings`, the $15 logical bytes after `SRAM_SKgame_backup` that the game never reads or writes (its SRAM routines copy exactly their block sizes), so save files and their backups are never touched. Logical byte N of the record is at `SRAM_settings+2*N`: bytes 0-3 `S3DV`, 4 the format version (2), 5 the payload length (9), then the Level Select unlock, DEBUG, ALL CHAOS EMERALDS, SUPER RINGS, RING DRAIN, GOD MODE, the Level Select character, SUPER MUSIC and ALL SUPER EMERALDS, then a big-endian additive checksum of everything before it.

Startup loads it after the game's own `SRAM_Load` (defaults for a missing or damaged record). A valid version 1 record keeps its settings, copies its old ALL EMERALDS value to both emerald cheats and defaults SUPER MUSIC to ON. The unlock codes, leaving the Level Select and every change on the CHEATS page save it. A write invalidates the signature first and commits it last, with interrupts masked while SRAM is mapped; the code stays below `$200000`, which SRAM covers while it is mapped. To add a setting, append its RAM byte to `Settings_Fields`, clamp it in `Settings_Normalize` and raise `settings_sram_version`; the record has room for 4 more settings. Emeralds, lives and progress are not part of it.
