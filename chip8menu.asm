
chip8Menu:
        di
        call    clearScreen
        ld      bc,$0800
        call    printSetAt
        call    printtext
        db      "ZX CHIP 8",0
        ld      bc,$0201
        call    printSetAt
        call    printtext
        db      "Thomas Quester, Jun 2023",0


        call    getTextUpdate
        push    hl
        ld      a,(cpu_new_shift)
        call    yesno
        push    hl
        ld      a,(opt_new_addi)
        call    yesno
        push    hl
        ld      a,(chip8_screen_mode)
        and     SCREEN_MODE_NO_ZOOM
        xor     4
        call    yesno
        push    hl
chip8MenuZoom:
           
        ld      hl,(opt_wait)
        push    hl
        call    printf
        db      "/n/n"
        db      "L/tLoad game/n/n"
        db      "G/tSelect game/n/n"
        db      "S/tStart game/n/n"
        db      "R/tReset game/n/n"
        db      "D/tStart Debug/n/n"
        db      "K/tKempston Joystick/n/n"
        db      "W/tCPU Slowdown %ld/n"
        db      "O/tZoom mode/t/t%s/n"
        db      "1/tNew ADD I,vx/t%s/n"
        db      "2/tNew Shift/t/t%s/n"
        db      "3/t%s/n/n"
        db      "Q/tReturn to game/n/n",0

chip8MenuLoop:
        call    GetKey
        cp      'G'
        jp      z,selectGame
        cp      'S'
        jr      z,menuStartGame
        cp      'R'
        jr      z,menuResetGame
        cp      'L'
        jr      z,menuLoadGame
        cp      'D'
        jp      z,menuDebugGame
        cp      'W'
        jr      z,menuChangeWait
        cp      'Q'
        jr      z,menuQuitToGame
        cp      'O'
        jr      z,menuSetZoom
        cp      'K'
        jp      z,menuKempston

        cp      '1'
        jr      z,menuModifyAddI
        cp      '2'
        jr      z,menuModifyShift
        cp      '3'
        jp      z,menuChangeUpdate

        jr      chip8MenuLoop

menuModifyAddI:
        ld      a,(opt_new_addi)        
        xor     1
        ld      (opt_new_addi),a
        jp      chip8Menu

menuModifyShift:
        ld      a,(cpu_new_shift)        
        xor     1
        ld      (cpu_new_shift),a
        jp      chip8Menu

menuSetZoom:
        ld      a,(chip8_screen_mode)
        xor     SCREEN_MODE_NO_ZOOM
        call    setSuperChip
        jp      chip8Menu

menuStartGame:
        ld      iy,chip8Memory+0x200
menuQuitToGame:
        call    clearScreen
        call    updateGameScreen    
        call    printMenuHint    
        ei
        ret

menuResetGame:                

        call    resetcpu
        call    clearScreenChip8
        call    printMenuHint
        ld      a,DEBUG_RUN
        ld      (debug_go),a
        jp      chip8Menu

menuLoadGame:
        ld      a,1
        ld      (ix+reg_quit),a
        jr      menuQuitToGame        

menuChangeWait:
        ld      hl,(opt_wait)        
        ld      de,100
        add     hl,de
        ld      (opt_wait),hl
        ld      de,2000
        sub     hl,de
        jp      c,chip8Menu
        ld      hl,0
        ld      (opt_wait),hl
        jp      chip8Menu

menuDebugGame:
        ld      a,DEBUG_STEP
        ld      (debug_go),a
        jr      menuQuitToGame

selectGame:
        call    chip8GameMenu
        jp      chip8Menu        

menuKempston:
        call           chip8KemstonMenu
        jp              chip8Menu

printMenuHint:
    ld      a,(debug_go)
    cp      DEBUG_STEP
    jp      nz, printMenuHintBig
    call    printf
    db      "%@0618M xMenu 0 Debug 5 Reset I Info",0
    ret 

getTextUpdate:
        ld      hl,txtUpdateDirect
        ld      a,(updateOnInterrupt)
        cp      0
        ret     z
        ld      a,(screenSkipFrames)
        add     a,48
        ld      (txtUpdateInterruptNr),a
        ld      hl,txtUpdateInterrupt
        ret

menuChangeUpdate:
        ld      a,(updateOnInterrupt)
        cp      0
        jr      nz,menuChangeUpdate1
        ld      a,1
        ld      (updateOnInterrupt),a
        jp      chip8Menu
menuChangeUpdate1:
        ld      a,(screenSkipFrames)
        inc     a
        ld      (screenSkipFrames),a
        cp      5
        jp      nz,chip8Menu
        ld      a,1
        ld      (screenSkipFrames),a
        ld      a,0
        ld      (updateOnInterrupt),a
        jp      chip8Menu

txtUpdateDirect:
        db      "Direkt screen drawing",0
txtUpdateInterrupt:
        db      "Update each "
txtUpdateInterruptNr
        db      "1"
        db      " vsync",0                

yesno:  cp      0
        jr      z,yesno_no
        ld      hl,strYes
        ret
yesno_no:
        ld      hl,strNo
        ret

strYes:    db      "Yes",0
strNo:     db       "No",0
printMenuHintBig:    
                ld      a,(charAttrib);
                push    af
                ld      a,LIGHTBLUE*PAPER+BLACK
                ld      (charAttrib),a
                call    printf
                db      "%@06141234/t123C/t0=Debug   "
                db      "%@0615qwer/t456D/tM=Menu    "
                db      "%@0616asdf/t789E/t5=Reset   "
                db      "%@0617zxcv/tA0BF/tI=Info Z=Y",0
                pop     af
                ld      (charAttrib),a
                ret        



        