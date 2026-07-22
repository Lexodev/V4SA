;*******************************************************************************
; BoingBall.s
;
; Boing ball SAGA demo screen
;
; Version 1.1 July 2026
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

  INCDIR  "Work:Sources/Projects/V4SA"

; Debug mode
MODE_DEBUG          = 1                 ; 0 inactive, 1 active

; Registers
  INCLUDE "Toolbox/Register.s"

; System
  INCLUDE "Toolbox/Constant.s"

; Macros
  INCLUDE "Toolbox/Macro.s"

; DMA activation
DMA_SET             = DMA_ON|DMA_COPPER
DMA_SET2            = DMA_STOP

; Interrupts activation
INT_SET             = INT_ON|INT_VERTB
INT_SET2            = INT_STOP

; Screen size
SCREEN_WIDTH        = 960
SCREEN_HEIGHT       = 540
SCREEN_DEPTH        = 24
SCREEN_MODULO       = 0
SCREEN_MODE         = VRES_960x540+PIXF_R8G8B8

;*******************************************************************************
  SECTION PROGRAM,CODE
;*******************************************************************************

Start:
  jsr     CheckV4Card                   ; Are we on a V4 card
  move.l  d0,LastError
  bne     Exit                          ; No let's get out

  jsr     SaveSystem                    ; Save system data
  move.l  d0,LastError
  bne     Restore                       ; Restore on error

  lea     CUSTOM,a6
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
  move.w  #DMA_STOP,DMACON2(a6)         ; Stop DMA 2
  move.w  #INT_STOP,INTENA(a6)          ; Stop interrupts
  move.w  #INT_STOP,INTENA2(a6)         ; Stop interrupts 2
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests
  move.w  #INT_STOP,INTREQ2(a6)         ; Stop requests 2

  move.w  #SAGA_ENABLE,FMODE(a6)        ; Enable SAGA features

.SetCopper:
  move.l  #CopperList,COP1LC(a6)        ; Our Copper list
  clr.w   COPJMP1(a6)                   ; Start it

.SetVBL:
  move.l  VbrBase,a0
  move.l  #VampireVbl,VEC_VBL(a0)       ; Set our VBL IT

  bsr     InitProgram                   ; Initialize the program

  lea     CUSTOM,a6
  move.w  #INT_SET,INTENA(a6)           ; VBL interrupt on
  move.w  #INT_SET2,INTENA2(a6)         ; VBL interrupt on
  move.w  #DMA_SET,DMACON(a6)           ; DMA channels
  move.w  #DMA_SET2,DMACON2(a6)         ; DMA channels

  move.w  #FALSE,ExitFlag

;*******************************************************************************
; This is the program main loop
;*******************************************************************************

MainLoop:
  jsr     WaitVbl
  
  bsr     UpdateProgram
  bsr     DrawProgram

  jsr     SwitchChunkyScreen

  tst.w   ExitFlag
  beq.s   MainLoop

;*******************************************************************************

ExitProgram:
  bsr     RestoreProgram

Restore:
  jsr     RestoreSystem

Exit:
  move.l  LastError,d0
  rts                                   ; Quit

;*******************************************************************************
; Initialize the program
;*******************************************************************************

InitProgram:
  jsr     OpenChunkyScreen              ; Open our screen

.InitBuffers:
  move.l  PhysicalScreen,a0             ; Our first buffer screen
  bsr     CopyBackground
  move.l  LogicalScreen,a0              ; Our second buffer screen
  bsr     CopyBackground
  move.l  WaitScreen,a0                 ; Our third buffer screen
  bsr     CopyBackground

; Init the pause counter for a pause of 10 seconds
  move.w  #10*50,PauseCounter

  rts

; Copy background to screen
;  a0 = screen address
CopyBackground:
  movem.l d6-d7/a0-a1,-(sp)
  lea     Background,a1
  move.w  #SCREEN_HEIGHT-1,d7
.NextLine:
  move.w  #SCREEN_WIDTH-1,d6
.NextPixel:
  move.w  (a1)+,(a0)+
  move.b  (a1)+,(a0)+
  dbf     d6,.NextPixel
  dbf     d7,.NextLine
  movem.l (sp)+,d6-d7/a0-a1
  rts

;*******************************************************************************
; Restore the program
;*******************************************************************************

RestoreProgram:
  rts

;*******************************************************************************
; Update the program
;*******************************************************************************

UpdateProgram:

; Decrement the pause counter until 0 then set exit flag
  move.w  PauseCounter,d1
  subi.w  #1,d1
  bne.s   .StillPause
  move.w  #TRUE,ExitFlag
.StillPause:
  move.w  d1,PauseCounter

; Another option could be to check for mouse button
;  btst    #MOUSE_BUTTON1,CIAA+CIAPRA
;  bne.s   .DoNotExit
;  move.w  #TRUE,ExitFlag
;.DoNotExit:

  rts

;*******************************************************************************
; Draw the program
;*******************************************************************************

DrawProgram:


  rts
  
;*******************************************************************************
; VBL
;*******************************************************************************

VampireVbl:
  movem.l d0-a6,-(sp)
; Add your own VBL process here
  move.w  #TRUE,VblFlag                 ; Set end of VBL
  move.w  #$20,CUSTOM+INTREQ            ; Release interrupt
  movem.l (sp)+,d0-a6
  rte

;*******************************************************************************
  SECTION COPPER,DATA_C
;*******************************************************************************
CopperList:
  CNOOP
CLEnd:
  CEND

;*******************************************************************************
; Vampire Toolbox functions
;*******************************************************************************

  INCLUDE "Toolbox/System.s"
  INCLUDE "Toolbox/Video.s"

;*******************************************************************************
  SECTION  GENERAL,DATA
;*******************************************************************************

; Last program error
LastError:
  dc.l    ERR_NONE

; Exit program flag
ExitFlag:
  dc.w    0

; Counter
PauseCounter:
  dc.w    0

; Background picture
Background:
  INCBIN  "BoingBall/assets/background.raw"

  END
