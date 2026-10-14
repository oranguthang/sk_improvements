; ---------------------------------------------------------------------------
; Light Dash (FeatureLightDash), ported from s1_improvements and
; s2_improvements. In the air, A next to a chain of at least three uncollected
; rings dashes the main character (Sonic, Tails or Knuckles in Player_1) from
; ring to ring. Without a chain, A does the normal air move. B and C never
; start it.
;
; The targets are the level's ring layout: RingLocPtrs gives one X/Y word pair
; per ring (sorted by X, the first entry a header, ending with a negative X),
; and Ring_status_table one word per ring at the same index (0 = not
; collected). The dash collects rings the way Test_Ring_Collisions does.
; ---------------------------------------------------------------------------
LightDash_StartRadius = 64
LightDash_MaxGap = 72
LightDash_Speed = $C00
LightDash_WaterSpeed = $600
LightDash_ExitSpeed = LightDash_Speed
LightDash_WaterExitSpeed = LightDash_WaterSpeed
LightDash_Substeps = 8
LightDash_MaxFrames = 384
LightDash_StallFrames = 3

; ---------------------------------------------------------------------------
; Called first in the air modes. A failed search leaves the press for the
; normal air move; success skips the rest of the calling mode.
; ---------------------------------------------------------------------------

Player_LightDashStart:
		tst.b	(LightDash_active).w
		bne.w	.return
		btst	#button_A,(Ctrl_1_pressed_logical).w
		beq.w	.return
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#button_B_mask|button_C_mask,d0	; B or C with A: the jump buttons win
		bne.w	.return
		btst	#Status_InAir,status(a0)		; on the ground, A always jumps
		beq.w	.return
		tst.b	double_jump_flag(a0)		; not from a flight, glide or shield move
		bne.w	.return
		bsr.w	LightDash_Allowed
		beq.w	.return
		cmpi.b	#90,invulnerability_timer(a0)
		bhs.w	.return
		bsr.w	LightDash_GetLayout
		clr.l	(LightDash_exclude_first).w	; and LightDash_exclude_second
		clr.b	(LightDash_near_ground).w
		clr.b	(LightDash_have_last_ring).w
		clr.l	(LightDash_exit_x).w		; and LightDash_exit_y
		move.b	#1,(LightDash_initial_search).w
		move.w	x_pos(a0),(LightDash_probe_x).w
		move.w	y_pos(a0),(LightDash_probe_y).w
		move.w	#LightDash_StartRadius,d6
		bsr.w	LightDash_FindTarget
		clr.b	(LightDash_initial_search).w
		tst.w	d0
		beq.w	.return
		bsr.w	LightDash_SetTarget
		; Require three reachable, uncollected rings before taking A: preview
		; the next two links without collecting them.
		move.w	d0,(LightDash_exclude_first).w
		bsr.w	LightDash_ProbeAtRing
		move.w	#LightDash_MaxGap,d6
		bsr.w	LightDash_FindTarget
		tst.w	d0
		beq.w	.noChain
		move.w	d0,(LightDash_exclude_second).w
		bsr.w	LightDash_ProbeAtRing
		bsr.w	LightDash_FindTarget
		tst.w	d0
		beq.w	.noChain
		clr.l	(LightDash_exclude_first).w
		move.b	#1,(LightDash_active).w
		move.w	(Current_zone_and_act).w,(LightDash_act).w
		move.w	#LightDash_MaxFrames,(LightDash_timer).w
		bset	#Status_InAir,status(a0)
		bclr	#Status_OnObj,status(a0)
		bclr	#Status_Push,status(a0)
		bsr.w	LightDash_Uncurl		; the dash is a run, not a ball
		clr.b	flip_angle(a0)
		clr.b	flip_type(a0)
		clr.b	jumping(a0)			; the exit keeps its speed, no jump-height cut
		clr.b	anim(a0)			; walking/running, turned by LightDash_Pose
		clr.l	(LightDash_full_x).w		; and LightDash_full_y
		bclr	#button_A,(Ctrl_1_pressed_logical).w
		bsr.w	Player_LightDashUpdate
		addq.l	#4,sp				; skip the rest of the air mode
		rts
