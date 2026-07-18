;*******************************************************************************
; TestPlanar.s
;
; Test SAGA planar screen
;
; Version 1.0 November 2021
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Debug mode
MODE_DEBUG          = 1       ; 0 inactive, 1 active

; Program errors
ERR_NONE            = 0
ERR_NOT080          = 1
ERR_NOTV4           = 2
ERR_DOSLIB          = 3
ERR_GFXLIB          = 4

; Base address
CUSTOM    = $DFF000

; Registers offset
DMACONR   = $002              ; DMA control (and blitter status) read
INTENAR   = $01C              ; Interrupt enable bits read
INTREQR   = $01E              ; Interrupt request bits read
COP1LC    = $080              ; Coprocessor 1st location
COPJMP1   = $088              ; Coprocessor restart at 1st location
DIWSTRT   = $08E              ; Display window start (upper left vert,horiz pos)
DIWSTOP   = $090              ; Display window stop (lower right vert,horiz pos)
DDFSTRT   = $092              ; Display bit plane data fetch start,horiz pos
DDFSTOP   = $094              ; Display bit plane data fetch stop,horiz pos
DMACON    = $096              ; DMA control write (clear or set)
INTENA    = $09A              ; Interrupt enable bits (clear or set bits)
INTREQ    = $09C              ; Interrupt request bits (clear or set bits)
BPL1PT    = $0E0              ; Bitplane pointer 1
BPLCON0   = $100              ; Bitplane control (miscellaneous control bits)
BPLCON1   = $102              ; Bitplane control (scroll value)
BPLCON2   = $104              ; Bitplane control (video priority control)
BPLCON3   = $106              ; Bitplane control (enhanced features)
BPL1MOD   = $108              ; Bitplane modulo (odd planes)
BPL2MOD   = $10A              ; Bitplane modulo (even planes)
BPLCON4   = $10C              ; Bitplane control (bitplane and sprite-masks)
SPR0PTH       = $120          ; Sprite 0 pointer (high 5 bits was 3 bits)
SPR0PTL       = $122          ; Sprite 0 pointer (low 15 bits)
SPR1PTH       = $124          ; Sprite 1 pointer (high 5 bits was 3 bits)
SPR1PTL       = $126          ; Sprite 1 pointer (low 15 bits)
SPR2PTH       = $128          ; Sprite 2 pointer (high 5 bits was 3 bits)
SPR2PTL       = $12A          ; Sprite 2 pointer (low 15 bits)
SPR3PTH       = $12C          ; Sprite 3 pointer (high 5 bits was 3 bits)
SPR3PTL       = $12E          ; Sprite 3 pointer (low 15 bits)
SPR4PTH       = $130          ; Sprite 4 pointer (high 5 bits was 3 bits)
SPR4PTL       = $132          ; Sprite 4 pointer (low 15 bits)
SPR5PTH       = $134          ; Sprite 5 pointer (high 5 bits was 3 bits)
SPR5PTL       = $136          ; Sprite 5 pointer (low 15 bits)
SPR6PTH       = $138          ; Sprite 6 pointer (high 5 bits was 3 bits)
SPR6PTL       = $13A          ; Sprite 6 pointer (low 15 bits)
SPR7PTH       = $13C          ; Sprite 7 pointer (high 5 bits was 3 bits)
SPR7PTL       = $13E          ; Sprite 7 pointer (low 15 bits)
COLOR00   = $180              ; Color table 0
COLOR01   = $182              ; Color table 1
FMODE     = $1FC              ; Fetch mode register
DMACON2R  = $202              ; DMA2 control (and blitter status) read
INTENA2R  = $21C              ; Interrupt enable bits read
INTREQ2R  = $21E              ; Interrupt request bits read
DMACON2   = $296              ; DMA2 control write (clear or set)
INTENA2   = $29A              ; Interrupt enable bits (clear or set bits)
INTREQ2   = $29C              ; Interrupt request bits (clear or set bits)
BPLHMOD   = $1E6              ; Chunky plane modulo
BPLHPT    = $1EC              ; Chunky plane pointer
GFXMODE   = $1F4              ; Set Resolution and Pixel format
PLANARCOL = $380              ; 32bit Planar COLOR Port register, Format [ID,RR,GG,BB]
SPRITECOL = $384              ; 32bit Sprite COLOR Port register
VAMPVERS  = $3FC              ; 8bit Card Version / 8bit clock multiplier

