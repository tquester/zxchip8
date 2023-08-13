debugcpu        equ 1
breakonunknown  equ 1
STARTMODE       equ DEBUG_RUN
fakeinterrupt   equ 0         ; all x commands
reg_v0          equ 0
reg_v1          equ 1
reg_v2          equ 2
reg_v3          equ 3
reg_v4          equ 4
reg_v5          equ 5
reg_v6          equ 6
reg_v7          equ 7
reg_v8          equ 8
reg_v9          equ 9
reg_va          equ 10
reg_vb          equ 11
reg_vc          equ 12
reg_vd          equ 13
reg_ve          equ 13
reg_vf          equ 15
reg_i           equ 16
reg_sound       equ 18
reg_delay       equ 19
reg_pc          equ 22
reg_sp          equ 24
reg_fakeir      equ 26
reg_hasBreakpoint equ 28
reg_cpuStepOverBreakpoint equ 29
reg_cpuStepOverBreakpointNext equ 30

reg_cpuStepOverBreakpointAdr equ 32

reg_stack       equ 32
                
reg_stacktop    equ reg_stack + 34
reg_quit        equ reg_stacktop+1
reg_size        equ reg_stacktop+2

;   set pc to hl and start 

/*
            00E0 - CLS
            00EE - RET
            0nnn - SYS addr
            1nnn - JP addr
            2nnn - CALL addr
            3xkk - SE Vx, byte
            4xkk - SNE Vx, byte
            5xy0 - SE Vx, Vy
            6xkk - LD Vx, byte
            7xkk - ADD Vx, byte
            8xy0 - LD Vx, Vy
            8xy1 - OR Vx, Vy
            8xy2 - AND Vx, Vy
            8xy3 - XOR Vx, Vy
            8xy4 - ADD Vx, Vy
            8xy5 - SUB Vx, Vy
            8xy6 - SHR Vx {, Vy}
            8xy7 - SUBN Vx, Vy
            8xyE - SHL Vx {, Vy}
            9xy0 - SNE Vx, Vy
            Annn - LD I, addr
            Bnnn - JP V0, addr
            Cxkk - RND Vx, byte
            Dxyn - DRW Vx, Vy, nibble
            Ex9E - SKP Vx
            ExA1 - SKNP Vx
            Fx07 - LD Vx, DT
            Fx0A - LD Vx, K
            Fx15 - LD DT, Vx
            Fx18 - LD ST, Vx
            Fx1E - ADD I, Vx
            Fx29 - LD F, Vx
            Fx33 - LD B, Vx
            Fx55 - LD [I], Vx
            Fx65 - LD Vx, [I]
      3.2 - Super Chip-48 Instructions
            00Cn - SCD nibble
            00FB - SCR
            00FC - SCL
            00FD - EXIT
            00FE - LOW
            00FF - HIGH
            Dxy0 - DRW Vx, Vy, 0
            Fx30 - LD HF, Vx
            Fx75 - LD R, Vx
            Fx85 - LD Vx, R
Octo-Extension
save vx - vy (0x5XY2) save an inclusive range of registers to memory starting at i.
load vx - vy (0x5XY3) load an inclusive range of registers from memory starting at i.
saveflags vx (0xFN75) save v0-vn to flag registers. (generalizing SCHIP).
loadflags vx (0xFN85) restore v0-vn from flag registers. (generalizing SCHIP).
i := long NNNN (0xF000, 0xNNNN) load i with a 16-bit address.
plane n (0xFN01) select zero or more drawing planes by bitmask (0 <= n <= 3).
audio (0xF002) store 16 bytes starting at i in the audio pattern buffer.
pitch := vx (0xFX3A) set the audio pattern playback rate to 4000*2^((vx-64)/48)Hz.
scroll-up n (0x00DN) scroll the contents of the display up by 0-15 pixels.
*/

cpuDoDebug:
    call    printcpu
    ld      a,(cpu_debug)
    cp      0
    ret     z
    jp      dodebug

cpuCheckKey
    call    ReadKeyboard
    cp      0
    ret     z
    cp      a,'0'
    jr      z,cpuKeySingleStep
    cp      a,'5'
    jr      z,cpukeyReset
    cp      a,'M'
    jr      z,cpukeyMenu:
    cp      a,'I'
    jr      z,cpuKeyInfo
    ret     

