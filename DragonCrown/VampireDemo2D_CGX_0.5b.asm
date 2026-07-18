;******************************************************************************
;* 
;* File:     VampireDemo2D_CGX.asm
;* Author:   Flype, Apollo-Team 2016
;* Version:  0.2 (2016-08-03)
;* Compiler: Devpac 3.18
;* 
;******************************************************************************
;* 
;* LMB      Exit program
;* ESCAPE   Exit program
;* SPACE    Display / Hide Logo
;* LEFT     Decrease number of sprites
;* RIGHT    Increase number of sprites
;* 
;******************************************************************************
;* 
;* TODO:
;* 
;* . RLE DrawSprite routine
;* . All sprites width dividable by 4 (Elf is not)
;* 
;******************************************************************************


	MACHINE MC68040


;******************************************************************************
;*
;* MACROS
;*
;******************************************************************************


CALLCGX MACRO
	move.l  _CgxBase,a6
	jsr     _LVO\1(a6)
	ENDM

CALLTIMER MACRO
	move.l  _TimerBase,a6
	jsr     _LVO\1(a6)
	ENDM

CLKCNT_RESET MACRO
	tst.l   SAGA_CLKCNT
	ENDM

CLKCNT_ADD MACRO
	move.l  d0,-(sp)
	move.l  SAGA_CLKCNT,d0
	add.l   d0,\1
	move.l  (sp)+,d0
	ENDM


;******************************************************************************
;*
;* INCLUDES
;*
;******************************************************************************


	INCLUDE exec/types.i
	INCLUDE exec/memory.i
	INCLUDE exec/exec_lib.i
	INCLUDE devices/timer.i
	INCLUDE devices/timer_lib.i
	INCLUDE dos/dos.i
	INCLUDE dos/dos_lib.i
	INCLUDE hardware/intbits.i
	INCLUDE intuition/screens.i
	INCLUDE intuition/intuition_lib.i
	INCLUDE cybergraphics/cybergraphics.i
	INCLUDE cybergraphics/cybergraphics_lib.i


;******************************************************************************
;*
;* PRIVATES
;*
;******************************************************************************


BMPHDR			EQU 138                     ; BMP Header Size
MEM_ALIGN		EQU 16                      ; FrameBuffer Alignment
SAGA_FBADDR		EQU $dff1ec                 ; FrameBuffer Address
SAGA_CLKCNT		EQU $de0008                 ; Clock Cycle Counter

BYTESPERPIX		EQU 2                       ; Bytes Per Pixel
SCREENWIDTH		EQU 960                     ; Screen Width
SCREENHEIGHT	EQU 540                     ; Screen Height
SCREENDEPTH		EQU (BYTESPERPIX*8)         ; 
SCREENSIZE		EQU (SCREENWIDTH*SCREENHEIGHT*BYTESPERPIX)

INTRODELAY      EQU 50
OUTRODELAY      EQU 50

FONTWIDTH		EQU 32                      ; Font Size
FONTHEIGHT		EQU 25                      ; 

LOGOWIDTH		EQU 200                     ; Logo Size (68080 AMMX)
LOGOHEIGHT		EQU 200

CROWNWIDTH		EQU 320                     ; Crown Size
CROWNHEIGHT		EQU 149                     ; 

MINSPRITE		EQU 1                       ; Minimum number of sprites to display
MAXSPRITE		EQU 7                       ; Maximum number of sprites to display

SprCount		EQU 0                       ; Frames Count
SprLeft			EQU 2                       ; X position
SprTop			EQU 6                       ; Y position
SprWidth		EQU 10                      ; Frames Width
SprHeight		EQU 14                      ; Frames Height
SprStepX		EQU 18                      ; X move step
SprStepY		EQU 22                      ; Y move step
SprIndex		EQU 26                      ; Index of frame
SprSize			EQU 28                      ; Bytes per frame
SprData			EQU 32                      ; Frames start address
SprSIZEOF		EQU 36                      ; SIZEOF


;******************************************************************************
;*
	SECTION S_0,CODE
;*
;******************************************************************************


MAIN:


;------------------------------------------------------------------------------
; INIT PROGRAM
;------------------------------------------------------------------------------


.OpenDOS
	lea      DosName,a1                     ; Open DOS
	move.l   #39,d0                         ; 
	CALLEXEC OpenLibrary                    ; 
	move.l   d0,_DOSBase                    ; Store result
	tst.l    d0                             ; 
	beq      .FreeALL                       ; Exit on error

.OpenIntuition
	lea      IntName,a1                     ; Open Intuition
	move.l   #39,d0                         ; 
	CALLEXEC OpenLibrary                    ; 
	move.l   d0,_IntuitionBase              ; Store result
	tst.l    d0                             ; 
	beq      .FreeALL                       ; Exit on error

.OpenCGX
	lea      CgxName,a1                     ; Open Cybergraphics
	move.l   #39,d0                         ; 
	CALLEXEC OpenLibrary                    ; 
	move.l   d0,_CgxBase                    ; Store result
	tst.l    d0                             ; 
	beq      .FreeALL                       ; Exit on error

.GetBestMode
	lea      MyBestModeTagItems,a0          ; Get Best ModeID
	CALLCGX  BestCModeIDTagList             ; 
	move.l   d0,ScrModeID                   ; Store result
	cmp.l    #INVALID_ID,d0                 ; 
	beq      .FreeALL                       ; Exit on error

.OpenScreen
	lea      MyNewScreen,a0                 ; NewScreen Struct
	lea      MyNewScreenTagItems,a1         ; TagItems
	move.l   ScrModeID,4(a1)                ; TagItems->SA_DisplayID
	CALLINT  OpenScreenTagList              ; 
	move.l   d0,ScrHandle                   ; Store result
	tst.l    d0                             ; 
	beq      .FreeALL                       ; Exit on error

