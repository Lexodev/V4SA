;*******************************************************************************
; TemplateChunky.s
;
; Template file for Vampire program with chunky screen
;
; Version 2.1 July 2026
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Compile with : vasm -m68080 -devpac -Fhunkexe -o TemplateChunky TemplateChunky.s

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
SCREEN_WIDTH        = 640
SCREEN_HEIGHT       = 480
SCREEN_DEPTH        = 16
SCREEN_MODULO       = 0
SCREEN_MODE         = VRES_640x480+PIXF_R5G6B5

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

; Let's fill the screen buffers with some colors
.FillScreenBuffers:
  move.w  #$10,d0                       ; Start with a simple color value
  move.l  PhysicalScreen,a0             ; Our first buffer screen
  move.w  #$100,d1                      ; Start with a simple color value
  move.l  LogicalScreen,a1              ; Our second buffer screen
  move.w  #$1000,d2                     ; Start with a simple color value
  move.l  WaitScreen,a2                 ; Our third buffer screen
  
.FillIt:
  move.w  #SCREEN_HEIGHT-1,d7           ; 480 lines to do
.NextLine:
  move.w  #SCREEN_WIDTH-1,d6            ; 640 pixels on a line
.NextPixel:
  move.w  d0,(a0)+                      ; Write our pixel value
  addq.l  #1,d0                         ; Change the color value
  move.w  d1,(a1)+                      ; Write our pixel value
  addq.l  #1,d1                         ; Change the color value
  move.w  d2,(a2)+                      ; Write our pixel value
  addq.l  #1,d2                         ; Change the color value
  dbf     d6,.NextPixel
  dbf     d7,.NextLine

; Init the pause counter for a pause of 10 seconds
  move.w  #10*50,PauseCounter

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

  END
