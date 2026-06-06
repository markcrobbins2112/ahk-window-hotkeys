#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Force Administrative Privileges to interact with system applications
if not A_IsAdmin {
    Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp()
}

; =======================================================================================
; INITIALIZATION & SYSTEM CONFIGURATION
; =======================================================================================
Global g_sIniFile := A_ScriptDir "\WindowHotkeys.ini"
Global g_sGeneratedFile := A_ScriptDir "\WindowHotkeys.ahk"
Global g_bSuspended := false
; --- ADD THIS NEW GLOBAL DICTIONARY TRACKER ---
Global g_mActiveTrayMenus := Map() ; Tracks all minimized tray menus safely in AHK v2
; --- ADD THESE TWO GLOBAL TRACKERS TO THE TOP OF PART 1 ---
Global g_ResetCallback := ""   ; Keeps the timer memory alive globally
Global g_hOpacityActiveHWND := 0 ; Remembers the window handle between keypresses
; --- ADD THIS NEW STATIC WINDOW HANDLE REGISTER ---
Global g_hMainScriptHWND := A_ScriptHwnd ; Locks the true physical window ID on startup
; --- THE LIVE WINDOW REGISTRY ---
Global g_mHiddenWindowsRegistry := Map() ; Key: hWnd | Value: Window Title text string
Global g_z := 20 ; 

; FIXED: Emergency compilation placeholder block stops boot crashing
if !FileExist(g_sGeneratedFile) {
    FileAppend("; Initial boot placeholder`n", g_sGeneratedFile, "UTF-8")
}

; --- THE SELF-COMPILING SCRIPT GENERATOR ENGINE ---
CompileIniToStaticHotkeys()

; Sound confirmation beep on successful loading
SoundBeep(1000, 300)
try TrayTip("Engine Reloaded", "Window Nudger Active", 1)

; Build Custom Tray Menu Layout using standard named callbacks
A_TrayMenu.Delete() ; Clear defaults
A_TrayMenu.Add("Suspend Hotkeys", Menu_ToggleSuspension)
A_TrayMenu.Add("Reload INI", Menu_ReloadIniConfig)
A_TrayMenu.Add("Edit INI", Menu_EditIniConfig)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", Menu_ExitApp)


; =======================================================================================
; ADMINISTRATIVE CONTROL UTILITIES
; =======================================================================================
IsMetaCommand(sCmd) {
    return RegExMatch(sCmd, "i)^(ToggleSuspension|ReloadConfig|EditConfig|ExitProgram|RestartProgram)$")
}

ToggleSuspension() {
    global g_bSuspended := !g_bSuspended
    SoundBeep(g_bSuspended ? 400 : 900, 200)
    ShowTargetToolTip(g_bSuspended ? "Suspended" : "Active")
}

ReloadIniConfig() {
    SoundBeep(600, 150)
    ShowTargetToolTip("Re-Compiling Matrix...")
    CompileIniToStaticHotkeys()
}

EditIniConfig() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        FileAppend("; Window Nudger Configuration Setup`n", g_sIniFile)
    }

    ; FIXED: Call the Windows Shell directly.
    ; This replicates a real mouse double-click, forcing your default .ini program to open it.
    DllCall("shell32\ShellExecuteW",
        "ptr", 0,
        "str", "open",
        "str", g_sIniFile,
        "str", "",
        "str", "",
        "int", 1) ; 1 = SW_SHOWNORMAL
}

; =======================================================================================
; CORE HOTKEY RUNTIME PIPELINE
; =======================================================================================
; Injects the freshly compiled, native shell hotkeys file directly into the script scope
#Include "WindowHotkeys.ahk"

