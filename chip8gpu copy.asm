
;--------------------------------------------------------------
; readraws the whole 64x64 pixel screen.E each pixel is displayed
; as 4x4 pixels.
;
; chip 8 screen. we have 64x64 pixels (8x64) bytes
; each pixel will be displayed as 4x4 pixels

; Make Space for variables on the Stack



        STRUCT SpriteVar
x               BYTE    ; Sprite x coordinate
y               BYTE    ; Sprite y coordinate
xbyte           BYTE    ; byte position in row (chip8 screen)
xlargebyte      WORD    ; byte positon in row (real screen)
lines           BYTE    ; Number of lines
data            WORD    ; Sprite Data 
magtable        WORD    ; Points to maginification table
line            WORD
lineEnd         WORD    ; end of current line
memory          WORD    ; Memory of top left byte where the sprite is on chip8 screen
screenIdx       WORD    ; Index in linedata. Points to the current line 
                ENDS  

updateOnInterrupt:      db      1       ; update screen via interrupt
screenDirty:            db      0       ; 1 if screen has modified 
screenNeedsRedraw:      db      0       ; we update on next cpu cycle

screenSkipFrames:       db      3
screenSkipCounter:      db      1       ; check on every x interrupts

dirtyScreenLines:       defs    64,0


updateGameScreen:
                push    bc
                push    hl
                push    iy
                push    ix
                ld      hl,dirtyScreenLines
                ld      b,64
updateGameScreen1:
                ld      (hl),a
                inc     hl
                djnz    updateGameScreen1
                ld      bc,0
                ld      hl,chip8Screen
                call    updateScreenChip8
                pop     ix
                pop     iy
                pop     hl
                pop     bc
                ret

updateGameScreenDirtyLines:
                push    iy
                push    ix
                ld      bc,0
                ld      hl,chip8Screen
                call    updateScreenChip8
                pop     ix
                pop     iy
                ret                

us_var_x    equ 1
us_var_y    equ 2
us_chip_y       equ 3
us_var_space equ 4

SCREEN_MODE_CHIP8 equ 0
SCREEN_MODE_SCHIP8 equ 1

updateScreenInterrupt:
                ld      hl,screenSkipCounter
                dec     (hl)
                ret     nz
                ld      a,(screenSkipFrames)
                ld      (hl),a
                ld      a,(updateOnInterrupt)
                cp      0
                ret     z
                ld      a,(screenDirty)
                cp      0
                ret     z
                jp      updateGameScreenDirtyLines
        
; ----------------------------------------------------------------------
; Update Screen Chip8
updateScreenChip8:
                PUSHA
                
    ;   hl = chip 8 screen
    ;   b  = line from top
    ;   c  = x position in char

                LAlloc       us_var_space
                ld      a,0
                ld      (screenDirty),a
                ld      (ix+us_chip_y),a
                ld      (ix+us_var_x),c
                ld      (ix+us_var_y),b
                ld      iy,chip8Screen
                ld      a,(screen_mag_x)
                cp      1

                jp      z,updateScreenChip81x1

                ld      a,b
                push    af
                ld      a,(screen_height)               
                ld      b,a
                pop     af
updateScreenChip8Loop1:        
                push    bc

                ld      a,(screen_widthbytes)
                ld      b,a

                ld      d,0
                ld      e,(ix+us_chip_y)
                inc     (ix+us_chip_y)
                ld      hl,dirtyScreenLines
                add     hl,de
                ld      a,(hl)
                cp      0
                
                jr      nz, updateScreenChip8Loop1a
; line is not dirty, so go to next line
                ld      a,(screen_mag_y)
                ld      b,a
                ld      a,(ix+us_var_y)
                add     b
                ld      (ix+us_var_y),a
                ld      a,(screen_widthbytes)
                inc     a                       ; 8 or 16 bytes plus two padding bytes
                inc     a
                ld      e,a
                add     iy,de
                pop     bc
                djnz updateScreenChip8Loop1   
                jr      updateScreenChip8End 
updateScreenChip8Loop1a:
                ld      a,0
                ld      (hl),a                  ; reset the dirty bit
                ld      a,e
                ld      a,(ix+us_var_y)
                call    calcLine
                ld      de,hl

updateScreenChip8Loop2:        
                push    bc
                push    de                   ; de = screen byte

                ld      a,(iy)                  ; a = chip8 screen byte
                ld      l,a
                ld      h,0
                ld      a,(screen_mag_x)
                cp      2
                jr      z,updateScreenChip8Loop2Super

                add     hl,hl
                add     hl,hl
                ld      de, chip8ScreenBytes
                add     hl,de                   ; hl = enlarged byte (4 bytes)
                pop     de
                jr      updateScreenChip8Loop4Paint

updateScreenChip8Loop2Super:                    ; in super chip, we multply by two and use the schip8ScreenBytes screen bytes   
                add     hl,hl
                ld      de, schip8ScreenBytes
                add     hl,de                   ; hl = enlarged byte (4 bytes)
                pop     de

; hl points to the 4 bytes of the enlarged byte pattern
; now copy it to the lines y, y+1, y+2, y+3
updateScreenChip8Loop4Paint:

; calc screen position        
; hl = address on speccy screen
; de = address of enlarged byte
; now copy 4 bytes
                ld      a,(screen_mag_x)
                ld      c,a
                ld      b,0
                ldir            
