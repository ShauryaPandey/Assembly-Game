*-----------------------------------------------------------
* Title      : File IO module
* Written by : 
* Date       : 
* Description: 
*-----------------------------------------------------------

FILE_TASK_FOPEN      EQU     51
FILE_TASK_FCREATE    EQU     52
FILE_TASK_FREAD      EQU     53
FILE_TASK_FWRITE     EQU     54
FILE_TASK_FCLOSE     EQU     56

*---
* Write a buffer to a file
*
* a1 - start address of filename
* a2 - start address of buffer to write
* d1.l - size of buffer to write
*
* out d0.b - 0 for success, non-zero for failure
*---

* Write file 
*    As above except D2.L holds number of bytes to write (unaltered upon return).
*    The write operation is not completed until the file is closed using 50 or 56.
*    File ID in D1.L
*    (A1) buffer address
*    D2.L size of bytes to write

*

file_Write:
        movem.l D2-D7/A3-A6, -(sp)

        move.l d1, d2
        
        * open the file
        move.b  #FILE_TASK_FCREATE, d0
        trap    #15
        tst.w   d0
        bne     .error
        ; d1 contains file ID
        move.l a1, a3 ; saving this in temporary register
        move.l a2, a1 ; the write task expects buffer address in a1
        
        ;a1: buffer address
        ;d1 : file ID
        ;d2 : buffer size
        
        * write the words
        move.b  #FILE_TASK_FWRITE, d0
        trap    #15
        
        move.b #FILE_TASK_FCLOSE, d0
        trap #15
.error        
        move.l a3, a1 ; restoring a1 even though we dont need to since a1 is volatile
        movem.l (sp)+, D2-D7/A3-A6
        rts

*---
* Read a buffer from a file
*
* a1 - start address of filename
* a2 - start address of buffer to read
* d1.l - size of buffer to read
*
* out d1.l - number of bytes read
* out d0.b - 0 for success, non-zero for failure
*---
file_Read:
        movem.l D2-D7/A1-A6, -(sp)
        
        move.l d1, d2 ; size of buffer to read store in d2
        
        move.b #FILE_TASK_FOPEN, d0
        trap #15
        tst.w d0
        bne .error
        
        move.l a2, a1
        ;D1 set to file ID
        ;D2 set to buffer size
        ;A1 set to buffer address
        
        ; file read code
        move.b #FILE_TASK_FREAD, d0
        trap #15
        move.l d2, d1 ; out d1 number of bytes read
.error
        movem.l (sp)+, D2-D7/A1-A6
        
        rts
    









*~Font name~Courier New~
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
