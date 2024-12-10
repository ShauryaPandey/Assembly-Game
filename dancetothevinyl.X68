*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
    
SENTINEL        EQU     $DEADDEAD
TASK_PRINT      EQU     13
ALL_REG                 REG     D0-D7/A0-A6
    ORG    $1000
    INCLUDE "file.x68"
    INCLUDE "memory.x68"
    INCLUDE "bitmap.x68"
DELAY_FRAME	            equ	    23
FRAME_DELAY_TIME        EQU     1
CLEAR_SCREEN_COMMAND    equ     11
CLOSE_ALL_FILES         equ 50
CLEAR_SCREEN_MAGIC_VAL  equ     $FF00
TRAP_TASK_GET_TIME equ 8
GET_TIME_COMMAND        equ     8
IDEAL_FPS_TIME          equ 5
OnScreen equ 1
OffScreen equ 0

    INCLUDE "background.X68"
    INCLUDE "bitmapmanager.X68"
    INCLUDE "random.X68"
    INCLUDE "collision.X68"
    INCLUDE "character.X68"
    INCLUDE "vinyl.X68"
    INCLUDE "seven_segment.X68"
    INCLUDE "soundmanager.X68"
*input : d1 : frame delay time    
DelayFrame
        move.l  #DELAY_FRAME, d0
        TRAP    #15
        rts

ClearScreen
        move.b  #CLEAR_SCREEN_COMMAND,d0
       	move.l  #CLEAR_SCREEN_MAGIC_VAL,d1
       	TRAP    #15
	rts

UpdateTimer:
.REGS REG d0-d2/d5/a1-a4
.one_sec equ 100
.decrement equ 1
.left_offs equ 100
.right_offs equ 160
    movem.l .REGS, -(sp)
    lea Timer, a4
    move.l (TIMER_FIELD_OFFS_LASTTIME, a4),d2 
    tst.l d2
    beq .init
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15
    sub.l d2, d1
    cmp.l #.one_sec, d1
    blt .done
    sub.w #1, (TIMER_FIELD_OFFS_COUNTER, a4)
    moveq #.decrement,d1 ; 
    lea SevenSegmentSymbolTable, a1
    lea SevenSegmentFunctions, a2
    lea SevenSegmentTimer,a3
    move.l #(.right_offs<<16 | .left_offs),d5
    bsr Update7Segment
    *if timer == 0 change game state
    move.b (a3),d5
    tst.b d5
    bne .Init
    lea GameStatus, a1
    move.b #GAME_STATUS_STOPPING, (a1)
.init
    *get time and set it to this field
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15
    
    move.l d1, (TIMER_FIELD_OFFS_LASTTIME, a4)
.done
    movem.l (sp)+,.REGS 
    rts 
    
*This function gets bmps of all the images being used in the game
GetBMPs:
.REGS REG d2-d3/a1-a3/d7
    movem.l .REGS, -(sp)
    lea ImageData,a2
    
    lea LoseScreenFile,a1
    lea LoadedLose, a3
    move.l #LOSESCREEN_WIDTH,d2
    move.l #LOSESCREEN_HEIGHT,d3
    moveq #1,d7
    bsr GetBMP
    
    lea TimerFile, a1
    lea LoadedTimer,a3
    move.l #TIMER_WIDTH,d2
    move.l #TIMER_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea RecordsLeftFile, a1
    lea LoadedRecordsLeft,a3
    move.l #RECORDSLEFT_WIDTH,d2
    move.l #RECORDSLEFT_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    
    lea BackgoundFile, a1 ;32 bit file
    lea LoadedBackground, a3
    move.w #BACKGROUND_WIDTH, d2
    move.w #BACKGROUND_HEIGHT, d3 
    moveq #1, d7
    bsr GetBMP
    
    lea VinylFile, a1
    lea LoadedVinyl, a3
    moveq #VINYL_WIDTH, d2
    moveq #VINYL_HEIGHT, d3
    moveq #0, d7
    bsr GetBMP