; continue with next byte
                inc     iy
                pop     bc                              ; pop schleifenzÃ¤hler
                djnz    updateScreenChip8Loop2  
                inc     iy
                inc     iy
; wie finished one screen line    
                ld      a,(ix+us_var_y)

// now copy the screen line to the next three lines
                call    calcLine
                ld      a,(screen_mag_x)
                dec     a
                ld      b,a
                ld      a,(ix+us_var_y)
                inc     a
        
updateScreenChip8CopyLine:
                push    bc
                push    hl
                call    calcLine
                inc     a
                pop     de
                push    de
                ex      hl,de
                ld      bc,32
                ldir
                pop     hl
                pop     bc
                djnz    updateScreenChip8CopyLine
        ;      inc     a
                ld      (ix+us_var_y),a
               ; inc     (ix+us_var_y)
                pop     bc
                dec     b
                jp      nz,updateScreenChip8Loop1   
                ;djnz updateScreenChip8Loop1   
        
updateScreenChip8End:
                LRelease us_var_space
                        
                POPA
                ret

updateGameScreen1x1:
                PUSHA
    ;   hl = chip 8 screen
    ;   b  = line from top
    ;   c  = x position in char

                LAlloc       us_var_space
                ld      (ix+us_var_x),c
                ld      (ix+us_var_y),b
                ld      iy,chip8Screen

updateScreenChip81x1:
                LRelease us_var_space

                ld      ix,linedata
                ld      a,(screen_height)
                ld      b,a
                ld      hl,chip8Screen
                ld      a,(screen_widthbytes)
                ld      c,a
updateScreenChip81x1LineLoop:
                push    bc
                ld      a,(screen_widthbytes)
                ld      c,a
                ld      b,0
                ld      de,(ix)
                ldir    
                inc     ix
                inc     ix
                inc     hl
                inc     hl
                pop     bc
                djnz    updateScreenChip81x1LineLoop
                
                POPA
                ret                
; ----------------------------------------------------------------------

; hl = Screen Address
clearScreenChip8:
        push    af
        push    bc
        push    hl
        ld      hl,chip8Screen
        ld  bc,1024
clearScreenChip8_1:
        
        ld a,0
        ld  (hl),a
        inc hl
        dec bc
        ld  a,c
        cp  0
        jr  nz,clearScreenChip8_1
        ld  a,b
        cp  0
        jr  nz,clearScreenChip8_1
        pop     hl
        pop     bc
        pop     af
        ret

initChip8:
        call    prepareChip8Screen
        call    prepareSChip8Screen
;        ld      hl, chip8Font
;        ld      de, chip8Memory+chip8FontAdr
;        ld      bc, chip8FontEnd-chip8Font
;        ldir
;        ld      hl,chip8Memory
        ld      de,$200
        add     hl,de
        ld      iy,hl
        ret
;---------------------------------------------------------------------------------------
; prepare the chip8 screen bytes
; in order not to shift during update, we pre-calculate all enlaged bytes from 00 to ff
; each enlarged byte is stored in 4 bytes
;---------------------------------------------------------------------------------------
prepareChip8Screen:
        ld  c,0
        ld  ix,chip8ScreenBytes
prepareChip8Screen_1:
        ld      a,c
        ld      b,8
        ld      hl,0
        ld      de,0
prepareChip8Screen_2:  
        push    bc
        ld      b,4
; shift rightmost bit into b1,b2,b3,b4 
; repeat 4 times
        rr	a
prepareChip8Screen_3:
        push    af
        rr      e
        rr      d
        rr      l
        rr      h
        pop     af
        djnz    prepareChip8Screen_3
; continue with next bit        
        pop     bc
        djnz    prepareChip8Screen_2
        ld      (ix),de
        inc     ix
        inc     ix
        ld      (ix),hl
        inc     ix
        inc     ix
        inc     c
        ld      a,c
        cp      0
        jr      nz, prepareChip8Screen_1
        ret

;---------------------------------------------------------------------------------------
; prepare the schip8 screen bytes
; in order not to shift during update, we pre-calculate all enlaged bytes from 00 to ff
; each enlarged byte is stored in 2 bytes
;---------------------------------------------------------------------------------------

prepareSChip8Screen:
        ld  c,0
        ld  ix,schip8ScreenBytes
prepareSChip8Screen_1:
        ld      a,c
        ld      b,8
        ld      de,0
prepareSChip8Screen_2:  
        push    bc
        ld      b,2
; shift rightmost bit into b1,b2,b3,b4 
; repeat 4 times
        rr	a
prepareSChip8Screen_3:
        push    af
        rr      e
        rr      d
        rr      l
        rr      h
        pop     af
        djnz    prepareSChip8Screen_3
; continue with next bit        
        pop     bc
        djnz    prepareSChip8Screen_2
        ld      (ix),de
        inc     ix
        inc     ix
        inc     c
        ld      a,c
        cp      0
        jr      nz, prepareSChip8Screen_1
        ret