; ---------------------------------------------------------------------------

.noChain:
		clr.l	(LightDash_exclude_first).w
		clr.w	(LightDash_target).w

.return:
		rts
; End of function Player_LightDashStart

; ---------------------------------------------------------------------------
; Called by the player's control routine instead of its mode while a dash runs.
; Returns d0 = 1 (Z=0) if the frame was handled, 0 (Z=1) if the normal mode
; should run.
; ---------------------------------------------------------------------------

Player_LightDashFrame:
		cmpa.w	#Player_1,a0
		bne.s	.normal
		clr.b	(LightDash_hitframe).w		; attacks only on frames the dash moved
		tst.b	(LightDash_active).w
		beq.s	.normal
		bsr.w	Player_LightDashUpdate
		tst.w	d0
		rts
; ---------------------------------------------------------------------------

.normal:
		moveq	#0,d0
		rts
; End of function Player_LightDashFrame

Player_LightDashUpdate:
		movem.l	d1-d7/a1-a6,-(sp)
		bsr.w	LightDash_Allowed
		beq.w	.cancelBeforeMove
		move.w	(Current_zone_and_act).w,d0
		cmp.w	(LightDash_act).w,d0
		bne.w	.cancelBeforeMove
		btst	#Status_Push,status(a0)
		bne.w	.cancelBeforeMove
		; Solid objects run after the player: a cancelled velocity stops the
		; next dash frame (water's halving still allows it).
		move.w	(LightDash_full_x).w,d0
		bpl.s	.absX
		neg.w	d0

.absX:
		cmpi.w	#$100,d0
		blo.s	.checkY
		tst.w	x_vel(a0)
		beq.w	.cancelBeforeMove

.checkY:
		btst	#Status_InAir,status(a0)
		beq.s	.timer				; landing may have stopped the vertical speed
		move.w	(LightDash_full_y).w,d0
		bpl.s	.absY
		neg.w	d0

.absY:
		cmpi.w	#$100,d0
		blo.s	.timer
		tst.w	y_vel(a0)
		beq.w	.cancelBeforeMove

.timer:
		subq.w	#1,(LightDash_timer).w
		bmi.w	.cancelBeforeMove
		bsr.w	LightDash_TargetStatus
		tst.w	(a4)
		bne.w	.nextTarget			; already collected the normal way
		bsr.w	LightDash_TargetDelta
		move.w	d1,d3
		muls.w	d3,d3
		move.w	d2,d4
		muls.w	d4,d4
		add.l	d4,d3
		move.w	#LightDash_Speed/256,d5
		btst	#Status_Underwater,status(a0)
		beq.s	.speed
		move.w	#LightDash_WaterSpeed/256,d5

.speed:
		move.w	d5,d4
		muls.w	d4,d4
		cmp.l	d4,d3
		bhi.s	.fullSpeed
		lsl.w	#8,d1				; reach a near target exactly over the substeps
		lsl.w	#8,d2
		move.w	d1,(LightDash_full_x).w
		move.w	d2,(LightDash_full_y).w
		bra.s	.substeps
; ---------------------------------------------------------------------------

.fullSpeed:
		jsr	(GetArcTan).l
		jsr	(GetSineCosine).l
		muls.w	d5,d1
		muls.w	d5,d0
		move.w	d1,(LightDash_full_x).w
		move.w	d0,(LightDash_full_y).w

.substeps:
		move.b	#1,(LightDash_hitframe).w
		move.w	(LightDash_full_x).w,d0
		asr.w	#3,d0
		move.w	d0,(LightDash_step_x).w
		move.w	(LightDash_full_y).w,d0
		asr.w	#3,d0
		move.w	d0,(LightDash_step_y).w
		moveq	#LightDash_Substeps-1,d7

.step:
		move.w	(LightDash_step_x).w,x_vel(a0)
		move.w	(LightDash_step_y).w,y_vel(a0)
		move.l	d7,-(sp)
		jsr	(MoveSprite_TestGravity2).l
		btst	#Status_InAir,status(a0)
		bne.s	.airCollision
		tst.w	(LightDash_step_y).w
		bmi.s	.takeOff			; follow a rising chain back into the air
		move.w	(LightDash_step_x).w,ground_vel(a0)
		movem.l	a4-a6,-(sp)
		jsr	(Call_Player_AnglePos).l	; follow the ground and its collisions
		movem.l	(sp)+,a4-a6
		bra.s	.collisionDone
; ---------------------------------------------------------------------------

.takeOff:
		bset	#Status_InAir,status(a0)

.airCollision:
		bsr.w	LightDash_LevelCollision	; walls, floor and ceiling in the air

.collisionDone:
		jsr	(Player_LevelBound).l
		move.l	(sp)+,d7
		tst.b	(LightDash_active).w		; a death or an event may have cancelled it
		beq.w	.handled
		cmpi.b	#2,routine(a0)
		bne.w	.cancelAfterMove
		btst	#Status_InAir,status(a0)
		beq.s	.groundContact
		move.w	(LightDash_step_x).w,d0
		cmp.w	x_vel(a0),d0
		bne.w	.cancelAfterMove
		move.w	(LightDash_step_y).w,d0
		cmp.w	y_vel(a0),d0
		bne.w	.cancelAfterMove
		bra.s	.stepDone
; ---------------------------------------------------------------------------

.groundContact:
		tst.w	(LightDash_step_x).w
		beq.s	.stepDone
		tst.w	x_vel(a0)
		beq.w	.cancelAfterMove		; a wall stopped the grounded dash

.stepDone:
		dbf	d7,.step
		move.w	(LightDash_full_x).w,x_vel(a0)
		btst	#Status_InAir,status(a0)
		bne.s	.stillAirborne
		clr.w	y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bra.s	.movementReady
; ---------------------------------------------------------------------------

.stillAirborne:
		move.w	(LightDash_full_y).w,y_vel(a0)

.movementReady:
		clr.b	anim(a0)
		bsr.w	LightDash_TargetDelta
		; Test_Ring_Collisions' hitbox: 8 pixels either side and (y_radius - 3)
		; above and below, against the ring's 6-pixel radius.
		tst.w	d1
		bpl.s	.dxPositive
		neg.w	d1

.dxPositive:
		cmpi.w	#8+6,d1
		bhi.s	.checkProgress
		tst.w	d2
		bpl.s	.dyPositive
		neg.w	d2

.dyPositive:
		moveq	#0,d3
		move.b	y_radius(a0),d3
		addq.w	#3,d3
		cmp.w	d3,d2
		bhi.s	.checkProgress
		bsr.w	LightDash_CollectRing
		bra.s	.nextTarget
; ---------------------------------------------------------------------------

.checkProgress:
		move.w	x_pos(a0),d1
		cmp.w	(LightDash_last_x).w,d1
		bne.s	.progressed
		move.w	y_pos(a0),d1
		cmp.w	(LightDash_last_y).w,d1
		bne.s	.progressed
		addq.b	#1,(LightDash_stall).w
		cmpi.b	#LightDash_StallFrames,(LightDash_stall).w
		bhs.s	.cancelAfterMove		; really stopped by the level or an object
		bra.s	.handled
; ---------------------------------------------------------------------------

.progressed:
		move.w	x_pos(a0),(LightDash_last_x).w
		move.w	y_pos(a0),(LightDash_last_y).w
		clr.b	(LightDash_stall).w
		bra.s	.handled
; ---------------------------------------------------------------------------

.nextTarget:
		move.w	(LightDash_target).w,d0
		bsr.w	LightDash_ProbeAtRing
		bsr.w	LightDash_RecordRing
		clr.b	(LightDash_near_ground).w
		btst	#Status_InAir,status(a0)
		beq.s	.nearGround
		movem.l	a4-a6,-(sp)
		jsr	(Sonic_CheckFloor).l		; also covers flying just above the ground
		movem.l	(sp)+,a4-a6
		cmpi.w	#12,d1
		bgt.s	.findNext
		cmpi.w	#-8,d1
		blt.s	.findNext

.nearGround:
		move.b	#1,(LightDash_near_ground).w

.findNext:
		move.w	#LightDash_MaxGap,d6
		bsr.w	LightDash_FindTarget
		tst.w	d0
		beq.s	.finishChain
		bsr.w	LightDash_SetTarget
		bra.s	.handled
; ---------------------------------------------------------------------------

.finishChain:
		bsr.w	Player_FinishLightDash

.handled:
		movem.l	(sp)+,d1-d7/a1-a6
		moveq	#1,d0
		rts
; ---------------------------------------------------------------------------

.cancelAfterMove:
		bsr.w	Player_CancelLightDash
		bra.s	.handled
; ---------------------------------------------------------------------------

.cancelBeforeMove:
		bsr.w	Player_CancelLightDash
		movem.l	(sp)+,d1-d7/a1-a6
		moveq	#0,d0
		rts
; End of function Player_LightDashUpdate

; ---------------------------------------------------------------------------
; Guards shared by the start and the dash. Returns Z=0 if the dash may run.
; ---------------------------------------------------------------------------

LightDash_Allowed:
		cmpa.w	#Player_1,a0			; only the player-controlled character
		bne.s	.deny
		cmpi.b	#2,routine(a0)
		bne.s	.deny
		move.b	(Game_mode).w,d0
		andi.b	#$7F,d0
		cmpi.b	#GameMode_Level,d0
		bne.s	.deny
		tst.w	(Demo_mode_flag).w
		bne.s	.deny
		tst.w	(Competition_mode).w
		bne.s	.deny
		tst.w	(Debug_placement_mode).w
		bne.s	.deny
		tst.b	(Ctrl_1_locked).w
		bne.s	.deny
		tst.b	object_control(a0)
		bne.s	.deny
		tst.b	(Reverse_gravity_flag).w	; the dash moves in world coordinates
		bne.s	.deny
		move.b	(Current_zone).w,d0
		cmpi.b	#$0E,d0				; Competition zones and bonus stages: no dash
		blo.s	.allow
		cmpi.b	#$15,d0
		bls.s	.deny

.allow:
		move	#0,ccr				; Z=0
		rts
; ---------------------------------------------------------------------------

.deny:
		move	#4,ccr				; Z=1
		rts
; End of function LightDash_Allowed

; LightDash_layout = the level's ring layout (RingLocPtrs), as sub_EB1A gets it
LightDash_GetLayout:
		move.w	(Current_zone_and_act).w,d0
		ror.b	#1,d0
		lsr.w	#5,d0
		lea	(RingLocPtrs).l,a1
		move.l	(a1,d0.w),(LightDash_layout).w
		rts
; End of function LightDash_GetLayout

; ---------------------------------------------------------------------------
; d6 = search radius around the probe (the previous ring, or the player when
; starting). Returns d0.w = the closest uncollected ring's index, or 0.
; Rings are sorted by X, so the scan stops past the radius.
; ---------------------------------------------------------------------------

LightDash_FindTarget:
		movem.l	d1-d5/d7/a1/a3,-(sp)
		moveq	#0,d7				; best index so far
		movea.l	(LightDash_layout).w,a1
		addq.w	#4,a1				; the first entry is the header
		lea	(Ring_status_table+2).w,a3
		moveq	#1,d4				; the current index
		move.w	d6,d5
		muls.w	d5,d5
		addq.l	#1,d5

.scan:
		move.w	(a1),d1
		bmi.w	.done				; end of the layout
		sub.w	(LightDash_probe_x).w,d1
		cmp.w	d6,d1
		bgt.w	.done
		move.w	d6,d0
		neg.w	d0
		cmp.w	d0,d1
		blt.w	.next
		tst.w	(a3)				; already collected?
		bne.w	.next
		cmp.w	(LightDash_exclude_first).w,d4
		beq.w	.next
		cmp.w	(LightDash_exclude_second).w,d4
		beq.w	.next
		tst.b	(LightDash_initial_search).w
		beq.s	.directionReady
		btst	#Status_Facing,status(a0)	; the first ring must be ahead
		bne.s	.facingLeft
		tst.w	d1
		bmi.w	.next
		bra.s	.directionReady
; ---------------------------------------------------------------------------

.facingLeft:
		tst.w	d1
		bgt.w	.next

.directionReady:
		move.w	2(a1),d2
		sub.w	(LightDash_probe_y).w,d2
		bsr.w	LightDash_WrapDeltaY
		cmp.w	d6,d2
		bgt.s	.next
		cmp.w	d0,d2
		blt.s	.next
		; Near the floor, do not turn back along the same row for a missed ring.
		tst.b	(LightDash_near_ground).w
		beq.s	.candidateReady
		move.w	d2,d3
		bpl.s	.dyPositive
		neg.w	d3

.dyPositive:
		cmpi.w	#16,d3
		bhs.s	.candidateReady
		move.w	(a1),d3
		btst	#Status_Facing,status(a0)
		bne.s	.candidateLeft
		cmp.w	x_pos(a0),d3
		blt.s	.next
		bra.s	.candidateReady
; ---------------------------------------------------------------------------

.candidateLeft:
		cmp.w	x_pos(a0),d3
		bgt.s	.next

.candidateReady:
		move.w	d1,d3
		muls.w	d3,d3
		muls.w	d2,d2
		add.l	d2,d3
		cmp.l	d5,d3
		bhs.s	.next
		move.l	d3,d5
		move.w	d4,d7

.next:
		addq.w	#4,a1
		addq.w	#2,a3
		addq.w	#1,d4
		cmpi.w	#(Ring_status_table_end-Ring_status_table)/2,d4
		blo.w	.scan

.done:
		move.w	d7,d0
		movem.l	(sp)+,d1-d5/d7/a1/a3
		rts
; End of function LightDash_FindTarget

LightDash_SetTarget:
		move.w	d0,(LightDash_target).w
		move.w	x_pos(a0),(LightDash_last_x).w
		move.w	y_pos(a0),(LightDash_last_y).w
		clr.b	(LightDash_stall).w
		rts
; End of function LightDash_SetTarget

; d0.w = ring index; the probe moves onto that ring. Clobbers a1.
LightDash_ProbeAtRing:
		movea.l	(LightDash_layout).w,a1
		move.w	d0,-(sp)
		add.w	d0,d0
		add.w	d0,d0
		adda.w	d0,a1
		move.w	(sp)+,d0
		move.w	(a1),(LightDash_probe_x).w
		move.w	2(a1),(LightDash_probe_y).w
		rts
; End of function LightDash_ProbeAtRing

; a4 = the target's Ring_status_table word
LightDash_TargetStatus:
		lea	(Ring_status_table).w,a4
		move.w	(LightDash_target).w,d0
		add.w	d0,d0
		adda.w	d0,a4
		rts
; End of function LightDash_TargetStatus

; Keeps the latest ring-to-ring direction for a natural exit.
LightDash_RecordRing:
		tst.b	(LightDash_have_last_ring).w
		beq.s	.store
		move.w	(LightDash_probe_x).w,d1
		sub.w	(LightDash_last_ring_x).w,d1
		move.w	(LightDash_probe_y).w,d2
		sub.w	(LightDash_last_ring_y).w,d2
		bsr.w	LightDash_WrapDeltaY
		move.w	d1,d3
		or.w	d2,d3
		beq.s	.store				; coincident rings keep the last real direction
		jsr	(GetArcTan).l
		jsr	(GetSineCosine).l
		move.w	#LightDash_ExitSpeed/256,d5
		btst	#Status_Underwater,status(a0)
		beq.s	.speed
		move.w	#LightDash_WaterExitSpeed/256,d5

.speed:
		muls.w	d5,d1
		muls.w	d5,d0
		move.w	d1,(LightDash_exit_x).w
		move.w	d0,(LightDash_exit_y).w

.store:
		move.w	(LightDash_probe_x).w,(LightDash_last_ring_x).w
		move.w	(LightDash_probe_y).w,(LightDash_last_ring_y).w
		move.b	#1,(LightDash_have_last_ring).w
		rts
; End of function LightDash_RecordRing

; Collects the target ring the way Test_Ring_Collisions does (sparkle, count,
; lives, sound).
LightDash_CollectRing:
		movem.l	d0-d7/a1-a4,-(sp)
		bsr.s	LightDash_TargetStatus
		move.w	#$604,(a4)			; sparkle frame and timer
		subq.w	#1,(Perfect_rings_left).w
		jsr	(GiveRing).l
		lea	(Ring_consumption_list).w,a3

.findSlot:
		tst.w	(a3)+
		bne.s	.findSlot
		move.w	a4,-(a3)
		addq.w	#1,(Ring_consumption_table).w
		movem.l	(sp)+,d0-d7/a1-a4
		rts
; End of function LightDash_CollectRing

; Natural end: hands the momentum to the normal ground or air physics.
Player_FinishLightDash:
		bsr.w	Player_CancelLightDash
		cmpi.b	#2,routine(a0)
		bne.s	.return
		tst.b	object_control(a0)
		bne.s	.return
		move.w	(LightDash_exit_x).w,x_vel(a0)
		move.w	(LightDash_exit_y).w,y_vel(a0)
		btst	#Status_InAir,status(a0)
		bne.s	.return				; in the air both components stay
		tst.w	y_vel(a0)
		bpl.s	.grounded
		bset	#Status_InAir,status(a0)	; a rising last link lifts off
		bra.s	.return
; ---------------------------------------------------------------------------

.grounded:
		clr.w	y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)