cpuKeyInfo:
    ld      hl,(gameInfo)
    ld      a,h
    or      l
    ret     z
    ld      a,(hl)
    cp      0
    ret     z
    call    printPagedHL
    call    clearScreen
    call    printMenuHint
    call    updateGameScreen
    ret

cpuKeySingleStep:
    ld      a,DEBUG_STEP
    ld      (debug_go),a
    ret

cpukeyReset:
    call    resetcpu
    ret

cpukeyMenu:
    push    ix
    call    chip8Menu
;    call    checkMemory
;    db      "cpukey2",0
    pop     ix
    ret



cpuwait:
    dec     hl
    ld      a,l
    cp      0
    jr      nz, cpuwait
    ld      a,h
    cp      0
    jr      nz, cpuwait
    ret



cpuIsBreakpoint:
    ld      a,DEBUG_STEP
    ld      (debug_go),a
    ret

cpuTestBreakpoint:    
    ld      a,(ix+reg_cpuStepOverBreakpointNext)
    cp      0
    jr      z,cpuTestBreakpoint0
    dec     a
    ld      (ix+reg_cpuStepOverBreakpointNext),a
cpuTestBreakpoint0:    
    ld      a,(ix+reg_cpuStepOverBreakpoint)
    cp      0
    jr      z,cpuTestBreakpoint2
    ld      hl,iy
    ld      de,(ix+reg_cpuStepOverBreakpointAdr)
    sub     hl,de
    jr      z,cpuTestBreakpoint3

cpuTestBreakpoint2;
    call    IsBreakpointHl
    cp      a,0
    ret z
cpuTestBreakpoint3:    
    ld      a,DEBUG_STEP
    ld      (debug_go),a
    ret

cpuJumpTable:
    dw      chip8callasm        ; 0
    dw      chip8jump           ; 1
    dw      chip8call           ; 2
    dw      chip8skipvxeqnn     ; 3
    dw      chip8skipvxnenn     ; 4
    dw      chip8skipvxeqvy     ; 5
    dw      chip8setvxnn        ; 6
    dw      chip8addnnvx        ; 7
    dw      chip8setetc         ; 8
    dw      chip89              ; 9
    dw      chip8setindex       ; A
    dw      chip8jumpofs        ; B
    dw      chip8xrand          ; C
    dw      chip8display        ; D
    dw      chip8skipifkey      ; E
    dw      chip8timers         ; F


vinterruptcheckKey:
        ld      a,20
        ld      (cpu_registers+reg_fakeir),a
        jp    cpuCheckKey

; called from the interrupt service or the fake ir    
vinterrupt:
        if fakeinterrupt > 0
        call    cpuCheckKey
        endif

        ld      a,(cpu_registers+reg_delay)
        cp      0
        jr      z, vinterrupt_1
        dec     a
        ld     (cpu_registers+reg_delay),a
vinterrupt_1:
        ld      a,(cpu_registers+reg_sound)
        cp      0
        jr      z,vinterrupt_2
        dec     a
        ld      (ix+reg_sound),a
vinterrupt_2:       
        if fakeinterrupt > 0
        ld      a,fakeinterrupt
        ld      (cpu_registers+reg_fakeir),a
        endif
        ret    

skip:   ld      a,(ix+reg_cpuStepOverBreakpointNext)
        cp      0
        jr      z,skip1
        ld      a,DEBUG_STEP
        ld      (debug_go),a


skip1:
        ld      hl,(iy)
        inc     iy
        inc     iy
        ld      de,$00f0
        sbc     hl,de
        jr      z, skiplong
        ret
skiplong:
        inc     iy
        inc     iy
        ret

updateScreenOnI:
    ld      a,0
    ld      (screenNeedsRedraw),a
    jp      updateGameScreen


chip8cpu:   
    ld      ix,cpu_registers
    push    hl
    pop     iy
    ld      de,cpuJumpTable
    ld      hl,reg_stacktop
    ld      de,cpu_registers
    add     hl, de
    ld      (ix+reg_sp),hl
    if fakeinterrupt > 0 
    ld      a, fakeinterrupt
    ld      (ix+reg_fakeir),a
    endif


