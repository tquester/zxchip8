; next board 4A10
    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	include "chip8macros.asm"
DEBUG:  equ 0
NEX:    equ 1   ;  1=Create nex file, 0=create sna file

START   equ $6000




    IF NEX == 0
        ;DEVICE ZXSPECTRUM128
        DEVICE ZXSPECTRUM48
        ;DEVICE NOSLOT64K
    ELSE
		ORG 0x4000
		;defs 0x6000 - $    ; move after screen area
		;defs 0x8000 - $
        DEVICE ZXSPECTRUMNEXT
    ENDIF

screen_top: defb    0   ; WPMEMx

; All Sprites are 8x8 Pixels ins size without color
; Prepare Sprite lays the sprite out in 8x16 Pixel so that the sprite is shifted in 8 different positions
; For bigger sprites, more than one 8x8 Pixel Sprite must be used


; The tool is called with A = Method

MAXSPRITE				EQU 	8
OPXOR					EQU		0				; Draws the sprite with XOR
OPPOKE					EQU 	1				; Draws directly to screen
OPOR					EQU		2				; OR with screen
OPAND					EQU		3				; OR with screen

DIRLEFT					EQU		0
DIRRIGHT				EQU 	1
DIRUP					EQU		2
DIRDOWN					EQU		3

CALCLINES				EQU  	0				; NO Param
PREPARESPRITE			EQU  	1				; Prepares all Sprites A = Count
SPRITEADR				EQU 	2				; Returns pointer to Sprites
SPRITECOUNT				EQU		3				; Returns the max count of sprites in HL
DRAWSPRITE				EQU  	4				; Draws sprite. 
												; L = Number
												; B=x, C=Y, 
												; H=Operation
PREPSPRITEDATA			EQU		5				; Returns the Address of a prepared sprite

CLEARSCREEN				EQU 	6				; B = Color, C = Pixeldata

DEMO					EQU		7

PLOT					EQU		8				; PLOT B=x/C=Y
												; H = Operation

LINE					EQU		9				; B=x;C=Y;D=x1;E=y1;h=Op

SCROLL					EQU		10				; B = Direction

PRINTA 					EQU 	11				; A = Char
PRINTHL					EQU		12				; HL Points to text end with 0
LOCATE					EQU		13				; b=x;c=y


ROM_CLS                 EQU  0x0DAF             ; Clears the screen and opens channel 2
ROM_OPEN_CHANNEL        EQU  0x1601             ; Open a channel
ROM_PRINT               EQU  0x203C             ; Print a string 


	ORG START
	
main:	
; bp = ec3
	IF DEBUG == 1 
	
		ld 		sp,stack_top

	ENDIF
   

   		di

		PUSHA	
		PUSH	IX
		PUSH	IY
		ld		a,i
		push	af
		if fakeinterrupt == 0
		call	startInterrupts
		endif
		call	startMain
		pop		af
		ld		i,a
		im		1
		POP		IY
		POP		IX
		POPA
		LD		BC,chip8Memory
		ei
		ret

chip8beep:
		push	af
		push	hl
		push	bc
		push	de
		ld		hl,2
		ld		bc,1
		call	beep
		pop		de
		pop		bc
		pop		hl
		pop		af
		ret
		; bc = pause (frequency)
		; hl = duration

startInterrupts:
		ld		hl,$fe00
		ld		de,hl
		inc		de
		ld            bc, 256
		; Setup the I register (the high byte of the table)
		ld            a, h
		ld            i, a
		; Set the first entries in the table to $FC
		ld            a, $FC
		ld            (hl), a
		; Copy to all the remaining 256 bytes
		ldir
		; Setup IM2 mode
		im            2
		ld			hl,$fcfc
		ld			a,$c3 		; jp
		ld			(hl),a
		inc			hl
		ld			de,isrfunc
		ld			(hl),de
		jp			$fcfc
		im 		2
		ei
		ret
 
isrfunc:	
		di
		push	ix
		push	iy
		push	hl
		push	de
		push	bc
		push	af
	;	rst 56
		call 	updateScreenInterrupt
		call	vinterrupt
		pop		af
		pop		bc
		pop		de
		pop		hl
		pop		iy
		pop		ix
		ei
		reti


	





startMain:	

	call	calcLines
	call	cls
	call	chip8Emulator
	ld		bc,chip8Memory

	ret

	include	"tools/math.asm"
	include "tools/print.asm"	
	include "tools/graphics.asm"
	include "tools/zxspectrum.asm"
	include "chip8gpu.asm"
	include "chip8cpu.asm"
	include "chip8disass.asm"
	include "chip8debugger.asm"
	include "chip8menu.asm"
	include "chip8GameMenu.asm"
	

ballsprite:
	;DB	$80, $80, $80, $80, $80, $80, $80, $80
	DB	$00, $18, $3C, $7E, $7E, $3C, $18, $00

				; 64 lines each 16 bytes (128 Pixels) + 2 Bytes padding
chip8Screen:    defs 18*64       ; 128*64 Pixels / 8 
chip8ScreenEnd:
chip8ScreenBytes:
                defs 256*4      ; Enlarged bytes from 00..FF map to 00000000 to ffffffff