; ---------------------------------------------------------------------------------
; the normal speccy print but in the chip8 display
; not used in the emulator, except for the title display
; hl = chip8 Display
; a = character
; b = x
; c = y
printChip8A:
	PUSH	AF
	PUSH	IX
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	L,	A
	LD	H,  0
	ADD	HL, HL
	ADD	HL, HL
	ADD	HL, HL
	LD	DE, CHARSET
	ADD	HL, DE
	LD	IX, HL			; ix points to the charmap of ascii A

        pop     hl
        push    hl              ; hl points to chip8 screen
        ld      d,0
        ld      e,b 
        add     hl,de           ; hl points to line 0, x in chip display
        ex      hl,de
        ld      l,c
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,de           ; hl points to target x,y in chip display
        ld      b,8
        ld      d,0
        ld      e,8
printChip8A_1:
        ld      a,(ix)
        ld      (hl),a
        inc     ix
        add     hl,de

        djnz    printChip8A_1

priprintChip8A_end:
	POP		HL
	POP		DE
	POP		BC
	POP		IX
	POP		AF
	ret

; -----------------------------------------------------------------
; chip 8 sprite
;       hl = i-Register
;        b = x
;        c = y
;        a = number of rows
;  if a = 0 we draw a schip sprite (16x16 pixel)

spriteCheckMaxLines:
; y coordinate of sprite
; (ix+SpriteVar.lines) = sprite height or 0 for 16
; return: (ix+SpriteVar.lines) = max number of sprite rows
        
        push            bc
        ld              a,(screen_height)
        ld              b,a
        dec             b
        ld              a,c
        and             b
        inc             b
        ld              c,a


        ld              a,(ix+SpriteVar.lines)
        cp              0
        jr              nz,spriteCheckMaxLines2
        ld              a,16
        ld              (ix+SpriteVar.lines),a
spriteCheckMaxLines2:
        add             a,c                             ; a = end of sprite (e.g. y=3 + 3 lines = 6)
        ld              c,a
        sub             b                               ; b = number of rows on screen (e.g. 32)
        jr              c,spriteCheckMaxLinesEnd        ; if negative, all is ok
        jr              z,spriteCheckMaxLinesEnd
        pop             bc
        push            bc
        ld              a,(screen_height)
        sub             c
        ld              (ix+SpriteVar.lines),a
 
spriteCheckMaxLinesEnd:
        pop             bc
        ret

chip8sprite:
        PUSHA
        push    ix
        push    iy
        LAlloc  SpriteVar                               ; ix points to variable space
        ld      (ix+SpriteVar.lines),a
        ld      a,(screen_mask_x)
        and     b
        ld      b,a
        ld      (ix+SpriteVar.x),a
        cp      120
        jr      nz, ok
        cp      0
ok:
        ld      a,(screen_mask_y)
        and     c
        ld      c,a
        ld      (ix+SpriteVar.y),a
        ld      (ix+SpriteVar.data),hl
        ld      a,(ix+SpriteVar.lines)
        push    ix
        cp      0
        jp      z,spriteSChip                           ; schip-sprites have 16x16 pixel
        push    af
        push    hl
        call    spriteCheckMaxLines
        ld      a,c
        ld      a,0
        ld      (cpu_registers+reg_vf),a                ; set vflag to 0 (no collision)
        ld      a,(screen_mask_x)
        and     b,a                                    ; clip coordinates
        ld      a,(screen_mask_y)
        and     c,a
; calc the offset into the (super) chip8 screen
; calc start of line    
        call    calcSpriteAdrInChip8Screen
 


        ld      a,b
        
        srl     a
        srl     a
        srl     a
        ld      e,a                             ; e = screen byte
        ld      a,(screen_widthbytes)
        dec     a
        cp      e
        ld      e,0
;        jr      nz, sprite8NotLastByte
;        ld      e,1
sprite8NotLastByte:        

        pop     iy
      
        ld      ix,hl

; now   c = number of bits to shift
;       ix = byte offset to screen
;       iy = byte offset to sprite
;       e = byte in row
;       d = row

        pop     af
        ld      b,a

;       b = number of rows

        ; row loop. 
        ; get the byte from iy, shift it c times 
spriteRow1:
        push    bc
        ld      b,c                     ; Number of times to shift
        ld      a,(iy)                  ; Get Sprite Byte 
        inc     iy                      ; go to the next sprite byte
        ld      l,0                     ; we shift hl
        ld      h,a
        cp      0
        jr      z,spritRowShift0       ; do not shift 0 byte
        ld      a,c                     ; shift 0 times?
        cp      0                        
        jr      z,spritRowShift0        ; skip shifting

spriteRowBit1:
        srl     h
        rr      l
        djnz spriteRowBit1
spritRowShift0:
        ; hl now contains the shifted byte
        ; ix contains the chip8 screen address 
        ; modify the byte and update real screen

        ld      a,h
        call    updateSpriteScreen
        inc     ix
        ld      a,l
        call    updateSpriteScreen
        dec     ix
        ld      hl,ix
        ld      a,(screen_widthbytes)
        inc     a
        inc     a
        push    de
        ld      e,a
        ld      d,0
        add     hl,de
        pop     de
        ld      ix,hl
        pop     bc
    
        djnz    spriteRow1              ; for each row
        pop     ix
        call    copySpriteToScreen

        LRelease SpriteVar
        pop     iy
        pop     ix
        POPA
        ret


; b = sprite byte in row
; c = sprite row
; a = byte to write
; hl = points to screen
updateSpriteScreen:
        push    de
        ld      d,a
;        ld      a,(screen_widthbytes)

; Detect collision
        ld      a,(ix)
        and     d
        cp      0
        jr      z,updateSpriteScreen1
        ld      a,1
        ld      (cpu_registers+reg_vf),a

; Write byte to Chip Screen
updateSpriteScreen1
        ld      a,(ix)
        xor     d
        ld      (ix),a
 ;       call    updateGameScreen            ; Update real screen
updateSpriteScreenEnd:
        pop     de
        ret
chip8spriteClipped:
        pop     af
        POPA
        ret

calcSpriteAdrInChip8Screen:
        ; input c = y row
        ;       b = x colum
        ; output
        ;       hl = Byte Adress
        ;        b = number of bits to shift
; calc the offset into the (super) chip8 screen
; calc start of line
        ld      a,(screen_width)
        ld      l,c
        ld      h,0
        add     hl,hl   ; *2
        ld      de,hl
        add     hl,hl   ; *4
        add     hl,hl   ; *8                            ; each row 8 bytes
        cp      64
        jr      z,schip8sprite_calc1
        add     hl,hl   ; *16
schip8sprite_calc1:        
        add     hl,de    
        ld      de, chip8Screen
        add     hl,de    
        ld      e,c
        ; hl now points to the start of the line
        ; y * 8 for chip 8 (64x32 Pixels) or
        ; y * 16 for schip (128x64 Pixels)

        ; calc the byte number in the row and add it to the row
        ld      e,b                                     ; hl = addres of row in chip8 screen
        srl     e                                       ; /2
        srl     e                                       ; /4
        srl     e                                       ; /8 d
        ld      d,0                                     ; each byte = 8 pixel
        add     hl,de                                   ; hl now points to the byte in the chip8 display
; HL now points to the correct byte inside the chip8 screen
; calc how many times we must shift the bit        
        ld      a,b
        and     7
        ld      b,a                                     ; b is the number of shifts we must do
        ld      c,b
        ret

; ----------------------------- schip sprite ---------------------------------------------
spriteSChip:
        push    af
        push    hl
        call    spriteCheckMaxLines

        ld      a,16
        ld      (ix+SpriteVar.lines),a
        ld      a,0
        ld      (cpu_registers+reg_vf),a                ; set vflag to 0 (no collision)
        call    calcSpriteAdrInChip8Screen
        pop     iy                                      ; pop sprite address to iy
        ld      ix,hl                                   ; ix = screen address

; now   c = number of bits to shift
;       ix = byte offset to screen
;       iy = byte offset to sprite
;       e = byte in row
;       d = row

        pop     af
        ld      b,16                                     ; super sprite is always 16 rows

;       b = number of rows

        ; row loop. 
        ; get the byte from iy, shift it c times 
sspriteRow1:
        push    bc
        ld      b,c                     ; Number of times to shift
        ld      a,(iy)                  ; Get Sprite Byte 
        ld      h,a
        inc     iy                      ; go to the next sprite byte
        ld      a,(iy)
        inc     iy
        ld      l,a
        ld      e,0

        or      h
        cp      0
        jr      z,sspritRowShift0       ; do not shift 0 byte
        ld      a,c                     ; shift 0 times?
        cp      0                        
        jr      z,sspritRowShift0        ; skip shifting

sspriteRowBit1:
        srl     h
        rr      l
        rr      e
        djnz sspriteRowBit1
sspritRowShift0:
        ; hl now contains the shifted byte
        ; ix contains the chip8 screen address 
        ; modify the byte and update real screen

        ld      a,h
        call    updateSpriteScreen
        inc     ix
        ld      a,l
        call    updateSpriteScreen
        inc     ix
        ld      a,e
        call    updateSpriteScreen
        dec     ix
        dec     ix

        ;       next line
        ld      hl,ix
        ld      a,(screen_widthbytes)
        inc     a
        inc     a
        ld      e,a
        ld      d,0
        add     hl,de
        ld      ix,hl
        pop     bc
    
        
        djnz    sspriteRow1              ; for each row
        pop     ix
        call    copySpriteToScreen
        ;call    updateGameScreen

        LRelease SpriteVar
        pop     iy
        pop     ix
        POPA
        ret
; write the byte a on line c byte b on the real screen
updateScreen:        
        push    hl
        push    iy
        push    ix
        push    ix              ; ix points to chip8 screen
        ld      a,(screen_mag_x)
        cp      2
        jr      z, updateSScreen

// calulate coordinates from ix
        pop     hl              ; hl now holds the chip8 screen
        ld      de,chip8Screen  ; calculate offset
        sub     hl,de
        ld      a,l             ; offset mod 8 = x coordinate in bytes
        and     7
        ld      b,a             ; store x coordinate to b
        ld      c,l
        srl     c
        srl      c
        srl      c
        ld      a,c
        add     a,a
        add     a,a
        ld      c,a
        
        push    de              ; calc screen line from line table
	LD	L,A             
	LD	H,0
	ADD	HL,HL
	LD	DE,linedata     
	ADD	HL,DE           ; hl points to start of line
        ld      iy,hl           ; store pointer to line table in iy
        ld      hl,(iy)
        pop     de

        ex      de,hl           ; calc byte offset * 4
        ld      l,b
        ld      h,0
        add     hl,hl           ; *2
        add     hl,hl           ; *4
        ld      bc,hl
        ex      hl,de
        add     hl,de           ; hl = screen coordinte
        ld      de,bc
        ld      b,4             ; 4 lines
