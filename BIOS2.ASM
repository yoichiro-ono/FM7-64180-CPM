;-----------------------------------------------------------
;63k CP/M
;BIOS2.ASM
;CPM ZAS -OBIOS2.OBJ -LBIOS2.LST BIOS2.ASM
;CPM LINK -S -X -Z -C8000H -OBIOS2.BIN BIOS2.OBJ
;DiskImageWriteSector.exe CPMZ180.dat BIOS2.bin 33
;-----------------------------------------------------------
;trk# sec#
;  0   1- 1  IPL
;  0   2-23  CCP/BDOS(E000-F5FF)
;  0  23-27  BIOS(F600-FAFF)
;  0  28-32  BLANK
;  1   1-32  BIOS2(88000-8AFFF)
;-----------------------------------------------------------

*Include CPM.INC
*Include Z180.INC
*Include FM7.INC
*Include SETTING.INC

BIOSENT EQU     0F600H

        ORG     8000H
        JP      NOIMPL          ;0:WBOOT
JCONST: JP      CONST           ;1:CONST
JCONIN: JP      CONIN           ;2:CONIN
JCONOUT:JP      CONOUT          ;3:CONOUT
        JP      NOIMPL          ;4:
        JP      NOIMPL          ;5:NOT IMPLEMENT
        JP      NOIMPL          ;6:NOT IMPLEMENT
        JP      NOIMPL          ;7:
        JP      NOIMPL          ;8:
        JP      NOIMPL          ;9
        JP      NOIMPL          ;10
        JP      NOIMPL          ;11
JREAD:  JP      READ            ;12
JWRITE: JP      WRITE           ;13:
        JP      NOIMPL          ;14:NOT IMPLEMENT
        JP      NOIMPL          ;15:
NOIMPL:
        RET


JINIT:  JP      INIT
JSECRED:JP      SECRED
JSECWRT:JP      SECWRT
JRESTOR:JP      DRESTOR
JTIMER: JP      HTIMER0

CTBLSZ  EQU     251

KEYCODE:DEFB    0
ESCFLG: DEFB    0
        ;078H:ESCAPE
        ;079H:ESC+'='
        ;07AH:ESC+???
CURDRV: DEFB    4               ;CURRENT DRIVE
CURTRK: DEFB    0,0,0,0         ;CURRENT TRACK ADDRESS
DMOTOR: DEFB    0               ;MOTOR FLAG AREA
DSTDRV: DEFB    0               ;DESTINATION DRIVE


STAT0   EQU     04H     ;ASCI Status Channel 0
A0TDRE  EQU     02H     ;STAT0 Transmit Data Register Empty
TDR0    EQU     06H     ;ASCI Transmit Data Register Channel 0


;-----------------------------------------------------------
;INITIALIZE
;-----------------------------------------------------------
INIT:   LD      HL,WORKS
        LD      DE,WORKS+1
        LD      BC,WORKE-WORKS
        LD      (HL),A
        LDIR

        LD      HL,(0FFE1H)
        LD      (CURTRK),HL
        LD      HL,(0FFE3H)
        LD      (CURTRK+2),HL

        RET

;-----------------------------------------------------------
;GET CONSOLE STATUS
;-----------------------------------------------------------
CONST:  PUSH    BC
        LD      BC,(KBWPTR)
        LD      A,C
        SUB     B       ;KBWPTR=KBRPTR?
        POP     BC
        RET     Z
        LD      A,0FFH
        RET

;-----------------------------------------------------------
;CONSOLE INPUT
;-----------------------------------------------------------
CONIN:  CALL    CONST
        OR      A
        JR      Z,CONIN
        PUSH    BC
        PUSH    HL
        LD      BC,(KBRPTR)     ;C=KBRPTR
        LD      B,0
        LD      HL,KEYBUF
        ADD     HL,BC
        LD      B,(HL)
        LD      A,C
        INC     A
        AND     1FH
        LD      (KBRPTR),A
        LD      A,B
        POP     HL
        POP     BC
        RET

;-----------------------------------------------------------
;CONSOLE OUTPUT
;-----------------------------------------------------------
CONOUT: LD      HL,ESCFLG
        LD      A,(HL)
        OR      A
        JR      NZ,ESCMODE

        LD      A,C
        CP      01BH            ;ESCAPE
        JP      NZ,PUTCHAR

        LD      (HL),078H
        RET

