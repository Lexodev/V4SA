;*******************************************************************************
; BoingBall.s
;
; Boing ball SAGA demo screen
;
; Version 1.0 November 2021
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Debug mode
MODE_DEBUG          = 1                 ; 0 inactive, 1 active

; Assemble settings
LTX_KEEPMULTI       = 0                 ; Keep multitask (0 = no, 1 = yes)
LTX_CHECKSYSTEM     = 0                 ; Check for system configuration (0 = no, 1 = yes)
LTX_VAMPIRE         = 0                 ; Assemble for V4 only

; Registers
  INCLUDE "Toolbox/Register.s"

; System
  INCLUDE "Toolbox/Constant.s"

; Macros
  INCLUDE "Toolbox/Macro.s"

; DMA activation
DMA_SET             = DMA_ON|DMA_BITPLANE|DMA_COPPER|DMA_SPRITE
DMA_SET2            = DMA_STOP

; Interrupts activation
INT_SET             = INT_ON|INT_VERTB
INT_SET2            = INT_STOP

; AGA Burst mode
BURST_SET           = BURST_BPL4

;*******************************************************************************
; Planar screen definition
;*******************************************************************************
SCREEN_WIDTH        = 320
SCREEN_HEIGHT       = 256
SCREEN_STARTX       = $80
SCREEN_STARTY       = $2C

;*******************************************************************************
; Playfield definition
;*******************************************************************************
PF_WIDTH            = 640
PF_HEIGHT           = 512
PF_DEPTH            = 8
PF_INTER            = 1                 ; 0 not interleave, 1 interleave
PF_LACED            = 1                 ; 0 not laced, 1 = laced
PF_LINE             = PF_WIDTH/8
PF_PLANE            = PF_LINE*PF_HEIGHT
PF_SIZE             = PF_PLANE*PF_DEPTH
PF_MOD              = PF_LINE*(PF_DEPTH-1)*PF_INTER+(PF_LACED*PF_LINE*PF_DEPTH)

;*******************************************************************************
; Boing ball sprite
;*******************************************************************************
BB_WIDTH            = 128
BB_HEIGHT           = 128
BB_PARTS            = 4
BB_FRAME            = 10
BB_TEMPO            = 5

;*******************************************************************************
  SECTION PROGRAM,CODE
;*******************************************************************************

Start:
  IFNE    LTX_VAMPIRE
  jsr     LTX_CheckV4Card               ; Are we on a V4 card
  tst.l   d0
  beq     Exit                          ; No let's get out
  ENDC
  
  jsr     LTX_SaveSystem                ; Save system data
  tst.l   d0
  beq     Restore                       ; Restore on error

  lea     CUSTOM,a6
.StopInterrupts:
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
  move.w  #INT_STOP,INTENA(a6)          ; Stop interrupts
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests
  IFNE    LTX_VAMPIRE
  move.w  #DMA_STOP,DMACON2(a6)         ; Stop DMA 2
  move.w  #INT_STOP,INTENA2(a6)         ; Stop interrupts 2
  move.w  #INT_STOP,INTREQ2(a6)         ; Stop requests 2
  ENDC

  move.w  #BURST_SET,FMODE(a6)          ; AGA burst mode
  IFNE    LTX_VAMPIRE
  ori.w   #SAGA_ENABLE,FMODE(a6)        ; Enable SAGA features
  ENDC

.SetVBL:
  move.l  VbrBase,a0
  move.l  #SagaVbl,VEC_VBL(a0)          ; Set our VBL IT

.SetCopper:
  move.l  #CopperList,COP1LC(a6)        ; Our Copper list
  clr.w   COPJMP1(a6)                   ; Start it

.Initialize:
  bsr     InitDemo                      ; Initialize the demo

.SetInterrupts:
  move.w  #DMA_SET,DMACON(a6)           ; DMA channels
  move.w  #INT_SET,INTENA(a6)           ; VBL interrupt on
  IFNE    LTX_VAMPIRE
  move.w  #DMA_SET2,DMACON2(a6)         ; DMA 2 channels
  move.w  #INT_SET2,INTENA2(a6)         ; No IT2
  ENDC

; Force long frame (because we are in interlace)
  move.w #$8000,VPOSW(a6)

;*******************************************************************************

MainLoop:
  move.w  #0,VblFlag
.VblWait:
  tst.w   VblFlag
  beq.s   .VblWait

  bsr     AnimateDemo

  btst    #MOUSE_BUTTON1,CIAA+CIAPRA    ; Mouse test
  bne.s   MainLoop

;*******************************************************************************

  bsr     RestoreDemo

Restore:
  jsr     LTX_RestoreSystem

Exit:
  move.l  #0,d0
  rts                                   ; Quit

;*******************************************************************************
; Initialize the demo
;*******************************************************************************

InitDemo:

  move.l  #ScreenBuffer,PhysicalScreen
