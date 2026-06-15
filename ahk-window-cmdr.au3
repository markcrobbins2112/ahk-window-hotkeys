#NoTrayIcon
#include <MsgBoxConstants.au3>

If $CmdLine[0] < 1 Then
    MsgBox($MB_ICONINFORMATION, "HotWinAHK Commander", "Usage: ahk-window-cmdr.exe <CommandName1> [<CommandName2> ...]")
    Exit
EndIf

; 1. Grab Mouse position
Local $aPos = MouseGetPos()
If @error Then Exit

; 2. Find Window under mouse cursor
Local $aWin = DllCall("user32.dll", "hwnd", "WindowFromPoint", "long", $aPos[0], "long", $aPos[1])
If @error Or Not $aWin[0] Then Exit
Local $hWnd = $aWin[0]

; 3. Obtain topmost parent / ancestor window of that target
Local $aRet = DllCall("user32.dll", "hwnd", "GetAncestor", "hwnd", $hWnd, "uint", 2) ; GA_ROOT = 2
Local $hWndAncestor = $hWnd
If Not @error And $aRet[0] Then
    $hWndAncestor = $aRet[0]
EndIf

; Check if topmost parent / ancestor window is visible and is an overlapped window.
; In Win32, an overlapped window features neither WS_CHILD (0x40000000) nor WS_POPUP (0x80000000).
Local $aVisible = DllCall("user32.dll", "bool", "IsWindowVisible", "hwnd", $hWndAncestor)
If @error Or Not $aVisible[0] Then Exit

Local $aStyle = DllCall("user32.dll", "long", "GetWindowLongW", "hwnd", $hWndAncestor, "int", -16) ; GWL_STYLE = -16
If @error Then Exit
Local $iStyle = $aStyle[0]

; Verify it is overlapped (no WS_CHILD, no WS_POPUP)
If BitAND($iStyle, 0x40000000) <> 0 Or BitAND($iStyle, 0x80000000) <> 0 Then Exit

; 4. Find the main HotWinAHK instance
Local $hAHK = WinGetHandle("[CLASS:AutoHotkey]")
If @error Or Not $hAHK Then
    MsgBox($MB_ICONERROR + $MB_SYSTEMMODAL, "Error", "HotWinAHK orchestrator engine is not running.")
    Exit
EndIf

; 5. Send each command parameter to HotWinAHK
For $i = 1 To $CmdLine[0]
    Local $cmd = $CmdLine[$i]
    ; Construct message payload: "CommandName|hWnd"
    Local $sPayload = $cmd & "|" & String($hWndAncestor)
    SendCopyData($hAHK, $sPayload)
Next

Func SendCopyData($hTarget, $sMessage)
    Local $tData = DllStructCreate("char[" & StringLen($sMessage) + 1 & "]")
    DllStructSetData($tData, 1, $sMessage)
    
    Local $tCDS = DllStructCreate("ulong_ptr;dword;ptr")
    DllStructSetData($tCDS, 1, 0)
    DllStructSetData($tCDS, 2, StringLen($sMessage) + 1)
    DllStructSetData($tCDS, 3, DllStructGetPtr($tData))
    
    Local $aResult = DllCall("user32.dll", "lresult", "SendMessage", _
                             "hwnd", $hTarget, _
                             "uint", 0x004A, _
                             "wparam", 0, _
                             "lparam", DllStructGetPtr($tCDS))
    If @error Then Return 0
    Return $aResult[0]
EndFunc
