; ---------------------------------------------------------------------------
; Cheats: the title unlock code. The settings are saved by Settings.asm.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Title code Up, Down, Down, Down, Left, Right (as in s1_improvements and
; s2_improvements) unlocks the Level Select and its CHEATS page, like the
; game's own code on the Angel Island vine. Called every title frame.
; ---------------------------------------------------------------------------

TitleUnlockCheat:
		move.b	(Ctrl_1_pressed).w,d1
		andi.b	#button_up_mask|button_down_mask|button_left_mask|button_right_mask,d1
		beq.s	.return
		lea	TitleUnlockCheat_Buttons(pc),a1
		move.w	(Level_select_cheat_counter).w,d0
		cmp.b	(a1,d0.w),d1
		bne.s	.reset
		addq.w	#1,(Level_select_cheat_counter).w
		tst.b	1(a1,d0.w)			; was that the last button?
		bne.s	.return
		move.w	#$101,(Level_select_flag).w	; and Slow_motion_flag, as the game's code does
		jsr	(Settings_Save).l
		moveq	#signextendB(sfx_RingRight),d0	; the game's cheat sound
		jsr	(Play_SFX).l

.reset:
		clr.w	(Level_select_cheat_counter).w

.return:
		rts
; End of function TitleUnlockCheat

TitleUnlockCheat_Buttons:
		dc.b	button_up_mask, button_down_mask, button_down_mask, button_down_mask
		dc.b	button_left_mask, button_right_mask, 0
		even

; ---------------------------------------------------------------------------
; CHEATS page of the Level Select (Start on the CHEATS item).
; Up/Down select, Left/Right/A/B/C change, Start goes back to the level list.
; Every change is saved in SRAM at once. The selected row is kept in the
; unused Debug_mode_cheat_counter.
; ---------------------------------------------------------------------------
cheats_row_emeralds = 0
cheats_row_debug = 1
cheats_row_rings = 2
cheats_row_drain = 3
cheats_row_god = 4
cheats_rows = 5

cheats_header_line = 4
cheats_first_line = 8			; rows are two lines apart
cheats_label_col = 6
cheats_value_col = 30
cheats_label_len = 21
cheats_value_len = 3

LevelSelect_Cheats:
		move	#$2700,sr
		bsr.w	CheatsPage_Clear
		bsr.w	CheatsPage_Draw
		move	#$2300,sr

.loop:
		move.b	#VInt_ID_16,(V_int_routine).w
		jsr	(Wait_VSync).l
		move	#$2700,sr
		bsr.w	CheatsPage_Controls
		move.w	d0,-(sp)
		bsr.w	CheatsPage_Draw
		move	#$2300,sr
		lea	(AniPLC_SONICMILES).l,a2
		jsr	(AnimateTiles_DoAniPLC).l
		tst.w	(sp)+				; leave the page?
		beq.s	.loop
		jsr	(Settings_Save).l
		move	#$2700,sr
		lea	(RAM_start).l,a1		; the Level Select's own plane map is still there
		move.l	#vdpComm(VRAM_Plane_A_Name_Table,VRAM,WRITE),d0
		moveq	#40-1,d1
		moveq	#28-1,d2
		jsr	(Plane_Map_To_VRAM).l
		moveq	#palette_line_0,d3
		jsr	(LevelSelect_DrawSoundNumber).l
		move	#$2300,sr
		rts
; End of function LevelSelect_Cheats

; Fills plane A with blank tiles.
CheatsPage_Clear:
		lea	(VDP_data_port).l,a6
		move.l	#vdpComm(VRAM_Plane_A_Name_Table,VRAM,WRITE),VDP_control_port-VDP_data_port(a6)
		moveq	#0,d0
		move.w	#64*32/2-1,d1

.loop:
		move.l	d0,(a6)
		dbf	d1,.loop
		rts
; End of function CheatsPage_Clear

; ---------------------------------------------------------------------------
; Returns d0 = 1 to leave the page, otherwise 0
; ---------------------------------------------------------------------------

CheatsPage_Controls:
		move.b	(Ctrl_1_pressed).w,d1
		andi.b	#button_up_mask|button_down_mask,d1
		bne.s	.upDown
		subq.w	#1,(Level_select_repeat).w	; held Up/Down repeats like the level list
		bpl.s	.change

