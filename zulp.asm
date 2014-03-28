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
					lda #$00		// load level 0
					jsr loadLevel

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
					lda levelPtrLo,y	// write base address of level in $f8/$f9
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
					lda levelPtrLo,y	// write base address of level in $f8/$f9
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

// missing: x and y offset map/screen correction

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
					.byte   3,  1,  2,144,  0,  0,  0,  0,  4,  0,  0,  2,  2,  0,  5,  0 // object 2
					.byte   3,  1,  4,144,  0,  0,  0,  0,  4,  0,  0,  3,  2,  0,  5,  0 // object 3
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
