; ---------------------------------------------------------------------------
; Debug coordinates in the upper right corner, as in s1_improvements and
; s2_improvements. While debug mode is available (Debug_mode_flag) in a
; 1-player game, the top row shows the camera X and Y position and the second
; row the player's X and Y position in hex; a third row shows SPR and the number
; of sprites drawn. SCORE, TIME and RINGS keep their normal meaning, in object
; placement too.
;
; Levels have no spare VRAM: the tiles after ArtTile_Shield_Sparks are the
; sprite table. The overlay borrows the last 11 tiles of the shield art
; (ArtTile_Shield+$14) and packs two 4-pixel-wide characters into each tile.
; It hides whenever something else may use them: a shield, invincibility or
; a Super form (their stars), the Insta-Shield's attack, and the Game Over.
; ---------------------------------------------------------------------------
ArtTile_Debug_Coords = ArtTile_Shield+$14
hud_debug_font_space = $13		; index of the blank glyph

	if ArtTile_Debug_Coords+11>ArtTile_Shield_Sparks
		error "The debug overlay tiles must stay inside the shield art"
	endif

; Z=1 when the overlay is shown
HudDebug_Visible:
		tst.w	(Debug_mode_flag).w
		beq.s	.hide
		tst.w	(Competition_mode).w
		bne.s	.hide
		move.b	(Player_1+status_secondary).w,-(sp)
		andi.b	#(1<<Status_Shield)|(1<<Status_Invincible)|(1<<Status_FireShield)|(1<<Status_LtngShield)|(1<<Status_BublShield),(sp)+
		bne.s	.hide				; the shield or the stars use these tiles
		tst.b	(Super_Sonic_Knux_flag).w
		bne.s	.hide
		tst.b	(Super_Tails_flag).w
		bne.s	.hide
		tst.b	(Shield+anim).w			; the Insta-Shield attacking?
		bne.s	.hide
		cmpi.b	#6,(Player_1+routine).w		; dying: the Game Over art goes there
		bhs.s	.hide
		move	#4,ccr				; Z=1
		rts
; ---------------------------------------------------------------------------

.hide:
		move	#0,ccr				; Z=0
		rts
; End of function HudDebug_Visible

; ---------------------------------------------------------------------------
; Writes the overlay tiles (called by UpdateHUD during V-int)
; ---------------------------------------------------------------------------

HudDebug_Overlay:
		bsr.w	HudDebug_Visible
		bne.s	.return
		movem.l	d0-d7/a1/a6,-(sp)
		lea	(VDP_data_port).l,a6
		move.l	#vdpComm(tiles_to_bytes(ArtTile_Debug_Coords),VRAM,WRITE),VDP_control_port-VDP_data_port(a6)
		move.w	(Camera_X_pos).w,d4
		swap	d4
		move.w	(Camera_Y_pos).w,d4		; top row: camera X, camera Y
		move.w	(Player_1+x_pos).w,d5
		swap	d5
		move.w	(Player_1+y_pos).w,d5		; second row: player X, player Y
		moveq	#4-1,d7				; a 4x2-tile sprite piece goes column by column

.column:
		rol.l	#8,d4
		move.b	d4,d0
		bsr.s	HudDebug_DrawHexPair
		rol.l	#8,d5
		move.b	d5,d0
		bsr.s	HudDebug_DrawHexPair
		dbf	d7,.column
		moveq	#$10,d0				; "SP"
		moveq	#$11,d1
		bsr.s	HudDebug_DrawGlyphs
		moveq	#$12,d0				; "R "
		moveq	#hud_debug_font_space,d1
		bsr.s	HudDebug_DrawGlyphs
		moveq	#0,d0
		move.b	(Sprites_drawn).w,d0
		cmpi.w	#99,d0
		bls.s	.count
		moveq	#99,d0

.count:
		divu.w	#10,d0
		move.l	d0,d1
		swap	d1				; ones
		bsr.s	HudDebug_DrawGlyphs
		movem.l	(sp)+,d0-d7/a1/a6

.return:
		rts
; End of function HudDebug_Overlay

; d0.b = two hex digits for one tile
HudDebug_DrawHexPair:
		moveq	#$F,d1
		and.b	d0,d1
		lsr.b	#4,d0
		andi.w	#$F,d0

; d0.w = left glyph, d1.w = right glyph; writes one tile to (a6)
HudDebug_DrawGlyphs:
		lea	HudDebug_Font(pc),a1
		lsl.w	#4,d0
		lsl.w	#4,d1
		moveq	#8-1,d6

