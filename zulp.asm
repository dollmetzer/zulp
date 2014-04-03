/*
 * Z U L P
 * =======
 *
 * A small maze game for the Commodore 64
 * (c) 2014 Dirk Ollmetzer, www.ollmetzer.com 
 * License: GPL V3.0
 *
 * Code was made for KickAssembler
 * (http://theweb.dk/KickAssembler/Main.php)
 */

.pc =$0801


/**
 * Variables
 */
.var screenChar		= $0400	// start of screen memory
.var screenColor	= $d800	// start of color memory

// zeropage variables
.var pointer		= $ea	// $ea/$eb is an universal pointer in subroutines 
.var newPosX		= $ec	// new calculated X position
.var newPosY		= $ed	// new calculated Y position
.var placeholder	= $ee	// currently unused
.var bufPhase		= $ef	// current animation phase
.var mapWidth		= $f0	// width of the current game map
.var mapHeight		= $f1	// height of the current game map
.var mapOffsetX		= $f2	// x offset of the map on screen
.var mapOffsetY		= $f3	// y offset of the map on screen
.var ptrMapdata		= $f4	// $f4/$f5 point to current map data
.var bufPosX		= $f6	// current x position
.var bufPosY		= $f7	// current y position
.var bufTile		= $f8	// Number of tile to display
.var bufObjectCount	= $f9	// object counter 0-15
.var ptrScreen		= $fa	// $fa/$fb points to current screen line
.var ptrColor		= $fc	// $fc/$fd points to current color line
.var ptrObject		= $fe	// $fe/$ff points to current object

.var bufferA		= $030c	// Buffer for Akku on SYS call
.var bufferX		= $030d	// Buffer for X-Register on SYS call
.var bufferY		= $030e	// Buffer for Y-Register on SYS call



/*
 * B a s i c s t a r t
 * -------------------
 *  2014 SYS 2062
 */
basicStart:			.byte $0b, $08, $de, $07, $9e
					.byte $20, $32, $30, $36, $32
					.byte $00, $00, $00



/*
 * P r o g r a m s t a r t
 * -----------------------
 */
startProgram:		jsr initProgram
					jsr title
					lda #$00
					sta mode
					jsr gameStart
					
					// todo: wait for mode 0 and return to title
					rts



/**
 * P r o g r a m   i n i t i a l i s a t i o n
 * -------------------------------------------
 */
initProgram:		lda #$00
					sta $d020		// black border
					sta $d021		// black background
					lda #$1c		// char memory is 12288...
					sta $d018
					rts


/**
 * T i t l e s c r e e n
 * ---------------------
 */
title:				ldy #$00
title1:				lda titleScreen,y
					beq titleWait
					jsr $ffd2
					iny
					jmp title1
					nop

					// wait for joystick fire
titleWait:			lda $dc00   	// read joystick 2
					and #$10		// check bit 5 - fire button
					bne titleWait	// no fire
					ldy #$00
titleWait1:			dey				// short delay
					nop
					bne titleWait1
					// wait for release fire
titleWait2:			lda $dc00   	// read joystick 2
					and #$10		// check bit 5 - fire button
					beq titleWait2	// fire
					rts

titleScreen:		.byte 154,147 // light blue, CLR
					.text "Z U L P"
					.byte  13, 13
					.text "PRESS FIRE TO START"
					.byte  0, 0, 0



/**
 * G a m e   s t a r t
 * -------------------
 */
gameStart:			lda #$00		// reset level
					sta level
					sta freight		// reset freight
					sta score		// reset score
					sta score+1
					sta score+2
					lda #$03		// reset lives
					sta lives
					lda #$01		// reset energy
					sta energy
					lda #$00
					sta energy+1

					jsr gameScreen	// prepare screen
					lda level		
					jsr loadLevel

					sei				// disable interrupt
					lda #<gameLoop	// set IRQ Pointer to gameloop
					sta $0314
					lda #>gameLoop
					sta $0315
					asl $d019		//
					lda #$7b		//
					sta $dc0d		// CIA Interrupt Control and Status
					lda #$81		// set interrupt request to raster
					sta $d01a
					lda #$1b 		// set raster row
					sta $d011 
					lda #$c0 
					sta $d012
					cli

					rts



/**
 * G a m e   S c r e e n
 * ---------------------
 * Write Top Line on game screen
 */
gameScreen:			ldy #$00
gameScreen1:		lda headline,y
					beq gameScreen2
					jsr $ffd2
					iny
					jmp gameScreen1
