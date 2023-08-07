; ------------------------------------------------
; calc line on screen
; requires calclines to be called
; calcline: A = Line, Returns HL = Pointer to line
; ------------------------------------------------ 
calcLine:
	PUSH	DE	
	LD		L,A
	LD		H,0
	ADD		HL,HL
	LD		DE,linedata
	ADD		HL,DE
	LD		DE,(HL)
	LD		HL,DE
	POP		DE
	ret

calcLineFast:
	LD		L,A
	LD		H,0
	ADD		HL,HL
	LD		DE,linedata
	ADD		HL,DE
	LD		DE,(HL)
	LD		HL,DE
	ret	

;----------------------------------------------
;draws a pixel at b=x,c=y with operation h
;----------------------------------------------
plot:		push	hl
			push	bc
			push	de
			push	af
			ld		d,h
			push	de
			ld		a,c
			call	calcLineFast
			ld		a,b
			srl		a		; x/2
			srl		a		; x/4
			srl		a		; x/7
			ld		e,a
			ld		d,0
			add		hl,de	; hl = byte to be written
			push	hl
			ld		hl,plotdata
			ld		a,b
			and		7
			ld		e,a
			ld		d,0
			add		hl,de
			ld		c,(hl)
			pop		hl

plot2:		pop		de
			ld		b,(hl)			; byte on screen
			ld		a,d
			cp		OPAND
			jr		z, plotand
			CP		OPOR
			jr		z, plotor
			cp		OPPOKE
			jr		z, plotpoke
			ld		a,c
			xor		b
			ld		(hl),a
			jr		plotend
plotor:		ld		a,c
			or		b
			ld		(hl),a
			jr		plotend
plotand:	ld		a,c
			and		b
			ld		(hl),a
			jr		plotend
plotpoke:	
			ld		(hl),a

plotend:	pop		af
			pop		de
			pop		bc
			pop		hl
			ret


VARX1		EQU 0
VARY1		EQU 1
VARX2		EQU 2
VARY2		EQU 3
VARDIFFX	EQU 4
VARDIFFY	EQU 6
VARABSX		EQU 8
VARABSY		EQU 7
VARSGNX		EQU 8
VARSGNY		EQU 9
VARER		EQU 10
VARSYTLE	EQU 12
; https://www.cpcwiki.eu/forum/programming/fast-line-draw-in-assembly-(breseham-algorithm)/
	; 10 REM === DRAW a LINE. Bresenham algorithm from (x1,y1) to (x2,y2)
	; 20 DX = ABS(X2 - X1) :SX = -1 :IF X1 - x2 < 0 THEN SX = 1
	; 30 DY = ABS(Y2 - Y1) :SY = -1 :IF Y1 - y2 < 0 THEN SY = 1
	; 40 ER = -DY : IF DX - dy > 0 THEN ER = DX
	; 50 ER = INT(ER / 2)
	; 60 PLOT X1,Y1
	; 70 IF X1 = X2 AND Y1 = Y2 THEN RETURN
	; 80 E2 = ER
	; 90 IF E2 +dx > 0 THEN ER = ER - DY:X1 = X1 + SX
	; 100 IF E2 -dy < 0 THEN ER = ER + DX:Y1 = Y1 + SY
	; 110 GOTO 60

	; 10 REM === DRAW a LINE. Bresenham algorithm from (x1,y1) to (x2,y2)
	; 20 DiffX = ABS(X2 - X1) :SgnX = SGN(DiffX)
	; 30 DiffY = ABS(Y2 - Y1) :SgnY = SGN(DiffY)
	; 40 ER = -DiffY : IF DiffX - DiffY > 0 THEN ER = DiffX
	; 50 ER = INT(ER / 2)
	; 60 PLOT X1,Y1
	; 70 IF X1 = X2 AND Y1 = Y2 THEN RETURN
	; 80 E2 = ER
	; 90 IF E2 +DiffX > 0 THEN ER = ER - DiffY:X1 = X1 + SgnX
	; 100 IF E2 -DiffY < 0 THEN ER = ER + DiffX:Y1 = Y1 + SgnY
	; 110 GOTO 60
