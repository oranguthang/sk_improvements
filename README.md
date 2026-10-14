# sk_improvements

`sk_improvements` is a Sonic 3 & Knuckles disassembly-based project focused on gameplay, engine, and quality-of-life improvements implemented from Sonic Retro tutorials.

This repository is built on top of the Sonic 3 & Knuckles community disassembly and gradually ports fixes and features from the Sonic Retro hacking guides into one project.

See also:
- Sonic Retro Disassemblies: https://info.sonicretro.org/Disassemblies
- Sonic Retro How-To guides: https://info.sonicretro.org/SCHG_How-to:Guide

## Build options

Build the game with `buildS3Complete.bat` (or `lua buildS3Complete.lua`), which writes `sonic3k.bin`: Sonic 3 & Knuckles with the Sonic 3 data built in. The Sonic & Knuckles-only build was removed, and the standalone Sonic 3 build (`buildS3`, `s3.asm`) is kept as upstream left it. The switches `FixBugs` and `Feature*` are near the top of `sonic3k.asm`. Every `Feature*` switch is 1 by default; 0 restores the original behaviour of that addition. See the [modding reference](docs/modding.md) for the feature options, the ported bug fixes and the water settings table. Keep both values of every switch assemblable when changing shared routines.

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

Six-button controllers are detected on both ports. X, Y, Z, and Mode have separate held/pressed input states in `Ctrl_1_held_6B` / `Ctrl_1_pressed_6B` and their player-two equivalents; bit 7 of the held state indicates a detected six-button controller. The extra buttons currently have no gameplay bindings. Enable six-button controllers in your emulator to use these inputs.

Blue Knuckles (`Player_mode` 4) can be picked in the Level Select by pressing C until the character number reads 04. Every player mode of 3 or higher now follows Knuckles' route, level events and abilities, and character-indexed tables are clamped so modes above 3 can no longer read past their end (signpost, Slots, Special Stage results, Continue screen, ending). Only mode 3 loads Knuckles' red palette, so mode 4 keeps Sonic's colors. Super/Hyper Blue Knuckles uses Super Knuckles' palette cycle with the red and blue channels swapped and returns to his blue colors, underwater included, when the form ends.

## Disclaimer

Any and all content presented in this repository is presented for informational and educational purposes only.
Commercial usage is expressly prohibited. Sonic Retro claims no ownership of any code in these repositories.
You assume any and all responsibility for using this content responsibly. Sonic Retro claims no responsibility or warranty.
