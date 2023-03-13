.386                        ; ��������� ���������� ���������� 80386
locals                      ; ��������� ������������� ��������� ����������
jumps   
.model flat, STDCALL        ; ������ ������ ��� 32������ ��������
include Win32.inc           ; 32������ ��������� � ���������
include SPI.inc
include Time.inc
include Shell.inc

L equ <LARGE>               ; ��������� ����

; ��� ����
WndStyle = WS_POPUP OR WS_SYSMENU
WndStyleEx = WS_EX_TOOLWINDOW OR WS_EX_TOPMOST ;OR WS_EX_CLIENTEDGE OR WS_EX_DLGMODALFRAME

WM_ICONMSG = WM_USER + 100H

;
; ���������� ������� �������, �������� �� ����� ������������
;
extrn            BeginPaint:PROC
extrn            CheckMenuItem:PROC
extrn            CreateFontIndirectA:PROC
extrn            CreateSolidBrush:PROC
extrn            CreateWindowExA:PROC
extrn            DefWindowProcA:PROC
extrn            DeleteObject:PROC
extrn            DestroyIcon:PROC
extrn            DestroyMenu:PROC
extrn            DestroyWindow:PROC
extrn            DispatchMessageA:PROC
extrn            DrawEdge:PROC
extrn            DrawTextA:PROC
extrn            EnableMenuItem:PROC
extrn            EndPaint:PROC
extrn            ExitProcess:PROC
extrn            FillRect:PROC
extrn            FindWindowA:PROC
extrn            FormatMessageA:PROC
extrn            GetClientRect:PROC
extrn            GetCursorPos:PROC
extrn            GetDC:PROC
extrn            GetDeviceCaps:PROC
extrn            GetLocalTime:PROC
extrn            GetMessageA:PROC
extrn            GetModuleHandleA:PROC
extrn            GetSubMenu:PROC
extrn            GetSysColor:PROC
extrn            GetTextExtentPoint32A:PROC
extrn            InvalidateRect:PROC
extrn            KillTimer:PROC
extrn            LoadCursorA:PROC
extrn            LoadImageA:PROC
extrn            LoadMenuA:PROC
extrn            LoadStringA:PROC
extrn            MessageBoxA:PROC
extrn            MulDiv:PROC
extrn            PostQuitMessage:PROC
extrn            RegisterClassA:PROC
extrn            ReleaseDC:PROC
extrn            SelectObject:PROC
extrn            SetBkMode:PROC
extrn            SetTextColor:PROC
extrn            SetTimer:PROC
extrn            SetWindowPos:PROC
extrn            ShellAboutA:PROC
extrn            ShowWindow:PROC
extrn            SystemParametersInfoA:PROC
extrn            TrackPopupMenu:PROC
extrn            UpdateWindow:PROC

;
; ��� ��������� Unicode Win32 ��������� ��������� ������� �� Ansi � Unicode
; 
CreateFontIndirect      equ <CreateFontIndirectA>
CreateWindowEx          equ <CreateWindowExA>
DefWindowProc           equ <DefWindowProcA>
DispatchMessage         equ <DispatchMessageA>
DrawText                equ <DrawTextA>
FindWindow              equ <FindWindowA>
FormatMessage           equ <FormatMessageA>
GetMessage              equ <GetMessageA>
GetModuleHandle         equ <GetModuleHandleA>
GetTextExtentPoint32    equ <GetTextExtentPoint32A>
InsertMenu              equ <InsertMenuA>
LoadCursor              equ <LoadCursorA>
LoadImage               equ <LoadImageA>
LoadMenu                equ <LoadMenuA>
LoadString              equ <LoadStringA>
MessageBox              equ <MessageBoxA>
RegisterClass           equ <RegisterClassA>
ShellAbout              equ <ShellAboutA>
SystemParametersInfo    equ <SystemParametersInfoA>

.data           ; ������������������ ������
; ������, ���������� ��������� �� ��������� ������
CopyrightMsg    db '������ 1.20 �� 20 ����� 2001 �.', 13, 10
                db 169, ' iaSoft (������ �������), 1998-2001', 0