cpuloop:
  ;  ld      a,(chip8Memory+$312)
  ;  cp      $10
  ;  ld      a,(chip8Memory+$312)
   ; jr      z,ok
   ; ld      a,0
; ok:
    ld      a,(screenNeedsRedraw)
    cp      0
;   call    nz, updateScreenOnI
;    ld      a,(ix+reg_sound)
;    cp      0
;    call    nz,chip8beep

    ld      a,(ix+reg_quit)
    cp      1
    ret     z
    ld      hl,(opt_wait)
    ld      a,l
    or      h
    call    nz, cpuwait
    if debugcpu == 1
    ld      a,(ix+reg_hasBreakpoint)
    cp      0
    call    nz, cpuTestBreakpoint
    ld      a,(debug_go)
    cp      a,DEBUG_RUN
    call    nz, cpuDoDebug
    endif
    if fakeinterrupt > 0 
    dec     (ix+reg_fakeir)    
    call    z, vinterrupt
    else
    dec     (ix+reg_fakeir)    
    call    z, vinterruptcheckKey

    endif
    ld      b,(iy)
    inc     iy
    ld      c,(iy)
    inc     iy
    ld      a,b
    and     $f0
    srl     a       ; /2     
    srl     a       ; /4
    srl     a       ; /8
    ; a contains opcode * 2
    ld      de,cpuJumpTable
    ld      l,a
    ld      h,0
    add     hl,de
    ld      de,(hl)
    ld      hl,de
    ld      de,cpuloop
    push    de
    ld      a,b
    and     15
    ld     b,a
    jp      (hl)                ; call function based on jump table
cpufinloop:
    jp      cpuloop



; ------------------ 0xxx ------------------------
chip8callasm:        ; 0
      
            ld      a,b
            cp      0
            ret     nz      ; We do not handle 01xx 
            ld      a,c
            cp      $e0
            jr      z,chip8cls
            cp      $ee 
            jp      z,chip8rts
            cp      $ff
            jr      z,chip8SetSuperScreen
            cp      $fe
            jr      z,chip8SetChip8Screen     
            cp      $FB
            jr      z,chip8Scroll4Right       
            cp      $FC
            jr      z,chip8Scroll4Left       
            cp      0
            jr      z,chip8stop
//            cp      $fd
//            jr      z,chip8Scroll4Left
            ld      b,a
            and     $F0
            cp      $C0
            jr      z,chip8ScrollUpDownN 
            ld      a,b
            cp      $D0
            jr      z,chip8ScrollUpUpN 

            if      breakonunknown=1
            endif
            ret




chip8stop   call    chip8Menu
            call    resetcpu
            jp      cpuloop
chip8Scroll4Right:
            call    scroll4Right
            jp      cpuloop

chip8Scroll4Left:
            call    scroll4Left
            jp      cpuloop
chip8ScrollUpDownN:
            ld      a,b
            and     15
            call    scrollDownA
            ret  
chip8ScrollUpUpN:
            ld      a,b
            call    scrollUpA
            ret                           

chip8SetChip8Screen:
            ld      a,(chip8_screen_mode)
            and     3
            or      SCREEN_MODE_CHIP8
            call    setSuperChip
            jr      chip8UpdateScreen
chip8SetSuperScreen:
            ld      a,(chip8_screen_mode)
            and     3
            or      SCREEN_MODE_SCHIP8
            call    setSuperChip
            ld      a,1
            ld      (opt_new_addi),a
            ld      (cpu_new_shift),a

chip8UpdateScreen:
            call    updateGameScreen
            ret                     
chip8cls:   
            push    ix
            push    iy
            call    clearScreen
            call    printMenuHint
            ld      hl,chip8Screen
            call    clearScreenChip8
            ld      hl,chip8Screen
            ld      bc,0
            call    updateScreenChip8
            ld      a, DEBUG_STEP
            ;ld      (debug_go),a
            pop     iy
            pop     ix


            ret   
chip8rts:   ld      hl,(ix+reg_sp)
            ld      de,(hl)
            ld      iy,de
            inc     hl
            inc     hl
            ld      (ix+reg_sp),hl
            ld      a,(ix+reg_cpuStepOverBreakpointNext)
            cp      0
            ret     z
            ld      a,DEBUG_STEP
            ld      (debug_go),a
            ret