.row:
		move.w	(a1,d0.w),d2
		swap	d2
		move.w	(a1,d1.w),d2
		move.l	d2,(a6)
		addq.w	#2,d0
		addq.w	#2,d1
		dbf	d6,.row
		rts
; End of function HudDebug_DrawGlyphs

; ---------------------------------------------------------------------------
; Draws the overlay sprites after the HUD (Render_HUD). a6 = sprite table,
; d7 = sprites left.
; ---------------------------------------------------------------------------

HudDebug_DrawSprite:
		bsr.w	HudDebug_Visible
		bne.s	.return
		lea	HudDebug_Pieces(pc),a1
		moveq	#(HudDebug_Pieces_End-HudDebug_Pieces)/6-1,d4
		move.w	#$80+320-16-32,d0		; 16 pixels from the right, like SCORE on the left
		move.w	#$80+8,d1
		move.w	#make_art_tile(ArtTile_Debug_Coords,0,1),d5
		moveq	#0,d6				; no flipping
		jmp	(sub_1AF6C).l
; ---------------------------------------------------------------------------

.return:
		rts
; End of function HudDebug_DrawSprite

; Sonic 3 & Knuckles mapping pieces: Y, size, tile, X
HudDebug_Pieces:
		dc.b	0, ((4-1)<<2)|(2-1)
		dc.w	0, 0
		dc.b	$10, ((3-1)<<2)|(1-1)
		dc.w	8, 0
HudDebug_Pieces_End:

; 4x8-pixel characters, white (colour 1 of palette line 0) on the dark colour F,
; like the game's own debug digits: 0-F, S, P, R, blank. One word per row.
HudDebug_Font:
		dc.w	$FFFF, $111F, $1F1F, $1F1F, $1F1F, $1F1F, $111F, $FFFF	; 0
		dc.w	$FFFF, $F1FF, $11FF, $F1FF, $F1FF, $F1FF, $111F, $FFFF	; 1
		dc.w	$FFFF, $111F, $FF1F, $111F, $1FFF, $1FFF, $111F, $FFFF	; 2
		dc.w	$FFFF, $111F, $FF1F, $F11F, $FF1F, $FF1F, $111F, $FFFF	; 3
		dc.w	$FFFF, $1F1F, $1F1F, $111F, $FF1F, $FF1F, $FF1F, $FFFF	; 4
		dc.w	$FFFF, $111F, $1FFF, $111F, $FF1F, $FF1F, $111F, $FFFF	; 5
		dc.w	$FFFF, $111F, $1FFF, $111F, $1F1F, $1F1F, $111F, $FFFF	; 6
		dc.w	$FFFF, $111F, $FF1F, $F1FF, $F1FF, $F1FF, $F1FF, $FFFF	; 7
		dc.w	$FFFF, $111F, $1F1F, $111F, $1F1F, $1F1F, $111F, $FFFF	; 8
		dc.w	$FFFF, $111F, $1F1F, $111F, $FF1F, $FF1F, $111F, $FFFF	; 9
		dc.w	$FFFF, $F1FF, $1F1F, $111F, $1F1F, $1F1F, $1F1F, $FFFF	; A
		dc.w	$FFFF, $11FF, $1F1F, $11FF, $1F1F, $1F1F, $11FF, $FFFF	; B
		dc.w	$FFFF, $F11F, $1FFF, $1FFF, $1FFF, $1FFF, $F11F, $FFFF	; C
		dc.w	$FFFF, $11FF, $1F1F, $1F1F, $1F1F, $1F1F, $11FF, $FFFF	; D
		dc.w	$FFFF, $111F, $1FFF, $11FF, $1FFF, $1FFF, $111F, $FFFF	; E
		dc.w	$FFFF, $111F, $1FFF, $11FF, $1FFF, $1FFF, $1FFF, $FFFF	; F
		dc.w	$FFFF, $F11F, $1FFF, $F1FF, $FF1F, $FF1F, $11FF, $FFFF	; S
		dc.w	$FFFF, $11FF, $1F1F, $11FF, $1FFF, $1FFF, $1FFF, $FFFF	; P
		dc.w	$FFFF, $11FF, $1F1F, $11FF, $1F1F, $1F1F, $1F1F, $FFFF	; R
		dc.w	$FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF	; blank
