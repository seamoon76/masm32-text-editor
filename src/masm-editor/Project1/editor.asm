TITLE MASM EDITOR
.386
.model flat,stdcall
option casemap:none
WinMain proto :DWORD
;INCLUDE Irvine32.inc
;INCLUDE GraphWin.inc

sprintf    PROTO C : dword,:vararg

include \masm32\include\windows.inc
include \MASM32\INCLUDE\masm32.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comdlg32.inc
include \masm32\include\masm32rt.inc
include dialogs.inc
INCLUDE \masm32\include\DateTime.inc
include msvcrt.inc
includelib \MASM32\LIB\masm32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib comdlg32.lib
INCLUDELIB \masm32\lib\DateTime.lib
includelib msvcrt.lib

; DATA区
.data
warn_title BYTE "Warning",0
succeed_title byte "Succeed",0
warn_text  BYTE "Sorry, We have not implemented this function!",0
warn_newfile_text  BYTE "Sorry, We have not supported editing more than one file at the same time!",0
warn_cannot_load_dll BYTE "Sorry, cannot find riched20.dll",0
cannot_compare_text BYTE "The specified file could not be found.",0
succeed_compare_text BYTE "Comparison succeed, result is saved in diff.txt(in the same directory as this executable program). Open it now?",0
no_select_text BYTE "No selected text",0
no_clipboard_text BYTE "No copied text",0
cannot_undo_text BYTE "No action can undo",0
cannot_redo_text BYTE "No action can redo",0
not_save_text BYTE "You have not saved file. Save it now ?",0
quick_start_text BYTE "快捷键",0ah, 0dh,"Ctrl-O:打开文件，Ctrl-S:保存文件，Ctrl-N:打开新文件，Ctrl-C：复制，Ctrl-V：粘贴，Ctrl-X剪切，Ctrl-F查找",0ah, 0dh,"菜单栏",0ah, 0dh,"+ File项下拉后有以下6个选项：打开文件、新建文件、保存、另存为、退出",0ah, 0dh,0
quick_start_text1 BYTE "+ Edit项下拉后有以下12个选项：撤销、重做、剪切、复制、粘贴、删除、选择、查找、替换、Goto、新建窗口、文件对比。",0ah, 0dh,"点击Options后可以选择全部文本、跳转到页首或跳转到页尾",0ah, 0dh,0
quick_start_text2 BYTE"点击文件对比后会先提示保存当前文件，然后让您选择被比较的第2个文件，再然后弹出窗口让您选择是否展示文件差异。默认会存储在diff.txt中。",0ah, 0dh,0
quick_start_text3 BYTE"+ Paragraph项下拉后可以将选中的文段设置为一级标题、二级标题等等不同级别的标题，方便用户把握文本整体结构。",0ah, 0dh,0
quick_start_text4 BYTE "+ Font项下拉后可以通过对话框设置全局字体、字号、字形及文字颜色",0ah, 0dh,0
quick_start_text5 BYTE "+ Theme项下拉后可以选择文本编辑器的主题，目前设计了十种不同的主题配色",0ah, 0dh,0
quick_start_text6 BYTE "+ Settings项下拉后可以选择设置背景颜色或文本颜色。点击选项后会弹出设置对话框",0ah, 0dh,0

help_title BYTE "Help",0
error_title  BYTE "Error",0
app_name  db "MASM EDITOR",0
class_name   db "ASMWin",0
;edit_class BYTE "edit",0
riched_dll_name db "riched20.dll",0
riched_class_name db "RichEdit20A",0
dialog_dispaly db "show dialog",0
dialog_color_dispaly db "show color dialog",0
h_main_window  DWORD ?  ; 窗口对象句柄
hInstance DWORD ?  ; 应用程序句柄
;h_edit HWND ?      ; edit的句柄
hmenu DWORD 0
new_file_name BYTE "newfile.txt",0
menu_name	BYTE		"FirstMenu",0
lineno_format byte "%lu",0
buffer BYTE 4000 dup ( 0 )
filename_buffer byte 128 dup(0)
h_file HANDLE ?
h_log_file HANDLE ?
h_hot_file HANDLE 0
h_rich_edit dd ?   ;操作RichEdit的句柄
h_wnd_rich_edit dd ?  ;操作RichEdit窗口的句柄
;状态栏相关
hStatus       dd 0
Statusbuffer  byte 40 DUP(?)
linetxt      byte "  LineNum : %d   ColNum : %d",0

totalchar         byte "  LineCount : %d   CharCount : %d",0
charset           byte "   CharSet : %s",0
gb2312            byte "GB2312(Chinese)",0
ansi              byte "ANSI(English)",0
charsetdefault    byte "default",0
symbol            byte "symbols",0
mac               byte "MAC(Apple Macintosh)",0
shiftjis          byte "Japanese",0
hangul            byte "Hangul Korean",0
johab             byte "Johab Korean",0
chinesebig5        byte "traditional Chinese",0
greek             byte "Greek",0
turkish           byte "Turkish",0
vietnamese        byte "Vietnamese",0
hebrew            byte "Hebrew",0
arabic            byte "Arabic",0
baltic            byte "Baltic (Northeastern European)",0
russian           byte "Russian Cyrillic",0
thai              byte "Thai",0
easteurope        byte "Eastern European",0
oem               byte "OEM code",0
statusclass       byte "Status",0
nowtext FINDTEXTEX <>
totaltxt GETTEXTLENGTHEX <GTL_DEFAULT,1200>
getformat CHARFORMAT <>
cf  CHOOSEFONT <>
font_dialog_choose_ok byte 0
color_dialog_choose_ok byte 0
txt_color_dialog_choose_ok byte 0
rgbCurrnt dd 00000000h
;查找替换相关
FindBuffer db 256 dup(?)
ReplaceBuffer db 256 dup(?)
uFlags dd ?
findtext FINDTEXTEX <>
hSearch dd ?		; handle to the search/replace dialog box
log_file_save_path byte "log.txt",0
log_msg byte "test log",0
nowFileName    db 260 dup(0)
log_open_str byte "open file",0
open_mode byte "a",0
out_fmt byte "time:%s",0ah,0
default_diff_txt_name byte "diff.txt",0
;颜色
bg_color dd 0FFFFFFh		;背景颜色
txt_color dd 0		; 文本颜色
cmp_file_path db 260 dup(0)

cmd_diff_fmt db "fc /w /n %s %s > diff.txt",0
cmd_diff  db 'fc /w /n test1.txt test2.txt > diff.txt',0
print_fmt db "%s",10,0

;字体名称
FontNameC        db  'Consolas',0

;ToolBar
hToolTips     dd ?
szDisplayName db "MASM32 Richedit",0
hTbBmp        dd 0
hToolBar      dd 0
tbn_new       db "New File",0
tbn_open      db "Open File",0
tbn_save      db "Save File",0
tbn_save_as   db "Save File As",0
tbn_cut       db "Edit Cut",0
tbn_copy      db "Edit Copy",0
tbn_paste     db "Edit Paste",0
tbn_undo      db "Edit Undo",0
tbn_redo      db "Edit Redo",0
tbn_find      db "Find Text",0
tbn_replace   db "Replace Text",0
tbn_instance  db "New Instance",0
tbn_font      db "Set Font",0
tbn_quit      db "Close Editor",0
tbn_else      db 0
;定义宏
TBextraData MACRO
    mov tbb.fsState,   TBSTATE_ENABLED
    mov tbb.dwData,    0
    mov tbb.iString,   0
ENDM

TBbutton MACRO bID, cID
    mov tbb.iBitmap,   bID  ;; button  ID number
    mov tbb.idCommand, cID  ;; command ID number
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb
ENDM

TBblank MACRO
    mov tbb.iBitmap,   0
    mov tbb.idCommand, 0
    mov tbb.fsStyle,   TBSTYLE_SEP
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb
ENDM