.SetupPlanarScreen:
  lea     CLBitplaneAdr,a0              ; Copperlist bitplanes
  move.l  PhysicalScreen,d0             ; Our screen
  move.w  #BPL1PT,d1                    ; Bitplane register
  move.w  #PF_DEPTH-1,d7
.SetBplPointer:
  move.w  d1,(a0)+                      ; Register address
  swap    d0
  move.w  d0,(a0)+                      ; Bitplane address high
  addq.w  #2,d1                         ; Next register
  move.w  d1,(a0)+                      ; Regiter address
  swap    d0
  move.w  d0,(a0)+                      ; Bitplane address low
  addq.w  #2,d1                         ; Next register
  IFEQ    PF_INTER
  addi.l  #PF_PLANE,d0                  ; Next bitplane (not interleave)
  ELSEIF
  addi.l  #PF_LINE,d0                   ; Next bitplane (interleave)
  ENDC
  dbf     d7,.SetBplPointer
.SetupSprites:
  lea     CLSpriteAdr,a0                ; Copperlist sprites
  move.l  #DefaultSprite,d0             ; Empty sprite
  move.w  #SPR_MAXSPRITE-1,d1           ; 8 sprites
.SetSpritePtr:
  move.w  d0,6(a0)                      ; Sprite address low
  swap    d0
  move.w  d0,2(a0)                      ; Sprite address high
  swap    d0
  adda.l  #8,a0
  dbf     d1,.SetSpritePtr

  bsr     PrepareBackground
  bsr     PrepareSprites

  rts

; Prepare background
PrepareBackground:
  lea     Amiga1000,a0
  lea     PaletteBuffer,a1
  movea.l PhysicalScreen,a2             ; Unpack directly on screen
  jsr     LTX_DecodePicture
  tst.l   d0
  beq     .DecodeError
.LoadPalette:
  move.w  #256,d0
  move.w  #0,d1
  movea.l a1,a0
  jsr     LTX_SetAGAPalette
.DecodeError:
  rts

; Prepare sprites
PrepareSprites:
  moveq.l #1,d1
  lea     BoingBallPictures,a6
  move.w  #BB_FRAME-1,d7
.NextPicture:
  movea.l (a6)+,a0
  lea     PaletteBuffer,a1
  lea     BBallBuffer,a2
  jsr     LTX_DecodePicture
; Load sprite pal
; Setup sprite data
  addq.l  #1,d1
  dbf     d7,.NextPicture
  rts

;*******************************************************************************
; Restore the demo
;*******************************************************************************

RestoreDemo:
  rts

;*******************************************************************************
; Animate the screen
;*******************************************************************************

AnimateDemo:
  rts

;*******************************************************************************
; VBL
;*******************************************************************************

SagaVbl:
  movem.l d0-a6,-(sp)
  move.w  #-1,VblFlag                   ; Set end of VBL

.SetupDisplayFrame:
  move.l  PhysicalScreen,d0             ; Our screen
  btst    #7,CUSTOM+VPOSR
  bne.s   .LongFrame
  addi.l  #PF_LINE*PF_DEPTH,d0          ; Odd frame
.LongFrame:
  lea     CLBitplaneAdr,a0              ; Copperlist bitplanes
  move.w  #BPL1PT,d1                    ; Bitplane register
  move.w  #PF_DEPTH-1,d7
.SetBplPointer:
  move.w  d1,(a0)+                      ; Register address
  swap    d0
  move.w  d0,(a0)+                      ; Bitplane address high
  addq.w  #2,d1                         ; Next register
  move.w  d1,(a0)+                      ; Regiter address
  swap    d0
  move.w  d0,(a0)+                      ; Bitplane address low
  addq.w  #2,d1                         ; Next register
  IFEQ    PF_INTER
  addi.l  #PF_LINE*PF_HEIGHT,d0         ; Next bitplane (not interleave)
  ELSEIF
  addi.l  #PF_LINE,d0                   ; Next bitplane (interleave)
  ENDC
  dbf     d7,.SetBplPointer

.EndVbl:
  move.w  #$20,CUSTOM+INTREQ            ; Release interrupt
  movem.l (sp)+,d0-a6
  rte

;*******************************************************************************
  SECTION  GENERAL,DATA
;*******************************************************************************

VblFlag:
  dc.w    0

; Physical screen address
PhysicalScreen:
  dc.l    0

; Boing ball animation
BBallCurrentFrame:
  dc.w    0
BBallAnimTempo:
  dc.w    BB_TEMPO

BBallAnim:
  dc.l    BBallFrames

BBallFrames:
  dc.l    BBall1SprData,BBall2SprData,BBall3SprData,BBall4SprData,BBall5SprData
  dc.l    BBall6SprData,BBall7SprData,BBall8SprData,BBall9SprData,BBall10SprData
  dc.l    0

