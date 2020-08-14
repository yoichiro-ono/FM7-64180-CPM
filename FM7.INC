;*****************************************************
;*                                                   *
;* FM-7 SPECIFIC                                     *
;*                                                   *
;*****************************************************
;I/O PORT
IRQMASK EQU     0FD02H          ;
IRQFLG  EQU     0FD03H          ;
SUBIF   EQU     0FD05H          ;

SHRMEM  EQU     0FC80H


;SYSTEM BIOS
BRESTOR EQU     0FE02H          ;HEAD RESTORE
BREAD   EQU     0FE08H          ;READ SECTOR

RCB     EQU     0FC00H          ;
ROMADRS EQU     0FC08H          ;
REGA    EQU     0FC0AH          ;

;-----------------------------------------------------------
;FDC
;-----------------------------------------------------------
FDCBSY  EQU     01H             ;BUSY BIT MASK
RDMSK   EQU     01CH            ;READ ERROR MASK
VERMSK  EQU     018H            ;VERIFY ERROR MASK
WTMSK   EQU     05CH            ;WRITE ERROR MASK


FDCBAS EQU      0FD18H          ;FDC PORT

CMDREG  EQU     0               ;COMMAND/STATUS REGISTER
TRKREG  EQU     1               ;TRACK REGISTER
SECREG  EQU     2               ;SECTOR REGISTER
DATREG  EQU     3               ;DATA REGISTER
HEDREG  EQU     4               ;HEAD REGISTER
DRVREG  EQU     5               ;DRIVE REGISTER
DRQIRQ  EQU     7               ;DRQ/IRQ REGISTER

RDSCMD  EQU     080H            ;READ SECTOR COMMAND
WTSCMD  EQU     0A0H            ;WRITE SECTOR COMMAND
RESCMD  EQU     00AH            ;RESTORE COMMAND
SEKCMD  EQU     01EH            ;SEEK COMMAND
FRCICM  EQU     0D0H            ;FORCE INTERRUPT
;HEAD REGISTER
;       +-----+-----+-----+-----+-----+-----+-----+-------+
;       |  7  |  6  |  5  |  4  |  3  |  2  |  1  |   0   |
;       +-----+-----+-----+-----+-----+-----+-----+-------+
;       |  1  |  1  |  1  |  1  |  1  |  1  |  1  | SIDE  |
;       |     |     |     |     |     |     |     |0:SIDE0|
;       |     |     |     |     |     |     |     |1:SIDE1|
;       +-----+-----+-----+-----+-----+-----+-----+-------+
;       FE:SIDE 0,FF:SIDE 1
;DRIVE REGISTER
;       +-----+-----+-----+-----+-----+-----+-----+-----+
;       |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
;       +-----+-----+-----+-----+-----+-----+-----+-----+
;       |MOTOR|  1  |  1  |  1  |  1  |  1  | DRIVE NO  |
;       |0:OFF|     |     |     |     |     +-----------+
;       |1:ON |     |     |     |     |     | DN1 | DN0 |
;       +-----+-----+-----+-----+-----+-----+-----+-----+
;       FC:DRIVE 0,MOTOR ON
;       7D:DRIVE 1,MOTOR OFF

;FDC STATUS
;       +-----+-----+-----+-----+-----+-----+-----+-----+
;       |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
;       +-----+-----+-----+-----+-----+-----+-----+-----+
;       | DRQ | IRQ |  1  |  1  |  1  |  1  |  1  |  1  |
;       |0:OFF|0:OFF|     |     |     |     |     |     |
;       |1:ON |1:ON |     |     |     |     |     |     |
;       +-----+-----+-----+-----+-----+-----+-----+-----+



;FDC STATUS
NOTRDY  EQU     0AH     ;DISK NOT READY
WRTPRT  EQU     0BH     ;DISK WRITE PROTECTED
HARDER  EQU     0CH     ;HARD ERROR
CRCERR  EQU     0DH     ;CRC ERROR
DDMERR  EQU     0EH     ;Delete Data Mark Detected
TIMOVR  EQU     0FH     ;TIME OUT

