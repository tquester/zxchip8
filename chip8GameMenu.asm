
chip8GameMenu:
        call            clearScreen
        ld              bc,0
        call            printSetAt
        call            printf
        db              "/t/tGames/n",0

        ld              de,1

        ld              hl,chip8Games

chip8GameMenuLoop:

        ld              a,(hl)
        cp              0
        jr              z,chip8GameMenuWait
        push            de
        push            hl
        push            de
        call            printf
        db              "/n%h/t",0
        pop             hl
        pop             de
        call            printHL
        call            skipStringHL
        call            skipStringHL

        ld              bc,(hl)
        add             hl,bc
        inc             de
        jr              chip8GameMenuLoop        

chip8GameMenuWait:
        call            printf
        db              "/n>:",0
        call            GetKey
        cp              'A'
        jr              z,chip8GameMenuStartFindA
        jr              nc,chip8GameMenuStartFindA
        sub             '1'
        jr              c,chip8GameMenu
        jr              chip8GameMenuStartFind    

chip8GameMenuStartFindA:
        sub             'A'-9
                                 
chip8GameMenuStartFind        
        ; go to game
        ld              hl,chip8Games
chip8GameMenuFind
        push            af
        ld              a,(hl)        
        cp              0
        jr              z,chip8GameMenuNotFound
        pop             af

        cp              a,0
        jr              z,chip8GameMenuFound

        call            skipStringHL
        call            skipStringHL
        ld              de,(hl)
        add             hl,de
        dec             a
        jr              chip8GameMenuFind
chip8GameMenuNotFound:      
        jr              chip8GameMenu
        

chip8GameMenuFound:
        call             skipStringHL    
        push            af            
        ld               a,(hl)
        cp               0
        jr               z,chip8GameMenuFoundNoText
        ld              (gameInfo),hl
        call            printPagedHL


chip8GameMenuFoundNoText: 
        pop             af
        call             skipStringHL                
        ld               bc,(hl)
        inc              hl
        inc              hl
        ld               de,chip8Memory+$200
        ldir
        call             resetcpu
        call            clearScreenChip8
        ret
        




skipStringHL:
        push            af
skipStringHLLoop        
        ld              a,(hl)
        inc             hl
        cp              0
        jr              nz,skipStringHLLoop
        pop             af
        ret
        