gameScreen2:		rts


headline:			.byte  154,147,151 // light blue, CLR, gray 1
					.text "SHP:"
					.byte 152
					.text "0 "
					.byte 151
					.text "LVL:"
					.byte 152
					.text "00 "
					.byte 151
					.text "PTS:"
					.byte 152
					.text "000000 "
					.byte 151
					.text "NRG:"
					.byte 152
					.text "100 "
					.byte 151
					.text "FRT:"
					.byte 152
					.text "    "
					.text "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
					.byte    0,  0,  0



/**
 * L o a d   l e v e l
 * -------------------
 * Number of level in Akkumulator
 */
loadLevel:			sta level
					tay
					lda levelPtrLo,y	// write base address of level
					sta ptrObject		// 'lending' the pointer for calculation
					lda levelPtrHi,y
					sta ptrObject+1

					// write width and height of the map
					ldy #$00
					lda (ptrObject),y
					sta mapWidth
					iny
					lda (ptrObject),y
					sta mapHeight

					// calculate map offset on screen
					sec
					lda #$28
					sbc mapWidth
					lsr					// difference / 2
					sta mapOffsetX
					sec
					lda #25
					sbc mapHeight
					lsr
					sta mapOffsetY

					// write pointer to map data
					clc
					lda ptrObject		// read raw level address
					adc #$02			// +2 skip width and height bytes
					sta ptrMapdata		// save map data
					lda ptrObject+1
					adc #$00
					sta ptrMapdata+1

					// write pointer to object data
					ldy level
					lda levelPtrLo,y	// write base address of object data
					sta ptrObject		// 'lending' the pointer for calculation
					lda levelPtrHi,y
					sta ptrObject+1

					// write pointer to screen with y and x offset
					clc
					ldy mapOffsetY
					lda screenLinesLo,y	// get low byte of first screen line
					adc mapOffsetX		// add x offset
					sta ptrScreen
					lda screenLinesHi,y
					adc #$00
					sta ptrScreen+1

					// paint map on screen
					ldx #$00		// rows
paintLvl1:			ldy #$00		// columns
paintLvl2:			lda (ptrMapdata),y
					sta (ptrScreen),y
					iny
					cpy mapWidth
					bne paintLvl2

					clc				// next row in map
					lda ptrMapdata
					adc mapWidth
					sta ptrMapdata
					lda ptrMapdata+1
					adc #$00
					sta ptrMapdata+1

					clc  			// next row on screen
					lda ptrScreen
					adc #$28
					sta ptrScreen
					lda ptrScreen+1
					adc #$00
					sta ptrScreen+1

					inx
					cpx mapHeight
					bne paintLvl1

					// clear object table
					ldy #$00
					lda #$00
clearObjTable:		sta objectTable,y
					iny
					bne clearObjTable

					// load objectdata
					ldy level
					lda levelObjPtrLo,y
					sta ptrObject
					lda levelObjPtrHi,y
					sta ptrObject+1

					lda #<objectTable-1
					sta ptrScreen		// 'lending' the pointer
					lda #>objectTable-1
					sta ptrScreen+1

					ldy #$00
					lda (ptrObject),y
					sta objectNumber	// get number of objects

					tax					// number of objects
copyObjectTable:	ldy #$10			// object has 16 bytes
copyObjectTable1:	lda (ptrObject),y
					sta (ptrScreen),y
					dey
					bne copyObjectTable1

					clc
					lda ptrObject
					adc #$10
					sta ptrObject
					lda ptrObject+1
					adc #$00
					sta ptrObject+1

					clc
					lda ptrScreen
					adc #$10
					sta ptrScreen
					lda ptrScreen+1
					adc #$00
					sta ptrScreen+1

					dex
					bne copyObjectTable

					// x and y offset map/screen correction
					// mapOffsetX
					lda #<objectTable	// Start of the objectlist
					sta ptrObject
					lda #>objectTable
					sta ptrObject+1
					lda #$00			// first object
					sta bufObjectCount

correctObjOffset:	ldy #$01	// xpos
					clc
					lda (ptrObject),y
					adc mapOffsetX
					sta (ptrObject),y
					ldy #$02	// ypos
					clc
					lda (ptrObject),y
					adc mapOffsetY
					sta (ptrObject),y
					
					clc					// calc start of next object list
					lda ptrObject
					adc #$10
					sta ptrObject
					lda ptrObject+1
					adc #$00
					sta ptrObject+1
					// next object or end of correction
					inc bufObjectCount
					lda bufObjectCount
					cmp #$10
					bne correctObjOffset

					rts