Create_Tool_Bar MACRO Wd, Ht
    szText tbClass,"ToolbarWindow32"
    invoke CreateWindowEx,0,
                          ADDR tbClass,
                          ADDR szDisplayName,
                          WS_CHILD or WS_VISIBLE or TBSTYLE_TOOLTIPS or TBSTYLE_FLAT,
                          0,0,500,40,
                          hWin,NULL,
                          hInstance,NULL
    mov hToolBar, eax

    invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0

    invoke SendMessage,hToolBar,TB_GETTOOLTIPS,0,0
    mov hToolTips, eax
    invoke SendMessage,hToolTips,TTM_SETDELAYTIME,TTDT_INITIAL,0
    invoke SendMessage,hToolTips,TTM_SETDELAYTIME,TTDT_RESHOW,0
    ; Put width & height of bitmap into DWORD
    mov  ecx,Wd  ;; loword = bitmap Width
    mov  eax,Ht  ;; hiword = bitmap Height
    shl  eax,16
    mov  ax, cx

    mov bSize, eax
    
    invoke SendMessage,hToolBar,TB_SETBITMAPSIZE,0,bSize
    
    invoke SetBmpColor,hTbBmp
    mov hTbBmp,eax
    
    mov tbab.hInst, 0
    m2m tbab.nID, hTbBmp
    invoke SendMessage,hToolBar,TB_ADDBITMAP,12,ADDR tbab
    invoke SendMessage,hToolBar,TB_SETBUTTONSIZE,0,bSize
ENDM

; 定义主窗口
;MainWin WNDCLASSEX <CS_HREDRAW or CS_VREDRAW,WinProc,NULL,NULL,NULL,NULL,NULL, \
;	COLOR_WINDOW,menu_name,class_name>
open_filename_struct OPENFILENAME <>
open_filename_struct_cmp OPENFILENAME <>

m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

; 全局参数设置
; 设置参数表示打开文件是否丢弃原有内容
;Menu file IO
MENU_ID_OPEN equ 1
MENU_ID_NEW  equ 40001
MENU_ID_SAVE equ 40007
MENU_ID_SAVE_AS equ 2
MENU_ID_EXIT equ 3
;Menu edit
IDM_COPY                      equ  40013
IDM_CUT                       equ  40012
IDM_PASTE                      equ 40014
IDM_DELETE                     equ 40015
IDM_SELECTALL                  equ 40017
IDM_OPTION 			equ 40016
IDM_UNDO			equ 40010
IDM_REDO			equ 40011
IDM_SETBKCOLOR      equ 40039
IDM_SETTEXTCOLOR    equ 40040
IDM_NEWWINDOW       equ 40041
IDM_COMPAREFILE       equ 40044
IDI_ICON1           equ 101
IDM_FONT  equ 40042
ICON_ID equ 5002
IDM_L1HEADER equ 40020
IDM_L2HEADER equ 40021
IDM_L3HEADER equ 40022
IDM_L4HEADER equ 40023
IDM_L5HEADER equ 40024
IDM_L6HEADER equ 40025
IDM_THEME_LIGHT equ 40008
IDM_THEME_NIGHT equ 40009
IDM_THEME_FOREST      equ    40045
IDM_THEME_LAKE        equ    40046
IDM_THEME_STARRYNIGHT equ    40047
IDM_THEME_CANDY       equ    40048
IDM_THEME_ELEGANT     equ    40049
IDM_THEME_POEM        equ    40050
IDM_THEME_TARO        equ    40051
IDM_THEME_OCEAN        equ    40052
MAXFILESIZE equ 255
MEM_SIZE equ 65535

RichEditID 			equ 300
MARGIN_LEFT equ 25

;search\repalce\goto function
MENU_ID_SEARCH equ 40002
MENU_ID_REPLACE equ 40029
MENU_ID_GOTO equ 40057
IDD_FINDDLG                    equ 102
IDD_GOTODLG                    equ 103
IDD_REPLACEDLG                 equ 104
IDC_FINDEDIT                  equ  1000
IDC_MATCHCASE                  equ 1001
IDC_REPLACEEDIT                 equ 1001
IDC_WHOLEWORD                  equ 1002
IDC_DOWN                       equ 1003
IDC_UP                       equ   1004
IDC_LINENO                   equ   1005
IDC_LAST                     equ   1006

;gototop/bottom
IDM_SKIPTOTHEEND    equ     40018
IDM_SKIPTOTHETOP    equ     40019

ID_HELP_QUICKSTART  equ     40004

hMemory HANDLE ?                            ;分配内存的句柄
pMemory DWORD ?                            ;分配内存的指针
SizeReadWrite DWORD ?                   ; 实际读写量
preWndProc   WNDPROC ?                  ;窗口原有地址
lpEditProc   WNDPROC ?

MainWin WNDCLASSEX <SIZEOF WNDCLASSEX,CS_HREDRAW or CS_VREDRAW,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW+1,menu_name,class_name>

; 定义函数
FileWrite PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
FileRead PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
FileCreate  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
set_bkcolor_dialog PROTO
set_textcolor_dialog PROTO
Confirmation   PROTO :DWORD
SaveHint proto :DWORD
SearchProc PROTO :DWORD, :DWORD, :DWORD, :DWORD 
ReplaceProc PROTO hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD 
GoToProc PROTO hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD 
set_font_dialog PROTO
GoToTop proto hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
GoToBottom proto hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

WriteToLogFile proto :dword
OpenDiffHint proto
set_theme PROTo :dword,:dword

Do_ToolBar  PROTO :DWORD
SetBmpColor PROTO :DWORD

Do_Status proto :DWORD

.code
start:
    invoke lstrcat,addr quick_start_text,addr quick_start_text1
    invoke lstrcat,addr quick_start_text,addr quick_start_text2
    invoke lstrcat,addr quick_start_text,addr quick_start_text3
    invoke lstrcat,addr quick_start_text,addr quick_start_text4
    invoke lstrcat,addr quick_start_text,addr quick_start_text5
    invoke lstrcat,addr quick_start_text,addr quick_start_text6
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke LoadLibrary,addr riched_dll_name
    .if eax!=0 
		mov h_rich_edit,eax
		invoke WinMain, hInstance
		invoke FreeLibrary,h_rich_edit
	.else;加载DLL失败
		call ErrorHandler
	.endif
    invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE
; 获取当前进程的handle
    LOCAL msg:MSG
    LOCAL lineno:DWORD
    push  hInst
    pop   MainWin.hInstance

	

    ; 加载程序图标和光标
	;IDB_PNG1  =    101
	INVOKE LoadIcon, hInst, ICON_ID;IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax
    	
	; 注册窗口类
    invoke RegisterClassEx, addr MainWin
    .IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

    ; 创建应用主窗口.
	; 返回main window的句柄到EAX.
    invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR class_name,ADDR app_name,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,1200,800,NULL,NULL,\
           hInst,NULL
    mov   h_main_window,eax

    ; 如果创建窗口失败，显示错误并退出程序
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

    ; 显示窗口
    invoke ShowWindow, h_main_window,SW_SHOWNORMAL
    invoke UpdateWindow, h_main_window

    ; 显示欢迎信息
	;INVOKE MessageBox, h_main_window, ADDR greet_text, ADDR greet_title, MB_OK

    ; 循环处理消息
