
disassAdr:                  dw  0x200+chip8Memory
disassCur:                  dw  0x200+chip8Memory

DEBUG_STEP   equ 0          ; wait for key, execute one statement
DEBUG_GONEXT equ 1          ; wait for key, execute until next line (e.g. skip calls)
DEBUG_GO     equ 2          ; do not wait for key. stop if 0 or 9 is pressed
DEBUG_RUN    equ 3          ; do not wait for key, clear debug aerea, run.
cpu_debug   db  1           ; 1 = debugger enabled
debug_go:    db  DEBUG_STEP      ; 0 = step, 1 = go until next, 2 = go

debug_gobp  dw  0           ; breakpoint for go until next

disassNumBreakpoints:
                            db  0
disassMaxBreakpoints        equ 20
disassBreakpoints:
                            defs  20*2,0

countBreakpoints:   push    ix
                    ld      ix,disassBreakpoints
                    ld      b,disassMaxBreakpoints
                    ld      c,0
countBreakpointsLoop:
                    ld      hl,(ix)
                    inc     ix
                    inc     ix  
                    ld      a,h
                    cp      0
                    jr      nz,countBreakpointsLoopCount
                    ld      a,l
                    cp      0
                    jr      z,countBreakpointsLoop2
countBreakpointsLoopCount:                    
                    inc     c
countBreakpointsLoop2:
                    djnz    countBreakpointsLoop
                    ld      a,c
                    ld      (cpu_registers+reg_hasBreakpoint),a  
                    pop     ix
                    ret                  

IsBreakpointHl:     push    hl
                    push     de
                    push     bc
                    push    ix
                    ld      hl,iy
                    ld      de,hl
                    ld      ix,disassBreakpoints
                    ld      b,disassMaxBreakpoints
isHlBreakpoint1:    ld      hl,(ix)
                    inc     ix 
                    inc     ix
                    sub     hl,de
                    jr      z,isHlBreakpoint2
                    djnz    isHlBreakpoint1
                    ld      a,0
isHlBreakpointEnd   pop     ix
                    pop     bc
                    pop     de
                    pop     hl
                    ret                                                                  
isHlBreakpoint2:    ld      a,10
                    jr      isHlBreakpointEnd

ClearBreakpointHl:  push    hl
                    push     de
                    push     bc
                    push    ix
                    ld      de,hl
                    ld      ix,disassBreakpoints
                    ld      b,disassMaxBreakpoints
clearBreakpoint1:   ld      hl,(ix)
                    sub     hl,de
                    jr      z, clearBreakpoint2
                    inc     ix
                    inc     ix
                    djnz    clearBreakpoint1
clearBreakpointEnd: call    countBreakpoints                 
                    pop     ix
                    pop     bc
                    pop     de
                    pop     hl
                    ret
clearBreakpoint2:   ld      hl,0
                    ld      (ix),hl
                    jr      clearBreakpointEnd
SetBreakpointHl:    push    hl
                    push     de
                    push     bc
                    push    ix
                    ld      ix,disassBreakpoints
                    ld      b,disassMaxBreakpoints
setBreakpoint1:     ld      a,(ix)
                    cp      0
                    jr      nz,setBreakpoint2
                    ld      a,(ix+1)
                    cp      0
                    jr      nz,setBreakpoint2
                    ld      (ix),hl
setBreakpointEnd:   call    countBreakpoints
                    pop     ix
                    pop     bc
                    pop     de
                    pop     hl
                    ret
setBreakpoint2:     inc     ix
                    inc     ix
                    djnz    setBreakpoint1
                    jr      setBreakpointEnd                    

debuggerMain:
            call    debuggerScreen
debuggerMainKey:
            call    GetKey
            ld      hl,disassAdr
            ld      de,(disassCur)
            cp      'Q'
            jr      z,debuggerQuit
            cp      '7'
            jr      z,debuggerUp
            cp      '6'
            jp      z,debuggerDown
            cp      '5'
            jr      z,debuggerPgUp
            cp      '8'
            jr      z,debuggerPgDown
            cp      'B'
            jr      z,debugSetClearBP

            jr      debuggerMainKey