.char_height equ 60
.char_width equ 30    
    lea CharacterFile, a1
    lea LoadedCharacter, a3
    moveq #.char_width, d2
    moveq #.char_height, d3
    moveq #0, d7
    bsr GetBMP
    
    lea BrokenVinylFile, a1
    lea LoadedBrokenVinyl, a3
    moveq #VINYL_WIDTH, d2
    moveq #VINYL_HEIGHT, d3
    moveq #0, d7
    bsr GetBMP
  
    lea StartScreenFile, a1
    lea LoadedStartScreen, a3
    move.l #STARTSCREEN_WIDTH,d2
    move.l #STARTSCREEN_HEIGHT,d3
    moveq #1,d7
    bsr GetBMP
    
    *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea WinScreenFile, a1
    lea LoadedWin, a3
    move.l #WINSCREEN_WIDTH,d2
    move.l #WINSCREEN_HEIGHT,d3
    moveq #1,d7
    bsr GetBMP
    
    lea Mja1, a1
    lea Moves, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja2, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja3, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja4, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja5, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja6, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea Mja7, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja8, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja9, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja10, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja11, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja12, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja13, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
        *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea Mja15, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja16, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja17, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja18, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja19, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja20, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
        *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea Mja21, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja22, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja23, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja24, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja25, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja26, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja27, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
        *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    
    lea Mja28, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja29, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja30, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja31, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja32, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja33, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja34, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea Mja35, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja36, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja37, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mja38, a1
    add.l #MOVE_OFFSET,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mjw1, a1
    lea WalkingMoves, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mjw2, a1
    add.l #WALK_MOVE_OFFSET, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP

    lea Mjw3, a1
    add.l #WALK_MOVE_OFFSET, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP    
    
    *close all files since we can only open max of 8 files
    moveq #CLOSE_ALL_FILES, d0
    trap #15
    
    lea Mjw4, a1
    add.l #WALK_MOVE_OFFSET, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP 
 
    lea Mjw5, a1
    add.l #WALK_MOVE_OFFSET, a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP
    
    lea Mji1,a1
    lea IdleMoves,a3
    move.l #CHAR_WIDTH,d2
    move.l #CHAR_HEIGHT,d3
    moveq #0, d7
    bsr GetBMP    
    
    movem.l (sp)+, .REGS
    rts
*output : d1 : current time    
GetCurrentTime
    move.l d0, -(sp)
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15
    move.l (sp)+,d0
    rts
*Intention : update character draw based on current beat pattern and time. Play current, update it to next and exit function
*Input : a3 : current_move pointer, a2 : character class, a4 : current move number, a5 : start time
AnimateCharacter:
.REGS REG d1/d6-d7/a1-a6
    movem.l .REGS, -(sp)

    move.w (CHAR_FIELD_OFFS_Y,a2),d6
    move.w (CHAR_FIELD_OFFS_X,a2),d7
    
    lea IsWalking,a1 * 0 for true
    tst.b (a1)
    beq .walking
    
    cmp.w #MOVES_COUNT,(a4) * current move number 
    beq .reset_cur_move
    bra .continue
.reset_cur_move
    lea Moves, a1
    move.l a1,(a3) *Store first move address in (a3)    
    move.w #0,(a4)
.continue  
    lea SongActive, a2
    tst.b (a2)
    beq .idle
    move.l (a3),a1 *a1 is also address of the character move data
    bsr GetCurrentTime ;time in d1
    sub.l (a5),d1
    lea CurrentBeatDuration, a6 
    cmp.b (a6),d1
    bge .next_move
    bra .render
 
.next_move
    bsr GetCurrentTime
    move.l d1,(a5)
    
    add.l #MOVE_OFFSET,(a3) * a3 should point to next character move data
    add.w #1, (a4) * current move number
    bra .render