.return:
		rts
; End of function Player_FinishLightDash

; Returns d1/d2 = target - player (Y wrapped on vertically wrapping levels).
LightDash_TargetDelta:
		movea.l	(LightDash_layout).w,a1
		move.w	(LightDash_target).w,d0
		add.w	d0,d0
		add.w	d0,d0
		adda.w	d0,a1
		move.w	(a1),d1
		sub.w	x_pos(a0),d1
		move.w	2(a1),d2
		sub.w	y_pos(a0),d2

LightDash_WrapDeltaY:
		cmpi.w	#-$100,(Camera_min_Y_pos).w	; vertical wrapping?
		bne.s	.return
		and.w	(Screen_Y_wrap_value).w,d2
		move.w	(Screen_Y_wrap_value).w,d3
		lsr.w	#1,d3
		cmp.w	d3,d2
		bls.s	.return
		sub.w	(Screen_Y_wrap_value).w,d2
		subq.w	#1,d2

.return:
		rts
; End of function LightDash_TargetDelta

LightDash_LevelCollision:
		movem.l	a4-a6,-(sp)
		cmpi.b	#1,character_id(a0)
		beq.s	.tails
		jsr	(SonicKnux_DoLevelCollision).l
		bra.s	.done
; ---------------------------------------------------------------------------

