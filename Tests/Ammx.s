; Test AMMX code

    SECTION TESTAMMX,CODE

Start:

    lea         Buffer,a0
    lea         Buffer+8,a1
    lea         Buffer+12,a2

    LOAD        (A0)+,D1        ;D1=64 bit from any memory location, A0=A0+8
    PAVGB       (A1)+,D1,D1     ;8x unsigned byte average (a+b+1)>>1
    STORE       D1,(A2)+        ;write result

    moveq       #4,d3           ;yes yes, this will stall in the following <VEA> calculation
    LOAD        4(A0,D3.l*4),D1 ;D1=64 bit from any memory location
    moveq       #%01010101,D2   ;D2.b=bit mask which bytes (bit=1) are to be written
    STOREM      D1,D2,(A2)+     ;write every second byte from D1 

    LOAD        (A0)+,D1        ;4 signed words: a0.w a1.w a2.w a3.w
    LOAD        (A1)+,D2        ;4 signed words: b0.w b1.w b2.w b3.w
    PACKUSWB    D1,D2,(A2)+     ;8 unsigned bytes: a0 a1 a2 a3 b0 b1 b2 b3 

    LOAD (A0)+,D0
    STORE3 D0,#1,(A1)+   , cookie cut copy 8 pixel which are not color = 0
    dbra D7,LOOP


    moveq.l #0,d0
    rts

    SECTION DATAAMMX,DATA

Buffer:
    dc.l        0,0,0,0,0,0,0,0
    
    END