.walking
    lea WalkingMoves, a1
    lea CurrentWalkMovePointer, a3 *long
    lea CurrentWalkMoveNumber, a4 *word
    cmp.w #WALK_MOVES_COUNT, (a4)
    beq .reset_walk
    bra .continue_walk
.reset_walk
    move.l a1, (a3)
    move.w #0, (a4)
.continue_walk
    move.l (a3),a1
    bsr GetCurrentTime
    lea LastWalkFrame, a5
    sub.l (a5),d1
    cmp.l #10,d1
    bge .next_walk_move
    bra .render
.next_walk_move
    bsr GetCurrentTime
    move.l d1,(a5)
    add.l #WALK_MOVE_OFFSET, (a3)
    add.w #1, (a4)
    bra .render
.idle
     lea IdleMoves, a1

.render   
    ;lea LoadedCharacter, a1
    move.l d6, -(sp) ;y
    move.l d7, -(sp) ;x
    move.l #CHAR_HEIGHT, -(sp) ;height
    move.l #CHAR_WIDTH, -(sp) ;width
    
    jsr FastRender
    add.l #16, sp
    
    movem.l (sp)+, .REGS
    rts
    
*Plays the currently referenced sound
*Input : a6:sound reference
PlaySound
.REGS REG d0-d3/a2-a6
.max_sounds equ 10
    movem.l .REGS, -(sp)
    *stop current song if any
    ;lea CurrentSoundReference, a1
    lea BeatsDuration, a4 * in bytes
    lea CurrentBeatDuration, a5 * also in byte
    move.l (a6),d1 *current sound
    tst.l d1
    beq .playsound
    *stop current and play next
    moveq #77, d0
    moveq #2, d2 *stop
    sub.l #1, d1 *to stop previous song
    trap #15
    add.l #1, d1 *current reference
    cmp.l #.max_sounds, d1
    bge .skipplaysound
.playsound  
    
    add.l d1,a4
    move.b (a4),(a5) * setting current beat duration  
    lea SongActive,a2
    move.b #1,(a2) 
    moveq #77, d0
    moveq #0, d2 *to play
    trap #15
    
    add.l #1, d1
    move.l d1, (a6)
.skipplaysound    
    movem.l (sp)+, .REGS
    rts

*Input : a6:sound reference
StopSound
.REGS REG d0-d3/a2/a6
    movem.l .REGS, -(sp)
    ;lea CurrentSoundReference, a1
    lea SongActive, a2
    move.b #0, (a2)
    
    move.l (a6),d1
    sub.l #1,d1
    moveq #77, d0
    moveq #2, d2 ;stop
    trap #15
    movem.l (sp)+,.REGS    
    rts


*This function sets up the various components of the program    
Init
.REGS REG a1-a2
    movem.l .REGS, -(sp)
    lea CurrentSoundReference,a1
    lea SOUNDFILES, a2
    bsr InitSounds 
    
    lea SevenSegmentFunctions, a1
    bsr InitSevenSegmentFunctions
    
    bsr GetBMPs
    
    lea SongStartTime,a1
    lea LastWalkFrame,a2
    bsr GetCurrentTime
    move.l d1, (a1)
    move.l d1, (a2)
    movem.l (sp)+, .REGS
    rts
    
START:                  ; first instruction of program
    ;Set size of screen
    move.b #33, d0
    move.l #400*$10000+400,d1
    trap #15
    
    bsr Init

*pre game
    lea LoadedStartScreen, a1
    moveq #100, d1
    moveq #100,d2
    
    bsr DrawStartScreen
    lea GameStatus, a1
    move.b #GAME_STATUS_STARTING, (a1)
.pre_loop
    cmp.b #GAME_STATUS_STARTING, (a1)
    bne .break
    move.l #$D, d1
    move.b #GET_USER_INPUT_COMMAND, d0
    trap #15
    tst.b d1
    bne .start_game
    bra .pre_loop
.start_game
    move.b #GAME_STATUS_RUNNING, (a1)
    bra .pre_loop