schip8ScreenBytes:
                defs 256*2      ; Enlarged bytes from 00..ff map to 0000 to ffff


				db 		"$chip8memory$"
chip8Memory:    db 'Z',  'X'

chip8Font:
				db $F0, $90, $90, $90, $F0; 0
				db $20, $60, $20, $20, $70; 1
				db $F0, $10, $F0, $80, $F0; 2
				db $F0, $10, $F0, $10, $F0; 3
				db $90, $90, $F0, $10, $10; 4
				db $F0, $80, $F0, $10, $F0; 5
				db $F0, $80, $F0, $90, $F0; 6
				db $F0, $10, $20, $40, $40; 7
				db $F0, $90, $F0, $90, $F0; 8
				db $F0, $90, $F0, $10, $F0; 9
				db $F0, $90, $F0, $90, $90; A
				db $E0, $90, $E0, $90, $E0; B
				db $F0, $80, $80, $80, $F0; C
				db $E0, $90, $90, $90, $E0; D
				db $F0, $80, $F0, $80, $F0; E
				db $F0, $80, $F0, $80, $80; F

bigfont:
				db	$00, $18, $24, $42, $42, $42, $42, $24, $18, $00	;	0
				db	$00, $08, $18, $28, $08, $08, $08, $08, $3E, $00	;	1
				db	$00, $3C, $42, $02, $04, $18, $20, $40, $7E, $00	;	2
				db	$00, $3C, $42, $02, $0C, $02, $02, $42, $3C, $00	;	3
				db	$00, $0C, $14, $14, $24, $24, $44, $7E, $04, $00 	;	4
				db	$00, $7E, $40, $70, $0C, $02, $02, $46, $38, $00 	;	5
				db	$00, $1C, $62, $40, $40, $7C, $42, $42, $3C, $00	;	6
				db	$00, $3E, $02, $04, $04, $08, $08, $10, $10, $00	;	7
				db	$00, $3C, $42, $42, $3C, $42, $42, $42, $3C, $00 	;	8
				db	$00, $3C, $42, $42, $3C, $02, $02, $42, $3C, $00 	;	9
				db	$00, $18, $24, $42, $42, $42, $7E, $42, $42, $00	;	A
				db	$00, $78, $44, $42, $42, $7C, $42, $42, $7C, $00	;	B
				db	$00, $38, $44, $40, $40, $40, $40, $44, $38, $00 	;	C
				db	$00, $78, $44, $42, $42, $42, $42, $44, $78, $00	;	D
				db	$00, $7C, $40, $40, $78, $40, $40, $40, $7C, $00 	;	E
				db	$00, $7C, $40, $40, $78, $40, $40, $40, $40, $00	;	F
fontsize 		equ  $-chip8Memory

				defs	$200-fontsize,0
	incbin "samples/EnterTheMine.ch8"