.OpenWindow
	lea      MyWindowTagItems,a1            ; TagItems
	move.l   ScrHandle,4(a1)                ; TagItems->CUSTOMSCREEN
	move.l   #0,a0                          ; 
	CALLINT  OpenWindowTagList              ;
	move.l   d0,WndHandle                   ; Store result
	tst.l    d0                             ;
	beq      .FreeALL                       ; Exit on error
	move.l   d0,a0                          ;
	move.l   wd_UserPort(a0),WndMsgPort     ; Store Window Message Port

.OpenTimer	
	lea      TimerName,a0                   ; Open Timer
	lea      TimerIORequest,a1              ; IORequest Struct
	move.l   #UNIT_MICROHZ,d0               ; Unit
	move.l   #0,d1                          ; Flags
	CALLEXEC OpenDevice                     ; 
	move.l   d0,TimerResult                 ; Store result
	tst.l    d0                             ; 
	bne      .FreeALL                       ; Exit on error
	lea      TimerIORequest,a1              ; 
	move.l   IO_DEVICE(a1),_TimerBase       ; Store IODevice

.AllocBuffers
	move.l   #(SCREENSIZE*2),d0             ; Screen Size * Two Buffers
	add.l    #(MEM_ALIGN-1),d0              ; Size + Alignment
	move.l   d0,MemSize                     ; MemSize
	move.l   #(MEMF_LOCAL!MEMF_FAST),d1     ; MemFlags
	CALLEXEC AllocMem                       ; Allocate memory
	tst.l    d0                             ; Check result
	beq      .FreeALL                       ; Exit on error
	move.l   d0,MemAddr                     ; MemAddr

.GetBuffers
	move.l   ScrHandle,a0                   ; Screen
	move.l   sc_RastPort+rp_BitMap(a0),a0   ; Screen->Rasport->Bitmap
	lea      MyLockTagItems,a1              ; TagItems
	CALLCGX  LockBitMapTagList              ; Get FrameBuffer #1
	tst.l    d0                             ; 
	beq      .FreeALL                       ; Exit on error
	move.l   d0,a0                          ; 
	CALLCGX  UnLockBitMap                   ; 
	move.l   MemAddr,d0                     ; MemAddr
	add.l    #(MEM_ALIGN-1),d0              ; Align MemAddr
	and.l    #~(MEM_ALIGN-1),d0             ; 
	move.l   d0,FBAddr2                     ; Get FrameBuffer #2
	add.l    #SCREENSIZE,d0                 ; 
	move.l   d0,FBAddr3                     ; Get FrameBuffer #3


.AddInterrupt
	moveq.l  #INTB_VERTB,d0                 ; Interrupt Number
	lea      VBLInterruptStruct,a1          ; Interrupt Struct
	CALLEXEC AddIntServer                   ; Exec->AddIntServer(num, interrupt)


;------------------------------------------------------------------------------
; INTRO SCREEN
;------------------------------------------------------------------------------


	move.l   FBAddr1,FBAddr                 ; Current FrameBuffer
	
	move.l   #0,d0                          ; XOffset
	move.l   #0,d3                          ; Modulus
	move.l   #GfxIntro+BMPHDR,a0            ; Source
	bsr      DrawBackground                 ; Draw Background
	
	move.l   FBAddr,SAGA_FBADDR             ; Set FrameBuffer

	
;------------------------------------------------------------------------------
; INIT GFX DATA
;------------------------------------------------------------------------------


	move.l   #GfxCrown+BMPHDR,a0            ; Source
	move.l   #GfxCrownRLE,a1                ; Destination
	move.l   #CROWNWIDTH,d0                     ; Width
	move.l   #CROWNHEIGHT,d1                ; Height
	bsr      PackSprite                     ; RLE Pack
	
;	move.l   #GfxCrownRLE,a0                ; Destination
;	move.l   #100,d0                        ; X
;	move.l   #10,d1                         ; Y
;	move.l   #CROWNWIDTH,d2                 ; W
;	move.l   #CROWNHEIGHT,d3                ; H
;	CLKCNT_RESET
;	bsr      DrawSpriteRLE                  ; RLE Render
;	CLKCNT_ADD MyClockCounter
	
	lea      SprFighter,a0                  ; 
	move.l   #GfxFighter+BMPHDR,SprData(a0) ; 
	
	lea      SprAmazon,a0                   ; 
	move.l   #GfxAmazon+BMPHDR,SprData(a0)  ; 
	
	lea      SprWizard,a0                   ; 
	move.l   #GfxWizard+BMPHDR,SprData(a0)  ; 
	
	lea      SprElf,a0                      ; 
	move.l   #GfxElf+BMPHDR,SprData(a0)     ; 
	
	lea      SprDwarf,a0                    ; 
	move.l   #GfxDwarf+BMPHDR,SprData(a0)   ; 
	
	lea      SprSorceress,a0                ; 
	move.l   #GfxSorceress+BMPHDR,SprData(a0) ;
	
	lea      SprSorceressIdle,a0            ; 
	move.l   #GfxSorceressIdle+BMPHDR,SprData(a0) ;

	
;------------------------------------------------------------------------------
; MAIN SCREEN
;------------------------------------------------------------------------------

	
	move.l   #INTRODELAY,d1                 ; Some ticks
	CALLDOS  Delay                          ; Wait

	
.MainLoop                                   ; Main loop

	move.l   FBAddr1,FBAddr                 ; Current FrameBuffer

