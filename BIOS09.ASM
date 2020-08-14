        ORG     $FC00
        FCB     $7C
        RZB     15,$FF
        BRA     MAINL
        BRA     PRTST
        BRA     PUTCH
        RZB     10,$FF
MAINL   LDA     #$FD
        TFR     A,DP
        LDX     #$FC00
        LDS     #$FC80
        LDA     #$01
        STA     <$05    ;FD05(switch to Z80)
        NOP
        LDA     $FC0A
        JSR     [$FC08]
        STA     $FC0A
        BRA     MAINL
PRTST   LDB     <$02    ;FD02(PRINTER STATUS)
        LSRB            ;PRINTER BUSY?
        BCS     PRTST   ;BUSY
        STA     <$01    ;FD01(WRITE PRINTER)
        NOP
        NOP
        CLR     <$00    ;FD00(PRINTER STROBE)
        NOP
        NOP
        LDB     #$40
        STB     <$00    ;FD00
        RTS
PUTCH   LDA     <$05    ;FD05
        ASLA
        BCS     PUTCH   ;SUB SYSTEM BUSY
        LDA     #$80
        STA     <$05    ;FD05(SUB SYSTEM HALT)
        LDY     #$FC80
        LDD     #$0000
        STD     ,Y
        LDD     #$0303
        STD     2,Y     ;FC82,FC83
        LDA     0,X     ;FC00
        STA     4,Y     ;FC84
        LDD     1,X     ;FC01
        STD     5,Y     ;FC85
        CLR     <$05    ;FD05(SUB SYSTEM RESTART)
        RTS
        RZB     $FC80-*
