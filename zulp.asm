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
gameStart:			lda #$02		// reset level
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
objectPlot:			ldy bufObjectCount		// load object number
					lda objPosTableLo,y
					sta objectPlot1+1
					lda objPosTableHi,y
					sta objectPlot1+2
					lda objPosTableX,y
					tay
					lda #64
objectPlot1:		sta $0000,y				// delete object on last position

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

					// save pointer to screen adress
					tya
					ldy bufObjectCount
					sta objPosTableX,y
					lda ptrScreen
					sta objPosTableLo,y
					lda ptrScreen+1
					sta objPosTableHi,y

					rts


// animation routines
.import source "animation.asm"


// collision routines
.import source "collision.asm"


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

objPosTableLo:		.fill 16,0			// Lo Bytes of line start
objPosTableHi:		.fill 16,0			// Hi Bytes of line start
objPosTableX:		.fill 16,0			// X Offset

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


// objectlists for levels
.import source "objectlist.asm"


/**
 * N e w   F o n t
 * ---------------
 */
			.pc = $3000
charset:	.import binary "font.bin"
/*
music:		.import c64 “music.bin”		// Import binary and skip first two bytes (loading address) 
*/
