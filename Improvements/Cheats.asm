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