.tails:
		jsr	(Tails_DoLevelCollision).l

.done:
		movem.l	(sp)+,a4-a6
		rts
; End of function LightDash_LevelCollision

; A rolling player straightens up for the dash, keeping his feet in place.
LightDash_Uncurl:
		bclr	#Status_Roll,status(a0)
		beq.s	.return
		move.b	default_y_radius(a0),d0
		sub.b	y_radius(a0),d0			; how much taller standing is
		ext.w	d0
		sub.w	d0,y_pos(a0)
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)

.return:
		rts
; End of function LightDash_Uncurl

; ---------------------------------------------------------------------------
; Turns the running frames along the dash direction: the character's own
; walking animation runs with a display-only angle and a running speed, as if
; he ran along a surface that points that way, then both are restored (the
; real angle belongs to the floor collision). Call LightDash_PoseStart before
; the animation routine and LightDash_PoseEnd after it, as the wrappers below do.
; ---------------------------------------------------------------------------

LightDash_Animate_Sonic:
		bsr.s	LightDash_PoseStart
		jsr	(Animate_Sonic).l
		bra.s	LightDash_PoseEnd
; ---------------------------------------------------------------------------

LightDash_Animate_Tails:
		bsr.s	LightDash_PoseStart
		jsr	(Animate_Tails).l
		bra.s	LightDash_PoseEnd
