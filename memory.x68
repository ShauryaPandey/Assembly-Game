*-----------------------------------------------------------
* Title      : Memory management module
* Written by : 
* Date       : 
* Description: 
*-----------------------------------------------------------

* constants for callers of mem_Audit
MEM_AUDIT_OFFS_FREE_CNT     EQU 0
MEM_AUDIT_OFFS_USED_CNT     EQU 4
MEM_AUDIT_OFFS_FREE_MEM     EQU 8
MEM_AUDIT_OFFS_USED_MEM     EQU 12
MEM_AUDIT_RETURN_SIZE       EQU 16
MEM_SENTINEL    EQU $deaddead

* constants for header struct (internal)
MEM_HEADER_SIZE EQU 8 * !!! update this value based on your header layout
MEM_HEADER_SIZE_REVERSE EQU -8
MEM_HEADER_OFFS_NEXT_REVERSE EQU -4
MEM_NEXT EQU 4
*---
* Initializes the start of the heap
* 
* a1 - start address of heap
* d1.l - size of heap
*
* out d0.b - 0 = success, non-zero = failure
*---

mem_InitHeap:
.REGS   REG     d1-d7/a0-a6
    movem.l .REGS, -(sp)

    sub.l #MEM_HEADER_SIZE, d1
    ble .error    
    neg.l d1 ; negative to denote free
    move.l d1, (a1) ;size of heap
    move.l #MEM_SENTINEL, MEM_NEXT(a1) ;next address
    move.l a1, StartOfHeap
    moveq #0, d0
    bra .end
.error
    moveq #1, d0
.end:
    movem.l (sp)+, .REGS
    rts

*---
* Accumulates some statistics for memory usage
*
* out d0.b - 0 = success, non-zero = error
* out (sp) - count of free blocks
* out (sp+4) - count of used blocks
* out (sp+8) - total remaining free memory
* out (sp+12) - total allocated memory
mem_Audit:
.STACK_SIZE EQU 15
.MULTIPLIER EQU 2
.REGS   REG     d1-d7/a0-a6
    
    movem.l .REGS, -(sp)
    move.l #.STACK_SIZE, d1
    asl.l #.MULTIPLIER , d1 ;offset to get to the output stack addresses
    move.l StartOfHeap, a1
    clr.l (sp, d1)
    clr.l (4,sp,d1)
    clr.l (8,sp,d1)
    clr.l (12,sp,d1)
.loop
    move.l MEM_NEXT(a1), a5 ;loaded next block address in a5    
    move.l (a1), d0 ;loaded size in d0
    
    tst.l d0
    blt .freeBlock
    
.allocatedBlock
    add.l #1, (4,sp,d1)
    add.l d0, (12,sp,d1)
    bra .nextBlock

.freeBlock
    add.l #1, (sp, d1) ;increase free blocks count
    neg.l d0
    add.l d0, (8,sp,d1) ; increase free remaining memory
    
.nextBlock
    cmp.l #MEM_SENTINEL, a5
    beq .noBlockFound
    move.l a5, a1 ; loading next address into current address
    bra .loop 
.noBlockFound
    move.b #0, d0 ;return 0

.exitLoop
     movem.l (sp)+, .REGS
     rts
          
*---
* Allocates a chunk of memory from the heap
*
* d1.l - size
*
* out a0 - start address of allocation
* out d0.b - 0 = success, non-zero = failure
*---

mem_Alloc:
.REGS   REG     D1-D7/A1-A6
    movem.l .REGS, -(sp)
    move.l StartOfHeap, a1    
*Making sure size requested is even so that it is word aligned 
*and dont have to do anything else for this   
    move.l d1, d2
    asr.l #1, d2
    bcs .oddBytes
    bra .loop
    
.oddBytes
    add.l #1, d1
    
.loop
    move.l MEM_NEXT(a1), a5 ;loaded next block address in a5    
    move.l (a1), d0 ;loaded size in d0
    tst.l d0
    bge .nextBlock
    neg.l d0
    sub.l d1, d0 ; d1 = requested size, d0 = available size, available - requested
    *Now d0 holds the difference between available and requested
    blt .nextBlock 
    ;handling yes case
    ;if diff > header size
    
    cmp.l #MEM_HEADER_SIZE, d0
    bgt .normalAlloc ; Modify size var, next add var and initialize values in next header
.fullAlloc
    neg.l (a1) 
    add.l #MEM_HEADER_SIZE, a1
    move.l a1, a0
    move.b #0, d0
    bra .exitLoop
    
