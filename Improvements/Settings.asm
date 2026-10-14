; ---------------------------------------------------------------------------
; Settings SRAM record, as in s1_improvements and s2_improvements.
; It sits in SRAM_settings, the $15 logical bytes after SRAM_SKgame_backup
; that the game never reads or writes, so the save files stay untouched.
; Logical byte N of the record is at SRAM_settings+2*N (odd-byte SRAM).
; 00..03 "S3DV", 04 version, 05 payload length, then the settings in
; Settings_Fields order, then an additive big-endian checksum of everything
; before it. Only configuration is saved, never progress.
; A write invalidates the signature first and commits its first byte last.
; This code runs with SRAM mapped over $200000, so it must stay below it.
; ---------------------------------------------------------------------------
settings_sram_version = 1
settings_sram_payload = (Settings_Fields_End-Settings_Fields)/2
settings_sram_size = 6+settings_sram_payload+2

; ---------------------------------------------------------------------------
; Values used on a cold boot without a valid record
; ---------------------------------------------------------------------------

Settings_Defaults:
		clr.w	(Level_select_flag).w		; and Slow_motion_flag
		clr.w	(Debug_cheat_flag).w
		clr.b	(Cheat_all_emeralds).w
		move.b	#50,(Cheat_super_rings).w
		move.b	#1,(Cheat_ring_drain).w
		clr.b	(Cheat_god_mode).w
		clr.w	(Player_option).w
		rts
; End of function Settings_Defaults

; ---------------------------------------------------------------------------
; Clamps every setting, then resolves the zero rings / ring drain pair
; ---------------------------------------------------------------------------

Settings_Normalize:
		movem.l	d0-d1/a0-a1,-(sp)
		lea	Settings_BoolFields(pc),a0
		moveq	#(Settings_BoolFields_End-Settings_BoolFields)/2-1,d1

.bools:
		movea.w	(a0)+,a1
		cmpi.b	#1,(a1)
		bls.s	.nextBool
		clr.b	(a1)

.nextBool:
		dbf	d1,.bools
		move.b	(Level_select_flag).w,(Slow_motion_flag).w	; the game sets both together
		move.b	(Debug_cheat_flag).w,(Debug_cheat_flag+1).w	; as the game's debug code does
		move.b	(Cheat_super_rings).w,d0
		beq.s	.noDrain
		cmpi.b	#10,d0
		beq.s	.character
		cmpi.b	#50,d0
		beq.s	.character
		move.b	#50,(Cheat_super_rings).w
		bra.s	.character
; ---------------------------------------------------------------------------

.noDrain:
		clr.b	(Cheat_ring_drain).w		; nothing to drain without a ring cost

.character:
		clr.b	(Player_option).w		; the word keeps its value in the low byte
		cmpi.b	#Settings_PlayerOptions,(Player_option+1).w
		blo.s	.done
		clr.b	(Player_option+1).w

.done:
		movem.l	(sp)+,d0-d1/a0-a1
		rts
; End of function Settings_Normalize

	if FeatureBlueKnuckles
Settings_PlayerOptions = 5
	else
Settings_PlayerOptions = 4
	endif

Settings_BoolFields:
		dc.w	Level_select_flag&$FFFF, Debug_cheat_flag&$FFFF
		dc.w	Cheat_all_emeralds&$FFFF, Cheat_ring_drain&$FFFF, Cheat_god_mode&$FFFF
Settings_BoolFields_End:

; RAM byte of each saved setting, in record order. Append new fields at the end
; and raise settings_sram_version.
Settings_Fields:
		dc.w	Level_select_flag&$FFFF		; Level Select and CHEATS unlocked
		dc.w	Debug_cheat_flag&$FFFF		; DEBUG
		dc.w	Cheat_all_emeralds&$FFFF	; ALL EMERALDS
		dc.w	Cheat_super_rings&$FFFF		; SUPER RINGS
		dc.w	Cheat_ring_drain&$FFFF		; RING DRAIN
		dc.w	Cheat_god_mode&$FFFF		; GOD MODE
		dc.w	(Player_option+1)&$FFFF		; Level Select character
Settings_Fields_End:

; d0.w = sum of the bytes before the checksum at a0. Clobbers d1/a0.
Settings_Checksum:
		moveq	#0,d0
		moveq	#settings_sram_size-2-1,d1

.loop:
		add.b	(a0)+,d0
		bcc.s	.next
		addi.w	#$100,d0			; carry from the low byte into the high byte

.next:
		dbf	d1,.loop
		rts
; End of function Settings_Checksum

; ---------------------------------------------------------------------------
; Loads the record into RAM, or the defaults if it is missing or invalid
; ---------------------------------------------------------------------------

Settings_Load:
		movem.l	d0-d2/a0-a2,-(sp)
		bsr.w	Settings_Defaults
		suba.w	#(settings_sram_size+1)&~1,sp
		lea	(SRAM_settings).l,a0
		movea.l	sp,a1
		moveq	#settings_sram_size-1,d1
		move.w	sr,-(sp)
		ori.w	#$700,sr			; no interrupts while SRAM is mapped
		move.b	#1,(SRAM_access_flag).l

.read:
		move.b	(a0),(a1)+
		addq.l	#2,a0				; odd-byte SRAM
		dbf	d1,.read
		move.b	#0,(SRAM_access_flag).l
		move.w	(sp)+,sr
		cmpi.l	#'S3DV',(sp)
		bne.s	.done
		cmpi.b	#settings_sram_version,4(sp)
		bne.s	.done
		cmpi.b	#settings_sram_payload,5(sp)
		bne.s	.done
		movea.l	sp,a0
		bsr.s	Settings_Checksum
		cmp.b	settings_sram_size-1(sp),d0
		bne.s	.done
		lsr.w	#8,d0
		cmp.b	settings_sram_size-2(sp),d0
		bne.s	.done
		lea	6(sp),a0
		lea	Settings_Fields(pc),a2
		moveq	#settings_sram_payload-1,d1

.fields:
		movea.w	(a2)+,a1
		move.b	(a0)+,(a1)
		dbf	d1,.fields

.done:
		bsr.w	Settings_Normalize
		adda.w	#(settings_sram_size+1)&~1,sp
		movem.l	(sp)+,d0-d2/a0-a2
		rts
; End of function Settings_Load

; ---------------------------------------------------------------------------
; Writes the current settings to SRAM
; ---------------------------------------------------------------------------

Settings_Save:
		movem.l	d0-d2/a0-a2,-(sp)
		bsr.w	Settings_Normalize
		suba.w	#(settings_sram_size+1)&~1,sp
		move.l	#'S3DV',(sp)
		move.b	#settings_sram_version,4(sp)
		move.b	#settings_sram_payload,5(sp)
		lea	6(sp),a0
		lea	Settings_Fields(pc),a2
		moveq	#settings_sram_payload-1,d1

.fields:
		movea.w	(a2)+,a1
		move.b	(a1),(a0)+
		dbf	d1,.fields
		movea.l	sp,a0
		bsr.w	Settings_Checksum
		move.b	d0,settings_sram_size-1(sp)
		lsr.w	#8,d0
		move.b	d0,settings_sram_size-2(sp)
		lea	(SRAM_settings).l,a0
		movea.l	sp,a1
		moveq	#settings_sram_size-2,d1
		move.w	sr,-(sp)
		ori.w	#$700,sr
		move.b	#1,(SRAM_access_flag).l
		clr.b	(a0)				; invalid until every other byte is written
		addq.l	#1,a1
		addq.l	#2,a0

.write:
		move.b	(a1)+,(a0)
		addq.l	#2,a0
		dbf	d1,.write
		move.b	#'S',(SRAM_settings).l		; commit the record last
		move.b	#0,(SRAM_access_flag).l
		move.w	(sp)+,sr
		adda.w	#(settings_sram_size+1)&~1,sp
		movem.l	(sp)+,d0-d2/a0-a2
		rts
; End of function Settings_Save

Settings_End:
	if MOMPASS>1
		if settings_sram_size>(SRAM_end-SRAM_settings)/2
			error "The settings record does not fit in SRAM_settings"
		endif
		if Settings_End>=$200000
			fatal "The settings code must stay below the SRAM window at $200000."
		endif
	endif