updateScreenLine:
        push    bc
        push    ix
        push    de
        ld      b,2             ; 2 Bytes 
        ld      a,e
        cp      28
        jr      nz, updateScreenLine1
        ld      b,1
updateScreenLine1:        
        ld      de,hl      
updateScreen1:
        push    bc
        ld      a,(ix)
        inc     ix
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      bc,chip8ScreenBytes
        add     hl,bc
        ld      bc,4            ; 4 bytes each pixel magnified by 4
        ldir
        pop     bc
        djnz    updateScreen1
        pop     de

        inc     iy              ; look up the pointer for the next screen line
        inc     iy              ; after incrementing the pointer
        ld      hl,(iy)         ; instead of calling calcLine on each row
        add     hl,de           ; add the byte offset

        pop     ix
        pop     bc
        djnz    updateScreenLine   ; do for 4 lines

 ;       call    updateGameScreen
        pop     ix              ; restore registers
        pop     iy
        pop     hl
        ret

; updayte for super screen
; ----------------------------------

updateSScreen:
        add     hl,hl           ; hl = a * 2
        ld      de, schip8ScreenBytes
        add     hl,de           ; add base to enlarged bytes
        ld      ix,hl           ; ix points to enlarged byte


// calulate coordinates from ix
        pop     hl              ; hl now holds the chip8 screen
        ld      de,chip8Screen  ; calculate offset
        sub     hl,de
        ld      a,l             ; offset mod 16 = x coordinate in bytes
        and     15
        ld      b,a             ; store x coordinate to b
        srl     h               ; calc offset / 8 to give the line
        rr      l               ; /2
        srl     h               ; /4
        rr      l
        srl     h               ; /8
        rr      l                      
        srl     h               ; /16
        rr      l                      
        ; calculate the screen line in real screen
        ld      a,l
        add     a,a     ; * 2   ; each byte is 2 rows in real screen
        ld      c,a     
 
        push    de              ; calc screen line from line table
	LD	L,A             
	LD	H,0
	ADD	HL,HL
	LD	DE,linedata     
	ADD	HL,DE           ; hl points to start of line
        ld      iy,hl           ; store pointer to line table in iy
        ld      hl,(iy)
        pop     de

        ex      de,hl           ; calc byte offset * 4
        ld      l,b
        ld      h,0
        add     hl,hl           ; *2
;        add     hl,hl           ; *4
        ex      hl,de
        add     hl,de           ; hl = screen coordinte
        ld      b,2
updateSScreen1:
        push    bc
        push    de              ; de = byte offset in screen row
        ld      de,hl           ; target = screen bytes
        ld      hl,ix           ; de now points to enlarged byte
        ld      bc,2            ; 4 bytes each pixel magnified by 4
        ldir
        pop     de
        pop     bc
        inc     iy              ; look up the pointer for the next screen line
        inc     iy              ; after incrementing the pointer
        ld      hl,(iy)         ; instead of calling calcLine on each row
        add     hl,de           ; add the byte offset
        djnz    updateSScreen1   ; do for 4 lines

        pop     ix              ; restore registers
        pop     iy
        POPA
        ret

; ------------------------------------------------------------------------
; copy sprite to screen
; ix = pointer to variables
; ------------------------------------------------------------------------

copySpriteToScreen:
        ld      a,1
        ld      (screenDirty),a
        ld      a,(updateOnInterrupt)
        cp      1
        jr      nz,copySpriteToScreen1a
        ld      l,(ix+SpriteVar.y)
        ld      h,0
        ld      de,dirtyScreenLines
        add     hl,de
        ld      a,(ix+SpriteVar.lines)
        ld      b,a
        ld      a,1
        
copySpriteToScreenMarkDirty:    
        ld      (hl),a
        inc     hl
        djnz    copySpriteToScreenMarkDirty
        ret        

copySpriteToScreen1a
        ld      a,(screen_mag_x)
        cp      1
        jp      z,updateScreen1x1
 ;       call    markScreen
        ; 1.Calc the byte position in chip8 screen
        ; ----------------------------------------
        ld      l,(ix+SpriteVar.y)
        ld      h,0
        ld      a,(screen_widthbytes)
        ld      c,a
        add     hl,hl                           ; *2
        ld      de,hl
        add     hl,hl                           ; *4
        add     hl,hl                           ; *8
        cp      8
        jr      z,copySpriteToScreen1
        add     hl,hl   ; *16

copySpriteToScreen1:
        add     hl,de
        ld      a,(ix+SpriteVar.x)
        srl     a                               ; / 2
        srl     a                               ; / 4
        srl     a                               ; / 8
        ld      (ix+SpriteVar.xbyte),a          
        ld      e,a
        ld      d,0
        add     hl,de
        ld      de,chip8Screen
        add     hl,de
        ld      (ix+SpriteVar.memory),hl
        ; ----------------------------------------


        ; 2. calc the line index from the line
        ; and the maginification
        ; ----------------------------------------
        
        ld      a,(ix+SpriteVar.y)
        ld      l,a
        ld      h,0
        ld      a,(screen_mag_x)                             ; b = screen width 8 or 16
        add     hl,hl                           ; * 2
        cp      2
        jr      z,copySpriteToScreen2
        add     hl,hl                           ; * 4
