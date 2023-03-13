.386                        ; Разрешить инструкции процессора 80386
locals                      ; Разрешить использование локальных переменных
jumps   
.model flat, STDCALL        ; Задать модель для 32битных программ
include Win32.inc           ; 32битные константы и структуры
include SPI.inc
include Time.inc
include Shell.inc

L equ <LARGE>               ; Указатель типа

; Тип окна
WndStyle = WS_POPUP OR WS_SYSMENU
WndStyleEx = WS_EX_TOOLWINDOW OR WS_EX_TOPMOST ;OR WS_EX_CLIENTEDGE OR WS_EX_DLGMODALFRAME

WM_ICONMSG = WM_USER + 100H

;
; Определяем внешние функции, которыми мы будем пользоваться
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
; Для поддержки Unicode Win32 разделяет некоторые функции на Ansi и Unicode
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

.data           ; Инициализированные данные
; Строка, содержащая сообшение об авторских правах
CopyrightMsg    db 'Версия 1.20 от 20 марта 2001 г.', 13, 10
                db 169, ' iaSoft (Иванов Алексей), 1998-2001', 0

szTitleName     db 'Часы', 0                 ; Заголовок окна
szClassName     db 'ClockWindow', 0          ; Имя окнонного класса

FaceName        db 'Ms Sans Serif', 0        ; Шрифт, используемый для вывода
FaceLength      = $ - FaceName

FormatedTime    db ' '
TimeString      db '00:00:00', 0             ; Строка со временем
MaxTimeBufSize  =  10
FormatString    db ' %1!2d!:%2!02d!'
FormatSeconds   db ':%3!02d!', 0             ; Строка для форматирования
SecondsFlag     db 1                         ; Признак вывода секунд

ALIGN 4

TextRect        RECT <0, 0>

TrayIconData    NOTIFYICONDATA <>
TrayIconID      = 1000H
TrayIconTip     db 'Часы', 0
TrayIconTipLen  = $ - TrayIconTip
TrayIconMinTip  db 'Часы (свернуты)', 0
TrayIcoMinLen   = $ - TrayIconMinTip

.data?           ; Неинициализированные данные

lppaint         PAINTSTRUCT <?> ; Структура для рисования окна
msg             MSGSTRUCT   <?> ; Структура для получения сообщений
wc              WNDCLASS    <?> ; Класс окна

hWindow         dd ?            ; Идентификатор окна

hInst           dd ?            ; Идентификатор процесса

hFont           dd ?            ; Идентификатор созданного шрифта
hOldFont        dd ?            ; Шрифт из контекста устройства

hDC             dd ?            ; Контекст устройства, используемый для
                                ;   создания нового шрифта
hTimer          dd ?            ; Идентификатор созданного таймера
TimerID         = 1

hIcon           dd ?            ; Идентификатор иконки в Панели задач
hMinIcon        dd ?            ; Идентификатор иконки в Панели задач для
                                ;   неотображаемого окна
hMenu           dd ?            ; Идентификатор меню
hPopupMenu      dd ?            ; Идентификатор выпадающего меню
hBrush          dd ?

WorkArea        RECT <?>        ; Размер экрана, незанятый панелью задач

CursorPos       POINT <?>       ; Положение курсора

TextSize        TSIZE <?>       ; Структура для получения размера текста
             
Font            LOGFONT <?>     ; Структура для создания шрифта

Time            SYSTEMTIME <?>  ; Структура для получения системного времени

Arguments       dd 3 dup(?)     ; Массив, содержащий переменные для
                                ;   форматирования


; Буфера строк, загружаемых из ресурсов, для отображения в MessageBox'е
TitleSize       = 30
InfoSize        = 200
MBTitle         db TitleSize dup(?)     ; Заголовок MessageBox'а
MBInfo          db InfoSize dup(?)      ; Сообщение


.code           ; Код программы
;-----------------------------------------------------------------------------
;
; Сюда нам передается управление от загрузчика.
;
start:
;*****************************************************************************
; Получить идентификатор модуля 
;*****************************************************************************
        push    L 0
        call    GetModuleHandle
        mov     [hInst], eax

;*****************************************************************************
; Проверить наличие уже запущенных часов
;*****************************************************************************

        push    L 0
        push    offset szClassName
        call    FindWindow

        or      eax,eax
        jnz     ClockAlreadyRunning

