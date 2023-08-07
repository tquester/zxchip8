

; ---------------------------------------------------------------------------
; locate, b =x, c = y
; ---------------------------------------------------------------------------

locate:
	ld		a,b
	LD		(charX),a
	ld		a,c
	ld		(charY),a
	ret

; ---------------------------------------------------------------------------
; print 0 terminated text pointed to by hl
; ---------------------------------------------------------------------------

printTextHl:
	 ld		a,(hl)
	 inc	hl
	 cp		0
	 ret	z
	 call	printA
	 jr		printTextHl
; ---------------------------------------------------------------------------
; prints the text after the command
; 		call printtext
; 		db "hello, world",0
;		ld	a,0 ; next assembler command
; ---------------------------------------------------------------------------
printtext:
	pop		hl
printtext1:
	ld		a,(hl)
	inc		hl
	cp		0
	jr		z, printtextend
	call	printA
	jr		printtext1
printtextend:
	push 	hl
	ret
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; print the text follwing the call, replace parameters
; ld hl, 123
; push hl
; call printf
; db "hl=%lx",0
;
;	Special commands: 	/n = newline, carrage return
;						/t = tab
;						// = /
;						%d = 8 bit decimal (ld a, 123, push af)
;						%ld = 16 bit decimal (ld hl, 12345, push hl)
;						%x = 8 bit hex
;						%lx = 16 bit hex
;						%c = char (ld a, 'x', push af)
;						%s = text (ld hl, text, push hl)
;						%% = %
; since oder computers like spectrum do not have backslash we use /n instead of \n 
;
; if you have the format string in the data section call printfHL;
;						ld		hl,123
;						push	hl
;						ld		hl,text
;						call	printfHL
;						ret
;		text:			db "Hello, world %ld",0 
; ---------------------------------------------------------------------------

printf:	
 		ld		hl,0
		add		hl,sp
		pop		hl			; hl points to text following the command
; we can not call the printHL because the parameters are on the stack
; so we set b to 1 as a flag and jump back manually
		ld		b,1	
		jr		printfLoop
printfExit:		
		push	hl
		ret

		
printfHL
		ld		b,0
printfLoop:
		ld 		a,(hl)
		inc		hl
		cp		0
		jr		z,printfEnd
		cp		'%'
		jr		z, printfpar
		cp		'/'
		jp		z, printfSpecialChar
		call	printA
		jr		printfLoop
printfEnd:
		ld		a,b
		cp		1
		jr		z,printfExit
		ret

printfSpecialChar:
		ld		a,(hl)
		inc		hl
		cp		0
		jr		nz,printfSpecialChar2
		ld		a,'/'
		call 	printA
		jr		printfEnd
printfSpecialChar2:		
		cp		'n'
		jr		z,printfNewLine
		cp		'/'
		jr		z,printfSlash
		cp		't'
		jr		z,printfTab
		push	af
		ld		a,'/'
		call	printA
		pop		af
		call	printA 
		jr		printfLoop
		
printfNewLine:
		call	newline
		jr		printfLoop		

printfSlash:
		call	printA
		jr		printfLoop	
printfTab:
		ld		a,8
		call	printA
		jr		printfLoop				
printfpar:
		ld 		a,(hl)
		inc		hl
		cp		0
		jr		z,printfEnd
		cp		'@'
		jr		z,printfAt
		cp		'l'
		jr		z,printfLPar
		cp		'x'
		jr		z,printfHex2
		cp		'd'
		jr		z,printfDez2
		cp		'c'
		jr		z,printfC
		cp		'h'
		jr		z,printfHalfByte
		cp		's'
		jr		z,printfString

		push	af
		pop		af
		call	printA
		jr		printfLoop

printfHalfByte:
		pop		de
		ld		a,e
		call	printNibble
		jr		printfLoop
printfC:
		pop		af		
		call	printA
		jp		printfLoop

printfString
		pop		de
		ex		de,hl
		call	printTextHl
		ex		de,hl
		jp		printfLoop
printfHex2:
		pop		de
		ld		a,e
		call	printHex2
		jp		printfLoop

printfDez2:
		pop		de
		ld		a,e
		call	printDez2Sgn
		jp		printfLoop

printfLPar:
		ld 		a,(hl)
		inc		hl
		cp		0
		jp		z,printfEnd
		cp		'd'
		jr		z,printfDez4
		cp		'x'
		jr		z,printfHex4
		push	af
		ld		a,'%'
		call	printA
		ld		a,'l'
		call	printA
		pop		af
		call	printA
		jp		printfLoop

printfAt:
		push	bc
		call	readHex2HL
		ld		b,a
		call	readHex2HL
		ld		c,a
		call	printSetAt
		pop		bc
		jp	    printfLoop



