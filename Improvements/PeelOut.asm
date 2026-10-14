; ---------------------------------------------------------------------------
; Super Peel-Out (FeaturePeelOut), as in s1_improvements and s2_improvements:
; standing still, Sonic holds Up and presses A/B/C to charge, then lets go of
; Up to launch an upright run. The charge is kept in spin_dash_counter, apart
; from ground_vel, which solid objects may clear every frame.
; Sonic 3 & Knuckles has no figure-eight frames or Peel-Out sounds, as Sonic 2:
; the charge shows the normal run cycle at the charged speed and uses the
; Spin Dash sounds.
; ---------------------------------------------------------------------------
PeelOut_ChargeStep = 100
PeelOut_MinCharge = $600
PeelOut_MaxCharge = $1000

; Called first in Sonic_MdNormal. While charging (and on a cancelled release)
; it skips the rest of the mode.
Sonic_PeelOut:
		cmpa.w	#Player_1,a0			; PeelOut_charging belongs to player 1
		bne.s	.return
		tst.b	(PeelOut_charging).w
		bne.s	.charge
		tst.w	(Demo_mode_flag).w		; the demos were recorded without it
		bne.s	.return
		tst.w	(Competition_mode).w
		bne.s	.return
		tst.b	spin_dash_flag(a0)
		bne.s	.return
		tst.w	move_lock(a0)
		bne.s	.return
		tst.w	ground_vel(a0)			; only from a standstill
		bne.s	.return
		move.b	(Ctrl_1_held_logical).w,d0
		andi.b	#button_up_mask|button_down_mask,d0
		cmpi.b	#button_up_mask,d0
		bne.s	.return
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#button_A_mask|button_B_mask|button_C_mask,d0
		beq.s	.return
		move.b	#1,(PeelOut_charging).w
		clr.w	spin_dash_counter(a0)
		moveq	#signextendB(sfx_Spindash),d0
		jsr	(Play_SFX).l
		bra.s	.stationary
; ---------------------------------------------------------------------------

.return:
		rts
; ---------------------------------------------------------------------------

.charge:
		btst	#button_up,(Ctrl_1_held_logical).w
		beq.s	.release
		move.w	(Max_speed).w,d0
		add.w	d0,d0				; up to twice the top speed...
		cmpi.w	#PeelOut_MaxCharge,d0
		bls.s	.limit
		move.w	#PeelOut_MaxCharge,d0		; ...but no more than $1000

.limit:
		addi.w	#PeelOut_ChargeStep,spin_dash_counter(a0)
		cmp.w	spin_dash_counter(a0),d0
		bhs.s	.stationary
		move.w	d0,spin_dash_counter(a0)

.stationary:
		clr.w	ground_vel(a0)
		clr.w	x_vel(a0)
		clr.w	y_vel(a0)
		clr.b	anim(a0)			; walking/running
		bclr	#Status_Push,status(a0)
		jsr	(Player_LevelBound).l
		jsr	(Call_Player_AnglePos).l
		; Run on the spot: the animation reads ground_vel, which the next frame
		; clears again before anything moves.
		move.w	spin_dash_counter(a0),d0
		btst	#Status_Facing,status(a0)
		beq.s	.right
		neg.w	d0

.right:
		move.w	d0,ground_vel(a0)
		addq.l	#4,sp				; skip the rest of Sonic_MdNormal
		rts
; ---------------------------------------------------------------------------

.release:
		move.w	spin_dash_counter(a0),d2
		clr.b	(PeelOut_charging).w
		clr.w	spin_dash_counter(a0)
		cmpi.w	#PeelOut_MinCharge,d2
		blo.s	.cancel
		btst	#Status_Facing,status(a0)
		beq.s	.launch
		neg.w	d2

.launch:
		move.w	d2,ground_vel(a0)		; Sonic_Move turns it into speed along the floor
		bclr	#Status_Push,status(a0)
		clr.b	anim(a0)
		moveq	#signextendB(sfx_Dash),d0
		jmp	(Play_SFX).l
; ---------------------------------------------------------------------------

.cancel:
		clr.w	ground_vel(a0)
		move.b	#5,anim(a0)			; standing
		addq.l	#4,sp				; a release cannot also jump
		rts
; End of function Sonic_PeelOut

; Leaving the ground, a hit or a death ends a charge. a0 = player.
PeelOut_Cancel:
		cmpa.w	#Player_1,a0
		bne.s	.return
		clr.b	(PeelOut_charging).w

.return:
		rts
; End of function PeelOut_Cancel
