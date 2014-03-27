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



/*
 * B a s i c s t a r t
 * -------------------
 *  2014 SYS2062
 */
basicStart:			.byte $0b, $08, $de, $07
					.byte $9e, $32, $30, $36
					.byte $32, $00, $00, $00



/*
 * P r o g r a m s t a r t
 * -----------------------
 */
startProgram:		nop
					rts



/**
 * P r o g r a m   i n i t i a l i s a t i o n
 * -------------------------------------------
 */
initProgram:		nop
					rts


/**
 * T i t l e s c r e e n
 * ---------------------
 */
title:				nop
					rts



/**
 * G a m e   s t a r t
 * -------------------
 */
gameStart:			nop
					rts



/**
 * L o a d   l e v e l
 * -------------------
 */
loadLevel:			nop
					rts



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
charset:	.import binary "chars.bin"