.RenderBackground
	move.l   XOffset,d0                     ; XOffset
	lsr.l    #4,d0                          ; 
	cmp.w    #(SCREENWIDTH*2),d0            ; Check bound
	bmi.s    .RenderBackground.next         ; 
	move.l   #0,XOffset                     ; Reset XOffset
	move.l   #0,d0                          ; 
.RenderBackground.next
	move.l   #GfxBack+BMPHDR,a0             ; Source
	move.l   #(SCREENWIDTH*2*BYTESPERPIX),d3  ; Modulus
	bsr      DrawBackground                 ; Draw Background

.RenderLogo
	move.l   #GfxLogo+BMPHDR,a0             ; Source
	move.l   #50,d0                         ; X
	move.l   #10,d1                         ; Y
	move.l   #LOGOWIDTH,d2                  ; W
	move.l   #LOGOHEIGHT,d3                 ; H
	bsr      DrawSprite                     ; Draw Sprite

.RenderCrown
	tst.l    DisplayCrown                   ; Check if true
	beq.s    .RenderSprites                 ; Else skip
	move.l   #GfxCrown+BMPHDR,a0            ; Source
	move.l   #(SCREENWIDTH/2)-(CROWNWIDTH/2),d0 ; X
	move.l   #10,d1                         ; Y
	move.l   #CROWNWIDTH,d2                 ; W
	move.l   #CROWNHEIGHT,d3                ; H
	bsr      DrawSprite                     ; Draw Sprite

.RenderSprites
	lea      SpriteList,a2                  ; Load sprite array
	move.l   NumSprite,d4                   ; 
	sub.l    #1,d4                          ; 
.RenderSprites.loop
	add.w    #4,SprIndex(a2)                ; Increment frame
	move.w   SprIndex(a2),d0                ; 
	cmp.w    SprCount(a2),d0                ; 
	ble.b    .RenderSprites.next            ; Skip
	sub.w    SprCount(a2),d0                ; 
	move.w   d0,SprIndex(a2)                ; 
.RenderSprites.next
	clr.l    d0                             ; 
	move.w   SprIndex(a2),d0                ; Calc frame addr
	lsr.w    #4,d0                          ; 
	mulu.l   SprSize(a2),d0                 ; 
	move.l   SprData(a2),a0                 ; 
	add.l    d0,a0                          ; Source
	move.l   SprLeft(a2),d0                 ; X
	lsr.l    #4,d0                          ; 
	move.l   SprTop(a2),d1                  ; Y
	move.l   SprWidth(a2),d2                ; W
	move.l   SprHeight(a2),d3               ; H
	bsr      DrawSprite                     ; Draw Sprite
	add.l    #SprSIZEOF,a2                  ; Next Sprite 
	dbf      d4,.RenderSprites.loop         ; Continue

.RenderStats
	bsr      DrawStats                      ; Draw Stats

.BusyWait
	tst.w    VBLCounter                     ; Check VBLCounter
	beq.s    .BusyWait                      ; Wait until VBLCounter = 0

.UpdateVBLInt
	move.w   VBLCounter,d7                  ; Read and reset the
	clr.w    VBLCounter                     ; VBL interrupt counter

.UpdateScrolling
	move.l   XStep,d0                       ; Increment Scrolling
	mulu.w   d7,d0                          ; 
	add.l    d0,XOffset                     ; 

.UpdateSprites
	lea      SpriteList,a0                  ; Load Sprite list
	move.l   NumSprite,d0                   ; 
	sub.l    #1,d0                          ; 
.UpdateSprites.loop
	move.l   SprStepX(a0),d1                ; Increment X position
	mulu.w   d7,d1                          ; 
	add.l    d1,SprLeft(a0)                 ; 
	add.l    #SprSIZEOF,a0                  ; Next SprList element 
	dbf      d0,.UpdateSprites.loop         ; Continue

.SwapBuffers
	move.l   FBAddr,SAGA_FBADDR             ; Set FrameBuffer
	move.l   FBAddr1,a1                     ; Swap FrameBuffers
	move.l   FBAddr2,a2                     ; 
	move.l   FBAddr3,a3                     ; 
	move.l   a2,FBAddr1                     ; 
	move.l   a3,FBAddr2                     ; 
	move.l   a1,FBAddr3                     ; 

.ProcessEvents	
	bsr      ProcessEvents                  ; Process Events
	tst.l    d0                             ; 
	beq      .MainLoop                      ; Until d0 = 1


;------------------------------------------------------------------------------
; OUTRO SCREEN
;------------------------------------------------------------------------------


	move.l   FBAddr1,FBAddr                 ; Current FrameBuffer
	
	move.l   #0,d0                          ; XOffset
	move.l   #0,d3                          ; Modulus
	move.l   #GfxOutro+BMPHDR,a0            ; Source
	bsr      DrawBackground                 ; Draw Background
	
	move.l   FBAddr,SAGA_FBADDR             ; Set FrameBuffer
	
	move.l   #OUTRODELAY,d1                 ; Some ticks
	CALLDOS  Delay                          ; Wait
	
	
;------------------------------------------------------------------------------
; EXIT PROGRAM
;------------------------------------------------------------------------------


.RemoveInterrupt
	moveq.l  #INTB_VERTB,d0                 ; Interrupt Number
	lea      VBLInterruptStruct,a1          ; Interrupt Struct
	CALLEXEC RemIntServer                   ; Exec->RemIntServer(num, interrupt)


.FreeALL


.FreeBuffers
	tst.l    MemAddr                        ; Free Memory
	beq.s    .CloseTimer                    ; 
    move.l   MemAddr,a1                     ; 
    move.l   MemSize,d0                     ; 
    CALLEXEC FreeMem                        ; 
