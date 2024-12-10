*COLLISION
*input : a2 : vinyl object, a4 : character class, a3 : Collision class
*output d0 :0 for success and 1 if no collision    
IsColliding:
.REGS REG d0-d7/a1-a4
    movem.l .REGS, -(sp)
.field_collider equ 0
    move.w (VINYL_FIELD_OFFS_XPOS,a2),d1 ; Left x
    move.w (VINYL_FIELD_OFFS_YPOS,a2),d2 ; Top y
    move.w d1, d3
    move.w d2, d4
    add.w #VINYL_WIDTH,d3 ; Right x
    add.w #VINYL_HEIGHT,d4 ; Bottom y
    
    move.w (CHAR_FIELD_OFFS_X,a4),d5 ; character left x
    move.w (CHAR_FIELD_OFFS_Y,a4),d6 ; character top y
    move.w d5,d7
    add.w #CHAR_WIDTH,d7 ; character right x
    
    cmp.w d4, d6 ; vinyl lower y < char upper y
    bgt .skip
    
    add.w #CHAR_HEIGHT,d6 *character bottom y
    cmp.w d6, d2
    bgt .skip
    
    cmp.w d3,d5 ;vinyl right x <c char left x
    bgt .skip
    
    cmp.w d7,d1 ; char right x < vinyl left x 
    bgt .skip
    
.true
    moveq #0, d0
    move.l a2, (.field_collider,a3)
    bra .done
.skip
    moveq #1,d0
.done
    movem.l (sp)+,.REGS
    rts 
    
*COLLISION
*This function runs every frame to detect collision and performs actions that are meant to happen afterwards
*input : a4: COllision class, a1 : 7 seg symbol table. a2 : 7 seg functions, a3 : 7 seg counter, a6 current sound reference
OnCollision:
.REGS REG d1/d5/a1-a5
.left_offs equ 480
.right_offs equ 540
    movem.l .REGS, -(sp)
    
    tst.l (a4)
    beq .noCollision
    *yes collision
    *make vinyl out of screen

    move.l (a4),a5 ; a2 contains address of the Vinyl Object
    bsr DeactivateVinyl
   
    move.l #0,(a4) ; so that the same collision is not read again and again
 
    *get type of vunyl object and do subsequent things
    *sound play/stop
    move.b (VINYL_FIELD_OFFS_Type,a5),d1
    tst.b d1 * brokenType = 0
    beq .stopSound
    bsr PlaySound
    bra .seven_segment
.stopSound    
    bsr StopSound

    *7 segment
.seven_segment    
    move.b (VINYL_FIELD_OFFS_Type,a5),d1 ; get type of vinyl object
   
    move.l #(.right_offs<<16 | .left_offs),d5
    bsr Update7Segment
    move.b (a3),d1
    tst.b d1
    bne .done
    lea GameStatus, a1 *bad code because this expects the calling code to have this label
    move.b #GAME_STATUS_STOPPING, (a1)
    
.noCollision 
.done
    movem.l (sp)+,.REGS
    rts



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
