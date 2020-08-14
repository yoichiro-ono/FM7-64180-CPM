;-----------------------------------------------------------
;IPL.ASM
;-----------------------------------------------------------
        ORG     $0100
        BRA     MAIN
RESTOR  FCB     $08     ;RESTORE COMMAND
        FCB     $00
        FCB     $00
        FCB     $00
        FCB     $00
        FCB     $00
        FCB     $00
        FCB     $00
DREAD   FCB     $0A     ;+0:DREAD COMMAND
        FCB     $00     ;+1:STATUS
        FDB     $E000   ;+2:DATA BUFFER ADDRESS
        FCB     $00     ;+4:TRACK
        FCB     $02     ;+5:SECTOR
        FCB     $00     ;+6:SIDE
        FCB     $00     ;+7:DRIVE
        FCB     $1B     ;+8:total read sector
        FCB     $00     ;+9
        ;$1B*256=$1B00=CCP+BDOS+BIOS+BIOS09のサイズ
        ;CCP～BDOS:E000～F5FF
        ;BIOS     :F600～FA7F
        ;BIOS09   :FA80～FAFF
MAIN    ORCC    #$50
        ;CCP+BDOS読み込み
        LDS     #$0100
        STA     $FD0F     ;ALL RAM MODE
        LDA     #$FD
        TFR     A,DP
        LEAX    DREAD,PCR
LOOP1   LDA     #$05
        STA     9,X       ;RETRY COUNT
LOOP2   JSR     $FE08     ;DREAD
        BCC     READOK    ;READ OK
        DEC     9,X
        BEQ     RETRYOV   ;リトライ回数オーバー
        STX     ,--S      ;PSHS X
        LEAX    RESTOR,PCR
        JSR     $FE02     ;RESTORE
        LDX     ,S++      ;PULS X
        BRA     LOOP2
RETRYOV LDA     #$81      ;SPEAKER ON
        STA     <$03      ;BEEP----
INFINIT BRA     INFINIT
READOK  INC     2,X       ;DATA BUFFER ADDRESS
        LDA     5,X       ;SECTOR NO
        INCA              ;INC SECTOR NO
        CMPA    #$11      ;SIDE
        BNE     SIDE0
        INC     6,X
        LDA     #$01
SIDE0   STA     5,X
        DEC     8,X
        BNE     LOOP1
        ;
        LDB     #$80  
        LDX     #$FA80
        LDY     #$FC00
COPYLP  LDA     ,X+   
        STA     ,Y+   
        DECB          
        BNE     COPYLP
        CLRA          
        TFR     A,DP  
        LDA     #$C3  
        STA     <$00  
        LDD     #$F600
        EXG     A,B   
        STD     <$01  
        JMP     $FC10     ;JMP BIOS09