printfDez4:
		pop		de
		ex		hl,de
		
		call	printDezHlSign
		ex		hl,de
		jp		printfLoop

printfHex4:
		ld		de,bc
		pop		bc
		call	printHex4
		ld		bc,de
		jp		printfLoop
debugvarA:
		ex      af,af
		pop		hl
debugvarA1:
		ld		a,(hl)
		inc		hl
		cp		0
		jr		z, debugvarAEnd
		call	printA
		jr		debugvarA1
debugvarAEnd:
		push 	hl
		ex      af,af
		call     printDez2Sgn
		ret

debugvarHL:
		ld      de,hl
		pop		hl
debugvarHL1:
		ld		a,(hl)
		inc		hl
		cp		0
		jr		z, debugvarHLEnd
		call	printA
		jr		debugvarHL1
debugvarHLEnd:
		push 	hl
		ld      hl,de
		call     printDezHlSign
		ret

printHL:
	PUSH	HL
	PUSH	AF
printHLLoop:
	LD		A,(HL)
	CP		0
	JR		NZ, printH1
	POP		AF
	POP		HL
	RET
printH1:
	call	printA
	INC		HL
	JR		printHLLoop	

newline:
	PUSH	AF
	LD		A,0
	LD		(charX),A
	LD		A,(charY)
	INC		A
	CP		A,24
	JR		C, newline2
	DEC		A
	call	scroll
newline2:
	LD		(charY),A
	POP		AF
	RET

readHex2HL:	
	push	bc
	ld		a,(hl)
	inc		hl
	call	readNibbleA
	add		a,a
	add		a,a	
	add		a,a
	add		a,a
	ld		b,a
	ld		a,(hl)
	inc		hl
	call	readNibbleA
	add		b
	pop		bc
	ret

readNibbleA:
	cp	'A'
	jr	z,readNibbleAA
	jr	nc,readNibbleAA
	sub	'0'
	ret
readNibbleAA:
	sub 'A'-10
	ret	


clearTextLine:
	PUSH	HL
	PUSH	BC
	PUSH	AF
	LD		B,8
clearTextLineLoop:
	PUSH	AF
	PUSH	BC
	call	calcLine
	LD		B,32
	LD		A,0
ckearTextLineLoop1:
	LD		(HL),A
	INC		HL
	DJNZ	ckearTextLineLoop1
	POP		BC
	POP		AF
	INC		A
	DJNZ	clearTextLineLoop
	POP		AF
	POP		BC
	POP		HL
	RET
scrollUp:
	PUSH	AF
	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD		A,	0
	LD		B,	192-8
scrollUpLoop:
	PUSH	AF
	PUSH	BC
	call	calcLine
	PUSH	HL
	ADD		A,8
	call	calcLine
	POP		DE
	LD		BC, 32
	LDIR
	POP		BC
	POP		AF
	INC		A
	DJNZ	scrollUpLoop
	LD		A,192-8
	call	clearTextLine
	POP		DE
	POP		HL
	POP		BC
	POP		AF
	RET

me:			call	printf
			db		"/tI am from Hamburg/n",0
			ret

; b = x; c = y
printSetAt:			push	af
					ld 		a,c
					ld 		(charY),a		
					ld		a,b
					ld		(charX),a
					pop		af
					ret

printNibble:		CP		10						; Emits a Nibble 0..9/A..F in A. 
					JR		C, printNibbleDigit
					ADD		A,55					; A = 65 - 10 = 55. If register A contains 10, we will emit "A"
					JR		printNibble2
printNibbleDigit:	ADD		A,48
printNibble2:		jp		printA					; Insteas of CALL/RET a JR is used

printHex2Sgn:       push    af
                    and     $80
                    jr      z, printHex2Sgn2
                    ld      A,'-'
                    call    printA
                    pop     af
                    neg     
                    jp      printHex2
printHex2Sgn2:      pop     af
                    jp      printHex2

printDez2Sgn:       push    af
                    and     $80
                    jr      z, printDez2Sgn2
                    ld      A,'-'
                    call    printA
                    pop     af
                    neg     
                    jr      printDezA
printDez2Sgn2:      pop     af
                    jr      printDezA


printDezA:       	push    ix
                    push    iy

					LAlloc	5

                    ld      b,0
                    ld      (iy),0
                    inc     iy

printdezLoop:       ld      l,a
                    ld      h,0
                    ld      d,10
                    push    hl
                    call    DivHLxD
                    push    hl
                    pop     bc
                    ld      h,l
                    ld      e,10
                    call    MulHxD
                    pop     de
                    
                    ex      hl,de
                    sub     hl,de
                    ld      a,l
                    add     48
                    ld      (iy),a
                    inc     iy
                    ld      a,c
                    cp      0
                    jr      nz, printdezLoop

                    dec     iy
