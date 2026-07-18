;*******************************************************************************
; VAMPIRE TOOLBOX
;*******************************************************************************
; Macro.s
;
; Usefull macros
;
; Version 2.1 July 2026
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Copperlist macros

; Move a data to a register (CMOVE value,register)
CMOVE     MACRO
  dc.w    (\2)&$0ffe,\1
  ENDM

; New 32 bits move exclusively on V4 core (CMOVL value,register)
CMOVL     MACRO
  dc.w    $8000+((\2)&$0ffe),((\1)>>16)&$ffff,(\1)&$ffff
  ENDM
  
; Wait for a beam position (CWAIT x,y,[mask])
CWAIT     MACRO
  IFC     '','\3'
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,$fffe
  ELSEIF
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,(\3)&$fffe
  ENDC
  ENDM

; Skip the following instruction (CSKIP x,y,[mask])
CSKIP     MACRO
  IFC     '','\3'
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,$ffff
  ELSEIF
  dc.w    ((\2)&$ff)<<8!((\1)&$fe)!1,((\3)&$ffff)!1
  ENDC
  ENDM

; NO-OP instruction
CNOOP     MACRO
  dc.l    $01fe0000
  ENDM

; End of copperlist (CEND)
CEND      MACRO
  dc.l    $fffffffe
  ENDM

;*******************************************************************************

; Allocate a memory buffer (ALLOCMEM size,memtype,adrsave,onerror)
ALLOCMEM  MACRO
  move.l  $4.w,a6
  move.l  #\1,d0
  move.l  #\2,d1
  jsr     _AllocMem(a6)
  move.l  d0,\3
  beq     \4
  ENDM

; Free a memory buffer (FREEMEM size,adrsave)
FREEMEM   MACRO
  tst.l   \2
  beq.s   .NoMemory\@
  move.l  $4.w,a6
  move.l  #\1,d0
  move.l  \2,a1
  jsr     _FreeMem(a6)
  move.l  #0,\2
.NoMemory\@:
  ENDM
