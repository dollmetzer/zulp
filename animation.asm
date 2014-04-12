/*
 * Z U L P
 * =======
 *
 * A small maze game for the Commodore 64
 * (c) 2014 Dirk Ollmetzer, www.ollmetzer.com 
 * License: GPL V3.0
 *
 * Animation routines for game objects
 */


// Animation 0 - do nothing. skipped anyway

// Animation 1 - player movement
animation1:			ldx $dc00			// read joystick 2

					// determine start of line of the object
					ldy #$02			// read ypos
					lda (ptrObject),y
					tay
					lda screenLinesLo,y
					sta ptrScreen
					lda screenLinesHi,y
					sta ptrScreen+1

joyUp:				txa
					and #$01			// check bit 1 - up
					bne joyDown			// not up - next check down
					ldy #$0a			// read direction
					lda (ptrObject),y
					//cmp #$02
					bne joyUp3			// skip move, when changing direction

					// calculate new position
					ldy #$01			// read xpos
					lda (ptrObject),y
					sta newPosX
					ldy #$02			// read ypos
					lda (ptrObject),y
					sec
					sbc #$01
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64				// is empty?
					beq joyUp2
					cmp #128
					bcs joyUp1			// branch if tile >= 128 (object)
					jmp joyFire			// no object, but border. stop here
joyUp1:				jsr getObjectAt		// get numer of collision object
					jsr getCollisionNr	// get collision code
					jsr objectCollision
					jmp joyFire

					// everything fine - we move
					// set new position
joyUp2:				lda newPosY
					ldy #$02			// ypos
					sta (ptrObject),y
					jmp joyUp4

joyUp3:				lda #$00			// direction up
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyUp4:				ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyDown:			txa
					and #$02			// check bit 2 - down
					bne joyLeft
					ldy #$0a			// read direction
					lda (ptrObject),y
					cmp #$02
					bne joyDown3		// skip move, when changing direction

					// calculate new position
					ldy #$01			// read xpos
					lda (ptrObject),y
					sta newPosX
					ldy #$02			// read ypos
					lda (ptrObject),y
					clc
					adc #$01
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64				// is empty?
					beq joyDown2
					cmp #128
					bcs joyDown1		// branch if tile >= 128 (object)
					jmp joyFire			// no object, but border. stop here
joyDown1:			jsr getObjectAt		// get numer of collision object
					jsr getCollisionNr	// get collision code
					jsr objectCollision
					jmp joyFire
					

					// everything fine - we move
					// set new position
joyDown2:			lda newPosY
					ldy #$02			// ypos
					sta (ptrObject),y
					jmp joyDown4

joyDown3:			lda #$02			// direction down
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyDown4:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyLeft:			txa
					and #$04			// check bit 3
					bne joyRight
					ldy #$0a			// read direction
					lda (ptrObject),y
					cmp #$03
					bne joyLeft3		// skip move, when changing direction

					// calculate new position
					ldy #$01			// read xpos
					lda (ptrObject),y
					sec
					sbc #$01
					sta newPosX
					ldy #$02			// read ypos
					lda (ptrObject),y
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64				// is empty?
					beq joyLeft2
					cmp #128
					bcs joyLeft1		// branch if tile >= 128 (object)
					jmp joyFire			// no object, but border. stop here
joyLeft1:			jsr getObjectAt		// get numer of collision object
					jsr getCollisionNr	// get collision code
					jsr objectCollision
					jmp joyFire

					// everything fine - we move
					// set new position
joyLeft2:			lda newPosX
					ldy #$01			// read xpos
					sta (ptrObject),y
					jmp joyLeft4

joyLeft3:			lda #$03			// direction left
					sta (ptrObject),y

					// copy nr of wait cycles to current cycle
joyLeft4:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					jmp joyFire


joyRight:			txa
					and #$08
					bne joyFire
					ldy #$0a			// read direction
					lda (ptrObject),y
					cmp #$01
					bne joyRight3		// skip move, when changing direction

					// calculate new position
					ldy #$01			// read xpos
					lda (ptrObject),y
					clc
					adc #$01
					sta newPosX
					ldy #$02			// read ypos
					lda (ptrObject),y
					sta newPosY

					// read tilenumber on new position
					jsr getTileNumber
					cmp #64				// is empty?
					beq joyRight2
					cmp #128
					bcs joyRight1		// branch if tile >= 128 (object)
					jmp joyFire			// no object, but border. stop here
joyRight1:			jsr getObjectAt		// get numer of collision object
					jsr getCollisionNr	// get collision code
					jsr objectCollision
					jmp joyFire

					// everything fine - we move
					// set new position
joyRight2:			lda newPosX
					ldy #$01			// read xpos
					sta (ptrObject),y
					jmp joyRight4

joyRight3:			lda #$01			// direction right
					sta (ptrObject),y
					// copy nr of wait cycles to current cycle
joyRight4:			ldy #$0e
					lda (ptrObject),y
					iny
					sta (ptrObject),y
					//jmp joyFire


joyFire:			txa
					and #$10			// check bit 5 - fire button
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



/**
 * Returns the number of an object on newPosX/NewPosY in A
 */
getObjectAt:		sty bufferY
					stx bufferX
					
					lda #<objectTable+16	// Start of the objectlist - skip player
					sta pointer
					lda #>objectTable+16
					sta pointer+1
					ldx #$01			// first object (after player)

getObjectAt1:		ldy #01				// x position
					lda (pointer),y
					cmp newPosX
					bne getObjectAt2
					ldy #02				// y position
					lda (pointer),y
					cmp newPosY
					bne getObjectAt2
					txa					// number of object in a
					ldx bufferX			// restore registers
					ldy bufferY
					rts

getObjectAt2:		clc					// next object
					lda pointer
					adc #$10
					sta pointer
					lda pointer+1
					adc #$00
					sta pointer+1
					inx
					cpx #$10
					bne getObjectAt1

					sta collisionObjNr

					ldx bufferX			// restore registers
					ldy bufferY
					rts


/**
 * Get collision code for object number in A
 */
getCollisionNr:		sty bufferY
					stx bufferX
					
					tax					// object number in X
					
					lda #<objectTable	// Start of the objectlist
					sta pointer
					lda #>objectTable
					sta pointer+1
					
getCollisionNr1:	clc
					lda pointer
					adc #$10
					sta pointer
					lda pointer+1
					adc #$00
					sta pointer+1
					dex
					bne getCollisionNr1

					ldy #13				// collision code
					lda (pointer),y

					sta collisionNr
					sta 1025

					ldx bufferX
					ldy bufferY
					rts