Message_Loop:
	; 从消息队列中获取下一条数据
    INVOKE GetMessage, ADDR msg, NULL,NULL,NULL
    ; 没有消息就退出
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    invoke IsDialogMessage,hSearch,ADDR msg 
    .IF eax==FALSE 

    invoke SendMessage,h_rich_edit,EM_LINEFROMCHAR,-1,0
    inc eax
    mov lineno,eax
    ;获取列号
    invoke SendMessage,h_rich_edit,EM_LINEINDEX,-1,0
    mov ebx,eax
    invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr nowtext.chrg
    mov eax,nowtext.chrg.cpMin
    sub eax,ebx
    invoke sprintf, offset Statusbuffer, offset linetxt,lineno,eax
    invoke SendMessage,hStatus,SB_SETTEXT,0,offset Statusbuffer
    ;获取总行数
    invoke SendMessage,h_rich_edit,EM_GETLINECOUNT,0,0
    mov ebx,eax

    ;获取总字符数
    invoke SendMessage,h_rich_edit,EM_GETTEXTLENGTHEX,addr totaltxt,0
    invoke sprintf, offset Statusbuffer, offset totalchar, ebx, eax
    invoke SendMessage,hStatus,SB_SETTEXT,1,offset Statusbuffer

    ;获取编码格式
    mov getformat.cbSize,sizeof getformat
    invoke SendMessage,h_rich_edit,EM_GETCHARFORMAT,SCF_DEFAULT,addr getformat  
    mov ebx,0
    mov bl,getformat.bCharSet
    .if ebx==86h
      invoke sprintf, offset Statusbuffer, offset charset,offset gb2312
    .elseif ebx==0
      invoke sprintf, offset Statusbuffer, offset charset,offset ansi
    .elseif ebx==1
      invoke sprintf, offset Statusbuffer, offset charset,offset charsetdefault
    .elseif ebx==2h
      invoke sprintf, offset Statusbuffer, offset charset,offset symbol
    .elseif ebx==4dh
      invoke sprintf, offset Statusbuffer, offset charset,offset mac
    .elseif ebx==80h
      invoke sprintf, offset Statusbuffer, offset charset,offset shiftjis
    .elseif ebx==81h
      invoke sprintf, offset Statusbuffer, offset charset,offset hangul
    .elseif ebx==88h
      invoke sprintf, offset Statusbuffer, offset charset,offset chinesebig5
    .elseif ebx==161
      invoke sprintf, offset Statusbuffer, offset charset,offset greek
    .elseif ebx==162
      invoke sprintf, offset Statusbuffer, offset charset,offset turkish
    .elseif ebx==163
      invoke sprintf, offset Statusbuffer, offset charset,offset vietnamese
    .elseif ebx==177h
      invoke sprintf, offset Statusbuffer, offset charset,offset hebrew
    .elseif ebx==178h
      invoke sprintf, offset Statusbuffer, offset charset,offset arabic
    .elseif ebx==186h
      invoke sprintf, offset Statusbuffer, offset charset,offset baltic
    .elseif ebx==0CCh
      invoke sprintf, offset Statusbuffer, offset charset,offset russian
    .elseif ebx==0DEh
      invoke sprintf, offset Statusbuffer, offset charset,offset thai
    .elseif ebx==0EEh
      invoke sprintf, offset Statusbuffer, offset charset,offset easteurope
    .elseif ebx==0FFh
      invoke sprintf, offset Statusbuffer, offset charset,offset oem
    .endif
    invoke SendMessage,hStatus,SB_SETTEXT,2,offset Statusbuffer


    ;判断消息是否为按下Shift
    cmp [msg.message],WM_KEYDOWN
    jne Message_Send
    invoke GetKeyState,VK_CONTROL
    and ah, 1000b
    test ah, ah
    jz Message_Send
    mov edx,msg.wParam
    .IF edx==4fh; 判断是否按下O
      call open_file
    .ELSEIF  edx==53h ; 判断是否按下S
      call save_file_local
    .ELSEIF  edx==4eh ; 判断是否按下N
      call new_file
    .ELSEIF edx==46h ; 判断是否按下F
      invoke CreateDialogParam,hInstance,IDD_FINDDLG,h_main_window,addr SearchProc,0
    .ELSE
      jmp Message_Send
    .ENDIF
    
    .ENDIF
    jmp Message_Loop

Message_Send:
    invoke TranslateMessage, ADDR msg
    ; 将消息中继到程序的 WinProc。
    invoke DispatchMessage, ADDR msg
    jmp Message_Loop
Exit_Program:
	 INVOKE ExitProcess,0
WinMain endp

paint_lineno_Proc proc uses esi edi ebx hWnd:HWND,localMsg:UINT,wParam:WPARAM,lParam:LPARAM
LOCAL point_:POINT
LOCAL size_[16]:CHAR
LOCAL line_count:DWORD
LOCAL rectangle:RECT,h_region:HRGN


    invoke CallWindowProc,lpEditProc,hWnd,localMsg,wParam,lParam
    .if localMsg == WM_PAINT
        push eax
        invoke SendMessage,hWnd,EM_GETLINECOUNT,0,0
        mov line_count,eax
        .if line_count
            invoke GetDC,hWnd
            mov ebx,eax
            invoke SaveDC,ebx
            invoke GetClientRect,hWnd,addr rectangle
            invoke CreateRectRgn,rectangle.left,rectangle.top,rectangle.right,rectangle.bottom
            mov h_region,eax
            invoke SelectClipRgn,ebx,h_region
           
            invoke BitBlt,ebx,0,0,MARGIN_LEFT,rectangle.bottom,ebx,0,0,PATCOPY
           
            invoke SendMessage,hWnd,EM_GETFIRSTVISIBLELINE,0,0
            mov esi,eax
            .while line_count > esi
                invoke SendMessage,hWnd,EM_LINEINDEX,esi,0
                .break .if eax == -1
                invoke SendMessage,hWnd,EM_POSFROMCHAR,addr point_,eax
                mov eax,point_.y
                .break .if SDWORD ptr eax > rectangle.bottom
                invoke wsprintf,addr size_,addr lineno_format,addr [esi+1]
                invoke lstrlen,addr size_
                invoke TextOut,ebx,0,point_.y,addr size_,eax
                inc esi
            .endw
            invoke RestoreDC,ebx,-1
            invoke DeleteObject,h_region
            invoke ReleaseDC,hWnd,ebx
        .endif
        pop eax
    .endif
    ret
paint_lineno_Proc endp


