screen_maxx             EQU     256
screen_maxy             EQU     192
screen_byte_line        equ     32
screen_size             EQU     32*192
screen_start            EQU     $4000
screen_len				EQU 	6144

SCREEN_ATTR				EQU		$4000+6144
attrib_len				equ		768
screen_char_maxx        EQU     32
screen_char_maxy        EQU     24

CHARSET				    EQU		15360

PAPER					EQU		8

BLACK					equ 	0
BLUE					equ		1
RED						equ		2
PINK					equ		3
GREEN					equ		4
LIGHTBLUE				equ		5
YELLOW					equ		6
WHITE					equ		7





; -------------------------------------------------------------------
; print the character in register A at charX, charY. 
; wrap line and scroll
; -------------------------------------------------------------------
printA:
	PUSH	AF
	PUSH	IX
	PUSH	BC
	PUSH	DE
	PUSH	HL
	cp		8
	jr		z,	printTab
	cp		9
	jr		z,	printTab
	cp		10
	jr		z,	printNewline
	cp		13
	jp		z,  printCarriageReturn 
	LD		L,	A
	LD		H,  0
	ADD		HL, HL
	ADD		HL, HL
	ADD		HL, HL
	LD		DE, CHARSET
	ADD		HL, DE
	LD		IX, HL			; ix points to the charmap of ascii A

; calc attribute address
	LD		a, (charY)		
	ld		l,a
	ld		h,0
	add		hl,hl				; * 2
	add		hl,hl				; * 4
	add		hl,hl				; * 8
	add		hl,hl				; * 16
	add		hl,hl				; * 32
	ld		a,(charX)
	ld		e,a
	ld		d,0
	add		hl,de
	ld		de, SCREEN_ATTR
	add		hl,de
	ld		a,(charAttrib);
	ld		(hl),a


	LD		A, (charY)		
	LD		L, A
	LD		H, 0
	ADD		HL, HL			
	ADD		HL, HL
	ADD		HL, HL			; *8, since each char is 8 lines high
	ADD		HL, HL			; *2, for word length
	LD		DE, linedata
	ADD		HL, DE
	LD		DE,(HL)
	LD		HL,DE

	LD		A, (charX)
	LD		E, A
	LD		D, 0
	ADD		HL, DE			; HL points to the line data
	LD		B,8
	LD		DE, 256
printALoop:
	LD		A,(IX)
	LD		(HL),A
	INC		IX
	ADD		HL, DE
	DJNZ	printALoop

;Advance the pointer, go to next line	
	LD		A, (charX)
	INC		A
	LD		(charX),A
	CP		32
	JR 		C, printAEnd
	call	newline

printAEnd:
	POP		HL
	POP		DE
	POP		BC
	POP		IX
	POP		AF
	ret

printTab:
	ld		a,(charX)
	and		$ff-3
	add		4
	cp		screen_char_maxx 
	jr		nc,printTab1
	ld		(charX),a
	jr		printAEnd
printTab1:
	call	newline
	jr		printAEnd

printNewline:
	ld		a,(charY)
	cp		screen_char_maxy
	jr		c, printNewline2
	inc		a
	ld		(charY),a
	jr		printAEnd
printNewline2:
	call	scroll
	jr		printAEnd


printCarriageReturn:
	call	newline
	jr		printAEnd


GetKey:                 call    ReadKeyboard
                        cp      0
                        jr      z,GetKey

WaitKeyRelease:         push af
WaitKeyRelease1:        call    ReadKeyboard
                        cp      0
                        jr      nz,WaitKeyRelease1
                        pop     af
                        ret
ReadKeyboard:           
                        PUSH    HL
                        PUSH    DE
                        PUSH    BC    
 
                        LD HL,Keyboard_Map                      ; Point HL at the keyboard list
                        LD D,8                                  ; This is the number of ports (rows) to check
                        LD C,$FE                                ; C is always FEh for reading keyboard ports
Read_Keyboard_0:        LD B,(HL)                               ; Get the keyboard port address from table
                        INC HL                                  ; Increment to list of keys
                        IN A,(C)                                ; Read the row of keys in
                        AND $1F                                 ; We are only interested in the first five bits
                        LD E,5                                  ; This is the number of keys in the row
