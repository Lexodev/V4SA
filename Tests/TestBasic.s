;*******************************************************************************
; TestBasic.s
;
; Test SAGA
;
; Version 1.0 November 2021
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Screen size
SCREEN_WIDTH        = 640
SCREEN_HEIGHT       = 480
SCREEN_DEPTH        = 16
SCREEN_MODE         = $0502

;*******************************************************************************
  SECTION PROGRAM,CODE
;*******************************************************************************

Start:
  
SagaSystemSave:                         ; Save system data

.SaveInterrupts:
  move.w  $DFF002,SaveDmacon
  ori.w   #$8000,SaveDmacon             ; Save DMA status
  move.w  #$7FFF,$DFF096                ; Stop DMA
  move.w  $DFF202,SaveDmacon+2
  ori.w   #$8000,SaveDmacon+2           ; Save DMA2 status
  move.w  #$7FFF,$DFF296                ; Stop DMA2
  move.w  $DFF01C,SaveIntena
  ori.w   #$8000,SaveIntena             ; Save IT status
  move.w  #$7FFF,$DFF09A                ; Stop IT
  move.w  $DFF21C,SaveIntena+2
  ori.w   #$8000,SaveIntena+2           ; Save IT2 status
  move.w  #$7FFF,$DFF29A                ; Stop IT2

.SaveScreen:
  move.w  $DFE1E6,SaveMod               ; Save screen modulo
  move.l  $DFE1EC,SaveScreen            ; Save the screen address
  move.w  $DFE1F4,SaveRes               ; Save screen resolution

.SetScreen:
  move.l  #ScreenBuffer,d0              ; Screen buffer address
  addi.l  #31,d0
  andi.l  #~31,d0                       ; Now screen address is 32 bytes aligned
  move.l  d0,PhysicalScreen             ; Save it

.SetupScreen:
  move.w  #0,$DFF1E6                    ; Screen modulo
  move.l  PhysicalScreen,$DFF1EC        ; Set screen address
  move.w  #SCREEN_MODE,$DFF1F4          ; Set screen mode

.HideMouse:
  move.w  #0,$DFF1D0                    ; Sprite start
  move.w  #0,$DFF1D2                    ; Sprite stop
  move.l  #NullSprite,$DFF1E8           ; Sprite address
  
; Let's fill the screen with some colors
.FillScreen:
  move.w  #$1,d0                        ; Start with a simple color value
  move.l  PhysicalScreen,a0             ; Our screen
  move.w  #SCREEN_HEIGHT-1,d7           ; 480 lines to do
.NextLine:
  move.w  #SCREEN_WIDTH-1,d6            ; 640 pixels on a line
.NextPixel:
  move.w  d0,(a0)+                      ; Write our pixel value
  addq.l  #1,d0                         ; Change the color value
  dbf     d6,.NextPixel
  dbf     d7,.NextLine

  move.w  #$8200,$DFF096                ; DMA channels
  move.w  #$C020,$DFF09A                ; VBL interrupt on

;*******************************************************************************

MainLoop:

.VblWait:
  btst    #5,$DFF01F
  beq     .VblWait
  move.w  #$0020,$DFF09C

  btst    #6,$BFE001
  bne.s   MainLoop

;*******************************************************************************

SagaSystemRestore:

.StopInterrupts:
  move.w  #$7FFF,$DFF096                ; Stop DMA
  move.w  #$7FFF,$DFF09A                ; Stop IT
  move.w  #$7FFF,$DFF296                ; Stop DMA2
  move.w  #$7FFF,$DFF29A                ; Stop IT2 
  move.w  SaveDmacon,$DFF096            ; Restore DMA
  move.w  SaveIntena,$DFF09A            ; Restore IT
  move.w  SaveDmacon+2,$DFF296          ; Restore DMA2
  move.w  SaveIntena+2,$DFF29A          ; Restore IT2

.RestoreScreen:
  move.w  SaveMod,$DFF1E6               ; Restore the screen modulo
  move.l  SaveScreen,$DFF1EC            ; Restore the screen address
  move.w  SaveRes,$DFF1F4               ; Restore screen resolution
  
Exit:
  move.l  #0,d0
  rts                                   ; Quit

;*******************************************************************************
  SECTION  GENERAL,DATA
;*******************************************************************************

; Save some system data
SaveIntena:
  dc.w    0,0
SaveDmacon:
  dc.w    0,0
SaveRes:
  dc.w    0
SaveMod:
  dc.w    0
SaveScreen:
  dc.l    0

; Physical screen address
PhysicalScreen:
  dc.l    0

; Empty sprite
NullSprite:
  dc.l    0

;*******************************************************************************
  SECTION SCREEN,BSS
;*******************************************************************************

ScreenBuffer:
  ds.b    (SCREEN_WIDTH*SCREEN_HEIGHT*(SCREEN_DEPTH/8))+32

  END
