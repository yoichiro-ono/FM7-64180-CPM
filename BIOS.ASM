;-----------------------------------------------------------
;63k CP/M
;BIOS.ASM
;CPM ZAS -OBIOS.OBJ -LBIOS.LST BIOS.ASM
;CPM LINK -S -X -Z -CF600H -OBIOS.BIN BIOS.OBJ
;-----------------------------------------------------------

*Include CPM.INC
*Include Z180.INC
*Include FM7.INC
*Include SETTING.INC

        ORG     0F600H

        JP      JCOLD
WBOOT:  JP      JWBOOT          ;0:WBOOT
        JP      JCONST          ;1:CONST
        JP      JCONIN          ;2:CONIN
        JP      JCONOUT         ;3:CONOUT
        JP      JLIST           ;4:
        JP      JPUNCH          ;5:NOT IMPLEMENT
        JP      JREADER         ;6:NOT IMPLEMENT
        JP      JHOME           ;7:
        JP      JSELDSK         ;8:
        JP      JSETTRK         ;9
        JP      JSETSEC         ;10
        JP      JSETDMA         ;11
        JP      JREAD           ;12
        JP      JWRITE          ;13:
        JP      JLISTST         ;14:NOT IMPLEMENT
        JP      JSECTRAN        ;15:

ECONST  EQU     8003H
ECONIN  EQU     8006H
ECONOUT EQU     8009H
EREAD   EQU     8024H
EWRITE  EQU     8027H
EINIT   EQU     8031H
ESECRED EQU     8034H
ESECWRT EQU     8037H
ERESTOR EQU     803AH
ETIMER  EQU     803DH

;F640-F65F:割込みベクタ
        DEFS    0F640H-$
VECTOR  EQU     $

        DEFS    0F660H-$
DMAADR: DEFW    0       ;last dma address

SEKDRV: DEFB    0       ;seek disk number
SEKTRK: DEFB    0       ;seek track number
SEKSEC: DEFB    0       ;seek sector number
SEKHST: DEFB    0       ;seek shr 1

HSTDRV: DEFB    0       ;host disk number
HSTTRK: DEFB    0       ;host track number
HSTSEC: DEFB    0       ;host sector number

HSTACT: DEFB    0       ;host active flag
HSTWRT: DEFB    0       ;host written flag

UNACNT: DEFB    0       ;unalloc rec cnt
UNADSK: DEFB    0       ;last unalloc disk
UNATRK: DEFB    0       ;last unalloc track
UNASEC: DEFB    0       ;last unalloc sector

ERRFLG: DEFB    0     ;
RSFLAG: DEFB    0       ;READ sector flag
READOP: DEFB    0       ;1 if READ operation
WRTYPE: DEFB    0       ;WRITE operation type
HSTBUF: DEFW    0       ;host buffer
HSTBUFH EQU     HSTBUF+1
RETRYCT:DEFB    0       ;RETRY COUNTER
SAVESP: DEFW    0       ;
FDCSTAT:DEFB    0       ;FDC STATUS(ERROR)



CONINI: ;CONSOLE INITIALIZE
        DEFB    0,0,1,0,80,25,0,25,0,1,0
CONCTL: ;CURSOR ON,ORDER ON
        DEFB    0,0,0CH,03H
KEYBFEN:;KEYBOARD BUFFER ENABLE
        DEFB    0,0,3,2,1BH,67H

;BOOT MESSAGE
BOOTMSG:DEFM    '63k CP/M80 for FM-7 with 64180 card'
CRLF:   DEFB    0DH,0AH, 0