; Base address
CIAA      = $BFE001

; Registers offset
CIAPRA    = $000

; Joystick / mouse
MOUSE_BUTTON1       = 6
MOUSE_BUTTON2       = 2
JOY_BUTTON1         = 7

; SAGA enable
SAGA_ENABLE         = $1C

; Exec constants
EXEC_ATTNFLAGS      = $128
EXEC_AF68080        = $A

; Graphics constants
GFX_ACTIVEVIEW      = $22
GFX_COPPERLIST      = $26

; DMA channels
DMA_ON              = $8200
DMA_OFF             = $0200
DMA_NASTYBLIT       = $0400
DMA_BITPLANE        = $0100
DMA_COPPER          = $0080
DMA_BLITTER         = $0040
DMA_SPRITE          = $0020
DMA_DISK            = $0010
DMA_AUDIO3          = $0008
DMA_AUDIO2          = $0004
DMA_AUDIO1          = $0002
DMA_AUDIO0          = $0001
DMA_AUDIOFULL       = DMA_AUDIO0|DMA_AUDIO1|DMA_AUDIO2|DMA_AUDIO3
DMA_AUDIO7          = $0008
DMA_AUDIO6          = $0004
DMA_AUDIO5          = $0002
DMA_AUDIO4          = $0001
DMA_AUDIOFULL2      = DMA_AUDIO4|DMA_AUDIO5|DMA_AUDIO6|DMA_AUDIO7
DMA_STOP            = $7FFF

; DMA activation
DMA_SET             = DMA_ON|DMA_COPPER|DMA_BITPLANE
DMA_SET2            = DMA_STOP

; Interrupts vectors
VEC_KBD             = $68
VEC_VBL             = $6C

; Interruptions
INT_ON              = $C000
INT_OFF             = $4000
INT_EXTER           = $2000
INT_DSKSYN          = $1000
INT_RBF             = $0800
INT_AUD3            = $0400
INT_AUD2            = $0200
INT_AUD1            = $0100
INT_AUD0            = $0080
INT_BLIT            = $0040
INT_VERTB           = $0020
INT_COPER           = $0010
INT_PORTS           = $0008
INT_SOFT            = $0004
INT_DSKBLK          = $0002
INT_STOP            = $7FFF

; Interrupts activation
INT_SET             = INT_ON|INT_VERTB

; Card versions
CARD_V600           = 1
CARD_V500           = 2
CARD_V4_500         = 3
CARD_V1200          = 4
CARD_V4SA           = 5

; EXEC functions
_ExecBase           = $4
_Supervisor         = -$1E
_Forbid             = -$84
_Permit             = -$8A
_CloseLibrary       = -$19E
_OpenLibrary        = -$228

; GRAPHICS functions
_LoadView           = -$DE
_WaitBlit           = -$E4
_WaitTOF            = -$10E

; Sprites
SPR_MAXSPRITE       = 8

; Screen size
SCREEN_WIDTH        = 320
SCREEN_HEIGHT       = 256
SCREEN_STARTX       = $80
SCREEN_STARTY       = $2C

PF_WIDTH            = 320
PF_HEIGHT           = 256
PF_DEPTH            = 4
PF_INTER            = 1                 ; 0 not interleave, 1 interleave 
PF_LINE             = PF_WIDTH/8
PF_PLANE            = PF_LINE*PF_HEIGHT
PF_SIZE             = PF_PLANE*PF_DEPTH
PF_MOD              = (PF_WIDTH/8)*(PF_DEPTH-1)*PF_INTER

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
  SECTION PROGRAM,CODE
