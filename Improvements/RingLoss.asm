; ---------------------------------------------------------------------------
; Ring loss speeds for loc_1A68C (Obj_Bouncing_Ring), as in s1_improvements
; (after "Speed Up Ring Loss Process"): x_vel and y_vel of each ring, exactly
; what the original computed with GetSineCosine from the angle $288, shifted
; left by the angle's high byte, every second ring the first one's mirror
; image. RingLoss_Velocities_Water halves each sine and cosine before the
; shift, as the underwater fix (FixBugs) did.
;
; A spill has at most 32 rings, but one that starts after the rings ran out
; (RING DRAIN can empty them between the hit and the spill) fills every free
; slot, and the original sequence then goes on, repeating every 48 rings. The
; tables cover every slot, so such a spill also matches the original.
; ---------------------------------------------------------------------------

RingLoss_Velocities:
		dc.w	-$C4,-$3EC, $C4,-$3EC, -$238,-$350, $238,-$350
		dc.w	-$350,-$238, $350,-$238, -$3EC,-$C4, $3EC,-$C4
		dc.w	-$3EC,$C4, $3EC,$C4, -$350,$238, $350,$238
		dc.w	-$238,$350, $238,$350, -$C4,$3EC, $C4,$3EC
		dc.w	-$62,-$1F6, $62,-$1F6, -$11C,-$1A8, $11C,-$1A8
		dc.w	-$1A8,-$11C, $1A8,-$11C, -$1F6,-$62, $1F6,-$62
		dc.w	-$1F6,$62, $1F6,$62, -$1A8,$11C, $1A8,$11C
		dc.w	-$11C,$1A8, $11C,$1A8, -$62,$1F6, $62,$1F6
		dc.w	-$31,-$FB, $31,-$FB, -$8E,-$D4, $8E,-$D4
		dc.w	-$D4,-$8E, $D4,-$8E, -$FB,-$31, $FB,-$31
		dc.w	-$FB,$31, $FB,$31, -$D4,$8E, $D4,$8E
		dc.w	-$8E,$D4, $8E,$D4, -$31,$FB, $31,$FB
		dc.w	-$C4,-$3EC, $C4,-$3EC, -$238,-$350, $238,-$350
		dc.w	-$350,-$238, $350,-$238, -$3EC,-$C4, $3EC,-$C4
		dc.w	-$3EC,$C4, $3EC,$C4, -$350,$238, $350,$238
		dc.w	-$238,$350, $238,$350, -$C4,$3EC, $C4,$3EC
		dc.w	-$62,-$1F6, $62,-$1F6, -$11C,-$1A8, $11C,-$1A8
		dc.w	-$1A8,-$11C, $1A8,-$11C, -$1F6,-$62, $1F6,-$62
		dc.w	-$1F6,$62, $1F6,$62, -$1A8,$11C, $1A8,$11C
		dc.w	-$11C,$1A8, $11C,$1A8, -$62,$1F6, $62,$1F6
		dc.w	-$31,-$FB, $31,-$FB, -$8E,-$D4, $8E,-$D4
		dc.w	-$D4,-$8E, $D4,-$8E, -$FB,-$31, $FB,-$31
		dc.w	-$FB,$31, $FB,$31, -$D4,$8E, $D4,$8E
		dc.w	-$8E,$D4, $8E,$D4, -$31,$FB, $31,$FB
RingLoss_Velocities_End:

RingLoss_Velocities_Water:
		dc.w	-$64,-$1F8, $64,-$1F8, -$11C,-$1A8, $11C,-$1A8
		dc.w	-$1A8,-$11C, $1A8,-$11C, -$1F8,-$64, $1F8,-$64
		dc.w	-$1F8,$60, $1F8,$60, -$1A8,$11C, $1A8,$11C
		dc.w	-$11C,$1A8, $11C,$1A8, -$64,$1F4, $64,$1F4
		dc.w	-$32,-$FC, $32,-$FC, -$8E,-$D4, $8E,-$D4
		dc.w	-$D4,-$8E, $D4,-$8E, -$FC,-$32, $FC,-$32
		dc.w	-$FC,$30, $FC,$30, -$D4,$8E, $D4,$8E
		dc.w	-$8E,$D4, $8E,$D4, -$32,$FA, $32,$FA
		dc.w	-$19,-$7E, $19,-$7E, -$47,-$6A, $47,-$6A
		dc.w	-$6A,-$47, $6A,-$47, -$7E,-$19, $7E,-$19
		dc.w	-$7E,$18, $7E,$18, -$6A,$47, $6A,$47
		dc.w	-$47,$6A, $47,$6A, -$19,$7D, $19,$7D
		dc.w	-$64,-$1F8, $64,-$1F8, -$11C,-$1A8, $11C,-$1A8
		dc.w	-$1A8,-$11C, $1A8,-$11C, -$1F8,-$64, $1F8,-$64
		dc.w	-$1F8,$60, $1F8,$60, -$1A8,$11C, $1A8,$11C
		dc.w	-$11C,$1A8, $11C,$1A8, -$64,$1F4, $64,$1F4
		dc.w	-$32,-$FC, $32,-$FC, -$8E,-$D4, $8E,-$D4
		dc.w	-$D4,-$8E, $D4,-$8E, -$FC,-$32, $FC,-$32
		dc.w	-$FC,$30, $FC,$30, -$D4,$8E, $D4,$8E
		dc.w	-$8E,$D4, $8E,$D4, -$32,$FA, $32,$FA
		dc.w	-$19,-$7E, $19,-$7E, -$47,-$6A, $47,-$6A
		dc.w	-$6A,-$47, $6A,-$47, -$7E,-$19, $7E,-$19
		dc.w	-$7E,$18, $7E,$18, -$6A,$47, $6A,$47
		dc.w	-$47,$6A, $47,$6A, -$19,$7D, $19,$7D

	if MOMPASS>1
	if (RingLoss_Velocities_End-RingLoss_Velocities)/4 < (Dynamic_object_RAM_end-Dynamic_object_RAM)/object_size+2
		fatal "RingLoss_Velocities needs an entry for every dynamic object slot"
	endif
	endif
