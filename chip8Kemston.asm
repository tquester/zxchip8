
chip8KemstonMenu:
        di
        call    clearScreen
        call    printf
        db      "%@0800ZXChip8%@0702Kemston Joystick/n/n",0

chip8kemstonMenuLoop:        
;        call     printf
;        db       "%@0103Press any key\nthen move the joystick/nEnter to exit",0
        call    kprintkeys
        call    printJoyAssignment
        ld      hl,strOff
        ld      a,(kempstonOn)
        cp      1
        call    z, setStrOn

        push    hl
        ld      b,0
        ld      c,14
        call    printSetAt
        
        call    printf
        db      "Kempston is %s/n/n"
    
        db      "/tM/tGo to Main menu/n"
        db      "/tK/tKempston on/off/n/n"
        db      "Press any key listed in the/ntable then press key on "
        db      "the/n joystick.",0

        
chip8KempstonKeyLoop:       
        call     GetKeyOrJoystick
        cp       $ff
        jr       z,chip8kemstonKemstonPressed
        cp      0
        jr      z,chip8KempstonKeyLoop
        cp       'M'
        jr      z,chip8KempstonMenuExit
        cp      'K'
        jr      z,kempstonOnOff
        ld       (kselected),a
        jp       chip8kemstonMenuLoop
        ret

kempstonOnOff:
        ld      a,(kempstonOn)
        xor     1
        ld      (kempstonOn),a
        jp       chip8kemstonMenuLoop

setStrOn:
        ld      hl,strOn
        ret        
chip8KempstonMenuExit:
        ei      
        ret        

chip8kemstonKemstonPressed:
        push    bc
        ld      bc,0
        call    printSetAt
        pop     bc
        ld      a,b
        call    printHex2
        ld      c,b
        ld      hl,kempstonMap
        ld      b,5
chip8kemstonKemstonPressed1:
        ld      a,(hl)
        inc     hl
        cp      c
        jr      z,chip8kemstonKemstonPressed2
        inc     hl
        djnz    chip8kemstonKemstonPressed1        
        jp       chip8kemstonMenuLoop     
chip8kemstonKemstonPressed2:
        ld      a,(kselected)
        ld      (hl),a

        jp      chip8kemstonMenuLoop
        

        
kempstonLeft    equ     2
kempstonRight   equ     1
kempstonUp      equ     8
kempstonDown    equ     4
kempstonFire    equ     $10        

; a = status, outputs hl = text
getJoyName:             push    bc
                        push    af
                        ld      c,a
                        ld      hl,kempstonText
getJoyName1:            ld      a,(hl)
                        inc     hl
                        cp      0
                        jr      z,getJoyNameNone
                        cp      c
                        jr      z,getJoyNameFound
                        inc     hl
                        inc     hl
                        jr      getJoyName1
getJoyNameNone:         ld      hl,strNone
getJoyNameExit          pop     af
                        pop     bc
                        ret     
getJoyNameFound:        ld      de,(hl)
                        ld      hl,de
                        jr      getJoyNameExit

printJoyAssignment:     ld      hl,kempstonMap
                        ld      c,6 
                        
                        ld      b,5
printJoyAssignment1:    push    bc
                        ld      b,20
                        call    printSetAt                        
                        ld      a,(hl)
                        inc     hl
                        push    hl
                        call    getJoyName
                        ld      b,18
                        call    printHL
                        pop     hl
                        ld      a,(hl)
                        inc     hl
                        cp      0
                        jr      nz,printJoyAssignment2
                        ld      a,' '
printJoyAssignment2:    ld      b,30
                        call    printSetAt                        
                        call    printA
                        pop     bc
                        inc     c
                        djnz    printJoyAssignment1
                        ret
                        
                        








kprintkeys:
        ld      hl,kkeys
        ld      b,1
        ld      c,6
chip8KemstonLine:
        ld      a,WHITE*PAPER+BLACK
        ld      (charAttrib),a
        ld      a,(hl)
        cp      0
        jr      z, chip8KemstonEndLine
        ld      d,a
        ld      a,(kselected)
        cp      d
        call    z,c8kSetSelected

        ld      a,b
        ld      (charX),a
        ld      a,c
        ld      (charY),a
        ld      a,(hl)
        call    printA
        ld      a,4
        add     a,b
        ld      b,a
        inc     hl
        jr      chip8KemstonLine
chip8KemstonEndLine:
        inc     hl
        ld      a,(hl)
        cp      0
        jr      z, chip8KemstonEndPrint
        ld      b,1
        inc     c
        inc     c
        jr      chip8KemstonLine
chip8KemstonEndPrint:
        ret


c8kSetSelected:
        ld      a,LIGHTBLUE*PAPER+BLACK
        ld      (charAttrib),a
        ret

; returns: Key vom keyboard map if kempston is on and the correct key pressed
getKempstonKey:
        ld      a,(kempstonOn)
        cp      0
        ret     z
        ld      bc,31
        in      a,(c)
;        ld      a,2
        and     31
        ret     z
; continue with getKeyFromKempston, instead of calling it is next 
; input A = kempston status
; output A = Key or 0
getKeyFromKempston:
        push    hl
        push    bc
        ld      c,a
        ld      b,5
        ld      hl,kempstonMap
getKeyFromKempston1:
        ld      a,(hl)
        inc     hl
        cp      c
        jr      z,getKeyFromKempstonFound
        inc     hl
        djnz    getKeyFromKempston1
        ld      a,0
getKeyFromKempstonExit:
        pop     bc
        pop     hl
        ret

getKeyFromKempstonFound:
        ld      a,(hl)
        jr      getKeyFromKempstonExit                


kempstonMap:    db      kempstonLeft,'A'
                db      kempstonRight,'D'
                db      kempstonUp,'W'
                db      kempstonDown,'S'
                db      kempstonFire,'Z'
kempstonOn:     db      0

strOn:  db "on ",0
strOff: db "off",0
kempstonText        
                db      kempstonLeft
                dw      strLeft
                db      kempstonRight
                dw      strRight
                db      kempstonUp
                dw      strUp 
                db      kempstonDown
                dw      strDown
                db      kempstonFire
                dw      strFire
                db      0
strLeft:        db      "left",0
strRight        db      "right",0
strUp:          db      "up",0
strDown:        db      "down",0
strFire:        db      "fire"
strNone:        db      0

kkeys   db      "1234",0
        db      "QWER",0
        db      "ASDF",0
        db      "ZXCV",0
        db      0
kselected: db   0

