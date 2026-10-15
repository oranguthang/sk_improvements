# Modding reference

## Feature options

The `Feature*` switches in `sonic3k.asm` turn this project's gameplay additions on (1, the default) or off (0). Off restores the original Sonic 3 & Knuckles behaviour for that feature only. The code stays assembled but is never entered, so a feature can be switched off without moving data or touching other features.

| Option | When 0 |
|---|---|
| `FeatureRollJumpSteering` | A jump from a roll locks midair steering again. |
| `FeatureAirRoll` | Pressing A/B/C in the air no longer curls the player into a ball, and a fresh press while rising fast no longer reaches the shield move, flight or glide. |
| `FeatureHomingAttack` | Sonic's A/B/C in the air does the Insta-Shield again, and invincibility blocks his air move as in the original game. |
| `FeatureExtendedCamera` | The camera keeps the original fixed focus. |
| `FeatureExtraLives` | Rings award lives only at 100 and 200. |
| `FeatureInvincibilityFlash` | The invincibility stars stay steady until they vanish. |
| `FeatureFastSoundTest` | B+A in the Level Select sound test steps ahead by $10 like A alone. |
| `FeatureSpecialStageSelect` | Left/Right on SPECIAL STAGE switch columns again, and a Special Stage started from the Level Select is the game's own choice. |
| `FeatureInstantTally` | Holding A/B/C no longer finishes the act bonus count at once. |
| `FeatureStarPostRings` | Restarting from a Star Post starts with no rings. Returning from a Special Stage or bonus stage still keeps them. |
| `FeatureSmoothSlots` | The Slots bonus stage rotates in 64 steps again. |
| `FeatureBlueKnuckles` | The Level Select character number stops at 03. The fixes that keep player modes above 3 working stay in. |
| `FeatureLightDash` | A in the air always does the normal air move; rings never start a Light Dash. |
| `FeaturePeelOut` | Up + A/B/C while standing jumps, as in the original game. |

Two optional alternatives are off by default; 1 enables them:

| Option | When 1 |
|---|---|
| `FeatureInfiniteLives` | The lives counter is hidden and dying never ends the game; it restarts the act, a Time Over too. Rings, the score and Special Stage rings no longer award lives or continues, and 1-ups give 10 rings. |
| `FeatureCDDrowning` | As in Sonic CD, the music keeps playing below 12 seconds of air and the air warning sounds every second; the countdown numbers still appear. Ending invincibility is no longer held back while the air is low, and breathing again does not restart the music. |

S1's `FeatureLamppostRings` is `FeatureStarPostRings` here; the other names match Sonic 1 Improvements. S1's `FeatureCentiseconds` is not available: levels have no free video memory for two more clock digits.

There is no `FeatureVictoryPoses`: Sonic 3 & Knuckles already has it. After the end-of-act sign or the capsule, `Set_PlayerEndingPose` stops the player, locks the controls and plays animation $13, a victory pose for each of Sonic, Tails and Knuckles, while the results come in.

## Air moves

With `FeatureHomingAttack`, a fresh A/B/C press in the air after a jump or an Air Roll (`Sonic_ShieldMoves`) does, in this order:

1. Hyper Sonic: the Hyper Dash, as before.
2. With all emeralds and 50 rings: the Super transformation, as before.
3. Not invincible, with a fire, lightning or bubble shield: that shield's move.
4. Otherwise, including Super Sonic, invincibility (whose stars hide the shield) and the blue shield: `Sonic_AirDash`. It aims at the nearest badnik or whole monitor ahead of Sonic within 150 pixels on both axes and dashes at speed 8 toward the upper third of its collision box (`Sonic_HomingTargetY`), as in Sonic 1 Improvements. Without a target it is a Jump Dash: speed 8 forward with the vertical speed cleared. Reverse gravity always gives the Jump Dash.

Targets come from `Collision_response_list`, so only objects that could be touched in the last frame count; bosses (`boss_hitcount2` set) are never picked. One dash is allowed per jump (`double_jump_flag` = 2). Breaking a badnik or monitor with it (`Touch_ResetAirDash`) stops Sonic and bounces him up at -$500, and he may dash again. The Insta-Shield object stays in the Shield slot but is never started.

