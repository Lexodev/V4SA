;*******************************************************************************
; Debugger.s
;
; Registers & memory dump
;
; Version 1.0 January 2021
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; EXEC functions
_CloseLibrary       = -$19E
_OpenLibrary        = -$228

; DOS functions
_PutStr             = -$3B4

; Special characters
DBG_NULL            = $00
DBG_EOL             = $0A
DBG_SPC             = ' '
DBG_SEP             = ':'

; Exec constants
EXEC_ATTNFLAGS      = $128
EXEC_AF68080        = $A

; Dump AMMX registers
AMMX_DUMP           = 1

; Some macros
PRINT   MACRO
  lea     \1,a1
  bsr     DBG_Print
  ENDM

PUTCHAR MACRO
  lea     DBGStringBuffer,a1
  move.b  #\1,(a1)
  move.b  #0,1(a1)
  bsr     DBG_Print
  ENDM

;*******************************************************************************
  SECTION DEBUGGERCODE,CODE
;*******************************************************************************

DBG_Start:
  movea.l $4.w,a6
  lea     DOSLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open dos.library
  tst.l   d0
  beq.s   DBG_Exit                      ; Quit if not present
  move.l  d0,DOSBase                    ; Keep the pointer
  bsr     DBG_RunTest
  movea.l $4.w,a6
  movea.l DOSBase,a1
  jsr     _CloseLibrary(a6)             ; Close dos.library
DBG_Exit
  moveq.l #0,d0
  rts

DBG_RunTest:
; Test memory dump
  lea     DBGHexaValue,a0
  move.l  #35,d0
  bsr     DBG_MemoryDump
  PUTCHAR DBG_EOL
; Test register dump
  move.l  #$42666FAB,d0
  move.l  #$42666FAB,d4
  move.l  #$42666FAB,d7
  move.l  #$42666FAB,A0
  move.l  #$42666FAB,A6
  bsr     DBG_RegistersDump
  IFNE    AMMX_DUMP
  PUTCHAR DBG_EOL
; Test AMMX dump
  load    #$FAB1747326012021,e1
  load    e1,e4
  load    #$FAB1747326012021,e7
  bsr     DBG_AmmxRegistersDump
  ENDC
  rts

;*******************************************************************************
; Print a string to the console (DMA_BLITTER should be active)
;   IN  : a1.l = string address
;*******************************************************************************
DBG_Print:
  movem.l d0-a6,-(sp)
  move.l  a1,d1
  move.l  DOSBase,a6
  jsr     _PutStr(a6)
  movem.l (sp)+,d0-a6
  rts

;*******************************************************************************
; Dump memory content to the console
;   IN  : a0.l = start address
;         d0.w = number of bytes to dump
;*******************************************************************************
DBG_MemoryDump:
  movem.l d0-a6,-(sp)
  PRINT   DBGMemoryTitle
  lea     DBGStringBuffer,a1
  moveq.l #0,d1
  move.w  d0,d2
  subi.w  #1,d2
.DumpBlock:
  move.w  d1,d0
  andi.w  #$7,d0                        ; Dump 8 bytes per line
  bne.s   .NoNewBlock
  move.b  #DBG_EOL,(a1)+
  move.b  #DBG_NULL,(a1)
  PRINT   DBGStringBuffer               ; After this PRINT we have a1=DBGStringBuffer
  move.l  a0,d0
  bsr     DBG_LongToString              ; Dump the address first
  move.b  #DBG_SEP,(a1)+
.NoNewBlock:
  move.b  #DBG_SPC,(a1)+
  move.b  (a0)+,d0
  bsr     DBG_ByteToString              ; Dump the memory content
  addq.l  #1,d1
  dbf     d2,.DumpBlock
  move.b  #DBG_EOL,(a1)+
  move.b  #DBG_NULL,(a1)
  PRINT   DBGStringBuffer               ; Print the last line
  movem.l (sp)+,d0-a6
  rts

;*******************************************************************************
; Dump M68K registers content to the console
;*******************************************************************************
DBG_RegistersDump:
  movem.l d0-a6,-(sp)
  movem.l d0-d7,DBGDataRegisterSave
  movem.l a0-a7,DBGAdrRegisterSave
  PRINT   DBGRegisterTitle
  lea     DBGRegisterName,a0
  lea     DBGStringBuffer,a1
  lea     DBGDataRegisterSave,a2
  lea     DBGAdrRegisterSave,a3
  move.w  #7,d7                         ; We have 8 data and 8 address registers to dump
.NextRegisterGroup:
  move.b  (a0)+,(a1)+
  move.b  (a0)+,(a1)+                   ; Data register name
  move.b  #DBG_SEP,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.l  (a2)+,d0
  bsr     DBG_LongToString
  move.b  #DBG_SPC,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.b  (a0)+,(a1)+
  move.b  (a0)+,(a1)+                   ; Adr register name
  move.b  #DBG_SEP,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.l  (a3)+,d0
  bsr     DBG_LongToString
  move.b  #DBG_EOL,(a1)+
  move.b  #DBG_NULL,(a1)
  PRINT   DBGStringBuffer               ; After this PRINT we have a1=DBGStringBuffer
  dbf     d7,.NextRegisterGroup
  movem.l (sp)+,d0-a6
  rts

  IFNE    AMMX_DUMP