Read_Keyboard_1:        SRL A                                   ; Shift A right; bit 0 sets carry bit
                        JR NC,Read_Keyboard_2                   ; If the bit is 0, we've found our key
                        INC HL                                  ; Go to next table address
                        DEC E                                   ; Decrement key loop counter
                        JR NZ,Read_Keyboard_1                   ; Loop around until this row finished
                        DEC D                                   ; Decrement row loop counter
                        JR NZ,Read_Keyboard_0                   ; Loop around until we are done
                        AND A                                   ; Clear A (no key found)
                        POP     BC
                        POP     DE
                        POP     HL
                        RET
Read_Keyboard_2:		
                        LD A,(HL)                               ; We've found a key at this point; fetch the character code!
                        POP     BC
                        POP     DE
                        POP     HL
                        RET

ReadMKeyboard:           
                        PUSH    HL
                        PUSH    DE
                        PUSH    BC    
						PUSH	IX
;						ld		bc,$0116
;						call	printSetAt  						
;						ld      a,$14*8
;						call    clearTextLine						

						ld		ix,ReadKeyboardPressedKeys
						ld		(ix),0
                        LD HL,Keyboard_Map                      ; Point HL at the keyboard list
                        LD D,8                                  ; This is the number of ports (rows) to check
                        LD C,$FE                                ; C is always FEh for reading keyboard ports
ReadMKeyboard_0:        LD B,(HL)                               ; Get the keyboard port address from table
                        INC HL                                  ; Increment to list of keys
                        IN A,(C)                                ; Read the row of keys in
                        AND $1F                                 ; We are only interested in the first five bits
;						call	printHex2
                        LD E,5                                  ; This is the number of keys in the row
ReadMKeyboard_1:        SRL A                                   ; Shift A right; bit 0 sets carry bit
                        JR C,ReadMKeyboard_2                   ; If the bit is 0, we've found our key
						push	af
						ld		a,(hl)
						ld		(ix),a
						inc		ix
						ld		(ix),0
						pop		af
ReadMKeyboard_2:								
                        INC HL                                  ; Go to next table address
                        DEC E                                   ; Decrement key loop counter
                        JR NZ,ReadMKeyboard_1                   ; Loop around until this row finished
                        DEC D                                   ; Decrement row loop counter
                        JR NZ,ReadMKeyboard_0                   ; Loop around until we are done
                        AND A                                   ; Clear A (no key found)
						ld		hl,ReadKeyboardPressedKeys
;						ld		bc,$0014
;						call	printSetAt
;						call	printHL
						POP		IX
                        POP     BC
                        POP     DE
                        POP     HL
                        RET

		

ReadKeyboardPressedKeys:defs 5*8+1,0						

cls:
                        LD		HL,$4000
                        LD		BC,6144
cls1:
                        LD		A,$00
                        LD		(HL),A
                        INC		HL
                        DEC		BC
                        LD    A,B
                        OR    C
                        JP		NZ, cls1
                        LD		BC,768
cls2:
                        LD		A,$7*8+0
                        LD		(HL),A
                        INC		HL
                        DEC		BC
                        LD    A,B
                        OR    C
                        JP		NZ, cls2
                        RET
calcLines:
                        LD		IX, linedata
                        LD		HL, 16384

                        LD		B, 3					// for block=1 to 3
calclines1:
                        PUSH	BC						// for
                        PUSH	HL						// base1=base
                        LD		B,8						// for b = 1 to 8

calclines2:
                        PUSH	BC
                        PUSH	HL						// 
                        LD		B,8
                        LD		DE, 256
calclines3:
                        LD	(IX), HL
                        INC	IX
                        INC	IX
                        ADD	HL,DE
                        DJNZ calclines3

                        POP		HL
                        POP		BC
                        LD		DE, 32
                        ADD		HL, DE
                        DJNZ	calclines2

                        POP		HL
                        POP		BC
                        LD		DE, 2048
                        ADD		HL, DE
                        DJNZ	calclines1
                        LD		HL,0				// OK
                        RET   

changeScreenAttrib:
                push    hl
                push    de
                ld      a,(screenCurAttrib)
                inc     a
                cp      screenMaxAttrib
                jr      c,changeScreenAttrib2
                ld      a,0
changeScreenAttrib2:
                ld      (screenCurAttrib),a
                call    setCurrentScreenAttributes
                pop     de
                pop     hl
                ret

setCurrentScreenAttributes:                
                ld      a,(screenCurAttrib);
                ld      e,a
                ld      d,0
                ld      hl,screenAttribs
                add     hl,de
                ld      a,(hl)
                call    setGameScreenAttributes
                ld      hl,SCREEN_ATTR+32*16
                ld      bc,(24-16)*32
                ld      a,LIGHTBLUE*PAPER+BLACK
                call    setGameScreenAttributesHLBC

                ret

