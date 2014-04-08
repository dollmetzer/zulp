/*
 * Z U L P
 * =======
 *
 * A small maze game for the Commodore 64
 * (c) 2014 Dirk Ollmetzer, www.ollmetzer.com 
 * License: GPL V3.0
 *
 * Object lists for all levels
 */


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
					.byte   3,  4,  2,144,  0,  0,  0,  0,  4,  0,  0,  2,  2,  1,  4,  0 // object 2
					.byte   3, 12,  2,145,  0,  0,  0,  0,  4,  0,  0,  3,  2,  2,  4,  0 // object 4

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