ESCMODE:CP      078H
        JR      NZ,ESCMD1
        ;ESCAPE 1文字目
        LD      A,C
        CP      '='
        JR      NZ,ESCMD2
        LD      (HL),079H
        RET

ESCMD2: LD      (HL),07AH
        RET

ESCMD1: CP      079H
        JR      NZ,ESCMD3
        LD      (HL),C          ;ESC+'='+Y
        RET

ESCMD3: CP      07AH
        JR      NZ,ESCMD4

        LD      (HL),0
        LD      A,12
PUTCH:  JP      PUTCHAR
        RET

ESCMD4: LD      A,(HL)
        LD      (HL),0
        SUB     020H
        LD      H,A
        LD      A,C
        SUB     020H
        LD      L,A
        LD      A,012H
        CALL    PUTCH3

;-----------------------------------------------------------
;READ
;-----------------------------------------------------------
READ:
        XOR     A
        LD      (UNACNT),A
        INC     A
        LD      (READOP),A
        LD      (RSFLAG),A
        INC     A
        LD      (WRTYPE),A
        JR      RWOPER


;-----------------------------------------------------------
;WRITE
;Write the currently set track and sector. C contains a deblocking code:
;
;C=0 - Write can be deferred
;C=1 - Write must be immediate
;C=2 - Write can be deferred, 先読みが不要な場合.
;Returns A=0 for OK, 1 for unrecoverable error, 2 if disc is readonly, 0FFh if media changed.
;-----------------------------------------------------------
WRITE:
        XOR     A
        LD      (READOP),A
        LD      A,C
        LD      (WRTYPE),A
        CP      WRUAL           ;WRITE to unallocated ?
        JR      NZ,CHKUNA       ;NO
        ;WRITE to unallocated
        ;LD      A,BLKSIZ/128    ;next unalloc recs(16)
        LD      A,1
        LD      (UNACNT),A

        ;SEKDRV=>UNADSK
        ;SEKTRK=>UNATRK
        ;SEKSEC=>UNASEC
        LD      HL,(SEKDRV)
        LD      (UNADSK),HL
        LD      A,(SEKSEC)
        LD      (UNASEC),A

CHKUNA:
        LD      A,(UNACNT)
        OR      A
        JR      Z,ALLOC

        DEC     A
        LD      (UNACNT),A

        ;COMPARE
        ;SEKDRV=UNADSK
        ;SEKTRK=UNATRK
        ;SEKSEC=UNASEC
        LD      HL,(SEKDRV)
        LD      DE,(UNADSK)
        OR      A
        SBC     HL,DE
        JR      NZ,ALLOC

        LD      A,(SEKSEC)
        LD      HL,UNASEC
        CP      (HL)
        JR      NZ,ALLOC

        INC     (HL)
        XOR     A
        LD      (RSFLAG),A
        JR      RWOPER

ALLOC:
        XOR     A
        LD      (UNACNT),A
        INC     A
        LD      (RSFLAG),A
;*****************************************************
;*                                                   *
;*      Common code for READ and WRITE follows       *
;*                                                   *
;*****************************************************
RWOPER:
        XOR     A
        LD      (ERRFLG),A
        LD      A,(SEKSEC)
        RRA                     ;[0,1]=>0,[2,3]=>1
        LD      (SEKHST),A
        LD      HL,HSTACT
        LD      A,(HL)
        LD      (HL),1
        OR      A
        JR      Z,FILHST

        ;COMPARE
        ;SEKDRV=HSTDRV
        ;SEKTRK=HSTTRK
        ;SEKHST=HSTSEC
        LD      HL,(SEKDRV)
        LD      DE,(HSTDRV)
        OR      A               ;CLEAR CARRY
        SBC     HL,DE
        JR      NZ,NOMATCH

        LD      A,(SEKHST)
        LD      HL,HSTSEC
        CP      (HL)
        JR      Z,MATCH

NOMATCH:
        LD      A,(HSTWRT)
        OR      A
        CALL    NZ,JSECWRT
