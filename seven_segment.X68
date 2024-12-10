*-----------------------------------------------------------
* Title      : Seven Segment Module
* Written by : Shaurya
* Date       : 
* Description: 
*-----------------------------------------------------------


*7SEG   
SEVEN_SEG_OFFS_X equ 0 * pass the offset to the function in d5 : 800 and 860
SEVEN_SEG_DISP_1_LEFT equ 800 
SEVEN_SEG_DISP_1_RIGHT equ 900 *this assumes the length of the seg stays 40. Modify this if you change the length

SEVEN_SEG_MAX_VALUE equ 99

SEVEN_SEG_OFFS_Y equ 600
SEVEN_SEG_WIDTH equ 10
SEVEN_SEG_LENGTH equ 40

* d1 = 0 if you want to add to counter and 1 if you want to decrement
*input : d1 = 0 for broken and 1 for genuine, a1 :Seven segment Symbol table, a2 : Seven segment functions, a3 : SevenSegmentCounter, d5.w (upper word) : right offset on x, (lower word) : left offset
Update7Segment
.REGS REG d1/d5/a1-a3
    movem.l .REGS, -(sp)
.maxValue equ 5
    tst.b d1 ;if broken
    beq .broken
.genuine
    moveq #0,d1 ; very important since if there is garabage it causes trouble when trying (a1,d1)
    move.b (a3),d1
    tst.b d1
    beq .done
    sub.b #1,d1
    move.b d1, (a3) ; updating value in the memory
    divu #10, d1 ;lower word contains quotient which goes in first segment
    bsr Draw7Segment
    lsr.l #8, d1
    lsr.l #8, d1 ;to get the remainder which is in the upper word
    lsr.l #8, d5 
    lsr.l #8, d5 ; to get the right offset
    bsr Draw7Segment
    bra .done
.broken
*    cmp.b #SEVEN_SEG_MAX_VALUE,(a3)
*    beq .done
*    add.b #1,(a3)
*    moveq #0,d1
*    move.b (a3),d1
*    divu #10, d1 ;lower word contains quotient which goes in first segment
*    bsr Draw7Segment
*    lsr.l #8, d1
*    lsr.l #8, d1 ;to get the remainder which is in the upper word
*    lsr.l #8, d5 
*    lsr.l #8, d5 ; to get the right offset
*    bsr Draw7Segment
.done
    movem.l (sp)+,.REGS
    rts
    
*input : d1.b : value, a1 :Seven segment Symbol table, a2 : Seven segment functions, d5.w : offset on x
* output : d0 : 0 for success else 1
Draw7Segment:
.REGS REG d1-d2/d5/d7/a1-a2
    movem.l .REGS, -(sp)
    bsr ClearSingleSevenSegment
    moveq #6, d7 ; loop counter init
    move.b (a1,d1),d2 ; d2 holds the hex value of the bits of the 7 segment
.loop
    lsr.b #1,d2
    bcc .skip
    bsr DrawSegment
.skip
    dbf d7, .loop ; subtract and if greater than -1 go back to loop
    movem.l (sp)+, .REGS
    rts

*input : which segment. D7 : segment number, a2: Seven segment functions, d5 : x offset
*output : d0 : 0 for success else 1
DrawSegment:
    move.l a2,-(sp)
    move.l d7, -(sp)
    move.l d5, -(sp)
    ;lea SevenSegmentFunctions, a1
    asl.b #2,d7
    add.l d7,a2
    move.l (a2),a2
    jsr (a2)
    moveq #0, d0
    move.l (sp)+,d5
    move.l (sp)+,d7
    move.l (sp)+,a2
    rts

*input : d5 : seven seg offset    
DrawASegment
.REGS REG d0-d5
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    move.w #(0+SEVEN_SEG_OFFS_X),d1 ;Left X
    add.w d5,d1
    move.w #(0+SEVEN_SEG_OFFS_Y),d2 ; top Y
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X),d3 ; Right X
    add.w d5,d3
    move.w #(SEVEN_SEG_WIDTH+SEVEN_SEG_OFFS_Y),d4 ; bottom Y
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts    
*input d5 ; offset on x
DrawBSegment
.REGS REG d0-d5  
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X-SEVEN_SEG_WIDTH),d1 ; Left X
    move.w #(0+SEVEN_SEG_OFFS_Y),d2 ; top Y
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X),d3 ; Right X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+SEVEN_SEG_WIDTH),d4 ; bottom Y
    add.w d5,d1
    add.w d5,d3
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts  