; ---------------------------------------------------------------------------

LightDash_Animate_Knuckles:
		bsr.s	LightDash_PoseStart
		jsr	(Animate_Knuckles).l
		bra.s	LightDash_PoseEnd
; End of function LightDash_Animate_Knuckles

LightDash_PoseStart:
		tst.b	(LightDash_active).w
		beq.s	.return
		cmpa.w	#Player_1,a0
		bne.s	.return
		move.b	angle(a0),(LightDash_saved_angle).w
		move.w	ground_vel(a0),(LightDash_saved_speed).w
		move.w	#LightDash_Speed,ground_vel(a0)
		clr.b	anim(a0)
		movem.l	d0-d2,-(sp)
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		move.w	d1,d0
		or.w	d2,d0
		beq.s	.keep
		jsr	(GetArcTan).l
		tst.w	x_vel(a0)
		bmi.s	.left
		bclr	#Status_Facing,status(a0)
		bra.s	.setAngle
; ---------------------------------------------------------------------------

.left:
		bset	#Status_Facing,status(a0)
		subi.b	#$80,d0				; running left along a surface of that angle

.setAngle:
		move.b	d0,angle(a0)

.keep:
		movem.l	(sp)+,d0-d2

.return:
		rts
; End of function LightDash_PoseStart