line: 	PUSHA
		push	ix

		call 	plot		; draw first point
		push	bc

		push	de
		pop		bc
		call    plot		; draw last point
		pop		bc
		LAlloc	20
		
		ld		(ix+VARX1),b
		ld		(ix+VARY1),c
		ld		(ix+VARX2),d
		ld		(ix+VARY2),e
		ld		(ix+VARSYTLE),h

	; 20 DX = ABS(X2 - X1) :SX = -1 :IF X1 - x2 < 0 THEN SX = 1

		ld		l,(ix+VARX2)
		ld		h,0
		ld		e,(ix+VARX1)
		ld		d,0
		sbc		hl,de
		ld		a,h
		call	sgnHL
		ld		(ix+VARSGNX),a
		call	absHL
		ld		(ix+VARDIFFX),hl

	; 30 DiffY = ABS(Y2 - Y1) :SgnY = SGN(DiffY)
		ld		l,(ix+VARY2)
		ld		h,0
		ld		e,(ix+VARY1)
		ld		d,0
		sbc		hl,de
		call	sgnHL
		ld		(ix+VARSGNY),a
		call	absHL
		ld		(ix+VARDIFFY),hl

; 40 ER = -DiffY : IF DiffX - DiffY > 0 THEN ER = DiffX

		ld		hl,0
		ld		de,(ix+VARDIFFY)
		sbc		hl,de
		ld		(ix+VARER),hl

		ld		hl,(ix+VARDIFFX)
		ld		de,(ix+VARDIFFY)
		sbc		hl,de
		jr		NC, line_1
		ld		hl,(ix+VARDIFFX)
		ld		(ix+VARER),hl
		
line_1:	
		ld	hl,(ix+VARER)
	; 50 ER = INT(ER / 2)
		SRA H
  		RR L
		ld		(ix+VARER),hl
		

	
		
line_loop:
	;	call	debugvars
; 60 PLOT X1,Y1		
		ld		h,(ix+VARSYTLE)
		ld		b,(ix+VARX1)
		ld		c,(ix+VARY1)
		call	plot

; 70 IF X1 = X2 AND Y1 = Y2 THEN RETURN
		ld		a,b
		sub		(ix+VARX2)
		call	absA
	
		cp		2
		jr		NC, line_2
		cp		0
		jr		nz, line_2
		ld		a,c
		sub		(ix+VARY2)
		call	absA
;		cp		0
;		jr		z, line_end

		cp		2
		jr		c,line_end
line_2:
	; 80 E2 = ER
		ld		bc,(ix+VARER)

	; 90 IF E2 +DiffX > 0 THEN ER = ER - DiffY:X1 = X1 + SgnX

		LD		hl,bc
		ld		de,(ix+VARDIFFX)
		add		hl,de
		ld		a,h
		and		$80
		cp		0
		jr		nz, line_3
		ld		hl,(ix+VARER)
		ld		de,(ix+VARDIFFY)
		sbc		hl,de
		ld		(ix+VARER),hl
	

		ld		a,(ix+VARX1)
		add		a,(ix+VARSGNX)
		ld		(ix+VARX1),a
line_3:
	; 100 IF E2 -DiffY < 0 THEN ER = ER + DiffX:Y1 = Y1 + SgnY
		ld		hl,bc
		ld		de,(ix+VARDIFFY)
		sbc		hl,de
		ld		a,h
		and		$80
		cp		0
		jr		z,line_4

		ld		hl,(ix+VARER)
		ld		de,(ix+VARDIFFX)
		add		hl,de
		ld		(ix+VARER),hl

		ld		a,(ix+VARY1)
		add		a,(ix+VARSGNY)
		ld		(ix+VARY1),a

line_4:	jp		line_loop



line_end:
		LRelease 20	
		pop		ix
		POPA

		
		ret

; Draws sprite. 
; E = Number
; D = Modus
; B=x, C=Y, 
drawsprite:

; Set IY to the start of line
	PUSH	DE
	PUSH	DE
	LD		HL,linedata
	LD		E,C
	LD		D,0
	ADD		DE,DE
	ADD		HL,DE
	LD		IY,HL 
	POP		DE
