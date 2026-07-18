;*******************************************************************************
; VAMPIRE TOOLBOX
;*******************************************************************************
; Constant.s
;
; Constants definition
;
; Version 2.0 August 2024
; Fabrice "Lexo" Labrador <fabrice.labrador@gmail.com>
;*******************************************************************************

; Program errors
ERR_NONE            = 0
ERR_NOT080          = 1
ERR_NOTV4           = 2
ERR_DOSLIB          = 3
ERR_GFXLIB          = 4

; Status constants
NULL                = 0
TRUE                = -1
FALSE               = 0
EOL                 = $0A

; EXEC functions
_ExecBase           = $4
_Supervisor         = -$1E
_Forbid             = -$84
_Permit             = -$8A
_AllocMem           = -$C6
_FreeMem            = -$D2
_CloseLibrary       = -$19E
_OpenLibrary        = -$228

; Exec constants
EXEC_ATTNFLAGS      = $128
EXEC_AF68080        = $A

; GRAPHICS functions
_LoadView           = -$DE
_WaitBlit           = -$E4
_WaitTOF            = -$10E

; Graphics constants
GFX_ACTIVEVIEW      = $22
GFX_COPPERLIST      = $26

; DOS functions
_Open               = -$1E
_Close              = -$24
_Read               = -$2A
_Write              = -$30
_Seek               = -$42
_PutStr             = -$3B4

; Interrupts vectors
VEC_ETH             = $48
VEC_AUDIO2          = $50
VEC_KBD             = $68
VEC_VBL             = $6C
VEC_AUDIO           = $70
VEC_TRAP0           = $80

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
INT_ETH             = $2000
INT_AUD7            = $0008
INT_AUD6            = $0004
INT_AUD5            = $0002
INT_AUD4            = $0001
INT_STOP            = $7FFF

; IT and DMA for DOS functions
DOS_INTENA          = INT_PORTS
DOS_DMA             = DMA_BLITTER|DMA_DISK

; Joystick / mouse CIA bits
MOUSE_BUTTON1       = 6
MOUSE_BUTTON2       = 2
JOY_BUTTON1         = 7

; Card versions
CARD_V600           = 1
CARD_V500           = 2
CARD_V4_500         = 3
CARD_V4_1200        = 4
CARD_V4SA           = 5
CARD_V1200          = 6
CARD_V4_600         = 7

; SAGA enable
SAGA_ENABLE         = $1C

; SAGA resolutions
VRES_NONE           = $0000
VRES_320x200        = $0100
VRES_320x240        = $0200
VRES_320x256        = $0300
VRES_640x400        = $0400
VRES_640x480        = $0500
VRES_640x512        = $0600
VRES_960x540        = $0700
VRES_480x270        = $0800
VRES_304x224        = $0900
VRES_1280x720       = $0A00
VRES_640x360        = $0B00
VRES_800x600        = $0C00
VRES_1024x768       = $0D00
VRES_720x576        = $0E00
VRES_848x480        = $0F00
VRES_640x200        = $1000
VRES_1920x1080      = $1100
VRES_1280x1024      = $1200
VRES_1280x800       = $1300
VRES_1440x900       = $1400

; SAGA pixel format
PIXF_NONE           = $00
PIXF_CLUT           = $01           ; 8bit (indexed)
PIXF_R5G6B5         = $02           ; 16bit R5G6B5
PIXF_R5G5B5         = $03           ; 15bit R5G5B5
PIXF_R8G8B8         = $04           ; 24bit R8G8B8
PIXF_A8R8G8B8       = $05           ; 32bit A8R8G8B8
PIXF_YUV            = $06           ; YUV
PIXF_P1BIT          = $08           ; Planar 1bit
PIXF_P2BIT          = $09           ; Planar 2bit
PIXF_P4BIT          = $0A           ; Planar 4bit
PIXF_P8BIT          = $0B           ; Planar 8bit