.break
*set up background and other static images
    ;Set size of screen
    move.b #33, d0
    move.l #580*$10000+800,d1
    trap #15
    
    lea LoadedBackground,a1
    bsr DrawBackground
    
    lea LoadedRecordsLeft, a1
    move.l #380, d6
    move.l #600, d7
    bsr DrawRecordsLeftScreen
    
    lea LoadedTimer, a1
    move.L #0, d6
    move.l #600, d7
    bsr DrawTimerScreen
    
*    moveq #71, d0
*    lea SOUNDSTRING10,a1
*    moveq #0, d1
*    trap #15
    
    moveq #76, d0
    moveq #0, d1
    moveq #1, d2
    trap #15
    
.gameloop:
    lea GameStatus, a1
    cmp.b #GAME_STATUS_STOPPING, (a1)
    beq .gameloopdone
    moveq #TRAP_TASK_GET_TIME, d0
    trap #15
    move.l d1,d2
    move.l  #92,d0
    move.l  #17,d1
    trap    #15
    
    lea VinylPositions,a1
    lea LoadedBackground,a2
	bsr ClearVinyls2
	
	lea Character, a1
	lea LoadedBackground, a2
    bsr ClearCharacter 
    
    bsr UpdateTimer
    
    lea VinylPositions,a1
    lea Collision, a3
    lea Character, a4
    bsr FinalUpdateVinyls
    
    lea Character, a1
    bsr UpdateCharacter
    * affects the animation
    lea IsWalking, a1
    move.b d0, (a1)
    
    lea Collision,a4
    lea SevenSegmentSymbolTable, a1
    lea SevenSegmentFunctions, a2
    lea SevenSegmentCounter,a3
    lea CurrentSoundReference,a6
    bsr OnCollision
    
    lea VinylPositions, a1
    lea LoadedVinyl,a2
    lea LoadedBrokenVinyl,a3
    bsr FastDrawVinyls
  
     lea CurrentMovePointer, a3
     lea Character, a2
     lea CurrentMoveNumber, a4
     lea SongStartTime, a5
     bsr AnimateCharacter
     
     moveq #TRAP_TASK_GET_TIME, d0
     trap #15
     sub.l d2,d1 *time this frame took
     moveq #IDEAL_FPS_TIME ,d3
     sub.l d1,d3
     tst.l d3
     bne .after_delay
     move.l d3,d1
     bsr DelayFrame

.after_delay
    move.b  #94,d0
    trap    #15
    bra .gameloop
.gameloopdone
    *after game loop
    move.l  #92,d0 * double buffering
    move.l  #17,d1
    trap    #15
    
    moveq #76, d0 *stop crowd sound playing on standard player
    moveq #3, d2
    trap #15
    
    ;Set size of screen
    move.b #33, d0
    move.l #400*$10000+400,d1
    trap #15
    
    *clear screen
    moveq #CLEAR_SCREEN_COMMAND, d0
    move.w #$FF00,d1
    trap #15
    lea SevenSegmentCounter, a1
    tst.b (a1)
    beq .win
    *lose
    lea LoadedLose, a1
    bsr DrawLoseScreen
    bra .try_again
.win
    lea LoadedWin, a1
    bsr DrawWinScreen
    *try_again function
.try_again
    
    move.b  #94,d0
    trap    #15
    
    jsr    DelayFrame

    bra .done    
.error
    moveq   #TASK_PRINT, d0
    lea     ErrorText, a1
    trap    #15
    

.done
    STOP #$2000
    
ErrorText          dc.b    'Error encountered',0
                   ds.w 0
BackgoundFile      dc.b    'stage2.bmp',0
                   ds.w 0
CharacterFile      dc.b    'michael.bmp',0
                   ds.w 0
VinylFile          dc.b    'vinyl_3.bmp',0
                   ds.w 0
BrokenVinylFile    dc.b    'broken_3.bmp',0
                   ds.w 0