; =======================================================================================
; HARDENED INI TO AHK COMPILER ENGINE
; =======================================================================================
; =======================================================================================
; DUP-PROTECTED INI TO AHK COMPILER ENGINE
; =======================================================================================
CompileIniToStaticHotkeys() {
    global g_sIniFile, g_sGeneratedFile

    if !FileExist(g_sIniFile)
        return

    ; Initialize the text buffer for the generated file
    ScriptBuffer := "; =======================================================================================`n"
    ScriptBuffer .= ";          AUTOMATICALLY GENERATED NATIVE SHELL HOTKEYS - DO NOT EDIT DIRECTLY`n"
    ScriptBuffer .= "; =======================================================================================`n#Requires AutoHotkey v2.0`n`n"

    ; NEW: Create a flat text registry to track uniquely written combinations
    WrittenKeysRegistry := ""

    ; Read all command section names from the INI configuration file
    SectionsText := IniRead(g_sIniFile)
    loop parse, SectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") ; Skip empty or disabled entries
            continue

        ; Scan for up to g_z fallback variant hotkey definitions per command
        loop 10 {
            KeyValue := IniRead(g_sIniFile, sCmd, "keys" A_Index, "")
            if (KeyValue == "")
                break

            ; Strictly parse strings using explicit 1-indexed AHK v2 array syntax
            if InStr(KeyValue, "|") {
                aSplit := StrSplit(KeyValue, "|")
                sStroke := Trim(aSplit[1])
                sCond := Trim(aSplit[2])
            } else {
                sStroke := Trim(KeyValue)
                sCond := ""
            }

            ; Map modifiers cleanly to strict shell layout notation symbols
            sAHKStroke := CompileStrokeToAHK(sStroke)
            if (sAHKStroke == "")
                continue

            ; NEW: INTERCEPT DUPLICATES. If this exact key combination was already written, skip it!
            if InStr(WrittenKeysRegistry, "|" sAHKStroke "|")
                continue

            ; Append the unique shortcut to our temporary tracker registry string
            WrittenKeysRegistry .= "|" sAHKStroke "|"

            ; Dynamically write structural, hardwired functional shortcut definitions
            ScriptBuffer .= sAHKStroke ":: {`n"
            ScriptBuffer .= "    ExecuteActionWithCondition(`"" sCmd "`", `"" sCond "`")`n"
            ScriptBuffer .= "}`n`n"
        }
    }

    ; Read existing file text to verify if any modifications actually happened
    ExistingText := FileExist(g_sGeneratedFile) ? FileRead(g_sGeneratedFile) : ""

    ; Standardize formatting for exact structural text comparison
    if (Trim(ScriptBuffer) != Trim(ExistingText)) {
        if FileExist(g_sGeneratedFile)
            FileDelete(g_sGeneratedFile)

        FileAppend(ScriptBuffer, g_sGeneratedFile, "UTF-8")
        Sleep(50) ; Hardened write delay ensures Windows registers file I/O operations

        ; If the engine is already initialized, reload immediately to apply shortcuts
        if (ExistingText != "") {
            Reload()
            ExitApp()
        }
    }
}

CompileStrokeToAHK(sStroke) {
    sStroke := StrReplace(sStroke, " ", "")

    bCtrl := RegExMatch(sStroke, "i)(Ctrl|LCtrl|RCtrl)")
    bAlt := RegExMatch(sStroke, "i)(Alt|LAlt|RAlt)")
    bShift := RegExMatch(sStroke, "i)(Shift|LShift|RShift)")
    bWin := RegExMatch(sStroke, "i)(Win|LWin|RWin)")

    sCleanKey := RegExReplace(sStroke, "i)(LCtrl\+|RCtrl\+|Ctrl\+|LAlt\+|RAlt\+|Alt\+|LShift\+|RShift\+|Shift\+|LWin\+|RWin\+|Win\+)", "")
    if (sCleanKey == "")
        return ""

    ; FIXED: Convert the final character key token to lowercase to prevent
    ; AutoHotkey from throwing duplicate Shift state calculation errors!
    sCleanKey := StrLower(sCleanKey)

    sAHKPrefix := ""
    if (bCtrl)
        sAHKPrefix .= "^"
    if (bAlt)
        sAHKPrefix .= "!"
    if (bShift)
        sAHKPrefix .= "+"
    if (bWin)
        sAHKPrefix .= "#"

    return sAHKPrefix . sCleanKey
}

; =======================================================================================
; STANDARD TRAY CALL-BACK FUNCTIONS
; =======================================================================================
Menu_ToggleSuspension(ItemName, ItemPos, MyMenu) {
    ToggleSuspension()
}
Menu_ReloadIniConfig(ItemName, ItemPos, MyMenu) {
    ReloadIniConfig()
}
Menu_EditIniConfig(ItemName, ItemPos, MyMenu) {
    EditIniConfig()
}

Menu_ExitApp(ItemName, ItemPos, MyMenu) {
    ShutdownEngine()
}    ; Clear any lingering tooltips on the screen

; --- NEW UNIFIED SHUTDOWN PIPELINE ---
ShutdownEngine() {
    ; Clear any lingering tooltips on the screen instantly
    ToolTip()

    ; Display the modern Windows system tray toast notification
    try TrayTip("Window Nudger", "Engine Shutdown - Hotkeys Released", 2)

    ; Play the polished, descending exit tone cascade
    SoundBeep(800, 100)
    SoundBeep(600, 100)
    SoundBeep(400, 150)

    ; Brief pause lets Windows draw the graphic toast before the thread destroys itself
    Sleep(300)
    ExitApp()
}
MouseGetWindowHWND() {
    MouseGetPos , , &hWnd
    return hWnd
}

ShowTargetToolTip(sText) {
    ToolTip(sText)
    SetTimer(ClearToolTip, -1500)
}

ClearToolTip() {
    ToolTip()
}

; === Keep your Part 2 Condition and Geometry functions appended down here ===
; =======================================================================================
; ACTION DISPATCHER & CONDITION MONITOR
; =======================================================================================
ExecuteActionWithCondition(sCmd, sCond) {
    TraceLogString := "Command: [" . sCmd . "] | Filter: [" . (sCond == "" ? "NONE" : sCond) . "]"
    ToolTip("⚡ RUNNING ENGINE ACTION`n" . TraceLogString)
    SetTimer(() => ToolTip(), -2500)

    if IsMetaCommand(sCmd) {
        ExecuteCommandRegistry(sCmd, 0)
        return
    }

    if g_bSuspended
        return

    hWndTarget := InStr(sCmd, "UnderMouse") ? MouseGetWindowHWND() : DllCall("user32\GetForegroundWindow", "ptr")

    if (hWndTarget) {
        A_Clipboard := "-- title " . WinGetTitle(hWndTarget) . WinGetClass(hWndTarget)
    }

    ; Bypass the tooltip check safely to avoid grabbing our own popup bubbles
    if (hWndTarget && WinGetClass(hWndTarget) == "tooltips_class32") {
        hWndTarget := WinExist("A")
    }

    if (!hWndTarget) {
        A_Clipboard := "No HWND"
        return
    }

    if (sCond != "" && sCond != '""' && sCond != '`"`"') {
        aP := StrSplit(sCond, "=")
        if (aP.Length < 2)
            return

        sT := aP[1]
        sM := aP[2]
        sTitle := WinGetTitle(hWndTarget)
        sClass := WinGetClass(hWndTarget)
        sExe := WinGetProcessName(hWndTarget)

        bFail := false
        if (sT == "wintitleis" && sTitle != sM) || (sT == "wintitlehas" && !InStr(sTitle, sM))
            bFail := true
        else if (sT == "winclassis" && sClass != sM) || (sT == "winclasshas" && !InStr(sClass, sM))
            bFail := true
        else if (sT == "winexeis" && sExe != sM)
            bFail := true

        if bFail {
            SoundBeep(400, 150)
            ShowTargetToolTip("Condition Failed: " sCmd)
            return
        }
    }

    ExecuteCommandRegistry(sCmd, hWndTarget)
}

