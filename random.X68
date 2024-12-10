*picked up directly from the reference code
seedRandomNumber
        movem.l ALL_REG,-(sp)           ;; What does this do?
        clr.l   d6
        move.b  #GET_TIME_COMMAND,d0    ;; What if you used the same seed?
        TRAP    #15

        move.l  d1,RANDOMVAL
        movem.l (sp)+,ALL_REG
        rts

getRandomByteIntoD6
        movem.l d0,-(sp)
        movem.l d1,-(sp)
        movem.l d2,-(sp)
        move.l  RANDOMVAL,d0
       	moveq	#$AF-$100,d1
       	moveq	#18,d2
Ninc0	
	add.l	d0,d0
	bcc	Ninc1
	eor.b	d1,d0
Ninc1
	dbf	d2,Ninc0
	
	move.l	d0,RANDOMVAL
	clr.l	d6
	move.b	d0,d6
	
        movem.l (sp)+,d2
        movem.l (sp)+,d1
        movem.l (sp)+,d0
        rts


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