FILHST:
        ;SEKDRV=>HSTDRV
        ;SEKTRK=>HSTTRK
        ;SEKHST=>HSTSEC
        LD      HL,(SEKDRV)
        LD      (HSTDRV),HL
        LD      A,(SEKHST)
        LD      (HSTSEC),A

        LD      A,(RSFLAG)
        OR      A
        CALL    NZ,SECRED
        XOR     A
        LD      (HSTWRT),A
MATCH:
        ;copy data to or from buffer
        LD      A,(SEKSEC)
        AND     1
        RRCA
        LD      L,A
        LD      H,0
        ;hl has relative host buffer address
        LD      DE,(HSTBUF)
        ADD     HL,DE
        LD      DE,(DMAADR)
        LD      BC,128
        LD      A,(READOP)
        OR      A
        JR      NZ,RWMOVE       ;READ operation
        ;WRITE operation, mark and switch direction
        INC     A
        LD      (HSTWRT),A
        EX      DE,HL
RWMOVE:
        CALL    DMACOPY
        ;data has been moved to/from host buffer
        LD      A,(WRTYPE)
        CP      WRDIR           ;WRITE to directory ?
        LD      A,(ERRFLG)
        RET     NZ              ;NO

        ;clear host buffer for directory WRITE
        OR      A
        RET     NZ

        XOR     A
        LD      (HSTWRT),A
        CALL    SECWRT
        LD      A,(ERRFLG)
        RET

;-----------------------------------------------------------
; DMA MEMORY COPY
; in    HL      source address
;       DE      destination address
;       BC      data size
;-----------------------------------------------------------
DMACOPY:
        XOR     A
        OUT0    (SAR0L),L
        OUT0    (SAR0H),H
        OUT0    (SAR0B),A

        OUT0    (DAR0L),E
        OUT0    (DAR0H),D
        OUT0    (DAR0B),A

        OUT0    (BCR0L),C
        OUT0    (BCR0H),B

        LD      A,02H
        OUT0    (DMODE),A

        LD      A,60H
        OUT0    (DSTAT),A

        RET

;-----------------------------------------------------------
; PHYS SECTOR READ
;-----------------------------------------------------------
SECRED: LD      A,10            ;RETRY COUNT
        LD      (RETRYCT),A
SECRED1:CALL    DREAD
        RET     NC
        CALL    PUTRERR
        LD      A,(RETRYCT)
        DEC     A
        LD      (RETRYCT),A
        JR      Z,SECREDE
        CALL    DRESTOR
        JR      SECRED1
SECREDE:LD      HL,ERRM4
        CALL    DISPERR
        SCF
        RET

PUTRERR:
        PUSH    AF
        PUSH    HL
        LD      HL,RDERM
        CALL    PUTS
        POP     HL
        POP     AF
        CALL    TOHEXA
        CALL    PUTCRLF
        RET

RDERM:  DEFM    'DREAD ERR:'
        DEFB    0

;-----------------------------------------------------------
; PHYS SECTOR WRITE
;-----------------------------------------------------------
SECWRT: LD      A,10            ;RETRY COUNT
        LD      (RETRYCT),A
SECWRT1:CALL    DWRITE
        RET     NC
        CALL    PUTWERR
        TST     40H             ;WRITE PROTECT?
        JR      Z,SECWRT2       ;NO
        LD      HL,ERRM5
        CALL    DISPERR
        SCF
        RET
SECWRT2:LD      A,(RETRYCT)
        DEC     A
        LD      (RETRYCT),A
        JR      Z,SECWRTE
        CALL    DRESTOR
        JR      SECWRT1
        
SECWRTE:LD      HL,ERRM3
        CALL    DISPERR
        SCF
        RET

PUTWERR:
        PUSH    AF
        PUSH    HL
        LD      HL,WTERM
        CALL    PUTS
        POP     HL
        POP     AF
        CALL    TOHEXA
        CALL    PUTCRLF
        RET

WTERM:  DEFM    'DWRITE ERR:'
        DEFB    0

;===========================================================
;表示
;===========================================================

;-----------------------------------------------------------
;PUTCHAR
;-----------------------------------------------------------
PUTCHAR:PUSH    BC
        PUSH    DE
        PUSH    HL
        
        LD      B,1
        LD      C,A             ;SAVE CHAR
        CALL    SCBUFW          ;D=SCRPTR,E=SCWPTR
        LD      A,E
        INC     A
        CP      120
        JR      C,PUTCH1
        XOR     A