; Set IX to the start of the sprite, each sprite is 8*8*2 = 16 Bytes
; 8 sprites with each one 8 lines and each line is two bytes

	
	LD		D,0
	ADD		DE,DE			; *2
	ADD		DE,DE			; *4
	ADD		DE,DE			; *8
	ADD		DE,DE			; *16
	ADD		DE,DE			; *32
	ADD		DE,DE			; *65
	ADD		DE,DE			; *128
	LD 		HL, spriteprepdata
	ADD		HL,DE


; Calc the X position. 
	LD		A,B
	AND		7
	LD		E,A
	LD		D,0
	ADD		DE,DE			; *2
	ADD		DE,DE			; *4
	ADD		DE,DE			; *8
	ADD		DE,DE			; *16
	ADD		HL,DE
	LD		IX,HL

; Calc the x offset in charater position e.g. x/8	
	LD		A,B
	SRL		A				; /2
	SRL		A				; /4
	SRL		A				; /8
	LD		E,A
	LD		D,0

; IX points to the sprite data
; IY points to the line data
; BC is the X-Offset in characters

	POP		BC
	LD		B,8
	LD		A,C
	CP		0
	JR		Z, drawspritexor
drawsprite1:
	LD		HL,(IY)		// start of line
	ADD		HL,DE		// x-offset
	LD		A,(IX)
	LD		(HL),A
	INC		HL
	INC		IX
	LD		A,(IX)
	LD		(HL),A
	INC		IX

	INC		IY
	INC		IY
	
	DJNZ	drawsprite1
	ret
drawspritexor:
	LD		HL,(IY)		// start of line
	ADD		HL,DE		// x-offset
	LD		A,(IX)
	XOR		(HL)
	LD		(HL),A
	INC		HL
	INC		IX
	LD		A,(IX)
	XOR		(HL)
	LD		(HL),A
	INC		IX

	INC		IY
	INC		IY
	
	DJNZ	drawspritexor
	ret	

prepspritedata:
	LD		HL,-1
	ret

prepsprite:
	LD		IX, spritedata
	LD		IY, spriteprepdata
	LD		B, MAXSPRITE
prepsprite1:
	PUSH	BC
	PUSH	IX
	PUSH	IY
	call	prespriteix
	POP		IY
	POP		IX
	LD		DE,8
	LD		HL,IX
	ADD		HL,DE
	LD		IX,HL

	LD		DE,8*2*8
	LD		HL,IY
	ADD		HL,DE
	LD		IY,HL
	POP		BC
	DJNZ	prepsprite1
	RET
prespriteix:
	LD		B,8
	PUSH	IY						; prepared sprite, 8 * 16 bytes
	LD		C,0
; Lay out the first row: x0 x0 x0 x0 ...
prepspriteRow0:
	LD		A,(IX)
	LD		(IY),A
	INC		IY
	LD		(IY),0
	INC		IY
	INC		IX
	DJNZ 	prepspriteRow0
	POP		IX

; IX points to the first row
; IY points to the second row
; we need still 7 passes shifted by 1 to the right	
	LD		B,7*8

prepspriteRowN:

	LD		A,(IX+0)
	LD		(IY+0),A
	LD		A,(IX+1)
	LD		(IY+1),A

	XOR		A,A
	SRL		(IY+0)
	RR		(IY+1)
	INC		IX
	INC		IX
	INC		IY
	INC		IY
	DJNZ	prepspriteRowN

	RET
spriteadr:
	LD		hl, spritedata
	ret

spritecount:
	LD		hl, spritecount
	ret



filllines:
	call	cls
	RET
	LD 		IX, linedata
	LD		B,192
	LD		C,1
filllines1:
	LD		HL,(IX)
	LD		(HL),C
	INC		C
	INC		IX
	INC		IX
	DJNZ	filllines1
	LD		HL,0
	RET	

plotdata:	db 		$80,$40,$20,$10,$8,$4,$2,$1
spritedata:
	defs	8*MAXSPRITE,0

spriteprepdata:
	DEFS	8*8*2*MAXSPRITE,255