/**
 * G a m e   L o o p
 * -----------------
 * Raster interrupt routine
 */
gameLoop:			asl $d019		// delete IRQ flag
					lda #$0b
					sta $d020

					jsr objectHandle
				
					lda #$00
					sta $d020
					pla				// restore a, y and x
					tay
					pla
					tax
					pla
					rti				// return from interrupt



/**
 * O b j e c t   H a n d l e
 * -------------------------
 * One complete cycle over the object table
 */
objectHandle:		lda #<objectTable	// Start of the objectlist
					sta ptrObject
					lda #>objectTable
					sta ptrObject+1
					lda #$00			// first object
					sta bufObjectCount

objectLoop:			ldy #$00			// read state
					lda (ptrObject),y	// check state active
					and #$01
					beq objectNext		// if not active, skip object

					ldy #$0f			// read number of phases to skip
					lda (ptrObject),y
					beq objectLoop1
					sec					// reduce phases to skip and end this object
					sbc #$01		
					sta (ptrObject),y
					jmp objectLoop2				

objectLoop1:		jsr objectAnimation	// animate object

objectLoop2:		ldy #$00			// read state
					lda (ptrObject),y	// check state visible
					and #$02			
					beq objectNext		// if not visible, skip object

					jsr objectPlot		// plot object

objectNext:			clc					// calc start of next object list
					lda ptrObject
					adc #$10
					sta ptrObject
					lda ptrObject+1
					adc #$00
					sta ptrObject+1
					inc bufObjectCount	// skip to next object
					lda bufObjectCount
					cmp #$10
					bne objectLoop

objectEnd:			rts



/**
 * O b j e c t   A n i m a t i o n
 * -------------------------------
 */
objectAnimation:	ldy #$0c			// read animation number
					lda (ptrObject),y
					beq objAnimEnd
objAnim1:			cmp #$01
					bne objAnim2
					jsr animation1
objAnim2:			cmp #$02
					bne objAnimEnd
					jsr animation2
objAnimEnd:			rts



/**
 * O b j e c t   P l o t
 * ---------------------
 *
 */
objectPlot:			nop
					// --- start calculate tilenumber
					// Tilenumer = Basetile + shift[direction] + phase*2
					ldy #$09			// read phase
					lda (ptrObject),y
					asl					// phase * 2
					sta bufTile

					ldy #$0a			// read direction
					clc
					lda (ptrObject),y
					adc #$04			// get shift[direction]
					tay
					clc
					lda (ptrObject),y
					adc bufTile
					sta bufTile
				
					ldy #$03			// read basetile
					clc
					lda (ptrObject),y
					adc bufTile
					sta bufTile			// now we have our current tile
					// --- end calculate tilenumber

					ldy #$02			// read y pos
					lda (ptrObject),y
					tay
					lda screenLinesLo,y	// get memory of the line beginning
					sta ptrScreen
					lda screenLinesHi,y
					sta ptrScreen+1
					lda colorLinesLo,y	// get memory of the line beginning
					sta ptrColor
					lda colorLinesHi,y
					sta ptrColor+1

					ldy #$01			// read x pos
					lda (ptrObject),y
					sta	bufPosX			// rescue xpos for color setting
					tay
					lda bufTile			// get tilenumerber
					sta (ptrScreen),y

					ldy #$0b			// read color
					lda (ptrObject),y
					ldy bufPosX			// restore x pos
					sta (ptrColor),y

					rts



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
 * G a m e   v a r i a b l e s
 * --------------------------- 
 */
mode:				.byte $00			// 0=finished, 1=running
level:				.byte $00			// current game level
freight:			.byte $00			// current freight color (0=none)
lives:				.byte $00			// remaining lives
energy:				.byte $00, $00		// BCD coded energy level
score:				.byte $00, $00, $00	// BCD coded game score
objectNumber:		.byte $00			// Number of objects in current level

objectTable:		.fill 256, 0		// 16 Objects with 16 Bytes

screenLinesLo:		.byte <1104
					.byte <1144
					.byte <1184
					.byte <1224
					.byte <1264
					.byte <1304
					.byte <1344
					.byte <1384
					.byte <1424
					.byte <1464
					.byte <1504
					.byte <1544
					.byte <1584
					.byte <1624
					.byte <1664
					.byte <1704
					.byte <1744
					.byte <1784
					.byte <1824
					.byte <1864
					.byte <1904
					.byte <1944
					.byte <1984
					.byte <2024