; =======================================================================================
; THE CORE COMMAND ENGINE (GEOMETRY & TRANSFORMATIONS)
; =======================================================================================
ExecuteCommandRegistry(sCmd, hWnd) {
    ; HARDENED SCOPE FIX: You MUST declare global access inside the first line of the function.
    ; This explicitly pulls your top-level trackers down into the function context.
    global g_hOpacityActiveHWND, g_ResetCallback

    if !IsMetaCommand(sCmd) {
        try {
            WinGetPos(&X, &Y, &W, &H, hWnd)
        } catch {
            return
        }
    }

    ; FIXED: Added ", false" to force case-insensitivity on administrative tools
    switch sCmd, false {
        case "ToggleSuspension": ToggleSuspension()
        case "ReloadConfig": ReloadIniConfig()
        case "EditConfig": EditIniConfig()
        case "ExitProgram": ShutdownEngine()
        case "RestartProgram": Reload()
    }

    if RegExMatch(sCmd, "i)^Move") {
        iStep := InStr(sCmd, "10px") ? g_z : 1
        dX := InStr(sCmd, "Left") ? -iStep : InStr(sCmd, "Right") ? iStep : 0
        dY := InStr(sCmd, "Up") ? -iStep : InStr(sCmd, "Down") ? iStep : 0
        WinMove(X + dX, Y + dY, , , hWnd)
        return
    }

    switch sCmd, false {
        case "SnapLeft", "SnapRight", "SnapTop", "SnapBottom", "SnapCenter", "SnapTopLeft", "SnapTopRight", "SnapBottomLeft", "SnapBottomRight":
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)
            if DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")
                mWidth := mRight - mLeft
                mHeight := mBottom - mTop

                nX := X, nY := Y
                switch sCmd {
                    case "SnapLeft": nX := mLeft
                    case "SnapRight": nX := mRight - W
                    case "SnapTop": nY := mTop
                    case "SnapBottom": nY := mBottom - H
                    case "SnapTopLeft": nX := mLeft, nY := mTop
                    case "SnapTopRight": nX := mRight - W, nY := mTop
                    case "SnapBottomLeft": nX := mLeft, nY := mBottom - H
                    case "SnapBottomRight": nX := mRight - W, nY := mBottom - H
                    case "SnapCenter": nX := mLeft + Floor((mWidth - W) / 2), nY := mTop + Floor((mHeight - H) / 2)
                }
                WinMove(nX, nY, , , hWnd)
            }
        case "StretchLeft", "StretchRight", "StretchTop", "StretchBottom":
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)
            if DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                nX := X, nY := Y, nW := W, nH := H
                switch sCmd {
                    case "StretchLeft":   nX := mLeft, nW := (X + W) - mLeft
                    case "StretchRight":  nW := mRight - X
                    case "StretchTop":    nY := mTop, nH := (Y + H) - mTop
                    case "StretchBottom": nH := mBottom - Y
                }
                WinMove(nX, nY, nW, nH, hWnd)
            }
        case "NextWindow":
            ; 1. Push current window to the absolute bottom of the stack
            DllCall("SetWindowPos", "ptr", hWnd, "ptr", 1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0013) ; 1 = HWND_BOTTOM, 0x0013 = NOSIZE|NOMOVE|NOACTIVATE
            
            ; 2. Critical Pause: Give Windows a split second to process the depth shift
            Sleep(10)

            ; 3. Scan top-down from the remaining open applications
            winList := WinGetList()
            for targetHwnd in winList {
                if (targetHwnd == hWnd) ; Skip the window we just pushed down
                    continue
                    
                ; Ignore hidden system modules, desktop backgrounds, and taskbars
                winClass := WinGetClass(targetHwnd)
                if (winClass == "Progman" || winClass == "WorkerW" || winClass == "Shell_TrayWnd")
                    continue

                style := WinGetStyle(targetHwnd)
                ; Verify window is visible (WS_VISIBLE) and NOT minimized
                if ((style & 0x10000000) && WinGetMinMax(targetHwnd) != -1) {
                    WinActivate(targetHwnd)
                    break
                }
            }

        case "PrevWindow":
            ; Scan the entire window list backward (starting from the bottom of the stack up)
            winList := WinGetList()
            idx := winList.Length
            while (idx > 0) {
                targetHwnd := winList[idx]
                idx--
                
                if (targetHwnd == hWnd) ; Skip our current window
                    continue
                    
                ; Ignore hidden system modules, desktop backgrounds, and taskbars
                winClass := WinGetClass(targetHwnd)
                if (winClass == "Progman" || winClass == "WorkerW" || winClass == "Shell_TrayWnd")
                    continue

                style := WinGetStyle(targetHwnd)
                ; Verify window is visible (WS_VISIBLE) and NOT minimized
                if ((style & 0x10000000) && WinGetMinMax(targetHwnd) != -1) {
                    WinActivate(targetHwnd)
                    break
                }
            }

        case "MouseRelativeSize":
            ; 1. Get current mouse position (Screen coordinates)
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mX, &mY)

            ; 2. Fetch Monitor Boundary Data
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)
            
            if DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI) {
                mLeft   := NumGet(MI, 20, "int")
                mTop    := NumGet(MI, 24, "int")
                mRight  := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")
                
                ; Snapshot existing geometry
                origRight  := X + W
                origBottom := Y + H
                nX := X, nY := Y, nW := W, nH := H

                ; 3. CHECK FOR THE CENTER ZONE (Zone 5) FIRST
                thirdW := Floor(W / 3)
                thirdH := Floor(H / 3)
                if (mX >= X + thirdW && mX <= origRight - thirdW && mY >= Y + thirdH && mY <= origBottom - thirdH) {
                    centerMidPoint := X + Floor(W / 2)
                    if (mX >= centerMidPoint) {
                        nW := W + 40, nX := X - 20
                    } else {
                        nW := W - 20, nX := X + g_z
                    }
                }
                ; 4. CORNERS (7, 9, 1, 3): Closest corner dictates sizing anchors
                else if (Abs(mX - X) < thirdW && Abs(mY - Y) < thirdH) {
                    ; Zone 7: Top-Left Corner
                    nX := mX, nY := mY, nW := origRight - mX, nH := origBottom - mY
                } else if (Abs(mX - origRight) < thirdW && Abs(mY - Y) < thirdH) {
                    ; Zone 9: Top-Right Corner
                    nX := X, nY := mY, nW := mX - X, nH := origBottom - mY
                } else if (Abs(mX - X) < thirdW && Abs(mY - origBottom) < thirdH) {
                    ; Zone 1: Bottom-Left Corner
                    nX := mX, nY := Y, nW := origRight - mX, nH := mY - Y
                } else if (Abs(mX - origRight) < thirdW && Abs(mY - origBottom) < thirdH) {
                    ; Zone 3: Bottom-Right Corner
                    nX := X, nY := Y, nW := mX - X, nH := mY - Y
                }
                ; 5. EDGES (8, 2, 4, 6): Sized according to closest individual boundary line
                else {
                    distLeft   := Abs(mX - X)
                    distRight  := Abs(mX - origRight)
                    distTop    := Abs(mY - Y)
                    distBottom := Abs(mY - origBottom)
                    
                    minDist := Min(distLeft, distRight, distTop, distBottom)

                    if (minDist == distTop) {
                        ; Zone 8: Top Edge
                        nX := X, nY := mY, nW := W, nH := origBottom - mY
                    } else if (minDist == distBottom) {
                        ; Zone 2: Bottom Edge
                        nX := X, nY := Y, nW := W, nH := mY - Y
                    } else if (minDist == distLeft) {
                        ; Zone 4: Left Edge
                        nX := mX, nY := Y, nW := origRight - mX, nH := H
                    } else if (minDist == distRight) {
                        ; Zone 6: Right Edge
                        nX := X, nY := Y, nW := mX - X, nH := H
                    }
                }

                ; Monitor boundary safety clamps
                if (nX < mLeft) {
                    nW := nW - (mLeft - nX)
                    nX := mLeft
                }
                if (nY < mTop) {
                    nH := nH - (mTop - nY)
                    nY := mTop
                }
                if (nX + nW > mRight) {
                    nW := mRight - nX
                }
                if (nY + nH > mBottom) {
                    nH := mBottom - nY
                }

                ; Minimum size layout protection
                if (nW < 150) {
                    if (nX != X) nX := origRight - 150
                    nW := 150
                }
                if (nH < 150) {
                    if (nY != Y) nY := origBottom - 150
                    nH := 150
                }

                WinMove(nX, nY, nW, nH, hWnd)
            }

        case "ScaleExpand10px": WinMove(X - 5, Y - 5, W + g_z, H + g_z, hWnd)
        case "ScaleReduce10px": WinMove(X + 5, Y + 5, W - g_z, H - g_z, hWnd)
        case "TrimTop": WinMove(X, Y + g_z, W, H - g_z, hWnd)
        case "TrimBottom": WinMove(X, Y, W, H - g_z, hWnd)
        case "TrimLeft": WinMove(X + g_z, Y, W - g_z, H, hWnd)
        case "TrimRight": WinMove(X, Y, W - g_z, H, hWnd)
        case "AddTop": WinMove(X, Y - g_z, W, H + g_z, hWnd)
        case "AddBottom": WinMove(X, Y, W + g_z, H + g_z, hWnd)
        case "AddLeft": WinMove(X - g_z, Y, W + g_z, H, hWnd)
        case "AddRight": WinMove(X, Y, W + g_z, H, hWnd)

        case "HalfSizeLeft": WinMove(X, Y, Floor(W / 2), H, hWnd)
        case "HalfSizeRight": WinMove(X + Floor(W / 2), Y, Floor(W / 2), H, hWnd)
        case "HalfSizeTop": WinMove(X, Y, W, Floor(H / 2), hWnd)
        case "HalfSizeBottom": WinMove(X, Y + Floor(H / 2), W, Floor(H / 2), hWnd)

        case "DoubleSizeLeft":   WinMove(X, Y, W * 2, H, hWnd)
        case "DoubleSizeRight":  WinMove(X - W, Y, W * 2, H, hWnd)
        case "DoubleSizeTop":    WinMove(X, Y, W, H * 2, hWnd)
        case "DoubleSizeBottom": WinMove(X, Y - H, W, H * 2, hWnd)


        case "AlwaysOnTop":
            WinSetAlwaysOnTop(-1, hWnd)
            bTop := WinGetExStyle(hWnd) & 0x8
            ShowTargetToolTip("AlwaysOnTop: " . (bTop ? "ON" : "OFF"))

        case "SetOpacity70":
            ; 1. Remember this specific window handle in our global tracker
            g_hOpacityActiveHWND := hWnd

            CurrentExStyle := DllCall("GetWindowLongPtrW", "ptr", g_hOpacityActiveHWND, "int", -20, "ptr")
            DllCall("SetWindowLongPtrW", "ptr", g_hOpacityActiveHWND, "int", -20, "ptr", CurrentExStyle | 0x00080000, "ptr")
            DllCall("user32\SetLayeredWindowAttributes", "ptr", g_hOpacityActiveHWND, "uint", 0, "uchar", 178, "uint", 2)
            ShowTargetToolTip("Opacity: 70% (60s Auto-Reset Active)")

        case "RemoveOpacity":
            global g_hOpacityActiveHWND, g_ResetCallback

            ; 1. Kill the background auto-reset timer loop immediately
            if (g_ResetCallback != "") {
                try SetTimer(g_ResetCallback, 0)
            }

            ; 2. Determine the target window handle safely
            if (g_hOpacityActiveHWND != 0) {
                hWndTarget := g_hOpacityActiveHWND
            } else {
                ; Fallback: Target the current active window if no variable was tracked yet
                hWndTarget := DllCall("user32\GetForegroundWindow", "ptr")
            }

            ; 3. NATIVE BYPASS CALL: Fire the fast internal reset pipeline directly
            if (hWndTarget) {
                ForceOpaqueWindowReset(hWndTarget)
            }
        case "SendToBack":
            WinMoveBottom(hWnd)

        case "MinimizeToTray":
            try hWnd := Number(hWnd)
            if (!hWnd || !WinExist(hWnd))
                return
                
            sTitle := WinGetTitle(hWnd)
            if (sTitle == "")
                sTitle := "Hidden Application Window"
            
            ; 1. RECORD WINDOW PROPERTIES IN OUR GLOBAL REGISTRY MAP
            global g_mHiddenWindowsRegistry
            g_mHiddenWindowsRegistry[hWnd] := sTitle
            
            if (StrLen(sTitle) > 60)
                sTitle := SubStr(sTitle, 1, 60) . "..."
                
            WinMinimize(hWnd)
            Sleep(100)
            WinHide(hWnd)
            
            ; 2. Launch the un-elevated tray helper child script to draw the individual icon
            sHelperPath := A_ScriptDir "\TrayHelper.ahk"
            if FileExist(sHelperPath) {
                sArgs := '"add" "' hWnd '" "' sTitle '"'
                ComObject("Shell.Application").ShellExecute(sHelperPath, sArgs, "", "open", 1)
            }
            ShowTargetToolTip("Minimized Window to System Tray")

        case "PickFromTray":
            ; Route hotkey commands directly into our dynamic popup menu constructor
            Menu_ShowHiddenMatrix()

        case "PeekUnderMouse":
            ShowTargetToolTip("Class: " . WinGetClass(hWnd))

        case "FocusLastActiveWindow":
            Send("!{Tab}")
        case "FocusProgramManager":
            ; Find the top-level Program Manager window handle natively by its class name
            hProgman := WinExist("ahk_class Progman")
            if hProgman {
                A_Clipboard := "Success: Focusing Program Manager Shell"
                WinActivate(hProgman)
                ShowTargetToolTip("Desktop Shell Focused")
            } else {
                ; Fallback: Try to target the companion desktop worker window if Progman is locked
                hWorkerW := WinExist("ahk_class WorkerW")
                if hWorkerW {
                    WinActivate(hWorkerW)
                    ShowTargetToolTip("Desktop Shell Focused (WorkerW)")
                }
            }

        case "FocusDeepestWindow":
            A_Clipboard := "hit FocusDeepestWindow case"

            aList := WinGetList()
            if (aList.Length > 0) {
                A_Clipboard := "hit FocusDeepestWindow case 2"
                
                loop aList.Length {
                    idx := aList.Length - A_Index + 1 ; Reverse scan from bottom up
                    targetHWND := aList[idx]

                    sTitle := WinGetTitle(targetHWND)
                    sClass := WinGetClass(targetHWND) ; Fetch the internal system class name
                    iStyle := WinGetStyle(targetHWND)
                    
                    ; Filter flags
                    bIsVisible := iStyle & 0x10000000 
                    bIsNotMinimized := !(WinGetMinMax(targetHWND) == -1)
                    
                    ; FIXED: Explicitly ignore Program Manager (Progman) and Windows Wallpaper containers (WorkerW)
                    bIsNotDesktop := (sClass != "Progman" && sClass != "WorkerW")

                    ; Execute filter validation including the desktop protection bypass
                    if (sTitle != "" && bIsVisible && bIsNotMinimized && bIsNotDesktop) {
                        A_Clipboard := "Success: Focusing Deepest Window -> " . sTitle
                        WinActivate(targetHWND)
                        ShowTargetToolTip("Focused Deepest Window")
                        break
                    }
                }
            }

        case "FocusDeepestClassInstance":
            sClass := WinGetClass(hWnd)
            if (sClass != "") {
                ; Get all windows matching the current window's precise class name
                aList := WinGetList("ahk_class " sClass)
                if (aList.Length > 1) {
                    ; The last element in the array is natively the absolute deepest instance in the Z-order
                    deepestHWND := aList[aList.Length]
                    WinActivate(deepestHWND)
                    ShowTargetToolTip("Focused Deepest Class Instance")
                }
            }

        case "CloseAllClassInstance", "MinimizeAllClassInstance", "RestoreAllClassInstance", "MaximizeAllClassInstance":
            sClass := WinGetClass(hWnd)
            if (sClass != "") {
                ; Isolate the target state alteration action verb
                sAction := RegExReplace(sCmd, "i)AllClassInstance$")

                ; Gather all program handles sharing the exact same class properties
                aList := WinGetList("ahk_class " sClass)
                loop aList.Length {
                    currentHWND := aList[A_Index]

                    switch sAction, false {
                        case "Close": WinClose(currentHWND)
                        case "Minimize": WinMinimize(currentHWND)
                        case "Restore": WinRestore(currentHWND)
                        case "Maximize": WinMaximize(currentHWND)
                    }
                }
                ShowTargetToolTip(sAction "d All Instances of Class: " sClass)
            }
    }
}