DrawGSegment
.REGS REG d0-d5   
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    move.w #(0+SEVEN_SEG_OFFS_X),d1 ;Left X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+SEVEN_SEG_WIDTH),d2 ; top Y
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X),d3 ; Right X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d4 ; bottom Y
    add.w d5,d1
    add.w d5,d3
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts

DrawCSegment
.REGS REG d0-d5  
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X-SEVEN_SEG_WIDTH),d1 ; Left X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d2 ; Top Y
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X),d3 ; Right X
    ;move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d4 ; Bottom Y
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+3*SEVEN_SEG_WIDTH),d4 ;bottom Y
    add.w d5,d1
    add.w d5,d3    
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts

DrawDSegment
.REGS REG d0-d5   
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    move.w #(0+SEVEN_SEG_OFFS_X),d1 ;Left X
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d2 ; top Y
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_X),d3 ; Right X
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+3*SEVEN_SEG_WIDTH),d4 ;bottom Y
    add.w d5,d1
    add.w d5,d3
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts

DrawESegment
.REGS REG d0-d5
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    move.w #(0+SEVEN_SEG_OFFS_X),d1 ;Left X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d2 ; Top Y
    move.w #(0+SEVEN_SEG_OFFS_X+SEVEN_SEG_WIDTH),d3 ;Right X
    ;move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+2*SEVEN_SEG_WIDTH),d4 ; bottom Y
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+3*SEVEN_SEG_WIDTH),d4 ;bottom Y
    add.w d5,d1
    add.w d5,d3
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts
    
DrawFSegment
.REGS REG d0-d5
    movem.l .REGS, -(sp)
    move.l #$FF, d1 ;setting pen colour to red
    moveq #80, d0
    trap #15
    move.l #$FF, d1 ;setting fill colour to red
    moveq #81, d0
    trap #15
    move.w #(0+SEVEN_SEG_OFFS_X),d1 ;Left X
    ;move.w #(SEVEN_SEG_WIDTH+SEVEN_SEG_OFFS_Y),d2 ;top Y
    move.w #(0+SEVEN_SEG_OFFS_Y),d2 ; top Y
    move.w #(0+SEVEN_SEG_OFFS_X+SEVEN_SEG_WIDTH),d3 ;Right X
    move.w #(SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+SEVEN_SEG_WIDTH),d4 ; Bottom Y
    add.w d5,d1
    add.w d5,d3
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts
*input : a1 : Seven segment functions
InitSevenSegmentFunctions
    move.l a1, -(sp)
    ;lea SevenSegmentFunctions, a1
    move.l #DrawASegment, (a1)
    move.l #DrawBSegment, (4,a1)
    move.l #DrawCSegment, (8,a1)
    move.l #DrawDSegment, (12,a1)
    move.l #DrawESegment, (16,a1)
    move.l #DrawFSegment, (20,a1)
    move.l #DrawGSegment, (24,a1)
    move.l (sp)+,a1
    rts  

    
ClearSevenSegmentDisplay
.REGS REG d0-d4
.offs equ 10
    movem.l .REGS, -(sp)
    moveq #0, d1 ; pen colour to black
    moveq #80, d0
    trap #15
    moveq #0, d1 ;setting fill colour to black
    moveq #81, d0
    trap #15
    move.w #(SEVEN_SEG_DISP_1_LEFT),d1 ;Left X
    move.w #(0+SEVEN_SEG_OFFS_Y-.offs),d2 ; top Y
    move.w #(SEVEN_SEG_DISP_1_RIGHT),d3 ; Right X    
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+3*SEVEN_SEG_WIDTH+.offs),d4 ;bottom Y
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts

ClearSingleSevenSegment
.REGS REG d0-d5
.offs equ 10
    movem.l .REGS, -(sp)
    moveq #0, d1 ; pen colour to black
    moveq #80, d0
    trap #15
    moveq #0, d1 ;setting fill colour to black
    moveq #81, d0
    trap #15
    moveq #0,d1 ;Left X
    add.w d5,d1
    move.w #(0+SEVEN_SEG_OFFS_Y-.offs),d2 ; top Y
    moveq #(SEVEN_SEG_LENGTH),d3 ; Right X   
    add.w d5,d3 
    move.w #(2*SEVEN_SEG_LENGTH+SEVEN_SEG_OFFS_Y+3*SEVEN_SEG_WIDTH+.offs),d4 ;bottom Y
    moveq #87, d0
    trap #15
    movem.l (sp)+,.REGS
    rts





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