.normalAlloc
    move.l (a1), d2 ;d2: original available space
    move.l MEM_NEXT(a1), a3 ; a3 next address pointed by current block
    move.l d1, (a1) ; 
    *Calculate next header address
    move.l a1, a2
    add.l #MEM_HEADER_SIZE, a2
    add.l d1, a2
    move.l a2, MEM_NEXT(a1)
    ;set properties of next header through mem_init
    add.l (a1), d2
    add.l #MEM_HEADER_SIZE, d2
    move.l d2, (a2)
    move.l a3, MEM_NEXT(a2)
    *end of normal alloc
    
    add.l #MEM_HEADER_SIZE, a1
    move.l a1, a0
    move.b #0, d0 ;return value success    
    bra .exitLoop
    
.nextBlock
    cmp.l #MEM_SENTINEL, a5
    beq .noBlockFound
    move.l a5, a1 ; loading next address into current address
    bra .loop
    
.noBlockFound
    move.b #1, d0 ;return value failure

.exitLoop
     movem.l (sp)+, .REGS
     rts

    
*---
* Frees a chunk of memory from the heap
*
* a1 - start address of allocation
*
* out d0.b - 0 = success, non-zero = failure
*---
mem_Free:
.REGS   REG a1
    movem.l .REGS, -(sp)
    tst.l MEM_HEADER_SIZE_REVERSE(a1)
    bgt .markFree
    bra .exit
.markFree
    neg.l MEM_HEADER_SIZE_REVERSE(a1)
    move.l StartOfHeap, a1
    add.l #MEM_HEADER_SIZE, a1
    ;bsr mem_Coalesce

.exit  
    clr.b d0 
    movem.l (sp)+, .REGS  
    rts
    
*---
* Reduces a current memory allocation to a smaller number of bytes
*
* a1 - start address of allocation
* d1.l - new size
* 
* out d0.b - 0 = success, non-zero = failure

mem_Shrink:
.REGS REG   d1-d7/a0-a6
    movem.l .REGS, -(sp)
    move.l MEM_HEADER_SIZE_REVERSE(a1), d2 
    move.l MEM_HEADER_OFFS_NEXT_REVERSE(a1), a2
    sub.l d1, d2 ; d2 - d1 : current size-shrink size
    ble .exit
    
    cmp.l #MEM_HEADER_SIZE, d2
    ble .exit
    
    sub.l #MEM_HEADER_SIZE, d2 ; the size of the new block
    move.l MEM_HEADER_SIZE_REVERSE(a1), d3 ; current size of the current block
    
    move.l d2, (a1,d1) ; setting size on the next block
    neg.l (a1,d1) ; negating it to indicate its free
    move.l a2, (4,a1,d1) ; the next address of the next block
    
    move.l d1, MEM_HEADER_SIZE_REVERSE(a1) ;update size of the current block
    move.l a1, a3 ;temporary variable
    add.l d1, a3 ; calculating the position of the next block
    move.l a3, MEM_HEADER_OFFS_NEXT_REVERSE(a1) ;setting the address of the next field in the header of the current block
    add.l #MEM_HEADER_SIZE, a3
    bsr mem_Coalesce
    move.l #0, d0 ; we should not fail shrink just because coalesce function fails to find blocks to coalesce 
    bra .done
    
.exit
    move.b #1, d0
.done
    movem.l (sp)+, .REGS
    rts

*Coalesces free blocks into one free block
*
* Start address of block : a1
*out : d0.b - 0 = success, non-zero : failure   
mem_Coalesce:
.REGS   REG d1-d2/a1-a2
    movem.l .REGS, -(sp)
    move.b #1, d0
.loop    
    tst.l MEM_HEADER_SIZE_REVERSE(a1)
    bge .nextBlock
    cmp.l #MEM_SENTINEL, MEM_HEADER_OFFS_NEXT_REVERSE(a1)
    beq .done
    move.l MEM_HEADER_OFFS_NEXT_REVERSE(a1), a2
    add.l #MEM_HEADER_SIZE, a2
    tst.l MEM_HEADER_SIZE_REVERSE(a2)
    bge .nextBlock
    move.l MEM_HEADER_SIZE_REVERSE(a2), d2
    move.l MEM_HEADER_SIZE_REVERSE(a1), d1
    neg.l d2
    neg.l d1
    add.l d2, d1
    add.l #MEM_HEADER_SIZE, d1
    neg.l d1
    move.l d1, MEM_HEADER_SIZE_REVERSE(a1)
    move.l MEM_HEADER_OFFS_NEXT_REVERSE(a2), MEM_HEADER_OFFS_NEXT_REVERSE(a1)
    move.b #0, d0
    bra .loop

.nextBlock
    move.l MEM_HEADER_OFFS_NEXT_REVERSE(a1), a2
    cmp.l #MEM_SENTINEL, a2
    beq .done
    add.l #MEM_HEADER_SIZE, a2
    move.l a2, a1
    bra .loop
.done
    movem.l (sp)+, .REGS
    rts

StartOfHeap ds.l 0


*~Font name~Courier New~
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