; =======================================================================================
; CORE RE-RENDER & HOOK EXCLUSIVITY FUNCTIONS (SILENT OVERRIDES)
; =======================================================================================
AutomaticallyRestoreOpacity(hWndToReset) {
    ; Explicitly check if the tracked window handles are still open in the OS window manager sheet
    if WinExist(hWndToReset) {
        ForceOpaqueWindowReset(hWndToReset)
    }
}

; =======================================================================================
; HARDENED NATIVE CORES RE-RENDER PIPELINE (NO EXTERNAL EXE)
; =======================================================================================
ForceOpaqueWindowReset(hWnd) {
    global g_hOpacityActiveHWND

    if !WinExist(hWnd)
        return

    ; --- CLIPBOARD TITLING ENGINE ---
    try {
        sTitle := WinGetTitle(hWnd)
        if (sTitle != "")
            A_Clipboard := sTitle
        else
            A_Clipboard := "No Window Title Found"
    } catch {
        A_Clipboard := "Error Extracting Window Title"
    }

    ; --- INSTANT WIN32 API BYPASS: RUNNING DIRECTLY INSIDE AHK ---
    ; Clear alpha channel tracking registers out of user32 memory map instantly
    DllCall("user32\SetLayeredWindowAttributes", "ptr", hWnd, "uint", 0, "uchar", 0, "uint", 0)

    ; Pull down extended attributes style sheet (-20 = GWL_EXSTYLE)
    CurrentExStyle := DllCall("GetWindowLongPtrW", "ptr", hWnd, "int", -20, "ptr")
    if (CurrentExStyle) {
        ; Completely delete the WS_EX_LAYERED flag (0x00080000) using a BitAND mask
        NewExStyle := CurrentExStyle & ~0x00080000
        DllCall("SetWindowLongPtrW", "ptr", hWnd, "int", -20, "ptr", NewExStyle, "ptr")
    }

    ; Immediately trigger a desktop paint redraw sequence natively
    WinRedraw(hWnd)

    ; Reset the global tracking slot back to 0 for fresh macros
    g_hOpacityActiveHWND := 0

    ; Play a crisp double-beep audio confirmation
    SoundBeep(1200, 80)
    SoundBeep(1500, 80)
}
; =======================================================================================
; SYSTEM TRAY MANAGEMENT UTILITIES (MAP INJECTION ROUTINES)
; =======================================================================================
TrayIconAdd(hWnd, TooltipText, IconPath) {
    global g_hMainScriptHWND
    CallbackFunc := (w, l, msg, h) => TrayIconCallback(hWnd, w, l, msg, h)
    OnMessage(0x0400 + hWnd, CallbackFunc)
    
    ; Fallback safety check: If the handle is blank, fetch it directly from kernel32
    if (!g_hMainScriptHWND) {
        g_hMainScriptHWND := DllCall("kernel32\GetModuleHandleW", "Ptr", 0, "Ptr")
    }

    NID := Buffer(A_PtrSize == 8 ? 976 : 528, 0)
    NumPut("UInt", NID.Size, NID, 0)
    NumPut("UPtr", g_hMainScriptHWND, NID, A_PtrSize) ; Passes the absolute true script handle
    NumPut("UInt", hWnd, NID, A_PtrSize * 2)
    NumPut("UInt", 1 | 2 | 4, NID, A_PtrSize * 2 + 4)
    NumPut("UInt", 0x0400 + hWnd, NID, A_PtrSize * 2 + 8)
    
    hShell32 := DllCall("kernel32\LoadLibraryW", "Str", "shell32.dll", "Ptr")
    
    hIcon := 0
    if (IconPath != "") {
        pExtractIcon := DllCall("kernel32\GetProcAddress", "Ptr", hShell32, "AStr", "ExtractIconW", "Ptr")
        if (pExtractIcon)
            hIcon := DllCall(pExtractIcon, "Ptr", g_hMainScriptHWND, "Str", IconPath, "UInt", 0, "Ptr")
    }
    
    if (hIcon == 0 || hIcon == -1 || hIcon == 1) {
        pExtractIcon := DllCall("kernel32\GetProcAddress", "Ptr", hShell32, "AStr", "ExtractIconW", "Ptr")
        if (pExtractIcon)
            hIcon := DllCall(pExtractIcon, "Ptr", g_hMainScriptHWND, "Str", "shell32.dll", "UInt", 15, "Ptr")
    }
    
    NumPut("UPtr", hIcon, NID, A_PtrSize * 3 + 4)
    StrPut(TooltipText, NID.Ptr + (A_PtrSize * 4 + 4), 128, "UTF-16")
    
    pShellNotifyIcon := DllCall("kernel32\GetProcAddress", "Ptr", hShell32, "AStr", "ShellNotifyIconW", "Ptr")
    if (pShellNotifyIcon) {
        DllCall(pShellNotifyIcon, "UInt", 0, "Ptr", NID) ; 0 = NIM_ADD
    }
}