.CloseTimer
	tst.l    TimerResult                    ; Close Timer device
	bne.s    .CloseWindow                   ; 
	lea      TimerIORequest,a1              ; 
	CALLEXEC CloseDevice                    ; 
.CloseWindow
	tst.l    WndHandle                      ; Close Window
	beq.s    .CloseScreen                   ; 
	move.l   WndHandle,a0                   ; 
	CALLINT  CloseWindow                    ; 
.CloseScreen
	tst.l    ScrHandle                      ; Close Screen
    beq.s    .CloseCGX                      ; 
	move.l   ScrHandle,a0                   ; 
	CALLINT  CloseScreen                    ; 
.CloseCGX
	tst.l    _CgxBase                       ; Close Cybergraphics
	beq.s    .CloseIntuition                ; 
	move.l   _CgxBase,a1                    ; 
	CALLEXEC CloseLibrary                   ; 
.CloseIntuition                             ; 
	tst.l    _IntuitionBase                 ; Close Intuition
	beq.s    .CloseDOS                      ; 
	move.l   _IntuitionBase,a1              ; 
	CALLEXEC CloseLibrary                   ; 
.CloseDOS                                   ; 
	tst.l    _DOSBase                       ; Close DOS
	beq.s    .Exit                          ; 
	move.l   _DOSBase,a1                    ; 
	CALLEXEC CloseLibrary                   ; 
.Exit                                       ; 
	move.l   #0,d0                          ; Return Code
	rts                                     ; Return to System


;******************************************************************************
;* 
ClearScreen:
;* 
******************************************************************************


	movem.l  d0/a0,-(sp)                    ; Store registers
	move.l   FBAddr,a0                      ; FrameBuffer
	move.l   #(SCREENSIZE/8),d0             ; Iterations
.a	move.l   #0,(a0)+                       ; Clear 2 pixels
	move.l   #0,(a0)+                       ; Clear 2 pixels
	subq.l   #1,d0                          ; 
	bne.s    .a                             ; Until d1 = 0
	movem.l  (sp)+,d0/a0                    ; Restore registers
	rts                                     ; Return


;*****************************************************************************
;* 
DrawBackground:
;* 
;* INPUTS
;* A0.L = Source
;* D0.L = XOffset
;* D3.L = Modulus
;* 
;******************************************************************************


	movem.l  d0-d2/a0-a1,-(sp)              ; Store Registers
	move.l   FBAddr,a1                      ; FrameBuffer
	lsl.l    #1,d0                          ; XOffset * BytesPerPixel
	add.l    d0,a0                          ; Update Source
	move.l   #(SCREENHEIGHT-1),d1           ; Number of loopY
.y	move.l   #(SCREENWIDTH/4)-1,d2          ; Number of loopX
.x	move.l   (a0)+,(a1)+                    ; Copy 2 pixels
	move.l   (a0)+,(a1)+                    ; Copy 2 pixels
	dbf      d2,.x                          ; Next x
	add.l    d3,a0                          ; Modulus
	dbf      d1,.y                          ; Next y
	movem.l  (sp)+,d0-d2/a0-a1              ; Restore Registers
	rts                                     ; Return


;******************************************************************************
;* 
DrawSprite:
;* 
;* INPUTS
;* A0.L = Source
;* D0.L = DestX
;* D1.L = DestY
;* D2.L = Width
;* D3.L = Height
;* 
;******************************************************************************


	movem.l  d0-d7/a0-a1,-(sp)              ; Store Registers
	move.l   FBAddr,a1                      ; FrameBuffer
	lsl.l    #1,d0                          ; x * BytesPerPixel
	add.l    d0,a1                          ; Update Dest
	mulu.l   #(SCREENWIDTH*2),d1            ; y * w * BytesPerPixel
	add.l    d1,a1                          ; Update Dest
	move.l   #SCREENWIDTH,d0                ; ( ScrW - SprW ) * BytesPerPixel
	sub.l    d2,d0                          ; 
	lsl.l    #1,d0                          ; 
	move.l   d3,d1                          ; Number of loopY
	sub.l    #1,d1                          ; 
	sub.l    #1,d2                          ; Number of loopX
	lsr.l    #2,d2                          ; loopX / 4
	move.w   #%1111100000011111,d7          ; Color mask (Pink R5G6B5)
.y	move.l   d2,d5                          ; Number of loopX
.x	move.w   (a0)+,d6                       ; Read pixel
	cmp.w    d7,d6                          ; Check if transparent
	beq.b    .a1                            ; Skip if transparent
	move.w   d6,(a1)                        ; Copy pixel
.a1	move.w   (a0)+,d6                       ; Read pixel
	cmp.w    d7,d6                          ; Check if transparent
	beq.b    .a2                            ; Skip if transparent
	move.w   d6,2(a1)                       ; Copy pixel
.a2	move.w   (a0)+,d6                       ; Read pixel
	cmp.w    d7,d6                          ; Check if transparent
	beq.b    .a3                            ; Skip if transparent
	move.w   d6,4(a1)                       ; Copy pixel
.a3	move.w   (a0)+,d6                       ; Read pixel
	cmp.w    d7,d6                          ; Check if transparent
	beq.b    .a4                            ; Skip if transparent
	move.w   d6,6(a1)                       ; Copy pixel
.a4	addq.l   #(2*4),a1                      ; Increment dest

	dbf      d5,.x                          ; Next x

	add.l    d0,a1                          ; Update Dest
	dbf      d1,.y                          ; Next y
	movem.l  (sp)+,d0-d7/a0-a1              ; Restore Registers
	rts                                     ; Return


