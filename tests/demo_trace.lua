-- Plays the title screen's demo cycle in Gens (gens_automation) and logs one
-- line per game frame of every demo. Run by tests/check_demo_cycle.py, which
-- passes these environment variables:
--   SK_OUT     log file
--   SK_SYMS    "name=HEX,..." RAM and ROM addresses from sonic3k.lst
--   SK_FRAMES  emulated frames to play at most
--   SK_DEMOS   demos to play
-- The line is written from a hook on LevelLoop, where the previous frame's
-- logic is complete, so lag frames do not shift what is read.

local log = assert(io.open(os.getenv("SK_OUT"), "w"))
local S = {}
for name, value in string.gmatch(os.getenv("SK_SYMS"), "([%w_]+)=(%x+)") do
	S[name] = tonumber(value, 16)
end
local FRAMES = tonumber(os.getenv("SK_FRAMES") or "40000")
local DEMOS = tonumber(os.getenv("SK_DEMOS") or "8")
local GAMEMODE_DEMO = 8
local P1, P2 = S.Player_1, S.Player_2

local demo, inDemo = 0, false
memory.registerexec(S.LevelLoop, function()
	if not inDemo then return end
	log:write(string.format("T %d %04X %04X %04X %04X %04X %04X %02X %02X %04X %04X %04X %04X\n",
		demo, memory.readword(S.Current_zone_and_act), memory.readword(S.Level_frame_counter),
		memory.readword(P1 + 0x10), memory.readword(P1 + 0x14), memory.readword(P1 + 0x18), memory.readword(P1 + 0x1A),
		memory.readbyte(P1 + 0x20), memory.readbyte(P1 + 0x05), memory.readword(S.Ring_count),
		memory.readword(S.Camera_X_pos), memory.readword(P2 + 0x10), memory.readword(P2 + 0x14)))
end)

for frame = 1, FRAMES do
	gens.frameadvance()
	local mode = memory.readbyte(S.Game_mode)
	if mode == GAMEMODE_DEMO and not inDemo then
		demo = demo + 1
		inDemo = true
		log:write(string.format("D %d start %d zone %04X\n", demo, frame, memory.readword(S.Current_zone_and_act)))
	elseif mode ~= GAMEMODE_DEMO and inDemo then
		inDemo = false
		log:write(string.format("D %d end %d\n", demo, frame))
		if demo >= DEMOS then break end
	end
end
log:write("END\n")
log:close()