TrayIconDelete(hWnd) {
    sHelperPath := A_ScriptDir "\TrayHelper.ahk"
    if FileExist(sHelperPath) {
        sArgs := '"delete" "' hWnd '" ""'
        ; FIXED: Route the deletion parameters via the safe COM shell architecture
        ComObject("Shell.Application").ShellExecute(sHelperPath, sArgs, "", "open", 1)
    }
}
TrayIconCallback(hWnd, wParam, lParam, msg, msg_hWnd) {
    global g_mActiveTrayMenus
    switch lParam {
        case 0x0201: ; WM_LBUTTONDOWN
            RestoreHiddenTrayWindow(hWnd)
        case 0x0205: ; WM_RBUTTONUP
            if g_mActiveTrayMenus.Has(hWnd) {
                CoordMode "Menu", "Screen"
                MouseGetPos &mX, &mY
                ; Pull the true Menu object reference straight out of the map and display it
                g_mActiveTrayMenus[hWnd].Show(mX, mY)
            }
    }
    return 1
}

RestoreHiddenTrayWindow(hWnd) {
    if WinExist(hWnd) {
        WinShow(hWnd)
        WinRestore(hWnd)
        WinActivate(hWnd)
    }
    TrayIconDelete(hWnd)
}

CloseHiddenTrayWindow(hWnd) {
    if WinExist(hWnd) {
        WinClose(hWnd)
    }
    TrayIconDelete(hWnd)
}
; =======================================================================================
; SPECIFIC EXCLUSIVITY TRAY MANAGEMENT MATRIX POPUP CONSTRUCTORS
; =======================================================================================
; =======================================================================================
; DARK-THEMED EXCLUSIVITY TRAY MANAGEMENT MATRIX POPUP CONSTRUCTORS
; =======================================================================================
; =======================================================================================
; OS THEME-MATCHING POPUP MENU ENGINE (TRUE WIN32 CORE INTERCEPT)
; =======================================================================================
; =======================================================================================
; NATIVE OS THEME-MATCHING & FOCUSED POPUP MENU ENGINE (UXTHEME HARDENED)
; =======================================================================================
; =======================================================================================
; NATIVE OS THEME-MATCHING & FOCUSED POPUP MENU ENGINE (UXTHEME HARDENED)
; =======================================================================================
; =======================================================================================
; NATIVE OS THEME-MATCHING & FOCUSED POPUP MENU ENGINE (UXTHEME HARDENED)
; =======================================================================================
; =======================================================================================
; NATIVE OS THEME-MATCHING & FOCUSED POPUP MENU ENGINE (UXTHEME HARDENED)
; =======================================================================================
; =======================================================================================
; NATIVE OS THEME-MATCHING & FOCUSED POPUP MENU ENGINE (UXTHEME HARDENED)
; =======================================================================================
; =======================================================================================
; MODERN NATIVE OS THEME-MATCHING POPUP MENU ENGINE (MODERN WINDOWS COMPLIANT)
; =======================================================================================
; =======================================================================================
; HARDENED NATIVE OS POPUP MENU ENGINE (TRUE CORE UXTHEME BYPASS)
; =======================================================================================
; =======================================================================================
; HARDENED NATIVE OS POPUP MENU ENGINE (UIPI FOCUS LOCK BYPASS)
; =======================================================================================
; =======================================================================================
; DIAGNOSTIC EXCEPTION TRACKING POPUP MENU ENGINE
; =======================================================================================
; =======================================================================================
; #Requires AutoHotkey v2.0
; OS-LEVEL ESCAPE POPUP MENU ENGINE (UIPI SECURITY COMPLIANT)
; =======================================================================================
; =======================================================================================
; RESTORED NATIVE OS POPUP MENU ENGINE (EXACT STEP RECOVERY)
; =======================================================================================
; =======================================================================================
; RESTORED NATIVE OS POPUP MENU ENGINE (NOTIFICATION LAYER BALANCED)
; =======================================================================================
; =======================================================================================
; RESTORED NATIVE OS POPUP MENU ENGINE (AUTO-HIGHLIGHT FOCUS INJECTED)
; =======================================================================================
; =======================================================================================
; THE ASYNCHRONOUS TIMER TARGET FUNCTION
; =======================================================================================
SendDownArrowToMenu() {
    ; #32768 is the internal hardcoded Windows class name for ALL native popup menus.
    ; We check if the menu window has physically spawned on the screen yet.
    hMenuWnd := WinExist("ahk_class #32768")
    if (hMenuWnd) {
        ; Force focus directly onto the menu container window frame
        DllCall("user32.dll\SetForegroundWindow", "Ptr", hMenuWnd)
        
        ; Send a standard keyboard Down Arrow press to highlight the first item row
        Send("{Down}")
    }
}
; =======================================================================================
; RESTORED NATIVE OS POPUP MENU ENGINE (STABLE RUNNER LAYOUT)
; =======================================================================================
Menu_ShowHiddenMatrix(*) {
    global g_mHiddenWindowsRegistry
    
    if (g_mHiddenWindowsRegistry.Count == 0) {
        TrayTip("The hidden window stashing registry database is currently empty.", "PickFromTray Matrix", 0x10)
        return
    }

    try {
        ; 1. Allocate a real, low-level OS popup window context from user32.dll
        hMenu := DllCall("user32.dll\CreatePopupMenu", "Ptr")
        if (!hMenu)
            return

        ; 2. Iterate through the database and clear out dead background window handles
        for hWnd, sTitle in g_mHiddenWindowsRegistry {
            if !WinExist(hWnd) {
                g_mHiddenWindowsRegistry.Delete(hWnd)
                continue
            }
            
            sCleanTitle := (StrLen(sTitle) > 35) ? SubStr(sTitle, 1, 35) . "..." : sTitle
            sDisplayTitle := sCleanTitle . " (" . Format("0x{:X}", hWnd) . ")"
            
            ; 3. Inject the element directly into the OS menu layout structure.
            DllCall("user32.dll\AppendMenuW", "Ptr", hMenu, "UInt", 0, "UPtr", hWnd, "Str", sDisplayTitle, "Int")
        }
        
        if (g_mHiddenWindowsRegistry.Count == 0) {
            DllCall("user32.dll\DestroyMenu", "Ptr", hMenu, "Int")
            TrayTip("The hidden window stashing registry database is currently empty.", "PickFromTray Matrix", 0x10)
            return
        }
        
        ; --- RESTORED VISUAL THEME ENGINE LAYER ---
        hUxTheme := DllCall("kernel32\LoadLibraryW", "Str", "uxtheme.dll", "Ptr")
        if (hUxTheme) {
            pShouldAppsUseDarkMode := DllCall("kernel32\GetProcAddress", "Ptr", hUxTheme, "Ptr", 132, "Ptr")
            bSysDark := pShouldAppsUseDarkMode ? DllCall(pShouldAppsUseDarkMode, "Int") : false
            
            pSetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", hUxTheme, "Ptr", 135, "Ptr")
            pFlushThemes := DllCall("kernel32\GetProcAddress", "Ptr", hUxTheme, "Ptr", 104, "Ptr")

            if (bSysDark) {
                if (pSetPreferredAppMode)
                    DllCall(pSetPreferredAppMode, "Int", 2) ; 2 = Force Dark Mode skin sheets
                if (pFlushThemes)
                    DllCall(pFlushThemes, "Int", 1)
                    
                bDarkOn := Buffer(4, 0), NumPut("Int", 1, bDarkOn, 0)
                DllCall("dwmapi.dll\DwmSetWindowAttribute", "Ptr", A_ScriptHwnd, "UInt", 20, "Ptr", bDarkOn, "UInt", 4, "Int")
            } else {
                if (pSetPreferredAppMode)
                    DllCall(pSetPreferredAppMode, "Int", 1) ; 1 = Force Standard Light Mode
                if (pFlushThemes)
                    DllCall(pFlushThemes, "Int", 0)
                    
                bDarkOff := Buffer(4, 0), NumPut("Int", 0, bDarkOff, 0)
                DllCall("dwmapi.dll\DwmSetWindowAttribute", "Ptr", A_ScriptHwnd, "UInt", 20, "Ptr", bDarkOff, "UInt", 4, "Int")
            }
        }
        
        ; 4. Pull down current mouse tracking integers for precise coordinate placement
        CoordMode "Mouse", "Screen"
        MouseGetPos &mX, &mY
        
        ; 5. Focus Mechanism: Set host script window context as active foreground master
        DllCall("user32.dll\SetForegroundWindow", "Ptr", A_ScriptHwnd)

        ;SetTimer(() => SendDownArrowToMenu(), -5000)        
        ; 6. TRACK THE POPUP: Display the native OS menu component.
        SelectedHWND := DllCall("user32.dll\TrackPopupMenu", 
            "Ptr", hMenu, 
            "UInt", 0x0182, ; TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON
            "Int", mX, 
            "Int", mY, 
            "Int", 0, 
            "Ptr", A_ScriptHwnd, 
            "Ptr", 0, 
            "UPtr")

        ;SetTimer(() => SendDownArrowToMenu(), -5000)            
        ; 7. Safe Garbage Collection: Clear out the OS menu handle immediately to free memory
        DllCall("user32.dll\DestroyMenu", "Ptr", hMenu, "Int")
        
        ; 8. Send an internal thread reset message to prevent mouse clicks from locking up
        DllCall("user32.dll\PostMessageW", "Ptr", A_ScriptHwnd, "UInt", 0, "Ptr", 0, "Ptr", 0)
        
        ; 9. If you selected an item, drop it straight into our window execution recovery loop
        if (SelectedHWND != 0) {
            RestoreRegistryWindow(SelectedHWND)
        }
        
        A_Clipboard := "SUCCESS: Menu code completed execution cycle safely."
        
    } catch Error as e {
        A_Clipboard := "CRASH DETAILS: Line [" . e.Line . "] - " . e.Message
    }
}

RestoreRegistryWindow(hWndToRestore) {
    global g_mHiddenWindowsRegistry
    
    if WinExist(hWndToRestore) {
        sHelperPath := A_ScriptDir "\TrayHelper.ahk"
        if FileExist(sHelperPath) {
            sArgs := '"delete" "' hWndToRestore '" ""'
            ComObject("Shell.Application").ShellExecute(sHelperPath, sArgs, "", "open", 1)
        }
        
        WinShow(hWndToRestore)
        WinRestore(hWndToRestore)
        WinActivate(hWndToRestore)
    }
    
    if g_mHiddenWindowsRegistry.Has(hWndToRestore) {
        g_mHiddenWindowsRegistry.Delete(hWndToRestore)
    }
}

FocusNativeMenuHandle() {
    hMenuWnd := WinExist("ahk_class #32768")
    if (hMenuWnd) {
        DllCall("user32.dll\SetForegroundWindow", "Ptr", hMenuWnd)
    }
}


; &"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\_ahk\WindowNudger.ahk"


