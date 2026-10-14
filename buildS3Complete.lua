#!/usr/bin/env lua

--------------
-- Settings --
--------------

-- Set this to true to use a better compression algorithm for the sound driver.
-- Having this set to false will use an inferior compression algorithm that
-- results in an accurate ROM being produced.
local improved_sound_driver_compression = false

---------------------
-- End of settings --
---------------------

-------------------------------------
-- Actual build script begins here --
-------------------------------------

local common = require "build_tools.lua.common"

-- The MD Debugger is on unless MDDebugger is 0 in sonic3k.asm; its symbol
-- names can be left out with --no-symbols.
local include_symbols = true
for _, option in ipairs(arg) do
	if option == "--no-symbols" then
		include_symbols = false
	else
		io.stderr:write("Unknown build option: " .. option .. "\nUsage: buildS3Complete.lua [--no-symbols]\n")
		os.exit(1)
	end
end

-- Produce PCM and DPCM data.
common.convert_pcm_files_in_directory("Sound/PCM")
common.convert_dpcm_files_in_directory("Sound/DAC")

-- Build the ROM.
local compression = improved_sound_driver_compression and "kosinski-optimised" or "kosinski"
common.build_rom_and_handle_failure("sonic3k", "sonic3k", "-D Sonic3_Complete=1", "-p=FF -z=0," .. compression .. ",Size_of_Snd_driver_guess,before -z=1300," .. compression .. ",Size_of_Snd_driver2_guess,before", false, "https://github.com/sonicretro/skdisasm")

-- Binary resources are read by words or used as DMA sources, so each must start
-- at an even address. An odd one is an address error on real hardware.
local error_handler_end, debugger
for line in io.lines("sonic3k.lst") do
	local address, label = line:match("^%s*%d+/%s*(%x+) :%s+([%w_]+):%s+binclude")
	if address and tonumber(address, 16) % 2 == 1 then
		print(label .. " starts at an odd address ($" .. address .. "); put 'even' before it.")
		os.exit(1)
	end
	error_handler_end = error_handler_end or line:match("^%s*%(?%d*%)?%s*%d+/%s*(%x+) :%s+ErrorHandler_End:")
	debugger = debugger or line:match("^%s*%(?%d*%)?%s*%d+/%s*%x+ :%s+ErrorHandler:") ~= nil
end

if debugger and include_symbols then
	local convsym = os.getenv("CONVSYM")
	if not convsym then
		local tools = common.find_tools("ConvSym", "https://github.com/vladikcomper/md-modules/tree/master/utils/convsym", "https://github.com/oranguthang/sk_improvements", "convsym")
		if not tools then os.exit(1) end
		convsym = tools.convsym
	end
	local before = assert(io.open("sonic3k.bin", "rb"))
	local size_before = before:seek("end")
	before:close()
	-- The debugger finds its symbol table directly after its blob, and ConvSym
	-- appends the table to the end of the file, so the blob must end the file.
	if not error_handler_end or tonumber(error_handler_end, 16) ~= size_before then
		print(string.format("The MD Debugger blob ends at $%s, but the ROM is $%X bytes; symbols would be unreachable.", error_handler_end or "?", size_before))
		os.exit(1)
	end
	local shell_prefix = package.config:sub(1, 1) == "\\" and "call " or ""
	local ok = os.execute(shell_prefix .. '"' .. convsym .. '" sonic3k.lst sonic3k.bin -input as_lst -range 0 FFFFFF -exclude -filter "(z.+)|(Size_of_.+)|(PLCID_.+)|(PalID_.+)|(GameMode_.+)" -a')
	if not ok then os.exit(1) end
	local after = assert(io.open("sonic3k.bin", "rb"))
	local size_after = after:seek("end")
	after:close()
	if size_after <= size_before then
		print("ConvSym did not append the debugger symbol table.")
		os.exit(1)
	end
	print("Debugger symbol table: " .. (size_after - size_before) .. " bytes.")
end

-- Symbols must immediately follow the debugger blob. Pad only afterwards, with
-- $FF up to a power-of-two cartridge size (4 MiB, like the original game).
local rom = assert(io.open("sonic3k.bin", "ab"))
local size = assert(rom:seek("end"))
local padded_size = 0x100000
while padded_size < size do
	padded_size = padded_size * 2
end
assert(rom:write(string.rep(string.char(0xFF), padded_size - size)))
assert(rom:close())
print("ROM padding: " .. (padded_size - size) .. " bytes; final size: " .. padded_size .. " bytes.")

-- Correct the ROM's header with a proper checksum and end-of-ROM value.
common.fix_header("sonic3k.bin")

-- A successful build; we can quit now.
common.exit()
