
chip8KemstonMenu:
        call    clearScreen
        call    printf
        db      "%@0800ZXChip8%@0702Kemston Joystick/n/n",0

chip8kemstonMenuLoop:        
        call     printf
        db       "%@01f5Press any key\n then move the joystick/nEnter to exit",0
        call    kprintkeys
        call     GetKey
        cp       35
        ret      z
        ld       (kselected),a
        jr       chip8kemstonMenuLoop
        ret


kprintkeys:
        ld      hl,kkeys
        ld      b,5
        ld      c,6
chip8KemstonLine:
        ld      a,WHITE*INK+BLACK
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
        ld      b,5
        inc     c
        inc     c
        jr      chip8KemstonLine
chip8KemstonEndPrint:
        ret


c8kSetSelected:
        ld      a,LIGHTBLUE*INK+BLACK
        ld      (charAttrib),a
        ret


kkeys   db      "1234",0
        db      "QWER",0
        db      "ASDF",0
        db      "ZXCV",0
        db      0
kselected: db   0