;*******************************************************************************

Start:
;  jsr     CheckV4Card                   ; Are we on a V4 card
;  tst.l   LastError
;  bne     Exit                          ; No let's get out

  jsr     SagaSystemSave                ; Save system data
  tst.l   LastError
  bne     Restore                       ; Restore on error

  lea     CUSTOM,a6
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
;  move.w  #DMA_STOP,DMACON2(a6)         ; Stop DMA 2
  move.w  #INT_STOP,INTENA(a6)          ; Stop interrupts
;  move.w  #INT_STOP,INTENA2(a6)         ; Stop interrupts 2
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests
;  move.w  #INT_STOP,INTREQ2(a6)         ; Stop requests 2

;  move.w  #SAGA_ENABLE,FMODE(a6)        ; Enable SAGA features

.SetVBL:
  move.l  VbrBase,a0
  move.l  #SagaVbl,VEC_VBL(a0)          ; Set our VBL IT

.SetCopper:
  move.l  #CopperList,COP1LC(a6)        ; Our Copper list
  clr.w   COPJMP1(a6)                   ; Start it

  bsr     InitDemo                      ; Initialize the demo

  lea     CUSTOM,a6
  move.w  #INT_SET,INTENA(a6)           ; VBL interrupt on
  move.w  #DMA_SET,DMACON(a6)           ; DMA channels

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
  jsr     SagaSystemRestore
  
Exit:
  move.l  LastError,d0
  rts                                   ; Quit

;*******************************************************************************
; Initialize the demo
;*******************************************************************************

InitDemo:
  move.l  #ScreenBuffer,d0              ; Screen buffer address
  addi.l  #31,d0
  andi.l  #~31,d0                       ; Now screen address is 32 bytes aligned
  move.l  d0,PhysicalScreen             ; Save it

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
  addq.w  #2,d1                         ; Registre suivant
  IFEQ    PF_INTER
  addi.l  #PF_WIDTH/8*PF_HEIGHT,d0      ; Next bitplane (not interleave)
  ELSEIF
  addi.l  #PF_WIDTH/8,d0                ; Next bitplane (interleave)
  ENDC
  dbf     d7,.SetBplPointer

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

  move.l  PhysicalScreen,a0
  move.l  #$12345678,d1
  move.w  #(PF_SIZE/4)-1,d0
.FillScreen:
  move.l  d1,(a0)+
  rol.l   #1,d1
  addi.l  #$01020304,d1
  dbf     d0,.FillScreen  

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
; Check if this is a V4 card
;*******************************************************************************

CheckV4Card:
  movea.l _ExecBase,a6                  ; EXEC library

.Check68080:
  move.w  EXEC_ATTNFLAGS(a6),d0         ; Flags ATTN EXEC (CPU & FPU)
  btst    #EXEC_AF68080,d0              ; Check for 68080
  bne.s   .CheckCard                    ; Yes
  move.l  #ERR_NOT080,LastError         ; No 68080 available
  rts

.CheckCard:
  move.w  CUSTOM+VAMPVERS,d0            ; Card version
  lsr.w   #$8,d0                        ; Keep only version
  cmpi.b  #CARD_V4SA,d0                 ; V4SA card ?
  beq.s   .V4                           ; Yes
  move.l  #ERR_NOTV4,LastError          ; No V4 available
  rts

.V4:
  move.l  #ERR_NONE,LastError           ; This is a V4 card
  rts

;*******************************************************************************
; Save system data
;*******************************************************************************

SagaSystemSave:

  IFEQ    MODE_DEBUG
  movea.l _ExecBase,a6                  ; EXEC library
  jsr     _Forbid(a6)                   ; Stop multitask
  ENDC

.OpenDOSLib:
  movea.l _ExecBase,a6                  ; EXEC library
  lea     DOSLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open DOS.library
  move.l  d0,DOSBase                    ; Keep the pointer
  bne.s   .OpenGraphicsLib              ; Open next lib
  move.l  #ERR_DOSLIB,LastError         ; No DOS lib available
  rts

