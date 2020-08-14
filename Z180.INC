;*****************************************************
;*                                                   *
;* 64180/Z180 SPECIFIC                               *
;*                                                   *
;*****************************************************
;Programmable Reload Timer (PTR)  Registers
TMDR0L  EQU     0CH     ;Timer Data Register Ch 0 L
TMDR0H  EQU     0DH     ;Timer Data Register Ch 0 H
RLDR0L  EQU     0EH     ;Timer Reload Register Ch 0 L
RLDR0H  EQU     0FH     ;Timer Reload Register Ch 0 H
TCR     EQU     10H     ;Timer Control Register

TMDR1L  EQU     14H     ;Timer Data Register Ch 1 L
TMDR1H  EQU     15H     ;Timer Data Register Ch 1 H
RLDR1L  EQU     16H     ;Timer Reload Register Ch 1 L
RLDR1H  EQU     17H     ;Timer Reload Register Ch 1 H

FRC     EQU     18H     ;Free Running Counter

;DMA Registers
SAR0L   EQU     20H     ;DMA Source Address Register Ch 0L
SAR0H   EQU     21H     ;DMA Source Address Register Ch 0H
SAR0B   EQU     22H     ;DMA Source Address Register Ch 0B
DAR0L   EQU     23H     ;DMA Destination Address Register Ch 0L
DAR0H   EQU     24H     ;DMA Destination Address Register Ch 0H
DAR0B   EQU     25H     ;DMA Destination Address Register Ch 0B
BCR0L   EQU     26H     ;DMA Byte Count Register Ch 0L
BCR0H   EQU     27H     ;DMA Byte Count Register Ch 0H

MAR1L   EQU     28H     ;DMA Memory Address Register Ch 1L
MAR1H   EQU     29H     ;DMA Memory Address Register Ch 1H
MAR1B   EQU     2AH     ;DMA Memory Address Register Ch 1B
IAR1L   EQU     2BH     ;DMA I/0 Address Register Ch 1L
IAR1H   EQU     2CH     ;DMA I/0 Address Register Ch 1H
BCR1L   EQU     2EH     ;DMA Byte Count Register Ch 1L
BCR1H   EQU     2FH     ;DMA Byte Count Register Ch 1H

DSTAT   EQU     30H     ;DMA Status Register
DMODE   EQU     31H     ;DMA Mode Register
DCNTL   EQU     32H     ;DMA/WAIT Control Register

;Interrupt Registers
IL      EQU     33H     ;IL Register (Interrupt Vector Low Register)
ITC     EQU     34H     ;INT/TRAP Control Register

;Refresh Register
RCR     EQU     36H     ;Refresh Control Register

;MMU Registers
CBR     EQU     38H     ;MMU Common Base Register
BBR     EQU     39H     ;MMU Bank Base Register
CBAR    EQU     3AH     ;MMU Common/Bank Area Register

;I/O Registers
OMCR    EQU     3EH     ;Operation Mode Control Register
ICR     EQU     3FH     ;I/O Control Register

VPRT0_OFS       EQU     4      ;$24:PRT Channel 0 offset