StartScreenFile    dc.b    'start_screen.bmp',0
                   ds.w 0
WinScreenFile      dc.b    'win.bmp',0
                   ds.w 0
LoseScreenFile     dc.b    'lose.bmp',0
                   ds.w 0
RecordsLeftFile    dc.b    'records_left.bmp',0
                   ds.w 0
TimerFile          dc.b    'timer.bmp',0
                   ds.w 0
Mja1                dc.b     'mj_a1.bmp',0
Mja2                dc.b     'mj_a2.bmp',0
Mja3                dc.b     'mj_a3.bmp',0
Mja4                dc.b     'mj_a4.bmp',0
Mja5                dc.b     'mj_a5.bmp',0
Mja6                dc.b     'mj_a6.bmp',0
Mja7                dc.b     'mj_a7.bmp',0
Mja8                dc.b     'mj_a8.bmp',0
Mja9                dc.b     'mj_a9.bmp',0
Mja10               dc.b     'mj_a10.bmp',0
Mja11               dc.b     'mj_a11.bmp',0
Mja12               dc.b     'mj_a12.bmp',0
Mja13               dc.b     'mj_a13.bmp',0
*Mja14               dc.b     'mj_a14.bmp',0
Mja15               dc.b     'mj_a15.bmp',0
Mja16               dc.b     'mj_a16.bmp',0
Mja17               dc.b     'mj_a17.bmp',0
Mja18               dc.b     'mj_a18.bmp',0
Mja19               dc.b     'mj_a19.bmp',0
Mja20               dc.b     'mj_a20.bmp',0
Mja21               dc.b     'mj_a21.bmp',0
Mja22               dc.b     'mj_a22.bmp',0
Mja23               dc.b     'mj_a23.bmp',0
Mja24               dc.b     'mj_a24.bmp',0
Mja25               dc.b     'mj_a25.bmp',0
Mja26               dc.b     'mj_a26.bmp',0
Mja27               dc.b     'mj_a27.bmp',0
Mja28               dc.b     'mj_a28.bmp',0
Mja29               dc.b     'mj_a29.bmp',0
Mja30               dc.b     'mj_a30.bmp',0
Mja31               dc.b     'mj_a31.bmp',0
Mja32               dc.b     'mj_a32.bmp',0
Mja33               dc.b     'mj_a33.bmp',0
Mja34               dc.b     'mj_a34.bmp',0
Mja35               dc.b     'mj_a35.bmp',0
Mja36               dc.b     'mj_a36.bmp',0
Mja37               dc.b     'mj_a37.bmp',0
Mja38               dc.b     'mj_a38.bmp',0

Mjw1                dc.b     'mj_w1.bmp',0
Mjw2                dc.b     'mj_w2.bmp',0
Mjw3                dc.b     'mj_w3.bmp',0
Mjw4                dc.b     'mj_w4.bmp',0
Mjw5                dc.b     'mj_w5.bmp',0
Mji1                dc.b     'mj_i1.bmp',0


;InputFile2        dc.b    'simple.bmp',0
                   ds.l 0
ImageData          ds.b $400000
                   ds.l 0
;LoadedVinyl        ds.b $400000
LoadedVinyl        ds.b $1000
                   ds.w 0
LoadedBackground   ds.b $400000
                   ds.w 0
LoadedCharacter    ds.b $2000
                   ds.w 0
LoadedBrokenVinyl  ds.b $1000
                   ds.w 0
LoadedStartScreen  ds.b $100000
                   ds.w 0
LoadedWin          ds.b $100000
                   ds.w 0
LoadedLose         ds.b $100000
                   ds.w 0
LoadedTimer        ds.b $A000
                   ds.w 0
LoadedRecordsLeft  ds.b $A000
                   ds.w 0
IsWalking          dc.b 0
IsIdle             dc.b 1
                   ds.w 0                   