copySpriteToScreen2: 
        add     hl,hl                           ; hl = line for sprite * 2
        ld      de,linedata
        add     hl,de
        ld      (ix+SpriteVar.screenIdx),hl
        ; ----------------------------------------



        ;3.  calc x offset to start of line in byte on real screen
        ;    this is the x byte offset * 2 (schip8) or * 4 (chip8)
        ; ----------------------------------------
        ld      a,(screen_mag_x)
        cp      4
        jr      z,copySpriteToScreenMag4        ; calc for chip8 (4x4 pixel per pixel)

        ld      a,(ix+SpriteVar.xbyte)
        add     a,a
        jr      copySpriteToScreenMag
copySpriteToScreenMag4:
        ld      a,(ix+SpriteVar.xbyte)
        add     a,a
        add     a,a
copySpriteToScreenMag:
        ld      l,a
        ld      h,0
        ld      (ix+SpriteVar.xlargebyte),hl
        ; ----------------------------------------
        ; 4. Loop over each line of the sprite
        ; ----------------------------------------
        ld      a,(ix+SpriteVar.lines)
        ld      b,a
copySpriteToScreenLineLoop:
        push    bc

        ; ----------------------------------------
        ; calc the exact byte position of the screen
        ; (SpriteVar.screenIdx) points to start of line
        ; (ix+spriteVar.xlargebyte) must be added
        ; ----------------------------------------

        ; ----------------------------------------
        ;       calc screen bytes
        ; ----------------------------------------
        ld      hl,(ix+SpriteVar.screenIdx)
        ld      de,(hl)
        ld      hl,de
        

        ld      hl,(ix+SpriteVar.xlargebyte)
        add     hl,de
        ld      de,hl

        ; ----------------------------------------
        ; hl now points to the target
        ; copy sprite data to the next 2 or 4 lines
        ; ----------------------------------------

        ld      a,(screen_mag_y )
        ld      b,a
copySpriteToScreenChipCopyLineLoop        
        push    bc

        ; ----------------------------------------
        ; loop over 2 scren bytes Bytes
        ; copy them to 8 (chip8) or 4 (schip) bytes
        ; ----------------------------------------
        ld      a,(screen_bytes_per_pixel)
        ld      b,a
        ld      a,(ix+SpriteVar.xbyte)
        ld      c,a
        ld      a,(screen_widthbytes)
        dec     a
        cp      c        
        jr      nz,copySpriteToScreenChipCopyLineLoop1a
        ld      b,1
copySpriteToScreenChipCopyLineLoop1a:        
        dec     a
        cp      c        
        jr      nz,copySpriteToScreenChipCopyLineLoop1
        ld      b,1

copySpriteToScreenChipCopyLineLoop1        

        ld      hl,(ix+SpriteVar.memory)
        ld      iy,hl                           ; iy points to sprite data
                                
copySpriteToScreenChipByteLoop:
        push    bc                              ; bc holds loop counter
        push    de                              ; de points to screen
        ld      h,0
        ld      a,(screen_mag_x)
        cp      4
        jr      z,copySpriteToScreenChipByteLoopMag4

        ld      a,(iy)
        ld      l,a
        add     hl,hl
        ld      de,schip8ScreenBytes             ; enlarged byte
        ld      bc,2                             ; two bytes to copy
        jr      copySpriteToScreenChipByteLoopMagEnd

copySpriteToScreenChipByteLoopMag4:
        ld      a,(iy)   
        ld      l,a
        add     hl,hl           
        add     hl,hl
        ld      de,chip8ScreenBytes
        ld      bc,4
copySpriteToScreenChipByteLoopMagEnd:   
        add     hl,de                           ; hl points to enlarged byte

        pop     de                              ; de points to screen

        ldir
copySpriteToScreenChipByteCopy2:        
        inc     iy
        pop     bc

        djnz    copySpriteToScreenChipByteLoop 

        ; go to next screen line
        ld      hl,(ix+SpriteVar.screenIdx)
        inc     hl
        inc     hl
        ld      (ix+SpriteVar.screenIdx),hl
        ld      de,(hl)
        ld      hl,(ix+SpriteVar.xlargebyte)
        add     hl,de
        ld      de,hl

; continue line loop
        pop     bc
        dec     b
        jp      nz,copySpriteToScreenChipCopyLineLoop
        ;djnz    copySpriteToScreenChipCopyLineLoop

        ld      hl,(ix+SpriteVar.xlargebyte)

        ld      hl,(ix+SpriteVar.memory)        ; go to next chip8 screen line
        ld      a,(screen_widthbytes)
        inc     a
        inc     a                               ; add to padding bytes
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (ix+SpriteVar.memory),hl


        pop     bc
        dec     b
        jp      nz,copySpriteToScreenLineLoop

        ; go to next sprite line
        ld      hl,(ix+SpriteVar.memory)
        ld      de,(screen_widthbytes)
        add     hl,de
        ld      (ix+SpriteVar.memory),hl

        ret