printdezLoop2:      ld      a,(iy)
                    cp      0
                    jr      z,printdezEnd
                    call    printA
                    dec     iy
                    jr      printdezLoop2
printdezEnd:        LRelease 5	


                    pop     iy
                    pop     ix 
                    ret

printDezHlSign:     push    af
                    ld      a,h
                    and     $80
                    jr      z,printDezHlSign_1
                    push    hl
                    push    de
                    ld      a,'-'
                    call    printA
                    ld      de,hl
                    ld      hl,0
                    sbc     hl,de
                    call    printDezHL
                    pop     de
                    pop     hl
                    pop     af
                    ret
printDezHlSign_1:   call    printDezHL
                    pop     af
                    ret
printDezHL:       	push    ix
                    push    iy
                    push    hl
                    push    de
                    push    bc
					LAlloc  10



                    ld      (ix),0
                    inc     ix

printdezHLLoop:     
                    ld      d,10
                    push    hl                          ; stack = hl
                    call    DivHLxD
                    
                    push    hl                          
                    pop     bc
                    ld      de,10
                    call    Mul16BCxDE
                    pop     de                          ; de = zahl, z.b. 1234
                                                        ; hl = zahl/10*10 z.b. 1230                    
                    ex      hl,de
                    sub     hl,de
                    ld      a,l
                    add     48
                    ld      (ix),a
                    inc     ix
                    ld      hl,bc
                    ld      a,h
                    cp      0
                    jr      nz, printdezHLLoop
                    ld      a,l
                    cp      0
                    jr      nz, printdezHLLoop

                    dec     ix
printdezHLLoop2:      ld      a,(ix)
                    cp      0
                    jr      z,printdezHLEnd
                    call    printA
                    dec     ix
                    jr      printdezHLLoop2
printdezHLEnd:      LRelease 10	

                    pop     bc
                    pop     de
                    pop     hl
                    pop     iy
                    pop     ix
 
                    ret                    
printHex2:			PUSH	AF
					PUSH	AF						; Writes the HEX number in A to the Output
					SRA		A
					SRA		A
					SRA		A
					SRA		A
					AND		$0F
					call	printNibble
					POP		AF
					AND		15
					CALL	printNibble
					POP		AF
					RET

printHex4:			LD		A,B
					call	printHex2
					LD		A,C
					JR		printHex2

printPagedHL:		PUSHA
printPagePage:		call	clearScreen 
					ld		bc,0
					ld		de, charX
					call	printSetAt
printPageCharLoop:	ld		a,(charX)
					cp		32
					jr		nz, printPageCharLoop1
					call	newline
printPageCharLoop1:										
					ld		a,(hl)
					inc		hl
					cp		0
					jr		z,printPageHLEndWaitKey
					cp		' '
					call	z,printPageCheckWordWrap
					
					call	printA
					ld		a,(charY)
					cp		22
					jr		nz,printPageCharLoop
					push	hl
					call	printf
					db		"/nq quit, any key next page",0
					pop		hl
					call	GetKey
					cp		'Q'
					jr		z, printPageHLEnd
					call	clearScreen
					ld		bc,0
					call	printSetAt
					jr		printPageCharLoop



printPageCheckWordWrap:
					push	af
					push	bc
					push	hl
					inc		hl
					ld		a,(hl)
					cp		0
					jr		z, printPageCheckWordWrapEnd
					cp		10
					jr		z, printPageCheckWordWrapEnd
					cp		13
					jr		z, printPageCheckWordWrapEnd
					cp		9
					jr		z, printPageCheckWordWrapEnd
// check lenght of word
					call	wordlenHL
					cp		32
					jr		nc, printPageCheckWordWrapEnd
					ld		b,a
					ld		a,(charX)
					add		a,b
					cp		30
					jr		c, printPageCheckWordWrapEnd
					call	newline 					
					pop		hl
					pop		bc
					pop		af
					ld		a,(hl)
					inc		hl
					ret					

printPageCheckWordWrapEnd:
					pop		hl
					pop		bc
					pop		af
					ret		

printPageHLEndWaitKey:
					call	GetKey									

printPageHLEnd:		POPA	
					ret

; wordlen. Input hl = String
; 			output: a = Length of word (until 10, 13, 9, 0, 32)
wordlenHL:			push 	HL	
					push	bc
					ld		b,0
wordlenHLLoop		ld		a,(hl)
					inc		hl
					cp		0
					jr		z, wordLenEnd
					cp		10
					jr		z, wordLenEnd
					cp		13
					jr		z, wordLenEnd
					cp		9
					jr		z, wordLenEnd
					cp		32
					jr		z, wordLenEnd
					inc		b
					jr		wordlenHLLoop
wordLenEnd:			ld		a,b
					pop		bc
					pop		hl
					ret					
														

charX				db		0
charY				db		0