WALK_MOVE_OFFSET equ $2000
WALK_MOVES_COUNT equ 5
CurrentWalkMovePointer dc.l WalkingMoves
CurrentWalkMoveNumber  dc.w 0
WalkingMoves
.move0           ds.b $2000
                 ds.w 0
.move1           ds.b $2000
                 ds.w 0
.move2           ds.b $2000
                 ds.w 0
.move3           ds.b $2000
                 ds.w 0
.move4           ds.b $2000
                 ds.w 0     

IdleMoves
.move0          ds.b $2000
                ds.w 0            

MOVE_OFFSET equ $2000
MOVES_COUNT equ 37
CurrentMovePointer dc.l Moves
CurrentMoveNumber  dc.w 0
Moves
.move0             ds.b $2000
                   ds.w 0
.move1             ds.b $2000
                   ds.w 0
.move2             ds.b $2000
                   ds.w 0
.move3             ds.b $2000
                   ds.w 0
.move4             ds.b $2000
                   ds.w 0
.move5             ds.b $2000
                   ds.w 0
.move6             ds.b $2000
                   ds.w 0
.move7             ds.b $2000
                   ds.w 0
.move8             ds.b $2000
                   ds.w 0
.move9             ds.b $2000
                   ds.w 0
.move10            ds.b $2000
                   ds.w 0
.move11            ds.b $2000
                   ds.w 0
.move12            ds.b $2000
                   ds.w 0
.move13            ds.b $2000
                   ds.w 0
.move14            ds.b $2000
                   ds.w 0
.move15            ds.b $2000
                   ds.w 0
.move16            ds.b $2000
                   ds.w 0
.move17            ds.b $2000
                   ds.w 0
.move18            ds.b $2000
                   ds.w 0
.move19            ds.b $2000
                   ds.w 0
.move20            ds.b $2000
                   ds.w 0
.move21            ds.b $2000
                   ds.w 0
.move22            ds.b $2000
                   ds.w 0
.move23            ds.b $2000
                   ds.w 0
.move24            ds.b $2000
                   ds.w 0
.move25            ds.b $2000
                   ds.w 0
.move26            ds.b $2000
                   ds.w 0
.move27            ds.b $2000
                   ds.w 0
.move28            ds.b $2000
                   ds.w 0
.move29            ds.b $2000
                   ds.w 0
.move30            ds.b $2000
                   ds.w 0
.move31            ds.b $2000
                   ds.w 0
.move32            ds.b $2000
                   ds.w 0
.move33            ds.b $2000
                   ds.w 0
.move34            ds.b $2000
                   ds.w 0
.move35            ds.b $2000
                   ds.w 0
.move36            ds.b $2000
                   ds.w 0
.move37            ds.b $2000
                   ds.w 0
*.move38            ds.b $2000
                   ds.w 0                   
                       
SevenSegmentCounter dc.b 10
                    ds.w 0
SevenSegmentTimer   dc.b 90
                    dc.w 1
SevenSegmentSymbolTable 
.Zero            dc.b   $7E
.One             dc.b   $30
.Two             dc.b   $6D
.Three           dc.b   $79
.Four            dc.b   $33
.Five            dc.b   $5B
.Six             dc.b   $5F
.Seven           dc.b   $70
.Eight           dc.b   $7F
.Nine            dc.b   $73

                 ds.w 0
                 
SevenSegmentFunctions
.A            ds.l 1
.B            ds.l 1
.C            ds.l 1
.D            ds.l 1
.E            ds.l 1
.F            ds.l 1
.G            ds.l 1
 
MaxFrameTime      ds.w 0
RANDOMVAL         ds.l    1

Collision         dc.l 0
                  dc.w 0
