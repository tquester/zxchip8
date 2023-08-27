# zxchip8
A chip8/superchip8 emulator for the ZX Spectrum

In order to compile the project, you need Visual Studio and Dezog https://github.com/maziac/DeZog.

The emulator can contain some games, which are not included into the project.
You can find lots of games here:
https://archive.org/details/chip-8-games
https://github.com/kripod/chip8-roms

Some are included in the sample .tap

The project also contains a java project and a jar file. For Windows there is a batch file loadgame.cmd. Start it with a chip8 game as a parameter and it will copy the game into the tape file and save it under a new name, then starts fuse as zx spectrum eumulator.
You must modify the path and probably call your favourite zx spectrum emulator.
If you double click a chip8 game in the Windows explorer, select startgame.cmd as the command to open it. From now on, just double click a chip8 game and it starts automatically in your zx spectrum emulator.
You need to update the path information in the batch file.

# debugger
The emulator contains a small debugger

# status
The emulator runs most games. Sprites need some more optimizations and still there is no vertical interrupt.



![image](https://github.com/tquester/zxchip8/assets/5380723/2541187a-b1a7-421f-b1f2-d72a53954603)
![image](https://github.com/tquester/zxchip8/assets/5380723/ba216e44-c4ed-43f6-9311-58f4e8481dc0)