; ----------------- 1xxx jump ------------------------            
chip8jump:          ; 1
            ld   hl,chip8Memory
            add  hl,bc
            ld   iy,hl
            ld      a,(ix+reg_cpuStepOverBreakpointNext)
            cp      0
            ret     z
            ld      a,DEBUG_STEP
            ld      (debug_go),a
            ret

; ----------------- 2 xxx call -----------------------                
chip8call:          ; 2
                ld  hl,(ix+reg_sp)
                dec hl
                dec hl
                ld  de,iy
                ld  (hl),de
                ld  (ix+reg_sp),hl
                ld  hl,chip8Memory
                add hl,bc
                ld  iy,hl
                ret

; ----------------- 3xnn skip -----------------                
chip8skipvxeqnn:    ; 3
                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                ld  e,b
                ld  d,0
                add hl,de
                ld  a,(hl)
                cp  c
                ret nz
                call   skip
                ret

; ----------------- 4xnn skip -----------------                                
chip8skipvxnenn:    ; 4
                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                ld  e,b
                ld  d,0
                add hl,de
                ld  a,(hl)      ; (hl) var vb
                cp  c
                ret z
                call   skip
                ret

; ----------------- 5xnn skip -----------------  
; 5acd
;  b = 0a    lower nibble of command
;  c = cd    last both nibbles of command
;                           
; 5xy0 - SE Vx, Vy
; Skip next instruction if Vx = Vy.
; octo Extension
; save vx - vy (0x5XY2) save an inclusive range of registers to memory starting at i.
; load vx - vy (0x5XY3) load an inclusive range of registers from memory starting at i.
chip8skipvxeqvy:    ; 5
                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                push    hl          ; hl = reg_v0
                ld  a,c
                and 15
                cp  2
                jr  z, octoSavexy
                cp  3
                jr  z, octoLoadxy
                ld  e,b
                ld  d,0
                add hl,de
                ld  b,(hl)
                pop hl
                ld  d,0
                srl c
                srl c
                srl c
                srl c
                ld  e,c
                add hl,de
                ld  a,(hl)

                
                cp  b
                ret nz
                call   skip
                ret

shifte:         srl c
                srl c
                srl c
                srl c
                ret

octoSavexy:     call    shifte
                ld      de,(ix+reg_i)   
                ld      a,b
                cp      c
                jr      c, octoSavexyR
                ld      e,c
                ld      d,0
                add     hl,de           ; points to first register
octoSaveLoop1:  ld      a,c
                cp      b
                ret     z
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                inc     c
                jr      octoSaveLoop1                
octoSavexyR:    ld      e,c
                ld      d,0
                add     hl,de           ; points to first register
octoSaveLoop2:  ld      a,c
                cp      b
                ret     z
                ld      a,(hl)
                ld      (de),a
                inc     hl
                inc     de
                inc     b
                jr      octoSaveLoop2

octoLoadxy:     ret                 


; ----------------- 6xnn set -----------------                

chip8setvxnn:       ; 6
                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                ld  e,b             ; add register number (6XNN)
                ld  d,0
                add hl,de
                ld  (hl),c          ; c contains the value (NN)
                ret

; ----------------- 7xnn add -----------------                  
chip8addnnvx:       ; 7
                ld  hl,cpu_registers+reg_v0
                ld  e,b
                ld  d,0
                add hl,de
                ld  a,(hl)
                add a,c
                ld  (hl),a
                ret
; ----------------- 8xnf set and math -----------------                  
chip8setetc:    ld      a,c
                and     15
                ld      hl,cpu_registers+reg_v0
                push    hl 
                ld      e,c
                srl     e
                srl     e
                srl     e
                srl     e
                ld      d,0
                add     hl,de
                ld      c,(hl)

                pop     hl
                ld      e,b
                ld      d,0
                add     hl,de
                ld      b,(hl)              // (hl) = vx
                push    hl
                ld      l,a
                ld      h,0
                add     hl,hl
                ld      de,chip8jmp8
                add     hl,de
                ld      de,(hl)
                pop     hl
                push    de              ; this is a jp (de)
                ret
                /*
                cp      0
                jp      z,chip8set8
                cp      1
                jp      z,chip8or8
                cp      2
                jp      z,chip8and8
                cp      3
                jp      z,chip8xor8
                cp      4
                jp      z,chip8add8
                cp      5
                jp      z,chip8subxy
                cp      6
                jr      z,chip8shright
                cp      7
                jp      z,chip8subyx
                cp      8
                jr      z,chip8shleft
                cp      $E
                jr      z,chip8shifte
*/

