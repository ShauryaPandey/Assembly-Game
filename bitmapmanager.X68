
*Intention : Iterate pixel array and send instructions to render function
*Inputs 
*a1 : pixelarray
*a2 : Loaded bmp data
*d2 : width
*d3 : height
*d7 : background = 1
LoadBMPData:
.REGS REG d1-d3/a1-a2/d7
    movem.l .REGS, -(sp)
    
    jsr GetPadding
    move.l d1, -(sp)
.PointsStack EQU 24
    sub.l #.PointsStack, sp
    move.l #0, (sp) ;x
    move.l #0, (4,sp) ;y
    move.l d2, (8,sp) ;width - made change here
    move.l d3, (12,sp) ;height - made change here
    move.l #0, (16,sp) ;screen x
    move.l #0, (20,sp) ; screen y
*Input: a1 : pixel array, a2 : Memory address to load image in, d7 : background =1
    jsr LoadBMPInMemory
    add.l #.PointsStack, sp
    add.l #BMP_LONG_SIZE, sp

    movem.l (sp)+,.REGS
    rts
  

*input : a1 : file name,a2: imageData, a3 : loading dock, d2 : width, d3 : height, d7 : backgorund = 1
GetBMP:
.REGS REG d2-d3/a1-a3/d7
    movem.l .REGS, -(sp)
    jsr Bmp_load
    tst.b d0
    bne .error
    move.l a2, a1 
    sub.l #4, sp
    jsr GetPixelArray
    tst.b d0
    bne .error
    move.l (sp)+,a2 ;storing array start pointer in a2 
    add.l a2, a1 ; pixel arr add = file add + pixel arr off
    move.l a3, a2 ; loading dock in a2
    ;d2 = width
    ;d3 = height
    ;x = 0
    ;y = 0
    bsr LoadBMPData
    bra .done
.error
    moveq #1, d0
.done
    moveq #0,d0
    movem.l (sp)+, .REGS
    rts
    




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