; a = attribute
setGameScreenAttributes
                ld      hl,SCREEN_ATTR
                ld      bc,32*16
setGameScreenAttributesHLBC
                push    de
                ld      d,a
setGameScreenAttributesLoop:
                ld      (hl),d
                inc     hl
                dec     bc
                ld      a,c
                or      a
                jr      nz, setGameScreenAttributesLoop
                ld      a,b
                or      a
                jr      nz, setGameScreenAttributesLoop
                pop     bc
                ret

screenAttribs:  db      BLACK*PAPER+WHITE
                db      WHITE*PAPER+BLACK
                db      BLUE*PAPER+WHITE
                db      WHITE*PAPER+BLUE
screenCurAttrib db      0
screenMaxAttrib equ     screenCurAttrib-screenAttribs						

clearScreen:		push	af
					push	bc
					push	hl
					ld		hl, screen_start
					ld		bc, screen_len
clearScreenLoop:	ld		a,0
					ld		(hl),a
					inc		hl
					dec		bc
					ld		a,c
					cp		0
					jr		nz,clearScreenLoop
					ld		a,b
					cp		0
					jr		nz,clearScreenLoop

					ld		hl, SCREEN_ATTR
					ld		bc, attrib_len
					
clearAttribLoop:	ld		a, WHITE*PAPER+BLACK
					ld		(hl),a
					inc		hl
					dec		bc
					ld		a,c
					cp		0
					jr		nz,clearAttribLoop
					ld		a,b
					cp		0
					jr		nz,clearAttribLoop

					pop		hl
					pop		bc
					pop		af
					ret 	


clearLowerScreenWhite:
					ld		a,WHITE*PAPER+BLACK
					jr  	clearLowerScreen
clearLowerScreenBlue:
					ld		a,LIGHTBLUE*PAPER+BLACK


; clears the screen from line 16 to 24 with the color in a
clearLowerScreen:	push	bc
					push	hl
					push	af
					ld		c,129
					ld		b,192-129
clearLowerScreen1:	ld		a,c
					call	calcLine
					push	bc
					ld		b,32
					ld		a,0
clearLowerScreen2:	ld		(hl),a
					inc		hl
					djnz	clearLowerScreen2
					pop		bc
					inc		c
					djnz	clearLowerScreen1

					pop		af
					ld		hl,SCREEN_ATTR+32*16
					ld		b,(24-16)*32
clearLowerScreen3:	ld		(hl),a
					inc		hl
					djnz	clearLowerScreen3
					pop		hl
					pop		bc
					ret																								

markScreen:		push	af
					push	bc
					push	hl
					ld		hl, 0x4000
					ld		bc, 6144
markScreenLoop:		ld		a,(hl)
					cp		0
					jr		nz,markScreenLoop1
					ld		(hl),$aa
markScreenLoop1:			
					inc		hl
					dec		bc
					ld		a,c
					cp		0
					jr		nz,markScreenLoop
					ld		a,b
					cp		0
					jr		nz,markScreenLoop
					pop		hl
					pop		bc
					pop		af
					ret 	

beep:	ld		a,(border)		; fetch border
		or		$08

beeploop2:
		push 	bc
		xor  %00010000
		out	 ($fe),a
beeploop1:
		dec	 c
		jr	nz, beeploop1
		cp	b,0
		jr	z,beeploop1x
		ld	e,a
		ld	 a,b
		cp	 0
		jr	z,beeploop1x
		ld	 a,e
		dec  b
		jr	nz, beeploop1
beeploop1x:		
		ld 	a,e
		pop	bc
		ld	 e,a
		dec  l
		jr   nz,beeploop2
		ld	 a,h
		cp	0
		jr	z,beeploop2x
		ld	a,e
		dec	 h
beeploop2x:		
		jr	 nz,beeploop2
		ret


border:	db	7
                     
; --------------- data section ------------------------- 
Keyboard_Map:           DB $FE,"#","Z","X","C","V"
                        DB $FD,"A","S","D","F","G"
                        DB $FB,"Q","W","E","R","T"
                        DB $F7,"1","2","3","4","5"
                        DB $EF,"0","9","8","7","6"
                        DB $DF,"P","O","I","U","Y"
                        DB $BF,"#","L","K","J","H"
                        DB $7F," ","#","M","N","B"   

linedata:               defs	192*2,0                             