chip8illegal:    if      breakonunknown=1
                ld      hl,iy
                ld      de,2
                sub     hl,de
                ld      de,chip8Memory
                sub     hl,de
                push    hl
                push    af
                call    printf
                db      "/nUnknown command 8x%x at %lx/n",0
                call    GetKey
                ld      a,DEBUG_STEP
                ld      (debug_go),a

                endif
                ret   

chip8jmp8:      dw      chip8set8       ;       0
                dw      chip8or8        ;       1  
                dw      chip8and8       ;       2
                dw      chip8xor8       ;       3
                dw      chip8add8       ;       4
                dw      chip8subxy      ;       5
                dw      chip8shright    ;       6
                dw      chip8subyx      ;       7
                dw      chip8illegal    ;       8
                dw      chip8illegal    ;       9
                dw      chip8illegal    ;       A
                dw      chip8illegal    ;       B
                dw      chip8illegal    ;       C
                dw      chip8illegal    ;       D
                dw      chip8shifte     ;       E
                dw      chip8illegal    ;       D

;       c = reg_y
;       b = reg_x
;       (hl) = reg_x

; ----------------- 8xy0 set x=y -----------------                 
chip8set8:      ld      (hl),c
                ret

; ----------------- 8xy1 or x= x or y -----------------                  
chip8or8:       ld      a,c
                or      b
                ld      (hl),a
                ;cp     0
                ;ld      a,0
                ;adc     0
                ;ld      (ix+reg_vf),a
                ret

; ----------------- 8xy2 or x= x and y -----------------                  

chip8and8:      ld      a,c
                and     b
                ld      (hl),a
                ;cp      0
                ;ld      a,0
                ;adc     0
                ;ld      (ix+reg_vf),a
                ret
; ----------------- 8xy3 or x= x xor y -----------------                  
chip8xor8:      ld      a,c
                xor     b
                ld      (hl),a
                xor     a
                ld      a,0
                adc     0
                ld      (ix+reg_vf),a
                ret

; ----------------- 8xy4 or x= x add y, vf = carry -----------------                  
chip8add8:      ld      a,0
                ld      a,c
                add     b
                ld      (hl),a
                adc     0
                ld      (ix+reg_vf),a
                ret


; ----------------- 8xy5 sub x = x-y -----------------                 
chip8subxy:     ld      a,b
                sbc     c
                ld      (hl),a
                ld      a,0
                adc     a,0
                xor     1
                ld      (ix+reg_vf),a
                ret


; ----------------- 8xy6 shift right -----------------  
chip8shright:   ld      a,(cpu_new_shift)
                cp      0
                jr      z,chip8shrightNew:  
                ld      c,b
chip8shrightNew:
                srl     c
                ld      a,0
                adc     a,0
                ld      (hl),c
                ld      (ix+reg_vf),a
                ret                


; ----------------- 8xy7 sub y-x x=y-x -----------------  

chip8subyx:     ld      a,c
                sbc     b
                ld      (hl),a
                ld      a,0
                adc     a,0
                xor     1
                ld      (ix+reg_vf),a
                ret

; ----------------- 8xy8 shift left -----------------  
chip8shleft:    ld      a,(cpu_new_shift)
                cp      0
                jr      z,chip8shleft1:  
                ld      c,b
                
chip8shleft1:   sla     c
                ld      a,0
                adc     a,0
                ld      (hl),c
                ld      (ix+reg_vf),a
                ret                 


// ----------------- 8xyE  b = vx c = vy
chip8shifte:    ld      a,(cpu_new_shift)
                cp      0
                jr      z,chip8shifte1
                ld      c,b
