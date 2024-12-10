CHAR_HEIGHT equ 60
CHAR_WIDTH equ 30

CHAR_FIELD_OFFS_Y equ 0
CHAR_FIELD_OFFS_X equ 2

CharacterSpeed equ 5

KEY_RIGHT_INPUT equ $27
KEY_LEFT_INPUT  equ $25
GET_USER_INPUT_COMMAND  equ 19
*BITMAP    
*This prints the character on the screen
*input : a1 : character bmp, a2 : character class
DrawCharacter:
.REGS REG d6-d7/a1-a2
    movem.l .REGS, -(sp)

    ;lea Character, a2
    move.w (CHAR_FIELD_OFFS_Y,a2),d6
    move.w (CHAR_FIELD_OFFS_X,a2),d7
    
    move.l d6, -(sp) ;y
    move.l d7, -(sp) ;x
    move.l #CHAR_HEIGHT, -(sp) ;height
    move.l #CHAR_WIDTH, -(sp) ;width
    
    jsr FastRender
    add.l #16, sp
    
    movem.l (sp)+, .REGS
    rts

*clears the character image and redraws background
*input : a1 : character class, a2 : loaded background 
ClearCharacter:
.REGS REG d6-d7/a1-a2
    movem.l .REGS,-(sp)

    move.w (CHAR_FIELD_OFFS_X,a1),d6
    move.w (CHAR_FIELD_OFFS_Y,a1),d7
    
    move.l a2, a1 * putting loaded background in a1
    move.l d7, -(sp) ;y
    move.l d6, -(sp) ;x
    move.l #CHAR_HEIGHT, -(sp) ;height
    move.l #CHAR_WIDTH, -(sp) ;width
    jsr FastRenderCutout2
    add.l #16, sp
    
    movem.l (sp)+,.REGS
    rts   
*INPUT
*Character control
*Output : d0 : 0 if there was a user input else 1
*input : a1 : character class
UpdateCharacter
.REGS REG d1-d2/d7/a1
    movem.l .REGS, -(sp)
 
    moveq #0, d0
    move.w (CHAR_FIELD_OFFS_X,a1),d7
    move.l #(KEY_LEFT_INPUT<<8 + KEY_RIGHT_INPUT),d1 ;read input for left and right arrow
    move.b #GET_USER_INPUT_COMMAND, d0
    trap #15
    move.l  d1, d2
    andi.l  #$0000FF00,d2
    bne .keyLeftInput
    move.l  d1, d2
    andi.l  #$000000FF,d2
    bne     .keyRightInput
    moveq #1, d0 * no user input    
    bra     .doneInput 
  
.keyRightInput:
    ;d7 is position of character
    addi.w #CharacterSpeed, d7
    cmpi.w #(BACKGROUND_WIDTH-CHAR_WIDTH),d7
    ble .valid ; if valid then exit function
    bra .doneInput

.keyLeftInput
    subi.w #CharacterSpeed, d7
    cmpi.w #0, d7
    bge .valid
    moveq #0, d7
    
.valid
    moveq #0, d0
    move.w d7,(CHAR_FIELD_OFFS_X,a1)
    bra .doneInput
    
.doneInput
    
    movem.l (sp)+,.REGS
    rts







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
