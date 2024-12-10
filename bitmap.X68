*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

BMP_LONG_SIZE EQU 4
BMP_SENTINEL EQU $DEADDEAD
BMP_TASK_OUTPUTSTR_CRLF EQU 13

*Input a1 : file
*Output d0 : 0 for success
*Set global Width variable    
    move.w #0, d0

GetWidth
.WidthOfs EQU $12
.Size   EQU 4
.REGS REG a1/d1/a2
    
    movem.l .REGS, -(sp)
    add.l #.WidthOfs, a1
    move.l #.Size, d1
    bsr ConvertToBigEndian
    tst.b d0
    bne .error
    lea Width, a2
    move.l (a1),(a2)
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+,.REGS 
    rts
  
*Input a1 : file
*Output d0 : for success
*Set Global Height Variable
GetHeight
.HeightOfs  EQU $16
.Size   EQU 4
.REGS   REG a1/d1/a2
    movem.l .REGS, -(sp)
    add.l #.HeightOfs, a1
    move.l #.Size, d1
    bsr ConvertToBigEndian
    tst.b d0
    bne .error
    lea Height, a2
    move.l (a1),(a2)
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+,.REGS
    rts

*Input : a1 : file
*Output : d0 : 0 for success
*Set global PixelSize Variable
GetPixelSize
.PixSizeOfs   EQU $1C
.Size   EQU 2
.REGS   REG a1/d1/a2
    movem.l .REGS, -(sp)    
    add.l #.PixSizeOfs, a1
    move.l #.Size, d1
    bsr ConvertToBigEndian
    tst.b d0
    bne .error
    move.w (a1),d1
    asr.w #3,d1 ; converting bits to bytes
    lea PixelSize, a2
    move.w d1,(a2)
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+,.REGS    
    rts


GetPixArrSize
.ArrSizeOfs EQU $22
.Size   EQU 4
.REGS   REG a1/d1/a2
    movem.l .REGS, -(sp)    
    add.l #.ArrSizeOfs, a1
    move.l #.Size, d1
    bsr ConvertToBigEndian
    tst.b d0
    bne .error
    lea ArraySize, a2
    move.l (a1),(a2)
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+,.REGS    
    rts

*Input a1 : inputFile
*Output d0: 0 for success
*Put PixelArray addr in stack 
GetPixelArray
.PixArrOfs  EQU $A
.Size   EQU 4
.REGS REG   a1/a2/d1

    movem.l .REGS, -(sp)
    move.l a1, a2 ;temp saving
    add.l #.PixArrOfs, a1
    move.l #.Size, d1
    bsr ConvertToBigEndian ;This should make the data big endian in-place
    tst.b d0
    bne .error
    move.l (a1),16(sp)
    move.b #0, d0
    bra .done
.error
    move.b #1, d0
.done
    movem.l (sp)+,.REGS 
    rts

*input a1 : inputFile
*output d0 : 0 for success and non zero for failure    
CheckSignature
.SIGN   EQU $424D
    cmp.w #.SIGN,(a1)
    bne .fail
    move.w #0, d0
    bra .done   
.fail
    move.b #1, d0
.done 
   rts  
*Input : a1 : file address, a2 : memory start
Bmp_Load:
.REGS REG d2-d7/a0-a1/a3-a6
    movem.l .REGS, -(sp)
    ;lea ImageData, a2
    move.l #$500000, d1
    bsr file_read
    tst.b d0
    bne .error
    move.l a2, a1
    bsr CheckSignature
    tst.b d0
    bne .error
    *The following getters are setting the value in the global variables
    bsr GetWidth
    tst.b d0
    bne .error
    
    bsr GetHeight
    tst.b d0
    bne .error
    
    bsr GetPixelSize
    tst.b d0
    bne .error
    
    bsr GetPixArrSize
    tst.b d0
    bne .error
    bra .done
    
.error
    move.l #1, d0
.done
    movem.l (sp)+, .REGS
    rts

*Intention : Reads points from the stack and location of image from a1 register and draws the image on the screen
*Input: a1 : file, a2: pixel array
*Output : d0 = 0 for success, non zero for failure    
Bmp_Draw:
.St_One EQU 32
.St_Two EQU (8+28)
.St_Three EQU (12+28)
.St_Four EQU (16+28)
.St_Five EQU (20+28)
.St_Six EQU (24+28)
.St_Seven EQU (28+28)
.St_Eight EQU (32+28)
.REGS REG d1-d5/a1-a2
    movem.l .REGS, -(sp)
    move.l (.St_One,sp),d1 ;x
    move.l (.St_One,sp),d3 ;x
    move.l (.St_Two,sp),d2 ;y
    move.l (.St_Two,sp),d4 ;y
    add.l (.St_Three,sp),d3 ;x+x_len
    add.l (.St_Four,sp),d4 ;y+y_len
    
.outer_loop
    cmp.l d2, d4
    blt .break_outer
    move.l (.St_One,sp),d1 ;resetting
.inner_loop
    cmp.l d1, d3
    blt .break_inner
    move.l d3, d5 ;temp
    move.l (.St_Seven,sp),d3 ; padding
    *d1,d2 = x & y in pixels, d3=padding
    sub.l #BMP_LONG_SIZE, sp
    bsr GetByteOffset
    move.l (sp)+,d3
    *d3 = byte offset
    *d1 = x, d2 = y, d3 = byte offset value, a1 = pixel array
    move.l a1, a3 ; temp
    move.l a2, a1
    *calculating drawing point for Render
    sub.l #BMP_LONG_SIZE, sp
    sub.l #BMP_LONG_SIZE, sp
    move.l d1, (sp)
    move.l d2, (4,sp)
    
    sub.l (.St_Three,sp),d1 ; x-starting_x
    add.l (.St_Seven,sp),d1 ; actual screen coordinate
    
    sub.l (.St_Four,sp),d2 ;y-starting_y
    add.l (.St_Eight,sp),d2 ;actual screen coordinate
    
    bsr Render
    
    move.l (sp),d1
    move.l (BMP_LONG_SIZE,sp),d2
    add.l #BMP_LONG_SIZE,sp
    add.l #BMP_LONG_SIZE,sp
    
    move.l d5, d3 ;restoring d3 to x+x_len
    add.l #1, d1
    bra .inner_loop
.break_inner    
    add.l #1, d2
    bra .outer_loop
.break_outer
    movem.l (sp)+, .REGS
    rts

*Intention : Given pixel coordinates and byte data representing R G B, print on screen
*Input : d1 : x, d2 : y, d3 : byte offset, a1 : pixel array
Render:
.REGS  REG d1-d3/a1-a2

    movem.l .REGS, -(sp)
    sub.l #8, sp
    move.l d1, (sp)
    move.l d2, (4,sp)
    add.l d3,a1 ; adding the offset to the array
    lea PixelSize, a2
    cmp.w #3, (a2)
    beq .parse_24
    cmp.w #4, (a2)
    beq .parse_32
.parse_32
    clr.l d1
    ;add.l #1, a1
.parse_24
    clr.l d1
    move.b (a1)+,d1
    lsl.l #8,d1 ;left shift one byte
    move.b (a1)+,d1
    lsl.l #8,d1
    move.b (a1)+,d1
    move.l #80, d0
    trap #15
    ;Print pixels on screen
    move.l (sp),d1
    move.l (4,sp),d2
    move.l #82, d0
    trap #15
        
    add.l #8, sp
    movem.l (sp)+, .REGS
    rts
    
*Intention: Given memory location of pixel data and width and height and screen coordinates of top left, render the image
*Input : sp-4 : width, sp-8 : height, sp-12: x_ofs, sp-16: y_ofs a1 : loadedData,     
FastRender2:
    movem.l d1-d7/a1, -(sp) ;32
    
    move.l (36,sp),d4
    move.l (40,sp),d5
    move.l (44,sp),d6
    move.l (48,sp),d7
    clr.l d2 ;y ;remove
    moveq #0, d2
.outer_loop:
    cmp.w d2,d5 ;is this better?
    blt .break_outer
    moveq #0, d3
    add.w d7, d2 ; y
.inner_loop:
    ;cmp.l d3,d4
    cmp.w d3,d4
    blt .break_inner
    move.l (a1)+, d1 ;bgra
    lsr.l #8,d1 ;0bgr
    bcs .skip_pixel
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    add.w d6, d1
    *d2 = y
    moveq #82, d0 ;put pixel on screen
    trap #15
    ;sub.w d7, d2
.skip_pixel
    add.w #1, d3
    bra .inner_loop
.break_inner
    sub.w d7, d2
    add.w #1, d2
    bra .outer_loop
.break_outer
    movem.l (sp)+, d1-d7/a1
    rts
    *todo - optimize by using dbff
  
FastRenderBackground2:
    movem.l d1-d7/a1-a2, -(sp)
.width equ 40
.height equ 44
.scr_x equ 48   
.scr_y equ 52
    move.l (.width,sp),d4 ;width
    move.l (.height,sp),d5 ;height
    move.l (.scr_x,sp),d6 ; x screen offset
    move.l (.scr_y,sp),d2 ; y screen offset
    
    sub.w #1,d4 ;new inst
    sub.w #1,d5 ;new inst    
    move.w d4, a2 ; out of registers so storing in a2
    
.outer:
    
    move.w d6, d3 ; screen offset x
    move.w a2, d4 ; width-1
.inner:

    move.l (a1)+, d1 ;0bgr
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    moveq #82, d0 ;put pixel on screen
    trap #15

    addi.w #1, d3
    dbf d4, .inner
    *break inner
    addi.w #1,d2
    dbf d5, .outer
    *break outer
    movem.l (sp)+, d1-d7/a1-a2
    
    rts  
    
FastRenderBackground:
     movem.l d0-d7/a1, -(sp) ;36
.offs_width equ 40
.offs_height equ 44
.offs_scr_x equ 48   
.offs_scr_y equ 52
    move.l (.offs_width,sp),d4 ;width
    move.l (.offs_height,sp),d5 ;height
    move.l (.offs_scr_x,sp),d6 ; x screen offset
    move.l (.offs_scr_y,sp),d7 ; y screen offset
    
    add.w d6,d4 ; width + screen x ofs
    add.w d7,d5 ; height + screen y ofs
    move.w d7, d2 ; start from screen ofs instead of 0
.outer_loop:
    cmp.w d2,d5 ;is this better?
    ble .break_outer
    
    move.w d6, d3 ; d3 has the starting coordinate in x which is the offset +0
.inner_loop:
    ;cmp.l d3,d4
    cmp.w d3,d4 ; new commented
    ble .break_inner ;new - commented
    move.l (a1)+, d1 ;0bgr
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    *d2 = y
    moveq #82, d0 ;put pixel on screen
    trap #15
    add.w #1, d3
    bra .inner_loop
.break_inner
    add.w #1, d2
    bra .outer_loop
.break_outer
    movem.l (sp)+, d1-d7/a1

    rts
*BITMAP    
*Intention: Given memory location of pixel data and width and height and screen coordinates of top left, starting x and starting y,  render the image
*This function does not need to concern with alphas so optimize that
*optimize by going reverse using dbf
*For background load data in 0bgr format and remove condition checking for carry
*Input : sp-4 : width, sp-8 : height, sp-12: x_ofs, sp-16: y_ofs, sp-20: x_init, sp-24 : y_init, a1 : loadedData,

FastRenderCutout:
    movem.l d0-d7/a1, -(sp) ;36
.offs_width equ 40
.offs_height equ 44
.offs_scr_x equ 48   
.offs_scr_y equ 52  
.img_width equ 580
.img_height equ 540 
    move.l (.offs_width,sp),d4 ;width
    move.l (.offs_height,sp),d5 ;height
    move.l (.offs_scr_x,sp),d6 ; x screen offset
    move.l (.offs_scr_y,sp),d7 ; y screen offset

.pix_size equ 4
    move.l d6, d3
    move.l d7, d2
    mulu.w #.pix_size,d2
    mulu.w #.img_width, d2 ; width * y pixel array offset
    mulu.w #.pix_size,d3
    add.l d3, d2 ; (4 * x pix array offset) +  (width * y pixel array offset * 4)
    add.l d2, a1 ;new a1  
    
    add.w d6,d4 ; width + screen x ofs
    add.w d7,d5 ; height + screen y ofs
    move.w d7, d2 ; start from screen ofs instead of 0
.outer_loop:
    cmp.w d2,d5 ;is this better?
    ble .break_outer
    move.w d6,d3
.inner_loop:
    cmp.w d3,d4
    ble .break_inner
    move.l (a1)+, d1 ;0bgr
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    *d2 = y
    moveq #82, d0 ;put pixel on screen
    trap #15
    add.w #1, d3
    bra .inner_loop
.break_inner
    add.w #1, d2
    move.w #.img_width, d1
    sub.w d4, d1 ; img width - cutout width
    add.w d6, d1 ; why do I need this?
    mulu.w #.pix_size, d1
    add.l d1, a1
    bra .outer_loop
.break_outer
    movem.l (sp)+, d1-d7/a1

    rts
*BITMAP
FastRenderCutout2:
    movem.l d0-d7/a1-a2, -(sp) ;40
.offs_width equ 44
.offs_height equ 48
.offs_scr_x equ 52  
.offs_scr_y equ 56  
.img_width equ 580
.img_height equ 540 
    move.l (.offs_width,sp),d4 ;width
    move.l (.offs_height,sp),d5 ;height
    move.l (.offs_scr_x,sp),d6 ; x screen offset
    move.l (.offs_scr_y,sp),d2 ; y screen offset
    
    sub.w #1,d4 ;new inst
    sub.w #1,d5 ;new inst    
    move.w d4, a2 ; out of registers so storing in a2
    move.w a2, a3
    add.l #1,a3

.pix_size equ 4
    move.l d6, d3
    mulu.w #.pix_size,d2
    mulu.w #.img_width, d2 ; width * y pixel array offset
    mulu.w #.pix_size,d3
    add.l d3, d2 ; (4 * x pix array offset) +  (width * y pixel array offset * 4)
    add.l d2, a1 ;new a1  
    
    move.l (.offs_scr_y,sp),d2 ; y screen offset
    
.outer_loop:
    move.w d6,d3
    move.w a2,d4
    
.inner_loop:
    move.l (a1)+, d1 ;0bgr
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    *d2 = y
    moveq #82, d0 ;put pixel on screen
    trap #15
    add.w #1, d3
    dbf d4, .inner_loop
    *break_inner
    
    *updating a1 to new row
    clr.l d1
    move.w #.img_width, d1
    sub.w a3, d1 ; img width - cutout width
    ;lsl.l #2,d1 ; mulu with .pix_size
    mulu.w #.pix_size, d1
    add.l d1, a1
    
    add.w #1, d2
    dbf d5, .outer_loop
    *break_outer
    movem.l (sp)+, d0-d7/a1-a2

    rts
*BITMAP
*Intention: Given memory location of pixel data and width and height and screen coordinates of top left, starting x and starting y,  render the image
*Input : sp-4 : width, sp-8 : height, sp-12: x_ofs, sp-16: y_ofs, sp-20: x_init, sp-24 : y_init, a1 : loadedData,     
FastRender:
    movem.l d0-d7/a1-a2, -(sp) ;40
.offs_width equ 44
.offs_height equ 48
.offs_scr_x equ 52 
.offs_scr_y equ 56
    move.l (.offs_width,sp),d4 ;width
    move.l (.offs_height,sp),d5 ;height
    move.l (.offs_scr_x,sp),d6 ; x screen offset
    move.l (.offs_scr_y,sp),d2 ; y screen offset
    
    sub.w #1,d4 ;new inst
    sub.w #1,d5 ;new inst    
    move.w d4, a2 ; out of registers so storing in a2
    
.outer_loop:
    ;cmp.l d2,d5 ; if y<height
      
    move.w d6, d3 ; screen offset x
    move.w a2, d4 ; width-1
    
.inner_loop:

    move.l (a1)+, d1 ;abgr
    btst #24,d1
    beq .skip_pixel
    bclr #24,d1
    moveq #80, d0 ; set paint colour
    trap #15
    
    move.w d3, d1 ;x
    moveq #82, d0 ;put pixel on screen
    trap #15
.skip_pixel
    add.w #1, d3
    dbf d4, .inner_loop
*break_inner
    add.w #1, d2
    dbf d5, .outer_loop
*break_inner
    movem.l (sp)+, d0-d7/a1-a2
    rts
*Intention : Reads points from the stack and location of image from a1 register and draws the image on the screen
*Input: a1 : pixel array, a2 : Memory address to load image in, d7.b : background 
*Output : d0 = 0 for success, non zero for failure
LoadBMPInMemory:
.St_One EQU (4+36)
.St_Two EQU (8+36)
.St_Three EQU (12+36)
.St_Four EQU (16+36)
.St_Five EQU (20+40)
.St_Six EQU (24+36)
.St_Seven EQU (28+36)
.St_Eight EQU (32+36)
.REGS REG d1-d7/a1-a2
    movem.l .REGS, -(sp)
    move.l (.St_One,sp),d1 ;x
    move.l (.St_One,sp),d3 ;x
    move.l (.St_Two,sp),d2 ;y
    move.l (.St_Two,sp),d4 ;y
    add.l (.St_Three,sp),d3 ;x+x_len
    add.l (.St_Four,sp),d4 ;y+y_len
    
.outer_loop
    cmp.l d2, d4
    ble .break_outer
    move.l (.St_One,sp),d1 ;resetting
.inner_loop
    cmp.l d1, d3
    ble .break_inner
    move.l d3, d5 ;temp
    move.l (.St_Seven,sp),d3 ; padding
    *d1,d2 = x & y in pixels, d3=padding
    sub.l #BMP_LONG_SIZE, sp
    bsr GetByteOffset
    move.l (sp)+,d3
    *d3 = byte offset
    *d1 = x, d2 = y, d3 = byte offset value, a1 = pixel array
        
    *calculating drawing point for Render
    sub.l #BMP_LONG_SIZE, sp
    sub.l #BMP_LONG_SIZE, sp
    move.l d1, (sp)
    move.l d2, (4,sp)
    
    sub.l (.St_Three,sp),d1 ; x-starting_x
    add.l (.St_Seven,sp),d1 ; actual screen coordinate
    
    sub.l (.St_Four,sp),d2 ;y-starting_y
    add.l (.St_Eight,sp),d2 ;actual screen coordinate
    
    bsr LoadPixelInMemory
    add.l #4, a2
    
    move.l (sp),d1
    move.l (BMP_LONG_SIZE,sp),d2
    add.l #BMP_LONG_SIZE,sp
    add.l #BMP_LONG_SIZE,sp
    
    move.l d5, d3 ;restoring d3 to x+x_len
    add.l #1, d1
    bra .inner_loop
.break_inner    
    add.l #1, d2
    bra .outer_loop
.break_outer

    ;add.l #16,sp
    movem.l (sp)+, .REGS
    rts

*Intention : Given pixel coordinates and byte data representing R G B, load pixel data in 0,B,G,R format
*Input : d1 : x, d2 : y, d3 : byte offset, a1 : pixel array, d7.b : bacgkround =1
*Input ; a2 : memory address
LoadPixelInMemory:
.REGS  REG d1-d3/a1-a2/d7

    movem.l .REGS, -(sp)
    sub.l #8, sp
    move.l d1, (sp)
    move.l d2, (4,sp)
    add.l d3,a1 ; adding the offset to the array

    clr.l d1
    ;add.l #1, a1
.parse_24
    clr.l d1
    move.b (a1)+,d1
    lsl.l #8,d1 ;left shift one byte
    move.b (a1)+,d1
    lsl.l #8,d1
    move.b (a1)+,d1
    lsl.l #8, d1 ;bgr0
    
    lea PixelSize, a3
    cmp.w #3, (a3)
    beq .parse_over
    cmp.w #4, (a3)
    beq .parse_32
.parse_32
    move.b (a1),d1 ;bgra
.parse_over    
    ;ror.l #8, d1   ;abgr ;no need to rotate
    tst.b d7 ; if 1 then background
    bne .background
    ror.l #8, d1 ; new format ABGR for non background
    andi.l #$01FFFFFF,d1
    bra .done
    
.background
    lsr.l #8, d1 ;0bgr
.done
    move.l d1,(a2) 
    add.l #8, sp
    movem.l (sp)+, .REGS
    rts