.upDown:
		move.w	#$B,(Level_select_repeat).w
		move.b	(Ctrl_1).w,d1
		andi.b	#button_up_mask|button_down_mask,d1
		beq.s	.change
		move.w	(Debug_mode_cheat_counter).w,d0	; the selected row
		btst	#button_up,d1
		beq.s	.down
		subq.w	#1,d0
		bpl.s	.down
		moveq	#cheats_rows-1,d0

.down:
		btst	#button_down,d1
		beq.s	.setRow
		addq.w	#1,d0
		cmpi.w	#cheats_rows,d0
		blo.s	.setRow
		moveq	#0,d0

.setRow:
		move.w	d0,(Debug_mode_cheat_counter).w
		bra.w	.stay
; ---------------------------------------------------------------------------

.change:
		move.b	(Ctrl_1_pressed).w,d1
		btst	#button_start,d1
		bne.w	.leave
		andi.b	#button_left_mask|button_right_mask|button_A_mask|button_B_mask|button_C_mask,d1
		beq.w	.stay
		move.w	(Debug_mode_cheat_counter).w,d0
		cmpi.w	#cheats_rows,d0
		blo.s	.rowOk
		moveq	#0,d0
		move.w	d0,(Debug_mode_cheat_counter).w

.rowOk:
		cmpi.w	#cheats_row_rings,d0
		beq.s	.rings
		add.w	d0,d0
		lea	CheatsPage_Vars(pc),a1
		movea.w	(a1,d0.w),a1
		eori.b	#1,(a1)				; ON/OFF rows
		cmpi.w	#cheats_row_debug*2,d0
		bne.s	.notDebug
		move.b	(a1),1(a1)			; the game sets Debug_cheat_flag as a word

.notDebug:
		cmpi.w	#cheats_row_drain*2,d0
		bne.s	.save
		tst.b	(Cheat_ring_drain).w
		beq.s	.save
		tst.b	(Cheat_super_rings).w
		bne.s	.save
		move.b	#10,(Cheat_super_rings).w	; a drain needs a ring cost: 0 becomes 10
		bra.s	.save
; ---------------------------------------------------------------------------

.rings:
		lea	CheatsPage_RingSteps(pc),a1
		move.b	(Cheat_super_rings).w,d0
		moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2

.findStep:
		cmp.b	(a1,d2.w),d0
		beq.s	.stepFound
		dbf	d2,.findStep
		moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2

.stepFound:
		btst	#button_left,d1
		beq.s	.nextStep
		subq.w	#1,d2
		bpl.s	.setStep
		moveq	#CheatsPage_RingSteps_End-CheatsPage_RingSteps-1,d2
		bra.s	.setStep
; ---------------------------------------------------------------------------

.nextStep:
		addq.w	#1,d2
		cmpi.w	#CheatsPage_RingSteps_End-CheatsPage_RingSteps,d2
		blo.s	.setStep
		moveq	#0,d2

.setStep:
		move.b	(a1,d2.w),(Cheat_super_rings).w

.save:
		moveq	#signextendB(sfx_Switch),d0
		jsr	(Play_SFX).l
		jsr	(Settings_Save).l		; also turns the drain off at 0 rings

.stay:
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

.leave:
		moveq	#1,d0
		rts
; End of function CheatsPage_Controls

; RAM byte of each row (SUPER RINGS is handled separately)
CheatsPage_Vars:
		dc.w	Cheat_all_emeralds&$FFFF
		dc.w	Debug_cheat_flag&$FFFF
		dc.w	Cheat_super_rings&$FFFF
		dc.w	Cheat_ring_drain&$FFFF
		dc.w	Cheat_god_mode&$FFFF
CheatsPage_Vars_End:

CheatsPage_RingSteps:
		dc.b	0, 10, 50
CheatsPage_RingSteps_End:
		even

; ---------------------------------------------------------------------------
; Draws the header, every row (the selected one in yellow) and the hint
; ---------------------------------------------------------------------------

CheatsPage_Draw:
		lea	(VDP_data_port).l,a6
		move.l	#vdpComm(VRAM_Plane_A_Name_Table+(cheats_header_line*$80)+((40-6)/2*2),VRAM,WRITE),VDP_control_port-VDP_data_port(a6)
		lea	CheatsPage_Header(pc),a1
		move.w	#palette_line_3,d3
		moveq	#6-1,d2
		bsr.w	CheatsPage_DrawText
		lea	CheatsPage_Labels(pc),a1
		move.l	#vdpComm(VRAM_Plane_A_Name_Table+(cheats_first_line*$80)+(cheats_label_col*2),VRAM,WRITE),d4
		moveq	#0,d1

.row:
		move.l	d4,VDP_control_port-VDP_data_port(a6)
		moveq	#palette_line_0,d3
		cmp.w	(Debug_mode_cheat_counter).w,d1
		bne.s	.normal
		move.w	#palette_line_3,d3

.normal:
		moveq	#cheats_label_len-1,d2
		bsr.w	CheatsPage_DrawText
		move.l	a1,-(sp)
		move.l	d4,d0
		addi.l	#((cheats_value_col-cheats_label_col)*2)<<16,d0
		move.l	d0,VDP_control_port-VDP_data_port(a6)
		bsr.s	CheatsPage_GetValue
		moveq	#cheats_value_len-1,d2
		bsr.w	CheatsPage_DrawText
		movea.l	(sp)+,a1
		addi.l	#($80*2)<<16,d4			; two lines down
		addq.w	#1,d1
		cmpi.w	#cheats_rows,d1
		blo.s	.row
		move.l	#vdpComm(VRAM_Plane_A_Name_Table+((cheats_first_line+cheats_rows*2+2)*$80)+(cheats_label_col*2),VRAM,WRITE),VDP_control_port-VDP_data_port(a6)
		lea	CheatsPage_Hint(pc),a1
		moveq	#palette_line_0,d3
		moveq	#CheatsPage_Hint_End-CheatsPage_Hint-1,d2
		bra.w	CheatsPage_DrawText
; End of function CheatsPage_Draw

; d1.w = row; returns a1 = its 3-character value
CheatsPage_GetValue:
		cmpi.w	#cheats_row_rings,d1
		beq.s	.rings
		move.w	d1,d0
		add.w	d0,d0
		lea	CheatsPage_Vars(pc),a1
		movea.w	(a1,d0.w),a1
		moveq	#1,d0
		and.b	(a1),d0				; 0 = "OFF", 1 = " ON"
		bra.s	.text
; ---------------------------------------------------------------------------

.rings:
		moveq	#2,d0				; "  0"
		move.b	(Cheat_super_rings).w,d2
		beq.s	.text
		moveq	#3,d0				; " 10"
		cmpi.b	#10,d2
		beq.s	.text
		moveq	#4,d0				; " 50"

.text:
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		lea	CheatsPage_Values(pc,d0.w),a1
		rts
; End of function CheatsPage_GetValue

; a1 = text, d2 = length-1, d3 = palette line, a6 = VDP data port (address set)
CheatsPage_DrawText:
		moveq	#0,d0
		move.b	(a1)+,d0
		beq.s	.space				; the blank tile stays on palette line 0
		add.w	d3,d0

.space:
		move.w	d0,(a6)
		dbf	d2,CheatsPage_DrawText
		rts
; End of function CheatsPage_DrawText

		save
		codepage	LEVELSELECT		; the Level Select font
CheatsPage_Values:
		dc.b	"OFF"	; 0
		dc.b	" ON"	; 1
		dc.b	"  0"	; 2
		dc.b	" 10"	; 3
		dc.b	" 50"	; 4
CheatsPage_Header:
		dc.b	"CHEATS"
CheatsPage_Labels:
		dc.b	"ALL EMERALDS         "
		dc.b	"DEBUG                "
		dc.b	"SUPER RINGS          "
		dc.b	"RING DRAIN           "
		dc.b	"GOD MODE             "
CheatsPage_Labels_End:
CheatsPage_Hint:
		dc.b	"START: BACK"
CheatsPage_Hint_End:
LevelSelect_CheatsItemText:		; the CHEATS item of the level list
		dc.b	"CHEATS"
LevelSelect_CheatsItemText_End:
		restore
		even

	if (CheatsPage_Labels_End-CheatsPage_Labels)<>cheats_rows*cheats_label_len
		error "CheatsPage_Labels needs one label of cheats_label_len characters per row"
	endif
	if (CheatsPage_Vars_End-CheatsPage_Vars)<>cheats_rows*2
		error "CheatsPage_Vars needs one entry per row"
	endif
