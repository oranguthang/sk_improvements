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
