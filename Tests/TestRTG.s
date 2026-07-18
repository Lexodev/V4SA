;*******************************************************************************
; TestRTG.s
;
; Test SAGA RTG screen
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
CUSTOMR   = $DFE000           ; Specific for SAGA

; Registers offset
DMACONR   = $002              ; DMA control (and blitter status) read
INTENAR   = $01C              ; Interrupt enable bits read
INTREQR   = $01E              ; Interrupt request bits read
COP1LC    = $080              ; Coprocessor 1st location
COPJMP1   = $088              ; Coprocessor restart at 1st location
DMACON    = $096              ; DMA control write (clear or set)
INTENA    = $09A              ; Interrupt enable bits (clear or set bits)
INTREQ    = $09C              ; Interrupt request bits (clear or set bits)
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
CHKCOL    = $388              ; 32bit Chunky COLOR Port register, Format [ID,RR,GG,BB]
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
DMA_SET             = DMA_ON|DMA_COPPER
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

; Resolutions
VRES_NONE           = $0000
VRES_320x240        = $0200
VRES_640x480        = $0500
VRES_960x540        = $0700
VRES_1280x720       = $0A00

; Pixel format
PIXF_NONE           = $00
PIXF_CLUT           = $01     ; 8bit (indexed)
PIXF_R5G6B5         = $02     ; 16bit R5G6B5
PIXF_R8G8B8         = $04     ; 24bit R8G8B8
PIXF_A8R8G8B8       = $05     ; 32bit A8R8G8B8

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

; Screen size
SCREEN_WIDTH        = 640
SCREEN_HEIGHT       = 480
SCREEN_DEPTH        = 16
SCREEN_MODE         = VRES_640x480+PIXF_R5G6B5

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
  jsr     CheckV4Card                   ; Are we on a V4 card
  tst.l   LastError
  bne     Exit                          ; No let's get out

  jsr     SagaSystemSave                ; Save system data
  tst.l   LastError
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
  move.l  #SagaVbl,VEC_VBL(a0)          ; Set our VBL IT

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

.SetupScreen:
  move.w  #0,CUSTOM+BPLHMOD             ; Screen modulo
  move.l  PhysicalScreen,CUSTOM+BPLHPT  ; Set screen address
  move.w  #SCREEN_MODE,CUSTOM+GFXMODE   ; Set screen mode

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
  move.w  DMACON2R(a6),SaveDmacon+2
  ori.w   #$8100,SaveDmacon+2           ; Save DMA 2 status
  move.w  INTENAR(a6),SaveIntena
  ori.w   #$C000,SaveIntena             ; Save IT status
  move.w  INTENA2R(a6),SaveIntena+2
  ori.w   #$C000,SaveIntena+2           ; Save IT 2 status

.SaveScreen:
  lea     CUSTOMR,a6
  move.w  BPLHMOD(a6),SaveMod           ; Save the screen modulo
  move.l  BPLHPT(a6),SaveScreen         ; Save the screen address
  move.w  GFXMODE(a6),SaveRes           ; Save the screen resolution

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

  tst.l   DOSBase
  beq    .RestoreEnd                    ; DOS library is not open

  tst.l   GfxBase
  beq    .CloseDOSLib                   ; GRAPHICS library is not open

.RestoreSystem:
  lea     CUSTOM,a6

.StopInterrupts:
  move.w  #DMA_STOP,DMACON(a6)          ; Stop DMA
  move.w  #DMA_STOP,DMACON2(a6)         ; Stop DMA 2
  move.w  #INT_STOP,INTENA(a6)          ; Stop interruptions
  move.w  #INT_STOP,INTENA2(a6)         ; Stop interruptions 2
  move.w  #INT_STOP,INTREQ(a6)          ; Stop requests
  move.w  #INT_STOP,INTREQ2(a6)         ; Stop requests 2

.RestoreCopper:
  move.l  SaveCopper,COP1LC(a6)         ; Restore Copper list

.RestoreVectors:
  move.l  VbrBase,a0                    ; Restore vectors
  move.l  SaveKeyboard,VEC_KBD(a0)      ; Keyboard
  move.l  SaveVbl,VEC_VBL(a0)           ; VBL

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
  move.w  SaveMod,BPLHMOD(a6)           ; Restore the screen modulo
  move.l  SaveScreen,BPLHPT(a6)         ; Restore the screen address
  move.w  SaveRes,GFXMODE(a6)           ; Restore the screen resolution

.RestoreInterrupts:
  move.w  SaveIntena,INTENA(a6)         ; Restore IT
  move.w  SaveIntena+2,INTENA2(a6)      ; Restore IT 2
  move.w  SaveDmacon,DMACON(a6)         ; Restore DMA
  move.w  SaveDmacon+2,DMACON2(a6)      ; Restore DMA 2

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
  SECTION COPPER,DATA_C
;*******************************************************************************
CopperList:
  CNOOP
CLEnd:
  CEND

;*******************************************************************************
  SECTION SCREEN,BSS
;*******************************************************************************

ScreenBuffer:
  ds.b    (SCREEN_WIDTH*SCREEN_HEIGHT*(SCREEN_DEPTH/8))+32

  END