debuggerQuit:
            call    clearScreen
            ld      hl,chip8Screen
            ld      bc,0
            call    updateScreenChip8
            ret
debugSetClearBP:
            ld      hl,(disassCur)
            call    IsBreakpointHl
            cp      0
            jr      z,debugSetClearBPSet
            call    ClearBreakpointHl
            jr      debuggerMain
debugSetClearBPSet:
            call    SetBreakpointHl
            jr      debuggerMain

debuggerPgDown:
            push    hl
            ld      bc,(hl)
            ld      hl,20
            add     hl,bc
            ld      bc,hl
            pop     hl
            ld      (hl),bc
            ld      (disassCur),bc
            jr      debuggerMain

debuggerPgUp:
            push    hl
            ld      bc,(hl)
            ld      hl,bc
            ld      bc,20
            sbc     hl,bc
            ld      bc,hl
            pop     hl
            ld      (hl),bc
            ld      (disassCur),bc
            jr      debuggerMain

debuggerUp: 
            ld      de,(disassCur)
            dec     de
            dec     de
            ld      (disassCur),de
            ld      hl,(disassAdr)
            push    hl
            sbc     hl,de
            jr      c,debuggerUp1
            pop     hl
            ld      bc,20
            sbc     hl,bc
            ld      (disassAdr),hl
            jp      debuggerMain
debuggerUp1:
            pop     hl
            jp      debuggerMain

debuggerDown: 
            ld      de,(disassCur)
            inc     de
            inc     de
            ld      (disassCur),de
            ld      hl,(disassAdr)
            push    hl
            ld      bc,40
            add     hl,bc
            sbc     hl,de
            jr      nc,debuggerDown1
            pop     hl
            ld      bc,20
            add     hl,bc
            ld      (disassAdr),hl
            jp      debuggerMain
debuggerDown1:
            pop     hl
            jp      debuggerMain            

debuggerScreen:
            PUSHA
            push    iy
            call    clearScreen
            ld      a,0
            ld      (charX),a
            ld      (charY),a
            ld      hl,(disassAdr)
            ld      de,chip8Memory
            sbc     hl,de
            ld      hl,(disassAdr)
            ld      iy,hl
            ld      de,(disassCur)
            ld      b,22
            call    printtext
            db      "q quit 5/9 pg 6/7 line b=bp",0
            call newline

        
debuggerScreenLoop:
            push    bc
            ld      a,' '
            ld      hl,iy
            ld      de,(disassCur)
            sub     hl,de
            jr      nz,debuggerScreenLoop1
            ld      a,'>'
debuggerScreenLoop1:
            call    printA
            ld      hl,iy
            call    IsBreakpointHl
            cp      0
            jr      z,debuggerScreenLoopBP1
            ld      a,'*'
            jr      debuggerScreenLoopBP2
debuggerScreenLoopBP1:
            ld      a,' '
debuggerScreenLoopBP2:            
            call    printA
            call    chip8disass            
            call    newline
            inc     iy
            inc     iy
            pop     bc
            djnz    debuggerScreenLoop
debuggerScreenEnd:
            pop     iy
            POPA
            ret

printcpu:
    PUSHA   
    ld      a,$16*8
    call    clearTextLine
    ld      a,$17*8
    call    clearTextLine
    ld      a,(cpu_debug)
    cp      0
    jr      z,printcpunodb
    ld      a,18*8
    call    clearTextLine
    ld      a,0
    ld      (charX),a
    ld      a,17
    ld      (charY),a
    call    printtext
    db      "0=step 9=over 8=go 7=run p=list",0
    call    newline
printcpunodb:
    ld      a,0
    ld      (charX),a
    ld      a,18
    ld      (charY),a
    call    chip8disass
    call    newline


    ld      hl,cpu_registers+reg_i
    ld      b,0
    ld      c,6
printcpuloop1:
    ld      a,b
    call    printNibble
    ld      a,':'
    call    printA 
    ld      hl,cpu_registers+reg_v0
    ld      e,b
    ld      d,0
    add     hl,de
    ld      a,(hl)
    call    printHex2
    ld      a,' '
    call    printA 
    inc     b
    dec     c
    jr      nz, printcpuloop2
    ld      c,6
    call    newline