;-----------------------------------------------------------
; COLD BOOT
;-----------------------------------------------------------
JCOLD:  LD      SP,0080H
        XOR     A
        LD      (0004H),A
        CALL    INITMMU
        
        LD      BC,11
        LD      HL,CONINI
        CALL    SUBSYSCMD

        LD      BC,4
        LD      HL,CONCTL
        CALL    SUBSYSCMD
        
        LD      BC,6
        LD      HL,KEYBFEN
        CALL    SUBSYSCMD

        LD      HL,BOOTMSG
        CALL    PUTS
        
        LD      HL,DMAADR
        LD      DE,DMAADR+1
        LD      BC,FDCSTAT-DMAADR
        LD      (HL),0
        LDIR
        

        CALL    LDBIOS2

        ;***************************************************
        ;割込みの設定
        ;***************************************************
        DI
        LD      HL,HTIMER0
        LD      (VECTOR+VPRT0_OFS),HL
        
        IN0     A,(ITC)
        AND     0F8H
        OUT0    (ITC),A
        ;IM      1
        LD      HL,VECTOR
        LD      A,H
        LD      I,A             ;interrupt vector addr high=F6
        OUT0    (IL),L          ;Interrupt Vevtor Addr B7-B5 set IL reg
        
        ;$9C40...100ms
        ;$4E20...50ms
        ;$1F40...20ms
        ;$0FA0...10ms
        LD      HL,INTERVAL
        XOR     A
        OUT0    (TCR),A         ;TIE0,TDE0 DISABLE
        OUT0    (TMDR0L),L      ;Timer Data Registers 0 L reg set
        OUT0    (TMDR0H),H      ;Timer Data Registers 0 H reg set
        OUT0    (RLDR0L),L      ;Timer Reload Registers 0 L reg set
        OUT0    (RLDR0H),H      ;Timer Reload Registers 0 H reg set
        LD      A,11H           ;Timer Control Register
        OUT0    (TCR),A         ;TIE0(Timer Interrupt Enable) CH0 set
        ;                       ;TDE0(Timer Down Count Enable) CH0 set
        ;***************************************************
        CALL    INITIAL
        
        JR      INIWRK

;-----------------------------------------------------------
; WARM BOOT
;-----------------------------------------------------------
JWBOOT: DI
        LD      SP,0080H
        
        CALL    INITMMU
        
        CALL    RESTOR
        ;LD      A,8
        ;LD      (RCB),A
        ;LD      BC,BRESTOR
        ;CALL    ROMBIOS
        
        LD      A,(HSTWRT)
        OR      A
        CALL    NZ,SECWRT
        CALL    ERFCHK

        CALL    INITIAL
        
        ;LOAD CCP/BDOS
        CALL    LOADCCP

INIWRK: LD      A,001H
        LD      (IRQFLG),A      ;SPEAKER OFF
        LD      A,0C3H
        LD      (0000H),A
        LD      HL,WBOOT
        LD      (0001H),HL
        LD      (0005H),A
        LD      HL,CPMBDOS
        LD      (0006H),HL
        
        LD      BC,0080H
        CALL    JSETDMA
        XOR     A
        LD      (HSTACT),A
        LD      (UNACNT),A
        LD      HL,SECTBUF
        LD      (HSTBUF),HL

        LD      A,(0004H)
        LD      C,A
        
        EI
        JP      CPMBASE

;-----------------------------------------------------------
;INITIALIZE WORK AREA AND CACHE
;-----------------------------------------------------------
INITIAL:;CLEAR OVER WRAPPED WORK AREA
        LD      HL,OVERWRAP
        LD      DE,OVERWRAP+1
        LD      BC,OWEND-OVERWRAP
        LD      (HL),0
        LDIR

        LD      HL,EINIT
        JR      CALLB2

;-----------------------------------------------------------
;SECTOR READ(BIOS2)
;-----------------------------------------------------------
SECRED: LD      HL,ESECRED
        JR      CALLB2

;-----------------------------------------------------------
;SECTOR WRITE(BIOS2)
;-----------------------------------------------------------
SECWRT: LD      HL,ESECWRT
        JR      CALLB2

;-----------------------------------------------------------
;SECTOR WRITE(BIOS2)
;-----------------------------------------------------------
RESTOR: LD      HL,ERESTOR
        JR      CALLB2

;-----------------------------------------------------------
;CONST(BIOS2)
;-----------------------------------------------------------
JCONST: LD      HL,ECONST
        JR      CALLB2

;-----------------------------------------------------------
;CONIN(BIOS2)
;-----------------------------------------------------------
JCONIN: LD      HL,ECONIN
        JR      CALLB2

;-----------------------------------------------------------
;CONOUT(BIOS2)
;-----------------------------------------------------------
JCONOUT:LD      HL,ECONOUT
        JR      CALLB2

;-----------------------------------------------------------
;READ(BIOS2)
;-----------------------------------------------------------
JREAD:  LD      HL,EREAD
        JR      CALLB2

