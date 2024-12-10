
*Load all sounds in directx player
*input : a2 : sound files,
InitSounds:
.REGS REG d0-d2/a1-a3
.num_sounds equ 10
.long_size equ 4
    movem.l .REGS, -(sp)
    
    ;lea SOUNDFILES, a2 ;holding an array of sounds that I will load into a1
    moveq #(.num_sounds-1),d1   
     
.loop
    moveq #74, d0
    moveq #0, d2 ;index into the sounds array
    move.b d1, d2
    lsl.b #2, d2 ; multiply by 4 the index into the sounds array
    move.l (a2,d2),a1
    trap #15
    dbf d1, .loop
    
    movem.l (sp)+, .REGS
    rts   


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