SOUNDSTRING0      dc.b 'BilliJean.wav',0
SOUNDSTRING1      dc.b 'heal-the-world.wav',0
SOUNDSTRING2      dc.b 'bad.wav',0
SOUNDSTRING3      dc.b 'beat-it.wav',0
SOUNDSTRING4      dc.b 'black-or-white.wav',0
SOUNDSTRING5      dc.b 'dirty-diana.wav',0
SOUNDSTRING6      dc.b 'they-dont.wav',0
SOUNDSTRING7      dc.b 'thriller.wav',0
SOUNDSTRING8      dc.b 'way-you-make-me-feel.wav',0
SOUNDSTRING9      dc.b 'you-are-not-alone.wav',0
SOUNDSTRING10     dc.b 'crowd-applause.wav',0
                  dc.w 0
BeatsDuration
                  dc.b 51 * billieJean
                  dc.b 74 * Heal the world
                  dc.b 53 * bad
                  dc.b 43 * beat it
                  dc.b 52 * black or white
                  dc.b 46 * dirty diana
                  dc.b 67 * they dont
                  dc.b 50 * thriller
                  dc.b 52 * way you make me     
                  dc.b 50 * you are not alone
                  ds.w 0
CurrentBeatDuration ds.b 1
SongActive          dc.b 0   
                    ds.w 1         
SOUNDFILES:
.s0               dc.l SOUNDSTRING0    
.s1               dc.l SOUNDSTRING1  
.s2               dc.l SOUNDSTRING2
.s3               dc.l SOUNDSTRING3
.s4               dc.l SOUNDSTRING4
.s5               dc.l SOUNDSTRING5
.s6               dc.l SOUNDSTRING6
.s7               dc.l SOUNDSTRING7
.s8               dc.l SOUNDSTRING8
.s9               dc.l SOUNDSTRING9                 

CurrentSoundReference dc.l 0
SongStartTime         ds.l 1
VinylXPos         dc.w 0
WalkingAnimState  dc.w 0
LastWalkFrame     ds.l 1

TIMER_FIELD_OFFS_COUNTER equ 0
TIMER_FIELD_OFFS_LASTTIME equ 2
Timer
.counter dc.w 30
.lastTime dc.l 0

GAME_STATUS_STARTING equ -1
GAME_STATUS_RUNNING equ 0
GAME_STATUS_STOPPING equ 1

GameStatus dc.b 0
                    dc.w 1
VinylOffScreenTimes

;CHAR_FIELD_OFFS_PREVIOUS_X equ 4
Character
Y               dc.w 300
X               dc.w 290
;PreviousX       dc.w 100
IsCharacterUpdated dc.b 0
                   ds.w 1
VinylPositions
*Vinyl1X         dc.w 250
*Vinyl1Y         dc.w 0
*Time1           dc.l 0
*Velocity1       dc.w 1
*                ds.l 1
*                dc.b GenuineType ;offset 14
*                dc.b OnScreen ; offset 15
Vinyl2X         dc.w 220   ;350
Vinyl2Y         dc.w 0
Time2           dc.l 0
Velocity2       dc.w 1
                ds.l 1
                dc.b GenuineType ;offset 14
                dc.b OnScreen ; offset 15
Vinyl3X         dc.w 260  ; 450
Vinyl3Y         dc.w 0
Time3           dc.l 0
Velocity3       dc.w 1
                ds.l 1
                dc.b GenuineType ;offset 14
                ds.b OnScreen ;offset 15
Vinyl4X         dc.w 300   ;550
Vinyl4Y         dc.w 0
Time4           dc.l 0
Velocity4       dc.w 1
                ds.l 1
                dc.b BrokenType
                dc.b OnScreen ;offset 15
Vinyl5X         dc.w 340   ;650
Vinyl5Y         dc.w 0
Time5           dc.l 0
Velocity5       dc.w 1
                ds.l 1
                dc.b BrokenType
                dc.b OnScreen ;offset 15

VinylObject
XPos    dc.w 50
YPos    dc.w 0
Time    dc.l 0
Velocity dc.w 4
        ds.l 1
        ds.w 1 
        

StartOfMem
            ;dcb.b   HEAP_BYTES,0
EndOfMem
            dc.l    SENTINEL

                 ds.w 0
    END    START        ; last line of source























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