;*****************************************************************************
; Инициализировать структуру WndClass (окнонного класса) и
;   зарегистрировать окнонный класс
;*****************************************************************************
        mov     [wc.clsStyle], CS_HREDRAW + CS_VREDRAW
        mov     [wc.clsLpfnWndProc], offset WndProc ; оконная процедура
        mov     [wc.clsCbClsExtra], 0
        mov     [wc.clsCbWndExtra], 0

        mov     eax, [hInst]
        mov     [wc.clsHInstance], eax

        mov     [wc.clsHIcon], 0

        ; Загрузить курсор для приложения
        push    L IDC_ARROW
        push    L 0
        call    LoadCursor
        mov     [wc.clsHCursor], eax

        mov     [wc.clsHbrBackground], COLOR_BTNFACE + 1
        mov     dword ptr [wc.clsLpszMenuName], 0
        mov     dword ptr [wc.clsLpszClassName], offset szClassName

        push    offset wc
        call    RegisterClass           ; Зарегистрировать оконный класс

;*****************************************************************************
; Создаем новый шрифт
;*****************************************************************************
        ; Обнулить содержимое структуры LOGFONT
        mov     edi, offset Font  
        mov     ecx, TYPE Font
        cld
        xor     al, al
        rep     stosb

        ; Вычислить значение параметра шрифта lfHeight по формуле
        ;  Font.lfHeight = -MulDiv(FontSize, GetDeviceCaps(DC, LOGPIXELSY), 72)
        push    L 72                    ; Последний параметр MulDiv

        ; Получить контекст устройства
        push    L 0                     ; Идентификатор окна (не связан с
                                        ;   физическим окном
        call    GetDC
        mov     [hDC], eax              ; Сохранить полученный результат

        ; Получить количество пикселов на логический дюйм по высоте экрана
        push    L 90                    ; LOGPIXELSY
        push    [hDC]
        call    GetDeviceCaps
        push    eax                     ; Второй параметр MulDiv

        push    L 8                     ; Первый параметр MulDiv
        call    MulDiv

        neg     eax                     ; Изменить знак

        ; Заполнить структуру LOGFONT
        mov     [Font.lfHeight], eax
        mov     [Font.lfCharSet], DEFAULT_CHARSET
        mov     Font.lfOutPrecision, OUT_DEVICE_PRECIS
        mov     Font.lfClipPrecision, CLIP_DEFAULT_PRECIS       
        mov     Font.lfQuality, PROOF_QUALITY
        mov     Font.lfPitchAndFamily, DEFAULT_PITCH OR FF_DONTCARE

        ; Копируем имя шрифта
        lea     edi, Font.lfFaceName 
        lea     esi, FaceName
        mov     ecx, FaceLength
        rep     movsb

        ; Создать шрифт
        push    offset Font
        call    CreateFontIndirect

        mov     [hFont], eax            ; Сохранить идентификатор нового шрифта

;*****************************************************************************
; Создать окно
;*****************************************************************************
        push    L 0                     ; lpParam
        push    [hInst]                 ; hInstance
        push    L 0                     ; menu
        push    L 0                     ; parent hwnd

;-----------------------------------------------------------------------------
; Вычислить размер окна и его координаты
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
; Вычислить размер текста
;-----------------------------------------------------------------------------
        ; Выбрать шрифт в контекст
        push    [hFont]
        push    [hDC]
        call    SelectObject
        mov     [hOldFont], eax         ; Сохранить старый шрифт

        ; Получить размер текста
        push    offset TextSize
        push    L 8
        push    offset TimeString
        push    [hDC]
        call    GetTextExtentPoint32

        ; Восстановить шрифт
        push    [hOldFont]
        push    [hDC]
        call    SelectObject

        ; Освободить контекст устройства
        push    [hDC]
        push    L 0
        call    ReleaseDC

;-----------------------------------------------------------------------------
; Установить размер окна
;-----------------------------------------------------------------------------
        mov     ebx, eax
        add     eax, TextSize.tsCY
        add     eax, 8                  ;10
        push    eax                     ; Высота окна

        add     ebx, TextSize.tsCX
        add     ebx, 14
        push    ebx                     ; Ширина окна

        call    EvaluateCoords          ; Получить координаты окна
        push    eax                     ; Передать x
        push    ebx                     ; Передать y

        push    L WndStyle               ; Style
        push    offset szTitleName       ; Title string
        push    offset szClassName       ; Class name
        push    L WndStyleEx             ; extra style

        call    CreateWindowEx

        mov     [hWindow], eax           ; Запомнить идентификатор окна
        or      eax, eax
        jz      WindowError             ; Не удалось создать окно

;*****************************************************************************
; Создать таймер для отображения времени
;*****************************************************************************

        push    L 0                     ; lpTimerProc (Отсутсвует)
        push    L 1000                  ; uElapse (Интервал 1 секунда)
        push    L TimerID               ; nIDEvent
        push    [hWindow]               ; hWnd
        call    SetTimer

        mov     [hTimer], eax           ; Сохранить идентификатор

        or      eax, eax                ; Проверить наличие ошибки
        jz      TimerError
        
        ; Отформатировать время
        call    FormatTime

;*****************************************************************************
; Отобразить окно
;*****************************************************************************

        ; Показать окно
        push    L SW_SHOWNORMAL
        push    [hWindow]
        call    ShowWindow

        ; Нарисовать содержимое в окне
        push    [hWindow]
        call    UpdateWindow

;*****************************************************************************
; Загрузить меню из ресурсов
;*****************************************************************************

        ; Загрузить главное меню
        push    L 1
        push    [hInst]
        call    LoadMenu

        mov     [hMenu], eax            ; Сохранить идентификатор

        ; Получить идентификатор выпадающего меню
        push    L 0
        push    [hMenu]
        call    GetSubMenu

        mov     [hPopupMenu], eax       ; Сохранить его

;*****************************************************************************
; Поместить иконку в панель задач 
;*****************************************************************************

        ; Загрузить иконку 16х16
        push    L 0                     ; fuLoad
        push    L 16                    ; cyDesired
        push    L 16                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 1                     ; lpszName
        push    [hInst]
        call    LoadImage
        mov     [hIcon], eax
        
        ; Заполнить структуру
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

        ; Поместить в Панель задач
        push    offset TrayIconData
        push    L NIM_ADD
        call    Shell_NotifyIcon

        ; Загрузить иконку 16х16 для неотображаемого окна
        push    L 0                     ; fuLoad
        push    L 16                    ; cyDesired
        push    L 16                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 2                     ; lpszName
        push    [hInst]
        call    LoadImage
        mov     [hMinIcon], eax

;-----------------------------------------------------------------------------
msg_loop: ; Цикл обработки сообщений
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
        call    ExitProcess       ; Завершить процесс

        ; Мы никогда не придем сюда

;*****************************************************************************
; Возникла ошибка при создании окна
;*****************************************************************************

WindowError:
        ; Загрузить строки из ресурсов
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

        ; Завершить выполнение программы
        push    L -1
        call    ExitProcess


;*****************************************************************************
; Возникла ошибка при создании таймера
;*****************************************************************************

TimerError:

;-----------------------------------------------------------------------------
; Вывести сообщение об ошибке
;-----------------------------------------------------------------------------

        ; Загрузить строки из ресурсов
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

        ; Удалить окно
        push    [hWindow]
        call    DestroyWindow

        ; Завершить выполнение программы
        push    L -1
        call    ExitProcess

ClockAlreadyRunning:

;-----------------------------------------------------------------------------
; Вывести сообщение о том, что программа уже запущена
;-----------------------------------------------------------------------------

        ; Загрузить строки из ресурсов
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

        ; Завершить выполнение программы
        push    L -1
        call    ExitProcess

;*****************************************************************************
;*****                                                                   *****
;*****                        Описание процедур                          *****
;*****                                                                   *****
;*****************************************************************************


;-----------------------------------------------------------------------------
EvaluateCoords PROC
;
;  Получает размер окна: EBX - ширина, EAX - высота.
;  Возвращает координату X в регистре EBX и Y в EAX.
;
        ; Сохранить регистры
        push    ebx
        push    eax

;-----------------------------------------------------------------------------
; Получить размер экрана
;-----------------------------------------------------------------------------
        push    L 0
        push    offset WorkArea
        push    L 0
        push    SPI_GETWORKAREA
        call    SystemParametersInfo

        pop     ebx                     ; Восстановить регистр (высота)
        mov     eax, WorkArea.rcBottom
        sub     eax, ebx
 
        pop     edx                     ; Восстановить регистр (ширина)

        mov     ebx, WorkArea.rcRight
        sub     ebx, edx

        ret
EvaluateCoords ENDP
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
PaintWindow PROC
;
;  На входе EAX должен содержать контекст, в котором следует производить
;    графический вывод, а EBX идентификатор окна, которое будет пере-
;    рисовываться.
;
        LOCAL   @@hDC: DWORD            ; Локальная переменная, содержащая
                                        ;   контекст устройства
        LOCAL   @@hWnd: DWORD           ; Индентификатор окна, в котором
                                        ;   требуется производить операцию
        LOCAL   @@hOldPen: DWORD        ; Идентификатор старого пера

        mov     [@@hDC], eax            ; Сохранить переданные идентификаторы
        mov     [@@hWnd], ebx

        ; Получить размер клиентской области окна
        push    offset TextRect
        push    [@@hWnd]
        call    GetClientRect

;----------------------------------------------------------------------------
; Создать необходимые инструменты для перерисовки окна
;----------------------------------------------------------------------------
        push    L BF_LEFT OR BF_RIGHT OR BF_TOP OR BF_ADJUST
                                        ; Прямоугольник без нижней границы +
                                        ;  нарисованный фрагмент будет исключен
                                        ;  из прямоугольника
        push    L EDGE_RAISED           ; Возвышенный край окна
        push    offset TextRect         ; Координаты прямоугольника, для
                                        ;   которого рисуются границы
        push    [@@hDC]                 ; Контекст устройства
        call    DrawEdge                ; Рисуем

        push    L BF_RECT OR BF_ADJUST  ; Целый прямоугольник
        push    L EDGE_SUNKEN           ; Утопленный край окна
        push    offset TextRect         ; Координаты прямоугольника
        push    [@@hDC]                 ; Контекст устройства
        call    DrawEdge                ; Рисуем

        mov     eax, [@@hDC]            ; Передаем параметр-контекст устройства
        call    PaintTime               ; Рисуем время

        ret
PaintWindow ENDP
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
PaintTime PROC
;
; На входе EAX содержит идентификатор контекста устройства
;
        LOCAL @@hDC: DWORD

        mov     [@@hDC], eax

        push    L 1               ; Делаем фон прозрачным, чтобы
        push    [@@hDC]           ;   функция DrawText не заполняла
        call    SetBkMode         ;   область еще раз

        ; Установить цвет шрифта в окне, который выбран пользователем
        push    L COLOR_WINDOWTEXT
        call    GetSysColor

        push    eax
        push    [@@hDC]
        call    SetTextColor

        ; Вывести текст
        push    [hFont]                 ; Выбрать созданный шрифт в контекст
        push    [@@hDC]
        call    SelectObject
        mov     [hOldFont], eax         ; Сохранить старый шрифт


        push    L DT_SINGLELINE OR DT_CENTER OR DT_VCENTER ; uFormat
        push    offset TextRect         ; lpRect
        push    L -1                    ; Длина текста (строка оканчивается нулем)
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
;  Форматирует время 
;
        ; Получить время
        push    offset Time
        call    GetLocalTime

        ; Сохранить часы, минуты и секунды в массиве
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
; ВНИМАНИЕ: Win32 требует, чтобы EBX, EDI и ESI были сохранены!  Мы удовлет-
; воряем этому условию с помощью перечисления этих регистров после директивы
; uses при описании процедуры. Это делается, чтобы Ассемблер автоматически
; сохранил эти регистры для нас
;
        cmp     [wmsg], WM_SYSCOLORCHANGE   ; Обрабатываемые сообщения
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

        jmp     defwndproc          ; Для необрабатываемых программой
                                    ;  сообщений    
wmsyscolorchange:
        ; Перерисовать содержимое окна
        push    L 1
        push    L 0
        push    [hWindow]
        call    InvalidateRect

        xor     eax, eax
        jmp     finish

wmpaint:        ; Перерисовка окна
        ; Начать операцию
        push    offset lppaint
        push    [hwnd]
        call    BeginPaint

        mov     ebx, [hwnd]

        call    PaintWindow

        ; Завершить операцию
        push    offset lppaint
        push    [hwnd]
        call    EndPaint

        mov     eax, 0                  ; Результат обработки сообщения
        jmp     finish

defwndproc:     ; Необрабатываемые сообщения
        push    [lparam]
        push    [wparam]
        push    [wmsg]
        push    [hwnd]
        call    DefWindowProc           ; Вызвать оконную процедру по умолчанию
        jmp     finish

wmtimer:
        ; Отформатировать время
        call    FormatTime

        or      eax, eax                ; Произошла ошибка
        jz      finish

        ; Получить размер клиентской области
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

        ; Создаем кисть
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

        ; Удаляем кисть
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

        ; Закрыть
        push    [hWindow]
        call    DestroyWindow
        
        xor     eax, eax
        jmp     finish

RestoreCommand:
        ; Показать окно на экране
        push    L SW_SHOW
        push    [hWindow]
        call    ShowWindow

        ; Запретить команду Восстановить
        push    L MF_GRAYED
        push    L 100
        push    [hMenu]
        call    EnableMenuItem

        ; Разрешить команду свернуть
        push    L MF_ENABLED
        push    L 101
        push    [hMenu]
        call    EnableMenuItem

;----------------------------------------------------------------------------
; Отобразить обычную иконку
;----------------------------------------------------------------------------

        ; Заполнить структуру
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

        ; Изменяем иконку в Панели задач
        push    offset TrayIconData
        push    L NIM_MODIFY
        call    Shell_NotifyIcon

        xor     eax, eax
        jmp     finish

MinimizeCommand:
        ; Убрать окно с экрана
        push    L SW_HIDE
        push    [hWindow]
        call    ShowWindow

        ; Разрешить команду Восстановить
        push    L MF_ENABLED
        push    L 100
        push    [hMenu]
        call    EnableMenuItem

        ; Запретить команду свернуть
        push    L MF_GRAYED
        push    L 101
        push    [hMenu]
        call    EnableMenuItem

;----------------------------------------------------------------------------
; Отобразить иконку для скрытого окна
;----------------------------------------------------------------------------

        ; Заполнить структуру
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

        ; Изменяем иконку в Панели задач
        push    offset TrayIconData
        push    L NIM_MODIFY
        call    Shell_NotifyIcon

        xor     eax, eax
        jmp     finish

SecondsCommand:
        ; Изменить состояние флага
        xor     SecondsFlag, 1
        jz      UncheckSeconds          ; Флаг стал нулем - удаляем секунды

;-----------------------------------------------------------------------------
; Добавляем вывод секунд
;-----------------------------------------------------------------------------
        mov     FormatSeconds, ':'      ; Добавить формат для секунд

        ; Установить флажок в меню
        push    L MF_CHECKED
        push    L 102
        push    [hMenu]
        call    CheckMenuItem

        jmp     SecondsCommandEnd

UncheckSeconds:
;-----------------------------------------------------------------------------
; Удаляем вывод секунд
;-----------------------------------------------------------------------------
        mov     FormatSeconds, 0        ; Удаляем формат для секунд

        ; Удаляем флажок в меню
        push    L MF_UNCHECKED
        push    L 102
        push    [hMenu]
        call    CheckMenuItem

SecondsCommandEnd:
        ; Переформатировать время
        call    FormatTime

        ; Перерисовать содержимое окна
        push    L 1
        push    L 0
        push    [hWindow]
        call    InvalidateRect

        xor     eax, eax
        jmp     finish

AboutCommand:
        ; О программе
        ; Загрузить иконку 16х16 для неотображаемого окна
        push    L 0                     ; fuLoad
        push    L 48                    ; cyDesired
        push    L 48                    ; cxDesired
        push    L 1 ; = IMAGE_ICON      ; uType
        push    L 1                     ; lpszName
        push    [hInst]
        call    LoadImage

        push    eax                     ; Передаем как параметр для DestroyIcon
        push    eax                     ; Передаем как параметр для ShellAbout

        push    offset CopyrightMsg     ; Основное сообщение
        push    offset szTitleName      ; Заголовок
        push    [hWindow]               ; Владеющее окно
        call    ShellAbout              ; Выводим диалог

        call    DestroyIcon             ; Удаляем соданную иконку

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
        ; Изменилось разрешение экрана -- перемещаем окно
        ;   на свое место
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

wmdestroy:      ; Разрушение окна и завершение работы

        ; Удалить созданный шрифт
        push    [hFont]
        call    DeleteObject

        ; Удалить меню
        push    [hMenu]
        call    DestroyMenu

        ; Удалить иконку из Панели задач
        mov     eax, [hWindow]
        mov     [TrayIconData.nidWindow], eax
        mov     [TrayIconData.nidID], TrayIconID
        mov     [TrayIconData.nidFlags], 0

        push    offset TrayIconData
        push    L NIM_DELETE
        call    Shell_NotifyIcon

        ; Удалить иконки
        push    [hIcon]
        call    DestroyIcon

        push    [hMinIcon]
        call    DestroyIcon

        ; Удалить таймер, если он был создан
        mov     eax, [hTimer]
        or      eax, eax
        jz      @@PostMessage           ; Таймер не был создан

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