copySpriteToScreenChipByteCopy1:
        pop     de
        pop     hl
        jr      copySpriteToScreenChipByteCopy2



; --------------------------------------------------
; -- Sprite Update without maginification
; -- since there is no processing needed
; -- the small display is faster        

updateScreen1x1:
    ;    jp      updateGameScreen
        ; 1.Calc the byte position in chip8 screen
        ; ----------------------------------------
        ld      l,(ix+SpriteVar.y)
        ld      h,0
        ld      a,(screen_widthbytes)
        ld      c,a
        add     hl,hl                           ; *2
        ld      de,hl
        add     hl,hl                           ; *4
        add     hl,hl                           ; *8
        cp      8
        jr      z,copySpriteToScreen1x1a
        add     hl,hl   ; *16
copySpriteToScreen1x1a:
        add     hl,de
        ld      a,(ix+SpriteVar.x)
        srl     a                               ; / 2
        srl     a                               ; / 4
        srl     a                               ; / 8
        ld      (ix+SpriteVar.xbyte),a
        ld      e,a
        ld      d,0
        ld      (ix+SpriteVar.xlargebyte),de
        add     hl,de
        ld      de,chip8Screen
        add     hl,de
        ld      (ix+SpriteVar.memory),hl
        ; ----------------------------------------
        ; 2. calc the line index from the line
        ; and the maginification
        ; ----------------------------------------  
        ld      a,(ix+SpriteVar.y)
        ld      l,a
        ld      h,0
        add     hl,hl                           ; hl = line for sprite * 2
        ld      de,linedata
        add     hl,de
        ld      (ix+SpriteVar.screenIdx),hl
        ; ----------------------------------------
        ld      a,(ix+SpriteVar.lines)
        ld      b,a
copySpriteToScreen1x1LineLoop:
        push    bc
        ld      hl,(ix+SpriteVar.screenIdx)
        ld      de,(hl)
        ld      hl,(ix+SpriteVar.xlargebyte)
        ld      a,l
        add     hl,de
        ld      de,hl
        ld      hl,(ix+SpriteVar.memory)
        ld      bc,2
        
        cp      7
        jr      nz,copySpriteToScreen1x1LineLoop1
        ld      c,1
copySpriteToScreen1x1LineLoop1:
        ldir
        ld      de,hl
        ld      hl,(ix+SpriteVar.screenIdx)
        inc     hl
        inc     hl
        ld      (ix+SpriteVar.screenIdx),hl

        ld      hl,(ix+SpriteVar.memory)
        ld      a,(screen_widthbytes)
        inc     a
        inc     a
        ld      e,a
        ld      d,0
        add     hl,de
        ld      (ix+SpriteVar.memory),hl
        
        pop     bc
        djnz    copySpriteToScreen1x1LineLoop            
        ret

; ----------------- draw sprite schip 

screen_width:           db 64                   ; pixel width of screen
screen_height:          db 32                   ; number of lines of screen
screen_widthbytes:      db 8                    ; number of bytes per row
screen_mag_x            db 4                    ; x factor of maximization, can be 1,2 or 4        
screen_mag_y            db 4                    ; y factor of maximization can be 1,2 or 4

screen_mask_x           db  63
screen_mask_y           db 31

screen_bytes_per_pixel  db  2

chip8_screen_mode       db  0

; a = 0 : Chip8
; a = 1 : Supe Chip             ; bit 0
; a = 4 : 1x1 Displkay          ; bit 3


SCREEN_MODE_NO_ZOOM     equ     4

setSuperChip            ld      (chip8_screen_mode),a
                        push    af
                        and     3
                        call    setSuperChipSub
                        pop     af
                        and     SCREEN_MODE_NO_ZOOM
                        ret     z
                        ld      a,1
                        ld      (screen_mag_x),a
                        ld      (screen_mag_y),a
                        ret     

setSuperChipSub:        push    hl
                        cp      0
                        jr      z,setChipScreen
                        ld      hl,128
                        ld      (screen_width),hl
                        ld      hl,64
                        ld      (screen_height),hl
                        ld      a,16
                        ld      (screen_widthbytes),a                        
                        ld      a,2
                        ld      (screen_mag_x),a
                        ld      (screen_mag_y),a
                        ld      a,127
                        ld      (screen_mask_x),a
                        ld      a,63
                        ld      (screen_mask_y),a
                        ld      a,3
                        ld      (screen_bytes_per_pixel),a


                        pop     hl
                        ret
setChipScreen:          ld      hl,64
                        ld      (screen_width),hl
                        ld      hl,32
                        ld      (screen_height),hl
                        ld      a,8
                        ld      (screen_widthbytes),a
                        ld      a,4
                        ld      (screen_mag_x),a
                        ld      (screen_mag_y),a
                        ld      a,63
                        ld      (screen_mask_x),a
                        ld      a,31
                        ld      (screen_mask_y),a
                        ld      a,2
                        ld      (screen_bytes_per_pixel),a

                        pop     hl
                        ret


; ------------------ scrolling -------------------------------------

scroll4Right:
        PUSHA
        ld      hl,chip8Screen
        ld      a,(screen_height)
        ld      b,a
        ld      a,(screen_widthbytes)
        ld      c,a
        ld      e,a
        ld      d,0