; 窗口过程
WinProc proc uses edx hWnd:HWND, localMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL chrg:CHARRANGE
	LOCAL editstream:EDITSTREAM
    LOCAL hTbar:DWORD
    LOCAL hSbar:DWORD
    LOCAL lpTxt:DWORD
    LOCAL Rct:RECT
    LOCAL Ps:PAINTSTRUCT
    LOCAL tbab:TBADDBITMAP
    LOCAL tbb:TBBUTTON

    .IF localMsg==WM_CREATE; 创建窗口
        invoke CreateWindowEx, NULL,addr riched_class_name,0,WS_VISIBLE or WS_CHILD or ES_MULTILINE or WS_VSCROLL or WS_HSCROLL or ES_NOHIDESEL,\
				0,0,0,0,hWnd,RichEditID,hInstance,0

        mov h_rich_edit,eax
        ;设置文本大小限制
        invoke SendMessage,h_rich_edit,EM_LIMITTEXT,-1,0
        invoke SendMessage,h_rich_edit,EM_SETMODIFY,FALSE,0
		invoke SendMessage,h_rich_edit,EM_EMPTYUNDOBUFFER,0,0
        invoke SetFocus,h_rich_edit
        mov open_filename_struct.lStructSize,SIZEOF OPENFILENAME
        push hWnd
        pop  open_filename_struct.hWndOwner
        push hInstance
        pop  open_filename_struct.hInstance
        mov  open_filename_struct.lpstrFile, OFFSET buffer
        mov  open_filename_struct.nMaxFile,MAXFILESIZE

        ;设置margin
        invoke SendMessage,h_rich_edit,EM_SETMARGINS,EC_LEFTMARGIN,MARGIN_LEFT
        ;获取原有窗口地址
        invoke GetWindowLong,h_main_window,GWL_WNDPROC
        mov preWndProc,eax
        ;设置新的窗口地址
        invoke SetWindowLong, h_rich_edit, GWL_WNDPROC, paint_lineno_Proc
        mov lpEditProc,eax
        ;设置toolbar
        invoke Do_ToolBar,hWnd
        invoke Do_Status,hWnd

        jmp WinProcExit
    .ELSEIF localMsg==WM_SIZE; 改大小
          
        invoke SendMessage,hToolBar,TB_AUTOSIZE,0,0
        invoke MoveWindow,hStatus,0,0,0,0,TRUE

        invoke GetClientRect,hToolBar,ADDR Rct
        mov eax, Rct.bottom
        mov hTbar, eax

        invoke GetClientRect,hStatus,ADDR Rct
        mov eax, Rct.bottom
        mov hSbar, eax

        invoke GetClientRect, hWnd, ADDR Rct

        mov eax, Rct.bottom
        sub eax, hTbar
        sub eax, hSbar

        add hTbar, 2
        sub eax, 2
        

        invoke MoveWindow,h_rich_edit,0,hTbar,Rct.right,eax,TRUE        

        jmp WinProcExit
    .ELSEIF localMsg==WM_CLOSE; 销毁窗口
        
        invoke SaveHint,h_rich_edit
        .if eax == IDYES
                  CALL save_file_local
              .elseif eax == IDCANCEL
                  ret
              .else
                jmp my_destory
              .endif
    .ELSEIF localMsg==WM_DESTROY; 销毁窗口
        my_destory:
        invoke PostQuitMessage,NULL
        jmp WinProcExit
    .ELSEIF localMsg==WM_COMMAND; 处理命令
        mov eax,wParam
        .if lParam==0
            .if ax==MENU_ID_OPEN
            open_file_order:
                CALL open_file      ; 打开文件
                
            .elseif ax==MENU_ID_SAVE
                CALL save_file_local      ; 保存文件（另存为）
            .elseif ax==MENU_ID_SAVE_AS
                CALL save_file      ; 保存文件（另存为）
            .elseif ax==MENU_ID_NEW
                CALL new_file       ; 新建文件
            .elseif ax==MENU_ID_EXIT
                push eax
                invoke SaveHint,h_rich_edit
                 .if eax == IDYES
                  CALL save_file_local
                .elseif eax == IDCANCEL
                  ret
                .endif
                invoke DestroyWindow, hWnd; 退出
                pop eax     
            .elseif ax==MENU_ID_SEARCH       ;查找  
				.if hSearch==0
					invoke CreateDialogParam,hInstance,IDD_FINDDLG,hWnd,addr SearchProc,0               
	            .endif
            .elseif ax==MENU_ID_REPLACE       ;替换  
				.if hSearch==0                  
                    invoke CreateDialogParam,hInstance,IDD_REPLACEDLG,hWnd,addr ReplaceProc,0                   
	            .endif
            .elseif ax==MENU_ID_GOTO       ;移动到某行  
				.if hSearch==0
                    invoke CreateDialogParam,hInstance,IDD_GOTODLG,hWnd,addr GoToProc,0                          
	            .endif
            .elseif ax==IDM_SKIPTOTHETOP       ;移动到顶部  		
                    call GoToTop      
            .elseif ax==IDM_SKIPTOTHEEND       ;移动到底部  		
                    call GoToBottom
            .elseif ax==IDM_COPY  ;复制选中的内容
                push eax
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr chrg
			    mov ebx,chrg.cpMin
			    .if ebx==chrg.cpMax		; 没有选中内容
                INVOKE MessageBox, h_main_window, ADDR no_select_text, ADDR warn_title, MB_OK
                .else
				    invoke SendMessage,h_rich_edit,WM_COPY,0,0
                .endif
                pop eax
            .elseif ax==IDM_CUT
                push eax 
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr chrg
			    mov ebx,chrg.cpMin
			    .if ebx==chrg.cpMax		; 没有选中内容
                INVOKE MessageBox, h_main_window, ADDR no_select_text, ADDR warn_title, MB_OK
                .else
				invoke SendMessage,h_rich_edit,WM_CUT,0,0
                .endif
                pop eax
			.elseif ax==IDM_DELETE
                push eax 
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr chrg
			    mov ebx,chrg.cpMin
			    .if ebx==chrg.cpMax		; 没有选中内容
                INVOKE MessageBox, h_main_window, ADDR no_select_text, ADDR warn_title, MB_OK
                .else
				invoke SendMessage,h_rich_edit,EM_REPLACESEL,TRUE,0
                .endif
                pop eax
            .elseif ax==IDM_PASTE
                push eax
                invoke SendMessage,h_rich_edit,EM_CANPASTE,CF_TEXT,0
			    .if eax==0;剪贴板没有内容
                    INVOKE MessageBox, h_main_window, ADDR no_clipboard_text, ADDR warn_title, MB_OK
                .else
				    invoke SendMessage,h_rich_edit,WM_PASTE,0,0
                .endif
                pop eax
            .elseif ax==IDM_SELECTALL
                push eax
				mov chrg.cpMin,0
				mov chrg.cpMax,-1
				invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr chrg
                pop eax
			.elseif ax==IDM_UNDO
                push eax
                ;判断undo queue是否为空
                invoke SendMessage,h_rich_edit,EM_CANUNDO,0,0
			    .if eax==0
				    INVOKE MessageBox, h_main_window, ADDR cannot_undo_text, ADDR warn_title, MB_OK
			    .else
				    invoke SendMessage,h_rich_edit,EM_UNDO,0,0
			    .endif
                pop eax
			.elseif ax==IDM_REDO
                push eax
                invoke SendMessage,h_rich_edit,EM_CANREDO,0,0
			    .if eax==0
				    INVOKE MessageBox, h_main_window, ADDR cannot_redo_text, ADDR warn_title, MB_OK
			    .else
				    invoke SendMessage,h_rich_edit,EM_REDO,0,0
                .endif
                pop eax
            .elseif ax==IDM_SETBKCOLOR
                push eax               
                invoke set_bkcolor_dialog
                pop eax
            .elseif ax==IDM_SETTEXTCOLOR
                push eax
                invoke set_textcolor_dialog
                pop eax
            .elseif ax==IDM_NEWWINDOW
                push eax
                new_window:
                invoke GetModuleFileName,NULL,ADDR filename_buffer,128
                invoke WinExec,ADDR filename_buffer,SW_SHOW
                pop eax
            .elseif ax==IDM_FONT
                push eax

                invoke set_font_dialog

                pop eax
            .elseif ax== IDM_L1HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,12,0
            .elseif ax== IDM_L2HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,10,0
            .elseif ax== IDM_L3HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,8,0
            .elseif ax== IDM_L4HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,6,0
            .elseif ax== IDM_L5HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,4,0
            .elseif ax== IDM_L6HEADER
                invoke SendMessage,h_rich_edit,EM_SETFONTSIZE,2,0
            .elseif ax==IDM_THEME_LIGHT
                mov ebx,00ffffffh
                mov edx,00000000h
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_NIGHT
                mov ebx,00000000h
                mov edx,00adf8c9h
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_OCEAN
                mov ebx,00693E2Ch
                mov edx,00f0ebceh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_FOREST
                mov ebx,00224000h
                mov edx,00a6fddch
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_LAKE
                mov ebx,00939b24h
                mov edx,00e0fecdh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_STARRYNIGHT
                mov ebx,006b210eh
                mov edx,0080ffffh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_CANDY
                mov ebx,00e0f3feh
                mov edx,009265efh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_ELEGANT
                mov ebx,00400000h
                mov edx,00e7ceffh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_POEM
                mov ebx,00d0e4fch
                mov edx,00000080h 
                invoke set_theme,ebx,edx
            .elseif ax==IDM_THEME_TARO
                mov ebx,0098879eh
                mov edx,00d9deeeh
                invoke set_theme,ebx,edx
            .elseif ax==IDM_COMPAREFILE
                ;获取要比较的文件
                push eax
                invoke SaveHint,h_rich_edit
                .if eax == IDYES
                  CALL save_file_local
              .elseif eax == IDCANCEL
                  ret
              .endif
                mov  open_filename_struct.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
                invoke GetOpenFileName, ADDR open_filename_struct
                .if eax==TRUE
                     invoke lstrcpy, OFFSET cmp_file_path,open_filename_struct.lpstrFile
                    ;m2m cmp_file_path,lcase$(open_filename_struct.lpstrFile)
                    invoke crt_printf,addr print_fmt,offset nowFileName
                    invoke crt_printf,addr print_fmt,offset cmp_file_path
                    invoke crt_sprintf,addr cmd_diff,addr cmd_diff_fmt,offset nowFileName,offset cmp_file_path
                    invoke crt_system,addr cmd_diff
                    .if eax==0
				    INVOKE MessageBox, h_main_window, ADDR cannot_compare_text, ADDR warn_title, MB_OK
			        .else
                        ;invoke SendMessage,h_rich_edit,EM_SETMODIFY,TRUE,0
                        invoke OpenDiffHint
				        
                    .endif
                .endif
                pop eax
            .elseif ax==ID_HELP_QUICKSTART
                push eax
                
                INVOKE MessageBox, h_main_window, ADDR quick_start_text, ADDR help_title, MB_OK
                pop eax
            .else
                INVOKE MessageBox, h_main_window, ADDR warn_text, ADDR warn_title, MB_OK
                ;invoke DestroyWindow, hWnd
            .endif
        .else ;ToolBar
            .if ax==50 ;NEW
                CALL new_file
            .elseif ax==51 ;OPEN
                CALL open_file
            .elseif ax==52 ;SAVE
                CALL save_file_local
            .elseif ax==53 ;SAVE AS
                CALL save_file
            .elseif ax==54 ;CUT
                push eax 
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr chrg
			    mov ebx,chrg.cpMin
			    .if ebx==chrg.cpMax		; 没有选中内容
                INVOKE MessageBox, h_main_window, ADDR no_select_text, ADDR warn_title, MB_OK
                .else
				invoke SendMessage,h_rich_edit,WM_CUT,0,0
                .endif
                pop eax
            .elseif ax==55 ;COPY
                push eax
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr chrg
			    mov ebx,chrg.cpMin
			    .if ebx==chrg.cpMax		; 没有选中内容
                INVOKE MessageBox, h_main_window, ADDR no_select_text, ADDR warn_title, MB_OK
                .else
				    invoke SendMessage,h_rich_edit,WM_COPY,0,0
                .endif
                pop eax
            .elseif ax==56 ;PASTE
                push eax
                invoke SendMessage,h_rich_edit,EM_CANPASTE,CF_TEXT,0
			    .if eax==0;剪贴板没有内容
                    INVOKE MessageBox, h_main_window, ADDR no_clipboard_text, ADDR warn_title, MB_OK
                .else
				    invoke SendMessage,h_rich_edit,WM_PASTE,0,0
                .endif
                pop eax
            .elseif ax==57 ;UNDO
                push eax
                ;判断undo queue是否为空
                invoke SendMessage,h_rich_edit,EM_CANUNDO,0,0
			    .if eax==0
				    INVOKE MessageBox, h_main_window, ADDR cannot_undo_text, ADDR warn_title, MB_OK
			    .else
				    invoke SendMessage,h_rich_edit,EM_UNDO,0,0
			    .endif
                pop eax
            .elseif ax==58;REDO
                push eax
                invoke SendMessage,h_rich_edit,EM_CANREDO,0,0
			    .if eax==0
				    INVOKE MessageBox, h_main_window, ADDR cannot_redo_text, ADDR warn_title, MB_OK
			    .else
				    invoke SendMessage,h_rich_edit,EM_REDO,0,0
                .endif
                pop eax
            .elseif ax==59;SEARCH
                .if hSearch==0
					invoke CreateDialogParam,hInstance,IDD_FINDDLG,hWnd,addr SearchProc,0               
	            .endif
            .elseif ax==60;REPLACE
                .if hSearch==0                  
                    invoke CreateDialogParam,hInstance,IDD_REPLACEDLG,hWnd,addr ReplaceProc,0                   
	            .endif
            .elseif ax==61;FONT
                push eax
                invoke set_font_dialog
                pop eax
            .elseif ax==62;NEW WINDOW
                push eax
                invoke GetModuleFileName,NULL,ADDR filename_buffer,128
                invoke WinExec,ADDR filename_buffer,SW_SHOW
                pop eax
            .elseif ax==63;CLOSE
                push eax
                invoke SaveHint,h_rich_edit
                 .if eax == IDYES
                  CALL save_file_local
                .elseif eax == IDCANCEL
                  ret
                .endif
                invoke DestroyWindow, hWnd
                pop eax
            .endif
        .endif
        jmp WinProcExit
     .elseif localMsg == WM_SYSCOLORCHANGE
        invoke Do_ToolBar,hWnd
     .elseif localMsg == WM_NOTIFY
      ; ---------------------------------------------------
      ; The toolbar has the TBSTYLE_TOOLTIPS style enabled
      ; so that a WM_NOTIFY message is sent when the mouse
      ; is over the toolbar buttons.
      ; ---------------------------------------------------
        mov eax, lParam
        mov eax, [eax]      ; get 1st member of NMHDR structure "hwndFrom"

        .if eax == hToolTips
            .if wParam == 50
                mov lpTxt, offset tbn_new
            .elseif wParam == 51
                mov lpTxt, offset tbn_open
            .elseif wParam == 52
                mov lpTxt, offset tbn_save
            .elseif wParam == 53
                mov lpTxt, offset tbn_save_as
            .elseif wParam == 54
                mov lpTxt, offset tbn_cut
            .elseif wParam == 55
                mov lpTxt, offset tbn_copy
            .elseif wParam == 56
                mov lpTxt, offset tbn_paste
            .elseif wParam == 57
                mov lpTxt, offset tbn_undo
            .elseif wParam == 58
                mov lpTxt, offset tbn_redo
            .elseif wParam == 59
                mov lpTxt, offset tbn_find
            .elseif wParam == 60
                mov lpTxt, offset tbn_replace
            .elseif wParam == 61
                mov lpTxt, offset tbn_font
            .elseif wParam == 62
                mov lpTxt, offset tbn_instance
            .elseif wParam == 63
                mov lpTxt, offset tbn_quit
            .endif
        .else
            mov lpTxt, offset tbn_else
        .endif
        invoke SendMessage,hStatus,SB_SETTEXT,3,lpTxt

     .ELSEIF localMsg == WM_CLOSE		; 关闭窗口
        invoke SaveHint,h_rich_edit
         .if eax == IDYES
                  CALL save_file_local
              .elseif eax == IDCANCEL
                  ret
              .endif
	     INVOKE PostQuitMessage,0
	     jmp WinProcExit
	 .ELSE		                        ; 默认处理函数
	     INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	     ret
     .ENDIF