; Background picture
Amiga1000:
  INCBIN  "assets/A1000.iff"

BoingBallPictures:
  dc.l    BoingBall1,BoingBall2,BoingBall3,BoingBall4,BoingBall5
  dc.l    BoingBall6,BoingBall7,BoingBall8,BoingBall9,BoingBall10

BoingBallBuffers:
  dc.l    BBall1SprData,BBall2SprData,BBall3SprData,BBall4SprData,BBall5SprData
  dc.l    BBall6SprData,BBall7SprData,BBall8SprData,BBall9SprData,BBall10SprData

; Boing balls
  EVEN
BoingBall1:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall2:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall3:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall4:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall5:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall6:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall7:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall8:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall9:
  INCBIN  "assets/bball1.iff"
  EVEN
BoingBall10:
  INCBIN  "assets/bball1.iff"

;*******************************************************************************
  SECTION PICBUFFER,BSS
;*******************************************************************************
PaletteBuffer:
  ds.l    256

BBallBuffer:
  ds.b    320*200/2                     ; Picture of 320x200 in 16 colors

;*******************************************************************************
  SECTION SCREEN,BSS_C
;*******************************************************************************
  CNOP    0,8                           ; Align on 8 bytes (FMODE constraint)
ScreenBuffer:
  ds.b    PF_SIZE

; Boing balls sprite data (10 frames)
  CNOP    0,64
BBall1SprData:
  REPT    BB_HEIGHT*BB_PARTS            ; 4 sprites for a ball
  ds.l    0,0,0,0
  ENDR

BBall2SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall3SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall4SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall5SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall6SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall7SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall8SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall9SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

BBall10SprData:
  REPT    BB_HEIGHT*BB_PARTS
  ds.l    0,0,0,0
  ENDR

;*******************************************************************************
  SECTION SPRITE,DATA_C
;*******************************************************************************
  CNOP    0,8                           ; Align on 8 bytes (FMODE constraint)
DefaultSprite:
  dc.l    0,0,0,0

BBallSprite0:
  dc.l    0,0,0,0
BBallSprite1:
  dc.l    0,0,0,0
BBallSprite2:
  dc.l    0,0,0,0
BBallSprite3:
  dc.l    0,0,0,0

;*******************************************************************************
  SECTION COPPER,DATA_C
;*******************************************************************************
CopperList:
  CMOVE   (SCREEN_STARTY<<8)|(SCREEN_STARTX+1),DIWSTRT
  CMOVE   (((SCREEN_STARTY+SCREEN_HEIGHT)&$FF)<<8)|((SCREEN_STARTX+SCREEN_WIDTH+1)&$FF),DIWSTOP
CLSpriteAdr:
  CMOVE   $0000,SPR0PTH
  CMOVE   $0000,SPR0PTL
  CMOVE   $0000,SPR1PTH
  CMOVE   $0000,SPR1PTL
  CMOVE   $0000,SPR2PTH
  CMOVE   $0000,SPR2PTL
  CMOVE   $0000,SPR3PTH
  CMOVE   $0000,SPR3PTL
  CMOVE   $0000,SPR4PTH
  CMOVE   $0000,SPR4PTL
  CMOVE   $0000,SPR5PTH
  CMOVE   $0000,SPR5PTL
  CMOVE   $0000,SPR6PTH
  CMOVE   $0000,SPR6PTL
  CMOVE   $0000,SPR7PTH
  CMOVE   $0000,SPR7PTL
CLPalette:
  CMOVE   $0000,COLOR00
CLScreenDef:
  CWAIT   $0001,SCREEN_STARTY-2
  CMOVE   $0038,DDFSTRT
  CMOVE   $00C0,DDFSTOP
  CMOVE   $8215,BPLCON0                 ; 256 colors high res
  CMOVE   $0000,BPLCON1
  CMOVE   $0224,BPLCON2                 ; Sprites prio over PF1 & PF2, no EHB
  CMOVE   $0C60,BPLCON3                 ; Border blank, sprite low-res
  CMOVE   $0011,BPLCON4
  CMOVE   PF_MOD,BPL1MOD
  CMOVE   PF_MOD,BPL2MOD
CLBitplaneAdr:
  REPT    PF_DEPTH
  CMOVE   $0000,$0000
  CMOVE   $0000,$0000
  ENDR
CLEnd:
  CEND

;*******************************************************************************
; Lexo Toolbox functions
;*******************************************************************************

  INCLUDE "Toolbox/System.s"
  INCLUDE "Toolbox/Saga.s"
  INCLUDE "Toolbox/IFFTool.s"
;  INCLUDE "Toolbox/Math.s"
;  INCLUDE "Toolbox/Input.s"
;  INCLUDE "Toolbox/ModPlayer.s"
;  INCLUDE "Toolbox/Debug.s"

  END