;******************************************************************************
;*
DrawStats:
;* 
;******************************************************************************


	movem.l  d0-d3,-(sp)                    ; Store registers

	add.l    #1,FPSCounter1                 ; Increment FPS
	bsr      GetTaskTime                    ; Get time
	cmp.l    #1,d0                          ; Seconds < 1 ?
	blt.s    .n1                            ; Draw or Reset
	move.l   FPSCounter1,d0                 ; Get current FPS
	move.l   d0,FPSCounter2                 ; Save old FPS
	move.l   #0,FPSCounter1                 ; Reset current FPS
	bsr      ResetTaskTime                  ; Reset time

.n1	move.l   FPSCounter1,d0                 ; Number to draw
	move.l   #2,d1                          ; Number of digits
	move.l   #4+(FONTWIDTH*1),d2            ; Destination X
	move.l   #4,d3                          ; Destination Y
	bsr      DrawNumber                     ; Draw number

.n2	move.l   FPSCounter2,d0                 ; Number to draw
	move.l   #2,d1                          ; Number of digits
	move.l   #(SCREENWIDTH*2)-FONTWIDTH-4,d2 ; Destination X
	move.l   #4,d3                          ; Destination Y
	bsr      DrawNumber                     ; Draw number

.n3	move.l   NumSprite,d0                   ; Number to draw
	move.l   #1,d1                          ; Number of digits
	move.l   #(SCREENWIDTH*2)-FONTWIDTH-4,d2 ; Destination X
	move.l   #5+FONTHEIGHT,d3               ; Destination Y
	bsr      DrawNumber                     ; Draw number

.n4	;not.l    DisplayClock                   ; Switch TRUE/FALSE
	tst.l    DisplayClock
	beq.s    .ex
	move.l   MyClockCounter,d0              ; Number to draw
	move.l   #7,d1                          ; Number of digits
	move.l   #200,d2 ; Destination X
	move.l   #SCREENHEIGHT-FONTHEIGHT-5,d3  ; Destination Y
	bsr      DrawNumber                     ; Draw number

.ex	movem.l  (sp)+,d0-d3                    ; Restore registers
	rts                                     ; Return	


;******************************************************************************
;*
DrawNumber:
;* 
;* INPUT
;* D0.L = Number to draw
;* D1.L = Number of digits to draw
;* D2.L = Destination X
;* D3.L = Destination Y
;* 
;******************************************************************************


	movem.l  d0-d4/a0,-(sp)                 ; Store registers
	sub.l    #1,d1                          ; Number of digits
.a	clr.l    d4                             ; Reset Digit
	divu.l   #10,d4:d0                      ; Get Digit
	mulu.l   #(FONTWIDTH*FONTHEIGHT*2),d4   ; Digit * FrameSize
	move.l   #GfxFont+BMPHDR,a0             ; Source
	add.l    d4,a0                          ; Source + D6 
	movem.l  d0-d3,-(sp)                    ; Push
	move.l   d2,d0                          ; X
	move.l   d3,d1                          ; Y
	move.l   #FONTWIDTH,d2                  ; W
	move.l   #FONTHEIGHT,d3                 ; H
	bsr      DrawSprite                     ; Draw Digit
	movem.l  (sp)+,d0-d3                    ; Pop
	sub.l    #FONTWIDTH,d2                  ; Update Destination X
	dbf      d1,.a                          ; Next Digit
	movem.l  (sp)+,d0-d4/a0                 ; Restore registers
	rts                                     ; Return


;******************************************************************************
;* 
ProcessEvents:
;* 
;* RETURNS
;* D0.L = TRUE (Message) OR FALSE (No message)
;*
;******************************************************************************

	
	movem.l  d1-a6,-(sp)                    ; Store registers
	move.l   WndMsgPort,a0                  ; Message Port
	CALLEXEC GetMsg                         ; Exec->GetMsg(port)
	tst.l    d0                             ; Check message
	beq      .ok                            ; No message
	move.l   d0,a1                          ; Reply Message
	move.l   im_Class(a1),d5                ; Get message class
	move.w   im_Code(a1),d6                 ; Get message code
	CALLEXEC ReplyMsg                       ; Exec->ReplyMsg(msg)
.mb	cmp.l    #IDCMP_MOUSEBUTTONS,d5         ; MOUSEBUTTONS
	beq      .st                            ; 
.rk	cmp.l    #IDCMP_RAWKEY,d5               ; RAWKEY
	bne      .ok                            ; 
.es	cmp.w    #$45,d6                        ; RAWKEY ESC
	beq      .st                            ; 
.sp	cmp.w    #$40,d6                        ; RAWKEY SPACE
	bne.s    .rW                            ; 
	not.l    DisplayCrown                   ; Switch TRUE/FALSE
	bra.w    .ok                            ; 
.rW	cmp.w    #$10,d6                        ; RAWKEY 'W'
	bne.s    .rQ                            ; 
	sub.l    #1,NumSprite                   ; NumSprite - 1
	cmp.l    #MINSPRITE,NumSprite           ; NumSprite < MINSPRITE ?
	bge.w    .ok                            ; 
	move.l   #MINSPRITE,NumSprite           ; NumSprite = MINSPRITE
	bra.w    .ok                            ; 
.rQ	cmp.w    #$11,d6                        ; RAWKEY 'Q'
	bne.s    .at                            ; 
	add.l    #1,NumSprite                   ; NumSprite + 1
	cmp.l    #MAXSPRITE,NumSprite           ; NumSprite > MAXSPRITE ?
	ble.w    .ok                            ; 
	move.l   #MAXSPRITE,NumSprite           ; NumSprite = MAXSPRITE
	bra.w    .ok                            ; 
.at	cmp.w    #$4c,d6                        ; RAWKEY ARROW TOP
	bne.s    .ab                            ; 
	lea      SprSorceressIdle,a0            ; 
	sub.l    #4,SprTop(a0)                 ; SprY--