chip8shifte1
                ld      a,0 
                sla     c  
                adc     a,0
                ld      (hl),c
                ld      (ix+reg_vf),a
                ret              



               






; ----------------- 9xnn skip -----------------                                
                
chip89:             ; 9
                                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                push    hl
                ld  e,b
                ld  d,0
                add hl,de
                ld  b,(hl)
                pop hl
                ld  d,0
                srl c
                srl c
                srl c
                srl c
                ld  e,c
                add hl,de
                ld  a,(hl)

                
                cp  b
                ret z
                call   skip
                ret
chip8setindex:      ; A
      
                ld  (ix+reg_i),bc
                ret

; ------------------- B ---------------------                
chip8jumpofs:   ld  hl,bc
                ld  a,(ix+reg_v0)
                ld  c,a
                ld  b,0
                add hl,bc
                ld  de,chip8Memory
                add hl,de
                ld  iy,hl
                ret

; ------------------- CXNN rand ----------------                
chip8xrand:         ; C
                ld      hl,cpu_registers
                ld      e,a
                ld      d,0
                add     hl,de
                ld      a,r
                neg
                add     a,25
                and     c
                ld      (hl),a

                ret

; ------------------- D display --------------
chip8display:       ; D
                ld  hl,ix
                ld  de,reg_v0
                add hl,de
                ld  de,hl
                ld  h,0
                ld  l,b
                add hl,de
                ld  b,(hl)
                ld  a,c
                srl     a
                srl     a
                srl     a
                srl     a
                ld      l,a
                ld      h,0
                add     hl,de
                ld      a,c
                and     a,$f
                ld      c,(hl)
                ld      hl,(ix+reg_i)
                push    ix
                push    iy
                ld      de,chip8Memory
                add     hl,de
                call    chip8sprite
                ld      hl,chip8Screen
                ld      bc,0
          ;      call    updateScreenChip8
                pop     iy
                pop     ix
                ret

; --------------------- E skip if key --------------------                
chip8skipifkey:     ; E
                ld  e,b
                ld  d,0
                ld  hl,ix
                add hl,de
                ld  a,c
                cp  $9e
                jr  z,chip8skipifkey9e
                cp  $a1
                jr  z,chip8skipifkeya1
                ret

chip8skipifkey9e:
                ld      a,(hl)
                call    checkMultipleHexKeyA
                cp      1
                ret     nz
                call   skip
                ret
/*
                call    readHexKeyboard
                cp  	$ff
                jr      z,chip8skipifkeyskip
                ld      b,a
                ld      a,(hl)
                cp      b
                ret     nz
chip8skipifkeyskip:                
                inc     iy
                inc     iy
                ret
*/                

; skip if key not pressed
chip8skipifkeya1:
                ld      a,(hl)
                call    checkMultipleHexKeyA
                cp      1
                ret     z
                call   skip
                ret

/*
                call    readHexKeyboard
                cp  	$ff
                jr      z,chip8skipifkeyskip
                ld      b,a
                ld      a,(hl)
                cp      b
                jr      z,chip8keynoskip
                inc     iy
                inc     iy
                ret
chip8keynoskip: 
                ret  
*/


                

; --------------------- FXcc timers -------------------------                
chip8timers:        ; F
                ld      hl,ix
                ld      de,reg_v0
                add     hl,de
                ld      a,b
                and     15
                ld      e,a
                ld      d,0
                add     hl,de       ; (hl) points to reg x
                ld      a,c
                cp      $07
                jp      z,chip8f07
                cp      $0A
                jp      z,chip8f0A
                cp      $15
                jp      z,chip8f15
                cp      $18
                jp      z,chip8f18
                cp      $1E
                jp      z,chip8f1E
                cp      $29
                jp      z,chip8f29
                cp      $30
                jp      z,chip8f30
                cp      $33
                jp      z,chip8f33
                cp      $55
                jp      z,chip8f55

                cp      $65
                jp      z,chip8f65
                cp      $94
                jp      z,chip8f94
                cp      $FB
                jp      z,chip8fFB
                cp      $F8
                jp      z,chip8fF8
                cp      $75
                jp      z,octoChip8saveFlags
                cp      $85
                jp      z,octoChip8saveFlags
                cp      1
                jp      z,octoChip8Plane
                cp      2
                jp      z,octoChip8Audio
                cp      $3a
                jp      z,octoChip8Pitch     

                cp      0
                jp      z,octoChip8LongI

                if      breakonunknown=1
                ld      hl,iy
                ld      de,2
                sub     hl,de
                ld      bc,(hl)
                ld      de,chip8Memory
                sub     hl,de
                push    hl
                ld      a,b
                ld      b,c
                ld      c,a
                push    bc
                call    printf

                db      "/nunknown command %lx at %lx/n",0
                call    GetKey
               ld      a,DEBUG_STEP
                ld      (debug_go),a

                endif
                ret

