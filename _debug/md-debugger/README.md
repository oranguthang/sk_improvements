# MD Debugger error screen

`buildS3Complete` produces `sonic3k.bin` with the MD Debugger 2.6 exception screen and a ConvSym DEB2 symbol table (about 420 KB). The ROM is padded with `$FF` after the symbols to a power-of-two cartridge size, 4 MiB like the original game, and the checksum and ROM-end header are fixed after padding. No intentional crash is present in gameplay code.

The exception screen shows the error, the faulting address and PC with their symbols, D0-D7, A0-A6, SP, SR, USP and the stack. A opens address-register symbols, B opens the backtrace, and Start returns to the exception screen. Reserved vectors go to `ErrorExcept`; unexpected interrupts and TRAPs go through `ErrorTrap`, which reports them on the same screen. This diagnostic screen is independent of the in-game Debug Mode. Upstream documentation: https://github.com/vladikcomper/md-modules/tree/master/modules/errorhandler

The debugger also provides `RaiseError`, `assert`, `Console` and `KDebug` macros (see `Debugger.asm` and the upstream documentation) for diagnostics in new code.

## Layout rule

`_debug/Debugger blob.asm` includes `ErrorHandler.asm` after the Sonic 3 lock-on data, at the very end of `sonic3k.asm`, and `buildS3Complete.lua` appends the symbol table directly after it at `ErrorHandler_End`; the debugger looks for the table right behind its own blob. Never put data after that include: add new code and resources above it. The assembler stops if `EndOfROM` is not `ErrorHandler_End`, and the build script stops if the assembled ROM does not end there.

The blob sits above $200000, the range that SRAM replaces while `SRAM_access_flag` is set. The game only sets it while it reads or writes a save; an exception inside that window could not reach the debugger.

The Sonic & Knuckles-only build was removed because its 2 MiB, which a lock-on cartridge must follow at $200000, had only about 3 KB free.

## Building without the symbol table

Symbols are enabled by default. To omit them:

```sh
build_tools/Lua/lua.exe buildS3Complete.lua --no-symbols
```

The numeric PC, register and stack display stays; function names and symbolic backtrace labels are unavailable, and ConvSym is not used. No DEB2 table is appended: the debugger detects the missing signature and falls back to numeric addresses. Padding must always follow any symbol table, never separate it from the debugger blob.

Setting `MDDebugger = 0` in `sonic3k.asm` restores the original behaviour, in which `ErrorTrap` falls through into `EntryPoint` and restarts the game, without the debugger code.

## Tools and platforms

Builds with symbols need ConvSym 2.12.1 in addition to the existing assembler and p2bin. Official Windows x86_64 and Linux x86_64 executables are bundled in `build_tools/Windows-x86/` and `build_tools/Linux-x86_64/`; other platforms can build ConvSym from https://github.com/vladikcomper/md-modules/tree/master/utils/convsym and either place it in the appropriate `build_tools/<platform>/` directory or set the `CONVSYM` environment variable to its path. Linux users may need `chmod +x build_tools/Linux-x86_64/convsym` after extracting a ZIP.

Official release: https://github.com/vladikcomper/md-modules/releases/tag/v.2.6-mddebugger

Assembly bundles and ConvSym binaries are redistributed under the included MIT license, copyright Vladikcomper. The ErrorHandler blob is unchanged from the `as` release bundle. Configuration is in `_debug/md-debugger/Debugger.asm`; SR/USP display is enabled for this project.
