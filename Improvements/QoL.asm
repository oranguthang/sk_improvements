; ---------------------------------------------------------------------------
; Small quality-of-life features, each behind its Feature* switch.
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; FeatureExtraLives: a life for every 100 rings, as in s1_improvements and
; s2_improvements. Bits 1-7 of Extra_life_flags(_P2) then count the hundreds
; already rewarded (bit 0 stays the Slots bonus continue). Losing the rings
; clears the flags, so the next 100 rings give another life.
; Returns Z=0 when a life is due (and counts it). No registers change.
; ---------------------------------------------------------------------------

ExtraLives_Check1P:
		movem.l	d0-d1/a2/a4,-(sp)
		lea	(Ring_count).w,a2
		lea	(Extra_life_flags).w,a4
		bra.s	ExtraLives_Count
; ---------------------------------------------------------------------------

ExtraLives_CheckP2:
		movem.l	d0-d1/a2/a4,-(sp)
		lea	(Ring_count_P2).w,a2
		lea	(Extra_life_flags_P2).w,a4
		bra.s	ExtraLives_Count
; ---------------------------------------------------------------------------

; a2 = ring count, a4 = its Extra_life_flags
ExtraLives_Check:
		movem.l	d0-d1/a2/a4,-(sp)

ExtraLives_Count:
		moveq	#0,d0
		move.w	(a2),d0
		divu.w	#100,d0				; hundreds of rings now
		moveq	#0,d1
		move.b	(a4),d1
		lsr.b	#1,d1				; hundreds already rewarded
		cmp.w	d1,d0
		bls.s	.none
		addq.b	#2,(a4)				; count one more
		movem.l	(sp)+,d0-d1/a2/a4		; (movem keeps the flags)
		move	#0,ccr				; Z=0: give a life
		rts
; ---------------------------------------------------------------------------

.none:
		movem.l	(sp)+,d0-d1/a2/a4
		move	#4,ccr				; Z=1
		rts
; End of function ExtraLives_Check

; ---------------------------------------------------------------------------
; FeatureInvincibilityFlash: the invincibility stars blink during the last
; two seconds, as in s1_improvements and s2_improvements.
; a1 = the player the stars belong to.
; ---------------------------------------------------------------------------

InvStars_Draw:
		cmpi.b	#(2*60)/8,invincibility_timer(a1)	; counted down every 8 frames
		bhi.s	.show
		btst	#2,(Level_frame_counter+1).w	; all the stars blink together
		bne.s	.hide

.show:
		jmp	(Draw_Sprite).l
; ---------------------------------------------------------------------------

.hide:
		rts
; End of function InvStars_Draw

; ---------------------------------------------------------------------------
; FeatureSpecialStageSelect: Left/Right on the SPECIAL STAGE items of the
; Level Select choose the stage, shown as 1-7 after "SPECIAL STG", as in
; s1_improvements and s2_improvements. Starting a Special Stage from the
; Level Select then plays that stage (Special_stage_select), even if its
; emerald was earned already.
; ---------------------------------------------------------------------------
levsel_ss_number = planeLocH28($16+12,$13)	; after "SPECIAL STG"

; Called by LevSelControls_SwitchSide; returns Z=0 when Left/Right changed the
; stage, so the column switch is skipped.
LevelSelect_SpecialStageLR:
		move.w	(Level_select_option).w,d0
		cmpi.w	#$1E,d0				; SPECIAL STAGE 1 or 2?
		blo.s	.none
		cmpi.w	#$1F,d0
		bhi.s	.none
		move.b	(Ctrl_1_pressed).w,d1
		andi.b	#button_left_mask|button_right_mask,d1
		beq.s	.none
		bsr.s	LevelSelect_GetSpecialStage
		btst	#button_left,d1
		beq.s	.right
		subq.w	#1,d0
		bpl.s	.set
		moveq	#7-1,d0
		bra.s	.set
; ---------------------------------------------------------------------------

.right:
		addq.w	#1,d0
		cmpi.w	#7,d0
		blo.s	.set
		moveq	#0,d0

.set:
		move.b	d0,(Current_special_stage).w
		bsr.s	LevelSelect_SpecialStageNumber
		moveq	#signextendB(sfx_Switch),d0
		jsr	(Play_SFX).l
		move	#0,ccr				; Z=0
		rts
; ---------------------------------------------------------------------------

.none:
		move	#4,ccr				; Z=1
		rts
; End of function LevelSelect_SpecialStageLR

; d0.w = the chosen stage, 0-6
LevelSelect_GetSpecialStage:
		moveq	#0,d0
		move.b	(Current_special_stage).w,d0
		cmpi.b	#7,d0
		blo.s	.done
		moveq	#0,d0

.done:
		rts
; End of function LevelSelect_GetSpecialStage

; Writes the stage number into the Level Select plane map in RAM_start, from
; where LevelSelect_MarkFields draws the item every frame.
LevelSelect_SpecialStageNumber:
		bsr.s	LevelSelect_GetSpecialStage
		addi.w	#16+1,d0			; menu font digits start at 16; stages count from 1
		move.w	d0,(RAM_start+levsel_ss_number).l
		rts
; End of function LevelSelect_SpecialStageNumber

; ---------------------------------------------------------------------------
; FeatureInfiniteLives: a 1-up gives 10 rings instead, as in s1_improvements
; and s2_improvements (the 10-ring monitor's own code covers 1-up monitors)
; ---------------------------------------------------------------------------

InfiniteLives_TenRings:
		addi.w	#10,(Ring_count).w
		cmpi.w	#999,(Ring_count).w
		blo.s	.counted
		move.w	#999,(Ring_count).w

.counted:
		addi.w	#10,(Total_ring_count).w
		cmpi.w	#999,(Total_ring_count).w
		blo.s	.total
		move.w	#999,(Total_ring_count).w

.total:
		ori.b	#1,(Update_HUD_ring_count).w
		moveq	#signextendB(sfx_RingRight),d0
		jmp	(Play_SFX).l
; End of function InfiniteLives_TenRings