;	incbin "D:\Emulator\chip8\chip8roms\Chip8-04-01-2022\Verisimilitudes\Asphyxiation (Verisimilitudes)(2020).ch8"
;		incbin "D:/Emulator/chip8/chip8roms/UPDATE-Jan-26-2021/Schip Games/Turm8 (Tobias V. Langhoff)(2020).sc8"
;	incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/2-Tests/Keypad Test [Hap, 2006].ch8"
;	incbin "D:/Emulator/chip8/Toms Test Suite/5-quirks.ch8"
;	incbin "D:/Emulator/chip8/SuperChip8-Games/Black Rainbow (by John Earnest)(2016).sc8"
;	incbin "intro_scrolltest.ch8"
;	incbin "intro.ch8"
;	incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/10 Bytes Pattern (by Bjorn Kempen)(2015).sc8"
;	incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/By the Moon (SystemLogoff)(2019).sc8"
;	incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Line Demo (unknown aauthor)(20xx).sc8"
;	incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Link Demo (by John Earnest)(2014).sc8"
;	incbin "D:/Emulator/chip8/SuperChip8-Games/Traffic (by Christian Kosman)(2018).sc8"
;	incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/By the Moon (SystemLogoff)(2019).sc8"
;    incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Trip8 Demo (2008) [Revival Studios].ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Super Trip8 Demo (by Revival Studios)(2008).sc8"
    ;incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Super Trip8 Demo (by Revival Studios)(2008).sc8"
    ;incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Super Trip8 Demo (by Revival Studios)(2008).sc8"
    ;incbin "D:/Emulator/chip8/chip8roms/SuperChip8-Demos/Progs & Demos/Super Trip8 Demo (by Revival Studios)(2008).sc8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Hello World (by Joel Yliluoma)(2015).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Jumping X and O (by Harry Kleinberg)(1977).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Kemono Friends logo (by Volgy)(2017).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/LabVIEW Splash Screen (by Richard James Lewis)(2019).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/LabVIEW Splash Screen (fix)(by Richard James Lewis)(2019).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Lainchain (by Ashton Harding)(2018).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Kemono Friends logo (by Volgy)(2017).ch8"
   ; incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Heart Monitor Demo (by Matthew Mikolay)(2015).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/8ce 8ttorney Disk1 (by SysL)(2016).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Cave Explorer (by John Earnest))(2014).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/2-alt/Rush Hour [Hap, 2006] (alt).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Death Star vs Yoda (fix)(by TodPunk)(2018).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Breakout (by Carmelo Cortez0(1979).ch8"
    ;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Demos/1-Demos/Octojam 7 Title (John Earnest)(2020).ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Space Invaders [David Winter].ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Stars [Sergey Naydenov, 2010].ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Tetris [Fran Dachille, 1991].ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Particle Demo [zeroZshadow, 2008].ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Zero Demo [zeroZshadow, 2007].ch8"
    ; incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Walking Dog (by John Earnest)(2015).ch8"
;    incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Sierpinski [Sergey Naydenov, 2010].ch8"
   ; incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Brix [Andreas Gustafsson, 1990].ch8"
    ;incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Breakout [Carmelo Cortez, 1979].ch8"
chip8InitGameLen equ $-chip8Memory

		defs 4096 - chip8InitGameLen,0

initGameInfo:
		incbin "intro.txt"
		db		0

gameInfo:	dw initGameInfo		

stack_bottom:   ; 100 bytes of stack
    defs    500, 0
stack_top	
GAME			MACRO text, filename
name:			db		text,0
				db		0
.start			dw		.end-.start
				incbin	filename
				db		0
.end 	
				ENDM				

romCollection:
				db		"$c8games$",0



chip8Games:	

				db		"Brix by Andras Gustafsson",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Brix.txt"
				db		0
chip8Game1:		dw		chip8Game1X-chip8Game1	
				incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Brix [Andreas Gustafsson, 1990].ch8"

chip8Game1X:	db		"Space Invaders/David Winter",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Space Invaders [David Winter].txt"
				db		0
chip8Game2:		dw		chip8Game2X-chip8Game2
				incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Space Invaders [David Winter].ch8"
chip8Game2X:	/*db		"Breakout by Camelo Cortez",0
				;incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Breakout [Carmelo Cortez, 1979].txt"
				db		0
chip8Game3:		dw		chip8Game3X-chip8Game3
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Breakout (by Carmelo Cortez0(1979).ch8"
chip8Game3X		*/
				db		"Tetris by Fran Dachille",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Tetris (Fran Dachille)].txt"
				db		0
chip8Game4:		dw		chip8Game4X-chip8Game4
				incbin "D:/Emulator/chip8/chip8-master/chip8-master/roms/Tetris [Fran Dachille, 1991].ch8"
chip8Game4X		
				db		"Rush Hour",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Rush Hour [Hap, 2006].txt"
				db		0
				
chip8Game5		dw 		chip8Game5X-chip8Game5
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/2-alt/Rush Hour [Hap, 2006] (alt).ch8"
				db		0

chip8Game5X		/* db		"Black Rainbow ",0
				incbin "D:/Emulator/chip8/SuperChip8-Games/manuals/BlackRainbow.txt"
				db 		0
chip8Game6:		dw		chip8Game6X-chip8Game6
				incbin  "D:/Emulator/chip8/SuperChip8-Games/Black Rainbow (by John Earnest)(2016).sc8"
chip8Game6X	
*/	
				db		"Minesweep8r by Kohli",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Minesweep8r.txt"
				db 		0
chip8Game7:		dw		chip8Game7X-chip8Game7
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Minesweep8r (James Kohli aka Hottie Pippen)(2014).ch8"
chip8Game7X		/*db		"Missile Command ",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/Missile Command.txt"
				db 		0
chip8Game8:		dw		chip8Game8X-chip8Game8
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/Missile Command (by David Winter)(19xx).ch8"
				*/
chip8Game8X		db		"Clostro",0
				incbin "D:/Emulator/chip8/chip8roms/UPDATE-Jan-26-2021/Chip-8 Games/Clostro.txt"
				db 		0
chip8Game9:		dw		chip8Game9X-chip8Game9				
				incbin "D:/Emulator/chip8/chip8roms/UPDATE-Jan-26-2021/Chip-8 Games/Clostro (jibbl)(2020).ch8"
chip8Game9X 	/*

				db		"The maze",0
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/1-Manuals/The Maze.txt"
				db 		0
chip8Game10:	dw		chip8Game10X-chip8Game10	
				incbin "D:/Emulator/chip8/chip8roms/Chip-8-Games/0-Games/The Maze (Ian Schert)(2020).ch8"		
chip8Game10X:	*/
	
romCollectionSize equ $-romCollection
chip8Game11X:	
				db		0,0
								


				db		0,0															





; total size of code block
code_size   EQU     $ - main
	MakeTape "chip8emu.tap", "zx chip8", START, code_size
;	MakeBinTape "chip8games.tap", "game", romCollection,romCollectionSize

 IF NEX == 0
        SAVESNA "z80-sample-program.sna", main
    ELSE
        SAVENEX OPEN "z80-sample-program.nex", main, stack_top
        SAVENEX CORE 3, 1, 5
        SAVENEX CFG 7   ; Border color
        SAVENEX AUTO
        SAVENEX CLOSE
    ENDIF

