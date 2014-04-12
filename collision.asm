/*
 * Z U L P
 * =======
 *
 * A small maze game for the Commodore 64
 * (c) 2014 Dirk Ollmetzer, www.ollmetzer.com 
 * License: GPL V3.0
 *
 * Collision routines for game objects
 */

objectCollision:	sta 1025		// just a test
					cmp #1
					bne objColl1
					jmp Collision1
objColl1:			cmp #2
					bne objCollEnd
					jmp Collision2
objCollEnd:			rts


// Collision 0 - do nothing

// Collision 1 - collect star
Collision1:			nop

					// todo: check, if freight already exists
					lda #145
					sta 1024+37

					// turn object off
					ldy #0				// object state state
					lda #1				// state = on/invisbile
					sta (pointer),y		// object pointer from check still valid

					// move ship to new position
//					ldy #1				// object x position
//					lda newPosX
//					sta objectTable,y	// object 0 is the ship
//					ldy #2				// object y position
//					lda newPosY
//					sta objectTable,y

					rts

// collision 2 - star target
Collision2:			nop
					rts


// Some variables
collisionObjNr:		.byte 0
collisionNr:		.byte 0