PUTCH1: LD      D,0
        LD      HL,SCRBUF
        ADD     HL,DE           ;ADD SCWPTR
        LD      (HL),C
        LD      (SCWPTR),A

        POP     HL
        POP     DE
        POP     BC
        RET

;-----------------------------------------------------------
;PUTCH3
;A,L,H:
;-----------------------------------------------------------
PUTCH3: PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    AF

        ;空を確認する(3文字以上必要)
        LD      B,3
        CALL    SCBUFW          ;D=SCRPTR,E=SCWPTR

        LD      D,0
        LD      A,E
        LD      HL,SCRBUF
        ADD     HL,DE
        POP     BC              ;AF
        LD      (HL),B
        INC     A
        SBC     HL,DE
        CP      120
        JR      C,PUTCH31
        XOR     A
PUTCH31:LD      E,A
        ADD     HL,DE
        POP     BC              ;HL
        LD      (HL),C          ;L
        INC     A
        SBC     HL,DE
        CP      120
        JR      C,PUTCH32
        XOR     A
PUTCH32:LD      E,A
        ADD     HL,DE
        LD      (HL),B          ;H
        LD      (SCWPTR),A

        POP     DE
        POP     BC
        RET

;-----------------------------------------------------------
;SCRBUFにBバイト以上の空ができるのを待つ
;OUT    A:空バイト数
;       DE:D=SCRPTR,E=SCWPTR
;-----------------------------------------------------------
SCBUFW: CALL    SCBFCHK
        DEC     E
        CP      B
        RET     NC
SCBUFWL:CALL    SCBFCHK
        CP      B
        JR      C,SCBUFWL
        DEC     E
        RET

;-----------------------------------------------------------
;SCRBUFの空を取得する
;-----------------------------------------------------------
SCBFCHK:LD      DE,(SCWPTR)     ;D=SCRPTR,E=SCWPTR
        LD      A,D
        INC     E
        SUB     E
        RET     NC
        ADD     A,120
        RET


;===========================================================
;DISK I/O
;===========================================================

;-----------------------------------------------------------
; READ ONE SECTOR
;-----------------------------------------------------------
DREAD:  LD      IX,FDCBAS
        CALL    DSEEK
        RET     C

        DI
        CALL    SECHED

        CALL    DELAY25U

        LD      A,RDSCMD        ;READ SECTOR
        LD      (IX+CMDREG),A

        LD      HL,(HSTBUF)
        LD      DE,FDCBAS+DRQIRQ
        LD      BC,FDCBAS+DATREG
        JR      READ2
        ;44(6+7+4+6+6+6+9)cycle/byte:11ns/byte
        ;drq wait:20cycle:5ns
READ1:  LD      A,(BC)          ;GET
        LD      (HL),A          ;STORE
        INC     HL
READ2:  LD      A,(DE)          ;GET DRQ/IRQ
        RLA
        JR      C,READ1         ;DRQ IS SET
        RLA
        JR      NC,READ2        ;DRQ,IRQ NOT SET
        ;IRQ IS SET
        CALL    FDCWAIT         ;WAIT TIL FDC IS FINISHED
        AND     RDMSK           ;MASK ERRORS
RWEND:  EI                      ;ENABLE INTERRUPTS
        JR      NZ,RWERR
        XOR     A
        RET

;-----------------------------------------------------------
; READ/WRITE ERROR
;-----------------------------------------------------------
RWERR:  LD      B,0AH
        TST     80H             ;DISK NOT READY
        JR      NZ,RWERR1
        INC     B
        TST     40H             ;DISK WRITE PROTECTED
        JR      NZ,RWERR1
        INC     B
        TST     14H             ;HARD ERROR(RECORD NOT FOUND,LOST DATA)
        JR      NZ,RWERR1
        INC     B
        TST     08H             ;CRC ERROR
        JR      NZ,RWERR1
        INC     B               ;RECORD TYPE ERROR,WRITE FAULT
RWERR1: SCF
        RET

