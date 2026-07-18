;*******************************************************************************
; VAMPIRE TOOLBOX
;*******************************************************************************
; Video.s
;
; Manage video system
;
; Version 2.1 July 2026
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

;*******************************************************************************
  SECTION VIDEOCODE,CODE
;*******************************************************************************

;*******************************************************************************
; Hide the mouse sprite
;*******************************************************************************
HideMouse:
  move.w  #0,CUSTOM+SPRHSTRT            ; Sprite start
  move.w  #0,CUSTOM+SPRHSTOP            ; Sprite stop
  move.l  #NullSprite,CUSTOM+SPRHPT     ; Sprite address
  rts

;*******************************************************************************
; Open the main screen
;*******************************************************************************
OpenChunkyScreen:
  move.l  d0,-(sp)
  move.l  #ScreenBuffer,d0              ; Screen buffer address
  addi.l  #31,d0
  andi.l  #~31,d0                       ; Now screen address is 32 bytes aligned
  move.l  d0,PhysicalScreen             ; Save it
  addi.l  #SCREEN_WIDTH*SCREEN_HEIGHT*(SCREEN_DEPTH/8),d0   ; Next buffer
  move.l  d0,LogicalScreen              ; Save it
  addi.l  #SCREEN_WIDTH*SCREEN_HEIGHT*(SCREEN_DEPTH/8),d0   ; Last buffer
  move.l  d0,WaitScreen                 ; Save it
.SetupScreen:
  move.w  #0,CUSTOM+BPLHMOD             ; Screen modulo
  move.l  PhysicalScreen,CUSTOM+BPLHPT  ; Set screen address
  move.w  #SCREEN_MODE,CUSTOM+GFXMODE   ; Set screen mode
  move.l  (sp)+,d0
  rts

;*******************************************************************************
; Wait for the VBL
;*******************************************************************************
VblWait:
  move.w  #0,VblFlag
.VblWait:
  tst.w   VblFlag
  beq.s   .VblWait
  rts

;*******************************************************************************
; Switch the screens
;*******************************************************************************
SwitchChunkyScreen:
  movem.l d0-d2/a0,-(sp)
  lea     PhysicalScreen,a0
  movem.l (a0),d0-d2
  exg     d0,d1
  exg     d1,d2
  movem.l d0-d2,(a0)
  move.l  PhysicalScreen,CUSTOM+BPLHPT  ; Set screen address
  movem.l (sp)+,d0-d2/a0
  rts

;*******************************************************************************
; Load a 32 bits colormap
;   IN  : d0.w = number of colors
;         d1.w = index of first color
;         a0.l = colors buffer address (32 bits format)
;         a1.l = color register
;*******************************************************************************
LoadSAGAColor:
  movem.l d0-d2/a0,-(sp)
  andi.l  #$ff,d1                       ; Clean color index
  ror.l   #8,d1                         ; Set color index on place
  subq.w  #1,d0                         ; Number of colors to load
.LoadColor:
  move.l  (a0)+,d2                      ; Get color value
  andi.l  #$ffffff,d2                   ; Clear high byte
  or.l    d1,d2                         ; Set color index
  move.l  d2,(a1)                       ; Load color value
  addi.l  #$1000000,d1                  ; Next color index
  dbf     d0,.LoadColor
  movem.l (sp)+,d0-d2/a0
  rts

;*******************************************************************************
; Load a 32 bits colormap for planar screen
;   IN  : d0.w = number of colors
;         d1.w = index of first color
;         a0.l = colors buffer address (32 bits format)
;*******************************************************************************
LoadPlanarColor:
  move.l  a1,-(sp)
  lea     CUSTOM+PLANARCOL,a1           ; Planar color register
  bsr.s   LoadSAGAColor
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Load a 32 bits colormap for sprites
;   IN  : d0.w = number of colors
;         d1.w = index of first color
;         a0.l = colors buffer address (32 bits format)
;*******************************************************************************
LoadSpriteColor:
  move.l  a1,-(sp)
  lea     CUSTOM+SPRITECOL,a1           ; Sprite color register
  bsr.s   LoadSAGAColor
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Load a 32 bits colormap for chunky screen
;   IN  : d0.w = number of colors
;         d1.w = index of first color
;         a0.l = colors buffer address (32 bits format)
;*******************************************************************************
LoadChunkyColor:
  move.l  a1,-(sp)
  lea     CUSTOM+CHUNKYCOL,a1           ; Chunky color register
  bsr.s   LoadSAGAColor
  move.l  (sp)+,a1
  rts

;*******************************************************************************
; Load a 32 bits colormap for PIP screen
;   IN  : d0.w = number of colors
;         d1.w = index of first color
;         a0.l = colors buffer address (32 bits format)
;*******************************************************************************
LoadPIPColor:
  move.l  a1,-(sp)
  lea     CUSTOM+PIPCOL,a1            ; Chunky color register
  bsr.s   LoadSAGAColor
  move.l  (sp)+,a1
  rts

;*******************************************************************************
  SECTION VIDEODATA,DATA
;*******************************************************************************

  CNOP    0,8                           ; Align on 8 bytes

; Empty sprite
NullSprite:
  dc.l    0,0,0,0,0,0,0,0

; Screen addresses
PhysicalScreen:
  dc.l    0
LogicalScreen:
  dc.l    0
WaitScreen:
  dc.l    0

;*******************************************************************************
  SECTION SCREEN,BSS
;*******************************************************************************

ScreenBuffer:
  ds.b    (SCREEN_WIDTH*SCREEN_HEIGHT*(SCREEN_DEPTH/8)*3)+32
