
;               disass the code at iy
;               iy is not modified since all commands are
;               two bytes, we do not need op code len
chip8disass     PUSHA
                push    ix
                ld      ix,disass_text
                ld      hl,iy
                ld      de,chip8Memory
                sub     hl,de
                ld      bc,hl
                call    emitHex4
                call    emitSpace

                ld      ix,disass_text
                ld      b,(iy)
                ld      c,(iy+1)
                ld      a,b
                call    emitHex2
                call    emitSpace
                ld      a,c
                call    emitHex2
                call    emitSpace

                ld      a,b

                and     $f0
                srl     a       ; /2     
                srl     a       ; /4
                srl     a       ; /8
                ; a contains opcode * 2
                ld      de,disassJumpTable
                ld      l,a
                ld      h,0
                add     hl,de
                ld      de,(hl)
                ld      hl,de
                ld      de,chip8disassend
                push    de
                ld      a,b
                ld      d,b
                and     15
                ld      b,a
                jp      (hl)                ; call function based on jump table
; $wxyz                
; a = z
; b = z
; c = w
; d = wx
; e = yz

chip8disassend: ld      a,0
               ; ld      (ix),a
                pop     ix
                POPA
                ret





disassJumpTable
    dw      dchip8callasm        ; 0
    dw      dchip8jump           ; 1
    dw      dchip8call           ; 2
    dw      dchip8skipvxeqnn     ; 3
    dw      dchip8skipvxnenn     ; 4
    dw      dchip8skipvxeqvy     ; 5
    dw      dchip8setvxnn        ; 6
    dw      dchip8addnnvx        ; 7
    dw      dchip8setetc         ; 8
    dw      dchip89              ; 9
    dw      dchip8setindex       ; A
    dw      dchip8jumpofs        ; B
    dw      dchip8xrand          ; C
    dw      dchip8display        ; D
    dw      dchip8skipifkey      ; E
    dw      dchip8timers         ; F                

; ------------------- 0 -----------------
dchip8callasm        ; 0
                    ld  a,c
                    cp  0xE0
                    jr  z,dchip8call_cls
                    cp  0xEE
                    jr  z,dchip8call_rts
dchip8unknowncall:  call    emitText
                    db      "call ",0
                    ld      hl,bc
                    call    emitHex4
                    ret
dchip8call_cls      call    emitText  
                    db      "cls",0                  
                    ret

dchip8call_rts:     call    emitText
                    db      "rts",0
                    ret
; ------------------- 1 -----------------
dchip8jump           ; 1
                    call    emitText
                    db      "jump ",0
                    call    emitHex4
                    ret
; ------------------- 2 -----------------
dchip8call           ; 2
                    call    emitText
                    db      "call ",0
                    call    emitHex4
                    ret
; ------------------- 3 -----------------
dchip8skipvxeqnn     ; 3
0                    call    emitText
                    db      "skip if v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " = ",0
                    ld      a,c
                    call    emitHex2
                    ret
; ------------------- 4 -----------------
dchip8skipvxnenn     ; 4
                    call    emitText
                    db      "skip if v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " <> ",0
                    ld      a,c
                    call    emitHex2
                    ret
; ------------------- 5XY0 -----------------
dchip8skipvxeqvy     ; 5
                    call    emitText
                    db      "skip if v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " = v",0
                    ld      a,c
                    srl     a       ; /2     
                    srl     a       ; /4
                    srl     a       ; /8
                    srl     a       ; /16
                    call    emitNibble
                    ret
; ------------------- 6 -----------------
dchip8setvxnn        ; 6
                    call    emitText
                    db      "v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " = ",0
                    ld      a,c
                    call    emitHex2
                    ret
; ------------------- 7 -----------------
dchip8addnnvx        ; 7
                    call    emitText
                    db      "v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " += ",0
                    ld      a,c
                    call    emitHex2
                    ret
; ------------------- 8 -----------------
dchip8setetc        ld      a,c
                    and     $f
                    push    af
                    ld      a,c
                    srl     a
                    srl     a
                    srl     a
                    srl     a
                    ld      c,a
                    pop     af
        ; a = sub command
        ; b = reg y
        ; c = reg x
                    cp      0
                    jr      z,dchip8_0
                    cp      1
                    jr      z,dchip8_1
                    cp      2
                    jr      z,dchip8_2
                    cp      3
                    jr      z,dchip8_3
                    cp      4
                    jr      z,dchip8_4
                    cp      5
                    jp      z,dchip8_5
                    cp      6
                    jp      z,dchip8_6
                    cp      7
                    jp      z,dchip8_7

                    cp      $E
                    jp      z,dchip8_E
                    ret
dchip8_0:           call    emitText
                    db      "set ",0
                    call    dchip8_regX
                    call    emitText
                    db      " = ",0
                    call    dchip8_regY
                    ret

