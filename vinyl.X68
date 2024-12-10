VINYL_FIELD_OFFS_XPos      equ 0
VINYL_FIELD_OFFS_YPos      equ 2
VINYL_FIELD_OFFS_Time      equ 4
VINYL_FIELD_OFFS_Velocity  equ 8
VINYL_FIELD_OFFS_Type      equ 14
VINYL_FIELD_OFFS_Screen    equ 15
SIZE_OF_VINYL equ 16

VINYL_WIDTH equ 20
VINYL_HEIGHT equ 20
VINYL_COUNT equ 4

BrokenType equ 0
GenuineType equ 1
INIT_VELOCITY equ 4
GravityConstant equ $80 *8.8 format
MaxSpeed equ 40<<8
FractionalBits equ 8


*BITMAP
*This function goes over all the vinyl object and draws them, after checking if they are on the screen
*input : a1 : Vinyl objects array, a2 : loaded vinyl, a3 : broken vinyl
FastDrawVinyls
.field_x equ 0
.field_y equ 2
.field_type equ 14
.object_size equ 16
.REGS REG d1-d3/d5-d7/a1-a3
    movem.l .REGS, -(sp)
    
    * int i = d1
    moveq #(VINYL_COUNT-1), d1
    moveq #0, d2
    ;lea VinylPositions, a1
.loop
    move.b d1, d2
    lsl.w #4,d2 ; 16*i to get to the object 
    move.b (VINYL_FIELD_OFFS_Screen,a1,d2),d3
    tst.b d3
    beq .skip
    move.w (.field_y,a1,d2),d7 ; y
    move.w (.field_x,a1,d2),d6 ; x
    move.b (.field_type,a1,d2),d5 ; type of vinyl - broken or genuine 
    bsr DrawVinyl
.skip
    dbf d1, .loop
    *break
    movem.l (sp)+,.REGS
    rts   
    
*input : d7 : screen offset on y, d6 : screen offset on x, d5 : vinyl type
* a2 : Vinyl, a3 : broken vinyl
DrawVinyl:
.stackSize equ 9
    move.l a1, -(sp)
    move.l a2, -(sp)
    move.w d6, -(sp)
    move.w d7, -(sp) 
    move.b d5, -(sp)
 
    tst.b d5
    beq.b .broken * broken == 0 and genuine == 1
    ;lea LoadedVinyl, a1
    move.l a2,a1
    bra.b .render
.broken
    move.l a3,a1 ; putting loadedbrokenvinyl in a1
.render
    move.l d7, -(sp) ;y
    move.l d6, -(sp) ;x
    move.l #VINYL_HEIGHT, -(sp) ;height
    move.l #VINYL_WIDTH, -(sp) ;width
    
    jsr FastRender
    add.l #16, sp
    move.b (sp)+,d5
    move.w (sp)+,d7 
    move.w (sp)+,d6
    move.l (sp)+,a2
    move.l (sp)+,a1
    rts
	
*This function clears all the vinyl objects on screen and redraws background
*input : a1 : list of vinyl objects, a2 : loadedBackground
ClearVinyls2:
.field_x equ 0
.field_y equ 2
.object_size equ 16
.REGS REG d1-d2/d5-d7/a1-a2
    movem.l .REGS, -(sp)
    
    moveq #(VINYL_COUNT-1), d1
    moveq #0, d2 *ensuring that d2 doesnt have garbage
    ;lea VinylPositions, a1
.loop * d1 -> [5 to 0]
    move.b d1, d2 ; d2 should not have any garbage
    lsl.w #4,d2 ; 16*i to get to the object
    move.b (VINYL_FIELD_OFFS_Screen,a1,d2),d5
    tst.b d5
    beq.b .skip 
    move.w (.field_y,a1,d2),d7 ; y
    move.w (.field_x,a1,d2),d6 ; x
    bsr ClearVinyl
.skip
    dbf d1, .loop
    *break
    movem.l (sp)+,.REGS
    rts	
    
*input : d7 : screen offset on y, d6 : screen offset on x
* a2 : loadedBackground
ClearVinyl:
    move.l a1, -(sp)
    move.l d6, -(sp)
    move.l d7, -(sp)
    
    ;lea LoadedBackground, a1
    move.l a2,a1
    move.l d7, -(sp) ;y
    move.l d6, -(sp) ;x
    move.l #VINYL_HEIGHT, -(sp) ;height
    move.l #VINYL_WIDTH, -(sp) ;width
    jsr FastRenderCutout2
    add.l #16, sp
    move.l (sp)+,d7
    move.l (sp)+,d6
    move.l (sp)+,a1
    rts