;-----------------------------------------------------------
;WRITE(BIOS2)
;-----------------------------------------------------------
JWRITE: LD      HL,EWRITE
        JR      CALLB2

;-----------------------------------------------------------
; CALL  BIOS2
;-----------------------------------------------------------
CALLB2: ;DI
        LD      (SAVESP),SP
        LD      SP,BIOS2ST      ;STACK=FA80
        PUSH    HL
        LD      HL,CALLB2E
        EX      (SP),HL
        
        PUSH    AF
        LD      A,80H
        OUT0    (BBR),A         ;SELECT BANK AREA 0000-EFFF=80000-8EFFF
        POP     AF
        
        JP      (HL)

CALLB2E:PUSH    AF
        XOR     A
        OUT0    (BBR),A         ;SELECT BANK AREA 0000-EFFF=00000-0EFFF
        POP     AF
        LD      SP,(SAVESP)
        ;EI
        RET

;-----------------------------------------------------------
;LIST
;-----------------------------------------------------------
JLIST:  RET

;-----------------------------------------------------------
;LISTST
;-----------------------------------------------------------
JLISTST:XOR     A
        RET

;-----------------------------------------------------------
;PUNCH
;-----------------------------------------------------------
JPUNCH: RET

;-----------------------------------------------------------
;READER (function 7)
;OUT
;       A=01AH(device isn't implemented)
;-----------------------------------------------------------
JREADER:LD      A,01AH
        RET

;-----------------------------------------------------------
;SELDSK (function 9)
;IN
;   C=drive(0=A:, 1=B: ...)
;   E=0 or 0FFH
;     0:the disc is logged in as if new;
;       if the format has to be determined from the boot
;       sector, for example, this will be done.
;     1:the disc has been logged in before.
;       The disc is not accessed; the DPBASE address (or zero)
        ;is returned immediately.
;OUT
;   HL=address of a Disc Parameter Header
;       If the disc could not be selected it returns HL=0.
;-----------------------------------------------------------
JSELDSK:
        LD      HL,0
        LD      A,C
        CP      2
        RET     NC

        LD      (SEKDRV),A
        LD      L,A
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,DPBASE
        ADD     HL,DE
        RET

;-----------------------------------------------------------
;HOME (function 8)
;Move the current drive to track 0.
;-----------------------------------------------------------
JHOME:
        LD      A,(HSTWRT)      ;check for pending write
        OR      A
        JR      NZ,HOME1
        LD      (HSTACT),A      ;clear host active flag
HOME1:
        LD      C,0
;-----------------------------------------------------------
;SETTRK (function 10)
;IN
;   BC=track(0 based)
;-----------------------------------------------------------
JSETTRK:
        LD      A,C
        LD      (SEKTRK),A
        RET

;-----------------------------------------------------------
;SETSEC (function 11)
;IN
;   BC=sector
;-----------------------------------------------------------
JSETSEC:
        LD      A,C
        LD      (SEKSEC),A
        RET

;-----------------------------------------------------------
;SETDMA (function 12)
;IN
;   BC=DMAADR
;-----------------------------------------------------------
JSETDMA:
        LD      (DMAADR),BC
        RET

;-----------------------------------------------------------
;SECTRAN (function 16)
;Translate sector numbers to take account of skewing.
;
;IN
;   BC=logical sector number (zero based)
;   DE=address of translation table.
;OUT
;   HL=physical sector number.
;   On a system with hardware skewing, this would normally
;   ignore DE and return either BC or BC+1.
;-----------------------------------------------------------
JSECTRAN:
        LD      L,C
        LD      H,B
        RET

;-----------------------------------------------------------
;DPB
;-----------------------------------------------------------
DPBASE: ;drive 0
        DEFW  0         ;Address of sector translation table
        DEFW  0,0,0     ;Used as workspace by CP/M
        DEFW  0FC00H    ;Address of a 128-byte sector buffer
        DEFW  DPB       ;Address of the DPB
        DEFW  CV0       ;Address of the directory checksum vector
        DEFW  AV0       ;Address of the allocation vector
        ;drive 1
        DEFW  0         ;Address of sector translation table
        DEFW  0,0,0     ;Used as workspace by CP/M
        DEFW  0FC00H    ;Address of a 128-byte sector buffer
        DEFW  DPB       ;Address of the DPB
        DEFW  CV1       ;Address of the directory checksum vector
        DEFW  AV1       ;Address of the allocation vector


DPB:    DEFW  0040H     ;Number of 128-byte records per track
        DEFB  04H       ;Block shift. 3 => 1k, 4 => 2k, 5 => 4k....
        DEFB  0FH       ;Block mask. 7 => 1k, 0Fh => 2k, 1Fh => 4k...
        DEFB  01H       ;Extent mask
        DEFW  0097H     ;(no. of blocks on the disc)-1
        DEFW  007FH     ;(no. of directory entries)-1
        DEFB  0C0H      ;Directory allocation bitmap, first byte
        DEFB  000H      ;Directory allocation bitmap, second byte
        DEFW  0020H     ;Checksum vector size, 0 for a fixed disc
                        ;No. directory entries/4, rounded up.
        DEFW  0002H     ;Offset, number of reserved tracks

;CV0:    DEFS  32        ;128/4
;CV1:    DEFS  32
;AV0:    DEFS  19        ;151/8+1
;AV1:    DEFS  19

;-----------------------------------------------------------
; MMU INITIALIZE
;-----------------------------------------------------------
INITMMU:
        LD      A,0F0H
        OUT0    (CBAR),A
        XOR     A
        OUT0    (BBR),A
        RET

;-----------------------------------------------------------
;LOAD CCP/BDOS
;-----------------------------------------------------------
LOADCCP:
        XOR     A
        LD      (HSTDRV),A
        LD      (HSTTRK),A      ;TRACK #0
        INC     A
        LD      (HSTSEC),A      ;SECTOR #1(2)
        LD      HL,SECTBUF
        LD      (HSTBUF),HL
        LD      DE,CPMBASE
        LD      B,16H
LDCCP1: PUSH    BC
        PUSH    DE
        CALL    SECRED
        CALL    ERFCHK

        LD      HL,HSTSEC
        INC     (HL)
        POP     DE
        LD      HL,SECTBUF
        LD      BC,100H
        LDIR
        
        POP     BC
        DJNZ    LDCCP1
        RET


;-----------------------------------------------------------
; TIMER 0 INTERRUPT HANDLER
;-----------------------------------------------------------
HTIMER0:DI
        LD      (IRQSP),SP
        LD      SP,IRQSTK

        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        
        ;---------------------------------------------------
        ;これが無いとRET直後に再度割込みがかかる
        IN0     A,(TCR)
        IN0     A,(TMDR0L)
        ;---------------------------------------------------
        
        IN0     A,(BBR)
        PUSH    AF              ;SAVE BBR
        
        CP      80H
        JR      Z,HTIM01
        LD      A,80H
        OUT0    (BBR),A         ;SELECT BANK AREA 0000-EFFF=80000-8EFFF
HTIM01:
        CALL    ETIMER

        POP     AF
        OUT0    (BBR),A         ;RESTORE BBR

        POP     HL
        POP     DE
        POP     BC
        POP     AF
        
        LD      SP,(IRQSP)
        EI
        RET

;-----------------------------------------------------------
; SUB SYSTEM HALT
;-----------------------------------------------------------
SUBHLT: LD      HL,SUBIF
SUBHLT1:LD      A,(HL)
        AND     080H
        JR      NZ,SUBHLT1
        LD      (HL),081H
        RET

;-----------------------------------------------------------
;SUB SYSTEM READY
;-----------------------------------------------------------
SUBRDY: PUSH    AF
        LD      A,(SHRMEM)
        OR      080H
        LD      (SHRMEM),A
        LD      (HL),1
        POP     AF
        RET

;-----------------------------------------------------------
;SUB SYSTEM COMMAND EXECUTE
;-----------------------------------------------------------
SUBSYSCMD:
        EX      DE,HL
        
        CALL    SUBHLT
        
        EX      DE,HL
        LD      DE,0FC80H
        LDIR
        LD      HL,SUBIF
        LD      (HL),1
        RET

;-----------------------------------------------------------
; ERFCHK : CHECK ERROR FLAG AND HALT
;-----------------------------------------------------------
ERFCHK: LD      A,(ERRFLG)
        OR      A
        RET     Z

        LD      C,007H  ;BEEP
        CALL    PUTCH
ERF1:   JR      ERF1

;-----------------------------------------------------------
; PUTCH : PUT CHARACTER
;-----------------------------------------------------------
PUTCH:  PUSH    DE
        PUSH    HL
        
        LD      D,A
        
        CALL    SUBHLT
        
        LD      A,D
        LD      DE,0103H
        LD      (0FC82H),DE
        LD      (0FC84H),A
        
        LD      (HL),1
        POP     HL
        POP     DE
        RET
;-----------------------------------------------------------
; PUTS : PUT STRING
;-----------------------------------------------------------
PUTS:   PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL

        EX      DE,HL           ;DE=STRING
        CALL    SUBHLT
        PUSH    HL
        EX      DE,HL           ;HL=STRING
        
        LD      BC,00003H
        LD      DE,0FC84H
        
PUTS1:  LD      A,(HL)
        OR      A
        JR      Z,PUTS2
        LD      (DE),A
        INC     HL
        INC     DE
        INC     B
        JR      PUTS1
        
PUTS2:  LD      (0FC82H),BC

        POP     HL
        LD      (HL),1

        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

;===========================================================
; OVER WRAP SUB ROUTINE
;===========================================================
OVERWRAP        EQU     $

;-----------------------------------------------------------
; CALL ROM BIOS
;-----------------------------------------------------------
ROMBIOS:
        LD      L,B
        LD      H,C
        LD      (ROMADRS),HL
        LD      (REGA),A
        XOR     A
        LD      (SUBIF),A       ;SWITCH TO 6809
        NOP
        LD      A,(REGA)
        RET

;-----------------------------------------------------------
;LOAD BIOS2
;-----------------------------------------------------------
LDBIOS2:LD      HL,RETRYCT
        LD      (HL),5
        LD      BC,16*256       ;LOAD SECTOR COUNT,START SECTOR(1-1)
        LD      DE,08000H
LDB2L:  PUSH    BC
        PUSH    DE
        CALL    RDSECT
        CALL    ERFCHK
        POP     DE
        
        LD      HL,SECTBUF
        LD      BC,256
        
        LD      A,80H
        OUT0    (BBR),A         ;SELECT BANK AREA 0000-EFFF=80000-8EFFF
        
        LDIR                    ;COPY SECTBUF TO DEST(88000-88FFF)
        
        XOR     A
        OUT0    (BBR),A         ;SELECT BANK AREA 0000-EFFF=00000-0EFFF
        
        POP     BC
        INC     C               ;NEXT SECTOR
        DJNZ    LDB2L
        RET

;-----------------------------------------------------------
;READ SECTOR
;-----------------------------------------------------------
RDSECT: LD      A,10
        LD      (RCB),A
        LD      DE,SECTBUF
        LD      L,D
        LD      H,E
        LD      (RCB+2),HL
        LD      A,1
        LD      (RCB+4),A       ;TRACK
        LD      A,C
        AND     0FH
        INC     A
        LD      (RCB+5),A       ;SECTOR(1-16)
        LD      A,C
        RRA
        RRA
        RRA
        RRA
        AND     1
        LD      (RCB+6),A       ;SIDE(0,1)
        XOR     A
        LD      (RCB+7),A       ;DRIVE
        LD      BC,BREAD
        CALL    ROMBIOS
        LD      HL,ERRFLG
        LD      (HL),0  ;CLEAR ERRFLG
        OR      A
        RET     Z

        INC     (HL)    ;SET ERRFLG
        LD      HL,RETRYCT
        DEC     (HL)
        RET     Z

        LD      A,8
        LD      (RCB),A
        LD      BC,BRESTOR
        CALL    ROMBIOS
        JR      RDSECT
        
;===========================================================
; OVER WRAP DATA
;===========================================================
        DEFS    0FA80H-$
        
        ORG     OVERWRAP
CV0:    DEFS    32      ;128/4
CV1:    DEFS    32      ;128/4
AV0:    DEFS    19      ;151/8+1
AV1:    DEFS    19      ;151/8+1
IRQSP:  DEFS    2
        DEFS    128
IRQSTK  EQU     $       ;割込み用スタック
OWEND   EQU     $
        END