dchip8_1:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regX
                    call    emitText
                    db      " OR ",0
                    jp      dchip8_regY

dchip8_2:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regX
                    call    emitText
                    db      " AND ",0
                    jp      dchip8_regY
dchip8_3:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regX
                    call    emitText
                    db      " XOR ",0
                    jp      dchip8_regY
                    ret                    
dchip8_4:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regX
                    call    emitText
                    db      " + ",0
                    jp      dchip8_regY
                    ret                    
dchip8_5:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regX
                    call    emitText
                    db      " - ",0
                    jp      dchip8_regY
                    ret                    
dchip8_6:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regY
                    call    emitText
                    db      " >> ",0
                    jp      dchip8_regX
                    ret                    
dchip8_7:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regY
                    call    emitText
                    db      " - ",0
                    jp      dchip8_regX
                    ret                    
                 
dchip8_E:           call    dchip8_regX
                    call    emitEqual
                    call    dchip8_regY
                    call    emitText
                    db      " << ",0
                    jp      dchip8_regX
                    ret                    
dchip8_regX         ld     a,'v'
                    call   dEmitA
                    ld     a,b
                    call   emitNibble
                    ret                    

dchip8_regY         ld     a,'v'
                    call   dEmitA
                    ld     a,c
                    call   emitNibble
                    ret   

emitEqual:          call    emitText
                    db      " = ",0
                    ret                 
; ------------------- 9 -----------------
dchip89              ; 9
                    call    emitText
                    db      "skip if v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " <> v",0
                    ld      a,c
                    srl     a       ; /2     
                    srl     a       ; /4
                    srl     a       ; /8
                    srl     a       ; /16
                    call    emitNibble
                    ret
; ------------------- A -----------------
dchip8setindex       ; A
                    call    emitText
                    db      "I = ",0
                    call    emitHex4
                    ret
; ------------------- B -----------------
dchip8jumpofs        ; B
                    call    emitText
                    db      "call ",0
                    call    emitHex4
                    call    emitText
                    db      " + v0",0
                    ret
; ------------------- C -----------------
dchip8xrand          ; C
                    call    emitText
                    db      "v",0
                    ld      a,b
                    call    emitNibble
                    call    emitText
                    db      " = rnd AND ",0
                    ld      a,c
                    call    emitHex2

                    ret
; ------------------- D -----------------
dchip8display        ; D
                    call    emitText
                    db      "draw ",0
                    ld      a,b
                    call    emitNibble
                    call    emitSpace
                    ld      a,c
                    srl     a       ; /2     
                    srl     a       ; /4
                    srl     a       ; /8
                    srl     a       ; /16
                    call    emitNibble
                    call    emitSpace
                    ld      a,c
                    and     15    
                    call    emitHex2
                    ret
; ------------------- E -----------------
dchip8skipifkey      ; E
                    ld      a,c
                    cp      $9e
                    jr      z,dchip8skipifkey_9e
                    cp      $a1
                    jr      z,dchip8skipifkey_a1
                    call    emitText
                    db      "unknown code",0
                    ret
dchip8skipifkey_9e: 
                    call    emitText
                    db      "skip key v",0
                    ld      a,b
                    jp    emitNibble

dchip8skipifkey_a1: 
                    call    emitText
                    db      "skip -key v",0
                    ld      a,b
                    jp    emitNibble


emitHighReg:        srl     a       ; /2     
                    srl     a       ; /4
                    srl     a       ; /8
                    srl     a       ; /16
                    jp    emitNibble                    
; ------------------- F -----------------
dchip8timers         ; F    
                    ld      a,c
                    cp      $07
                    jr      z,chip8f_07
                    cp      $15
                    jr      z,chip8f_15
                    cp      $18
                    jr      z,chip8f_18
                    cp      $1e
                    jr      z,chip8f_1e
                    cp      $0a
                    jr      z,chip8f_0a
                    cp      $29
                    jp      z,chip8f_29
                    cp      $33
                    jp      z,chip8f_33
                    cp      $55
                    jp      z,chip8f_55
                    cp      $65
                    jp      z,chip8f_65
                    cp      $56
                    jp      z,chip8f_56
                    cp      $01
                    jp      z,chip8f_plane
                    cp      $02
                    jp      z,chip8f_audio
                    ret
chip8f_plane:       call    emitText
                    db      "plane ",0
                    jp     dchip8_regX
chip8f_audio:       call    emitText
                    db      "audio",0
                    ret
chip8f_07:          call    dchip8_regX
                    call    emitEqual
                    call    emitText
                    db      "delay",0   
                    ret

chip8f_15:          call    emitText
                    db      "delay = ",0
                    jp     dchip8_regX
chip8f_18:          call    emitText
                    db      "sound = ",0
                    jp     dchip8_regX
                    ret