LightDash_PoseEnd:
		tst.b	(LightDash_active).w
		beq.s	.return
		cmpa.w	#Player_1,a0
		bne.s	.return
		move.b	(LightDash_saved_angle).w,angle(a0)
		move.w	(LightDash_saved_speed).w,ground_vel(a0)

.return:
		rts
; End of function LightDash_PoseEnd

; ---------------------------------------------------------------------------
; Ends the dash. In the air the player falls uncurled, on the ground he keeps
; running.
; ---------------------------------------------------------------------------

Player_CancelLightDash:
		tst.b	(LightDash_active).w
		beq.s	.return
		clr.b	(LightDash_active).w
		clr.w	(LightDash_timer).w
		clr.w	(LightDash_target).w
		cmpi.b	#2,routine(a0)
		bne.s	.return
		tst.b	object_control(a0)
		bne.s	.return
		clr.w	y_vel(a0)			; never carry the dash lift into the fall
		btst	#Status_InAir,status(a0)
		bne.s	.return
		move.w	x_vel(a0),ground_vel(a0)	; keep running when the chain ends on land

.return:
		rts
; End of function Player_CancelLightDash

; ---------------------------------------------------------------------------
; Hooks for the rest of the game
; ---------------------------------------------------------------------------

; HurtCharacter/Kill_Character: a hit or a death ends the dash.
LightDash_PlayerHit:
		cmpa.w	#Player_1,a0
		bne.s	.return
		clr.b	(LightDash_active).w
		clr.b	(LightDash_hitframe).w

.return:
		rts
; End of function LightDash_PlayerHit

; Touch_Enemy: Z=0 while the dash moved the main character this frame, so he
; attacks badniks (and is vulnerable again once it ends, unless curled).
LightDash_Attacking:
		cmpa.w	#Player_1,a0
		bne.s	.no
		tst.b	(LightDash_hitframe).w
		rts
; ---------------------------------------------------------------------------

.no:
		move	#4,ccr				; Z=1
		rts
; End of function LightDash_Attacking
