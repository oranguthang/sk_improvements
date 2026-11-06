; Shared, physical-player-one Super/Hyper controls.
; Buttons 4..6 are A/B/C; bit 0 remembers an eligible jumping start and
; bit 7 consumes a completed combo until all three buttons are released.
Player_SuperCombo:
	if FeatureSuperToggle=0
		moveq	#0,d0
		rts
	endif
		cmpa.w	#Player_1,a0
		bne.w	.none
		tst.w	(Demo_mode_flag).w
		bne.w	.reset
		tst.w	(Competition_mode).w
		bne.w	.reset
		btst	#Status_InAir,status(a0)
		beq.w	.reset
		tst.b	object_control(a0)
		bne.w	.reset
		move.b	(Ctrl_1_held_logical).w,d2
		andi.b	#button_A_mask|button_B_mask|button_C_mask,d2
		tst.b	(Super_combo_buttons).w
		bpl.s	.window
		tst.b	d2
		beq.w	.reset
		bra.w	.none
.window:
		tst.b	(Super_combo_timer).w
		beq.s	.presses
		subq.b	#1,(Super_combo_timer).w
		bne.s	.presses
		clr.b	(Super_combo_buttons).w
.presses:
		move.b	(Ctrl_1_pressed_logical).w,d1
		andi.b	#button_A_mask|button_B_mask|button_C_mask,d1
		beq.w	.none
		tst.b	(Super_combo_timer).w
		bne.s	.merge
		move.b	#10,(Super_combo_timer).w
		clr.b	(Super_combo_buttons).w
		tst.b	jumping(a0)
		beq.s	.merge
		tst.b	double_jump_flag(a0)
		bne.s	.merge
		bset	#0,(Super_combo_buttons).w
.merge:
		or.b	d1,(Super_combo_buttons).w
		cmpi.w	#2,(Player_mode).w
		bhs.s	.freshOnly
		or.b	d2,(Super_combo_buttons).w	; Sonic may hold a jump button
.freshOnly:
		move.b	(Super_combo_buttons).w,d0
		andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
		move.b	d0,d1
		subq.b	#1,d1
		and.b	d0,d1
		beq.w	.none			; fewer than two distinct buttons
		tst.b	(Super_Sonic_Knux_flag).w
		bne.w	.revert
		tst.b	(Super_Tails_flag).w
		bne.w	.revert
		btst	#0,(Super_combo_buttons).w
		beq.w	.consumeOnly		; later flight/glide combos only revert
		jsr	(Cheat_CmpSuperEmeralds).l
		bhs.s	.emeralds
		jsr	(Cheat_CmpChaosEmeralds).l
		blo.w	.consumeOnly
		tst.b	(Cheat_all_emeralds).w
		bne.s	.emeralds
		tst.b	(Emeralds_converted_flag).w
		bne.w	.consumeOnly
.emeralds:
		jsr	(Cheat_CmpSuperRings).l
		blo.w	.consumeOnly
		tst.b	(Update_HUD_timer).w
		beq.w	.consumeOnly
		clr.b	double_jump_flag(a0)
		cmpi.w	#2,(Player_mode).w
		beq.s	.tails
		bhi.s	.knuckles
		jsr	(Sonic_Transform).l
		bra.s	.handled
.tails:
		jsr	(Tails_Transform).l
		bra.s	.handled
.knuckles:
		jsr	(Knux_Transform).l
		bra.s	.handled
.revert:
		jsr	(SonicKnux_SuperHyper.revertToNormal).l
		; End temporary invincibility directly; using timer=1 would defer
		; recovery and could restart a level/boss song when no theme played.
		clr.b	invincibility_timer(a0)
		bclr	#Status_Invincible,status_secondary(a0)
.handled:
		move.b	#$80,(Super_combo_buttons).w
		clr.b	(Super_combo_timer).w
		moveq	#1,d0
		rts
.consumeOnly:
		move.b	#$80,(Super_combo_buttons).w
		clr.b	(Super_combo_timer).w
.none:
		moveq	#0,d0
		rts
.reset:
		clr.b	(Super_combo_buttons).w
		clr.b	(Super_combo_timer).w
		bra.s	.none


; Both ordinary deaths and drowning enter here before the death pose is drawn.
Super_ResetOnDeath:
		cmpa.w	#Player_1,a0
		bne.s	.return
		tst.b	(Super_Sonic_Knux_flag).w
		bne.s	.reset
		tst.b	(Super_Tails_flag).w
		bne.s	.reset
		tst.b	(Super_palette_status).w
		beq.s	.return
.reset:
		movem.l	d0/a0-a2/a4,-(sp)
		lea	(Max_speed).w,a4
		cmpi.b	#1,character_id(a0)
		bne.s	.speed
		lea	(Max_speed_P2).w,a4
		move.b	#-1,(Player_prev_frame_P2).w
.speed:
		jsr	(SonicKnux_SuperHyper.revertToNormal).l
		clr.b	object_control(a0)
		clr.b	invincibility_timer(a0)
		bclr	#Status_Invincible,status_secondary(a0)
		clr.w	(Super_frame_count).w
		clr.w	(Palette_frame).w	; restore the normal palettes in one step
		clr.b	(Palette_timer).w
		jsr	(SuperHyper_PalCycle).l
		movem.l	(sp)+,d0/a0-a2/a4
.return:
		rts

Player_DebugButton:
		movem.l	d0,-(sp)
		cmpa.w	#Player_1,a0
		bne.s	.none
		btst	#button_B,(Ctrl_1_pressed).w
		beq.s	.none
	if FeatureSuperToggle
		cmpi.b	#6,routine(a0)
		bhs.s	.pressed				; death and drowning have no Super combo
		btst	#Status_InAir,status(a0)
		beq.s	.pressed
		move.b	(Ctrl_1).w,d0
		andi.b	#button_A_mask|button_C_mask,d0
		bne.s	.none
		move.b	(Super_combo_buttons).w,d0
		andi.b	#button_A_mask|button_C_mask,d0
		bne.s	.none
	endif
.pressed:
		moveq	#1,d0
		movem.l	(sp)+,d0
		rts
.none:
		moveq	#0,d0
		movem.l	(sp)+,d0
		rts