;	bra.s    .ok                            ; 
.ab	cmp.w    #$4d,d6                        ; RAWKEY ARROW BOTTOM
	bne.s    .ar                            ; 
	lea      SprSorceressIdle,a0            ; 
	add.l    #4,SprTop(a0)                 ; SprY++
;	bra.s    .ok                            ; 
.ar	cmp.w    #$4e,d6                        ; RAWKEY ARROW RIGHT
	bne.s    .al                            ; 
	lea      SprSorceressIdle,a0            ; 
	add.l    #48,SprLeft(a0)                ; SprX++
;	bra.s    .ok                            ; 
.al	cmp.w    #$4f,d6                        ; RAWKEY ARROW LEFT
	bne.s    .ok                            ; 
	lea      SprSorceressIdle,a0            ; 
	sub.l    #48,SprLeft(a0)                ; SprX--
	bra.s    .ok                            ; 
.st	moveq.l  #-1,d0                         ; STOP = TRUE
	bra.s    .ex                            ; 
.ok	moveq.l  #0,d0                          ; STOP = FALSE
.ex	movem.l  (sp)+,d1-a6                    ; Restore registers
	rts                                     ; Return


;******************************************************************************
;
PackSprite:
;*
;* INPUT
;* A0.L = Source
;* A1.L = Destination
;* D0.L = Width
;* D1.L = Height
;* 
;******************************************************************************


	movem.l  d0-a6,-(sp)                    ; Store registers
	subq.l   #1,d1                          ; LoopY
.y	move.l   d0,d2                          ; Reset x
.x	clr.l    d4                             ; Counter Transparent pixels
	clr.l    d5                             ; Reset Count
.transparentLoop
	cmpi.w   #%1111100000011111,(a0)        ; Check if transparent
	bne.s    .notTransparent                ; 
	addq.l   #1,d4                          ; Increment transparent pixels 
	addq.l   #2,a0                          ; 
	subq.l   #1,d2                          ; 
	bne.s    .transparentLoop               ; Stop at line end
	bra.s    .writeControl                  ; End of line ?
.notTransparent
	move.l   a0,a2                          ; Remember start of Opaque
.opaqueLoop
	cmpi.w   #%1111100000011111,(a0)        ; Check if transparent
	beq.s    .writeControl                  ; 
	addq.l   #1,d5                          ; Increment opaque pixels 
	addq.l   #2,a0                          ; 
	subq.l   #1,d2                          ; 
	bne.s    .opaqueLoop                    ; Stop at line end
.writeControl
	move.w   d4,(a1)+                       ; Write transparent pixels counter
	move.w   d5,(a1)+                       ; Write opaque pixels counter
	tst.w    d5                             ; Check if opaque count > 0
	beq.s    .noWrite                       ; Else skip write opaque pixels
.writePixels
	move.w   (a2)+,(a1)+                    ; Copy pixel
	subq.l   #1,d5                          ; 
	bne.s    .writePixels                   ; Until count = 0
.noWrite
	tst.w    d2                             ; LoopX - 1
	bne      .x                             ; Next x
	dbf      d1,.y                          ; Next y
.exit
	movem.l  (sp)+,d0-a6                    ; Restore registers
	rts                                     ; Return


;******************************************************************************
;* 
DrawSpriteRLE:
;* 
;* INPUTS
;* A0.L = Source
;* D0.L = DestX
;* D1.L = DestY
;* D2.L = Width
;* D3.L = Height
;* 
;******************************************************************************


	movem.l  d0-d7/a0-a6,-(sp)              ; Store Registers
	move.l   FBAddr,a1                      ; FrameBuffer
	lsl.l    #1,d0                          ; Dest + X
	add.l    d0,a1                          ; 
	mulu.l   #(SCREENWIDTH*2),d1            ; Dest + Y
	add.l    d1,a1                          ; 
	move.l   #SCREENWIDTH,d0                ; Modulus
	sub.l    d2,d0                          ; 
	lsl.l    #1,d0                          ; 
	sub.l    #1,d3                          ; Number of loopY
	
	; a0 = source
	; a1 = dest + x + y
	; d0 = modulus
	; d1 = free. / loopx
	; d2 = width
	; d3 = height-1
	; d4 = free.
	; d5 = free.
	; d6 = free.
	; d7 = free.
.y
	move.l   d2,d1                          ; LoopX
.x
	move.w   (a0)+,d4                       ; Transparent pixels
	sub.w    d4,d1	                        ; loopx - n
	lea      (a1,d4.w*2),a1	                        ; dest + n
	
	
	move.w   (a0)+,d5                       ; Opaque pixels
	beq      .noCopy
	sub.w    d5,d1	                        ; X inus Opaque
.drawPixels
	move.w   (a0)+,(a1)+                    ; Draw 1 pixel
	subq.l   #1,d5                          ; 
	bne.s    .drawPixels                    ; Until d5 = 0
.noCopy	
	tst.w    d1
	bne      .x
	
	add.l    d0,a1                          ; Update Dest
	dbf      d3,.y                          ; Next y
	
	movem.l  (sp)+,d0-d7/a0-a6              ; Restore Registers
	rts                                     ; Return




;******************************************************************************
;* 
GetTaskTime:
;* 
;* RETURNS
;* D0.L = Seconds
;* D1.L = Microseconds
;* 
;******************************************************************************


	movem.l   a0/a1/a6,-(sp)                ; Store registers
	lea       TimerVal2,a0                  ;
	CALLTIMER GetSysTime                    ; 
	lea       TimerVal1,a1                  ;
	CALLTIMER SubTime                       ; 
	move.l    TV_SECS(a0),d0                ; 
	move.l    TV_MICRO(a0),d1               ;
	movem.l   (sp)+,a0/a1/a6                ; Restore registers
	rts                                     ; Return