.OpenGraphicsLib:
  movea.l _ExecBase,a6                  ; EXEC library
  lea     GraphicsLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open GRAPHICS.library
  move.l  d0,GfxBase                    ; Keep the pointer
  bne.s   .SaveSystem                   ; All libs are open
  move.l  #ERR_GFXLIB,LastError         ; No GRAPHICS lib available
  rts

.SaveSystem:
  lea     CUSTOM,a6

.SaveInterrupts:
  move.w  DMACONR(a6),SaveDmacon
  ori.w   #$8100,SaveDmacon             ; Save DMA status
;  move.w  DMACON2R(a6),SaveDmacon+2
;  ori.w   #$8100,SaveDmacon+2           ; Save DMA 2 status
  move.w  INTENAR(a6),SaveIntena
  ori.w   #$C000,SaveIntena             ; Save IT status
;  move.w  INTENA2R(a6),SaveIntena+2
;  ori.w   #$C000,SaveIntena+2           ; Save IT 2 status

.SaveScreen:
;  move.w  GFXMODE(a6),SaveRes           ; Save screen resolution
;  move.w  BPLHMOD(a6),SaveMod           ; Save screen modulo
;  move.l  BPLHPT(a6),SaveScreen         ; Save the screen address

  movea.l GfxBase,a6                    ; GRAPHICS base
.ReserveBlitter:
  jsr     _WaitBlit(a6)                 ; Wait end of Blitter activity

.SaveCopper:
  move.l  GFX_COPPERLIST(a6),SaveCopper ; Save current copper list

.ResetView:
  move.l  GFX_ACTIVEVIEW(a6),SaveView   ; Save the current view
  suba.l  a1,a1
  jsr     _LoadView(a6)                 ; Load an empty view
  jsr     _WaitTOF(a6)
  jsr     _WaitTOF(a6)                  ; Two wait for interlaced screens

; We are on a 68080, let's get the VBR
.GetVectorBase:
  movea.l _ExecBase,a6                  ; EXEC library
  lea     SagaGetVBR,a5
  jsr     _Supervisor(a6)
  move.l  d0,VbrBase                    ; Save VBR

.SaveVectors:
  movea.l VbrBase,a0                    ; Save current interrupts vectors
  move.l  VEC_KBD(a0),SaveKeyboard      ; Keyboard
  move.l  VEC_VBL(a0),SaveVbl           ; VBL

.NoError:
  move.l  #ERR_NONE,LastError           ; Everything is ok
  rts

SagaGetVBR:
  dc.l    $4E7A0801                     ; Opcode for "movec VBR,d0"
  rte

;*******************************************************************************
; Restore system data
;*******************************************************************************

SagaSystemRestore:

  tst.l   GfxBase
  beq    .CloseDOSLib                  ; GRAPHICS library is not open

  tst.l   DOSBase
  beq    .RestoreEnd                   ; DOS library is not open

.RestoreSystem:
  lea     CUSTOM,a6

.StopInterrupts:
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
;  move.w  #DMA_STOP,DMACON2(a6)         ; Stop DMA 2
  move.w  #INT_STOP,INTENA(a6)          ; Stop interruptions
;  move.w  #INT_STOP,INTENA2(a6)         ; Stop interruptions 2
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests
;  move.w  #INT_STOP,INTREQ2(a6)         ; Stop requests 2

.RestoreVectors:
  move.l  VbrBase,a0                    ; Restore vectors
  move.l  SaveKeyboard,VEC_KBD(a0)      ; Keyboard
  move.l  SaveVbl,VEC_VBL(a0)           ; VBL

  lea     CUSTOM,a6

.RestoreCopper:
  move.l  SaveCopper,COP1LC(a6)         ; Restore Copper list

.RestoreView:
  movea.l GfxBase,a6
  movea.l SaveView,a1
  jsr     _LoadView(a6)                 ; Restore view
  jsr     _WaitTOF(a6)
  jsr     _WaitTOF(a6)                  ; Two times for interlaced screens