;-----------------------------------------------------------
; WRITE ONE SECTOR
;-----------------------------------------------------------
DWRITE: LD      IX,FDCBAS
        CALL    DSEEK
        RET     C

        DI
        CALL    SECHED

        CALL    DELAY25U

        LD      HL,(HSTBUF)
        LD      DE,FDCBAS+DRQIRQ
        LD      B,0

        LD      A,WTSCMD        ;WRITE SECTOR
        LD      (IX+CMDREG),A

        JR      WRITE1
        ;DRQ
WRITE0: LD      (IX+DATREG),C   ;15
WRITE1: LD      C,(HL)          ;6
        INC     HL              ;
WRITE2: LD      A,(DE)          ;6
        RLA
        JR      C,WRITE0        ;DRQ IS SET
        RLA
        JR      NC,WRITE2       ;DRQ,IRQ NOT SET
        ;IRQ SET
WRITE3: CALL    FDCWAIT         ;WAIT TIL FDC IS FINISHED
WRITE4: AND     WTMSK
        JR      RWEND

;-----------------------------------------------------------
;ERROR
;-----------------------------------------------------------
ERRNOTRDY:
        LD      A,NOTRDY                ;NOT READY
        DEFB    21H                     ;SKIP 2 BYTES(LD HL,nn)
ERRTIMOVR:
        LD      A,TIMOVR                ;TIME OVER
        SCF
        RET

;-----------------------------------------------------------
; RESTORES THE HEAD TO 00
;-----------------------------------------------------------
DRESTOR:LD      IX,FDCBAS
        LD      A,(HSTDRV)
RESTOR0:
        AND     3
        LD      B,A
        CALL    FNDTRK          ;FIND TRACK
        LD      A,B
        LD      (HL),0
        LD      B,(IX+DRVREG)   ;PREV DRIVE
        OR      80H             ;MOTOR ON
        LD      (IX+DRVREG),A
        CALL    DELAY20
        LD      A,(IX+DRVREG)
        RLA                     ;MOTOR BIT=>Carry FLG
        JR      NC,ERRNOTRDY    ;MOTOR OFF
        RL      B               ;PREV DRIVE MOTOR ON ?
        JP      C,DORESTOR      ;YES
        ;WAIT 2 SEC(WAIT MOTOR ON)
        LD      A,2
RESLP1: CALL    DELAY1S
        DEC     A
        JR      NZ,RESLP1
DORESTOR:
        LD      A,RESCMD        ;RESTORE COMMAND
        JR      EXECMD

;-----------------------------------------------------------
;SEEK THE HEAD TO SPECIFIED TRACK
;-----------------------------------------------------------
DSEEK:  CALL    DRVSEL          ;SELECT DRIVE
        JR      C,ERRNOTRDY

        ;GET CURRENT TRACK OF DSTDRV
        LD      A,(DSTDRV)
        CALL    FNDTRK
        LD      B,(HL)
        LD      (IX+TRKREG),B
        ;CHECK NEW TRACK
        LD      A,(HSTTRK)
        CP      B                       ;CURRENT TRACK = NEW TRACK ?
        JR      Z,OK_DEL25              ;YES
        LD      (HL),A
        LD      (IX+DATREG),A
        LD      A,SEKCMD                ;SEEK COMMAND
EXECMD:
        LD      (IX+CMDREG),A
        LD      B,30
EXEC1:  LD      DE,17391
EXEC2:  LD      A,(IX+DRQIRQ)
        OR      40H                     ;DRQ IS SET ?
        JR      NZ,EXEC3                ;YES
        DEC     DE
        LD      A,D
        OR      E
        JR      NZ,EXEC2
        DJNZ    EXEC1
        JR      ERRTIMOVR
EXEC3:  CALL    WNBUSY
        ;fall through
;-----------------------------------------------------------
;RETURN OK AND DELAY 25 usec
;-----------------------------------------------------------
OK_DEL25:
        XOR     A
;-----------------------------------------------------------
;DELAY 25 usec(200 clock)
;-----------------------------------------------------------
DELAY25U:
        PUSH    AF                      ;11
        LD      A,13                    ;6
DELAY2L:DEC     A                       ;4
        JR      NZ,DELAY2L              ;6/8
        POP     AF                      ;9
        RET

