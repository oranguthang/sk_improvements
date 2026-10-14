# Modding reference

## Feature options

The `Feature*` switches in `sonic3k.asm` turn this project's gameplay additions on (1, the default) or off (0). Off restores the original Sonic 3 & Knuckles behaviour for that feature only. The code stays assembled but is never entered, so a feature can be switched off without moving data or touching other features. Both builds, `buildSK` and `buildS3Complete`, read the same switches.

| Option | When 0 |
|---|---|
| `FeatureRollJumpSteering` | A jump from a roll locks midair steering again. |
| `FeatureAirRoll` | Pressing A/B/C in the air no longer curls the player into a ball, and a fresh press while rising fast no longer reaches the shield move, flight or glide. |
| `FeatureInstantTally` | Holding A/B/C no longer finishes the act bonus count at once. |
| `FeatureStarPostRings` | Restarting from a Star Post starts with no rings. Returning from a Special Stage or bonus stage still keeps them. |
| `FeatureSmoothSlots` | The Slots bonus stage rotates in 64 steps again. |
| `FeatureBlueKnuckles` | The Level Select character number stops at 03. The fixes that keep player modes above 3 working stay in. |

S1's `FeatureLamppostRings` is `FeatureStarPostRings` here; the other names match Sonic 1 Improvements.

## Bug fixes

`FixBugs` (default 1) switches the disassembly's own bug fixes and the ones this project ported from Sonic Retro guides. With 0, both builds assemble the original code again:

- [Fix Scattered Rings Underwater Physics](https://info.sonicretro.org/SCHG_How-to:Fix_Scattered_Rings_Underwater_Physics): rings scattered under water start at half speed and fall with gravity $A instead of $18. `Bouncing_Ring_Gravity` applies it to normal and reverse gravity rings.
- [Fix Ring Timers](https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers): each scattered ring counts down its own lifetime in `height_pixels`, so rings lost later do not keep older ones alive, and they flash during their last 80 frames (`Bouncing_Ring_TimerAndDraw`). The global `Ring_spill_anim_counter` still drives the spin animation.
- [Fix Accidental Deletion of Scattered Rings](https://info.sonicretro.org/SCHG_How-to:Fix_Accidental_Deletion_of_Scattered_Rings): in acts that wrap vertically (`Camera_min_Y_pos` is -$100) rings are not deleted below the bottom of the level.
- [Use correct height when roll jumping](https://info.sonicretro.org/SCHG_How-to:Use_correct_height_when_roll_jumping)
- [Fix Tails' respawn speeds](https://info.sonicretro.org/SCHG_How-to:Fix_Tails%27_respawn_speeds)
- [Fix screen boundary spindash bug](https://info.sonicretro.org/SCHG_How-to:Fix_screen_boundary_spindash_bug)

The Blue Knuckles fixes (player modes 3 and above treated as Knuckles, clamped character tables) do not change modes 0–3 and are always assembled.

## Water settings table

Inspired by [Work with Water in S3K](https://info.sonicretro.org/SCHG_How-to:Work_with_Water_in_S3K). Which acts have water used to be decided by chains of hard-coded zone checks in `CheckLevelForWater` and `LoadWaterPalette`. It now comes from the `WaterSettings` table in `sonic3k.asm`: one `waterlevel` line per act with water, giving its underwater palette ID, the palette data used along an uneven water surface, Knuckles' underwater colors, and these flags:

- `WaterFlag_FlatSurface`: flat surface handled by `HInt2`, as in Hydrocity
- `WaterFlag_NoKnuckles`: no water for player modes 3 and above
- `WaterFlag_NoKnucklesAtActStart`: together with `WaterFlag_NoKnuckles`, only when the act is started directly rather than continued from the act before (Angel Island 2)

To give another act water, add a `waterlevel` line for it and set its starting height in `Levels/Misc/StartingWaterHeights.bin` (two words per zone, acts 1 and 2). Moving water also needs a routine in `DynamicWaterHeight_Index`. Knuckles' colors are taken from the table entry, and an entry of 0 keeps the palette's own colors, so water in Mushroom Hill or later zones does not read past the end of `Pal_WaterKnux`. The original acts behave as before.
