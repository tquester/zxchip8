ZXB_CLEAR       EQU     $FD
ZXB_VAL         EQU     $B0
ZXB_INPUT       EQU     $EE
ZXB_LET			equ		#F1
ZXB_LOAD        EQU     $EF
ZXB_CODE        EQU     $AF
ZXB_RANDOMIZE   EQU     $F9
ZXB_USR         EQU     $C0
ZX_PRINT		equ	#F5
ZX_STOP		    equ	#E2

ZXB_GOTO		equ	#Ec

LAlloc     		MACRO   value
				push	hl
				push	de
				push	bc
                ld	hl,0
                add	hl,sp
                ld	de,value
                sub	hl,de
                ld	ix,hl
                ld	sp,hl
				ld	bc,(ix+value)
				ld	de,(ix+value+2)
				ld	hl,(ix+value+4)
                ENDM

LRelease	    MACRO   value
                ld		hl,0
                add		hl,sp
                ld		de,value
                add		hl,de
                ld		sp,hl	  
				pop		bc
				pop		de
				pop		hl              
                ENDM

LAllocNoPush	MACRO   value
                ld	hl,0
                add	hl,sp
                ld	de,value
                sub	hl,de
                ld	ix,hl
                ld	sp,hl
				ld	bc,(ix+value)
				ld	de,(ix+value+2)
				ld	hl,(ix+value+4)
                ENDM

LReleaseNoPush  MACRO   value
                ld		hl,0
                add		hl,sp
                ld		de,value
                add		hl,de
                ld		sp,hl	  
                ENDM				

PUSHA           MACRO    
                    PUSH    AF
                    PUSH    BC
                    PUSH    DE
                    PUSH    HL
                ENDM

POPA           MACRO   
                    POP     HL
                    POP     DE
                    POP     BC
                    POP     AF
                ENDM	

JUMP			MACRO   target
				if abs($-target) < 128
				jr		target
				else
				jp		target
				endif
				ENDM

JZ				MACRO   target
				if abs($-target) < 128
				jr		z,target
				else
				jp		z,target
				endif
				ENDM				

JNZ				MACRO   target
				if abs($-target) < 128
				jr		nz,target
				else
				jp		nz,target
				endif
				ENDM				

JC				MACRO   target
				if abs($-target) < 128
				jr		c,target
				else
				jp		c,target
				endif
				ENDM	

JNC				MACRO   target
				if abs($-target) < 128
				jr		nc,target
				else
				jp		nc,target
				endif
				ENDM				



line_useval	=	0
line_number	=	10
line_step	=	10

;; Begin of basic line

LINE  MACRO
	ASSERT line_number < #4000 , Line number overflows
	db	high line_number
	db	low line_number
	LUA ALLPASS
	sj.parse_code('dw line_' .. tostring(sj.calc("line_number")) .. '_length')
	sj.parse_line(   'line_' .. tostring(sj.calc("line_number")) .. '_begin')
	ENDLUA
      ENDM

;; End of basic line

LEND  MACRO
	db	#0D
	LUA ALLPASS
	sj.parse_line('line_'
		.. tostring(sj.calc("line_number"))
		.. '_length = $ - line_'
		.. tostring(sj.calc("line_number"))
		.. '_begin')
	ENDLUA
line_number  =	line_number + line_step
      ENDM

;; Include number value into basic line

NUM   MACRO	value
	IF line_useval
	  db	val,'"'
	ENDIF
	  LUA ALLPASS
	  sj.parse_code('db	"' .. tostring(sj.calc("value")) .. '"')
	  ENDLUA
	IF line_useval
	  db	'"'
	ELSE
	  db	#0E,0,0
	  dw	value
	  db	#00
	ENDIF
      ENDM


    MACRO        MakeTape tape_file?, prog_name?, code_adr?, code_len?

                ORG     #5C00
.bas_start    
				LINE	
				DB      ZXB_CLEAR, ZXB_VAL, '"24500":'
				DB		ZXB_LET,"A=",ZXB_VAL, '"24500":'
				LEND

				LINE	
                DB      ZXB_LOAD, '"'                           ; LOAD "
.code_name      DB      prog_name?                              ; code name
                ASSERT ($ - .code_name) <= 10                   ; (max 10 chars)
                DB      '"',ZXB_CODE,'a:'                       ; " CODE a:
				LEND

	;			LINE
	;			db		ZX_STOP
	;			LEND

				LINE
				db		ZXB_LET, "ADR=",ZXB_USR,'a '
				LEND

				LINE
				db		ZX_PRINT, "ADR:", ZX_STOP
				LEND

				LINE
				db		ZXB_LOAD, '""', ZXB_CODE, 'ADR'
				LEND

			;	LINE
			;	db		ZXB_GOTO: NUM 10	:
			;	LEND



.bas_len        EQU     $-.bas_start

            EMPTYTAP tape_file?
            SAVETAP  tape_file?,BASIC,prog_name?,.bas_start,.bas_len,1
            ; make CODE-block load address 0, so it must be overriden by "LOAD CODE" explicitly

            SAVETAP  tape_file?,CODE,prog_name?,code_adr?,code_len?,0
			ENDM

        MACRO        MakeBinTape tape_file?, prog_name?, code_adr?, code_len?
        SAVETAP  tape_file?,CODE,prog_name?,code_adr?,code_len?,0
    	ENDM