screenLinesHi:		.byte >1104
					.byte >1144
					.byte >1184
					.byte >1224
					.byte >1264
					.byte >1304
					.byte >1344
					.byte >1384
					.byte >1424
					.byte >1464
					.byte >1504
					.byte >1544
					.byte >1584
					.byte >1624
					.byte >1664
					.byte >1704
					.byte >1744
					.byte >1784
					.byte >1824
					.byte >1864
					.byte >1904
					.byte >1944
					.byte >1984
					.byte >2024

colorLinesLo:		.byte <55376
					.byte <55416
					.byte <55456
					.byte <55496
					.byte <55536
					.byte <55576
					.byte <55616
					.byte <55656
					.byte <55696
					.byte <55736
					.byte <55776
					.byte <55816
					.byte <55856
					.byte <55896
					.byte <55936
					.byte <55976
					.byte <56016
					.byte <56056
					.byte <56096
					.byte <56136
					.byte <56176
					.byte <56216
					.byte <56256
colorLinesHi:		.byte >55376
					.byte >55416
					.byte >55456
					.byte >55496
					.byte >55536
					.byte >55576
					.byte >55616
					.byte >55656
					.byte >55696
					.byte >55736
					.byte >55776
					.byte >55816
					.byte >55856
					.byte >55896
					.byte >55936
					.byte >55976
					.byte >56016
					.byte >56056
					.byte >56096
					.byte >56136
					.byte >56176
					.byte >56216
					.byte >56256

/**
 * L E V E L S
 * -----------
 */
levelPtrLo:			.byte <level1
					.byte <level2
					.byte <level3

levelPtrHi:			.byte >level1
					.byte >level2
					.byte >level3

level1:				.import binary "level_1.bin"
level2:				.import binary "level_2.bin"
level3:				.import binary "level_3.bin"


levelObjPtrLo:		.byte <levelObjects1
					.byte <levelObjects2
					.byte <levelObjects3

levelObjPtrHi:		.byte >levelObjects1
					.byte >levelObjects2
					.byte >levelObjects3

/**
 * O B J E C T L I S T S
 * ---------------------
 * 0  state			- 0=off, 1=on, 2=visible
 * 1  xpos			- xpos on screen
 * 2  ypos			- ypos on screen (ignoring first two lines)
 * 3  basetile		- Number of first tile, direction 1, phase 1
 * 4  shift0		- Add for direction 0
 * 5  shift1		- Add for direction 1
 * 6  shift2		- Add for direction 2
 * 7  shift3		- Add for direction 3
 * 8  maxphase		- max phase (0=one phase, 1=2phases)
 * 9  phase			- current phase
 * 10 direction		- current direction
 * 11 color			- number of color
 * 12 animationNr	- Number of the animation
 * 13 contactNr		- Number of the action when contact
 * 14 animateDelay	- Number of frames to wait for next step
 * 15 waitstate		- Current remaing frames to skip before next step 
 */
levelObjects1:		.byte   5	// 3 objects
					.byte   3,  8,  2,128,  0,  4,  8, 12,  1,  0,  0,  1,  1,  0,  4,  0 // player
					.byte   3,  4,  2,144,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  4,  0 // object 2
					.byte   3, 12,  2,145,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  4,  0 // object 4

levelObjects2:		.byte   5	// 5 objects
					.byte   3,  8,  4,128,  0,  4,  8, 12,  1,  0,  0,  1,  1,  0,  4,  0 // player
					.byte   3,  3,  2,144,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  4,  0 // object 2
					.byte   3, 13,  5,144,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  5,  0 // object 3
					.byte   3,  1,  2,145,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  4,  0 // object 4
					.byte   3, 15,  5,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 5

levelObjects3:		.byte   9	// 5 objects
					.byte   3,  7,  3,128,  0,  4,  8, 12,  1,  0,  0,  1,  1,  0,  4,  0 // player
					.byte   3,  1,  2,144,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  5,  0 // object 2
					.byte   3,  1,  4,144,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 3
					.byte   3, 13,  4,145,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  5,  0 // object 4
					.byte   3, 13,  2,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 5
					.byte   3,  3,  5,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 6
					.byte   3, 11,  1,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 7
					.byte   3,  5,  1,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 6
					.byte   3,  9,  5,145,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 7


			.pc = $3000
charset:	.import binary "font.bin"
/*
music:		.import c64 “music.bin”		// Import binary and skip first two bytes (loading address) 
*/
