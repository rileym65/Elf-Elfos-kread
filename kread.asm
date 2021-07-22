; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    ../bios.inc
include    ../kernel.inc

d_idewrite: equ    044ah
d_ideread:  equ    0447h

           org     8000h
           lbr     0ff00h
           db      'kread',0
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0
 
           org     2000h
           br      start

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

start:
           lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           bdf     loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    good                ; jump if filename given
           sep     scall               ; otherwise display usage message
           dw      o_inmsg
           db      'Usage: kread filename',10,13,0
           sep     sret                ; and return to os

good:      mov     rb,filename
           ghi     rf
           str     rb
           inc     rb
           glo     rf
           str     rb

           ldi     1                   ; setup sector address
           plo     r7
           mov     rf,kernel           ; point to memory to place kernel image
bootrd:    glo     r7                  ; save R7
           str     r2
           out     4
           dec     r2
           stxd
           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; call bios to read sector
           dw      d_ideread
           irx                         ; recover R7
           ldxa
           plo     r7
           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     15                  ; was last sector (16) read?
           lbnz    bootrd              ; jump if not

           mov     rb,filename         ; get filename pointer
           lda     rb
           phi     rf
           ldn     rb
           plo     rf
           ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     3                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           bnf     opened              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           lbr     o_wrmboot           ; and return to os
opened:    push    rd                  ; save file descriptor
           mov     rf,kernel           ; point to kernel data
           mov     rc,8192             ; 8k to write
           sep     scall               ; write it
           dw      o_write
           lbnf    written             ; jump if write was good
           sep     scall               ; indicate error
           dw      o_inmsg
           db      'Error writing to file',10,13,0
written:   pop     rd                  ; recover file descriptor
           sep     scall               ; close file
           dw      o_close
           lbr     o_wrmboot           ; and return to os


filename:  db      0,0
errmsg:    db      'File not found',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

buffer:    ds      20
cbuffer:   ds      80
dta:       ds      512

kernel:    ds      8192

