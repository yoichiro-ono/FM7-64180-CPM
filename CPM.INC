;*****************************************************
;*                                                   *
;*         CP/M to host disk constants               *
;*                                                   *
;*****************************************************
BLKSIZ	EQU	2048	        ;CP/M allocation size
HSTSIZ	EQU	256	        ;host disk sector size
HSTSPT	EQU	32	        ;host disk sectors/trk
HSTBLK	EQU	HSTSIZ/128	;CP/M sects/host buff
CPMSPT	EQU	HSTBLK * HSTSPT
SECMSK	EQU	HSTBLK-1	;sector mask
SECSHF	EQU	1	        ;log2(HSTBLK)
;
;*****************************************************
;*                                                   *
;*        BDOS constants on entry to WRITE           *
;*                                                   *
;*****************************************************
WRALL	EQU	0	;WRITE to allocated
WRDIR	EQU	1	;WRITE to directory
WRUAL	EQU	2	;WRITE to unallocated


CPMBASE EQU     0E000H
CPMBDOS EQU     0E806H