;-----------------------------------------------------------
;DRIVE SELECT
;-----------------------------------------------------------
DRVSEL:
        LD      A,(IX+DRVREG)
        LD      B,A             ;CURRENT DRIVE(MOTOR)
        AND     3
        LD      C,A

        LD      A,(HSTDRV)      ;GET NEW DRIVE NO
        AND     3
        LD      (DSTDRV),A      ;SET DESTINATION DRIVE
        LD      D,A
        LD      A,B             ;GET CURRENT DRIVE(MOTOR)
        AND     80H             ;CURRENT DRIVE MOTOR ON ?
        JR      Z,MOTOFF        ;NO
        ;CURRENT DRIVE MOTOR WAS ON
        LD      A,D             ;DSTDRV
        CP      C               ;CURDRV=DSTDRV ?
        JR      Z,CHKRDY        ;YES
        OR      80H             ;MOTOR ON AND SET NEW DRIVE
        LD      (IX+DRVREG),A
        JR      CHKRDY

        ;MOTORがONになっていない場合は全ドライブをRESTORする
MOTOFF:
        LD      A,80H
RESTLP:
        PUSH    AF
        CALL    RESTOR0
        POP     AF
        INC     A
        CP      84H
        JR      NZ,RESTLP

        LD      A,(DSTDRV)
        OR      80H
        LD      (IX+DRVREG),A
CHKRDY: ;CHECK DRIVE IS READY
        LD      A,(IX+CMDREG)
        RRA                     ;BUSY ?
        JR      NC,DRVCHK1      ;NO
        ;FDC BUSY
        LD      A,FRCICM        ;FORCE INTERRUPT
        LD      (IX+CMDREG),A
DRVCHK1:
        LD      A,(IX+DATREG)
        CPL
        LD      (IX+DATREG),A
        CALL    DELAY25U
        CP      (IX+DATREG)
        JR      NZ,OK_DEL25

        ;WAIT FDC IS READY
        LD      DE,60000        ;6
DRVCHKL:DEC     DE              ;4
        LD      A,D             ;4
        OR      E               ;4
        JP      Z,ERRTIMOVR     ;5 TIMEOUT ERROR
        LD      A,(IX+CMDREG)   ;14
        AND     80H             ;6 READY ?
        JR      NZ,DRVCHKL      ;8 NOT READY
        XOR     A               ;RESET CARRY FLG
        RET

;-----------------------------------------------------------
;WAIT NOT BUSY
;-----------------------------------------------------------
WNBUSY: LD      A,(IX+CMDREG)
        RRA                     ;BUSY ?
        RET     NC
        JR      WNBUSY

;-----------------------------------------------------------
;SECTOR => SECTOR , SIDE
;-----------------------------------------------------------
SECHED: LD      A,(HSTSEC)      ;0-31
        LD      B,0             ;HEAD:0
        CP      16
        JR      C,SECHED1
        INC     B               ;HEAD:1
        SUB     16
SECHED1:INC     A
        LD      (IX+HEDREG),B
        LD      (IX+SECREG),A
        RET

;-----------------------------------------------------------
; FIND THE TRACK FOR SPECIFIED DRIVE
; A : DRIVE
;-----------------------------------------------------------
FNDTRK: LD      HL,CURTRK       ;POINT TO TRACK STORE
        ADD     A,L
        LD      L,A
        RET     NC
        INC     H
        RET

;-----------------------------------------------------------
; WAIT FOR FDC TO FINISH COMMAND
;-----------------------------------------------------------
FDCWAIT:LD      A,(IX+CMDREG)   ;GET STATUS
        TST     FDCBSY          ;CHECK IF BUSY
        JR      NZ,FDCWAIT      ;LOOP TIL NOT BUSY
        RET


;===========================================================
; DELAY ROUTINE
;===========================================================

;-----------------------------------------------------------
;DELAY 1sec
;-----------------------------------------------------------
DELAY1S:
        PUSH    AF
        PUSH    BC
        LD      BC,999
DELAY1L:
        CALL    DELAY1MS
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,DELAY1L
        POP     BC
        POP     AF
        RET
;-----------------------------------------------------------
;DELAY 20sec
;-----------------------------------------------------------
DELAY20MS:
        PUSH    AF
        LD      A,20
