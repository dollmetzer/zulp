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
.var mapOffsetX		= $f4	// x offset of the map on screen
.var mapOffsetY		= $f5	// y offset of the map on screen
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
loadLevel:			tay
					lda levelPtrLo,y	// write base address of level in $f8/$f9
					sta $f8
					lda levelPtrHi,y
					sta $f9

					ldy #$00
					lda ($f8),y			// write width of map in $fa
					sta $fa
					iny
					lda ($f8),y			// write height of map in $fb
					sta $fb

					clc					// write pointer to map data in $fc/$fd
					lda $f8				// read raw level address
					adc #$02			// +2 skip width and height bytes 
					sta $fc				// save map data
					lda $f9
					adc #$00
					sta $fd
					lda #<1104			// write pointer to screen address in $fe/$ff
					sta $fe
					lda #>1104
					sta $ff

					ldx #$00		// rows
paintLvl1:			ldy #$00		// columns
paintLvl2:			lda ($fc),y
					sta ($fe),y
					iny
					cpy $fa			// width
					bne paintLvl2

					clc				// next row in map
					lda $fc
					adc $fa
					sta $fc
					lda $fd
					adc #$00
					sta $fd

					clc  			// next row on screen
					lda $fe
					adc #$28
					sta $fe
					lda $ff
					adc #$00
					sta $ff

					inx
					cpx $fb			// height
					bne paintLvl1
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

objectTable:		.fill 256, 0		// 16 Objects with 16 Bytes


/**
 * L E V E L S
 * -----------
 */
levelPtrLo:	.byte <level1
			.byte <level2
			.byte <level3

levelPtrHi:	.byte >level1
			.byte >level2
			.byte >level3

level1:		.import binary "level_1.bin"
level2:		.import binary "level_2.bin"
level3:		.import binary "level_3.bin"

			.pc = $3000
charset:	.import binary "font.bin"
/*
music:		.import c64 “music.bin”		// Import binary and skip first two bytes (loading address) 
*/
