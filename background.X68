BACKGROUND_WIDTH EQU 580
BACKGROUND_HEIGHT EQU 540

STARTSCREEN_WIDTH equ 400
STARTSCREEN_HEIGHT equ 400

LOSESCREEN_WIDTH  equ 400
LOSESCREEN_HEIGHT equ 400
WINSCREEN_WIDTH   equ 400
WINSCREEN_HEIGHT  equ 400

TIMER_WIDTH equ 100
TIMER_HEIGHT equ 100
RECORDSLEFT_WIDTH equ 100
RECORDSLEFT_HEIGHT equ 100

*This function draws the background
*input : a1 : background file
DrawBackground
    move.l a1, -(sp)
    ;lea LoadedBackground, a1
    move.l #0, -(sp) ;y
    move.l #0, -(sp) ;x
    move.l #BACKGROUND_HEIGHT, -(sp) ;height
    move.l #BACKGROUND_WIDTH , -(sp) ;width
    
    jsr FastRenderBackground2 ;since there is no transparency here we can optimize by calling an overloaded function
    add.l #16, sp
    move.l (sp)+,a1
    rts
*BITMAP
*input : a1 : start screen file, d1 : y, d2 : x
DrawStartScreen
.REGS REG d1-d2/a1
    movem.l .REGS, -(sp)
    move.l #0, -(sp) ;y
    move.l #0, -(sp) ;x
    move.l #STARTSCREEN_HEIGHT, -(sp) ;height
    move.l #STARTSCREEN_WIDTH, -(sp) ;width
    
    jsr FastRenderBackground2 ;since there is no transparency here we can optimize by calling an overloaded function
    add.l #16, sp
    movem.l (sp)+,.REGS
    rts
*input : a1 : loadedLose
DrawLoseScreen
.REGS REG d1-d2/a1
    movem.l .REGS, -(sp)
    move.l #0, -(sp) ;y
    move.l #0, -(sp) ;x
    move.l #LOSESCREEN_HEIGHT, -(sp) ;height
    move.l #LOSESCREEN_WIDTH, -(sp) ;width
    
    jsr FastRenderBackground2 ;since there is no transparency here we can optimize by calling an overloaded function
    add.l #16, sp
    movem.l (sp)+,.REGS 
    rts
*input : a1 : loadedWin
DrawWinScreen
.REGS REG d1-d2/a1
    movem.l .REGS, -(sp)
    ;lea LoadedBackground, a1
    move.l #0, -(sp) ;y
    move.l #0, -(sp) ;x
    move.l #WINSCREEN_HEIGHT, -(sp) ;height
    move.l #WINSCREEN_WIDTH, -(sp) ;width
    
    jsr FastRenderBackground2 ;since there is no transparency here we can optimize by calling an overloaded function
    add.l #16, sp
    movem.l (sp)+,.REGS 
    rts

*input : a1 : loadedRecordsLeft, d6 : x, d7 : y  
DrawRecordsLeftScreen
.REGS REG d6-d7/a1
    movem.l .REGS, -(sp)
    move.l d7, -(sp) ;y
    move.l d6, -(sp) ;x
    move.l #RECORDSLEFT_HEIGHT, -(sp) ;height
    move.l #RECORDSLEFT_WIDTH, -(sp) ;width
    
    jsr FastRender
    add.l #16, sp
    movem.l (sp)+,.REGS 
    rts
*input : a1 : loadedTimer, d6 : x, d7 : y  
DrawTimerScreen
.REGS REG d6-d7/a1
    movem.l .REGS, -(sp)
    move.l d7, -(sp) ;y
    move.l d6, -(sp) ;x
    move.l #TIMER_HEIGHT, -(sp) ;height
    move.l #TIMER_WIDTH, -(sp) ;width
    
    jsr FastRender
    add.l #16, sp
    movem.l (sp)+,.REGS 
    rts



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