DELAY2ML:
        CALL    DELAY1MS
        DEC     A
        JR      NZ,DELAY2ML
        POP     AF
        RET

;-----------------------------------------------------------
;DELAY 1msec
;-----------------------------------------------------------
DELAY1MS:
        ;8000カウント@8MHz(8,000,000Hz)
        PUSH    AF              ;11
        PUSH    BC              ;11
        LD      BC,397          ;9
DELAYLP:
        ;4+4+4+8=20,8000/20=400
        DEC     BC              ;4
        LD      A,B             ;4
        OR      C               ;4
        JR      NZ,DELAYLP      ;6/8
        POP     BC              ;9
        POP     AF              ;9
        RET                     ;9

;-----------------------------------------------------------
; DELAY 38uS
; 229cycle
;-----------------------------------------------------------
DELAY38:PUSH    AF
        LD      A,18
        JR      DELLOOP

;-----------------------------------------------------------
; DELAY 20uS
; 100cycle
;-----------------------------------------------------------
DELAY20:PUSH    AF
        LD      A,8
DELLOOP:DEC     A
        JR      NZ,DELLOOP
        POP     AF
        RET

;-----------------------------------------------------------
;DISPERR
;-----------------------------------------------------------
DISPERR:PUSH    AF
        CALL    PUTS
        POP     AF
        CALL    TOHEXA
        CALL    PUTCRLF
ERROR1: JR      ERROR1

ERRM9:  DEFM    'NO SEEK'
        DEFB    0
ERRM1:  DEFM    'SELECT DRIVE ERROR:'
        DEFB    0
ERRM2:  DEFM    'SEEK ERROR:'
        DEFB    0
ERRM3:  DEFM    'WRITE ERROR:'
        DEFB    0
ERRM4:  DEFM    'READ ERROR:'
        DEFB    0
ERRM5:  DEFM    'WRITE PROTECTED:'
        DEFB    0

;-----------------------------------------------------------
;PUTS
;-----------------------------------------------------------
PUTS:   PUSH    AF
        PUSH    HL
        CALL    PUTS0
        POP     HL
        POP     AF
        RET
PUTS0:  LD      A,(HL)
        OR      A
        RET     Z

        CALL    PUTCHAR
        INC     HL
        JR      PUTS


;-----------------------------------------------------------
; TIMER 0 INTERRUPT HANDLER
;-----------------------------------------------------------
HTIMER0:;---------------------------------------------------
        ;SUBSYSTEM BUSY CHECK
        LD      HL,SUBIF
        LD      A,(HL)
        AND     080H
        JP      NZ,HTSBUSY      ;SUBSYSTEM BUSY
        ;---------------------------------------------------
        ;裏レジスタのPUSH
        EXX             ;B
        PUSH    BC
        PUSH    DE
        PUSH    HL
        EXX             ;A
        ;---------------------------------------------------
        ;SUBSYSTEM HALT
        LD      (HL),081H
HT01L:  LD      A,(HL)
        AND     080H
        JR      Z,HT01L
        ;---------------------------------------------------
        PUSH    HL
        LD      HL,KEYFLG       ;0:INKEYリクエスト後
                                ;2:画面表示後
        LD      A,(HL)
        OR      A
        JR      NZ,SCRCHK
        LD      (HL),2

        LD      A,(SHRMEM+4)
        OR      A
        JR      Z,SCRCHK
        LD      A,(SHRMEM+3)
        OR      A
        JR      Z,SCRCHK
        EXX                     ;B
        LD      C,A             ;C=KEY CODE
        ;---------------------------------------------------
        ;キーコードをキーバッファに追加する
        ;---------------------------------------------------
        LD      DE,(KBWPTR)     ;D=KBRPTR,E=KBWPTR
        ;次のポインタ値を計算する
        LD      A,E
        INC     A
        AND     1FH
        ;読み込みポインタと一致するとFULL
        CP      D
        JR      Z,KBFULL        ;BUFFER FULL
        LD      D,0
        LD      HL,KEYBUF
        ADD     HL,DE           ;ADD KBWPTR
        LD      (HL),C
        LD      (KBWPTR),A