The attract demos were recorded with the original moves, so while one plays (`Demo_mode_flag`) Sonic still does the Insta-Shield, and Super Sonic and invincible Sonic do nothing, as in the original game.

`jumping` = 2 marks a jump the button may not cut short: the Air Roll sets it, so a spring launch keeps its height when the button is released, and so do the dash and the bounce after a hit. A normal jump is still `jumping` = 1.

## Light Dash

With `FeatureLightDash`, a fresh A press in the air (`Player_LightDashStart`, first in every air mode of Sonic, Tails and Knuckles) next to a chain of at least three uncollected rings dashes the player along it, as in Sonic 1 and Sonic 2 Improvements. B and C never start it, and A alone on the ground still jumps. Without a chain the press falls through to the normal air move: the Air Roll, the Jump Dash or Homing Attack, Tails' flight or Knuckles' glide. It is not started from a flight, a glide or a shield move (`double_jump_flag` set), by the sidekick, in Competition mode, the Competition zones or the bonus stages, under reverse gravity, or while control is locked or an object holds the player.

The first ring must lie ahead within 64 pixels; each next one within 72 pixels of the last ring reached. The targets are the level's ring layout itself (`RingLocPtrs`, the same index as `Ring_status_table`), so rings outside the screen count too and the chain is found the same way in every zone. The dash moves at speed $C (6 underwater) in eight substeps a frame with the normal level collision, follows the ground when a link runs along it, collects each ring like `Test_Ring_Collisions` and attacks badniks (`LightDash_Attacking` in `Touch_Enemy`). It ends when the chain does, keeping the last ring-to-ring direction at full speed; or when it is blocked for three frames, after 384 frames, on a hit or a death, or in a new act. The player straightens up from a roll and shows the running frames turned along the dash: the animation borrows `angle` and `ground_vel` for one call (`LightDash_Animate_*`) and gives them back. The state lives in the `LightDash_*` bytes after `Emerald_flicker_flag`, which were unused.

## Super Peel-Out

With `FeaturePeelOut`, Sonic standing still holds Up and presses A, B or C to charge a Super Peel-Out (`Sonic_PeelOut`, first in `Sonic_MdNormal`), as in Sonic 1 and Sonic 2 Improvements. The charge grows by 100 a frame up to twice `Max_speed`, at most $1000; letting go of Up launches an upright run at that speed, and a charge under $600 is cancelled without a jump. Like Sonic 2, Sonic 3 & Knuckles has no figure-eight frames or Peel-Out sounds, so Sonic runs the normal run cycle on the spot at the charged speed with the Spin Dash sounds, and the extended camera looks ahead as for a Spin Dash. The charge is kept in `spin_dash_counter`, and `PeelOut_charging` (after the Light Dash bytes) marks it for player 1. Landing, a hit, a death or a new level ends it. Tails and Knuckles, the demos and Competition mode are unchanged.

## Bug fixes

`FixBugs` (default 1) switches the disassembly's own bug fixes and the ones this project ported from Sonic Retro guides. With 0, the original code is assembled again:

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

## Extended camera

With `FeatureExtendedCamera`, `Player_PanCamera` moves `Camera_pan_X` 2 pixels a frame up to 64 pixels from the centre (160) while the player the 1-player camera follows moves at top speed ($600) or charges a Spin Dash, so more of the way ahead is visible, as in Sonic 1 and Sonic 2 Improvements. It holds until the speed drops below $4B0, then eases back, as it also does while an object or cutscene controls the player (`object_control` bit 7). `MoveCameraX` keeps the player `Camera_pan_X`-16 to `Camera_pan_X` pixels from the left edge; a forced scroll position (`Scroll_force_positions`) stays centred. Competition mode and the attract demos do not use it: the demos were recorded with the camera centred, and a panned camera loads objects such as platforms at other times, so the recorded input would no longer fit.