WinProcExit:
	xor    eax,eax ;清零eax
	ret

WinProc endp
;---------------------------------------------------
ErrorHandler PROC
; 来自助教给的示例程序
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR error_title,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

;---------------------------------------------------
open_file PROC
;打开文件
;使用eax
;参考 http://www.interq.or.jp/chubu/r6/masm32/tute/tute012.html
;---------------------------------------------------
     invoke SaveHint,h_rich_edit
     .if eax == IDYES
                  CALL save_file_local
              .elseif eax == IDCANCEL
                  ret
              .endif
     mov  open_filename_struct.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
     invoke GetOpenFileName, ADDR open_filename_struct
     .if eax==TRUE

     invoke CreateFile,ADDR buffer,GENERIC_READ or GENERIC_WRITE ,\
                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
                                NULL
     mov h_file,eax
     mov h_hot_file,eax
     invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEM_SIZE
     mov  hMemory,eax
     invoke GlobalLock,hMemory
     mov  pMemory,eax
     invoke ReadFile,h_file,pMemory,MEM_SIZE-1,ADDR SizeReadWrite,NULL
     invoke SendMessage,h_rich_edit,WM_SETTEXT,NULL,pMemory
     invoke CloseHandle,h_file
     invoke GlobalUnlock,pMemory
     invoke GlobalFree,hMemory
     invoke lstrcpy, OFFSET nowFileName,open_filename_struct.lpstrFile
     .endif
     invoke SetFocus,h_rich_edit
     
     ret ; 一定要注意别丢了ret
     