chip8f07:       ; vx = delay
                ld      a,(ix+reg_delay)
                ld      (hl),a
                ret
                ; fx0a
chip8f0A:       call    GetKey
                cp      '0'
                jr      z,chip80a_debug
                cp      'M'
                jr      z,chip80a_menu
                call    translateHexKeybardA
                ld      (hl),a
                ret
chip80a_debug   ld      a,DEBUG_STEP
                ld      (debug_go),a
                call    printcpu
                jr      chip8f0A

chip80a_menu   call     chip8Menu
                jr      chip8f0A

chip8f15:       ; delay = vx
                ld a,(hl)
                ld (ix+reg_delay),a
                ret
chip8f18:       ; timer = vx
                ld      a,(hl)
                or      1
                ld      (ix+reg_sound),a
                ret
chip8f1E:       ; i = i + vx
                ld      e,(hl)
                ld      a,e
                ld      d,0
                ld      hl,(ix+reg_i)
                add     hl,de
                ld      (ix+reg_i),hl
                ld      a,0
                ld      de,$1000
                sub     hl,de
                adc     0
                ld      (ix+reg_vf),a
                ret
chip8f29:       ; i = font sprite x     ; 8x5 font
                ld      de,chip8Font-chip8Memory
                ld      a,(hl)
                and     15
                ld      l,a
                ld      h,0
                ld      bc,hl
                ; multiply by 5
                add     hl,hl   ; *2
                add     hl,hl   ; *4
                add     hl,bc   ; *5
;                add     hl,de   ; + base
                ld      (ix+reg_i),hl
                ret
chip8f30:       ; i= font sprite x   ; 16x10 font
                ld      de,bigfont-chip8Memory
                ld      a,(hl)
                ld      l,a
                ld      h,0
                ; each letter has 1 bytes * 10 lines = 10 bytes
                ; multiply by 20
                add     hl,hl   ; *2
                ld      bc,hl
                add     hl,hl   ; *4
                add     hl,hl   ; *8
                add     hl,bc   ; *10
                add     hl,de   ; + base
                ld      (ix+reg_i),hl
                ret

    ; bcd to i, i+1, i+2
chip8f33:   ;    ret
                ; convert vx to decimal and store in i+0, i+1, i+2
                ld      a,(hl)
                push    iy
                ld      hl,(ix+reg_i)
                ld      de,2
                add     hl,de
                ld      de,chip8Memory
                add     hl,de
                ld      iy,hl                   ; iy = i+3.

                ; we work backwards, hl=hl/10; de=hl*10, hl-de = last digit

                ld      b,3
                ld      l,a
                ld      h,0                     ; hl = vx
chip8f33_loop:  push    bc              
                ld      d,10
                push    hl
                call    DivHLxD
                ld      bc,hl
                ld      de,hl
                ld      a,10
                call    MulHleqDExA:
                ld      de,hl
                pop     hl
                sub     hl,de
                ld      a,l
                ld      hl,bc
                pop     bc
chip8fStore:    ld      (iy),a
                dec     iy                
                djnz    chip8f33_loop
                pop     iy
                ret
chip8f55:       ld      c,b              ; store  load vars v0..vx from I to vars
                ld      b,0
                inc     bc
                ld     hl,chip8Memory
                ld      de,(ix+reg_i)
                add     hl,de
                ld      de,cpu_registers+reg_v0
                ex      de,hl
                push    bc
                ldir
                pop     bc
                ld      a,(opt_new_addi)
                cp      1
                ret     z

                ld      hl,(ix+reg_i)
                add     hl,bc
                ld      (ix+reg_i),hl
                ret