*Intention : adjust coordinates if they are beyond the dimensions of the image   
*Input d1, d2, d3, d4
*Out : d0: 0 if no clamping was needed. 1 if clamping was done
ClampPixelCoordinates
.REGS   REG d5/a1-a3
    movem.l .REGS, -(sp)
    lea Width, a2
    lea Height, a3
    tst.l d1
    blt .resetx
.preresetx
    tst.l d2
    blt .resety
    bra .check_x
.resetx
    move.l #0, d1
    bra .preresetx
.resety
    move.l #0, d2
.check_x    
    move.l d3, d5 ; d5 : x_len
    sub.l #1, d5
    add.l d1, d5
    cmp.l (a2),d5 
    bge .clampx
.check_y    
    move.l d4, d5 ; d5: y_len
    sub.l #1, d5
    add.l d2, d5
    cmp.l (a3),d5 
    bge .clampy
    move.b #0, d0
    bra .done
.clampx
    move.l (a2),d5 ; storing in temp
    sub.l d1, d5 
    sub.l #1, d5
    move.l d5, d3 ; resetting x_len to diff between width and x -1
    move.b #1, d0
    bra .check_y
.clampy
    move.l (a3),d5
    sub.l d2, d5
    sub.l #1, d5
    move.l d5, d4
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts
*Intention : Clamp screen coordinates to ensure they lie within the screen
*Out : Changes values in place in the registers d1 = x, d2 = y
ClampScreenPoints:
.REGS   REG d3-d4
    movem.l .REGS, -(sp)
    ;Get Screen coordinates and clamp
    sub.l #4, sp
    move.l d1,(sp) ;saving d1 in stack
    
    move.b #33, d0 ;Trap task to get screen coordinates
    clr.l d1    
    trap #15
    move.w d1, d4 ;Height of screen by getting lower word
    lsr.l #8, d1
    lsr.l #8, d1
    move.w d1, d3 ;Width of screen by getting upper word
    
    move.l (sp),d1
    add.l #4, sp
    
    ;d1 and d2 have x and y
    
    cmp.w d1, d3 ; ScreenWidth - x
    bgt .clampHeight
    clr.l d1
    move.w d3, d1
    sub.w #1, d1 
.clampHeight
    cmp.w d2, d4
    bgt .done
    clr.l d2
    move.w d4, d2 
    sub.w #1, d2 
.done
    movem.l (sp)+, .REGS
    clr.l d0
    rts


*Intention: Provides starting pixel of rectangle and height and width
*Out: d0: 0 for success, Loads the following in the stack created by the calling function 
*d1 : x, d2 : y, d3 : x_len, d4 : y_len
GetRectPoints:
.St_One EQU 4
.St_Two EQU 8
.St_Three EQU 12
.St_Four EQU 16
.St_Five EQU 20
.St_Six EQU 24
.St_Seven EQU 28
.Trap_Input EQU 4
    move.l a1, -(sp)
    *Taking user input for rectangle points in image
    moveq #BMP_TASK_OUTPUTSTR_CRLF, d0
    lea RectPrompt, a1
    trap #15
    
    sub.l #4, sp ;To store the value of d1 temporarily
    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, (.St_one,sp) ;x value in temp
    
    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, d2 ; y
    
    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, d3 ;x_len

    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, d4 ;y_len
    
    move.l (.St_one,sp),d1 ;temp value in x
    add.l #4, sp
    
    jsr ClampPixelCoordinates ; updates values of the registers
    
    move.l d1, (.St_Two,sp) ;x
    move.l d2, (.St_Three,sp) ;y
    move.l d3, (.St_Four,sp) ;x_len
    move.l d4, (.St_Five,sp) ;y_len
    
    *Taking user input for screen point where we want to start drawing the rectangle
    moveq #BMP_TASK_OUTPUTSTR_CRLF, d0
    lea ScreenPrompt, a1
    trap #15
    
    sub.l #4, sp ;To store the value of d1 in the stack temporarily
    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, (.St_One,sp) ;screen x value in temp
    
    clr.l d1
    move.b #.Trap_Input, d0
    trap #15
    move.l d1, d2 ; screen y
    
    move.l (.St_one,sp), d1 ; temp value in screen x
    add.l #4, sp
    
    jsr ClampScreenPoints
   
    move.l d1, (.St_Six,sp) ;screen_x
    move.l d2, (.St_Seven,sp) ;screen_y
    
    move.b #11, d0 ;Clear screen
    move.w #$FF00, d1
    trap #15
    
    clr.l d0
    move.l (sp)+, a1
    rts