scroll4RightLoop:
        push    bc
        ld      b,c
        ld      a,0
        ld      a,0
scroll4RightLoop2:
        rrd
        inc     hl
        djnz    scroll4RightLoop2
        pop     bc
        djnz    scroll4RightLoop
        call    updateGameScreen
        POPA    
        ret

scroll4Left:
        PUSHA
        ld      hl,chip8Screen
        ld      a,(screen_height)
        ld      b,a
        ld      a,(screen_widthbytes)
        ld      e,a
        ld      d,0   
        ld      c,a
scroll4LeftLoop:
        push    bc
        add     hl,de
        push    hl
        ld      b,c
        ld      a,0
        dec hl
scroll4LeftLoop2:
        rld
        dec     hl
        djnz    scroll4LeftLoop2
        pop     hl
        pop     bc
        djnz    scroll4LeftLoop
        call    updateGameScreen
        POPA    
        ret

scrollDownA:    
        PUSHA
        push    af
        ld      b,a

        ld      e,a
        ld      d,0
        ld      a,(screen_widthbytes)
        call    MulHleqDExA
        push    hl                      ; hl = number of rows * bytes

        ld      a,(screen_widthbytes)
        ld      e,a
        ld      d,0
        ld      a,(screen_height)
        dec     a
        call    MulHleqDExA             ; hl = offset to start of last line in screen

        ld      bc,chip8Screen
        add     hl,bc                   ; hl/de = last line of screen
        ld      de,hl   
        pop     bc      
        sub     hl,bc                   ; hl = last line - offset
       ; ex      hl,de

        pop     af
        push    af
        ld      b,a
        ld      a,(screen_height)
        sub     b
        ld      b,a                     ; number of rows (total-a)
        ld      a,(screen_widthbytes)
scrollDownLoop:
        push    bc
        ld      b,0
        ld      c,a
        ldir                            ; copy a line
        ld      c,a
        ld      b,0
        sub     hl,bc                   ; advance to previou lines
        sub     hl,bc
        ex      hl,de
        sub     hl,bc
        sub     hl,bc
        ex      hl,de
        pop     bc
        djnz    scrollDownLoop

        pop     af
        ld      hl,chip8Screen
        ld      c,a
scrollDownLoop1:
        ld      a,(screen_widthbytes)
        ld      b,a
        ld      a,0
scrollDownLoop2:
        ld      (hl),a        
        inc     hl
        djnz    scrollDownLoop2
        dec     c
        jr      nz,scrollDownLoop1

        call    updateGameScreen
        POPA
        ret
scrollUpA:
            ret

checkMultipleHexKeyA:  
                ;  returns a = 1 if the key a is pressed
                ;          a = 0 if not
                push    bc
                push    hl
                ld      b,a
                call    ReadMKeyboard       
                ld      hl,ReadKeyboardPressedKeys
checkMultipleHexKeyLoop:
                ld      a,(hl)
                inc     hl
                cp      0
                jr      z,checkMultipleHexKeyNotFound
                call    translateHexKeybardA
                cp      a,b
                jr      nz,checkMultipleHexKeyLoop
                ld      a,1
                pop     hl
                pop     bc
                cp      0
                ret
checkMultipleHexKeyNotFound:
                ld      a,0
                pop     hl
                pop     bc
                cp      0
                ret


readHexKeyboard:
                call    ReadKeyboard
                cp      0
                jr      nz,readHexKeyboard1
readHexKeyboardNoKey:
                ld      bc,$0017
                call    printSetAt
                call    printtext
                db      "Key:-",0
                ld      a,$ff
                ret
readHexKeyboard1:
translateHexKeybardA:
                push    hl
                push    bc
                ld      hl,keyboard_map
                ld      b,a
                dec     hl
readHexKeyboard2:         
                inc     hl                                  
                ld      a,(hl)
                inc     hl
                cp      0
                jr      z,readHexKeyboardNoKey2
                ld      c,(hl)
                cp      b
                jr      nz,readHexKeyboard2
                ld      a,0
                ld      (charX),a
                ld      a,23
                ld      (charY),a
                push    af
                call    printtext
                db      "Key:",0
                pop     af
                ld      a,c
                call    printNibble
                ld      a,c
                pop     bc
                pop     hl
                ret
readHexKeyboardNoKey2:
                ld      bc,$0017
                call    printSetAt
                call    printtext
                db      "Key:-",0
                ld      a,$ff
                pop   bc
                pop   hl
                ret





screen_translation_table: 
                        dw chip8ScreenBytes

; for chip8 we have 64x32 pixels each 4x4 pixels wide
; for super chip8 we have 128x64 pixels each 2x2 screen pixels
; in debugger view we may have 1x1 pixels per pixel





keyboard_map:
            db  '1', $1
            db  '2', $2
            db  '3', $3
            db  '4', $C

            db  'Q', $4
            db  'W', $5
            db  'E', $6
            db  'R', $D

            db  'A', $7
            db  'S', $8
            db  'D', $9
            db  'F', $E

            db  'Z', $A
            db  'Y', $A
            db  'X', $0
            db  'C', $B
            db  'V', $F

            
            db  0,0

chip8Font1016:
        defs    16*2*10
chip8FontEnd:





; for super chip 8 we need 128x64 pixel, 16x64 bytes = 1024 Bytes