;*******************************************************************************
; Dump AMMX registers content to the console
;*******************************************************************************
DBG_AmmxRegistersDump:
  movem.l d0-a6,-(sp)
  movea.l $4.w,a6                       ; Exec library
  move.w  EXEC_ATTNFLAGS(a6),d0         ; Flags ATTN Exec (CPU & FPU)
  btst    #EXEC_AF68080,d0              ; Check for 68080
  beq.s   .Not68080                     ; Don't try to dump AMMX register on a non 68080 proc
  lea     DBGAmmxRegisterSave,a0
  move.l  #40,d0                        ; Start with E0
  move.w  #7,d7                         ; Save 8 registers
.SaveNextRegister:
  storei  d0,(a0)+
  addq.l  #1,d0
  dbf     d7,.SaveNextRegister
  PRINT   DBGAmmxTitle
  lea     DBGAmmxRegisterName,a0
  lea     DBGStringBuffer,a1
  lea     DBGAmmxRegisterSave,a2
  move.w  #7,d7                         ; Dump 8 registers
.NextRegister:
  move.b  (a0)+,(a1)+
  move.b  (a0)+,(a1)+                   ; Register name
  move.b  #DBG_SEP,(a1)+
  move.b  #DBG_SPC,(a1)+
  move.l  (a2)+,d0
  bsr     DBG_LongToString              ; Dump first 32bits of register
  move.b  #DBG_SPC,(a1)+
  move.l  (a2)+,d0
  bsr     DBG_LongToString              ; Dump last 32bits of register
  move.b  #DBG_EOL,(a1)+
  move.b  #DBG_NULL,(a1)
  PRINT   DBGStringBuffer               ; After this PRINT we have a1=DBGStringBuffer
  dbf     d7,.NextRegister
  movem.l (sp)+,d0-a6
  rts
.Not68080:  
  PRINT   DBGAmmxTitle
  PRINT   AMMXError
  movem.l (sp)+,d0-a6
  rts
  ENDC

;*******************************************************************************
; Transform a byte value to a string
;   IN  : d0.b = value to transform
;         a1.l = buffer for the string
;*******************************************************************************
DBG_ByteToString:
  movem.l d0-d1/a0,-(sp)
  lea     DBGHexaValue,a0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),1(a1)
  ror.w   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),(a1)
  adda.l  #2,a1
  movem.l (sp)+,d0-d1/a0
  rts

;*******************************************************************************
; Transform a long value to a string
;   IN  : d0.l = value to transform
;         a1.l = buffer for the string
;*******************************************************************************
DBG_LongToString:
  movem.l d0-d1/a0,-(sp)
  lea     DBGHexaValue,a0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),7(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),6(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),5(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),4(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),3(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),2(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),1(a1)
  ror.l   #4,d0
  move.w  d0,d1
  andi.w  #$f,d1
  move.b  (a0,d1.w),(a1)
  adda.l  #8,a1
  movem.l (sp)+,d0-d1/a0
  rts

;*******************************************************************************
  SECTION  DEBUGGERDATA,DATA
;*******************************************************************************

  EVEN

; DOS library
DOSBase:
  dc.l    0

DOSLib:
  dc.b    'dos.library',0

AMMXError:
  dc.b    'You should have a 68080 to dump AMMX registers',DBG_EOL,DBG_NULL

  EVEN

; Buffer for string dump
DBGStringBuffer:
  dcb.b   256,0

DBGHexaValue:
  dc.b    '0','1','2','3','4','5','6','7'
  dc.b    '8','9','A','B','C','D','E','F'

; Title for memory dump
DBGMemoryTitle:
  dc.b    '** Memory dump **',DBG_EOL,DBG_NULL

; Title for m68k registers dump
DBGRegisterTitle:
  dc.b    '** M68K registers **',DBG_EOL,DBG_NULL

  EVEN

; Save space for registers
DBGDataRegisterSave:
  dcb.l    8,0
DBGAdrRegisterSave:
  dcb.l    8,0

DBGRegisterName:
  dc.b    'D0','AO','D1','A1','D2','A2','D3','A3'
  dc.b    'D4','A4','D5','A5','D6','A6','D7','A7'

  IFNE    AMMX_DUMP
; Title for AMMX registers dump
DBGAmmxTitle:
  dc.b    '** AMMX registers **',DBG_EOL,DBG_NULL

DBGAmmxRegisterName:
  dc.b    'E0','E1','E2','E3','E4','E5','E6','E7'

  EVEN

; Save space for AMMX registers
DBGAmmxRegisterSave:
  dcb.l    8*2,0
  ENDC

;*******************************************************************************
  SECTION  DEBUGGERBSS,BSS
;*******************************************************************************

DBGBuffer:
  ds.l    256