;******************************************************************************
;* 
ResetTaskTime:
;*
;******************************************************************************


	movem.l   a0/a6,-(sp)                   ; Store registers
	lea       TimerVal1,a0                  ; 
	CALLTIMER GetSysTime                    ; 
	movem.l   (sp)+,a0/a6                   ; Restore registers
	rts                                     ; Return


;******************************************************************************
;*
VBLInterruptCode:
;*
;******************************************************************************


	movem.l  d1-a6,-(sp)                    ; Push (a1=interrupt data)
	addq.w   #1,VBLCounter                  ; Increment counter
	movem.l  (sp)+,d1-a6                    ; Pop
	moveq    #0,d0                          ; Return code
	rts                                     ; Return


;******************************************************************************
;*
	SECTION S_1,DATA
;*
;******************************************************************************


	EVEN
CgxName			CGXNAME                     ; Cybergraphics
DosName			DOSNAME                     ; DOS
IntName			INTNAME                     ; Intuition
TimerName		TIMERNAME                   ; Timer.device


;------------------------------------------------------------------------------


	EVEN
_CgxBase		DC.L 0                      ; Cybergraphics
_DOSBase		DC.L 0                      ; DOS
_IntuitionBase	DC.L 0                      ; Intuition
_TimerBase		DC.L 0                      ; Timer (IODevice)


;------------------------------------------------------------------------------


	EVEN
MemSize			DC.L 0                      ; Allocated Memory Address
MemAddr			DC.L 0                      ; Allocated Memory Size

FBAddr			DC.L 0                      ; Current FrameBuffer
FBAddr1			DC.L 0                      ; FrameBuffer #1
FBAddr2			DC.L 0                      ; FrameBuffer #2
FBAddr3			DC.L 0                      ; FrameBuffer #3

XStep			DC.L 16                     ; Scrolling step
XOffset			DC.L 0                      ; Background Scrolling X offset
ScrModeID		DC.L 0                      ; Display ModeID
ScrHandle		DC.L 0                      ; Intuition Screen
WndHandle		DC.L 0                      ; Intuition Window
WndMsgPort		DC.L 0                      ; Intuition Message Port

TimerResult		DC.L 0                      ; OpenDevice Result
TimerVal1		DS.B TV_SIZE                ; TimeVal Struct
TimerVal2		DS.B TV_SIZE                ; TimeVal Struct
TimerIORequest	DS.B IOTV_SIZE              ; TimeVal IORequest Struct

FPSCounter1		DC.L 0                      ; 
FPSCounter2		DC.L 0                      ; 

DisplayCrown    DC.L ~0                     ; Display or Hide the crown
DisplayClock    DC.L ~0                     ; Display or Hide the clock
NumSprite		DC.L MAXSPRITE				; Number of sprites to display

SprX			DC.L 0
SprY			DC.L 0

MyClockCounter	DC.L 0


;------------------------------------------------------------------------------


	EVEN
MyNewScreen:                                ; Intuition->OpenScreenTagList()
	DC.W 0                                  ; Left
	DC.W 0                                  ; Top
	DC.W SCREENWIDTH                        ; Width
	DC.W SCREENHEIGHT                       ; Height
	DC.W SCREENDEPTH                        ; Depth
	DC.B 0                                  ; DetailPen
	DC.B 1                                  ; BlockPen
	DC.W 0                                  ; ViewModes
	DC.W SCREENQUIET|CUSTOMSCREEN           ; Types
	DC.L 0                                  ; *Font
	DC.L MyNewScreenTitle                   ; *Title
	DC.L 0                                  ; *Gadgets
	DC.L 0                                  ; *Bitmap

	EVEN
MyNewScreenTagItems:                        ; Intuition->OpenScreenTagList()
	DC.L SA_DisplayID,0                     ; Display ModeID
	DC.L 0,0                                ; TAGEND

	EVEN
MyNewScreenTitle:                           ; Screen->Title
	DC.B "VampireDemo2D",0                  ; 


;------------------------------------------------------------------------------


	EVEN
MyWindowTagItems:                           ; Intuition->OpenWindowTagList()
	DC.L WA_CustomScreen,0                  ; Is  CustomScreen
	DC.L WA_Backdrop,-1                     ; Has Backdrop
	DC.L WA_Borderless,-1                   ; Has BorderLess
	DC.L WA_Activate,-1                     ; Has Activate
	DC.L WA_ReportMouse,-1                  ; Has ReportMouse
	DC.L WA_SizeGadget,0                    ; Has SizeGadget
	DC.L WA_DepthGadget,0                   ; Has DepthGadget
	DC.L WA_CloseGadget,-1                  ; Has CloseGadget
	DC.L WA_DragBar,0                       ; Has DragBar
	DC.L WA_IDCMP,IDCMP_RAWKEY|IDCMP_MOUSEBUTTONS ; EVENTS
	DC.L 0,0                                ; TAGEND


;------------------------------------------------------------------------------


	EVEN
MyBestModeTagItems:                         ; Cybergraphics->BestCModeIDTagList()
	DC.L CYBRBIDTG_Depth,SCREENDEPTH        ; Depth
	DC.L CYBRBIDTG_NominalWidth,SCREENWIDTH ; Width
	DC.L CYBRBIDTG_NominalHeight,SCREENHEIGHT ; Height
	DC.L 0,0                                ; TAGEND


;------------------------------------------------------------------------------


	EVEN
MyLockTagItems:                             ; Cybergraphics->LockBitMapTagList()
	DC.L LBMI_BASEADDRESS,FBAddr1           ; FrameBuffer #1 Address
	DC.L 0,0                                ; TAGEND

	
