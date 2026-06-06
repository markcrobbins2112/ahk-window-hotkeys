#Requires AutoHotkey v2.0
#SingleInstance Off
Persistent

; Read the parameters passed by the main script
if (A_Args.Length < 3)
    ExitApp()

sAction      := A_Args[1] ; The "add" or "delete" action parameter
sHwndHex     := A_Args[2] ; The target window handle string
sTooltipText := A_Args[3] ; The mouse-over hover description text

; Force the hex tracking text back into a true numeric pointer integer
hWndTarget := Number(sHwndHex)

if (sAction == "add") {
    ; Clear default AHK tray icon menu layouts
    A_TrayMenu.Delete()
    
    ; Setup standard native menu handlers
    A_TrayMenu.Add("Restore Window", (*) => RestoreWindowBridge(hWndTarget))
    A_TrayMenu.Add("Close Window", (*) => CloseWindowBridge(hWndTarget))
    A_TrayMenu.Default := "Restore Window"
    
    ; Extract the executable path of the program from its active window handle
    sProcessPath := ""
    try sProcessPath := WinGetProcessPath(hWndTarget)
    
    ; Set the hover description text natively
    if (sTooltipText != "")
        A_IconTip := sTooltipText

    ; Inject the native icon directly into the Windows Shell Core System Tray area
    if (sProcessPath != "" && FileExist(sProcessPath)) {
        try TraySetIcon(sProcessPath, 1)
    } else {
        try TraySetIcon("shell32.dll", 16) ; Fallback generic application frame icon
    }
} else if (sAction == "delete") {
    ExitApp()
}

RestoreWindowBridge(hWnd) {
    try {
        ShellObj := ComObject("Shell.Application")
        ShellObj.UndoMinimizeALL() 
    }
    ; Restore the frame safely using native AHK window controllers
    if WinExist(hWnd) {
        WinShow(hWnd)
        WinRestore(hWnd)
        WinActivate(hWnd)
    }
    ExitApp()
}

CloseWindowBridge(hWnd) {
    if WinExist(hWnd)
        WinClose(hWnd)
    ExitApp()
}
