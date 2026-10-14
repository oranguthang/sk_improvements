# Settings, cheats and SRAM

## Unlocking the Level Select

Either of these unlocks the Level Select and its CHEATS page, and SRAM remembers it:

- the game's own code: hang on a vine in Angel Island Zone and press Left, Left, Left, Right, Right, Right, Up, Up, Up (the same code on a Mushroom Hill pulley then turns DEBUG on);
- the Sonic 1 code on the title screen: Up, Down, Down, Down, Left, Right.

The title screen then offers LEVEL SELECT as a third item. With the unlock, Pause and A in a level returns to the Level Select. C in the Level Select changes the character (00 Sonic and Tails, 01 Sonic, 02 Tails, 03 Knuckles, 04 Blue Knuckles); SRAM remembers it.

## CHEATS

CHEATS is the last item of the Level Select, below the sound test. Up/Down select a row, Left/Right/A/B/C change it and Start goes back to the level list. Every change is saved at once.

| Setting | Values | Default | Effect |
|---|---|---|---|
| ALL EMERALDS | OFF / ON | OFF | Counts as all seven Chaos Emeralds and all seven Super Emeralds for the Super and Hyper forms (Super Tails, Hyper Sonic, Hyper Knuckles), giant rings, the Doomsday Zone after the Death Egg and the ending. The real emeralds are kept. |
| DEBUG | OFF / ON | OFF | Debug mode in every level (B enters object placement) without holding A. It is the game's own debug flag, so the Mushroom Hill code turns it on too. |
| SUPER RINGS | 0 / 10 / 50 | 50 | Rings needed to transform. 0 turns RING DRAIN off. |
| RING DRAIN | OFF / ON | ON | OFF keeps a Super or Hyper form until the act ends. Turning it on at 0 rings sets SUPER RINGS to 10. |
| GOD MODE | OFF / ON | OFF | Nothing hurts or kills the players, the air never runs out and the clock stops at 9:59. A fall below the level bounces the player back up as an airborne, non-jumping player, so Left/Right can steer back onto solid ground. |

None of them apply in title demos or Competition mode.

## Debug coordinates

While debug mode is available in a 1-player game, the upper right corner shows the camera X and Y (top row) and the player's X and Y (second row) in hex, then SPR and the number of sprites drawn. SCORE, TIME and RINGS keep their meaning, in object placement too. Levels have no spare video memory, so the overlay borrows the last 11 tiles of the shield art: it hides while the player has a shield, invincibility or a Super form, during the Insta-Shield attack and while the player dies.

## SRAM record

The game keeps its save files in odd-byte SRAM at `$200001`. `Improvements/Settings.asm` keeps one more record in `SRAM_settings`, the $15 logical bytes after `SRAM_SKgame_backup` that the game never reads or writes (its SRAM routines copy exactly their block sizes), so save files and their backups are never touched. Logical byte N of the record is at `SRAM_settings+2*N`: bytes 0-3 `S3DV`, 4 the format version (1), 5 the payload length (7), then the Level Select unlock, DEBUG, ALL EMERALDS, SUPER RINGS, RING DRAIN, GOD MODE and the Level Select character, then a big-endian additive checksum of everything before it.

Startup loads it after the game's own `SRAM_Load` (defaults for a missing or damaged record). The unlock codes, leaving the Level Select and every change on the CHEATS page save it. A write invalidates the signature first and commits it last, with interrupts masked while SRAM is mapped; the code stays below `$200000`, which SRAM covers while it is mapped. To add a setting, append its RAM byte to `Settings_Fields`, clamp it in `Settings_Normalize` and raise `settings_sram_version`; the record has room for 6 more settings. Emeralds, lives and progress are not part of it.
