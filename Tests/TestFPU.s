;*******************************************************************************
; Vampire tests
;*******************************************************************************
; TestFPU.s
;
; Test instructions FPU Vampire
;
; Version 1.0 September 2020
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

NULL                = 0
TRUE                = -1
FALSE               = 0
LF                  = $0A

_CloseLibrary       = -$19E
_OpenLibrary        = -$228
_PutStr             = -$3B4

; Dump a memory part (MEMDUMP start,len)
MEMDUMP   MACRO
  lea     \1,a0
  move.w  #\2,d0
  jsr     DumpMemory
  ENDM

; Dump registers (REGDUMP)
REGDUMP   MACRO
  jsr     DumpRegisters
  ENDM

;*******************************************************************************
  SECTION VAMPIRETEST,CODE
;*******************************************************************************

Start:
  movea.l $4.w,a6                       ; Exec library

.OpenDOSLib:
  lea     DOSLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open dos.library
  tst.l   d0
  beq     .EndInit                      ; Quit if not present
  move.l  d0,DOSBase                    ; Keep the pointer

  bsr     DoTheTest

.CloseDOSLib:
  movea.l $4.w,a6
  movea.l DOSBase,a1
  jsr     _CloseLibrary(a6)             ; Close DOS library

.EndInit:
  moveq.l #0,d0
  rts

;*******************************************************************************

DoTheTest:

  move.l  #12345,d0
  move.l  #3,d1
  fmove.l d0,fp0
  fdiv.l  d1,fp0
  fmove.l fp0,d0                        ; Result in D0 ($00001013)
  REGDUMP

  rts

;*******************************************************************************

;*******************************************************************************
; Dump memory content to the console
;   IN  : a0.l = start address
;         d0.w = number of bytes to dump
;*******************************************************************************
DumpMemory:
  movem.l d0-d2/a0-a1,-(sp)
  lea     DumpMemoryTitle,a1
  jsr     PrintString
  moveq.l #0,d1
  move.w  d0,d2
  subi.w  #1,d2
.DumpBlock:
  move.w  d1,d0
  andi.w  #$7,d0
  bne.s   .NoNewBlock
  jsr     PrintNewLine
  move.l  a0,d0
  bsr     LongToString
  lea     ConvertString,a1
  jsr     PrintString
  jsr     PrintBlockMark
.NoNewBlock:
  jsr     PrintSpace
  move.b  (a0)+,d0
  jsr     ByteToString
  lea     ConvertString,a1
  jsr     PrintString
  addq.l  #1,d1
  dbf     d2,.DumpBlock
.AllDone:
  jsr     PrintNewLine
  movem.l (sp)+,d0-d2/a0-a1
  rts

;*******************************************************************************
; Dump all registers content to the console
;*******************************************************************************
DumpRegisters:
  movem.l d0/a0-a1,-(sp)
  lea     DumpRegisterTitle,a1
  jsr     PrintString
  lea     RegisterNames,a0
.DumpD0A0:
  bsr     DumpRegisterValue
  move.l  4(sp),d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD1A1:
  move.l  d1,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  8(sp),d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD2A2:
  move.l  d2,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a2,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD3A3:
  move.l  d3,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a3,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD4A4:
  move.l  d4,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a4,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD5A5:
  move.l  d5,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a5,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD6A6:
  move.l  d6,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a6,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.DumpD7A7:
  move.l  d7,d0
  lea     8(a0),a0
  bsr     DumpRegisterValue
  move.l  a7,d0
  lea     6(a0),a0
  bsr     DumpRegisterValue
.AllDone:
  jsr     PrintNewLine
  movem.l (sp)+,d0/a0-a1
  rts

;*******************************************************************************
; Dump register content to the console
;   IN  : d0.l = value to dump
;         a0.l = register name
;*******************************************************************************
DumpRegisterValue:
  movem.l a0-a1,-(sp)
  movea.l a0,a1
  jsr     PrintString
  bsr     DumpLongValue
  movem.l (sp)+,a0-a1
  rts

