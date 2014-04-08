/**
 * A N I M A T I O N S
 * -------------------
 */

// Animation 0 - do nothing. skipped anyway

// Animation 1 - player movement
animation1:			ldx $dc00   	// read joystick 2

					// determine start of line of the object
					ldy #$02		// read ypos
					lda (ptrObject),y
					tay
					lda screenLinesLo,y
					sta ptrScreen
					lda screenLinesHi,y
					sta ptrScreen+1

joyUp:				txa
					and #$01		// check bit 1 - up
					bne joyDown		// not up - next check down
					ldy #$0a		// read direction
					lda (ptrObject),y
					//cmp #$02
					bne joyUp1		// skip move, when changing direction

					// calculate new position
					ldy #$01		// read xpos
					lda (ptrObject),y
					sta newPosX
					ldy #$02		// read ypos
					lda (ptrObject),y
					sec
					sbc #$01
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64			// is empty?
					bne joyLeft

					// everything fine - we move
					// delete current position
					ldy #$01		// read xpos
					lda (ptrObject),y
					tay
					lda #$40		// delete current position
					sta (ptrScreen),y

					// calculate new position
					lda newPosY
					ldy #$02		// ypos
					sta (ptrObject),y
					jmp joyUp2

joyUp1:				lda #$00		// direction up
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyUp2:				ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyDown:			txa
					and #$02		// check bit 2 - down
					bne joyLeft
					ldy #$0a		// read direction
					lda (ptrObject),y
					cmp #$02
					bne joyDown1	// skip move, when changing direction

					// calculate new position
					ldy #$01		// read xpos
					lda (ptrObject),y
					sta newPosX
					ldy #$02		// read ypos
					lda (ptrObject),y
					clc
					adc #$01
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64			// is empty?
					bne joyLeft

					// everything fine - we move
					// delete current position
					ldy #$01		// read xpos
					lda (ptrObject),y
					tay
					lda #$40		// delete current position
					sta (ptrScreen),y

					// calculate new position
					lda newPosY
					ldy #$02		// ypos
					sta (ptrObject),y
					jmp joyDown2

joyDown1:			lda #$02		// direction down
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyDown2:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyLeft:			txa
					and #$04		// check bit 3
					bne joyRight
					ldy #$0a		// read direction
					lda (ptrObject),y
					cmp #$03
					bne joyLeft1	// skip move, when changing direction

					// calculate new position
					ldy #$01		// read xpos
					lda (ptrObject),y
					sec
					sbc #$01
					sta newPosX
					ldy #$02		// read ypos
					lda (ptrObject),y
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64			// is empty?
					bne joyFire

					// everything fine - we move
					// delete current position
					ldy #$01		// read xpos
					lda (ptrObject),y
					tay
					lda #$40		// delete current position
					sta (ptrScreen),y

					// calculate new position
					lda newPosX
					ldy #$01		// read xpos
					sta (ptrObject),y
					jmp joyLeft2

joyLeft1:			lda #$03		// direction left
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyLeft2:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyRight:			txa
					and #$08
					bne joyFire
					ldy #$0a		// read direction
					lda (ptrObject),y
					cmp #$01
					bne joyRight1	// skip move, when changing direction

					// calculate new position
					ldy #$01		// read xpos
					lda (ptrObject),y
					clc
					adc #$01
					sta newPosX
					ldy #$02		// read ypos
					lda (ptrObject),y
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64			// is empty?
					bne joyFire

					// everything fine - we move
					// delete current position
					ldy #$01		// read xpos
					lda (ptrObject),y
					tay
					lda #$40		// delete current position
					sta (ptrScreen),y

					// calculate new position
					lda newPosX
					ldy #$01		// read xpos
					sta (ptrObject),y
					jmp joyRight2

joyRight1:			lda #$01		// direction right
					sta (ptrObject),y
					// copy nr of wait cycles to current cycle
joyRight2:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					//jmp joyFire


joyFire:			txa
					and #$10		// check bit 5 - fire button
					bne joyEnd

joyEnd:				nop
					rts


// Animation 2 - no movement, just cycle the animation frames
animation2:			ldy #$08			// read max phase
					lda (ptrObject),y
					sta bufPhase
					ldy #$09			// read phase
					lda (ptrObject),y
					tax
					inx
					cpx bufPhase
					bne anim21
					ldx #$00
anim21:				txa
					sta (ptrObject),y
					// copy nr of wait cycles to current cycle
					ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					rts


/**
 * S U P P O R T   F U N C T I O N S
 * ---------------------------------
 */



/**
 * Returns the number of a tile on newPosX/NewPosY in A
 */
getTileNumber:		sty bufferY			// Rescue registers in SYS call buffer

					ldy newPosY			// get pointer to screen line
					lda screenLinesLo,y
					sta pointer
					lda screenLinesHi,y
					sta pointer+1

					ldy newPosX			// get tilenumber
					lda (pointer),y

					ldy bufferY			// Restore register from SYS call buffer
					rts