*Intention : Calculate padding bytes value
*Output d1 : padding bytes, d0 : output
GetPadding:
.REGS REG d2-d7/a0-a6
.Bitmask EQU 3
    movem.l .REGS, -(sp)
    lea PixelSize, a2
    clr.l d1
    move.w (a2),d1 ;pixel size is word defined in word
    lea Width, a2
    move.l (a2),d2 
    mulu.w d1,d2 ; PixelSize * Width
    and.l #.Bitmask, d2 ; bitmasking to get remainder
    move.l d2, d1 
    sub.l #BMP_LONG_SIZE, d1 ; padding is 4 - remainder so negate in next instruction
    neg.l d1 
    cmp.l #BMP_LONG_SIZE, d1
    beq .set_zero
    bra .done
.set_zero
    clr.l d1
.done
    clr.l d0
    movem.l (sp)+, .REGS
    rts
    
*Intention : return the offset based on h and w based on fixed formula
*d1 : w
*d2 : h
*d3 : padding
*Out : Put value in stack
GetByteOffset
.REGS REG d1-d3/a2-a4
.STACK_OP EQU 28
    movem.l .REGS, -(sp)
    lea Width, a2
    lea Height, a3
    lea PixelSize, a4 ;word
    
    tst.l d2
    bge .calculate_rev
    bra .negate_h
.calculate_rev
    add.l #1, d2
    sub.l (a3),d2
.negate_h    
    neg.l d2
    
    mulu.w d2, d3 ; h * padding
    mulu.w (a4),d2 ; pixelSize*h
    mulu.w 2(a2),d2 ; WIDTH * h *pixelSize
    mulu.w (a4),d1 ; w*pixelSize
    add.l d1, d2 ; w*pixelSize + WIDTH*h*pixelSize
    ;mulu.w (a4),d2 ; (w + WIDTH*h)*pixelSize = w*pixelSize + WIDTH*(h*pixelSize)
    add.l d2, d3 ; (w + WIDTH*h)*pixelSize + (h*padding)
    move.l d3, (.STACK_OP,sp)
    
    movem.l (sp)+, .REGS
    rts
    
*Intention : convert given bytes in place from little endian to big endian
*Inputs
* a1 : start address
* d1.b : size
*Output
*d0.b : 0 for success and non zero for failure   
ConvertToBigEndian:
.REGS REG d1-d2/a1
    movem.l .REGS, -(sp)
    ;for n byte data
    sub.b #1, d1
    moveq #0, d2 ; clearing d2
    move.b d1, d2 ; end index
    move.b #0, d1 ; start index
    
.loop
    cmp.b d1, d2
    ble .exit  ; if end index becomes smaller than or equal to start index
    bsr Swap
    add.b #1, d1
    sub.b #1, d2
    bra .loop
.exit
    move.b #0, d0
    movem.l (sp)+, .REGS
.done
    rts
    
*Intention : Swap 2 elements in an array
*Input
*a1 : start address
*d1: start index
*d2 : end index
*Output
*d0.b : 0 for success    
Swap:
.REGS REG d1-d3/a1
    movem.l .REGS, -(sp) 
    move.b (a1,d1), d3 ; d3 is temp
    move.b (a1,d2), (a1,d1)
    move.b  d3, (a1,d2)
    move.b #0, d0
    movem.l (sp)+, .REGS
    rts


Width            ds.l 1
Height           ds.l 1
PixelSize        ds.w 1
ArraySize        ds.l 1
                 ds.w 0
RectPrompt       dc.b 'Please provide top left x and y and also the width and the height of the rectangle',0
                 ds.w 0
ScreenPrompt     dc.b 'Please provide x and y on the screen where you want the rectangle to be drawn',0
                 ds.w 0
                 dc.l     BMP_SENTINEL        
 














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