*Physics - Gravity simulation
*This function updates all vinyls
*input : a1 : Vinyl objects, a3 : collision class, a4 :  character class   
FinalUpdateVinyls:
.field_x equ 0
.field_y equ 2
.field_time equ 4
.field_velo equ 8
.object_size equ 16
.offscrn_time equ 500
.REGS    REG d0-d7/a1-a5
;save d2, a1,d6,d7,d3,d0,d1
* 6 vinyls
* int i = d2
    movem.l .REGS, -(sp)
    ;lea VinylPositions, a1
    moveq #(VINYL_COUNT-1), d2
    moveq #0,d3
.loop
    *get y
    move.b d2, d3 
    lsl.w #4, d3 ; d3 *16 ; d3 now points to the object
    move.w (.field_y,a1,d3),d7 ; d7 = y
    move.w (.field_velo,a1,d3),d6 ; d6 = speed in fixed point
    bsr UpdateVinyl
    move.w d7, (.field_y,a1,d3) ;update y in the object
    move.w d6, (.field_velo,a1,d3) ; update velocity in object
    tst.b d0
    beq .nextVinyl
    cmp.b #1,d0
    beq .setTime
    *check time
.checkTime
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15 ; d1 has current time
    sub.l (.field_time,a1,d3),d1 ; current time - saved time
    cmp.l #.offscrn_time, d1
    ble .nextVinyl
    bsr InitVinyl
    bra .nextVinyl
    
.setTime
    move.l a1,a5
    add.l d3,a5
    bsr DeactivateVinyl
    bra .nextVinyl

.nextVinyl
    move.l a1, a2 *todo : move into a different place
    add.l d3, a2
    bsr IsColliding
    dbf d2, .loop
.break 
    movem.l (sp)+,.REGS   
    rts

*input : a5 : address of the vinyl   
DeactivateVinyl:
    move.l a5, -(sp)
    move.l d0, -(sp)
    move.l d1, -(sp)
.offLimit equ (BACKGROUND_HEIGHT-VINYL_HEIGHT+1)

    move.w #.offLimit,(VINYL_FIELD_OFFS_YPos,a5) ; setting y to an off limit position
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15
    move.l d1, (VINYL_FIELD_OFFS_TIME,a5)   
    move.b #OffScreen, (VINYL_FIELD_OFFS_Screen,a5)
    
    move.l (sp)+,d1
    move.l (sp)+,d0
    move.l (sp)+,a5
    rts
* Moving Vinyl record down the screen from multiple x coordinates
*Physics
* x = 0, 50, 100
*input d6 = speed, d7 = position of vinyl. Make sure to send them as long words
*output d0: 0: success, 1: vinyl gone out of screen, 2 : vinyl already out of bounds
* to do : take delta time into account using v = u + a*t
UpdateVinyl:
    cmpi.w #(BACKGROUND_HEIGHT-VINYL_HEIGHT),d7
    bgt .invalid
    cmp.w #MaxSpeed, d6
    bgt .max
    
    add.l #GravityConstant, d6
    lsl.l #8, d7 ; to fixed point with 8 frac bits, whole number can be greater than 8 bits
    add.l d6, d7
  
    lsr.l #8, d7 ; fixed point to whole number
    cmpi.w #(BACKGROUND_HEIGHT-VINYL_HEIGHT),d7
    ble .valid
    move.b #1, d0
    bra .done

.invalid
    moveq #2, d0
    move.w #0,d6 ; 0 velocity if vinyl is beyond the screen
    bra .done

.max
.valid
    move.b #0, d0 ; the vinyl is on screen
    bra .done

.done
    
    *return d6 in fixed point
    rts
*RANDOM  
*input : a1 :VinylPositions, d3 : pointer to object
InitVinyl
.REGS REG d1-d3/d6/a1
    movem.l .REGS, -(sp)
.random equ 127
    move.w #0, (VINYL_FIELD_OFFS_YPos,a1,d3) ; set y to 0
    move.w #INIT_VELOCITY,(VINYL_FIELD_OFFS_VELOCITY,a1,d3) ; set velocity to initial velocity
    move.b #OnScreen, (VINYL_FIELD_OFFS_Screen,a1,d3)
    bsr getRandomByteIntoD6
    cmp.w #.random, d6
    bgt .setBroken
.setGenuine
    move.b #GenuineType,(VINYL_FIELD_OFFS_Type,a1,d3)
    movem.l (sp)+, .REGS
    rts
.setBroken
    move.b #BrokenType, (VINYL_FIELD_OFFS_Type,a1,d3)
    movem.l (sp)+, .REGS
    rts
    




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