;*******************************************************************************
; Dump byte to the console
;   IN  : d0.b = value to dump
;*******************************************************************************
DumpByteValue:
  move.l  a1,-(sp)
  bsr     ByteToString
  lea     ConvertString,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Dump word to the console
;   IN  : d0.w = value to dump
;*******************************************************************************
DumpWordValue:
  move.l  a1,-(sp)
  bsr     WordToString
  lea     ConvertString,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Dump long word to the console
;   IN  : d0.l = value to dump
;*******************************************************************************
DumpLongValue:
  move.l  a1,-(sp)
  bsr     LongToString
  lea     ConvertString,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Transform a byte value to a string
;   IN  : d0.b = value to transform
;*******************************************************************************
ByteToString:
  movem.l d0-d1/a0-a1,-(sp)
  lea     HexaValues,a0
  lea     ConvertString,a1
  move.b  #0,2(a1)
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),1(a1)
  ror.w   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),(a1)
  movem.l (sp)+,d0-d1/a0-a1
  rts

;*******************************************************************************
; Transform a word value to a string
;   IN  : d0.w = value to transform
;*******************************************************************************
WordToString:
  movem.l d0-d1/a0-a1,-(sp)
  lea     HexaValues,a0
  lea     ConvertString+4,a1
  move.b  #0,4(a1)
  move.w  #3,d7
.NextHexa:
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),-(a1)
  ror.w   #4,d0
  dbf     d7,.NextHexa
  movem.l (sp)+,d0-d1/a0-a1
  rts

;*******************************************************************************
; Transform a long value to a string
;   IN  : d0.l = value to transform
;*******************************************************************************
LongToString:
  movem.l d0-d1/a0-a1,-(sp)
  lea     HexaValues,a0
  lea     ConvertString+8,a1
  move.b  #0,(a1)
  move.w  #7,d7
.NextHexa:
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),-(a1)
  ror.l   #4,d0
  dbf     d7,.NextHexa
  movem.l (sp)+,d0-d1/a0-a1
  rts

;*******************************************************************************
; Print a new line
;*******************************************************************************
PrintNewLine:
  move.l  a1,-(sp)
  lea     NewLine,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Print a block mark
;*******************************************************************************
PrintBlockMark:
  move.l  a1,-(sp)
  lea     BlockMark,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Print a space
;*******************************************************************************
PrintSpace:
  move.l  a1,-(sp)
  lea     SpaceChar,a1
  jsr     PrintString
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Print a string to the console (DMA_BLITTER should be active)
;   IN  : a1.l = string address
;*******************************************************************************
PrintString:
  movem.l d0-a6,-(sp)
  move.l  a1,d1
  move.l  DOSBase,a6
  jsr     _PutStr(a6)
  movem.l (sp)+,d0-a6
  rts

;*******************************************************************************
  SECTION  VAMPIREDATA,DATA
;*******************************************************************************

DOSLib:
  dc.b    "dos.library",0

DumpMemoryTitle:
  dc.b    LF,'** Memory dump **',0

DumpRegisterTitle:
  dc.b    LF,'** Registers dump **',0

RegisterNames:
  dc.b    LF,'D0: ',0
  dc.b    '   A0: ',0
  dc.b    LF,'D1: ',0
  dc.b    '   A1: ',0
  dc.b    LF,'D2: ',0
  dc.b    '   A2: ',0
  dc.b    LF,'D3: ',0
  dc.b    '   A3: ',0
  dc.b    LF,'D4: ',0
  dc.b    '   A4: ',0
  dc.b    LF,'D5: ',0
  dc.b    '   A5: ',0
  dc.b    LF,'D6: ',0
  dc.b    '   A6: ',0
  dc.b    LF,'D7: ',0
  dc.b    '   A7: ',0

StatusRegisterName:
  dc.b    LF,'SR: ',0

NewLine:
  dc.b    LF,0

BlockMark:
  dc.b    ':',0

SpaceChar:
  dc.b    ' ',0

HexaValues:
  dc.b    '0','1','2','3','4','5','6','7'
  dc.b    '8','9','A','B','C','D','E','F'

ConvertString:
  dc.b    0,0,0,0,0,0,0,0,0

  EVEN

DOSBase:
  dc.l    0

  END