chip8f65:       ld      a,b
                ld      c,b                ; load vars v0..vx from I to vars
                ld      b,0
                inc     bc
                push    bc
                ld      de,(ix+reg_i)
                ld      hl,chip8Memory
                add     hl,de
                ld      de,cpu_registers+reg_v0
                ldir
                pop     bc
                ld      a,(opt_new_addi)
                cp      1
                ret     z

                ld      hl,(ix+reg_i)
                add     hl,bc

                ld      (ix+reg_i),hl
                

                ret

chip8f75:
                ret
chip8f85:
                ret

chip8f94:
                ret

chip8fFB:
                ret

chip8fF8:
                ret

octoChip8saveFlags:
                ret
octoChip8loadFlags:
                ret
octoChip8Plane:
                ret
octoChip8Audio:
                ret
octoChip8Pitch:
                ret     
octoChip8LongI:
                ld hl,(iy)
                ld (ix+reg_i),hl
                inc iy
                inc iy
                ret              

                

startchip8:
chip8Emulator:
    call    clearScreen
    call    prepareChip8Screen
    call    initChip8

    ld      a,0
    call    setSuperChip
; copy sample rom

    ld      a,STARTMODE
    ld      (debug_go),a

    call    clearScreen
    call    printMenuHint
    ld      hl,chip8Memory+0x200

    ld      hl,chip8Memory+0x200
    call    chip8cpu

    ret



scroll: ret
resetcpu:
    call    setSuperChip
    call    clearScreen
    call    printMenuHint
    ld      iy,chip8Memory+0x200
    ld      ix,cpu_registers
    ld      hl,reg_stacktop
    ld      de,cpu_registers
    add     hl, de
    ld      (ix+reg_sp),hl

    ld      hl,cpu_registers
    ld      b,reg_size
resetloop:
    ld      (hl),0
    inc     hl
    djnz    resetloop

    call    countBreakpoints
    ld      a,0

    ret

/*
checkMemoryHl: dw 0
checkMemoryText: dw 0
checkMemory:
    ld      (checkMemoryHl),hl
    pop     hl
    ld      (checkMemoryText),hl
checkMemoryTxtLoop:
    ld      a,(hl)
    inc     hl
    cp      0
    jr      nz,checkMemoryTxtLoop
    push    hl
    ld      hl,(checkMemoryHl)
   PUSHA
    ld  hl,chip8Memory+0x200
    ld  de,rom_ibmlogo
    ld  bc,rom_ibmlogoend-rom_ibmlogo
checkMemoryLoop:
    ld  a,(de)
    cp  (hl)
    jr  nz,checkMemoryErr
    inc hl
    inc de
    dec bc
    ld  a,b
    cp  0
    jr  nz,checkMemoryLoop
    ld  a,c     
    cp  0
    jr  nz,checkMemoryLoop

checkMemoryEnd:
    POPA
    ret

checkMemoryErr:
    push    hl
    push    de
    push    bc
    
    ld      bc,0
    call    printSetAt
    push    hl
    ld      hl,(checkMemoryText)
    call    printTextHl
    
    call    newline
    pop     hl
    push    hl

    ld  de,chip8Memory
    sub hl,de
    ld      de,hl
    ld      hl,iy
    ld      bc,chip8Memory
    sub     hl,bc
    push    hl

    push    de
    push    de
    call    printf
    db      "Memory has changed/nat $%lx // %ld/ncpu at $%lx org adr=$%lx",0
    call    newline
    call    GetKey
    pop     bc
    pop     de
    pop     hl
    jp      checkMemoryLoop
*/



cpu_registers:
    defs    reg_size





opt_new_jump: 
            db  1           ; 0 = add register to jump
                            ; 1 = original jump
opt_new_addi
            db  0                           

cpu_new_shift:  
            db  0           ; 0 = new shift shift x inplace
                            ; 1 = old shift copy y to x and shift

opt_wait                    ; how many loops we do in cpu main loop to slow down the thing
            dw      0
; if set to 0 the instruction B220 will jump to 220 plus v2
; if set to 1 the instruction B220 will jump to 20 + v2