szTitleName     db '����', 0                 ; ��������� ����
szClassName     db 'ClockWindow', 0          ; ��� ��������� ������

FaceName        db 'Ms Sans Serif', 0        ; �����, ������������ ��� ������
FaceLength      = $ - FaceName

FormatedTime    db ' '
TimeString      db '00:00:00', 0             ; ������ �� ��������
MaxTimeBufSize  =  10
FormatString    db ' %1!2d!:%2!02d!'
FormatSeconds   db ':%3!02d!', 0             ; ������ ��� ��������������
SecondsFlag     db 1                         ; ������� ������ ������

ALIGN 4

TextRect        RECT <0, 0>

TrayIconData    NOTIFYICONDATA <>
TrayIconID      = 1000H
TrayIconTip     db '����', 0
TrayIconTipLen  = $ - TrayIconTip
TrayIconMinTip  db '���� (��������)', 0
TrayIcoMinLen   = $ - TrayIconMinTip

.data?           ; �������������������� ������

lppaint         PAINTSTRUCT <?> ; ��������� ��� ��������� ����
msg             MSGSTRUCT   <?> ; ��������� ��� ��������� ���������
wc              WNDCLASS    <?> ; ����� ����

hWindow         dd ?            ; ������������� ����

hInst           dd ?            ; ������������� ��������

hFont           dd ?            ; ������������� ���������� ������
hOldFont        dd ?            ; ����� �� ��������� ����������

hDC             dd ?            ; �������� ����������, ������������ ���
                                ;   �������� ������ ������
hTimer          dd ?            ; ������������� ���������� �������
TimerID         = 1

hIcon           dd ?            ; ������������� ������ � ������ �����
hMinIcon        dd ?            ; ������������� ������ � ������ ����� ���
                                ;   ��������������� ����
hMenu           dd ?            ; ������������� ����
hPopupMenu      dd ?            ; ������������� ����������� ����
hBrush          dd ?

WorkArea        RECT <?>        ; ������ ������, ��������� ������� �����

CursorPos       POINT <?>       ; ��������� �������

TextSize        TSIZE <?>       ; ��������� ��� ��������� ������� ������
             
Font            LOGFONT <?>     ; ��������� ��� �������� ������

Time            SYSTEMTIME <?>  ; ��������� ��� ��������� ���������� �������

Arguments       dd 3 dup(?)     ; ������, ���������� ���������� ���
                                ;   ��������������


; ������ �����, ����������� �� ��������, ��� ����������� � MessageBox'�
TitleSize       = 30
InfoSize        = 200
MBTitle         db TitleSize dup(?)     ; ��������� MessageBox'�
MBInfo          db InfoSize dup(?)      ; ���������


.code           ; ��� ���������
;-----------------------------------------------------------------------------
;
; ���� ��� ���������� ���������� �� ����������.
;
start:
;*****************************************************************************
; �������� ������������� ������ 
;*****************************************************************************
        push    L 0
        call    GetModuleHandle
        mov     [hInst], eax

;*****************************************************************************
; ��������� ������� ��� ���������� �����
;*****************************************************************************

        push    L 0
        push    offset szClassName
        call    FindWindow

        or      eax,eax
        jnz     ClockAlreadyRunning