open_file ENDP


;---------------------------------------------------
save_file PROC
;另存为文件
;使用eax
;参考 http://www.interq.or.jp/chubu/r6/masm32/tute/tute012.html
;---------------------------------------------------


    mov open_filename_struct.Flags,OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
    invoke GetSaveFileName, ADDR open_filename_struct
    .if eax==TRUE
        invoke CreateFile,ADDR buffer,\
            GENERIC_READ or GENERIC_WRITE ,\
            FILE_SHARE_READ or FILE_SHARE_WRITE,\
            NULL,CREATE_NEW,FILE_ATTRIBUTE_ARCHIVE,\
            NULL
        mov h_file,eax
        invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEM_SIZE
        mov  hMemory,eax
        invoke GlobalLock,hMemory
        mov  pMemory,eax
        invoke SendMessage,h_rich_edit,WM_GETTEXT,MEM_SIZE-1,pMemory
        invoke WriteFile,h_file,pMemory,eax,ADDR SizeReadWrite,NULL
        invoke CloseHandle,h_file
        invoke GlobalUnlock,pMemory
        invoke GlobalFree,hMemory
        invoke SendMessage,h_rich_edit,EM_SETMODIFY,FALSE,0
        invoke lstrcpy, OFFSET nowFileName,open_filename_struct.lpstrFile
     .endif
     invoke SetFocus,h_rich_edit
     ret
save_file ENDP

;---------------------------------------------------
save_file_local PROC
;保存文件
;使用eax
;参考 http://www.interq.or.jp/chubu/r6/masm32/tute/tute012.html
;---------------------------------------------------
    .if h_hot_file == 0 ;新建的文件
    mov open_filename_struct.Flags,OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
        invoke GetSaveFileName, ADDR open_filename_struct
    .if eax==TRUE
        invoke CreateFile,ADDR buffer,\
            GENERIC_READ or GENERIC_WRITE ,\
            FILE_SHARE_READ or FILE_SHARE_WRITE,\
            NULL,CREATE_NEW,FILE_ATTRIBUTE_ARCHIVE,\
            NULL
        mov h_file,eax
        invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEM_SIZE
        mov  hMemory,eax
        invoke GlobalLock,hMemory
        mov  pMemory,eax
        invoke SendMessage,h_rich_edit,WM_GETTEXT,MEM_SIZE-1,pMemory
        invoke WriteFile,h_file,pMemory,eax,ADDR SizeReadWrite,NULL
        invoke CloseHandle,h_file
        invoke GlobalUnlock,pMemory
        invoke GlobalFree,hMemory
        invoke SendMessage,h_rich_edit,EM_SETMODIFY,FALSE,0
        invoke lstrcpy, OFFSET nowFileName,open_filename_struct.lpstrFile
    .endif
    .else ;是打开的文件
        mov open_filename_struct.Flags,OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
        ;invoke GetSaveFileName, ADDR open_filename_struct
        ;mov h_hot_file,0
    ;.if eax==TRUE
        invoke CreateFile,ADDR buffer,\
            GENERIC_READ or GENERIC_WRITE ,\
            FILE_SHARE_READ or FILE_SHARE_WRITE,\
            NULL,OPEN_ALWAYS,FILE_ATTRIBUTE_ARCHIVE,\
            NULL
        mov h_file,eax
        invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEM_SIZE
        mov  hMemory,eax
        invoke GlobalLock,hMemory
        mov  pMemory,eax
        invoke SendMessage,h_rich_edit,WM_GETTEXT,MEM_SIZE-1,pMemory
        invoke WriteFile,h_file,pMemory,eax,ADDR SizeReadWrite,NULL
        invoke CloseHandle,h_file
        invoke GlobalUnlock,pMemory
        invoke GlobalFree,hMemory
        invoke SendMessage,h_rich_edit,EM_SETMODIFY,FALSE,0
        invoke lstrcpy, OFFSET nowFileName,open_filename_struct.lpstrFile
     ;.endif

    .endif
    
     invoke SetFocus,h_rich_edit
     ret
save_file_local ENDP

;---------------------------------------------------
new_file PROC uses eax
;打开文件
;使用eax
;---------------------------------------------------
    invoke SaveHint,h_rich_edit
    .if eax == IDYES
                  CALL save_file_local
              .elseif eax == IDCANCEL
                  ret
              .endif
              

              cover:
                invoke SendMessage,h_main_window,WM_SETTEXT,0,ADDR new_file_name
                invoke SendMessage,h_rich_edit,WM_SETTEXT,0,0
                invoke SendMessage,h_rich_edit,EM_SETMODIFY,0,0
                mov h_hot_file,0


     ;INVOKE MessageBox, h_main_window, ADDR warn_newfile_text, ADDR warn_title, MB_OK
     ret
new_file ENDP

MyBGColorDialog proc hWin:DWORD, instance:DWORD, Flags:DWORD

    LOCAL ccl:CHOOSECOLOR
    LOCAL crv[16]:DWORD

    lea edi, crv[0]
    mov ecx, 16
    mov eax, 0FFFFFFh
    rep stosd

    mov ccl.lStructSize,    sizeof CHOOSECOLOR
    push hWin
    pop ccl.hwndOwner 
    push instance
    pop ccl.hInstance
    mov ccl.rgbResult,      00ffffffh
    lea eax, crv                ; address of 16 item DWORD array
    mov ccl.lpCustColors,   eax
    push Flags
    pop ccl.Flags
    mov ccl.lCustData,      0
    mov ccl.lpfnHook,       0
    mov ccl.lpTemplateName, 0

    invoke ChooseColor,ADDR ccl

    .if eax != 0
      mov color_dialog_choose_ok,1
      mov eax, ccl.rgbResult
    .else
      mov color_dialog_choose_ok,0
    .endif

    ret

MyBGColorDialog endp

set_bkcolor_dialog PROC 
    LOCAL cfm:CHARFORMAT
    invoke MyBGColorDialog,h_main_window,hInstance,00000001h ; dialog for choosing global background color
    .if color_dialog_choose_ok==1
    mov bg_color, eax

    ;set background color
	invoke SendMessage,h_rich_edit,EM_SETBKGNDCOLOR,0,bg_color
	invoke RtlZeroMemory,addr cfm,sizeof cfm
	mov cfm.cbSize,sizeof cfm
	mov cfm.dwMask,CFM_COLOR
    .endif
	ret

set_bkcolor_dialog ENDP

MyTxtColorDialog proc hWin:DWORD, instance:DWORD, Flags:DWORD

    LOCAL ccl:CHOOSECOLOR
    LOCAL crv[16]:DWORD

    lea edi, crv[0]
    mov ecx, 16
    mov eax, 0FFFFFFh
    rep stosd

    mov ccl.lStructSize,    sizeof CHOOSECOLOR
    push hWin
    pop ccl.hwndOwner 
    push instance
    pop ccl.hInstance
    mov ccl.rgbResult,      00000000h
    lea eax, crv                ; address of 16 item DWORD array
    mov ccl.lpCustColors,   eax
    push Flags
    pop ccl.Flags
    mov ccl.lCustData,      0
    mov ccl.lpfnHook,       0
    mov ccl.lpTemplateName, 0

    invoke ChooseColor,ADDR ccl

    .if eax != 0
      mov txt_color_dialog_choose_ok,1
      mov eax, ccl.rgbResult
    .else
      mov txt_color_dialog_choose_ok,0
    .endif

    ret

MyTxtColorDialog endp

set_textcolor_dialog PROC 
    LOCAL cfm:CHARFORMAT
    invoke MyTxtColorDialog,h_main_window,hInstance,00000001h ; dialog for choosing global text color
    .if txt_color_dialog_choose_ok==1
    mov txt_color, eax
    mov rgbCurrnt,eax

    ;set text color
	invoke RtlZeroMemory,addr cfm,sizeof cfm
	mov cfm.cbSize,sizeof cfm
	mov cfm.dwMask,CFM_COLOR
    push txt_color
	pop cfm.crTextColor
	invoke SendMessage,h_rich_edit,EM_SETCHARFORMAT,SCF_SELECTION,addr cfm
    .endif
	ret