KBFULL: EXX                     ;A
SCRCHK: DEC     (HL)
        JR      Z,KEYREQ
        ;---------------------------------------------------
        ;スクリーンバッファをチェックする
        ;---------------------------------------------------
        LD      BC,(SCWPTR)     ;B=SCRPTR,C=SCWPTR
        LD      A,B
        CP      C
        JR      Z,KEYREQ        ;OUTBUF IS EMPTY
        LD      HL,SCRBUF
        LD      D,0
        LD      E,B
        ADD     HL,DE
        LD      DE,SHRMEM+4     ;OUTPUT START
        LD      A,B             ;A=SCRPTR
        LD      B,C             ;C=SCWPTR
        LD      C,255
OUTLP:  LDI
        INC     A
        CP      120
        JR      C,OUTCHK1
        XOR     A
        LD      HL,SCRBUF
OUTCHK1:CP      B
        JR      NZ,OUTLP
        ;CARRY=0
        LD      (SCRPTR),A
        ;CALC CHAR COUNT
        EX      DE,HL
        LD      DE,SHRMEM+4
        SBC     HL,DE           ;L=count
        LD      H,L
        LD      L,3             ;PUT COMMAND
        LD      (SHRMEM+2),HL   ;SHRMEM+2:3,SHRMEM+3:count
        JR      HTSUBRST
        ;---------------------------------------------------
        ;スクリーンバッファが空の場合に入力チェック
        ;---------------------------------------------------
KEYREQ: LD      DE,0029H        ;INKEY WITH NO RESET NO WAIT
        LD      (SHRMEM+2),DE
        XOR     A
        LD      (KEYFLG),A
HTSUBRST:
        POP     HL
        LD      (HL),1          ;SUBSYSTEM RESTART
        ;---------------------------------------------------
        ;裏レジスタのPOP
        EXX             ;B
        POP     HL
        POP     DE
        POP     BC
        EXX             ;A
        ;---------------------------------------------------
HTSBUSY:
        RET

;-----------------------------------------------------------
;TOHEXA
;-----------------------------------------------------------
TOHEXA: PUSH    AF
        CALL    HEX1
        POP     AF
        PUSH    AF
        CALL    HEX2
        POP     AF
        RET
HEX1:   RRA
        RRA
        RRA
        RRA
HEX2:   OR      0F0H
        DAA
        ADD     A,0A0H
        ADC     A,040H
        JP      PUTCHAR

;-----------------------------------------------------------
;PUTCRLF
;-----------------------------------------------------------
PUTCRLF:LD      A,0DH
        CALL    PUTCHAR
        LD      A,10
        JP      PUTCHAR

WORKS   EQU     $
KEYFLG: DEFS    1       ;CONSOLE INPUT FLG
KBWPTR: DEFS    1
KBRPTR: DEFS    1
KEYBUF: DEFS    32
SCWPTR: DEFS    1
SCRPTR: DEFS    1
SCRBUF: DEFS    120
WORKE   EQU     $


;===========================================================

        ORG     0F660H
;-----------------------------------------------------------
; BIOS WORK AREA
;-----------------------------------------------------------
DMAADR: DEFS    2       ;last dma address

SEKDRV: DEFS    1       ;seek disk number
SEKTRK: DEFS    1       ;seek track number
SEKSEC: DEFS    1       ;seek sector number
SEKHST: DEFS    1       ;seek shr SECSHF

HSTDRV: DEFS    1       ;host disk number
HSTTRK: DEFS    1       ;host track number
HSTSEC: DEFS    1       ;host sector number

HSTACT: DEFS    1       ;host active flag
HSTWRT: DEFS    1       ;host written flag

UNACNT: DEFS    1       ;unalloc recorc count
UNADSK: DEFS    1       ;last unalloc disk
UNATRK: DEFS    1       ;last unalloc track
UNASEC: DEFS    1       ;last unalloc sector

ERRFLG: DEFS    1       ;error reporting
RSFLAG: DEFS    1       ;READ sector flag
READOP: DEFS    1       ;1 if READ operation
WRTYPE: DEFS    1       ;WRITE operation type
HSTBUF: DEFS    2       ;address of host buffer
HSTBUFH EQU     HSTBUF+1
RETRYCT:DEFS    1       ;retry counter
SAVESP: DEFS    2       ;
FDCSTAT:DEFS    1       ;FDC STATUS(ERROR)

        END
