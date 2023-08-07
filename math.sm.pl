
Mul8:                            ; this routine performs the operation HL=DE*A
  ld hl,0                        ; HL is used to accumulate the result
  ld b,8                         ; the multiplier (A) is 8 bits wide
Mul8Loop:
  rrca                           ; putting the next bit into the carry
  jp nc,Mul8Skip                 ; if zero, we skip the addition (jp is used for speed)
  add hl,de                      ; adding to the product if necessary
Mul8Skip:
  sla e                          ; calculating the next auxiliary product by shifting
  rl d                           ; DE one bit leftwards (refer to the shift instructions!)
  djnz Mul8Loop
  ret

  Mul8b:                           ; this routine performs the operation HL=H*E
  ld d,0                         ; clearing D and L
  ld l,d
  ld b,8                         ; we have 8 bits
Mul8bLoop:
  add hl,hl                      ; advancing a bit
  jp nc,Mul8bSkip                ; if zero, we skip the addition (jp is used for speed)
  add hl,de                      ; adding to the product if necessary
Mul8bSkip:
  djnz Mul8bLoop
  ret

  Div8:                            ; this routine performs the operation HL=HL/D
  xor a                          ; clearing the upper 8 bits of AHL
  ld b,16                        ; the length of the dividend (16 bits)
Div8Loop:
  add hl,hl                      ; advancing a bit
  rla
  cp d                           ; checking if the divisor divides the digits chosen (in A)
  jp c,Div8NextBit               ; if not, advancing without subtraction
  sub d                          ; subtracting the divisor
  inc l                          ; and setting the next digit of the quotient
Div8NextBit:
  djnz Div8Loop
  ret

  Mul16:                           ; This routine performs the operation DEHL=BC*DE
  ld hl,0
  ld a,16
Mul16Loop:
  add hl,hl
  rl e
  rl d
jp nc,NoMul16
  add hl,bc
  jp nc,NoMul16
  inc de                         ; This instruction (with the jump) is like an "ADC DE,0"
NoMul16:
  dec a
  jp nz,Mul16Loop
  ret