set_textcolor_dialog ENDP

set_theme PROC b_color:dword,t_color:dword
    LOCAL cfm:CHARFORMAT
	invoke RtlZeroMemory,addr cfm,sizeof cfm
	mov cfm.cbSize,sizeof cfm
	mov cfm.dwMask,CFM_COLOR
    push t_color
	pop cfm.crTextColor
    mov ebx,t_color
    mov rgbCurrnt,ebx

	invoke SendMessage,h_rich_edit,EM_SETCHARFORMAT,SCF_ALL,addr cfm
    invoke SendMessage, h_rich_edit, EM_SETBKGNDCOLOR, 0, b_color

	ret

set_theme ENDP

SaveHint proc h_editor:DWORD

    invoke SendMessage,h_editor,WM_GETTEXTLENGTH,0,0
      cmp eax, 0
      jne not_empty
      ret
    not_empty:
    invoke SendMessage,h_editor,EM_GETMODIFY,0,0
      cmp eax, 0  ; zero = unmodified
      jne modify
    
    ret
      modify:
      invoke MessageBox,h_main_window, ADDR not_save_text,
                           ADDR warn_title,
                           MB_YESNOCANCEL or MB_ICONQUESTION
      ret

SaveHint endp


OpenDiffHint proc

    invoke MessageBox,h_main_window, ADDR succeed_compare_text,
                           ADDR succeed_title,
                           MB_YESNO

    .if eax == IDYES
        invoke SendMessage,h_rich_edit,EM_SETMODIFY,FALSE,0
        invoke lstrcpy,addr buffer,addr default_diff_txt_name
        invoke lstrcpy,addr nowFileName,addr default_diff_txt_name
        mov  open_filename_struct.lpstrFile, OFFSET buffer
        invoke CreateFile,ADDR buffer,GENERIC_READ or GENERIC_WRITE ,\
                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
                                NULL
     mov h_file,eax
     mov h_hot_file,eax
     invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEM_SIZE
     mov  hMemory,eax
     invoke GlobalLock,hMemory
     mov  pMemory,eax
     invoke ReadFile,h_file,pMemory,MEM_SIZE-1,ADDR SizeReadWrite,NULL
     invoke SendMessage,h_rich_edit,WM_SETTEXT,NULL,pMemory
     invoke CloseHandle,h_file
     invoke GlobalUnlock,pMemory
     invoke GlobalFree,hMemory
     invoke SetFocus,h_rich_edit
    .else
        ret
    .endif
    ret

OpenDiffHint endp


SearchProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	.if uMsg==WM_INITDIALOG
		push hWnd
		pop hSearch
		invoke CheckRadioButton,hWnd,IDC_DOWN,IDC_UP,IDC_DOWN
		invoke SendDlgItemMessage,hWnd,IDC_FINDEDIT,WM_SETTEXT,0,addr FindBuffer
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		shr eax,16
		.if ax==BN_CLICKED
			mov eax,wParam
			.if ax==IDOK
				mov uFlags,0
				invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr findtext.chrg ;obtain the current selection to to know the starting point of the search operation
				invoke GetDlgItemText,hWnd,IDC_FINDEDIT,addr FindBuffer,sizeof FindBuffer
				.if eax!=0
					invoke IsDlgButtonChecked,hWnd,IDC_DOWN
					.if eax==BST_CHECKED ;If the downward search is indicated, we set FR_DOWN flag to uFlags
						or uFlags,FR_DOWN
						mov eax,findtext.chrg.cpMin
						.if eax!=findtext.chrg.cpMax 
							push findtext.chrg.cpMax
							pop findtext.chrg.cpMin ;cpMin=cpMax
						.endif
						mov findtext.chrg.cpMax,-1 ;cpMax=max
					.else                          ;upward search
						mov findtext.chrg.cpMax,0  ;cpMax=0
					.endif
					invoke IsDlgButtonChecked,hWnd,IDC_MATCHCASE
					.if eax==BST_CHECKED
						or uFlags,FR_MATCHCASE
					.endif
					invoke IsDlgButtonChecked,hWnd,IDC_WHOLEWORD
					.if eax==BST_CHECKED
						or uFlags,FR_WHOLEWORD
					.endif
					mov findtext.lpstrText,offset FindBuffer
					invoke SendMessage,h_rich_edit,EM_FINDTEXTEX,uFlags,addr findtext
					.if eax!=-1
						invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr findtext.chrgText
					.endif
				.endif
			.elseif ax==IDCANCEL
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.else
				mov eax,FALSE
				ret
			.endif
		.endif
	.elseif uMsg==WM_CLOSE
		mov hSearch,0
		invoke EndDialog,hWnd,0
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
SearchProc endp

GoToProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	LOCAL LineNo:DWORD
	LOCAL chrg:CHARRANGE
	.if uMsg==WM_INITDIALOG
		push hWnd
		pop hSearch
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		shr eax,16
		.if ax==BN_CLICKED
			mov eax,wParam
			.if ax==IDCANCEL
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.elseif ax==IDOK
				invoke GetDlgItemInt,hWnd,IDC_LINENO,NULL,FALSE
                dec eax
				mov LineNo,eax
				invoke SendMessage,h_rich_edit,EM_GETLINECOUNT,0,0
				.if eax>LineNo				
					invoke SendMessage,h_rich_edit,EM_LINEINDEX,LineNo,0
					invoke SendMessage,h_rich_edit,EM_SETSEL,eax,eax
					invoke SetFocus,h_rich_edit				
				.endif
			.endif
		.endif
	.elseif uMsg==WM_CLOSE
		mov hSearch,0
		invoke EndDialog,hWnd,0
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
GoToProc endp

ReplaceProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	LOCAL settext:SETTEXTEX
	.if uMsg==WM_INITDIALOG
		push hWnd
		pop hSearch
		invoke SetDlgItemText,hWnd,IDC_FINDEDIT,addr FindBuffer
		invoke SetDlgItemText,hWnd,IDC_REPLACEEDIT,addr ReplaceBuffer
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		shr eax,16
		.if ax==BN_CLICKED
			mov eax,wParam
			.if ax==IDCANCEL
                invoke GetDlgItemText,hWnd,IDC_FINDEDIT,addr FindBuffer,sizeof FindBuffer
				invoke GetDlgItemText,hWnd,IDC_REPLACEEDIT,addr ReplaceBuffer,sizeof ReplaceBuffer
				mov findtext.chrg.cpMin,0
				mov findtext.chrg.cpMax,-1
				mov findtext.lpstrText,offset FindBuffer
				mov settext.flags,ST_SELECTION
				mov settext.codepage,CP_ACP
            	.while TRUE
					invoke SendMessage,h_rich_edit,EM_FINDTEXTEX,FR_DOWN,addr findtext
					.if eax==-1
						.break
					.else
						invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr findtext.chrgText
						invoke SendMessage,h_rich_edit,EM_SETTEXTEX,addr settext,addr ReplaceBuffer
					.endif
				.endw
				;invoke SendMessage,hWnd,WM_CLOSE,0,0
			.elseif ax==IDOK
                invoke SendMessage,h_rich_edit,EM_EXGETSEL,0,addr findtext.chrg                	
				invoke GetDlgItemText,hWnd,IDC_FINDEDIT,addr FindBuffer,sizeof FindBuffer
				invoke GetDlgItemText,hWnd,IDC_REPLACEEDIT,addr ReplaceBuffer,sizeof ReplaceBuffer
				mov eax,findtext.chrg.cpMin
				.if eax!=findtext.chrg.cpMax 
					push findtext.chrg.cpMax
					pop findtext.chrg.cpMin ;cpMin=cpMax
				.endif
				mov findtext.chrg.cpMax,-1;cpMax=max
				mov findtext.lpstrText,offset FindBuffer
				mov settext.flags,ST_SELECTION
				mov settext.codepage,CP_ACP
                invoke SendMessage,h_rich_edit,EM_FINDTEXTEX,FR_DOWN,addr findtext
                .if eax!=-1
						invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr findtext.chrgText
                        invoke SendMessage,h_rich_edit,EM_SETTEXTEX,addr settext,addr ReplaceBuffer
				.endif
            .elseif ax==IDC_LAST
				invoke GetDlgItemText,hWnd,IDC_FINDEDIT,addr FindBuffer,sizeof FindBuffer
				invoke GetDlgItemText,hWnd,IDC_REPLACEEDIT,addr ReplaceBuffer,sizeof ReplaceBuffer
				mov findtext.chrg.cpMax,0 ;cpMax=0
				mov findtext.lpstrText,offset FindBuffer
				mov settext.flags,ST_SELECTION
				mov settext.codepage,CP_ACP
                invoke SendMessage,h_rich_edit,EM_FINDTEXTEX,0,addr findtext
                .if eax!=-1
						invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr findtext.chrgText
                        invoke SendMessage,h_rich_edit,EM_SETTEXTEX,addr settext,addr ReplaceBuffer
				.endif
			.endif
		.endif
	.elseif uMsg==WM_CLOSE
		mov hSearch,0
		invoke EndDialog,hWnd,0
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
ReplaceProc endp

