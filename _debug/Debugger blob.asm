; ---------------------------------------------------------------------------
; The MD Debugger blob. The debugger reads its symbol table from the address
; directly after it, ErrorHandler_End, where the build scripts put the ConvSym
; table: into the padding before $200000 in the Sonic & Knuckles build, or at
; the end of the file in the Sonic 3 & Knuckles build. Add new ROM data above
; the place this file is included.
; ---------------------------------------------------------------------------
		even
	if MDDebugger
		include "_debug/md-debugger/ErrorHandler.asm"
	endif
ErrorHandler_End:
