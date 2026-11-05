; Player selection, independent of the route character ID.
ApplyPlayerOption:
		clr.b	(Knuckles_Tails_flag).w
		move.w	(Player_option).w,(Player_mode).w
		cmpi.w	#5,(Player_mode).w
		bne.s	.return
		move.w	#3,(Player_mode).w
		move.b	#1,(Knuckles_Tails_flag).w
.return:
		rts

; Called after the entrance objects run. Leave the partner slot empty while
; they are positioning or moving Knuckles, as in Knuckles Alone.
SpawnKnucklesPartner:
		tst.b	(Level_started_flag).w
		beq.s	.return
		tst.b	(Ctrl_1_locked).w
		bne.s	.return
		tst.b	(Player_1+object_control).w
		bne.s	.return
		cmpi.b	#2,(Player_1+routine).w
		bne.s	.return
		clr.b	(Knuckles_partner_pending).w
		move.l	#Obj_Tails,(Player_2).w
		move.w	#$7F00,(Player_2+x_pos).w	; wait off-screen for the normal AI fly-in
		move.b	#$81,(Player_2+object_control).w
		move.l	#Obj_DashDust,(Dust_P2).w
		clr.w	(Tails_CPU_routine).w
.return:
		rts

SaveMenu_CharacterFrame:
		cmpi.w	#5,d0
		bne.s	.normal
		moveq	#36,d0
		rts
.normal:
		addq.w	#4,d0
		rts

LevelSelect_DrawCharacterName:
		lea	(VDP_data_port).l,a6
		move.l	#vdpComm(VRAM_Plane_A_Name_Table+$19C,VRAM,WRITE),4(a6)
		move.l	#0,(a6)		; erase the old numeric character field
		move.l	#vdpComm(VRAM_Plane_A_Name_Table+planeLoc(64,22,25),VRAM,WRITE),4(a6)
		move.w	(Player_option).w,d0
		cmpi.w	#6,d0
		blo.s	.valid
		moveq	#0,d0
.valid:
		mulu.w	#15,d0
		lea	CharacterNames(pc),a1
		adda.w	d0,a1
		moveq	#15-1,d2
		jmp	(CheatsPage_DrawText).l

		save
		codepage LEVELSELECT
CharacterNames:
		dc.b "SONIC AND TAILS"
		dc.b "SONIC ALONE    "
		dc.b "TAILS ALONE    "
		dc.b "KNUCKLES ALONE "
		dc.b "BLUE KNUCKLES  "
		dc.b "KNUX AND TAILS "
		restore
		even

; AI-only held input for the scrolling AIZ2 bombing passage.
Tails_FollowBombingRun:
		cmpi.w	#1,(Current_zone_and_act).w
		bne.s	.return
		cmpi.w	#20,(Events_routine_bg).w
		bne.s	.return
		tst.w	(Events_routine_fg).w
		bne.s	.return
		tst.w	(Tails_CPU_idle_timer).w
		bne.s	.return
		cmpa.w	#Player_1,a0
		beq.s	.return
		tst.w	(Demo_mode_flag).w
		bne.s	.return
		andi.w	#~((button_left_mask|button_right_mask)<<8),d1
		ori.w	#button_right_mask<<8,d1
.return:
		rts

; A sign created without its boss controller (debug) must load its own
; supporting graphics as well as its normal per-frame DPLC.
Signpost_DebugArt:
		tst.b	(Debug_mode_flag).w
		beq.s	.return
		movem.l	d0-d6/a1-a3,-(sp)
		lea	(PLC_EndSignStuff).l,a1
		jsr	(Load_PLC_Raw).l
		movem.l	(sp)+,d0-d6/a1-a3
.return:
		rts
