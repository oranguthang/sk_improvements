#!/usr/bin/env lua

local clownmd5 = require "build_tools.lua.clownmd5"

-- Prevent build.lua's calls to os.exit from terminating the program.
local os_exit = os.exit
os.exit = coroutine.yield

-- Build the ROMs.
local co

-- Sonic 3
co = coroutine.create(function() dofile("buildS3.lua") end)
local _, _, abort_s3 = assert(coroutine.resume(co))

-- Restore os.exit back to normal.
os.exit = os_exit

if not abort_s3 then
	-- Hash the ROMs.
	local s3_hash = clownmd5.HashFile("s3built.bin")

	-- Verify the hashes.
	print "-------------------------------------------------------------"

	if s3_hash == "\xD7\x24\xEA\x4D\xD4\x17\xFE\x33\x0C\x9D\xCF\xD9\x55\xC5\x96\xB2" then
		print "Sonic 3 ROM is bit-perfect (with USA version)."
	else
		print "Sonic 3 ROM is NOT bit-perfect (with USA version)!"
	end
end