The direction comes from `x_vel` on the ground as well as in the air: `ground_vel` points along the surface and has the opposite sign on a ceiling or in a loop, which panned the old work-in-progress port the wrong way. Level events that read `Camera_X_pos` see the panned camera, so they can start up to 64 pixels earlier or later than in the original game.

## Quality-of-life details

With `FeatureExtraLives`, bits 1-7 of `Extra_life_flags` (and `Extra_life_flags_P2`) count the hundreds of rings already rewarded; bit 0 stays the Slots stage's continue. Losing the rings clears the flags, so the next 100 give another life. `ExtraLives_Check` in `Improvements/QoL.asm` serves collected rings, 10-ring monitors and Competition player 2.

With `FeatureSpecialStageSelect`, the stage number after "SPECIAL STG" is `Current_special_stage`+1, written into the Level Select plane map in `RAM_start`. Starting a Special Stage from the Level Select sets `Special_stage_select`, the byte after `Current_special_stage`, so the stage set-up plays that stage instead of searching for one without an emerald; winning a stage whose emerald was already earned does not count it twice.

## Optimisations

These change no behaviour, so they have no switches. Each was checked against the original code in the Unicorn 68000 emulator and on the attract demos, which play out frame for frame as before.

- Kosinski and Enigma decompression (`Improvements/Decompression.asm`, after [Improving compression formats](https://info.sonicretro.org/SCHG_How-to:Improving_compression_formats), as in Sonic 1 and Sonic 2 Improvements). `Kos_Decomp` and `Eni_Decomp` jump to vladikcomper's Kosinski decoder with MarkeyJester's and Flamewing's improvements and to an Enigma decoder with ideas from Malachi's. The Kosinski queue (`Process_Kos_Queue`) has its own copy of the fast decoder: V-int may stop it anywhere, and `Set_Kos_Bookmark` saves only d0-d6/a0-a2, SR and the PC, so this copy uses no stack and no other register (a2 holds the bit reversal table, and dictionary copies read `(a1,d5.w)`). Same formats, output, end pointers and preserved registers on all 129 Kosinski files, all 412 KosM modules and all 35 Enigma maps, with about a third fewer instructions for Kosinski and an eighth fewer for Enigma; the demos start up to 170 frames sooner.
- `GetArcTan` (after [Improving CalcAngle subroutines](https://info.sonicretro.org/SCHG_How-to:Improving_CalcAngle_subroutines), as in Sonic 1 and Sonic 2 Improvements) saves only d3, uses short branches and checks for x = y = 0 only when |y| >= |x|. Same angles, registers and flags on 60,000 pairs; only when x = y = 0 does the upper word of d0 now come back clear instead of unchanged, and every caller reads just the low word. The air collision of `SonicKnux_DoLevelCollision`, `Tails_DoLevelCollision`, `Knux_DoLevelCollision_CheckRet` and the MGZ top platform picks its direction with `CalcAirQuadrant` (`Improvements/Math.asm`), which gives (`GetArcTan`-$20)&$C0 without a division, the table's rounding near the diagonals included.
- Ring loss (`loc_1A68C`, after [Speed Up Ring Loss Process in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Speed_Up_Ring_Loss_Process_in_Sonic_1), as in Sonic 1 Improvements) takes each ring's speed from `RingLoss_Velocities` or `RingLoss_Velocities_Water` (`Improvements/RingLoss.asm`) instead of `GetSineCosine` and shifts, and finds the free slots in one pass instead of one `AllocateObjectAfterCurrent` search per ring. The slots searched are the same, the allocator's own look-up table included, and the tables cover every slot, for a spill that starts after the rings ran out. The same objects on 3,000 random object RAM states, with about a quarter of the instructions (a 32-ring spill: 13,910 down to 1,800).

`Draw_Sprite` keeps the original code. Sonic 3 & Knuckles already stores `priority` as the list's offset, so the table look-up of [Improve DisplaySprite subroutines](https://info.sonicretro.org/SCHG_How-to:Improve_DisplaySprite_subroutines) has nothing to replace. What is left, detecting a full list by the count overflowing into bit 7, saves about 10 cycles a call but would change d0, which the original leaves alone, for its 845 callers.
