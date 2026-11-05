# sk_improvements

`sk_improvements` is a Sonic 3 & Knuckles disassembly-based project focused on gameplay, engine, and quality-of-life improvements implemented from Sonic Retro tutorials.

This repository is built on top of the Sonic 3 & Knuckles community disassembly and gradually ports fixes and features from the Sonic Retro hacking guides into one project.

See also:
- Sonic Retro Disassemblies: https://info.sonicretro.org/Disassemblies
- Sonic Retro How-To guides: https://info.sonicretro.org/SCHG_How-to:Guide

## Build options

Build the game with `buildS3Complete.bat` (or `lua buildS3Complete.lua`), which writes `sonic3k.bin`: Sonic 3 & Knuckles with the Sonic 3 data built in. The Sonic & Knuckles-only build was removed, and the standalone Sonic 3 build (`buildS3`, `s3.asm`) is kept as upstream left it. The switches `FixBugs` and `Feature*` are near the top of `sonic3k.asm`. Every `Feature*` switch is 1 by default; 0 restores the original behaviour of that addition. See the [modding reference](docs/modding.md) for the feature options, the ported bug fixes and the water settings table. Keep both values of every switch assemblable when changing shared routines.

## Features

Gameplay additions, each behind its own switch near the top of `sonic3k.asm` (1 = on, 0 = the original game; see the [modding reference](docs/modding.md) for the details and what 0 restores):

| Switch | Default | What it does |
|---|---|---|
| `FeatureRollJumpSteering` | 1 | Steering after jumping from a roll |
| `FeatureAirRoll` | 1 | A/B/C in the air (after a spring, for example) curls the player into a ball |
| `FeatureInstantTally` | 1 | Holding A/B/C finishes the act bonus count at once |
| `FeatureStarPostRings` | 1 | Restarting at a Star Post keeps the ring count |
| `FeatureSmoothSlots` | 1 | The Slots bonus stage rotates in 256 steps instead of 64 |
| `FeatureBlueKnuckles` | 1 | Player mode 4, Blue Knuckles, in the Level Select |
| `FeatureSuperToggle` | 1 | A+B/A+C/B+C toggles Super/Hyper for every character, including reversion during flight/glide/climbing |
| `FeatureHomingAttack` | 1 | Sonic's Homing Attack, or a Jump Dash without a target, instead of the Insta-Shield |
| `FeatureExtendedCamera` | 1 | The camera looks ahead at top speed and while charging a Spin Dash |
| `FeatureExtraLives` | 1 | A life for every 100 rings, not only at 100 and 200 |
| `FeatureInvincibilityFlash` | 1 | The invincibility stars blink during their last two seconds |
| `FeatureFastSoundTest` | 1 | B+A steps the Level Select sound test back by $10 |
| `FeatureSpecialStageSelect` | 1 | Left/Right on SPECIAL STAGE in the Level Select choose the stage |
| `FeatureLightDash` | 1 | In the air, A next to a chain of 3+ rings dashes along it (Sonic, Tails, Knuckles) |
| `FeaturePeelOut` | 1 | Sonic's Super Peel-Out: standing still, hold Up and press A/B/C |
| `FeatureInfiniteLives` | 0 | Optional: no lives counter, Game Over or continues; 1-ups give 10 rings |
| `FeatureCDDrowning` | 0 | Optional: the music keeps playing under water and the air warning beeps every second, as in Sonic CD |

The attract demos keep the original air move and camera, so they play as recorded. There is no `FeatureVictoryPoses` as in Sonic 1 and Sonic 2 Improvements: Sonic 3 & Knuckles already has victory poses for all three characters. There is no `FeatureCentiseconds`: levels have no free video memory for the extra clock digits.

Always in the build, without a switch:

- Vladikcomper's MD Debugger with symbolic backtraces (see [Error diagnostics](#error-diagnostics))
- The title LEVEL SELECT and CHEATS entries, separate Chaos/Super Emerald cheats, SUPER MUSIC, DEBUG, SUPER RINGS, RING DRAIN, GOD MODE, debug coordinates and their SRAM record (see [Cheats and settings](#cheats-and-settings))
- The disassembly's `FixBugs` fixes and the ported Sonic Retro fixes (see [Built-in fixes](#built-in-fixes) and [Implemented Sonic Retro tutorials](#implemented-sonic-retro-tutorials))
- The data-driven water table (`WaterSettings`) and bounds-safe character tables for player modes above 3
- Flamewing's UltraDMAQueue and six-button controller support
- Faster Kosinski and Enigma decompression, `GetArcTan`, airborne collision and ring loss, all with unchanged gameplay (see [optimisations](docs/modding.md#optimisations))
- A demo cycle test bench (see [Tests](#tests))

## Cheats and settings

The Angel Island vine code or the title code Up, Down, Down, Down, Left, Right unlocks LEVEL SELECT and CHEATS as separate title entries. CHEATS has separate ALL CHAOS EMERALDS and ALL SUPER EMERALDS, DEBUG, SUPER RINGS, RING DRAIN, GOD MODE and SUPER MUSIC. DEBUG and GOD MODE also work for player 1 in Competition. The unlock, the cheats and the Level Select character are kept in an SRAM record that leaves the save files untouched, and debug mode shows the coordinates in the upper right corner. Level Select displays character names. New save slots and NO SAVE also offer Knuckles and Tails, with Knuckles' route and AI partner. During the AIZ2 bombing run, AI Tails continues running right instead of braking when he reaches the leader. See [settings, cheats and SRAM](docs/settings.md).

## Error diagnostics

Every build includes Vladikcomper's MD Debugger: a crash shows the exception screen with the faulting label, registers, stack and a symbolic backtrace instead of restarting the game. `buildS3Complete.lua --no-symbols` leaves out the symbol names. See the [debugger guide](_debug/md-debugger/README.md) for controls, the layout rule and tool requirements.

## Tests

`tests/check_demo_cycle.py` plays the title screen's five attract demos (Angel Island, Hydrocity, Marble Garden, Flying Battery, Sandopolis) and prints, for each, the frames played, the frames player 1 spent dead, the furthest X reached and the rings; a healthy cycle has no deaths. With `--baseline OLD.bin` it plays the same demos on another build and compares them frame by frame (player 1 and 2, rings, camera), which is how changes meant to keep gameplay as it was, such as the optimisations, are checked. It needs Python 3 and Gens with the automation extension, built from [gens_automation](https://github.com/oranguthang/gens_automation) (its `Gens.exe` via `--gens` or `GENS_EXE`); neither is part of this repository.

```
python tests/check_demo_cycle.py --gens path/to/Gens.exe
git worktree add ../sk_base HEAD~1   # then build sonic3k.bin there
python tests/check_demo_cycle.py --gens path/to/Gens.exe --baseline ../sk_base/sonic3k.bin
```

The demos were recorded with the original game, so they keep its moves and centred camera (see the [modding reference](docs/modding.md)); the default build plays them frame for frame like a build with every `Feature` switch at 0.

`python tests/check_aiz1_camera_bounds.py` checks camera panning in AIZ1's lower giant-ring passage for all five player modes, the height-table transitions, forced and locked cameras, and death on a real fall. It runs the assembled 68000 routines and needs Python 3 with `unicorn==2.1.4`; build `sonic3k.bin` first.

`python tests/check_controls_and_settings.py` exercises the assembled settings migration, both emerald cheats, character selection, Super/Hyper combos, music recovery, debug signpost loading and P1-only Competition protection. It needs Unicorn 2.1.4 and the default ROM build. Real-emulator checks cover title menus, a Knuckles and Tails save across a cold reset, all eight solo form toggles, and repeated debug roundtrips for all nine Competition character pairs; full routes and endings still need play-testing.

## Built-in fixes

The disassembly's built-in `FixBugs` flag is enabled, applying approximately 59 bug fixes already present in the codebase, including skid animation register corruption for all characters, sprite height initialization for various objects, boss attack positioning, Super Sonic palette fade-in, and many other minor bugs.

## Implemented Sonic Retro tutorials

- [Remove the Roll-Jump Lock](https://info.sonicretro.org/SCHG_How-to:Remove_the_Roll-Jump_Lock)
- [Fix Scattered Rings Underwater Physics](https://info.sonicretro.org/SCHG_How-to:Fix_Scattered_Rings_Underwater_Physics)
- [Fix Accidental Deletion of Scattered Rings](https://info.sonicretro.org/SCHG_How-to:Fix_Accidental_Deletion_of_Scattered_Rings)
- [Fix Ring Timers](https://info.sonicretro.org/SCHG_How-to:Fix_Ring_Timers)
- [Use correct height when roll jumping](https://info.sonicretro.org/SCHG_How-to:Use_correct_height_when_roll_jumping)
- [Make the Slots Bonus Game Rotate Smoothly](https://info.sonicretro.org/SCHG_How-to:Make_the_Slots_Bonus_Game_Rotate_Smoothly)
- [Fix Tails' respawn speeds](https://info.sonicretro.org/SCHG_How-to:Fix_Tails%27_respawn_speeds)
- [Add Flamewing's UltraDMAQueue to Sonic 3 & Knuckles](https://info.sonicretro.org/SCHG_How-to:Add_Flamewing%27s_UltraDMAQueue_to_Sonic_3_%26_Knuckles)
- [Skip Score Tallies](https://info.sonicretro.org/SCHG_How-to:Skip_Score_Tallies)
- [Fix screen boundary spindash bug](https://info.sonicretro.org/SCHG_How-to:Fix_screen_boundary_spindash_bug)
- [Add the Air Roll/Flying Spin Attack](https://info.sonicretro.org/SCHG_How-to:Add_the_Air_Roll/Flying_Spin_Attack)
- [Retain Rings when returning at a Star Post](https://info.sonicretro.org/SCHG_How-to:Retain_Rings_when_returning_at_a_Star_Post)
- [Add 6 button support](https://info.sonicretro.org/SCHG_How-to:Add_6_button_support)
- [Fix Blue Knuckles](https://info.sonicretro.org/SCHG_How-to:Fix_Blue_Knuckles)
- [Create a Homing Attack from scratch](https://info.sonicretro.org/SCHG_How-to:Create_a_Homing_Attack_from_scratch): Sonic's Homing Attack and Jump Dash replace the Insta-Shield (see [air moves](docs/modding.md#air-moves))
- [Add Extended Camera to Sonic 1](https://info.sonicretro.org/SCHG_How-to:Add_Extended_Camera_to_Sonic_1), ported to S3K for every character with the Spin Dash pan from Sonic 2 Improvements (see [extended camera](docs/modding.md#extended-camera))
- [Improving compression formats](https://info.sonicretro.org/SCHG_How-to:Improving_compression_formats): faster Kosinski (including the decompression queue) and Enigma decoders (see [optimisations](docs/modding.md#optimisations))
- [Improving CalcAngle subroutines](https://info.sonicretro.org/SCHG_How-to:Improving_CalcAngle_subroutines): a faster `GetArcTan` and an air collision direction without a division (see [optimisations](docs/modding.md#optimisations))
- [Speed Up Ring Loss Process in Sonic 1](https://info.sonicretro.org/SCHG_How-to:Speed_Up_Ring_Loss_Process_in_Sonic_1), ported to S3K (see [optimisations](docs/modding.md#optimisations))

Six-button controllers are detected on both ports. X, Y, Z, and Mode have separate held/pressed input states in `Ctrl_1_held_6B` / `Ctrl_1_pressed_6B` and their player-two equivalents; bit 7 of the held state indicates a detected six-button controller. The extra buttons currently have no gameplay bindings. Enable six-button controllers in your emulator to use these inputs.

Blue Knuckles (`Player_mode` 4) can be picked in the Level Select by pressing C until the footer reads BLUE KNUCKLES. Every player mode of 3 or higher now follows Knuckles' route, level events and abilities, and character-indexed tables are clamped so modes above 3 can no longer read past their end (signpost, Slots, Special Stage results, Continue screen, ending). Only mode 3 loads Knuckles' red palette, so mode 4 keeps Sonic's colors. Super/Hyper Blue Knuckles uses Super Knuckles' palette cycle with the red and blue channels swapped and returns to his blue colors, underwater included, when the form ends.

## Open questions

Things not yet checked in the emulator, or left as they are on purpose:

- Homing Attack: that bosses are never targeted was not tried in a boss fight.
- Light Dash: chains under water, across loops or into walls, and an act change during a dash.
- Super Peel-Out: tried in Angel Island only.
- CHEATS: the emerald overlays were not followed through the giant rings, Doomsday and the endings.
- `FeatureInstantTally`, `FeatureStarPostRings` and `FeatureSmoothSlots` were not played with the switch at 0.
- Extended camera: the snap down after a long fall was not reproduced.
- The Kosinski queue's fast decoder is checked to keep to the registers that `Set_Kos_Bookmark` saves and to write only its output; an interruption at every point was not simulated.
- `Draw_Sprite` keeps the original code (see [optimisations](docs/modding.md#optimisations)).

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
