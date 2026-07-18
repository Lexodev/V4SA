;*******************************************************************************
; VAMPIRE TOOLBOX
;*******************************************************************************
; System.s
;
; Save and restore system state
;
; Version 2.1 July 2026
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

  IFND    MODE_DEBUG
MODE_DEBUG       = 1                 ; Debug mode (0 = inactive, 1 = active)
  ENDC

;*******************************************************************************
  SECTION SYSTEMCODE,CODE
;*******************************************************************************

;*******************************************************************************
; Check if this is a V4 card
;   OUT : d0.l = operation success
;*******************************************************************************

CheckV4Card:
  movea.l _ExecBase,a6                  ; EXEC library

.Check68080:
  move.w  EXEC_ATTNFLAGS(a6),d0         ; Flags ATTN EXEC (CPU & FPU)
  btst    #EXEC_AF68080,d0              ; Check for 68080
  bne.s   .CheckCard                    ; Yes
  move.l  #ERR_NOT080,d0                ; No 68080 available
  rts

.CheckCard:
  move.w  CUSTOM+VAMPVERS,d0            ; Card version
  lsr.w   #$8,d0                        ; Keep only version
  cmpi.b  #CARD_V4SA,d0                 ; V4SA card ?
  beq.s   .V4                           ; Yes
  cmpi.b  #CARD_V4_500,d0               ; V4_500 card ?
  beq.s   .V4                           ; Yes
  cmpi.b  #CARD_V4_1200,d0              ; V4_1200 card ?
  beq.s   .V4                           ; Yes
  cmpi.b  #CARD_V4_600,d0               ; V4_600 card ?
  beq.s   .V4                           ; Yes
  move.l  #ERR_NOTV4,d0                 ; No V4 available
  rts

.V4:
  move.l  #ERR_NONE,d0                  ; This is a V4 card
  rts

;*******************************************************************************
; Save system
;   OUT : d0.l = operation success
;*******************************************************************************

SaveSystem:
  movem.l d1-a6,-(sp)

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
  move.l  #ERR_DOSLIB,d0                ; No DOS lib available
  bra     .EndSave                      ; Return

.OpenGraphicsLib:
  movea.l _ExecBase,a6                  ; EXEC library
  lea     GraphicsLib,a1
  move.l  #33,d0
  jsr     _OpenLibrary(a6)              ; Open GRAPHICS.library
  move.l  d0,GfxBase                    ; Keep the pointer
  bne.s   .SaveSystem                   ; All libs are open
  move.l  #ERR_GFXLIB,d0                ; No GRAPHICS lib available
  bra     .EndSave                      ; Return

.SaveSystem:
  lea     CUSTOM,a6                     ; Custom base

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
  lea     CUSTOMR,a6                    ; SAGA R/O custom base
  move.w  BPLHMOD(a6),SaveSagaMod       ; Save the screen modulo
  move.l  BPLHPT(a6),SaveSagaScreen     ; Save the screen address
  move.w  GFXMODE(a6),SaveSagaRes       ; Save the screen resolution

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
  move.l  #ERR_NONE,d0                  ; Everything is ok

.EndSave:
  movem.l (sp)+,d1-a6
  rts

SagaGetVBR:
  dc.l    $4E7A0801                     ; Opcode for "movec VBR,d0"
  rte

;*******************************************************************************
; Restore system data
;*******************************************************************************

RestoreSystem:
  movem.l d1-a6,-(sp)

  tst.l   DOSBase
  beq    .EndRestore                    ; DOS library is not open

  tst.l   GfxBase
  beq    .CloseDOSLib                   ; GRAPHICS library is not open

  lea     CUSTOM,a6                     ; Custom base

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
  movea.l GfxBase,a6                    ; GRAPHICS base
  movea.l SaveView,a1
  jsr     _LoadView(a6)                 ; Restore view
  jsr     _WaitTOF(a6)
  jsr     _WaitTOF(a6)                  ; Two times for interlaced screens

.FreeBlitter:
  jsr     _WaitBlit(a6)                 ; Wait end of Blitter activity

  lea     CUSTOM,a6                     ; Custom base

.RestoreScreen:
  move.w  SaveSagaMod,BPLHMOD(a6)       ; Restore the screen modulo
  move.l  SaveSagaScreen,BPLHPT(a6)     ; Restore the screen address
  move.w  SaveSagaRes,GFXMODE(a6)       ; Restore the screen resolution

.RestoreInterrupts:
  move.w  SaveIntena,INTENA(a6)         ; Restore IT
  move.w  SaveIntena+2,INTENA2(a6)      ; Restore IT 2
  move.w  SaveDmacon,DMACON(a6)         ; Restore DMA
  move.w  SaveDmacon+2,DMACON2(a6)      ; Restore DMA 2

.CloseGraphicsLib:
  movea.l _ExecBase,a6                  ; EXEC base
  movea.l GfxBase,a1
  jsr     _CloseLibrary(a6)             ; Close GRAPHICS library

.CloseDOSLib:
  movea.l _ExecBase,a6                  ; EXEC base
  movea.l DOSBase,a1
  jsr     _CloseLibrary(a6)             ; Close DOS library

.EndRestore:
  IFEQ    MODE_DEBUG
  movea.l _ExecBase,a6                  ; EXEC library
  jsr     _Permit(a6)                   ; Start multitask
  ENDC

  movem.l (sp)+,d1-a6
  rts

;*******************************************************************************
  SECTION SYSTEMDATA,DATA
;*******************************************************************************

GraphicsLib:
  dc.b    "graphics.library",0

DOSLib:
  dc.b    "dos.library",0

  EVEN

; Vector base register and library base
VbrBase:
  dc.l    0
GfxBase:
  dc.l    0
DOSBase:
  dc.l    0

; System data save
SaveIntena:
  dc.w    0,0
SaveDmacon:
  dc.w    0,0
SaveSagaRes:
  dc.w    0
SaveSagaMod:
  dc.w    0
SaveSagaScreen:
  dc.l    0
SaveKeyboard:
  dc.l    0
SaveVbl:
  dc.l    0
SaveView:
  dc.l    0
SaveCopper:
  dc.l    0