chip8f_1e:          call    emitText
                    db      "I = I + ",0
                    jp     dchip8_regX
                    ret
chip8f_0a:          call    dchip8_regX
                    call    emitText
                    db      " = key (wait)",0
                    ret

chip8f_29:          call    emitText
                    db      "I = font ",0
                    call    dchip8_regX
                    ret
chip8f_33:          call    emitText
                    db      "(I)=bcd ",0
                    call    dchip8_regX
                    ret
chip8f_55:          call    emitText
                    db      "store V0..",0
                    call    dchip8_regX
                    ret
chip8f_65:          call    emitText
                    db      "load V0..",0
                    call    dchip8_regX
                    ret

chip8f_56:          call    emitText
                    db      "load V0..",0
                    call    dchip8_regX
                    ret

; ------------------- printing. Emitting text to (ix) ----------------------

dPrintText      PUSHA
                ld      hl,disass_text
dPrintText_1:   ld      a,(hl)  
                inc     hl
                cp      0
                jr      z,dPrintText_2
                call    printA     
                jr      dPrintText_1
dPrintText_2:   POPA
                ret                           

dEmitA:      ;   ld (ix),a
                inc ix
                call    printA
                ret

emitSpace:      push af 
                ld a,' '
                call dEmitA
                pop af
                ret                

emitText:                                       
            	pop		hl
demittext1:
                ld		a,(hl)
                inc		hl
                cp		0
                jr		z, demittextend
                call	dEmitA
                jr		demittext1
demittextend:
                push 	hl
                ret

emitNibble:		CP		10						; Emits a Nibble 0..9/A..F in A. 
					JR		C, emitNibbleDigit
					ADD		A,55					; A = 65 - 10 = 55. If register A contains 10, we will emit "A"
					JR		emitNibble2
emitNibbleDigit:	ADD		A,48
emitNibble2:		jp		dEmitA					; Insteas of CALL/RET a JR is used

emitHex2Sgn:       push    af
                    and     $80
                    jr      z, emitHex2Sgn2
                    ld      A,'-'
                    call    dEmitA
                    pop     af
                    neg     
                    jp      emitHex2
emitHex2Sgn2:      pop     af
                    jp      emitHex2

emitDez2Sgn:       push    af
                    and     $80
                    jr      z, emitDez2Sgn2
                    ld      A,'-'
                    call    dEmitA
                    pop     af
                    neg     
                    jr      emitDezA
emitDez2Sgn2:      pop     af
                    jr      emitDezA


emitDezA:       	push    ix
                    push    iy


                    LAlloc  5

                    ld      b,0
                    ld      (iy),0
                    inc     iy

emitdezLoop:        ld      l,a
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
                    jr      nz, emitdezLoop

                    dec     iy
emitdezLoop2:       ld      a,(iy)
                    cp      0
                    jr      z,emitdezEnd
                    call    dEmitA
                    dec     iy
                    jr      emitdezLoop2
emitdezEnd:        LRelease 5	


                    pop     iy
                    pop     ix
 
                    ret

emitDezHlSign      push    af
                    ld      a,h
                    and     $80
                    jr      z,emitDezHlSign_1
                    push    hl
                    push    de
                    ld      a,'-'
                    call    dEmitA
                    ld      de,hl
                    ld      hl,0
                    sbc     hl,de
                    call    emitDezHL
                    pop     de
                    pop     hl
                    pop     af
                    ret
emitDezHlSign_1:   call    emitDezHL
                    pop     af
                    ret
emitDezHL:       	push    ix
                    push    iy
                    push    hl
                    push    de
                    push    bc
                    LAlloc  10


                    ld      (iy),0
                    inc     iy

emitdezHLLoop:     
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
                    ld      (iy),a
                    inc     iy
                    ld      hl,bc
                    ld      a,h
                    cp      0
                    jr      nz, emitdezHLLoop
                    ld      a,l
                    cp      0
                    jr      nz, emitdezHLLoop

                    dec     iy
emitdezHLLoop2:      ld      a,(iy)
                    cp      0
                    jr      z,emitdezHLEnd
                    call    dEmitA
                    dec     iy
                    jr      emitdezHLLoop2
emitdezHLEnd:       LRelease 10	

                    pop     bc
                    pop     de
                    pop     hl
                    pop     iy
                    pop     ix
 
                    ret                    
emitHex2:			PUSH	AF
					PUSH	AF						; Writes the HEX number in A to the Output
					SRA		A
					SRA		A
					SRA		A
					SRA		A
					AND		$0F
					call	emitNibble
					POP		AF
					AND		15
					CALL	emitNibble
					POP		AF
					RET

emitHex4:			LD		A,B
					call	emitHex2
					LD		A,C
					JR		emitHex2                    


disass_text     defs    64