;------------------------------------------------------------------------------


	EVEN
VBLCounter:
	DC.W 0

	EVEN
VBLInterruptStruct:
	DC.L 0                                  ; Succ
	DC.L 0                                  ; Pred
	DC.B NT_INTERRUPT                       ; Type
	DC.B -60                                ; Prio
	DC.L VBLInterruptName                   ; Name
	DC.L 0                                  ; Data
	DC.L VBLInterruptCode                   ; Code

	EVEN
VBLInterruptName:
	DC.B "VBLCounter",0


;******************************************************************************
;*
	SECTION S_2,DATA
;*
;******************************************************************************


SpriteList

SprSorceressIdle
	DC.w (31-1)*16                          ; Count
	DC.l 0                                  ; Left
	DC.l 5                                  ; Top
	DC.l 164                                ; Width
	DC.l 217                                ; Height
	DC.l 0                                  ; StepX
	DC.l 0                                  ; StepY
	DC.w 0                                  ; Index
	DC.l 164*217*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprFighter
	DC.w (36-1)*16                          ; Count
	DC.l 80*1                               ; Left
	DC.l SCREENHEIGHT-60-259                ; Top
	DC.l 176                                ; Width
	DC.l 259                                ; Height
	DC.l 4                                  ; StepX
	DC.l 4                                  ; StepY
	DC.w 0                                  ; Index
	DC.l 176*259*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprAmazon
	DC.w (12-1)*16                          ; Count
	DC.l 80*2                               ; Left
	DC.l SCREENHEIGHT-55-248                ; Top
	DC.l 152                                ; Width
	DC.l 248                                ; Height
	DC.l 36                                 ; StepX
	DC.l 36                                 ; StepY
	DC.w 0                                  ; Index
	DC.l 152*248*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprElf
	DC.w (12-1)*16                          ; Count
	DC.l 80*3                               ; Left
	DC.l SCREENHEIGHT-45-240                ; Top
	DC.l 164                                ; Width
	DC.l 240                                ; Height
	DC.l 32                                 ; StepX
	DC.l 32                                 ; StepY
	DC.w 0                                  ; Index
	DC.l 164*240*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprWizard
	DC.w (12-1)*16                          ; Count
	DC.l 80*4                               ; Left
	DC.l SCREENHEIGHT-40-216                ; Top
	DC.l 144                                ; Width
	DC.l 216                                ; Height
	DC.l 28                                 ; StepX
	DC.l 28                                 ; StepY
	DC.w 0                                  ; Index
	DC.l 144*216*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprSorceress
	DC.w (12-1)*16                          ; Count
	DC.l 80*5                               ; Left
	DC.l SCREENHEIGHT-35-214                ; Top
	DC.l 184                                ; Width
	DC.l 214                                ; Height
	DC.l 24                                 ; StepX
	DC.l 24                                 ; StepY
	DC.w 0                                  ; Index
	DC.l 184*214*2                          ; GfxSize
	DC.l 0                                  ; GfxData

SprDwarf
	DC.w (14-1)*16                          ; Count
	DC.l 80*5                               ; Left
	DC.l SCREENHEIGHT-30-187                ; Top
	DC.l 212                                ; Width
	DC.l 187                                ; Height
	DC.l 20                                 ; StepX
	DC.l 20                                 ; StepY
	DC.w 0                                  ; Index
	DC.l 212*187*2                          ; GfxSize
	DC.l 0                                  ; GfxData


;------------------------------------------------------------------------------


	EVEN
GfxFont				INCBIN "gfx/font-1-BE.bmp"     ; Digits Font
	EVEN
GfxIntro			INCBIN "gfx/intro-BE.bmp"      ; Intro Screen (960*540)
	EVEN
GfxOutro			INCBIN "gfx/outro-BE.bmp"      ; Outro Screen (960*540)
	EVEN
GfxBack				INCBIN "gfx/back-3-BE.bmp"     ; Castle ((960*3)*540)
	EVEN
GfxLogo				INCBIN "gfx/68080-200-BE.bmp"  ; Logo (200*200)
	EVEN
GfxCrown			INCBIN "gfx/crown-BE.bmp"      ; Crown (320*149)
	EVEN
GfxFighter			INCBIN "gfx/walk-1-BE.bmp"     ; Fighter Walk
	EVEN
GfxAmazon			INCBIN "gfx/walk-2-BE.bmp"     ; Amazon Walk
	EVEN
GfxWizard			INCBIN "gfx/walk-3-BE.bmp"     ; Wizard Walk
	EVEN
GfxElf				INCBIN "gfx/walk-4-BE.bmp"     ; Elf Walk
	EVEN
GfxDwarf			INCBIN "gfx/walk-5-BE.bmp"     ; Dwarf Walk
	EVEN
GfxSorceress		INCBIN "gfx/walk-6-BE.bmp"     ; Sorceress Walk
	EVEN
GfxSorceressIdle	INCBIN "gfx/idle-6-BE.bmp"     ; Sorceress Idle


;******************************************************************************
;*
	SECTION S_3,BSS
;*
;******************************************************************************


	EVEN
GfxLogoRLE		DS.W (LOGOWIDTH*LOGOHEIGHT)
	EVEN
GfxCrownRLE		DS.W (CROWNWIDTH*CROWNHEIGHT)


;******************************************************************************
;*
	SECTION S_4,DATA
;*
;******************************************************************************


	EVEN
VERSTRING:
	DC.B "$VER: VampireDemo2D 0.5 (2016-08-05) APOLLO-Team",10,0,0;


;******************************************************************************
;** 
    END
;**
;******************************************************************************