printcpuloop2:
    ld      a,b
    cp      $10
    jr      nz,printcpuloop1
    call    printtext
    db      "D:",0
    ld      a,(ix+reg_delay)
    call    printHex2
    call    printtext
    db      " S:",0
    ld      a,(ix+reg_sound)
    call    printHex2

    call    newline
    call    printtext
    db      "I:",0
    ld      bc,(ix+reg_i)
    call    printHex4
    ld      a,'>'
    call    printA

    ld      b,4
    ld      hl,(ix+reg_i)
    ld      de,chip8Memory
    add     hl,de
printcpuLoopI:
    ld      a,(hl)
    inc     hl
    call    printHex2
    ld      a,' '
    call    printA
    djnz    printcpuLoopI
    POPA
    ret

dodebug:
    ld      hl,(debug_gobp)
    ld      de,0
    sbc     hl,de
    jr      z,dodebug_1
    ld      de,iy               ; we have a run until
    sbc     hl,de               ; if pc equals breakpoint 
    jr      nz, dodebug_1
    ld      a,DEBUG_STEP
    ld      (debug_go),a
    ld      hl,0
    ld      (debug_gobp),hl
dodebug_1:
    ld      a,(debug_go)
    cp      DEBUG_RUN
    jp      z,dodebug_end2
    cp      DEBUG_GO
    jp      z,dodebug_run
  
dodebug_end:
    call    GetKey
   
    jp      z,dodebug_end2
    cp      a,'0'
    jr      z,dodebug_run0
    cp      a,'9'
    jr      z,dodebug_run9
    cp      a,'8'
    jr      z,dodebug_run8
    cp      a,'7'
    jr      z,dodebug_run7
    cp      a,'P'
    jr      z,dodebug_print
    cp      'U'
    jr      z,dodebug_update
    cp      'Z'
    jr      z,dodebug_restart
    jr      dodebug_end2

dodebug_restart:
    ld      iy,chip8Memory+0x200
    jr      dodebug_end2
dodebug_print:
    push    iy
    push    ix
    ld      (disassAdr),iy
    ld      (disassCur),iy
    call    debuggerMain
    pop     ix
    pop     iy
    ret    
dodebug_run0:    
    sub     a,DEBUG_STEP
    ld      (debug_go),a
    jr      dodebug_end2
dodebug_update:
    call    updateGameScreen:
    jr      dodebug_end2
dodebug_run7:
    ld      a,17*8
    ld      b,6
dodebug_run7_loop:
    call    clearTextLine
    add     a,8
    djnz    dodebug_run7_loop
    ld      a,DEBUG_RUN
    ld      (debug_go),a
    call    printMenuHint
    jr      dodebug_end2    

dodebug_run8:
    ld     a,DEBUG_GO
    ld      (debug_go),a
    jr      dodebug_end2
dodebug_run9:    
    ld     a,DEBUG_RUN
    ld      (debug_go),a
    ld      ix,cpu_registers
    ld     a,1
    ld      (ix+reg_cpuStepOverBreakpoint),a
    ld      (ix+reg_hasBreakpoint),a
    inc     a
    ld      (ix+reg_cpuStepOverBreakpointNext),a
    ld      hl,iy
    ld      de,2
    add     hl,de
    ld      (ix+reg_cpuStepOverBreakpointAdr),hl
dodebug_end2:

    ret

dodebug_run:
    call    ReadKeyboard
    jr      z,dodebug_end2
    cp      a,'0'
    jr      z,dodebug_go0
    cp      a,'9'
    jr      z,dodebug_go9
    jr      dodebug_end2
dodebug_go0:
    ld      a,DEBUG_STEP
    ld      (debug_go),a
    jr      dodebug_end2
dodebug_go9:
    ld      a,DEBUG_GONEXT
    ld      (debug_go),a
    jr      dodebug_end2

dodebug_stepinto:
    ld      a,DEBUG_GONEXT
    ld      (debug_go),a
    ld      hl,iy
    ld      (debug_gobp),hl
    jp      dodebug_end