;*****************************************************************************
; ���������������� ��������� WndClass (��������� ������) �
;   ���������������� �������� �����
;*****************************************************************************
        mov     [wc.clsStyle], CS_HREDRAW + CS_VREDRAW
        mov     [wc.clsLpfnWndProc], offset WndProc ; ������� ���������
        mov     [wc.clsCbClsExtra], 0
        mov     [wc.clsCbWndExtra], 0

        mov     eax, [hInst]
        mov     [wc.clsHInstance], eax

        mov     [wc.clsHIcon], 0

        ; ��������� ������ ��� ����������
        push    L IDC_ARROW
        push    L 0
        call    LoadCursor
        mov     [wc.clsHCursor], eax

        mov     [wc.clsHbrBackground], COLOR_BTNFACE + 1
        mov     dword ptr [wc.clsLpszMenuName], 0
        mov     dword ptr [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClass           ; ���������������� ������� �����

;*****************************************************************************
; ������� ����� �����
;*****************************************************************************
        ; �������� ���������� ��������� LOGFONT
        mov     edi, offset Font  
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        ; ��������� �������� ��������� ������ lfHeight �� �������
        ;  Font.lfHeight = -MulDiv(FontSize, GetDeviceCaps(DC, LOGPIXELSY), 72)
        push    L 72                    ; ��������� �������� MulDiv

        ; �������� �������� ����������
        push    L 0                     ; ������������� ���� (�� ������ �
                                        ;   ���������� �����
        call    GetDC
        mov     [hDC], eax              ; ��������� ���������� ���������

        ; �������� ���������� �������� �� ���������� ���� �� ������ ������
        push    L 90                    ; LOGPIXELSY
        push    [hDC]
        call    GetDeviceCaps
        push    eax                     ; ������ �������� MulDiv

        push    L 8                     ; ������ �������� MulDiv
        call    MulDiv

        neg     eax                     ; �������� ����

        ; ��������� ��������� LOGFONT
        mov     [Font.lfHeight], eax
        mov     [Font.lfCharSet], DEFAULT_CHARSET
        mov     Font.lfOutPrecision, OUT_DEVICE_PRECIS
        mov     Font.lfClipPrecision, CLIP_DEFAULT_PRECIS       
        mov     Font.lfQuality, PROOF_QUALITY
        mov     Font.lfPitchAndFamily, DEFAULT_PITCH OR FF_DONTCARE

        ; �������� ��� ������
        lea     edi, Font.lfFaceName 
        lea     esi, FaceName
        mov     ecx, FaceLength
        rep     movsb

        ; ������� �����
        push    offset Font
        call    CreateFontIndirect

        mov     [hFont], eax            ; ��������� ������������� ������ ������

;*****************************************************************************
; ������� ����
;*****************************************************************************
        push    L 0                     ; lpParam
        push    [hInst]                 ; hInstance
        push    L 0                     ; menu
        push    L 0                     ; parent hwnd

;-----------------------------------------------------------------------------
; ��������� ������ ���� � ��� ����������
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
; ��������� ������ ������
;-----------------------------------------------------------------------------
        ; ������� ����� � ��������
        push    [hFont]
        push    [hDC]
        call    SelectObject
        mov     [hOldFont], eax         ; ��������� ������ �����

        ; �������� ������ ������
        push    offset TextSize
        push    L 8
        push    offset TimeString
        push    [hDC]
        call    GetTextExtentPoint32

        ; ������������ �����
        push    [hOldFont]
        push    [hDC]
        call    SelectObject

        ; ���������� �������� ����������
        push    [hDC]
        push    L 0
        call    ReleaseDC

;-----------------------------------------------------------------------------
; ���������� ������ ����
;-----------------------------------------------------------------------------
        mov     ebx, eax
        add     eax, TextSize.tsCY
        add     eax, 8                  ;10
        push    eax                     ; ������ ����

        add     ebx, TextSize.tsCX
        add     ebx, 14
        push    ebx                     ; ������ ����

        call    EvaluateCoords          ; �������� ���������� ����
        push    eax                     ; �������� x
        push    ebx                     ; �������� y

        push    L WndStyle               ; Style
        push    offset szTitleName       ; Title string
        push    offset szClassName       ; Class name
        push    L WndStyleEx             ; extra style

        call    CreateWindowEx

        mov     [hWindow], eax           ; ��������� ������������� ����
        or      eax, eax
        jz      WindowError             ; �� ������� ������� ����

;*****************************************************************************
; ������� ������ ��� ����������� �������
;*****************************************************************************

        push    L 0                     ; lpTimerProc (����������)
        push    L 1000                  ; uElapse (�������� 1 �������)
        push    L TimerID               ; nIDEvent
        push    [hWindow]               ; hWnd
        call    SetTimer

        mov     [hTimer], eax           ; ��������� �������������

        or      eax, eax                ; ��������� ������� ������
        jz      TimerError
        
        ; ��������������� �����
        call    FormatTime

;*****************************************************************************
; ���������� ����
;*****************************************************************************

        ; �������� ����
        push    L SW_SHOWNORMAL
        push    [hWindow]
        call    ShowWindow

        ; ���������� ���������� � ����
        push    [hWindow]
        call    UpdateWindow

;*****************************************************************************
; ��������� ���� �� ��������
;*****************************************************************************

        ; ��������� ������� ����
        push    L 1
        push    [hInst]
        call    LoadMenu

        mov     [hMenu], eax            ; ��������� �������������

        ; �������� ������������� ����������� ����
        push    L 0
        push    [hMenu]
        call    GetSubMenu

        mov     [hPopupMenu], eax       ; ��������� ���

;*****************************************************************************
; ��������� ������ � ������ ����� 
;*****************************************************************************

        ; ��������� ������ 16�16
        push    L 0                     ; fuLoad
        push    L 16                    ; cyDesired
        push    L 16                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 1                     ; lpszName
        push    [hInst]
        call    LoadImage
        mov     [hIcon], eax
        
        ; ��������� ���������
        mov     eax, [hWindow]
        mov     [TrayIconData.nidWindow], eax
        mov     [TrayIconData.nidID], TrayIconID
        mov     [TrayIconData.nidFlags], NIF_ICON OR NIF_TIP OR NIF_MESSAGE
        mov     [TrayIconData.nidCallbackMessage], WM_ICONMSG

        mov     eax, [hIcon]
        mov     [TrayIconData.nidIcon], eax

        mov     edi, offset TrayIconData.nidTip
        mov     esi, offset TrayIconTip
        mov     ecx, TrayIconTipLen
        cld
        rep     movsb

        ; ��������� � ������ �����
        push    offset TrayIconData
        push    L NIM_ADD
        call    Shell_NotifyIcon

        ; ��������� ������ 16�16 ��� ��������������� ����
        push    L 0                     ; fuLoad
        push    L 16                    ; cyDesired
        push    L 16                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 2                     ; lpszName
        push    [hInst]
        call    LoadImage
        mov     [hMinIcon], eax

;-----------------------------------------------------------------------------
msg_loop: ; ���� ��������� ���������
        push    L 0
        push    L 0
        push    L 0
        push    offset msg
        call    GetMessage

        cmp     ax, 0
        je      end_loop

        push    offset msg
        call    DispatchMessage
                                          
        jmp     msg_loop

end_loop:
        push    [msg.msWPARAM]
        call    ExitProcess       ; ��������� �������

        ; �� ������� �� ������ ����

;*****************************************************************************
; �������� ������ ��� �������� ����
;*****************************************************************************

WindowError:
        ; ��������� ������ �� ��������
        push    L TitleSize
        push    offset MBTitle
        push    L 102
        push    [hInst]
        call    LoadString

        push    L InfoSize
        push    offset MBInfo
        push    L 101
        push    [hInst]
        call    LoadString

        push    L MB_ICONSTOP
        push    offset MBTitle
        push    offset MBInfo
        push    [hWindow]
        call    MessageBox

        ; ��������� ���������� ���������
        push    L -1
        call    ExitProcess


;*****************************************************************************
; �������� ������ ��� �������� �������
;*****************************************************************************

TimerError:

;-----------------------------------------------------------------------------
; ������� ��������� �� ������
;-----------------------------------------------------------------------------

        ; ��������� ������ �� ��������
        push    L TitleSize
        push    offset MBTitle
        push    L 102
        push    [hInst]
        call    LoadString

        push    L InfoSize
        push    offset MBInfo
        push    L 105
        push    [hInst]
        call    LoadString

        push    L MB_ICONSTOP
        push    offset MBTitle
        push    offset MBInfo
        push    [hWindow]
        call    MessageBox

        ; ������� ����
        push    [hWindow]
        call    DestroyWindow

        ; ��������� ���������� ���������
        push    L -1
        call    ExitProcess

ClockAlreadyRunning:

;-----------------------------------------------------------------------------
; ������� ��������� � ���, ��� ��������� ��� ��������
;-----------------------------------------------------------------------------

        ; ��������� ������ �� ��������
        push    L TitleSize
        push    offset MBTitle
        push    L 104
        push    [hInst]
        call    LoadString

        push    L InfoSize
        push    offset MBInfo
        push    L 103
        push    [hInst]
        call    LoadString

        push    L MB_ICONSTOP
        push    offset MBTitle
        push    offset MBInfo
        push    L 0
        call    MessageBox

        ; ��������� ���������� ���������
        push    L -1
        call    ExitProcess

;*****************************************************************************
;*****                                                                   *****
;*****                        �������� ��������                          *****
;*****                                                                   *****
;*****************************************************************************


;-----------------------------------------------------------------------------
EvaluateCoords PROC
;
;  �������� ������ ����: EBX - ������, EAX - ������.
;  ���������� ���������� X � �������� EBX � Y � EAX.
;
        ; ��������� ��������
        push    ebx
        push    eax

;-----------------------------------------------------------------------------
; �������� ������ ������
;-----------------------------------------------------------------------------
        push    L 0
        push    offset WorkArea
        push    L 0
        push    SPI_GETWORKAREA
        call    SystemParametersInfo

        pop     ebx                     ; ������������ ������� (������)
        mov     eax, WorkArea.rcBottom
        sub     eax, ebx
 
        pop     edx                     ; ������������ ������� (������)

        mov     ebx, WorkArea.rcRight
        sub     ebx, edx

        ret
EvaluateCoords ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
PaintWindow PROC
;
;  �� ����� EAX ������ ��������� ��������, � ������� ������� �����������
;    ����������� �����, � EBX ������������� ����, ������� ����� ����-
;    ������������.
;
        LOCAL   @@hDC: DWORD            ; ��������� ����������, ����������
                                        ;   �������� ����������
        LOCAL   @@hWnd: DWORD           ; �������������� ����, � �������
                                        ;   ��������� ����������� ��������
        LOCAL   @@hOldPen: DWORD        ; ������������� ������� ����

        mov     [@@hDC], eax            ; ��������� ���������� ��������������
        mov     [@@hWnd], ebx

        ; �������� ������ ���������� ������� ����
        push    offset TextRect
        push    [@@hWnd]
        call    GetClientRect

;----------------------------------------------------------------------------
; ������� ����������� ����������� ��� ����������� ����
;----------------------------------------------------------------------------
        push    L BF_LEFT OR BF_RIGHT OR BF_TOP OR BF_ADJUST
                                        ; ������������� ��� ������ ������� +
                                        ;  ������������ �������� ����� ��������
                                        ;  �� ��������������
        push    L EDGE_RAISED           ; ����������� ���� ����
        push    offset TextRect         ; ���������� ��������������, ���
                                        ;   �������� �������� �������
        push    [@@hDC]                 ; �������� ����������
        call    DrawEdge                ; ������

        push    L BF_RECT OR BF_ADJUST  ; ����� �������������
        push    L EDGE_SUNKEN           ; ���������� ���� ����
        push    offset TextRect         ; ���������� ��������������
        push    [@@hDC]                 ; �������� ����������
        call    DrawEdge                ; ������

        mov     eax, [@@hDC]            ; �������� ��������-�������� ����������
        call    PaintTime               ; ������ �����

        ret
PaintWindow ENDP
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
PaintTime PROC
;
; �� ����� EAX �������� ������������� ��������� ����������
;
        LOCAL @@hDC: DWORD

        mov     [@@hDC], eax

        push    L 1               ; ������ ��� ����������, �����
        push    [@@hDC]           ;   ������� DrawText �� ���������
        call    SetBkMode         ;   ������� ��� ���

        ; ���������� ���� ������ � ����, ������� ������ �������������
        push    L COLOR_WINDOWTEXT
        call    GetSysColor

        push    eax
        push    [@@hDC]
        call    SetTextColor

        ; ������� �����
        push    [hFont]                 ; ������� ��������� ����� � ��������
        push    [@@hDC]
        call    SelectObject
        mov     [hOldFont], eax         ; ��������� ������ �����


        push    L DT_SINGLELINE OR DT_CENTER OR DT_VCENTER ; uFormat
        push    offset TextRect         ; lpRect
        push    L -1                    ; ����� ������ (������ ������������ �����)
        push    offset TimeString
        push    [@@hDC]
        call    DrawText

        push    [hOldFont]
        push    [@@hDC]
        call    SelectObject

        ret 
PaintTime ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
FormatTime PROC
;
;  ����������� ����� 
;
        ; �������� �����
        push    offset Time
        call    GetLocalTime

        ; ��������� ����, ������ � ������� � �������
        xor     eax, eax
        mov     ax, [Time.wHour]
        mov     [Arguments], eax
        mov     ax, [Time.wMinute]
        mov     [Arguments + 4], eax
        mov     ax, [Time.wSecond]
        mov     [Arguments + 8], eax

        push    offset Arguments        ; Arguments
        push    L MaxTimeBufSize        ; nSize
        push    offset FormatedTime     ; lpBuffer
        push    L 0                     ; dwLanguageId
        push    L 0                     ; dwMessageId
        push    offset FormatString     ; lpSource
        push    FORMAT_MESSAGE_FROM_STRING OR FORMAT_MESSAGE_ARGUMENT_ARRAY
        call    FormatMessage

        ret
FormatTime ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
WndProc          proc uses ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
;
; ��������: Win32 �������, ����� EBX, EDI � ESI ���� ���������!  �� �������-
; ������ ����� ������� � ������� ������������ ���� ��������� ����� ���������
; uses ��� �������� ���������. ��� ��������, ����� ��������� �������������
; �������� ��� �������� ��� ���
;
        cmp     [wmsg], WM_SYSCOLORCHANGE   ; �������������� ���������
        je      wmsyscolorchange

        cmp     [wmsg], WM_DESTROY
        je      wmdestroy

        cmp     [wmsg], WM_PAINT
        je      wmpaint

        cmp     [wmsg], WM_TIMER
        je      wmtimer

        cmp     [wmsg], WM_RBUTTONUP
        je      ShowMenu

        cmp     [wmsg], WM_LBUTTONUP
        je      ShowMenu

        cmp     [wmsg], WM_COMMAND
        je      wmcommand

        cmp     [wmsg], WM_ICONMSG
        je      wmiconmsg

        cmp     [wmsg], WM_DISPLAYCHANGE
        je      wmdisplaychange

        jmp     defwndproc          ; ��� ���������������� ����������
                                    ;  ���������    
wmsyscolorchange:
        ; ������������ ���������� ����
        push    L 1
        push    L 0
        push    [hWindow]
        call    InvalidateRect

        xor     eax, eax
        jmp     finish

wmpaint:        ; ����������� ����
        ; ������ ��������
        push    offset lppaint
        push    [hwnd]
        call    BeginPaint

        mov     ebx, [hwnd]

        call    PaintWindow

        ; ��������� ��������
        push    offset lppaint
        push    [hwnd]
        call    EndPaint

        mov     eax, 0                  ; ��������� ��������� ���������
        jmp     finish

defwndproc:     ; ���������������� ���������
        push    [lparam]
        push    [wparam]
        push    [wmsg]
        push    [hwnd]
        call    DefWindowProc           ; ������� ������� �������� �� ���������
        jmp     finish

wmtimer:
        ; ��������������� �����
        call    FormatTime

        or      eax, eax                ; ��������� ������
        jz      finish

        ; �������� ������ ���������� �������
        push    offset TextRect
        push    [hwnd]
        call    GetClientRect

        mov     [TextRect.rcLeft], 5
        mov     [TextRect.rcTop], 5
        sub     [TextRect.rcRight], 6
        sub     [TextRect.rcBottom], 4

        push    [hwnd]
        call    GetDC

        mov     [hDC], eax

        ; ������� �����
        push    L COLOR_BTNFACE
        call    GetSysColor

        push    eax
        call    CreateSolidBrush
        mov     [hBrush], eax

        push    [hBrush]
        push    offset TextRect
        push    [hDC]
        call    FillRect

        mov     eax, [hDC]
        call    PaintTime

        ; ������� �����
        push    [hBrush]
        call    DeleteObject

        push    [hDC]
        push    [hwnd]
        call    ReleaseDC

        mov     eax, 0
        jmp     finish

ShowMenu:
        push    offset CursorPos
        call    GetCursorPos

        push    L 0                     ; *prcRect
        push    [hwnd]                  ; hWnd
        push    L 0                     ; nReserved
        push    [CursorPos.ptY]         ; y
        push    [CursorPos.ptX]         ; x
        push    L 0     ;TPM_LEFTALIGN OR TPM_RIGHTBUTTON    ; uFlags
        push    [hPopupMenu]
        call    TrackPopupMenu

        mov     eax, 0
        jmp     finish

wmcommand:
        xor     eax, eax

        mov     ebx, [wparam]

        test    ebx, 0FFFF0000H
        jnz     finish

        cmp     bx, 100
        je      RestoreCommand

        cmp     bx, 101
        je      MinimizeCommand

        cmp     bx, 102
        je      SecondsCommand

        cmp     bx, 103
        je      AboutCommand

        ; �������
        push    [hWindow]
        call    DestroyWindow
        
        xor     eax, eax
        jmp     finish

RestoreCommand:
        ; �������� ���� �� ������
        push    L SW_SHOW
        push    [hWindow]
        call    ShowWindow

        ; ��������� ������� ������������
        push    L MF_GRAYED
        push    L 100
        push    [hMenu]
        call    EnableMenuItem

        ; ��������� ������� ��������
        push    L MF_ENABLED
        push    L 101
        push    [hMenu]
        call    EnableMenuItem

;----------------------------------------------------------------------------
; ���������� ������� ������
;----------------------------------------------------------------------------

        ; ��������� ���������
        mov     eax, [hWindow]
        mov     [TrayIconData.nidWindow], eax
        mov     [TrayIconData.nidID], TrayIconID
        mov     [TrayIconData.nidFlags], NIF_ICON OR NIF_TIP

        mov     eax, [hIcon]
        mov     [TrayIconData.nidIcon], eax

        mov     edi, offset TrayIconData.nidTip
        mov     esi, offset TrayIconTip
        mov     ecx, TrayIconTipLen
        cld
        rep     movsb

        ; �������� ������ � ������ �����
        push    offset TrayIconData
        push    L NIM_MODIFY
        call    Shell_NotifyIcon

        xor     eax, eax
        jmp     finish

MinimizeCommand:
        ; ������ ���� � ������
        push    L SW_HIDE
        push    [hWindow]
        call    ShowWindow

        ; ��������� ������� ������������
        push    L MF_ENABLED
        push    L 100
        push    [hMenu]
        call    EnableMenuItem

        ; ��������� ������� ��������
        push    L MF_GRAYED
        push    L 101
        push    [hMenu]
        call    EnableMenuItem

;----------------------------------------------------------------------------
; ���������� ������ ��� �������� ����
;----------------------------------------------------------------------------

        ; ��������� ���������
        mov     eax, [hWindow]
        mov     [TrayIconData.nidWindow], eax
        mov     [TrayIconData.nidID], TrayIconID
        mov     [TrayIconData.nidFlags], NIF_ICON OR NIF_TIP

        mov     eax, [hMinIcon]
        mov     [TrayIconData.nidIcon], eax

        mov     edi, offset TrayIconData.nidTip
        mov     esi, offset TrayIconMinTip
        mov     ecx, TrayIcoMinLen
        cld
        rep     movsb

        ; �������� ������ � ������ �����
        push    offset TrayIconData
        push    L NIM_MODIFY
        call    Shell_NotifyIcon

        xor     eax, eax
        jmp     finish

SecondsCommand:
        ; �������� ��������� �����
        xor     SecondsFlag, 1
        jz      UncheckSeconds          ; ���� ���� ����� - ������� �������

;-----------------------------------------------------------------------------
; ��������� ����� ������
;-----------------------------------------------------------------------------
        mov     FormatSeconds, ':'      ; �������� ������ ��� ������

        ; ���������� ������ � ����
        push    L MF_CHECKED
        push    L 102
        push    [hMenu]
        call    CheckMenuItem

        jmp     SecondsCommandEnd

UncheckSeconds:
;-----------------------------------------------------------------------------
; ������� ����� ������
;-----------------------------------------------------------------------------
        mov     FormatSeconds, 0        ; ������� ������ ��� ������

        ; ������� ������ � ����
        push    L MF_UNCHECKED
        push    L 102
        push    [hMenu]
        call    CheckMenuItem

SecondsCommandEnd:
        ; ����������������� �����
        call    FormatTime

        ; ������������ ���������� ����
        push    L 1
        push    L 0
        push    [hWindow]
        call    InvalidateRect

        xor     eax, eax
        jmp     finish

AboutCommand:
        ; � ���������
        ; ��������� ������ 16�16 ��� ��������������� ����
        push    L 0                     ; fuLoad
        push    L 48                    ; cyDesired
        push    L 48                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 1                     ; lpszName
        push    [hInst]
        call    LoadImage

        push    eax                     ; �������� ��� �������� ��� DestroyIcon
        push    eax                     ; �������� ��� �������� ��� ShellAbout

        push    offset CopyrightMsg     ; �������� ���������
        push    offset szTitleName      ; ���������
        push    [hWindow]               ; ��������� ����
        call    ShellAbout              ; ������� ������

        call    DestroyIcon             ; ������� �������� ������

        xor     eax, eax
        jmp     finish

wmiconmsg:
        cmp     [lparam], WM_LBUTTONUP
        je      ShowMenu

        cmp     [lparam], WM_RBUTTONUP
        je      ShowMenu

        xor     eax, eax
        jmp     finish

wmdisplaychange:
        ; ���������� ���������� ������ -- ���������� ����
        ;   �� ���� �����
        push    offset TextRect
        push    [hWindow]
        call    GetClientRect

        mov     eax, [TextRect.rcBottom]
        mov     ebx, [TextRect.rcRight]
        call    EvaluateCoords

        push    L SWP_NOZORDER OR SWP_NOSIZE OR SWP_NOOWNERZORDER OR SWP_NOACTIVATE
        push    L 0                     ; cy
        push    L 0                     ; cx
        push    eax                     ; y
        push    ebx                     ; x
        push    L 0                     ; hWndInsertAfter
        push    [hWindow]
        call    SetWindowPos

        xor     eax, eax
        jmp     finish

wmdestroy:      ; ���������� ���� � ���������� ������

        ; ������� ��������� �����
        push    [hFont]
        call    DeleteObject

        ; ������� ����
        push    [hMenu]
        call    DestroyMenu

        ; ������� ������ �� ������ �����
        mov     eax, [hWindow]
        mov     [TrayIconData.nidWindow], eax
        mov     [TrayIconData.nidID], TrayIconID
        mov     [TrayIconData.nidFlags], 0

        push    offset TrayIconData
        push    L NIM_DELETE
        call    Shell_NotifyIcon

        ; ������� ������
        push    [hIcon]
        call    DestroyIcon

        push    [hMinIcon]
        call    DestroyIcon

        ; ������� ������, ���� �� ��� ������
        mov     eax, [hTimer]
        or      eax, eax
        jz      @@PostMessage           ; ������ �� ��� ������

        push    L TimerID
        push    [hWindow]
        call    KillTimer

@@PostMessage:
        push    L 0
        call    PostQuitMessage

        xor     eax, eax

finish:
        ret
WndProc          endp
;-----------------------------------------------------------------------------
public WndProc
ends
end start