.FreeBlitter:
  jsr     _WaitBlit(a6)                 ; Wait end of Blitter activity

  lea     CUSTOM,a6

.RestoreScreen:
;  move.l  SaveScreen,BPLHPT(a6)         ; Restore the screen address
;  move.w  SaveMod,BPLHMOD(a6)           ; Restore the screen modulo
;  move.w  SaveRes,GFXMODE(a6)           ; Restore screen resolution

.RestoreInterrupts:
  move.w  SaveIntena,INTENA(a6)         ; Restore IT
;  move.w  SaveIntena+2,INTENA2(a6)      ; Restore IT 2
  move.w  SaveDmacon,DMACON(a6)         ; Restore DMA
;  move.w  SaveDmacon+2,DMACON2(a6)      ; Restore DMA 2

.CloseGraphicsLib:
  movea.l _ExecBase,a6
  movea.l GfxBase,a1
  jsr     _CloseLibrary(a6)             ; Close GRAPHICS library

.CloseDOSLib:
  movea.l _ExecBase,a6
  movea.l DOSBase,a1
  jsr     _CloseLibrary(a6)             ; Close DOS library

.RestoreEnd:
  IFEQ    MODE_DEBUG
  movea.l _ExecBase,a6                  ; EXEC library
  jsr     _Permit(a6)                   ; Start multitask
  ENDC

  rts

;*******************************************************************************
; VBL
;*******************************************************************************

SagaVbl:
  movem.l d0-a6,-(sp)
  move.w  #-1,VblFlag                   ; Set end of VBL
  move.w  #$20,CUSTOM+INTREQ            ; Release interrupt
  movem.l (sp)+,d0-a6
  rte

;*******************************************************************************
  SECTION  GENERAL,DATA
;*******************************************************************************

GraphicsLib:
  dc.b    "graphics.library",0

DOSLib:
  dc.b    "dos.library",0

  EVEN

VblFlag:
  dc.w    0

LastError:
  dc.l    0

; Vector base register and library base
VbrBase:
  dc.l    0
GfxBase:
  dc.l    0
DOSBase:
  dc.l    0

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
SaveKeyboard:
  dc.l    0
SaveVbl:
  dc.l    0
SaveView:
  dc.l    0
SaveCopper:
  dc.l    0

; Physical screen address
PhysicalScreen:
  dc.l    0

;*******************************************************************************
  SECTION SCREEN,BSS
;*******************************************************************************
  CNOP    0,8                           ; Align on 8 bytes (FMODE constraint)
ScreenBuffer:
  ds.b    PF_SIZE+32

;*******************************************************************************
  SECTION SPRITE,DATA_C
;*******************************************************************************
  CNOP    0,8                           ; Align on 8 bytes (FMODE constraint)
DefaultSprite:
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
  CMOVE   $0FFF,COLOR00+2 
  CMOVE   $0F00,COLOR00+4
  CMOVE   $00F0,COLOR00+6
  CMOVE   $000F,COLOR00+8
  CMOVE   $0FF0,COLOR00+10
  CMOVE   $00FF,COLOR00+12
  CMOVE   $0F0F,COLOR00+14
  CMOVE   $0888,COLOR00+16
  CMOVE   $08F8,COLOR00+18 
  CMOVE   $0F88,COLOR00+20
  CMOVE   $088F,COLOR00+22
  CMOVE   $0F8F,COLOR00+24
  CMOVE   $048F,COLOR00+26
  CMOVE   $0F84,COLOR00+28
  CMOVE   $04F8,COLOR00+30
CLScreenDef:
  CWAIT   $0001,SCREEN_STARTY-2
  CMOVE   $0038,DDFSTRT
  CMOVE   $00D0,DDFSTOP
  CMOVE   $4200,BPLCON0                 ; 16 colors low res
  CMOVE   $0000,BPLCON1
  CMOVE   $0000,BPLCON2
  CMOVE   $0C00,BPLCON3
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

  END