MyFontDialog proc hwnd:DWORD,lf:DWORD

          ; ------------------------------------
          ; Initialize the CHOOSEFONT structure.
          ; ------------------------------------
          invoke RtlZeroMemory,ADDR cf,SIZEOF cf 
          mov cf.lStructSize,SIZEOF cf
          mov eax,hwnd
          mov cf.hwndOwner,eax
          mov eax,lf 
          mov cf.lpLogFont,eax
          mov eax,rgbCurrnt
          mov cf.rgbColors,eax

          mov cf.Flags,CF_SCREENFONTS or CF_EFFECTS or CF_INITTOLOGFONTSTRUCT; or CF_NOFACESEL or CF_NOSTYLESEL or CF_NOSIZESEL
          ; -------------------------------------
          ; Call the Font Common Control dialog.
          ; -------------------------------------
          invoke ChooseFont,ADDR cf
          .if eax==0
          mov font_dialog_choose_ok,0
          .else
          mov font_dialog_choose_ok,1
          .endif
          ; -------------------------------------------------------
          ; If OK button is clicked return value is TRUE and the
          ; members of the CHOOSEFONT structure contains the users
          ; selections. If Cancel or [X] clicked in the Font dialog
          ; box or an error occurs the return value is FALSE.
          ; -------------------------------------------------------
          ret

MyFontDialog endp

set_font_dialog PROC
    LOCAL lfnt:LOGFONT
    LOCAL cfm:CHARFORMAT
    LOCAL chrg:CHARRANGE
    LOCAL hfnt:HANDLE
    mov lfnt.lfItalic,0
    mov lfnt.lfUnderline,0
    mov lfnt.lfStrikeOut,0
    mov lfnt.lfHeight,20
    invoke MyFontDialog,h_main_window,addr lfnt;,CF_SCREENFONTS or CF_FIXEDPITCHONLY ; dialog for choosing font

    ;全选
    mov chrg.cpMin,0
	mov chrg.cpMax,-1
	invoke SendMessage,h_rich_edit,EM_EXSETSEL,0,addr chrg
    .if font_dialog_choose_ok==1;设置成功

    invoke CreateFontIndirect, addr lfnt
    
    mov hfnt, eax

    invoke SendMessage, h_rich_edit, WM_SETFONT, hfnt, 1

    invoke RtlZeroMemory,addr cfm,sizeof cfm
	mov cfm.cbSize,sizeof cfm
	mov cfm.dwMask,CFM_COLOR
    push rgbCurrnt
	pop cfm.crTextColor
	invoke SendMessage,h_rich_edit,EM_SETCHARFORMAT,SCF_SELECTION,addr cfm
	ret
    .else
        ret
    .endif
set_font_dialog ENDP

GoToBottom proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL LineNo:DWORD
	invoke SendMessage,h_rich_edit,EM_GETLINECOUNT,0,0
	mov LineNo,eax				
	invoke SendMessage,h_rich_edit,EM_LINEINDEX,LineNo,0
	invoke SendMessage,h_rich_edit,EM_SETSEL,eax,eax
	invoke SetFocus,h_rich_edit				
	ret
GoToBottom endp

GoToTop proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL LineNo:DWORD
	invoke SendMessage,h_rich_edit,EM_GETLINECOUNT,0,0
	mov LineNo,0				
	invoke SendMessage,h_rich_edit,EM_LINEINDEX,LineNo,0
	invoke SendMessage,h_rich_edit,EM_SETSEL,eax,eax
	invoke SetFocus,h_rich_edit				
	ret
GoToTop endp

Do_ToolBar proc hWin :DWORD
    LOCAL bSize :DWORD
    LOCAL tbab  :TBADDBITMAP
    LOCAL tbb   :TBBUTTON

    invoke LoadBitmap, hInstance, 2000
    mov hTbBmp,eax

    Create_Tool_Bar 25, 25 ;toolbar button width & height

    TBextraData     ; additional data for TBBUTTON structure

    TBbutton  0,  50
    TBbutton  1,  51
    TBbutton  2,  52
    TBbutton  3,  53
    TBblank
    TBbutton  4,  54
    TBbutton  5,  55
    TBbutton  6,  56
    TBblank
    TBbutton  7,  57
    TBbutton  8,  58
    TBbutton  9,  59
    TBbutton  10, 60
    TBblank
    TBbutton  11, 61
    TBbutton  12, 62
    TBbutton  13, 63

    ret

Do_ToolBar endp

SetBmpColor proc hBitmap:DWORD

    LOCAL mDC       :DWORD
    LOCAL hBrush    :DWORD
    LOCAL hOldBmp   :DWORD
    LOCAL hReturn   :DWORD
    LOCAL hOldBrush :DWORD

      invoke CreateCompatibleDC,NULL
      mov mDC,eax

      invoke SelectObject,mDC,hBitmap
      mov hOldBmp,eax

      invoke GetSysColor,COLOR_BTNFACE
      invoke CreateSolidBrush,eax
      mov hBrush,eax

      invoke SelectObject,mDC,hBrush
      mov hOldBrush,eax

      invoke GetPixel,mDC,1,1
      invoke ExtFloodFill,mDC,1,1,eax,FLOODFILLSURFACE

      invoke SelectObject,mDC,hOldBrush
      invoke DeleteObject,hBrush

      invoke SelectObject,mDC,hBitmap
      mov hReturn,eax
      invoke DeleteDC,mDC

      mov eax,hReturn

    ret
SetBmpColor endp

Do_Status proc hParent:DWORD

    LOCAL sbParts[4] :DWORD
    
    invoke CreateStatusWindow,WS_CHILD or WS_VISIBLE or SBS_SIZEGRIP,NULL, hParent, 200
    ;invoke CreateWindowEx, NULL,addr statusclass,0,WS_VISIBLE or WS_CHILD or SBS_SIZEGRIP,\
	;			0,0,0,0,hParent,200,0,0
                
    mov hStatus, eax
    invoke SendMessage,hStatus,SB_SETUNICODEFORMAT,TRUE,0
    ; -------------------------------------
    ; sbParts is a DWORD array of 4 members
    ; -------------------------------------
    mov [sbParts +  0],   250    ; pixels from left
    mov [sbParts +  4],   500    ; pixels from left
    mov [sbParts +  8],   750    ; pixels from left
    mov [sbParts + 12],    -1    ; last part

    invoke SendMessage,hStatus,SB_SETPARTS,4,ADDR sbParts
 
    ret

Do_Status endp

end start
