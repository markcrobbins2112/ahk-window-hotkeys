; #region  _hdr 
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

if not A_IsAdmin {
    Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp()
}
; #endregion

; #region _globals 
Global g_sIniFile := A_ScriptDir "\HotWinAHK.ini"
Global g_sGeneratedFile := A_ScriptDir "\HotWinAHK_aux.ahk"
Global g_SettingsSilenceAll := false
Global g_SettingsSilentOnWinCmds := false
Global g_SettingsTipWinCmds := true
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
Global g_z := 40 ; Legacy step size
Global g_zx := 106 ; Tad width (1/4 of cell width 424)
Global g_zy := 58  ; Tad height (1/4 of cell height 232)
Global g_DragTuckActive := false   ; Whether a tuck indicator is active during DragWindow
Global g_DragTuckEdge := ""        ; The edge we want to tuck to
Global g_DragTuckIndicatorGui := "" ; Translucent tuck preview GUI
Global g_SettingsDisableStartupBeep := false
Global g_SettingsDisableSuspensionBeep := false
Global g_SettingsEditorPath := "notepad.exe"
Global g_TuckedWindows := Map()  ; Format: hWnd -> {edge: "Left", x: origX, y: origY, w: origW, h: origH}
Global g_ActiveUntuckedHwnd := 0 ; Tracks currently hovered untucked window
Global g_LastActiveBeforeUntuck := 0
Global g_IsProcessingUntuck := false ; Safety latch stops recursive untuck/retuck loops
Global g_IsUntuckLocked := false ; Atomic thread lock protects layout transitions
Global g_PrevMouseX := -1
Global g_PrevMouseY := -1
Global g_UntuckCooldown := false
Global g_BaselineActiveWindow := 0 ; Tracks your primary application window handle
Global g_ResetBumpMemory := false ; Controls mouse vector memory flushes
Global g_UntuckGraceTicks := 0 ; Grace period countdown latch for untucking; #endregion
Global g_DiagnosticFocusHook := 0 ; Global focus monitoring hook handle
Global g_PeekX := 0 ; Tracks peek position X
Global g_PeekY := 0 ; Tracks peek position Y
Global g_DotGui := "" ; Early declared active window top-left indicator dot GUI hook
Global g_OsFocusHookHandle := 0
Global g_SavedHomesList := []
Global g_HomeIndicators := Map()
Global g_OverlayGui := ""
Global g_OverlayTimer := ""

Global g_TuckPeekList := []
Global g_TuckPeekIndex := 0
Global g_TuckPeekEdge := ""
Global g_TuckPeekActive := false

Global g_DragActive := false
Global g_DragHwnd := 0
Global g_DragOrigX := 0
Global g_DragOrigY := 0
Global g_DragOrigW := 0
Global g_DragOrigH := 0
Global g_DragWindowsAbove := []
Global g_DragMouseOffsetX := 0
Global g_DragMouseOffsetY := 0

Global g_NumpadMap := Map(
    "numpad0", "numpadins",
    "numpad1", "numpadend",
    "numpad2", "numpaddown",
    "numpad3", "numpadpgdn",
    "numpad4", "numpadleft",
    "numpad5", "numpadclear",
    "numpad6", "numpadright",
    "numpad7", "numpadhome",
    "numpad8", "numpadup",
    "numpad9", "numpadpgup",
    "numpaddot", "numpaddel"
)

Global g_NumpadReverseMap := Map(
    "numpadins", "numpad0",
    "numpadend", "numpad1",
    "numpaddown", "numpad2",
    "numpadpgdn", "numpad3",
    "numpadleft", "numpad4",
    "numpadclear", "numpad5",
    "numpadright", "numpad6",
    "numpadhome", "numpad7",
    "numpadup", "numpad8",
    "numpadpgup", "numpad9",
    "numpaddel", "numpaddot"
)

Global g_Desk3dActive := false
Global g_Desk3dWindows := []
Global g_DeskStartMouseX := 0
Global g_DeskStartMouseY := 0

; --- CUSTOM VELOCITY BUMP SENSITIVITY REGISTRY ---
; Lower numbers make the flick speed more sensitive (5 is ultra-sensitive, 10 is moderate, 20 is heavy wrist snap)
Global g_BumpVelocityThreshold := 5

; Sets the physical width of the monitor wall catch lane zone in pixels (20px to 30px is highly reliable)
Global g_BumpEdgeZonePixels := 30
; --- GLOBAL WINDOW EDGE INDICATOR CONFIGURATION ---
; Defines exactly how many physical pixels remain wide awake and visible on your
; screen margins when an application window slides back into its tucked dock slot.
Global g_TuckedVisiblePixels := 20
; #endregion _globals 

; #region  _startups 
; Cleanly terminate any prior crashed/dangling zombie/helper threads on startup.
; This releases their keyboard resource allocations and hooks before we register our own!
Global g_bIsSilentRestart := false
wasAlreadyRunning := false
try {
    DetectHiddenWindows(true)
    currentPID := DllCall("GetCurrentProcessId")
    existingAhkWins := WinGetList("ahk_class AutoHotkey")
    for hAhk in existingAhkWins {
        try {
            thisTitle := WinGetTitle("ahk_id " hAhk)
            thisPID := WinGetPID("ahk_id " hAhk)
            if (thisPID != currentPID && InStr(thisTitle, "HotWinAHK")) {
                wasAlreadyRunning := true
                WinClose("ahk_id " hAhk)
                Sleep(50) ; Give it a brief moment of grace to unload
                if WinExist("ahk_id " hAhk) {
                    ProcessClose(thisPID)
                }
            }
        }
    }
}

if (wasAlreadyRunning && A_Args.Length > 0) {
    g_bIsSilentRestart := true
}

SetProcessDarkMode()
LoadSettings()
SetNumLockState "AlwaysOn"
A_IconTip := "🤖 HotWinAHK"
SetTimer(CheckScreenEdgeBumps, 25)
SetTimer(UpdateActiveWindowDot, 100)
SetTimer(UpdateHomeIndicators, 250)
OnMessage(0x004A, ReceiveCopyData)
DetectHiddenWindows(true)
WinSetTitle("HotWinAHK_Main_Orchestrator_Window", "ahk_id " . g_hMainScriptHWND)
; Execute the initializer hook immediately on script launch
InitializeGlobalFocusBeeper()
if !FileExist(g_sGeneratedFile) {
    FileAppend("; Initial boot placeholder`n", g_sGeneratedFile, "UTF-8")
}

; --- THE SELF-COMPILING SCRIPT GENERATOR ENGINE ---
UpdateSavedHomesCache()
CompileIniToStaticHotkeys()
; Sound confirmation beep on successful loading
if (!g_bIsSilentRestart) {
    PlayStartupSound()
    try TrayTip("Engine Reloaded", "Window Nudger Active", 1)
}

if (A_Args.Length > 0) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &mHwnd)
    if (mHwnd) {
        mRoot := DllCall("GetAncestor", "ptr", mHwnd, "uint", 2, "ptr")
        targetHwnd := mRoot ? mRoot : mHwnd
        
        for cmd in A_Args {
            if (targetHwnd && WinExist("ahk_id " . targetHwnd)) {
                ExecuteCommandRegistry(cmd, targetHwnd)
            } else {
                ExecuteActionWithCondition(cmd, "")
            }
        }
    }
}

; Build Custom Tray Menu Layout using standard named callbacks
A_TrayMenu.Delete() ; Clear defaults
A_TrayMenu.Add("Suspend Hotkeys", Menu_ToggleSuspension)
A_TrayMenu.Add("Reload INI", Menu_ReloadIniConfig)
A_TrayMenu.Add("Edit INI", Menu_EditIniConfig)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", Menu_ExitApp)
; #endregion

; ----
; #region  _utils 
LogMessage(msg) {
    sLogPath := A_ScriptDir "\HotWinAHK.log"
    try {
        timestamp := A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec
        FileAppend("[" timestamp "] " msg "`r`n", sLogPath, "UTF-8")
    }
}
SafeHotkey(KeyString, CallbackFunction) {
    try {
        ; Clean any accidental quotes off the string
        CleanedKey := StrReplace(KeyString, '"', '')

        if (CleanedKey == "" || CleanedKey == "Not Set") {
            return
        }

        ; Attempt to natively register the hotkey with Windows
        Hotkey(CleanedKey, CallbackFunction)
    }
    catch Error as err {
        ; IF AN INVALID KEY IS FOUND: SILENTLY ZAP IT IN THE INI AND REBOOT!
        ;MsgBox(0,err.msg, "HERE")
        if (InStr(err.Message, "Invalid key name") || InStr(err.Message, "Parameter #1 invalid")) {

            ; 1. Scan through the INI file to find exactly which line contains the bad key string
            iniText := FileRead(g_sIniFile)
            cleanIniText := ""

            Loop Parse, iniText, "`n", "`r" {
                ; If this specific line contains the bad key name, skip writing it (ZAP IT)
                if (InStr(A_LoopField, KeyString)) {
                    continue
                }
                cleanIniText .= A_LoopField . "`r`n"
            }

            ; 2. Overwrite the INI file with the clean, zapped version
            FileDelete(g_sIniFile)
            FileAppend(cleanIniText, g_sIniFile)

            ; 3. Instantly reboot the script to execute cleanly with no popups
            Reload()
            ExitApp()
        }
    }
}
InitializeGlobalFocusBeeper() {
    ; 0x0003 = EVENT_SYSTEM_FOREGROUND (Natively tracks any active window change)
    hFocusCallback := CallbackCreate(AudibleFocusListenerCallback, "Fast")

    ; Register the hook directly into the Microsoft Windows OS kernel
    Global g_DiagnosticFocusHook := DllCall("SetWinEventHook"
        , "uint", 0x0003, "uint", 0x0003
        , "ptr", 0, "ptr", hFocusCallback
        , "uint", 0, "uint", 0, "uint", 0)
}
AudibleFocusListenerCallback(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    ; Silencing focus changes as requested by user
    return
}
IsEligibleForBulkCommand(hwnd, allowMinimized := false) {
    global g_TuckedWindows
    if (g_TuckedWindows.Has(hwnd)) {
        return false
    }
    
    if (!WinExist("ahk_id " . hwnd)) {
        return false
    }
    
    try {
        winClass := WinGetClass(hwnd)
        winTitle := WinGetTitle(hwnd)
        style := WinGetStyle(hwnd)
        minMaxStatus := WinGetMinMax(hwnd)
        
        if (minMaxStatus == -1) {
            if (!allowMinimized) {
                return false
            }
        } else {
            if (!(style & 0x10000000)) {
                return false
            }
        }
        
        if (InStr(winClass, "Shell_TrayWnd") || InStr(winClass, "Progman") || InStr(winClass, "WorkerW") || InStr(winTitle, "HotWinAHK") || winClass == "Windows.UI.Core.CoreWindow" || winClass == "TaskListThumbnailWnd") {
            return false
        }
        
        if (minMaxStatus != -1) {
            WinGetPos(, , &wWidth, &wHeight, hwnd)
            if (wWidth <= 100 || wHeight <= 100) {
                return false
            }
        }
    } catch {
        return false
    }
    return true
}
SetProcessDarkMode() {
    try {
        hUxtheme := DllCall("LoadLibrary", "str", "uxtheme.dll", "ptr")
        if (hUxtheme) {
            ; Ordinal 135 is SetPreferredAppMode (ForceDark = 2)
            pSetPreferredAppMode := DllCall("GetProcAddress", "ptr", hUxtheme, "ptr", 135, "ptr")
            if (pSetPreferredAppMode) {
                DllCall(pSetPreferredAppMode, "int", 2)
            }
            ; Ordinal 136 is FlushMenuThemes
            pFlushMenuThemes := DllCall("GetProcAddress", "ptr", hUxtheme, "ptr", 136, "ptr")
            if (pFlushMenuThemes) {
                DllCall(pFlushMenuThemes)
            }
        }
    } catch {
        ; ignore
    }
}
PlayStartupSound() {
    global g_SettingsSilenceAll, g_SettingsDisableStartupBeep
    if (g_bIsSilentRestart || g_SettingsSilenceAll || g_SettingsDisableStartupBeep)
        return
    ; A beautiful upbeat major triad arpeggio (A4, C#5, E5, A5)
    SoundBeep(440, 80)
    Sleep(30)
    SoundBeep(554, 80)
    Sleep(30)
    SoundBeep(659, 80)
    Sleep(30)
    SoundBeep(880, 150)
}
PlayBigCommandSound() {
    global g_SettingsSilenceAll
    if (g_SettingsSilenceAll)
        return
    ; Ascending dual-tone sweep for administrative commands
    SoundBeep(880, 80)
    Sleep(40)
    SoundBeep(1320, 120)
}
PlayToggleSuspensionSound(bSuspended) {
    global g_SettingsSilenceAll, g_SettingsDisableSuspensionBeep
    if (g_SettingsSilenceAll || g_SettingsDisableSuspensionBeep)
        return
    if (bSuspended) {
        ; Descending sad tones for suspension (deactivation)
        SoundBeep(700, 60)
        Sleep(30)
        SoundBeep(500, 100)
    } else {
        ; Ascending happy tones for activation
        SoundBeep(500, 60)
        Sleep(30)
        SoundBeep(700, 100)
    }
}
PlayTinyFeedbackSound() {
    global g_SettingsSilenceAll, g_SettingsSilentOnWinCmds
    if (g_SettingsSilenceAll || g_SettingsSilentOnWinCmds)
        return
    ; Snappy feedback click/tone
    SoundBeep(1600, 15)
}
ShowQuickTip(sCmd) {
    if (SubStr(sCmd, 1, 4) == "🤖 ") {
        sCmd := SubStr(sCmd, 5)
    }

    description := ""
    category := ""
    keybinding := ""

    for item in GetGlobalCommandList() {
        if (item.cmd = sCmd) {
            description := item.desc
            category := item.cat
            keybinding := item.key
            break
        }
    }

    if (description != "") {
        tipText := "🤖 [HotWinAction] " . sCmd . "`n"
        tipText .= "🔹 Category: " . category . "`n"
        tipText .= "📝 Desc: " . description
        if (keybinding != "" && keybinding != "Custom") {
            tipText .= "`n⌨️ Default: " . keybinding
        }
    } else {
        tipText := "🤖 Running: " . sCmd
    }

    ToolTip(tipText)
    SetTimer(() => ToolTip(), -2000)
}
SquareRoot(val) {
    return val ** 0.5
}
AnimateWinMove(targetX, targetY, hWnd) {
    ; Fetch current window coordinates
    try {
        WinGetPos(&currentX, &currentY, &W, &H, hWnd)
    } catch {
        return
    }

    ; Configure animation speed parameters
    duration := 150  ; Total target time in milliseconds
    steps := 12      ; Number of intermediate visual frames
    sleepTime := Floor(duration / steps)

    Loop steps {
        ; Easing math: calculate progress step fractions
        t := A_Index / steps
        easeStep := t * (2 - t) ; Quadratic Ease-Out formula

        ; Calculate this frame's exact intermediate coordinates
        frameX := currentX + Floor((targetX - currentX) * easeStep)
        frameY := currentY + Floor((targetY - currentY) * easeStep)

        ; Move the window to the intermediate step frame
        WinMove(frameX, frameY, , , hWnd)

        ; Force a brief pause to render the movement frame visibly
        Sleep(sleepTime)
    }

    ; Final hard clamp to ensure absolute coordinate precision
    WinMove(targetX, targetY, , , hWnd)
}
; #endregion

; #region  _ini 
ReloadIniConfig() {
    PlayBigCommandSound()
    ShowTargetToolTip("Re-Compiling Matrix...")
    CompileIniToStaticHotkeys()
}
EditIniConfig() {
    global g_sIniFile, g_SettingsEditorPath
    if !FileExist(g_sIniFile) {
        FileAppend("; Window Nudger Configuration Setup`n", g_sIniFile)
    }

    try {
        Run('"' g_SettingsEditorPath '" "' g_sIniFile '"')
    } catch {
        DllCall("shell32\ShellExecuteW",
            "ptr", 0,
            "str", "open",
            "str", g_sIniFile,
            "str", "",
            "str", "",
            "int", 1) ; 1 = SW_SHOWNORMAL
    }
}
GetSectionKeys(sectionName) {
    try {
        ; Access your top-level global ini location variable safely
        global g_sIniFile
        secText := IniRead(g_sIniFile, sectionName)
        compiledKeys := ""

        Loop Parse, secText, "`n", "`r" {
            if (RegExMatch(A_LoopField, "i)^[^=]+=\s*([^;]+)", &Match)) {
                cleanKey := Trim(Match[1])
                if (cleanKey != "") {
                    if (compiledKeys == "") {
                        compiledKeys := cleanKey
                    } else {
                        compiledKeys .= " | " . cleanKey
                    }
                }
            }
        }
        if (compiledKeys != "") {
            return " " . compiledKeys . " "
        }
    }
    return "Not Set"
}
; #endregion

; #region  _keys 
IsValidAhkKey(keyString) {
    ; Clean any quotes off the key string
    cleanKey := StrReplace(keyString, '"', '')
    if (cleanKey == "" || cleanKey == "Not Set") {
        return false
    }

    ; Remove all standard modifiers to isolate the core button name
    pureKey := RegExReplace(cleanKey, "i)[#\^\!\+\~\*\<\>]", "")

    ; Fast check: Is it a single standard character or single number?
    if (StrLen(pureKey) == 1) {
        return true
    }

    ; Master list of allowed AHK multi-character key names
    static validKeys := Map(
        "lbutton", 1, "rbutton", 1, "mbutton", 1, "xbutton1", 1, "xbutton2", 1,
        "wheelup", 1, "wheeldown", 1, "wheelleft", 1, "wheelright", 1,
        "numpad0", 1, "numpad1", 1, "numpad2", 1, "numpad3", 1, "numpad4", 1,
        "numpad5", 1, "numpad6", 1, "numpad7", 1, "numpad8", 1, "numpad9", 1,
        "numpaddot", 1, "numpaddiv", 1, "numpadmult", 1, "numpadadd", 1, "numpadsub", 1,
        "numpadenter", 1, "numpadins", 1, "numpadend", 1, "numpaddown", 1, "numpadpgdn", 1,
        "numpadleft", 1, "numpadclear", 1, "numpadright", 1, "numpadhome", 1, "numpadup", 1,
        "numpadpgup", 1, "numpaddel", 1,
        "f1", 1, "f2", 1, "f3", 1, "f4", 1, "f5", 1, "f6", 1, "f7", 1, "f8", 1, "f9", 1, "f10", 1,
        "f11", 1, "f12", 1, "f13", 1, "f14", 1, "f15", 1, "f16", 1, "f17", 1, "f18", 1, "f19", 1,
        "f20", 1, "f21", 1, "f22", 1, "f23", 1, "f24", 1,
        "space", 1, "tab", 1, "enter", 1, "escape", 1, "esc", 1, "backspace", 1, "bs", 1,
        "delete", 1, "del", 1, "insert", 1, "ins", 1, "home", 1, "end", 1,
        "pgup", 1, "pgdn", 1, "up", 1, "down", 1, "left", 1, "right", 1,
        "scrolllock", 1, "capslock", 1, "numlock", 1,
        "printscreen", 1, "prtsc", 1, "ctrlbreak", 1, "pause", 1, "break", 1,
        "lcontrol", 1, "lctrl", 1, "rcontrol", 1, "rctrl", 1,
        "lshift", 1, "rshift", 1, "lalt", 1, "ralt", 1, "lwin", 1, "rwin", 1,
        "appskey", 1, "sleep", 1
    )

    return validKeys.Has(Format("{:L}", pureKey))
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
GetNumpadCounterpart(keyName) {
    global g_NumpadMap, g_NumpadReverseMap
    kL := StrLower(keyName)
    if (g_NumpadMap.Has(kL)) {
        return g_NumpadMap[kL]
    }
    if (g_NumpadReverseMap.Has(kL)) {
        return g_NumpadReverseMap[kL]
    }
    return ""
}
NormalizeHotKeyToNumpad9Display(strokeString) {
    global g_NumpadReverseMap
    lowerStroke := StrLower(strokeString)
    outStr := strokeString
    for navKey, numKey in g_NumpadReverseMap {
        pos := InStr(lowerStroke, navKey)
        if (pos > 0) {
            origKey := SubStr(outStr, pos, StrLen(navKey))
            isAllUpper := (Format("{:U}", origKey) == origKey)
            isAllLower := (Format("{:L}", origKey) == origKey)
            isTitle := (SubStr(origKey, 1, 1) == "N" && SubStr(origKey, 7, 1) == "P")
            
            targetNumKey := numKey
            if (isAllUpper) {
                targetNumKey := Format("{:U}", targetNumKey)
            } else if (isTitle || !isAllLower) {
                targetNumKey := "Numpad" . SubStr(targetNumKey, 7)
            }
            
            outStr := SubStr(outStr, 1, pos - 1) . targetNumKey . SubStr(outStr, pos + StrLen(navKey))
            lowerStroke := StrLower(outStr)
        }
    }
    return outStr
}
EnsureAllCommandsInIni() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        return
    }
    
    sc := ";"
    iniText := FileRead(g_sIniFile)
    
    ; Map of lowercase command name -> { orig: "[SectionName]", keys: "keys1=...\r\n" }
    sectionsMap := Map()
    
    currSectionMain := ""
    currSectionRaw := ""
    currSectionKeys := ""
    headerComments := ""
    hasHitSection := false
    
    Loop Parse, iniText, "`n", "`r" {
        line := Trim(A_LoopField)
        if (InStr(line, "#region") || InStr(line, "#endregion")) {
            continue
        }
        if (RegExMatch(line, "^\[([^\]]+)\](?:\s*;.*)?$", &match)) {
            hasHitSection := true
            if (currSectionMain != "") {
                sectionsMap[StrLower(currSectionMain)] := { orig: currSectionRaw, keys: currSectionKeys }
            }
            currSectionRaw := "[" . match[1] . "]"
            currSecName := match[1]
            if (SubStr(currSecName, 1, 1) == "-") {
                currSecName := SubStr(currSecName, 2)
            }
            currSectionMain := Trim(currSecName)
            currSectionKeys := ""
        } else {
            if (!hasHitSection) {
                headerComments .= A_LoopField . "`r`n"
            } else {
                if (currSectionMain != "") {
                    currSectionKeys .= A_LoopField . "`r`n"
                }
            }
        }
    }
    if (currSectionMain != "") {
        sectionsMap[StrLower(currSectionMain)] := { orig: currSectionRaw, keys: currSectionKeys }
    }
    
    ; If the top headerComments are empty, provide a clean default header
    if (Trim(headerComments, "`r`n`t ") == "" || InStr(headerComments, "WINDOW NUDGER")) {
        headerComments := "; =======================================================================================`r`n"
        headerComments .= ";                        WINDOW NUDGER CONFIGURATION MATRIX`r`n"
        headerComments .= "; =======================================================================================`r`n"
        headerComments .= "; SYNTAX: [CommandName] (Active) or [-CommandName] (Disabled)`r`n"
        headerComments .= "; keys1=Combo|Filter  (Optional filter like wintitleis=Chrome)`r`n"
    } else {
        cleanedHeader := ""
        Loop Parse, headerComments, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line != "") {
                cleanedHeader .= line . "`r`n"
            }
        }
        headerComments := cleanedHeader
    }
    iniStructure := [
        {
            cat: "SYSTEM",
            name: "System",
            desc: "Administrative utilities, telemetry dashboards, configuration hot-reloading, and debug tools.",
            subs: [
                { name: "Utilities", desc: "Diagnostic overlay displays, command palettes, and custom context menus.", cmds: ["HelpScreen", "CmdPalette", "WinInfo", "PeekUnderMouse", "SysMenu"] },
                { name: "Clipboard", desc: "Fast extraction of system shortcuts, active layout bounds, and command help definitions.", cmds: ["CopyCommands", "CopyBindings", "CopyCommandsHelp", "CopyCommandsAlpha", "CopyBindingsAlpha", "CopyBindingsLocation"] },
                { name: "Engine", desc: "Processes controlling suspension toggles, configuration updates, and preference properties.", cmds: ["ToggleSuspension", "ReloadConfig", "EditConfig", "ExitProgram", "RestartProgram", "KeyDiagnostics", "KeyQuery", "Settings"] }
            ]
        },
        {
            cat: "WINDOW",
            name: "Window",
            desc: "Coordinate placement, boundary states, attribute overrides, and bulk actions on application windows.",
            subs: [
                { name: "Attributes", desc: "Attributes including level toggles, frame transparency values, and layout stacking.", cmds: ["AlwaysOnTop", "SetOpacity70", "RemoveOpacity", "SendToBack"] },
                { name: "Tray", desc: "State stowing and recovery interfaces driving custom system notification tasks.", cmds: ["MinimizeToTray", "PickFromTray"] },
                { name: "Interactive", desc: "Direct user-interactive bounds manipulation features.", cmds: ["DragWindow"] },
                { name: "Bulk", desc: "Symmetrical state actions applied across multiple target window containers simultaneously.", cmds: ["RestoreAll", "RestoreAllMinimized", "MaximizeAll", "RestoreAllMaximized", "MaximizeAllRestored", "MaximizeAllMinimized", "SwapMaximizedRestored", "SwapMinimizedRestored", "MinimizeAll", "MinimizeAllRestored", "MinimizeAllMaximized"] }
            ]
        },
        {
            cat: "HOME",
            name: "Home",
            desc: "Target locking, layout footprints, and remote window alignment restorations.",
            subs: [
                { name: "Targeting", desc: "Coord tracking and snapping windows to configured reference layouts.", cmds: ["SetHome", "ClearHome", "GoHome", "Home", "HomePeek"] }
            ]
        },
        {
            cat: "FOCUS",
            name: "Focus",
            desc: "Z-order stack traversal, fuzzy search pickers, layout history steps, and volumetric spaces.",
            subs: [
                { name: "Cycling", desc: "Moving layout focus sequentially across open application processes.", cmds: ["NextWindow", "PrevWindow", "NextClassWindow", "PrevClassWindow"] },
                { name: "Advanced", desc: "Fuzzy title filters, depth layers, and history layout state controllers.", cmds: ["FocusDeepestWindow", "WindowPicker", "Desk3d", "WindowHistoryPrev", "WindowHistoryNext", "WindowHistoryPick"] }
            ]
        },
        {
            cat: "MOVE",
            name: "Move",
            desc: "Precision coordinate moves, physical alignment snaps, partition shifts, and layout swaps.",
            subs: [
                { name: "Precision", desc: "Moves windows by small offsets (10px, 1px) or aligns centers.", cmds: ["Center", "MoveTadLeft", "MoveTadRight", "MoveTadUp", "MoveTadDown", "MovepxLeft", "MovepxRight", "MovepxUp", "MovepxDown"] },
                { name: "Align", desc: "Snaps windows directly along physical monitor bounds or grid sectors.", cmds: ["EdgeLeft", "EdgeRight", "EdgeTop", "EdgeBottom", "EdgeTopLeft", "EdgeTopRight", "EdgeBottomLeft", "EdgeBottomRight", "EdgeCenter", "EdgeInLeft", "EdgeInRight", "EdgeInTop", "EdgeInBottom", "EdgeInTopLeft", "EdgeInTopRight", "EdgeInBottomLeft", "EdgeInBottomRight"] },
                { name: "MoveToGrid", desc: "Slices monitor monitors into fractions and centers windows on selected parts.", cmds: ["MoveToGridLeft", "MoveToGridRight", "MoveToGridUp", "MoveToGridDown", "MoveToGridTopLeft", "MoveToGridTopRight", "MoveToGridBottomLeft", "MoveToGridBottomRight"] },
                { name: "JumpGrid", desc: "Shifts windows along layout partitions relative to current cells.", cmds: ["JumpGridLeft", "JumpGridRight", "JumpGridUp", "JumpGridDown", "JumpGridTopLeft", "JumpGridTopRight", "JumpGridBottomLeft", "JumpGridBottomRight"] },
                { name: "Interactive", desc: "Boundary exchange swaps, hover-relative selections, and menu grid placement.", cmds: ["Swap", "SwapSize", "SwapPosition", "SwapPick", "SwapPickSize", "SwapPickPosition", "Gridify"] }
            ]
        },
        {
            cat: "SIZE",
            name: "Size",
            desc: "Ratios adjustments, frame trimming, border additions, grid snaps, and grid stretches.",
            subs: [
                { name: "GridBinding", desc: "Direct mouse sizing, padding overrides, and scale factors.", cmds: ["MouseToGrid", "MouseRelativeSize", "SnapToGridEnlarge", "SnapToGridShrink", "ScaleExpand10px", "ScaleReduce10px", "ScaleExpandGridPart", "ScaleReduceGridPart"] },
                { name: "Trim", desc: "Symmetry border trims matching target grid proportions.", cmds: ["TrimTop", "TrimBottom", "TrimLeft", "TrimRight", "TrimAll", "TrimTopLeft", "TrimTopRight", "TrimBottomLeft", "TrimBottomRight"] },
                { name: "Grow", desc: "Symmetry border expansions enlarging target sizes.", cmds: ["AddTop", "AddBottom", "AddLeft", "AddRight", "AddTopLeft", "AddTopRight", "AddBottomLeft", "AddBottomRight", "AddAll", "GrowLeft", "GrowRight", "GrowTop", "GrowBottom", "GrowAll", "GrowTopLeft", "GrowTopRight", "GrowBottomLeft", "GrowBottomRight"] },
                { name: "Shrink", desc: "Symmetry border contractions shrinking target dimensions.", cmds: ["SubtractTop", "SubtractBottom", "SubtractLeft", "SubtractRight", "SubtractTopLeft", "SubtractTopRight", "SubtractBottomLeft", "SubtractBottomRight", "SubtractAll"] },
                { name: "HalfDouble", desc: "Fast dimension updates scaling window size by 0.5x or 2.0x.", cmds: ["HalfSizeLeft", "HalfSizeRight", "HalfSizeTop", "HalfSizeBottom", "DoubleSizeLeft", "DoubleSizeRight", "DoubleSizeTop", "DoubleSizeBottom"] },
                { name: "StretchGrid", desc: "Stretches target borders onto custom screen segments.", cmds: ["StretchToGridLeft", "StretchToGridRight", "StretchToGridUp", "StretchToGridDown", "StretchToGridTopLeft", "StretchToGridTopRight", "StretchToGridBottomLeft", "StretchToGridBottomRight", "StretchToGridAll"] },
                { name: "PullGrid", desc: "Pulls target margins onto predicted grid lines.", cmds: ["PullToGridLeft", "PullToGridRight", "PullToGridUp", "PullToGridDown", "PullToGridTopLeft", "PullToGridTopRight", "PullToGridBottomLeft", "PullToGridBottomRight", "PullToGridAll"] },
                { name: "StretchScreenEdge", desc: "Expands window borders outward onto screen limits.", cmds: ["StretchLeft", "StretchRight", "StretchTop", "StretchBottom", "StretchTopLeft", "StretchTopRight", "StretchBottomLeft", "StretchBottomRight", "StretchAll"] }
            ]
        },
        {
            cat: "TUCK",
            name: "Tuck",
            desc: "Marginal docking, off-screen hiding, tactile peek actions, and pop-up picker menus.",
            subs: [
                { name: "Actions", desc: "Folds containers under screen edges keeping small peek boundaries visible.", cmds: ["TuckLeft", "TuckRight", "TuckUp", "TuckDown", "BumpEdgeUntuck", "BumpEdgeUntuckActivate", "PeekTucked", "Untuck", "UntuckLeft", "UntuckRight", "UntuckTop", "UntuckBottom", "TuckPeekLeft", "TuckPeekRight", "TuckPeekTop", "TuckPeekBottom", "TuckPeekAll", "TuckedPeekLeft", "TuckedPeekRight", "TuckedPeekTop", "TuckedPeekBottom"] }
            ]
        }
    ]
    localRows := GetGlobalCommandList()
    curatedSet := Map()
    for outerCat in iniStructure {
        for subCat in outerCat.subs {
            for cmdName in subCat.cmds {
                curatedSet[StrLower(cmdName)] := true
            }
        }
    }
    for row in localRows {
        if (InStr(row.cmd, " ")) {
            continue
        }
        cmdLower := StrLower(row.cmd)
        if (!curatedSet.Has(cmdLower)) {
            for outerCat in iniStructure {
                if (outerCat.cat == row.cat) {
                    if (outerCat.subs.Length > 0) {
                        outerCat.subs[outerCat.subs.Length].cmds.Push(row.cmd)
                    } else {
                        outerCat.subs.Push({ name: "Other", desc: "Uncategorized preferences and custom actions.", cmds: [row.cmd] })
                    }
                    curatedSet[cmdLower] := true
                    break
                }
            }
        }
    }
    writtenCommands := Map()
    newIniText := headerComments
    for outerCat in iniStructure {
        newIniText .= sc . "   #region " . outerCat.name . "`r`n"
        if (outerCat.HasOwnProp("desc")) {
            newIniText .= "    " . sc . " " . outerCat.desc . "`r`n"
        }
        for subCat in outerCat.subs {
            newIniText .= "    " . sc . "   #region " . subCat.name . "`r`n"
            if (subCat.HasOwnProp("desc")) {
                newIniText .= "        " . sc . " " . subCat.desc . "`r`n"
            }
            for cmdName in subCat.cmds {
                cleanCmd := StrLower(cmdName)
                if (writtenCommands.Has(cleanCmd)) {
                    continue
                }
                writtenCommands[cleanCmd] := true
                
                ; Look up original built-in pattern details
                rowDesc := ""
                rowKey := ""
                for row in localRows {
                    if (StrLower(row.cmd) == cleanCmd) {
                        rowDesc := row.desc
                        rowKey := row.key
                        break
                    }
                }
                
                if (sectionsMap.Has(cleanCmd)) {
                    secData := sectionsMap[cleanCmd]
                    sectionsMap.Delete(cleanCmd)
                    
                    ; Canonicalize section header (e.g. [HelpScreen] or [-HelpScreen])
                    sectionHeader := secData.orig
                    if (RegExMatch(sectionHeader, "^\[([^\]]+)\]", &mHead)) {
                        sectionHeader := "[" . mHead[1] . "]"
                    }
                    
                    commentPart := (rowDesc != "") ? (" " . sc . " " . rowDesc) : ""
                    newIniText .= "        " . sectionHeader . commentPart . "`r`n"
                    
                    Loop Parse, secData.keys, "`n", "`r" {
                        line := Trim(A_LoopField)
                        ; Exclude comment lines and blank lines to avoid duplication/clutter within keys block
                        if (line == "" || SubStr(line, 1, 1) == sc) {
                            continue
                        }
                        newIniText .= "            " . line . "`r`n"
                    }
                } else {
                    commentPart := (rowDesc != "") ? (" " . sc . " " . rowDesc) : ""
                    newIniText .= "        [-" . cmdName . "]" . commentPart . "`r`n"
                    
                    defaultBinding := rowKey
                    if (defaultBinding == "Custom" || defaultBinding == "Edge Bump" || defaultBinding == "Edge Click/Drag" || defaultBinding == "Auto Indicator") {
                        defaultBinding := ""
                    }
                    newIniText .= "            " . sc . "keys1=" . defaultBinding . "`r`n"
                }
            }
            newIniText .= "    " . sc . " #endregion " . subCat.name . "`r`n"
        }
        newIniText .= sc . " #endregion " . outerCat.name . "`r`n"
    }
    if (sectionsMap.Count > 0) {
        newIniText .= sc . "   #region Preferences`r`n"
        newIniText .= "    " . sc . " User preferences, custom defaults, and localized setup settings.`r`n"
        newIniText .= "    " . sc . "   #region Settings`r`n"
        for key, value in sectionsMap {
            newIniText .= "        " . value.orig . "`r`n"
            Loop Parse, value.keys, "`n", "`r" {
                line := Trim(A_LoopField)
                if (line == "") {
                    continue
                }
                newIniText .= "            " . line . "`r`n"
            }
        }
        newIniText .= "    " . sc . " #endregion Settings`r`n"
        newIniText .= sc . " #endregion Preferences`r`n"
    }
    if (Trim(newIniText) != Trim(iniText)) {
        FileDelete(g_sIniFile)
        FileAppend(newIniText, g_sIniFile, "UTF-8")
    }
}
CompileIniToStaticHotkeys() {
    global g_sIniFile, g_sGeneratedFile

    EnsureAllCommandsInIni()

    if !FileExist(g_sIniFile) {
        return
    }

    ; ===================================================================================
    ; INTERNAL HOTKEY STRUCTURAL VALIDATION ENGINE
    ; ===================================================================================
    IsValidAhkKey(keyString) {
        cleanKey := StrReplace(keyString, '"', '')
        if (cleanKey == "" || cleanKey == "Not Set") {
            return false
        }

        ; Clean out ALL hotkey modifier and hook flags: # ! ^ + < > * ~ $ &
        pureKey := RegExReplace(cleanKey, "i)[#\^\!\+\~\*\<\>\$\&]", "")

        ; If it isolates down to a single standard character or single number, it is valid
        if (StrLen(pureKey) == 1) {
            return true
        }

        ; Master list of allowed AHK multi-character key and mouse button names
        static validKeys := Map(
            "lbutton", 1, "rbutton", 1, "mbutton", 1, "xbutton1", 1, "xbutton2", 1,
            "wheelup", 1, "wheeldown", 1, "wheelleft", 1, "wheelright", 1,
            "numpad0", 1, "numpad1", 1, "numpad2", 1, "numpad3", 1, "numpad4", 1,
            "numpad5", 1, "numpad6", 1, "numpad7", 1, "numpad8", 1,"numpad9", 1,
            "numpaddot", 1, "numpaddiv", 1, "numpadmult", 1, "numpadadd", 1, "numpadsub", 1,
            "numpadenter", 1, "numpadins", 1, "numpadend", 1, "numpaddown", 1, "numpadpgdn", 1,
            "numpadleft", 1, "numpadclear", 1, "numpadright", 1, "numpadhome", 1, "numpadup", 1,
            "numpadpgup", 1, "numpaddel", 1,
            "f1", 1, "f2", 1, "f3", 1, "f4", 1, "f5", 1, "f6", 1, "f7", 1, "f8", 1, "f9", 1, "f10", 1,
            "f11", 1, "f12", 1, "f13", 1, "f14", 1, "f15", 1, "f16", 1, "f17", 1, "f18", 1, "f19", 1,
            "f20", 1, "f21", 1, "f22", 1, "f23", 1, "f24", 1,
            "space", 1, "tab", 1, "enter", 1, "escape", 1, "esc", 1, "backspace", 1, "bs", 1,
            "delete", 1, "del", 1, "insert", 1, "ins", 1, "home", 1, "end", 1,
            "pgup", 1, "pgdn", 1, "up", 1, "down", 1, "left", 1, "right", 1,
            "scrolllock", 1, "capslock", 1, "numlock", 1,
            "printscreen", 1, "prtsc", 1, "ctrlbreak", 1, "pause", 1, "break", 1,
            "lcontrol", 1, "lctrl", 1, "rcontrol", 1, "rctrl", 1,
            "lshift", 1, "rshift", 1, "lalt", 1, "ralt", 1, "lwin", 1, "rwin", 1,
            "appskey", 1, "sleep", 1
        )

        return validKeys.Has(Format("{:L}", pureKey))
    }

    ; Initialize the text buffer for the generated file
    ScriptBuffer := "; =======================================================================================`n"
    ScriptBuffer .= ";          AUTOMATICALLY GENERATED NATIVE SHELL HOTKEYS - DO NOT EDIT DIRECTLY`n"
    ScriptBuffer .= "; =======================================================================================`n#Requires AutoHotkey v2.0`n`n"

    ; Create a flat text registry to track uniquely written combinations
    WrittenKeysRegistry := ""

    ; Read all command section names from the INI configuration file
    SectionsText := IniRead(g_sIniFile)
    loop parse, SectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") {
            continue
        }

        ; Scan for up to 10 fallback variant hotkey definitions per command
        loop 10 {
            currentKeyProp := "keys" A_Index
            KeyValue := IniRead(g_sIniFile, sCmd, currentKeyProp, "")
            if (KeyValue == "") {
                break
            }

            ; FIXED: Restored explicit 1-indexed AHK v2 array bracket tracking syntax
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
            if (sAHKStroke == "") {
                continue
            }

            ; ===========================================================================
            ; INTERCEPT COMPILER INVALID HOTKEY TYPOS (e.g., mousebump_left)
            ; ===========================================================================
            if (!IsValidAhkKey(sAHKStroke)) {
                ; Read the current INI data out of memory
                iniText := FileRead(g_sIniFile)
                cleanIniText := ""

                Loop Parse, iniText, "`n", "`r" {
                    ; Locate the specific line within the section containing the error typo and zap it!
                    if (InStr(A_LoopField, KeyValue) && InStr(A_LoopField, currentKeyProp)) {
                        continue
                    }
                    cleanIniText .= A_LoopField . "`r`n"
                }

                ; Overwrite the file with the sanitized configuration
                FileDelete(g_sIniFile)
                FileAppend(cleanIniText, g_sIniFile, "UTF-8")

                ; Skip appending this invalid definition to the .ahk file entirely
                continue
            }

            ; EXCELLENT: Automatically handle dual registration for Numpad Keys (Numpad9 <-> NumpadPgUp etc)
            pureKey := RegExReplace(sAHKStroke, "i)[#\^\!\+\~\*\<\>\$\&]", "")
            prefix := SubStr(sAHKStroke, 1, StrLen(sAHKStroke) - StrLen(pureKey))
            counterpart := GetNumpadCounterpart(pureKey)

            ; 1. Record and compile primary stroke
            if !InStr(WrittenKeysRegistry, "|" sAHKStroke "|") {
                WrittenKeysRegistry .= "|" sAHKStroke "|"
                
                sPrefix := "$"
                if (InStr(sAHKStroke, "$") || InStr(sAHKStroke, "~") || InStr(sAHKStroke, "*") || RegExMatch(sAHKStroke, "i)(lbutton|rbutton|mbutton|xbutton|wheel)")) {
                    sPrefix := ""
                }
                ScriptBuffer .= sPrefix sAHKStroke ":: {`n"
                if (sCmd == "ToggleSuspension" || sCmd == "ExitProgram" || sCmd == "RestartProgram" || sCmd == "ReloadConfig" || sCmd == "EditConfig" || sCmd == "HelpScreen" || sCmd == "WinInfo" || sCmd == "CopyCommands" || sCmd == "CopyBindings" || sCmd == "CopyCommandsHelp" || sCmd == "CopyCommandsAlpha" || sCmd == "CopyBindingsAlpha" || sCmd == "CopyBindingsLocation" || sCmd == "SysMenu" || InStr(sCmd, "TuckedPeek") || sCmd == "Untuck" || sCmd == "CmdPalette" || sCmd == "KeyDiagnostics" || sCmd == "KeyQuery" || sCmd == "Settings" || sCmd == "WindowPicker" || sCmd == "Desk3d" || InStr(sCmd, "WindowHistory") || InStr(sCmd, "Swap") || sCmd == "Gridify") {
                    ScriptBuffer .= '    try Suspend("Permit")`n'
                }
                ScriptBuffer .= '    ExecuteActionWithCondition("' sCmd '", "' sCond '")`n'
                ScriptBuffer .= "}`n`n"
            }

            ; 2. Record and compile counterpart stroke
            if (counterpart != "") {
                counterpartStroke := prefix . counterpart
                if !InStr(WrittenKeysRegistry, "|" counterpartStroke "|") {
                    WrittenKeysRegistry .= "|" counterpartStroke "|"
                    
                    sPrefix := "$"
                    if (InStr(counterpartStroke, "$") || InStr(counterpartStroke, "~") || InStr(counterpartStroke, "*") || RegExMatch(counterpartStroke, "i)(lbutton|rbutton|mbutton|xbutton|wheel)")) {
                        sPrefix := ""
                    }
                    ScriptBuffer .= sPrefix counterpartStroke ":: {`n"
                    if (sCmd == "ToggleSuspension" || sCmd == "ExitProgram" || sCmd == "RestartProgram" || sCmd == "ReloadConfig" || sCmd == "EditConfig" || sCmd == "HelpScreen" || sCmd == "WinInfo" || sCmd == "CopyCommands" || sCmd == "CopyBindings" || sCmd == "CopyCommandsHelp" || sCmd == "CopyCommandsAlpha" || sCmd == "CopyBindingsAlpha" || sCmd == "CopyBindingsLocation" || sCmd == "SysMenu" || InStr(sCmd, "TuckedPeek") || sCmd == "Untuck" || sCmd == "CmdPalette" || sCmd == "KeyDiagnostics" || sCmd == "KeyQuery" || sCmd == "Settings" || sCmd == "WindowPicker" || sCmd == "Desk3d" || InStr(sCmd, "WindowHistory") || InStr(sCmd, "Swap") || sCmd == "Gridify") {
                        ScriptBuffer .= '    try Suspend("Permit")`n'
                    }
                    ScriptBuffer .= '    ExecuteActionWithCondition("' sCmd '", "' sCond '")`n'
                    ScriptBuffer .= "}`n`n"
                }
            }
        }
    }

    ; Read existing file text to verify if any modifications actually happened
    ExistingText := FileExist(g_sGeneratedFile) ? FileRead(g_sGeneratedFile) : ""

    ; Standardize formatting for exact structural text comparison
    if (Trim(ScriptBuffer) != Trim(ExistingText)) {
        if FileExist(g_sGeneratedFile) {
            FileDelete(g_sGeneratedFile)
        }

        FileAppend(ScriptBuffer, g_sGeneratedFile, "UTF-8")
        Sleep(50) ; Hardened write delay ensures Windows registers file I/O operations

        ; If the engine is already initialized, reload immediately to apply shortcuts
        if (ExistingText != "") {
            Reload()
            ExitApp()
        }
    }
}
LoadHotkeysAtRuntime() {
    global g_sGeneratedFile

    if !FileExist(g_sGeneratedFile) {
        return
    }

    ; Read the flat hotkey database file from disk
    fileData := FileRead(g_sGeneratedFile)

    Loop Parse, fileData, "`n", "`r" {
        if (Trim(A_LoopField) == "") {
            continue
        }

        ; Extract variables from our tab-separated data line
        dataFields := StrSplit(A_LoopField, "`t")
        sAHKStroke := dataFields[1]
        sCmd := dataFields[2]
        sCond := dataFields[3]

        ; --- CRITICAL CORRECTION LAYER ---
        ; AutoHotkey v2 Hotkey() function requires normalized modifier symbols.
        ; This ensures compound combinations like !#s or #f12 translate to valid syntax.
        cleanStroke := sAHKStroke

        ; Standardize casing to make parsing reliable
        cleanStroke := Format("{:L}", cleanStroke)

        try {
            ; Dynamic Runtime Binding: AutoHotkey registers the string safely
            Hotkey(cleanStroke, (*) => ExecuteActionWithCondition(sCmd, sCond))
        }
        catch Error as err {
            ; Silent catch container handles illegal entries gracefully
            continue
        }
    }
}
; #endregion
; ----
; #region  _engine 
IsMetaCommand(sCmd) {
    ; Add your untuck commands to the meta-command bypass list
    if (InStr(sCmd, "BumpEdgeUntuck") || InStr(sCmd, "HelpScreen") || InStr(sCmd, "ReloadConfig") || InStr(sCmd, "CopyCommands") || InStr(sCmd, "CopyBindings") || InStr(sCmd, "CopyCommandsHelp") || InStr(sCmd, "CopyCommandsAlpha") || InStr(sCmd, "CopyBindingsAlpha") || InStr(sCmd, "CopyBindingsLocation") || InStr(sCmd, "SysMenu") || InStr(sCmd, "TuckedPeek") || InStr(sCmd, "Untuck") || InStr(sCmd, "CmdPalette") || InStr(sCmd, "KeyDiagnostics") || sCmd == "KeyQuery" || sCmd == "Settings" || sCmd == "RestoreAll" || sCmd == "RestoreAllMinimized" || sCmd == "MaximizeAll" || sCmd == "RestoreAllMaximized" || sCmd == "MaximizeAllRestored" || sCmd == "MaximizeAllMinimized" || sCmd == "SwapMaximizedRestored" || sCmd == "SwapMinimizedRestored" || sCmd == "MinimizeAll" || sCmd == "MinimizeAllRestored" || sCmd == "MinimizeAllMaximized" || sCmd == "WindowPicker" || sCmd == "Desk3d" || InStr(sCmd, "WindowHistory") || InStr(sCmd, "Swap") || sCmd == "Gridify") {
        return true
    }

    ; ... keep whatever other meta-commands you already have here ...
    return false
}
ExecuteActionWithCondition(sCmd, sCond) {
    global g_SettingsTipWinCmds
    if IsMetaCommand(sCmd) {
        ExecuteCommandRegistry(sCmd, 0)
        return
    }

    if g_bSuspended
        return

    ; Play a snappy retro click tone and show an elegant cursor tooltip
    PlayTinyFeedbackSound()
    if (g_SettingsTipWinCmds) {
        ShowQuickTip(sCmd)
    }

    hWndTarget := InStr(sCmd, "UnderMouse") ? MouseGetWindowHWND() : DllCall("user32\GetForegroundWindow", "ptr")

    if (hWndTarget) {
        LogMessage("-- title " . WinGetTitle(hWndTarget) . WinGetClass(hWndTarget))
    }

    ; Bypass the tooltip check safely to avoid grabbing our own popup bubbles
    if (hWndTarget && WinGetClass(hWndTarget) == "tooltips_class32") {
        hWndTarget := WinExist("A")
    }

    if (!hWndTarget) {
        LogMessage("No HWND")
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
ExecuteCommandRegistry(sCmd, hWnd) {
    ; HARDENED SCOPE FIX: You MUST declare global access inside the first line of the function.
    ; This explicitly pulls your top-level trackers down into the function context.
    ;global g_hOpacityActiveHWND, g_ResetCallback
    ; HARDENED SCOPE FIX: Explicitly pull your untuck and tracking variables down into the function context
    ; global g_hOpacityActiveHWND, g_ResetCallback, g_ActiveUntuckedHwnd, g_IsUntuckLocked
    global g_hOpacityActiveHWND, g_ResetCallback, g_ActiveUntuckedHwnd, g_TuckedWindows, g_BaselineActiveWindow, g_UntuckGraceTicks, g_PeekX, g_PeekY
    ;global g_ResetCallback, g_ActiveUntuckedHwnd, g_IsUntuckLocked

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
        case "CopyCommands": CopyCommands()
        case "CopyBindings": CopyBindings()
        case "CopyCommandsHelp": CopyCommandsHelp()
        case "CopyCommandsAlpha": CopyCommandsAlpha()
        case "CopyBindingsAlpha": CopyBindingsAlpha()
        case "CopyBindingsLocation": CopyBindingsLocation()
        case "KeyDiagnostics": StartKeyDiagnostics()
        case "KeyQuery": StartKeyQuery()
        case "Settings": StartSettingsDialog()
        case "SysMenu": SysMenu()
    }

    ; --- DYNAMIC POSITION PIXEL SHIFT MOVEMENT MATRIX ---
    ; --- DYNAMIC POSITION PIXEL SHIFT MOVEMENT MATRIX (INSTANT WARP) ---
    if RegExMatch(sCmd, "i)^(MoveTad|Movepx)") {
        ; 1. Determine base step parameters for horizontal and vertical axes
        if InStr(sCmd, "MoveTad") {
            stepX := g_zx
            stepY := g_zy
        } else {
            stepX := 10
            stepY := 5
        }

        ; 2. Corrected Independent Axis Evaluation (Enables flawless compound diagonal tracking)
        dX := 0
        if (InStr(sCmd, "Left")) {
            dX := -stepX
        } else if (InStr(sCmd, "Right")) {
            dX := stepX
        }

        dY := 0
        if (InStr(sCmd, "Up")) {
            dY := -stepY
        } else if (InStr(sCmd, "Down")) {
            dY := stepY
        }

        ; 3. Execute instant target warp with no animation latency
        SafeMove(X + dX, Y + dY, , , hWnd)
        return
    }

    ;LogMessage(sCmd)
    switch sCmd, false {
        case "HelpScreen":
            ShowHelpScreen(hWnd)

        case "CmdPalette":
            ShowCmdPalette(hWnd)

        case "TuckPeekAll":
            Menu_TuckedPeek()

        case "TuckedPeekLeft":
            Menu_TuckedPeek("Left")

        case "TuckedPeekRight":
            Menu_TuckedPeek("Right")

        case "TuckedPeekTop", "TuckedPeekUp":
            Menu_TuckedPeek("Up")

        case "TuckedPeekBottom", "TuckedPeekDown":
            Menu_TuckedPeek("Down")

        case "Untuck":
            Menu_Untuck()

        case "WindowPicker":
            ShowWindowPicker()

        case "Desk3d":
            StartDesk3D()

        case "WindowHistoryPrev":
            GotoHistoryPosition(hWnd, -1)

        case "WindowHistoryNext":
            GotoHistoryPosition(hWnd, 1)

        case "WindowHistoryPick":
            Menu_PickHistory(hWnd)

        case "Swap":
            SwapWindows(hWnd, "All")

        case "SwapSize":
            SwapWindows(hWnd, "Size")

        case "SwapPosition":
            SwapWindows(hWnd, "Position")

        case "SwapPick":
            StartSwapPick("All")

        case "SwapPickSize":
            StartSwapPick("Size")

        case "SwapPickPosition":
            StartSwapPick("Position")

        case "Gridify":
            ShowGridifyMenu(hWnd)

        case "UntuckLeft":
            UntuckDimension("Left")

        case "UntuckRight":
            UntuckDimension("Right")

        case "UntuckTop", "UntuckUp":
            UntuckDimension("Up")

        case "UntuckBottom", "UntuckDown":
            UntuckDimension("Down")

        case "TuckPeekLeft":
            TuckPeekDimension("Left")

        case "TuckPeekRight":
            TuckPeekDimension("Right")

        case "TuckPeekTop", "TuckPeekUp":
            TuckPeekDimension("Up")

        case "TuckPeekBottom", "TuckPeekDown":
            TuckPeekDimension("Down")

        case "DragWindow":
            StartDragWindow(hWnd)

        case "TuckLeft", "TuckRight", "TuckUp", "TuckDown":
            ; Force global registry data attachment directly inside the local case context
            global g_TuckedWindows, g_TuckedVisiblePixels

            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                origX := Number(X)
                origY := Number(Y)
                origW := Number(W)
                origH := Number(H)

                g_TuckedWindows[hWnd] := { edge: SubStr(sCmd, 5), x: origX, y: origY, w: origW, h: origH }

                nX := origX
                nY := origY

                ; --- SYNCED DOCK ACCENT ENGINE ---
                ; Employs your central global variable value to calculate the exact offset placement
                switch sCmd, false {
                    case "TuckLeft":
                        nX := mLeft - origW + g_TuckedVisiblePixels

                    case "TuckRight":
                        nX := mRight - g_TuckedVisiblePixels

                    case "TuckUp":
                        nY := mTop - origH + g_TuckedVisiblePixels

                    case "TuckDown":
                        nY := mBottom - g_TuckedVisiblePixels
                }

                SafeMove(nX, nY, origW, origH, hWnd)
                ExecuteCommandRegistry("NextWindow", hWnd)
            }

        case "TuckMouseBump":
            ; 1. Grab current mouse position (Screen coordinates)
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mX, &mY)

            ; 2. Fetch Active Monitor Surface Boundary Data via Windows API
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; 3. Calculate distance from mouse to each monitor boundary line
                distLeft := Abs(mX - mLeft)
                distRight := Abs(mX - mRight)
                distTop := Abs(mY - mTop)
                distBottom := Abs(mY - mBottom)

                ; Find the absolute shortest distance
                minDist := Min(distLeft, distRight, distTop, distBottom)

                ; 4. Re-route command execution dynamically to the closest edge case
                if (minDist == distLeft) {
                    ExecuteCommandRegistry("TuckLeft", hWnd)
                } else if (minDist == distRight) {
                    ExecuteCommandRegistry("TuckRight", hWnd)
                } else if (minDist == distTop) {
                    ExecuteCommandRegistry("TuckUp", hWnd)
                } else if (minDist == distBottom) {
                    ExecuteCommandRegistry("TuckDown", hWnd)
                }
            }

        case "BumpEdgeUntuck", "BumpEdgeUntuckActivate":
            global g_ActiveUntuckedHwnd, g_UntuckCooldown, g_BaselineActiveWindow, g_UntuckGraceTicks

            CoordMode("Mouse", "Screen")
            MouseGetPos(&mX, &mY)

            ; 1. Pull the active monitor layout dimensions cleanly
            hMon := DllCall("MonitorFromWindow", "ptr", 0, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; Calculate active monitor width and height
                mWidth := mRight - mLeft
                mHeight := mBottom - mTop

                ; 2. Determine target edge wall
                distLeft := Abs(mX - mLeft)
                distRight := Abs(mX - mRight)
                distTop := Abs(mY - mTop)
                distBottom := Abs(mY - mBottom)

                minDist := Min(distLeft, distRight, distTop, distBottom)
                targetEdge := ""
                if (minDist == distLeft) {
                    targetEdge := "Left"
                } else if (minDist == distRight) {
                    targetEdge := "Right"
                } else if (minDist == distTop) {
                    targetEdge := "Top"
                } else if (minDist == distBottom) {
                    targetEdge := "Bottom"
                }

                ; 3. Identify closest tucked window handle
                closestHwnd := 0
                closestDist := 999999

                for tHwnd, tuckObj in g_TuckedWindows {
                    numericHwnd := Number(tHwnd)
                    if (tuckObj.edge != targetEdge || !WinExist("ahk_id " . numericHwnd)) {
                        continue
                    }

                    if (targetEdge == "Left" || targetEdge == "Right") {
                        tCenter := tuckObj.y + Floor(tuckObj.h / 2)
                        mDist := Abs(mY - tCenter)
                    } else {
                        tCenter := tuckObj.x + Floor(tuckObj.w / 2)
                        mDist := Abs(mX - tCenter)
                    }

                    if (mDist < closestDist) {
                        closestDist := mDist
                        closestHwnd := numericHwnd
                    }
                }

                ; 4. Execute Untuck Position Fixes
                if (closestHwnd != 0) {
                    activeTuckProfile := g_TuckedWindows[closestHwnd]
                    if (sCmd == "BumpEdgeUntuck") {
                        RevealTuckedWindow(closestHwnd, targetEdge, activeTuckProfile)
                    }
                    else if (sCmd == "BumpEdgeUntuckActivate") {
                        try {
                            WinGetPos(&tX, &tY, &tW, &tH, closestHwnd)

                            nX := tX
                            nY := tY
                            switch targetEdge {
                                case "Left":
                                    nX := mLeft

                                case "Right":
                                    nX := mRight - Number(activeTuckProfile.w)

                                case "Top":
                                    nY := mTop

                                case "Bottom":
                                    nY := mBottom - Number(activeTuckProfile.h)
                            }

                            SafeMove(nX, nY, Number(activeTuckProfile.w), Number(activeTuckProfile.h), closestHwnd)
                            
                            ; --- HIGHLY ROBUST Z-ORDER SEIZURE (ACTIVE) ---
                            WinSetAlwaysOnTop(1, "ahk_id " . closestHwnd)
                            WinSetAlwaysOnTop(0, "ahk_id " . closestHwnd)
                            WinMoveTop("ahk_id " . closestHwnd) ; Elevate window to top of Z-order index

                            ; Draw window on top and give it full foreground focus
                            DllCall("SetWindowPos", "ptr", closestHwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0040)
                            WinActivate("ahk_id " . closestHwnd)

                            g_PeekX := nX
                            g_PeekY := nY
                            g_ActiveUntuckedHwnd := closestHwnd
                            g_UntuckGraceTicks := 10

                            SetTimer(TrackUntuckedFocusLifecycle, 0)
                            SetTimer(TrackUntuckedFocusLifecycle, 50)
                        }
                    }
                }

                ; ALWAYS re-arm the edge bump mouse-monitoring loop if no window is actively untucked!
                if (g_ActiveUntuckedHwnd == 0) {
                    SetTimer(CheckScreenEdgeBumps, 25)
                }

            }

        case "EdgeLeft", "EdgeRight", "EdgeTop", "EdgeBottom", "EdgeCenter", "EdgeTopLeft", "EdgeTopRight", "EdgeBottomLeft", "EdgeBottomRight", "EdgeInLeft", "EdgeInRight", "EdgeInTop", "EdgeInBottom", "EdgeInTopLeft", "EdgeInTopRight", "EdgeInBottomLeft", "EdgeInBottomRight":
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

                pX := 424
                pY := 232

                nX := X, nY := Y
                switch sCmd, false {
                    case "EdgeLeft": nX := mLeft
                    case "EdgeRight": nX := mRight - W
                    case "EdgeTop": nY := mTop
                    case "EdgeBottom": nY := mBottom - H
                    case "EdgeTopLeft": nX := mLeft, nY := mTop
                    case "EdgeTopRight": nX := mRight - W, nY := mTop
                    case "EdgeBottomLeft": nX := mLeft, nY := mBottom - H
                    case "EdgeBottomRight": nX := mRight - W, nY := mBottom - H
                    case "EdgeCenter": nX := mLeft + Floor((mWidth - W) / 2), nY := mTop + Floor((mHeight - H) / 2)
                    case "EdgeInLeft": nX := mLeft + pX
                    case "EdgeInRight": nX := mRight - W - pX
                    case "EdgeInTop": nY := mTop + pY
                    case "EdgeInBottom": nY := mBottom - H - pY
                    case "EdgeInTopLeft": nX := mLeft + pX, nY := mTop + pY
                    case "EdgeInTopRight": nX := mRight - W - pX, nY := mTop + pY
                    case "EdgeInBottomLeft": nX := mLeft + pX, nY := mBottom - H - pY
                    case "EdgeInBottomRight": nX := mRight - W - pX, nY := mBottom - H - pY
                }
                AnimateWinMove(nX, nY, hWnd)
            }
        case "StretchLeft", "StretchRight", "StretchTop", "StretchBottom", "StretchTopLeft", "StretchTopRight", "StretchBottomLeft", "StretchBottomRight", "StretchAll":
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

                nX := X, nY := Y, nW := W, nH := H
                switch sCmd {
                    case "StretchLeft": nX := mLeft, nW := (X + W) - mLeft
                    case "StretchRight": nW := mRight - X
                    case "StretchTop": nY := mTop, nH := (Y + H) - mTop
                    case "StretchBottom": nH := mBottom - Y
                    case "StretchTopLeft": nX := mLeft, nY := mTop, nW := (X + W) - mLeft, nH := (Y + H) - mTop
                    case "StretchTopRight": nY := mTop, nW := mRight - X, nH := (Y + H) - mTop
                    case "StretchBottomLeft": nX := mLeft, nW := (X + W) - mLeft, nH := mBottom - Y
                    case "StretchBottomRight": nW := mRight - X, nH := mBottom - Y
                    case "StretchAll": nX := mLeft, nY := mTop, nW := mWidth, nH := mHeight
                }
                SafeMove(nX, nY, nW, nH, hWnd)
            }

        case "SnapToGridEnlarge", "SnapToGridShrink", "MouseToGrid", "MoveToGridLeft", "MoveToGridRight", "MoveToGridUp", "MoveToGridDown", "MoveToGridTopLeft", "MoveToGridTopRight", "MoveToGridBottomLeft", "MoveToGridBottomRight":
            ; 1. Base Grid Geometry Configurations
            gX := 15
            gY := 15
            rW := 418
            rH := 226
            pX := 424 ; 418px box + 6px gap
            pY := 232 ; 226px box + 6px gap

            ; 2. Fetch Active Monitor Work Surface Bound Data via Windows API
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; Compute max valid tile block columns/rows that cleanly fit inside the monitor
                maxCols := Floor((mRight - gX) / pX)
                maxRows := Floor((mBottom - gY) / pY)

                ; 3. MATHEMATICALLY SOUND INDEX CORNER MAPPING
                ; Locates exactly which cell blocks the outside edges rest upon
                cLeft := Round((X - gX) / pX)
                cRight := Round((X + W - gX) / pX)
                rTop := Round((Y - gY) / pY)
                rBottom := Round((Y + H - gY) / pY)

                ; Derive grid spans safely
                gridUnitsWide := cRight - cLeft
                gridUnitsTall := rBottom - rTop

                ; Re-translate indices into perfect reference pixel footprints
                snapX := gX + (cLeft * pX)
                snapY := gY + (rTop * pY)
                snapW := (gridUnitsWide * pX) - 6
                snapH := (gridUnitsTall * pY) - 6

                switch sCmd {
                    case "SnapToGridEnlarge":
                        ; Check if already matched to our grid footprint template within a 10px variance
                        if (Abs(X - snapX) < 10 && Abs(Y - snapY) < 10 && Abs(W - snapW) < 10 && Abs(H - snapH) < 10) {
                            cLeft -= 1
                            cRight += 1
                            rTop -= 1
                            rBottom += 1
                        } else {
                            ; Off-Grid: Snap to grid by sizing the window to grid units (favoring enlargement) then moving to grid
                            gridUnitsWide := Max(1, Ceil((W + 6) / pX))
                            gridUnitsTall := Max(1, Ceil((H + 6) / pY))
                            cLeft := Round((X - gX) / pX)
                            cRight := cLeft + gridUnitsWide
                            rTop := Round((Y - gY) / pY)
                            rBottom := rTop + gridUnitsTall
                        }

                    case "SnapToGridShrink":
                        ; Check if already matched to our grid footprint template within a 10px variance
                        if (Abs(X - snapX) < 10 && Abs(Y - snapY) < 10 && Abs(W - snapW) < 10 && Abs(H - snapH) < 10) {
                            if (cRight - cLeft > 2) {
                                cLeft += 1
                                cRight -= 1
                            } else if (cRight - cLeft == 2) {
                                cRight -= 1
                            }
                            if (rBottom - rTop > 2) {
                                rTop += 1
                                rBottom -= 1
                            } else if (rBottom - rTop == 2) {
                                rBottom -= 1
                            }
                        } else {
                            ; Off-Grid: Snap to grid by sizing the window to grid units (favoring shrinkage) then moving to grid
                            gridUnitsWide := Max(1, Floor((W + 6) / pX))
                            gridUnitsTall := Max(1, Floor((H + 6) / pY))
                            cLeft := Round((X - gX) / pX)
                            cRight := cLeft + gridUnitsWide
                            rTop := Round((Y - gY) / pY)
                            rBottom := rTop + gridUnitsTall
                        }

                    case "MoveToGridLeft":
                        cLeft -= 1
                        cRight -= 1

                    case "MoveToGridRight":
                        cLeft += 1
                        cRight += 1

                    case "MoveToGridUp":
                        rTop -= 1
                        rBottom -= 1

                    case "MoveToGridDown":
                        rTop += 1
                        rBottom += 1

                    case "MoveToGridTopLeft":
                        cLeft -= 1
                        cRight -= 1
                        rTop -= 1
                        rBottom -= 1

                    case "MoveToGridTopRight":
                        cLeft += 1
                        cRight += 1
                        rTop -= 1
                        rBottom -= 1

                    case "MoveToGridBottomLeft":
                        cLeft -= 1
                        cRight -= 1
                        rTop += 1
                        rBottom += 1

                    case "MoveToGridBottomRight":
                        cLeft += 1
                        cRight += 1
                        rTop += 1
                        rBottom += 1

                    case "MouseToGrid":
                        CoordMode("Mouse", "Screen")
                        MouseGetPos(&mX, &mY)

                        mCol := Round((mX - gX - (rW / 2)) / pX)
                        mRow := Round((mY - gY - (rH / 2)) / pY)

                        if (mX >= X && mX <= X + W && mY >= Y && mY <= Y + H) {
                            thirdW := Floor(W / 3)
                            thirdH := Floor(H / 3)

                            if (mX < X + thirdW) {
                                cLeft := mCol
                            } else if (mX > X + W - thirdW) {
                                cRight := mCol + 1
                            }

                            if (mY < Y + thirdH) {
                                rTop := mRow
                            } else if (mY > Y + H - thirdH) {
                                rBottom := mRow + 1
                            }
                        } else {
                            if (mX < X) {
                                cLeft := mCol
                            } else if (mX > X + W) {
                                cRight := mCol + 1
                            }

                            if (mY < Y) {
                                rTop := mRow
                            } else if (mY > Y + H) {
                                rBottom := mRow + 1
                            }
                        }
                }

                ; 4. STRICT INDEX-BASED BOUNDARY PROTECTION
                ; Enforce minimum window footprint space parameters (1x1 tile)
                if (cRight <= cLeft) {
                    cRight := cLeft + 1
                }
                if (rBottom <= rTop) {
                    rBottom := rTop + 1
                }

                ; Left and Top Screen Edge Limits
                if (cLeft < 0) {
                    cRight -= cLeft
                    cLeft := 0
                }
                if (rTop < 0) {
                    rBottom -= rTop
                    rTop := 0
                }

                ; Right and Bottom Screen Edge Limits
                if (cRight > maxCols) {
                    cLeft -= (cRight - maxCols)
                    cRight := maxCols
                    if (cLeft < 0) {
                        cLeft := 0
                    }
                }
                if (rBottom > maxRows) {
                    rTop -= (rBottom - maxRows)
                    rBottom := maxRows
                    if (rTop < 0) {
                        rTop := 0
                    }
                }

                ; 5. Final Pixel Conversion & Execution
                nX := gX + (cLeft * pX)
                nY := gY + (rTop * pY)
                nW := (cRight - cLeft) * pX - 6
                nH := (rBottom - rTop) * pY - 6

                SafeMove(nX, nY, nW, nH, hWnd)
            }
        case "NextWindow":
            ; 1. Push current window to the absolute bottom of the stack
            DllCall("SetWindowPos", "ptr", hWnd, "ptr", 1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0013) ; 1 = HWND_BOTTOM, 0x0013 = NOSIZE|NOMOVE|NOACTIVATE

            ; 2. Critical Pause: Give Windows a split second to process the depth shift
            Sleep(10)

            ; 3. Scan top-down from the remaining open applications
            winList := WinGetList()
            for targetHwnd in winList {
                if (targetHwnd == hWnd) {
                    continue
                }
                ; EXCLUDE TUCKED WINDOWS SELECTION CODES
                if (g_TuckedWindows.Has(targetHwnd)) {
                    continue
                }

                ; Ignore hidden system modules, desktop backgrounds, and taskbars
                winClass := WinGetClass(targetHwnd)
                if (winClass == "Progman" || winClass == "WorkerW" || winClass == "Shell_TrayWnd") {
                    continue
                }

                ; SAFETY LAYER: Inspect window dimensions to discard zero-size ghost frames
                try {
                    WinGetPos(, , &tW, &tH, targetHwnd)
                    if (tW <= 0 || tH <= 0) {
                        continue
                    }
                } catch {
                    continue
                }

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

                if (targetHwnd == hWnd) {
                    continue
                }
                ; EXCLUDE TUCKED WINDOWS SELECTION CODES
                if (g_TuckedWindows.Has(targetHwnd)) {
                    continue
                }

                ; Ignore hidden system modules, desktop backgrounds, and taskbars
                winClass := WinGetClass(targetHwnd)
                if (winClass == "Progman" || winClass == "WorkerW" || winClass == "Shell_TrayWnd") {
                    continue
                }

                ; SAFETY LAYER: Inspect window dimensions to discard zero-size ghost frames
                try {
                    WinGetPos(, , &tW, &tH, targetHwnd)
                    if (tW <= 0 || tH <= 0) {
                        continue
                    }
                } catch {
                    continue
                }

                style := WinGetStyle(targetHwnd)
                ; Verify window is visible (WS_VISIBLE) and NOT minimized
                if ((style & 0x10000000) && WinGetMinMax(targetHwnd) != -1) {
                    WinActivate(targetHwnd)
                    break
                }
            }

        case "NextClassWindow":
            ; 1. Grab the active window's full executable path safely
            activeExe := ""
            try {
                activeExe := WinGetProcessPath(hWnd)
            } catch {
                return
            }

            ; 2. Push current window to the absolute bottom of the stack
            DllCall("SetWindowPos", "ptr", hWnd, "ptr", 1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0013) ; 1 = HWND_BOTTOM, 0x0013 = NOSIZE|NOMOVE|NOACTIVATE

            ; Yield 10ms to let the Windows visual index layer register the shift depth
            Sleep(10)

            ; 3. Scan top-down exclusively for matching application executables
            winList := WinGetList()
            for targetHwnd in winList {
                if (targetHwnd == hWnd) {
                    continue
                }
                ; EXCLUDE TUCKED WINDOWS SELECTION CODES
                if (g_TuckedWindows.Has(targetHwnd)) {
                    continue
                }

                ; Only process if it belongs to our exact active application full path exe
                try {
                    thisExe := WinGetProcessPath(targetHwnd)
                } catch {
                    continue
                }

                if (thisExe == activeExe) {
                    ; SAFETY LAYER: Inspect window dimensions to discard zero-size ghost frames
                    try {
                        WinGetPos(, , &tW, &tH, targetHwnd)
                        if (tW <= 0 || tH <= 0) {
                            continue
                        }
                    } catch {
                        continue
                    }

                    style := WinGetStyle(targetHwnd)
                    ; Verify window is visible (WS_VISIBLE) and NOT minimized
                    if ((style & 0x10000000) && WinGetMinMax(targetHwnd) != -1) {
                        WinActivate(targetHwnd)
                        break
                    }
                }
            }

        case "PrevClassWindow":
            ; 1. Grab the active window's full executable path safely
            activeExe := ""
            try {
                activeExe := WinGetProcessPath(hWnd)
            } catch {
                return
            }

            ; 2. Scan the window list backward (starting from the bottom of the stack up)
            winList := WinGetList()
            idx := winList.Length
            while (idx > 0) {
                targetHwnd := winList[idx]
                idx--

                if (targetHwnd == hWnd) {
                    continue
                }
                ; EXCLUDE TUCKED WINDOWS SELECTION CODES
                if (g_TuckedWindows.Has(targetHwnd)) {
                    continue
                }

                ; Only process if it belongs to our exact active application full path exe
                try {
                    thisExe := WinGetProcessPath(targetHwnd)
                } catch {
                    continue
                }

                if (thisExe == activeExe) {
                    ; SAFETY LAYER: Inspect window dimensions to discard zero-size ghost frames
                    try {
                        WinGetPos(, , &tW, &tH, targetHwnd)
                        if (tW <= 0 || tH <= 0) {
                            continue
                        }
                    } catch {
                        continue
                    }

                    style := WinGetStyle(targetHwnd)
                    ; Verify window is visible (WS_VISIBLE) and NOT minimized
                    if ((style & 0x10000000) && WinGetMinMax(targetHwnd) != -1) {
                        WinActivate(targetHwnd)
                        break
                    }
                }
            }

        case "RestoreAll":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd, true)) {
                    status := WinGetMinMax(hwnd)
                    if (status == 1 || status == -1) {
                        try WinRestore(hwnd)
                    }
                }
            }

        case "RestoreAllMinimized":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd, true) && WinGetMinMax(hwnd) == -1) {
                    try WinRestore(hwnd)
                }
            }

        case "MaximizeAll":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd, true)) {
                    status := WinGetMinMax(hwnd)
                    if (status == 0 || status == -1) {
                        try WinMaximize(hwnd)
                    }
                }
            }

        case "RestoreAllMaximized":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd) && WinGetMinMax(hwnd) == 1) {
                    try WinRestore(hwnd)
                }
            }

        case "MaximizeAllRestored":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd) && WinGetMinMax(hwnd) == 0) {
                    try WinMaximize(hwnd)
                }
            }

        case "MaximizeAllMinimized":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd, true) && WinGetMinMax(hwnd) == -1) {
                    try WinMaximize(hwnd)
                }
            }

        case "SwapMaximizedRestored":
            winList := WinGetList()
            maxList := []
            resList := []
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd)) {
                    status := WinGetMinMax(hwnd)
                    if (status == 1) {
                        maxList.Push(hwnd)
                    } else if (status == 0) {
                        resList.Push(hwnd)
                    }
                }
            }
            for hwnd in maxList {
                try WinRestore(hwnd)
            }
            for hwnd in resList {
                try WinMaximize(hwnd)
            }

        case "SwapMinimizedRestored":
            winList := WinGetList()
            minList := []
            resList := []
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd, true)) {
                    status := WinGetMinMax(hwnd)
                    if (status == -1) {
                        minList.Push(hwnd)
                    } else if (status == 0) {
                        resList.Push(hwnd)
                    }
                }
            }
            for hwnd in minList {
                try WinRestore(hwnd)
            }
            for hwnd in resList {
                try WinMinimize(hwnd)
            }

        case "MinimizeAll":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd)) {
                    status := WinGetMinMax(hwnd)
                    if (status == 0 || status == 1) {
                        try WinMinimize(hwnd)
                    }
                }
            }

        case "MinimizeAllRestored":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd) && WinGetMinMax(hwnd) == 0) {
                    try WinMinimize(hwnd)
                }
            }

        case "MinimizeAllMaximized":
            winList := WinGetList()
            for hwnd in winList {
                if (IsEligibleForBulkCommand(hwnd) && WinGetMinMax(hwnd) == 1) {
                    try WinMinimize(hwnd)
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
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; Snapshot existing geometry
                origRight := X + W
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
                        nW := W - 20, nX := X + 40
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
                    distLeft := Abs(mX - X)
                    distRight := Abs(mX - origRight)
                    distTop := Abs(mY - Y)
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

                SafeMove(nX, nY, nW, nH, hWnd)
            }

        case "WinInfo":
            ; 1. Base Grid Constants for Index Extraction
            gX := 15, gY := 15
            pX := 424, pY := 232 ; Pitch spacing (Width/Height + 6px gap)

            ; 2. Fetch Active Monitor Data and Window Metadata
            wTitle := WinGetTitle(hWnd)
            wClass := WinGetClass(hWnd)
            wProc := WinGetProcessName(hWnd)

            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            mLeft := 0, mTop := 0, mRight := 0, mBottom := 0
            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")
            }

            ; 3. Calculate Grid Unit Positions
            cLeft := Round((X - gX) / pX)
            cRight := Round((X + W - gX) / pX)
            rTop := Round((Y - gY) / pY)
            rBottom := Round((Y + H - gY) / pY)

            gridWidth := cRight - cLeft
            gridHeight := rBottom - rTop

            ; 4. Format the Diagnostic Blueprint String
            infoString := "========================================`n"
            infoString .= "       WINDOW NUDGER METADATA           `n"
            infoString .= "========================================`n"
            infoString .= "Title:        " . wTitle . "`n"
            infoString .= "HWND:         " . hWnd . "`n"
            infoString .= "Class:        " . wClass . "`n"
            infoString .= "Process:      " . wProc . "`n"
            infoString .= "----------------------------------------`n"
            infoString .= "PIXEL GEOMETRY:`n"
            infoString .= "X: " . X . " | Y: " . Y . " | W: " . W . " | H: " . H . "`n"
            infoString .= "Right Edge: " . (X + W) . " | Bottom Edge: " . (Y + H) . "`n"
            infoString .= "----------------------------------------`n"
            infoString .= "GRID COORDINATES:`n"
            infoString .= "Columns (X):  Span " . cLeft . " to " . cRight . " (" . gridWidth . " units wide)`n"
            infoString .= "Rows (Y):     Span " . rTop . " to " . rBottom . " (" . gridHeight . " units tall)`n"
            infoString .= "----------------------------------------`n"
            infoString .= "MONITOR WORKAREA:`n"
            infoString .= "Left: " . mLeft . " | Top: " . mTop . " | Right: " . mRight . " | Bottom: " . mBottom . "`n"
            infoString .= "========================================"

            ; 5. Write diagnostic blueprint directly to Logfile
            LogMessage(infoString)

        case "Center":
            ; 1. Fetch Active Monitor Surface Boundary Data via Windows API
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; Calculate monitor dimensions
                mWidth := mRight - mLeft
                mHeight := mBottom - mTop

                ; 2. Centering Logic equations (Monitor work-surface mid-point minus half of active window dimensions)
                nX := mLeft + Floor((mWidth - W) / 2)
                nY := mTop + Floor((mHeight - H) / 2)

                ; 3. Centering active window precisely on screen
                SafeMove(nX, nY, , , hWnd)
            }

        case "ScaleExpandGridPart", "ScaleReduceGridPart":
            ; 1. Base Grid Geometry Configurations
            gX := 15
            gY := 15
            pX := 424
            pY := 232

            ; Find closest half-grid indices
            iLeft := FindLineX(X, gX, pX)
            jRight := FindRightX(X + W, gX, pX)
            kTop := FindLineY(Y, gY, pY)
            lBottom := FindBottomY(Y + H, gY, pY)

            ; Ideal half-grid reference positions mapped from these indices
            snapX := gX + Floor(iLeft / 2) * pX + (Mod(iLeft, 2) == 0 ? 0 : 209)
            snapY := gY + Floor(kTop / 2) * pY + (Mod(kTop, 2) == 0 ? 0 : 113)
            snapW := (gX + Floor(jRight / 2) * pX + (Mod(jRight, 2) == 0 ? -6 : 209)) - snapX
            snapH := (gY + Floor(lBottom / 2) * pY + (Mod(lBottom, 2) == 0 ? -6 : 113)) - snapY

            ; Check if already matched to our half-grid footprint within 10px variance
            if (Abs(X - snapX) < 10 && Abs(Y - snapY) < 10 && Abs(W - snapW) < 10 && Abs(H - snapH) < 10) {
                if (sCmd == "ScaleExpandGridPart") {
                    iLeft := iLeft - 1
                    jRight := jRight + 1
                    kTop := kTop - 1
                    lBottom := lBottom + 1
                } else { ; ScaleReduceGridPart
                    spanX := jRight - iLeft
                    if (spanX > 2) {
                        iLeft += 1
                        jRight -= 1
                    } else if (spanX == 2) {
                        jRight -= 1
                    }
                    spanY := lBottom - kTop
                    if (spanY > 2) {
                        kTop += 1
                        lBottom -= 1
                    } else if (spanY == 2) {
                        lBottom -= 1
                    }
                }
            } else {
                ; Off-grid: Snap to nearest half-grid position
                if (sCmd == "ScaleExpandGridPart") {
                    ; Snap with ceil/round to favor enlargement
                    spanX := Max(1, Ceil((W + 6) / (pX / 2)))
                    spanY := Max(1, Ceil((H + 6) / (pY / 2)))
                    iLeft := Max(0, Round((X - gX) / (pX / 2)))
                    jRight := iLeft + spanX
                    kTop := Max(0, Round((Y - gY) / (pY / 2)))
                    lBottom := kTop + spanY
                } else { ; ScaleReduceGridPart
                    ; Snap with floor/round to favor shrinkage
                    spanX := Max(1, Floor((W + 6) / (pX / 2)))
                    spanY := Max(1, Floor((H + 6) / (pY / 2)))
                    iLeft := Max(0, Round((X - gX) / (pX / 2)))
                    jRight := iLeft + spanX
                    kTop := Max(0, Round((Y - gY) / (pY / 2)))
                    lBottom := kTop + spanY
                }
            }

            ; Ensure minimum of 0 for indices to avoid going off screen left/top
            if (iLeft < 0) {
                jRight -= iLeft  ; Maintain the width
                iLeft := 0
            }
            if (kTop < 0) {
                lBottom -= kTop  ; Maintain the height
                kTop := 0
            }

            ; Re-translate indices into final pixel footprint
            nX := gX + Floor(iLeft / 2) * pX + (Mod(iLeft, 2) == 0 ? 0 : 209)
            nY := gY + Floor(kTop / 2) * pY + (Mod(kTop, 2) == 0 ? 0 : 113)
            nW := (gX + Floor(jRight / 2) * pX + (Mod(jRight, 2) == 0 ? -6 : 209)) - nX
            nH := (gY + Floor(lBottom / 2) * pY + (Mod(lBottom, 2) == 0 ? -6 : 113)) - nY

            SafeMove(nX, nY, nW, nH, hWnd)

        case "ScaleExpand10px": SafeMove(X - g_zx // 2, Y - g_zy // 2, W + g_zx, H + g_zy, hWnd)
        case "ScaleReduce10px": SafeMove(X + g_zx // 2, Y + g_zy // 2, W - g_zx, H - g_zy, hWnd)
        case "TrimTop": SafeMove(X, Y + g_zy, W, H - g_zy, hWnd)
        case "TrimBottom": SafeMove(X, Y, W, H - g_zy, hWnd)
        case "TrimLeft": SafeMove(X + g_zx, Y, W - g_zx, H, hWnd)
        case "TrimRight": SafeMove(X, Y, W - g_zx, H, hWnd)
        case "TrimTopLeft": SafeMove(X + g_zx, Y + g_zy, W - g_zx, H - g_zy, hWnd)
        case "TrimTopRight": SafeMove(X, Y + g_zy, W - g_zx, H - g_zy, hWnd)
        case "TrimBottomLeft": SafeMove(X + g_zx, Y, W - g_zx, H - g_zy, hWnd)
        case "TrimBottomRight": SafeMove(X, Y, W - g_zx, H - g_zy, hWnd)
        case "TrimAll": SafeMove(X + g_zx, Y + g_zy, W - 2 * g_zx, H - 2 * g_zy, hWnd)
        case "GrowTop": SafeMove(X, Y - g_zy, W, H + g_zy, hWnd)
        case "GrowBottom": SafeMove(X, Y, W, H + g_zy, hWnd)
        case "GrowLeft": SafeMove(X - g_zx, Y, W + g_zx, H, hWnd)
        case "GrowRight": SafeMove(X, Y, W + g_zx, H, hWnd)
        case "GrowTopLeft": SafeMove(X - g_zx, Y - g_zy, W + g_zx, H + g_zy, hWnd)
        case "GrowTopRight": SafeMove(X, Y - g_zy, W + g_zx, H + g_zy, hWnd)
        case "GrowBottomLeft": SafeMove(X - g_zx, Y, W + g_zx, H + g_zy, hWnd)
        case "GrowBottomRight": SafeMove(X, Y, W + g_zx, H + g_zy, hWnd)
        case "GrowAll": SafeMove(X - g_zx, Y - g_zy, W + 2 * g_zx, H + 2 * g_zy, hWnd)
        case "SetHome": SetWindowHome(hWnd)
        case "ClearHome": ClearWindowHome(hWnd)
        case "GoHome": GoWindowHome(hWnd)
        case "Home": InteractiveHome(hWnd)
        case "HomePeek": ShowHomePeek(hWnd)
        case "StretchToGridLeft", "StretchToGridRight", "StretchToGridUp", "StretchToGridDown", "StretchToGridTopLeft", "StretchToGridTopRight", "StretchToGridBottomLeft", "StretchToGridBottomRight", "StretchToGridAll", "PullToGridLeft", "PullToGridRight", "PullToGridUp", "PullToGridDown", "PullToGridTopLeft", "PullToGridTopRight", "PullToGridBottomLeft", "PullToGridBottomRight", "PullToGridAll":
        case "AddTop", "AddBottom", "AddLeft", "AddRight", "AddTopLeft", "AddTopRight", "AddBottomLeft", "AddBottomRight", "AddAll", "SubtractTop", "SubtractBottom", "SubtractLeft", "SubtractRight", "SubtractTopLeft", "SubtractTopRight", "SubtractBottomLeft", "SubtractBottomRight", "SubtractAll":
            ; 1. Base Grid Geometry Configurations (using half-grid / mid-point cells)
            gX := 15
            gY := 15
            pX := 424
            pY := 232

            ; Find closest half-grid indices
            iLeft := FindLineX(X, gX, pX)
            jRight := FindRightX(X + W, gX, pX)
            kTop := FindLineY(Y, gY, pY)
            lBottom := FindBottomY(Y + H, gY, pY)

            ; Ideal half-grid reference positions mapped from these indices
            snapX := gX + Floor(iLeft / 2) * pX + (Mod(iLeft, 2) == 0 ? 0 : 209)
            snapRight := gX + Floor(jRight / 2) * pX + (Mod(jRight, 2) == 0 ? -6 : 209)
            snapY := gY + Floor(kTop / 2) * pY + (Mod(kTop, 2) == 0 ? 0 : 113)
            snapBottom := gY + Floor(lBottom / 2) * pY + (Mod(lBottom, 2) == 0 ? -6 : 113)

            switch sCmd {
                case "StretchToGridLeft", "AddLeft":
                    if (snapX >= X - 2) {
                        iLeft := iLeft - 1
                    }
                case "StretchToGridRight", "AddRight":
                    if (snapRight <= (X + W) + 2) {
                        jRight := jRight + 1
                    }
                case "StretchToGridUp", "AddTop":
                    if (snapY >= Y - 2) {
                        kTop := kTop - 1
                    }
                case "StretchToGridDown", "AddBottom":
                    if (snapBottom <= (Y + H) + 2) {
                        lBottom := lBottom + 1
                    }
                case "StretchToGridTopLeft", "AddTopLeft":
                    if (snapX >= X - 2) {
                        iLeft := iLeft - 1
                    }
                    if (snapY >= Y - 2) {
                        kTop := kTop - 1
                    }
                case "StretchToGridTopRight", "AddTopRight":
                    if (snapRight <= (X + W) + 2) {
                        jRight := jRight + 1
                    }
                    if (snapY >= Y - 2) {
                        kTop := kTop - 1
                    }
                case "StretchToGridBottomLeft", "AddBottomLeft":
                    if (snapX >= X - 2) {
                        iLeft := iLeft - 1
                    }
                    if (snapBottom <= (Y + H) + 2) {
                        lBottom := lBottom + 1
                    }
                case "StretchToGridBottomRight", "AddBottomRight":
                    if (snapRight <= (X + W) + 2) {
                        jRight := jRight + 1
                    }
                    if (snapBottom <= (Y + H) + 2) {
                        lBottom := lBottom + 1
                    }
                case "PullToGridLeft", "SubtractLeft":
                    if (snapX <= X + 2) {
                        iLeft := iLeft + 1
                    }
                    if (iLeft >= jRight) {
                        iLeft := jRight - 1
                    }
                case "PullToGridRight", "SubtractRight":
                    if (snapRight >= (X + W) - 2) {
                        jRight := jRight - 1
                    }
                    if (jRight <= iLeft) {
                        jRight := iLeft + 1
                    }
                case "PullToGridUp", "SubtractTop":
                    if (snapY <= Y + 2) {
                        kTop := kTop + 1
                    }
                    if (kTop >= lBottom) {
                        kTop := lBottom - 1
                    }
                case "PullToGridDown", "SubtractBottom":
                    if (snapBottom >= (Y + H) - 2) {
                        lBottom := lBottom - 1
                    }
                    if (lBottom <= kTop) {
                        lBottom := kTop + 1
                    }
                case "PullToGridTopLeft", "SubtractTopLeft":
                    if (snapY <= Y + 2) {
                        kTop := kTop + 1
                    }
                    if (kTop >= lBottom) {
                        kTop := lBottom - 1
                    }
                    if (snapX <= X + 2) {
                        iLeft := iLeft + 1
                    }
                    if (iLeft >= jRight) {
                        iLeft := jRight - 1
                    }
                case "PullToGridTopRight", "SubtractTopRight":
                    if (snapY <= Y + 2) {
                        kTop := kTop + 1
                    }
                    if (kTop >= lBottom) {
                        kTop := lBottom - 1
                    }
                    if (snapRight >= (X + W) - 2) {
                        jRight := jRight - 1
                    }
                    if (jRight <= iLeft) {
                        jRight := iLeft + 1
                    }
                case "PullToGridBottomLeft", "SubtractBottomLeft":
                    if (snapBottom >= (Y + H) - 2) {
                        lBottom := lBottom - 1
                    }
                    if (lBottom <= kTop) {
                        lBottom := kTop + 1
                    }
                    if (snapX <= X + 2) {
                        iLeft := iLeft + 1
                    }
                    if (iLeft >= jRight) {
                        iLeft := jRight - 1
                    }
                case "PullToGridBottomRight", "SubtractBottomRight":
                    if (snapBottom >= (Y + H) - 2) {
                        lBottom := lBottom - 1
                    }
                    if (lBottom <= kTop) {
                        lBottom := kTop + 1
                    }
                    if (snapRight >= (X + W) - 2) {
                        jRight := jRight - 1
                    }
                    if (jRight <= iLeft) {
                        jRight := iLeft + 1
                    }
                case "StretchToGridAll", "AddAll":
                    if (snapX >= X - 2) {
                        iLeft := iLeft - 1
                    }
                    if (snapRight <= (X + W) + 2) {
                        jRight := jRight + 1
                    }
                    if (snapY >= Y - 2) {
                        kTop := kTop - 1
                    }
                    if (snapBottom <= (Y + H) + 2) {
                        lBottom := lBottom + 1
                    }
                case "PullToGridAll", "SubtractAll":
                    if (snapX <= X + 2) {
                        iLeft := iLeft + 1
                    }
                    if (snapRight >= (X + W) - 2) {
                        jRight := jRight - 1
                    }
                    if (iLeft >= jRight) {
                        iLeft := jRight - 1
                    }
                    if (jRight <= iLeft) {
                        jRight := iLeft + 1
                    }
                    if (snapY <= Y + 2) {
                        kTop := kTop + 1
                    }
                    if (snapBottom >= (Y + H) - 2) {
                        lBottom := lBottom - 1
                    }
                    if (kTop >= lBottom) {
                        kTop := lBottom - 1
                    }
                    if (lBottom <= kTop) {
                        lBottom := kTop + 1
                    }
            }

            ; Ensure minimum of 0 for indices to avoid going off screen left/top
            if (iLeft < 0) {
                jRight -= iLeft  ; Maintain the width
                iLeft := 0
            }
            if (kTop < 0) {
                lBottom -= kTop  ; Maintain the height
                kTop := 0
            }

            ; Re-translate indices into final pixel footprint
            nX := gX + Floor(iLeft / 2) * pX + (Mod(iLeft, 2) == 0 ? 0 : 209)
            nY := gY + Floor(kTop / 2) * pY + (Mod(kTop, 2) == 0 ? 0 : 113)
            nW := (gX + Floor(jRight / 2) * pX + (Mod(jRight, 2) == 0 ? -6 : 209)) - nX
            nH := (gY + Floor(lBottom / 2) * pY + (Mod(lBottom, 2) == 0 ? -6 : 113)) - nY

            SafeMove(nX, nY, nW, nH, hWnd)

        case "JumpGridLeft", "JumpGridRight", "JumpGridUp", "JumpGridDown", "JumpGridTopLeft", "JumpGridTopRight", "JumpGridBottomLeft", "JumpGridBottomRight":
            ; 1. Base Grid Constants
            gX := 15, gY := 15
            pX := 424, pY := 232 ; Pitch spacing (Box width/height + 6px gap)

            ; 2. Fetch Monitor Boundary Data
            hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                ; Compute max valid grid columns and rows fitting inside the screen
                maxCols := Floor((mRight - gX) / pX)
                maxRows := Floor((mBottom - gY) / pY)

                ; 3. Establish Perfect Snap Grid Unit Boundaries First
                cLeft := Round((X - gX) / pX)
                cRight := Round((X + W - gX) / pX)
                rTop := Round((Y - gY) / pY)
                rBottom := Round((Y + H - gY) / pY)

                ; Determine current grid spans (Width and Height in blocks)
                gridUnitsWide := cRight - cLeft
                gridUnitsTall := rBottom - rTop

                ; 4. Execute the Leap Matrix Shift
                switch sCmd, false {
                    case "JumpGridLeft":
                        ; New Right edge equals old Left edge index
                        cRight := cLeft
                        cLeft := cRight - gridUnitsWide

                    case "JumpGridRight":
                        ; New Left edge equals old Right edge index
                        cLeft := cRight
                        cRight := cLeft + gridUnitsWide

                    case "JumpGridUp":
                        ; New Bottom edge equals old Top edge index
                        rBottom := rTop
                        rTop := rBottom - gridUnitsTall

                    case "JumpGridDown":
                        ; New Top edge equals old Bottom edge index
                        rTop := rBottom
                        rBottom := rTop + gridUnitsTall

                    case "JumpGridTopLeft":
                        cRight := cLeft
                        cLeft := cRight - gridUnitsWide
                        rBottom := rTop
                        rTop := rBottom - gridUnitsTall

                    case "JumpGridTopRight":
                        cLeft := cRight
                        cRight := cLeft + gridUnitsWide
                        rBottom := rTop
                        rTop := rBottom - gridUnitsTall

                    case "JumpGridBottomLeft":
                        cRight := cLeft
                        cLeft := cRight - gridUnitsWide
                        rTop := rBottom
                        rBottom := rTop + gridUnitsTall

                    case "JumpGridBottomRight":
                        cLeft := cRight
                        cRight := cLeft + gridUnitsWide
                        rTop := rBottom
                        rBottom := rTop + gridUnitsTall
                }

                ; 5. INTERCEPT & TRIM BOUNDS (If it pushes past the monitor edges)
                ; Left / Top Trimming Clamps
                if (cLeft < 0) {
                    cLeft := 0 ; Pull left edge to screen start, trimming width automatically
                }
                if (rTop < 0) {
                    rTop := 0  ; Pull top edge to screen start, trimming height automatically
                }

                ; Right / Bottom Trimming Clamps
                if (cRight > maxCols) {
                    cRight := maxCols ; Pull right edge to screen end, trimming width automatically
                }
                if (rBottom > maxRows) {
                    rBottom := maxRows ; Pull bottom edge to screen end, trimming height automatically
                }

                ; Guard against collapsing below a 1x1 block
                if (cRight <= cLeft) {
                    cRight := cLeft + 1
                }
                if (rBottom <= rTop) {
                    rBottom := rTop + 1
                }

                ; 6. Translate Final Grid Indices back to exact Pixels
                nX := gX + (cLeft * pX)
                nY := gY + (rTop * pY)
                nW := (cRight - cLeft) * pX - 6
                nH := (rBottom - rTop) * pY - 6

                SafeMove(nX, nY, nW, nH, hWnd)
            }

        ; Legacy Subtract commands are now handled in the unified grid block.


        case "HalfSizeLeft": SafeMove(X, Y, Floor(W / 2), H, hWnd)
        case "HalfSizeRight": SafeMove(X + Floor(W / 2), Y, Floor(W / 2), H, hWnd)
        case "HalfSizeTop": SafeMove(X, Y, W, Floor(H / 2), hWnd)
        case "HalfSizeBottom": SafeMove(X, Y + Floor(H / 2), W, Floor(H / 2), hWnd)

        case "DoubleSizeLeft": SafeMove(X, Y, W * 2, H, hWnd)
        case "DoubleSizeRight": SafeMove(X - W, Y, W * 2, H, hWnd)
        case "DoubleSizeTop": SafeMove(X, Y, W, H * 2, hWnd)
        case "DoubleSizeBottom": SafeMove(X, Y - H, W, H * 2, hWnd)


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
            sHelperPath := A_ScriptDir "\HotWinAHK_tray.ahk"
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
                LogMessage("Success: Focusing Program Manager Shell")
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
            LogMessage("hit FocusDeepestWindow case")

            aList := WinGetList()
            if (aList.Length > 0) {
                LogMessage("hit FocusDeepestWindow case 2")

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
                        LogMessage("Success: Focusing Deepest Window -> " . sTitle)
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
ShutdownEngine() {
    ; Clear any lingering tooltips on the screen instantly
    ToolTip()
    ClearCustomOverlay()

    ; Destroy active window dot indicator
    global g_DotGui
    if (g_DotGui) {
        try g_DotGui.Destroy()
        g_DotGui := ""
    }

    ; Release WinEvent focus tracking hooks safely
    global g_DiagnosticFocusHook, g_OsFocusHookHandle
    if (g_DiagnosticFocusHook) {
        try DllCall("UnhookWinEvent", "ptr", g_DiagnosticFocusHook)
        g_DiagnosticFocusHook := 0
    }
    if (g_OsFocusHookHandle) {
        try DllCall("UnhookWinEvent", "ptr", g_OsFocusHookHandle)
        g_OsFocusHookHandle := 0
    }

    ; Cleanly close any stowed helper sub-scripts and other process instances to release keyboard hook processes
    try {
        DetectHiddenWindows(true)
        currentPID := DllCall("GetCurrentProcessId")
        existingAhkWins := WinGetList("ahk_class AutoHotkey")
        for hAhk in existingAhkWins {
            try {
                thisTitle := WinGetTitle("ahk_id " hAhk)
                thisPID := WinGetPID("ahk_id " hAhk)
                ; Forcefully release and close other instances of any script in our toolkit
                if (thisPID != currentPID && InStr(thisTitle, "HotWinAHK")) {
                    WinClose("ahk_id " hAhk)
                    Sleep(50) ; Give it a brief moment of grace to unload
                    if WinExist("ahk_id " hAhk) {
                        ProcessClose(thisPID)
                    }
                }
            }
        }
    }

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
ToggleSuspension() {
    global g_bSuspended := !g_bSuspended
    try Suspend(g_bSuspended ? 1 : 0)
    PlayToggleSuspensionSound(g_bSuspended)
    ShowTargetToolTip(g_bSuspended ? "Suspended" : "Active")
}
; #endregion
; ----
; #region  _tray 
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
    sHelperPath := A_ScriptDir "\HotWinAHK_tray.ahk"
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
RestoreRegistryWindow(hWndToRestore) {
    global g_mHiddenWindowsRegistry

    if WinExist(hWndToRestore) {
        sHelperPath := A_ScriptDir "\HotWinAHK_tray.ahk"
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
CloseHiddenTrayWindow(hWnd) {
    if WinExist(hWnd) {
        WinClose(hWnd)
    }
    TrayIconDelete(hWnd)
}
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
; #endregion

; #region  _menu 
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

        LogMessage("SUCCESS: Menu code completed execution cycle safely.")

    } catch Error as e {
        LogMessage("CRASH DETAILS: Line [" . e.Line . "] - " . e.Message)
    }
}
FocusNativeMenuHandle() {
    hMenuWnd := WinExist("ahk_class #32768")
    if (hMenuWnd) {
        DllCall("user32.dll\SetForegroundWindow", "Ptr", hMenuWnd)
    }
}
; #endregion

; #region  _tooltip 
ShowTargetToolTip(sText, duration := -1800) {
    global g_OverlayGui
    
    ; Cancel any existing timer
    try SetTimer(ClearCustomOverlay, 0)
    
    ; If the GUI exists, destroy it
    if (g_OverlayGui != "") {
        try g_OverlayGui.Destroy()
        g_OverlayGui := ""
    }
    
    ; Split input into lines
    lines := StrSplit(sText, "`n")
    maxLen := 0
    for line in lines {
        if (StrLen(line) > maxLen) {
            maxLen := StrLen(line)
        }
    }
    
    ; Set minimum/maximum width/height constraints
    estWidth := Integer(maxLen * 8.5) + 40
    if (estWidth < 260)
        estWidth := 260
    if (estWidth > 750)
        estWidth := 750
        
    lineCount := lines.Length
    estHeight := lineCount * 22 + 35
    if (estHeight < 65)
        estHeight := 65
    
    ; Create a highly polished, elegant center screen overlay (dark/black theme with pretty icon)
    g_OverlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    g_OverlayGui.BackColor := "121214" ; Deep premium dark charcoal
    
    ; Select pretty icon depending on the message context
    iconChar := "🤖"
    iconColor := "00FFCC" ; Vibrant cyan
    if (InStr(sText, "Save") || InStr(sText, "Saved") || InStr(sText, "Added")) {
        iconChar := "✔"
        iconColor := "00FF55" ; Radiant neon green
    } else if (InStr(sText, "Clear") || InStr(sText, "Delete") || InStr(sText, "Remove") || InStr(sText, "cancelled") || InStr(sText, "cancelled.")) {
        iconChar := "✕"
        iconColor := "FF3366" ; Vibrant ruby coral
    } else if (InStr(sText, "Suspended")) {
        iconChar := "⏸"
        iconColor := "FFCC00" ; Cyber Amber
    } else if (InStr(sText, "Active") || InStr(sText, "Restore") || InStr(sText, "restored")) {
        iconChar := "▶"
        iconColor := "00FF55" ; Radiant neon green
    } else if (InStr(sText, "Error") || InStr(sText, "Failed")) {
        iconChar := "⚠️"
        iconColor := "FF3366" ; Ruby coral
    } else if (InStr(sText, "AlwaysOnTop")) {
        iconChar := "📌"
        iconColor := "00FFFF" ; Cool Cyan
    } else if (InStr(sText, "Running") || InStr(sText, "Re-Compile") || InStr(sText, "RUNNING ENGINE ACTION")) {
        iconChar := "⚡"
        iconColor := "FFCC00" ; Cyber Amber
    } else if (InStr(sText, "Home")) {
        iconChar := "🏠"
        iconColor := "00FFFF" ; Ambient Cyan
    }
    
    ; Icon Placement
    g_OverlayGui.SetFont("s18 c" . iconColor, "Segoe UI Symbol")
    g_OverlayGui.AddText("x22 y" . ((estHeight - 34) // 2) . " w32 h35 Center", iconChar)
    
    ; Message Text Box
    g_OverlayGui.SetFont("s10.5 w600 cFFFFFF", "Segoe UI")
    g_OverlayGui.AddText("x64 y" . ((estHeight - (lineCount * 21)) // 2) . " w" . estWidth . " h" . (lineCount * 22), sText)
    
    ; Accent Bottom Border
    g_OverlayGui.AddProgress("x0 y" . (estHeight - 3) . " w" . (estWidth + 92) . " h3 Background121214 c" . iconColor, 100)
    
    ; Show Centered
    guiW := Integer(estWidth + 92)
    guiH := Integer(estHeight)
    posX := Integer((A_ScreenWidth - guiW) // 2)
    posY := Integer((A_ScreenHeight - guiH) // 2)
    
    g_OverlayGui.Show("x" . posX . " y" . posY . " w" . guiW . " h" . guiH . " NoActivate")
    
    if (duration < 0) {
        SetTimer(ClearCustomOverlay, duration)
    }
}
ClearToolTip() {
    ToolTip()
    ClearCustomOverlay()
}
ClearCustomOverlay() {
    global g_OverlayGui
    if (g_OverlayGui != "") {
        try g_OverlayGui.Destroy()
        g_OverlayGui := ""
    }
}
; #endregion
; ----
; #region  _helpers 
ForceOpaqueWindowReset(hWnd) {
    global g_hOpacityActiveHWND

    if !WinExist(hWnd)
        return

    ; --- LOG TITLING ENGINE ---
    try {
        sTitle := WinGetTitle(hWnd)
        if (sTitle != "")
            LogMessage(sTitle)
        else
            LogMessage("No Window Title Found")
    } catch {
        LogMessage("Error Extracting Window Title")
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
SafeMove(nX, nY, nW := -1, nH := -1, targetHwnd := "") {
    global g_TuckedWindows

    static s_DiagnosticOutputHistory := ""

    if (targetHwnd != "" && WinExist("ahk_id " . targetHwnd)) {
        RecordWindowHistory(targetHwnd)
    }

    ; Fetch metadata of the target window frame container before any code runs
    targetTitle := "UNKNOWN"
    targetClass := "UNKNOWN"

    try {
        if WinExist("ahk_id " . targetHwnd) {
            targetTitle := WinGetTitle(targetHwnd)
            targetClass := WinGetClass(targetHwnd)
        }
    }

    ; Package log input metrics details into a flat string buffer array block
    logText := "--- SAFEMOVE INCOMING INPUT LOG ---`n"
    logText .= "Timestamp:       " . A_Hour . ":" . A_Min . ":" . A_Sec . "." . A_MSec . "`n"
    logText .= "Target HWND:     " . targetHwnd . "`n"
    logText .= "Window Class:    " . targetClass . "`n"
    logText .= "Window Title:    " . targetTitle . "`n"
    logText .= "Input nX:        " . nX . "`n"
    logText .= "Input nY:        " . nY . "`n"
    logText .= "Input nW (Raw):  " . nW . "`n"
    logText .= "Input nH (Raw):  " . nH . "`n`n"

    s_DiagnosticOutputHistory := s_DiagnosticOutputHistory . logText

    try {
        ; Flush the accumulated RAM history string to the Logfile
        LogMessage(s_DiagnosticOutputHistory)
        s_DiagnosticOutputHistory := "" ; Reset memory after flushing
    } catch {
        noticeText := "Disk I/O collision detected on this tick.`nSafeMove is caching log entries in RAM.`nRetrying flush pass on next edge tick..."
        ShowTargetToolTip("LOG WRITE FAILED! (Disk I/O collision)`n`n" . noticeText, -2500)
    }

    if (targetHwnd == "" || !WinExist("ahk_id " . targetHwnd)) {
        return false
    }

    realW := Number(nW)
    realH := Number(nH)

    ; HARDENED PROFILE BACKUP RESCUE LAYER WITH DIMENSION PRESERVATION
    if (realW <= 0 || realH <= 0 || realW == -1 || realH == -1) {
        try {
            WinGetPos(, , &currW, &currH, targetHwnd)
            if (realW <= 0 || realW == -1) {
                realW := Number(currW)
            }
            if (realH <= 0 || realH == -1) {
                realH := Number(currH)
            }
        } catch {
            if (g_TuckedWindows.Has(targetHwnd)) {
                profile := g_TuckedWindows[targetHwnd]
                realW := Number(profile.w)
                realH := Number(profile.h)
            }
        }
    }

    ; Final absolute default safety limits to prevent zero pixel layout crashes
    if (realW <= 0) {
        realW := 800
    }

    if (realH <= 0) {
        realH := 600
    }

    realX := Number(nX)
    realY := Number(nY)

    try {
        ; Execute the physical window movement with guaranteed non-zero profile metrics
        WinMove(realX, realY, realW, realH, targetHwnd)
        return true
    } catch {
        return false
    }
}
MouseGetWindowHWND() {
    MouseGetPos , , &hWnd
    return hWnd
}
; #endregion

; #region  _events
CheckScreenEdgeBumps() {
    global g_ActiveUntuckedHwnd, g_BumpVelocityThreshold, g_BumpEdgeZonePixels, g_ResetBumpMemory, g_bSuspended
    
    if (g_bSuspended) {
        return
    }
    
    ; --- THE STATIC MEMORY ANCHORS ---
    ; Using static primitive numbers completely eliminates array type crashes!
    static s_PrevX := -1
    static s_PrevY := -1
    
    if (g_ActiveUntuckedHwnd != 0) {
        return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)

    ; If the retuck handler flipped the reset flag, instantly flush out your anchors
    if (g_ResetBumpMemory) {
        s_PrevX := mX
        s_PrevY := mY
        g_ResetBumpMemory := false
        return
    }

    ; Seed the coordinates safely on the very first execution pass
    if (s_PrevX == -1 && s_PrevY == -1) {
        s_PrevX := mX
        s_PrevY := mY
        return
    }

    ; Calculate direction vectors directly from your locked internal memory coordinates
    deltaX := mX - s_PrevX
    deltaY := mY - s_PrevY

    ; Update internal static memory anchors immediately for the next interval cycle
    s_PrevX := mX
    s_PrevY := mY

    activeHWnd := DllCall("GetForegroundWindow", "ptr")
    if (activeHWnd == 0) {
        return
    }
    
    hMon := DllCall("MonitorFromWindow", "ptr", activeHWnd, "uint", 2, "ptr")
    MI := Buffer(40)
    NumPut("uint", 40, MI, 0)
    
    if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
        mLeft   := NumGet(MI, 20, "int")
        mTop    := NumGet(MI, 24, "int")
        mRight  := NumGet(MI, 28, "int")
        mBottom := NumGet(MI, 32, "int")

        ; Dynamic registry zones pull directly from your central global parameter width boxes
        isLeftZone   := (mX >= mLeft && mX <= mLeft + g_BumpEdgeZonePixels)
        isRightZone  := (mX >= mRight - g_BumpEdgeZonePixels && mX <= mRight)
        isTopZone    := (mY >= mTop && mY <= mTop + g_BumpEdgeZonePixels)
        isBottomZone := (mY >= mBottom - g_BumpEdgeZonePixels && mY <= mBottom)

        ; --- INSTANT VELOCITY CHECK ---
        ; Measures raw pixel acceleration traveled over the last 25ms interval cycle
        rawDistance := ((deltaX * deltaX) + (deltaY * deltaY)) ** 0.5
        pixelDistance := Integer(rawDistance)

        isBumping := false
        
        if (isLeftZone && deltaX < 0 && pixelDistance >= g_BumpVelocityThreshold) {
            isBumping := true
        }
        
        if (isRightZone && deltaX > 0 && pixelDistance >= g_BumpVelocityThreshold) {
            isBumping := true
        }
        
        if (isTopZone && deltaY < 0 && pixelDistance >= g_BumpVelocityThreshold) {
            isBumping := true
        }
        
        if (isBottomZone && deltaY > 0 && pixelDistance >= g_BumpVelocityThreshold) {
            isBumping := true
        }

        if (isBumping) {
            ; Terminate this polling thread instantly to protect layout rendering
            SetTimer(CheckScreenEdgeBumps, 0)
            
            ; Reset tracking metrics so your very next pass seeds cleanly on retuck
            s_PrevX := -1
            s_PrevY := -1
            
            ; Success confirmation beep tone
            SoundBeep(1200, 60)
            
            ExecuteCommandRegistry("BumpEdgeUntuck", activeHWnd)
        }
    }
}
HandleGlobalFocusChangeEvent(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global g_ActiveUntuckedHwnd, g_OsFocusHookHandle, g_IsUntuckLocked

    ; HARDENED SAFETY GATE: If our own script layout macro is actively repositioning a window,
    ; completely ignore the message to break the recursive fluttering/retuck loops!
    if (g_IsUntuckLocked) {
        return
    }

    ; If a window is currently untucked, and a valid window focus change event occurs
    if (g_ActiveUntuckedHwnd != 0 && idObject == 0 && hwnd != g_ActiveUntuckedHwnd) {

        ; Unregister the OS focus hook immediately
        if (g_OsFocusHookHandle) {
            DllCall("UnhookWinEvent", "ptr", g_OsFocusHookHandle)
            g_OsFocusHookHandle := 0
        }

        ; Execute the retuck sequence
        ExecuteRetuckSequence(g_ActiveUntuckedHwnd)
    }
}
; #endregion

; #region  _tucks 
MonitorUntuckedMouseExit() {
    global g_ActiveUntuckedHwnd, g_TuckedWindows

    ; Break early if tracking pointer is unassigned or window was closed/destroyed
    if (g_ActiveUntuckedHwnd == 0 || !WinExist("ahk_id " g_ActiveUntuckedHwnd)) {
        SetTimer(MonitorUntuckedMouseExit, 0)
        return
    }

    try {
        ; HARDENED WIN32 API FOCUS CHECK: Natively get the raw system foreground window handle
        currentActiveHWnd := DllCall("GetForegroundWindow", "ptr")

        ; RETUCK TRIGGER: The moment the raw active window changes to ANY window but our untucked one
        if (currentActiveHWnd != g_ActiveUntuckedHwnd) {

            SetTimer(MonitorUntuckedMouseExit, 0) ; Turn off tracking loop explicitly by name

            hMon := DllCall("MonitorFromWindow", "ptr", g_ActiveUntuckedHwnd, "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)

            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft := NumGet(MI, 20, "int")
                mTop := NumGet(MI, 24, "int")
                mRight := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")

                data := g_TuckedWindows[g_ActiveUntuckedHwnd]

                ; Read its current dimensions to compute the tucked offset handle position
                WinGetPos(, , &wW, &wH, g_ActiveUntuckedHwnd)

                nX := mLeft, nY := mTop
                switch data.edge {
                    case "Left": nX := mLeft - data.w + 5
                    case "Right": nX := mRight - 5
                    case "Top": nY := mTop - data.h + 5
                    case "Bottom": nY := mBottom - 5
                }

                ; Slide the window safely back into its hidden 5px border handle
                WinMove(nX, nY, data.w, data.h, g_ActiveUntuckedHwnd)
                g_ActiveUntuckedHwnd := 0
            }
        }
    } catch {
        SetTimer(MonitorUntuckedMouseExit, 0)
        g_ActiveUntuckedHwnd := 0
    }
}
DestroyUntuckCooldownFlag() {
    global g_UntuckCooldown
    g_UntuckCooldown := false
}
ExecuteRetuckSequence(targetHwnd) {
    global g_ActiveUntuckedHwnd, g_TuckedWindows, g_IsUntuckLocked

    if (!WinExist("ahk_id " targetHwnd)) {
        return
    }

    try {
        ; Activate safety latch while sliding the window back off-screen
        g_IsUntuckLocked := true

        hMon := DllCall("MonitorFromWindow", "ptr", targetHwnd, "uint", 2, "ptr")
        MI := Buffer(40)
        NumPut("uint", 40, MI, 0)

        if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
            mLeft := NumGet(MI, 20, "int")
            mTop := NumGet(MI, 24, "int")
            mRight := NumGet(MI, 28, "int")
            mBottom := NumGet(MI, 32, "int")

            tuckProfile := g_TuckedWindows[targetHwnd]

            nX := Number(tuckProfile.x)
            nY := Number(tuckProfile.y)

            switch tuckProfile.edge {
                case "Left": nX := mLeft - Number(tuckProfile.w) + 5
                case "Right": nX := mRight - 5
                case "Top": nY := mTop - Number(tuckProfile.h) + 5
                case "Bottom": nY := mBottom - 5
            }

            ; Slide window back into its clean 5px border handle using saved shapes
            SafeMove(nX, nY, Number(tuckProfile.w), Number(tuckProfile.h), targetHwnd)

            g_ActiveUntuckedHwnd := 0
        }

        ; Turn off safety latch: layout adjustment finished cleanly
        g_IsUntuckLocked := false
    } catch {
        g_IsUntuckLocked := false
        g_ActiveUntuckedHwnd := 0
    }
}
TrackUntuckedFocusLifecycle() {
    global g_ActiveUntuckedHwnd, g_TuckedWindows, g_BaselineActiveWindow, g_UntuckGraceTicks, g_TuckedVisiblePixels, g_ResetBumpMemory, g_PeekX, g_PeekY
    
    ; 1. VALIDATION GATE: Break out safely if tracking pointer is unassigned
    if (g_ActiveUntuckedHwnd == 0 || !WinExist("ahk_id " . g_ActiveUntuckedHwnd)) {
        SetTimer(TrackUntuckedFocusLifecycle, 0)
        g_UntuckGraceTicks := 0
        g_ResetBumpMemory := true
        SetTimer(ExecuteCleanBumperReArm, -200)
        return
    }

    ; --- THE DELAYED DEACTIVATION GRACE PERIOD SHIELD ---
    ; If our countdown latch is still active, tick it down and exit early!
    ; This forces the window to stay locked wide open on your screen canvas.
    if (g_UntuckGraceTicks > 0) {
        g_UntuckGraceTicks := g_UntuckGraceTicks - 1
        return
    }

    try {
        ; Query the Win32 kernel directly for the true active foreground window handle
        currentForeground := DllCall("GetForegroundWindow", "ptr")
        
        ; Query mouse coordinates and the window handle beneath cursor
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY, &mHwnd)

        ; Retrieve top-level root window ancestor of the hovered window to handle child controls
        mRoot := mHwnd ? DllCall("GetAncestor", "ptr", mHwnd, "uint", 2, "ptr") : 0

        isHovered := (mHwnd == g_ActiveUntuckedHwnd || mRoot == g_ActiveUntuckedHwnd)
        isActive := (currentForeground == g_ActiveUntuckedHwnd)

        ; 2. HARDENED DUAL-ANCHOR PROTECTION: Stay wide open while focus is in the untucked
        ; window, OR while the mouse is hovering over it, OR a transitional 0 state!
        if (isHovered || isActive || currentForeground == 0) {
            return
        }
        
        ; Filter out hidden background system popups, wallpaper updates, and taskbar refreshes
        try {
            if (WinGetTitle(currentForeground) == "") {
                return 
            }
        } catch {
            return
        }

        ; ==============================================================================
        ; DETERMINISTIC RETUCK TRIGGER: Focus has definitively switched to a new application!
        ; ==============================================================================
        SetTimer(TrackUntuckedFocusLifecycle, 0) ; Kill this tracking loop thread immediately
        
        hMon := DllCall("MonitorFromWindow", "ptr", g_ActiveUntuckedHwnd, "uint", 2, "ptr")
        MI := Buffer(40)
        NumPut("uint", 40, MI, 0)
        
        if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
            mLeft   := NumGet(MI, 20, "int")
            mTop    := NumGet(MI, 24, "int")
            mRight  := NumGet(MI, 28, "int")
            mBottom := NumGet(MI, 32, "int")

            tuckProfile := g_TuckedWindows[g_ActiveUntuckedHwnd]
            
            finalGridW := Number(tuckProfile.w)
            finalGridH := Number(tuckProfile.h)
            nX         := Number(tuckProfile.x)
            nY         := Number(tuckProfile.y)
            
            switch tuckProfile.edge {
                case "Left":
                    nX := mLeft - finalGridW + g_TuckedVisiblePixels
                
                case "Right":
                    nX := mRight - g_TuckedVisiblePixels
                
                case "Top":
                    nY := mTop - finalGridH + g_TuckedVisiblePixels
                
                case "Bottom":
                    nY := mBottom - g_TuckedVisiblePixels
            }
            
            ; Slide window back into your custom global visibility handle slot safely
            SafeMove(nX, nY, finalGridW, finalGridH, g_ActiveUntuckedHwnd)
            
            ; --- THE RE-ARM ROUTING TRIGGER ---
            ; Clear your main tracking handle variable
            g_ActiveUntuckedHwnd := 0
            
            ; Engage the explicit reset flag so the loop flushes its memory blocks
            g_ResetBumpMemory := true
            
            ; Launch a single-execution timer to fire our dedicated re-arm handler in 200ms
            SetTimer(ExecuteCleanBumperReArm, -200)
        }
    } catch {
        SetTimer(TrackUntuckedFocusLifecycle, 0)
        g_ActiveUntuckedHwnd := 0
        g_ResetBumpMemory := true
        SetTimer(ExecuteCleanBumperReArm, -200)
    }
}
ExecuteCleanBumperReArm() {
    ; Wake the core 25ms mouse-polling loop back up cleanly on a dedicated thread lane!
    SetTimer(CheckScreenEdgeBumps, 25)
}

; #region  _helpscreen
ShowHelpScreen(hWnd := 0) {
    static helpGui := ""
    
    ; If Gui already exists, just show it and bring it to front
    if (helpGui != "") {
        try {
            if (WinExist("ahk_id " helpGui.Hwnd)) {
                helpGui.Show()
                WinActivate("ahk_id " helpGui.Hwnd)
                return
            }
        }
        helpGui := ""
    }

    ; Create a highly polished, dark themed AHK v2 GUI window conforming exactly to user color scheme and dimensions
    helpGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "🤖 HotWinAHK - Commands & Gestures Reference")
    helpGui.BackColor := "121214"
    helpGui.SetFont("s10 cE0E0E6", "Segoe UI")

    ; Header Display Heading (Visual Accent & Typography Pairing)
    helpGui.SetFont("s16 bold c00FFCC", "Segoe UI")
    helpGui.Add("Text", "w940 Center x30 y15", "HotWinAHK Command Matrix & Keybindings")
    helpGui.SetFont("s9 c8A8A93", "Segoe UI")
    helpGui.Add("Text", "w940 Center x30 y+4", "Precision Window Management & Gesture Edge-Docking Suite")

    ; --- 3-COLUMN REFERENCE MATRIX (ABOVE THE LOOKUP GRID) ---
    helpGui.Add("GroupBox", "x30 y60 w360 h170 c55555C", "NUMPAD MATRIX")
    helpGui.Add("GroupBox", "x410 y60 w260 h170 c55555C", "ARROW MOVEMENT")
    helpGui.Add("GroupBox", "x690 y60 w280 h170 c55555C", "MOUSE ACTIONS")

    ; --- COLUMN 1: NUMPAD ---
    helpGui.SetFont("s9 norm cE0E0E6", "Segoe UI")
    helpGui.Add("Text", "x45 y80 w140", "MoveToGrid")
    helpGui.Add("Text", "x200 y80 w180", "Numpad 1-9")

    helpGui.SetFont("s9 bold c00FFFF", "Segoe UI")
    helpGui.Add("Text", "x45 y98 w140", "JumpGrid")
    helpGui.Add("Text", "x200 y98 w180", "Alt + Numpad 1-9")

    helpGui.SetFont("s9 bold cFF4444", "Segoe UI")
    helpGui.Add("Text", "x45 y116 w140", "Edge")
    helpGui.Add("Text", "x200 y116 w180", "Ctrl + Numpad 1-9")

    helpGui.SetFont("s9 bold c00FFCC", "Segoe UI")
    helpGui.Add("Text", "x45 y134 w140", "StretchToGrid")
    helpGui.Add("Text", "x200 y134 w180", "Win + Numpad 1-9")

    helpGui.SetFont("s9 bold c00FFFF", "Segoe UI")
    helpGui.Add("Text", "x45 y152 w140", "PullToGrid")
    helpGui.Add("Text", "x200 y152 w180", "Win + Alt + Numpad")

    helpGui.SetFont("s9 bold cFF4444", "Segoe UI")
    helpGui.Add("Text", "x45 y170 w140", "Stretch")
    helpGui.Add("Text", "x200 y170 w180", "Win + Ctrl + Numpad")

    helpGui.SetFont("s9 norm cE0E0E6", "Segoe UI")
    helpGui.Add("Text", "x45 y188 w140", "SnapToGridEnlarge/Shrink")
    helpGui.Add("Text", "x200 y188 w180", "Add / Subtract")

    helpGui.SetFont("s9 bold cFF4444", "Segoe UI")
    helpGui.Add("Text", "x45 y206 w140", "ScaleExpand/Reduce")
    helpGui.Add("Text", "x200 y206 w180", "Ctrl + Add / Subtract")

    ; --- COLUMN 2: ARROW MOVEMENT ---
    helpGui.SetFont("s9 bold c4476ff", "Segoe UI")
    helpGui.Add("Text", "x425 y80 w110", "MoveTad")
    helpGui.Add("Text", "x545 y80 w110", "Win + Alt + Arrows")

    helpGui.SetFont("s9 bold cFFCC00", "Segoe UI")
    helpGui.Add("Text", "x425 y98 w110", "Movepx")
    helpGui.Add("Text", "x545 y98 w110", "Win + Shift + Arrows")

    helpGui.SetFont("s9 bold c44FF44", "Segoe UI")
    helpGui.Add("Text", "x425 y116 w110", "Add (Grow)")
    helpGui.Add("Text", "x545 y116 w110", "Win+Alt+Shift+Arrows")

    helpGui.SetFont("s9 bold cCC66FF", "Segoe UI")
    helpGui.Add("Text", "x425 y134 w110", "Sub (Shrink)")
    helpGui.Add("Text", "x545 y134 w110", "Win+Ctrl+Alt+Arrows")

    helpGui.SetFont("s9 norm cE0E0E6", "Segoe UI")
    helpGui.Add("Text", "x425 y152 w110", "Trim")
    helpGui.Add("Text", "x545 y152 w110", "Win + Alt + Arrows")

    ; --- COLUMN 3: MOUSE ACTIONS ---
    helpGui.SetFont("s9 norm cE0E0E6", "Segoe UI")
    helpGui.Add("Text", "x705 y80 w100", "ToGrid")
    helpGui.Add("Text", "x815 y80 w140", "Win + MButton")

    helpGui.Add("Text", "x705 y98 w100", "RelativeSize")
    helpGui.Add("Text", "x815 y98 w140", "Win + LButton")

    ; --- INTERACTION SEPARATOR ---
    helpGui.Add("Text", "w940 h1 Background3A3A3D x30 y242", "")

    ; Live Dynamic Filter Box Row
    helpGui.SetFont("s10 bold c00FFCC", "Segoe UI")
    helpGui.Add("Text", "w100 x30 y255 h24 +0x200", "Live Filter:")
    helpGui.SetFont("s10 norm cFFFFFF", "Segoe UI")
    searchBox := helpGui.Add("Edit", "w400 x115 y255 Background1E1E22 cFFFFFF Border r1 h24", "")
    
    helpGui.SetFont("s9 c8A8A93", "Segoe UI")
    helpGui.Add("Text", "w320 x650 y255 h24 +0x200 Right", "Press [ESC] at any time to close")

    ; Create the Main ListView
    helpGui.SetFont("s10 cE0E0E6", "Segoe UI")
    helpLV := helpGui.Add("ListView", "x30 y290 w940 h350 Background111112 cFFFFFF +Grid -Multi -ReadOnly", ["Category", "Action Command", "Trigger Key combo", "Functional Description"])
    
    helpLV.ModifyCol(1, 140) ; Category
    helpLV.ModifyCol(2, 150) ; Action Command
    helpLV.ModifyCol(3, 160) ; Trigger Key combo
    helpLV.ModifyCol(4, 490) ; Functional Description

    ; Populate rows based on global list
    localHelpRows := GetGlobalCommandList()

    ; Function to populate rows based on a search term
    PopulateLV(searchTerm := "") {
        helpLV.Opt("-Redraw")
        helpLV.Delete()
        
        for row in localHelpRows {
            ; FILTER OUT ARROWS AND NUMPAD COMBOS FROM LIST
            if (RegExMatch(row.key, "i)Arrows|Arrow|Left|Right|Up|Down|Numpad|Add|Sub|Subtract")) {
                continue
            }
            if (searchTerm != "") {
                if (!InStr(row.cat, searchTerm) && !InStr(row.cmd, searchTerm) && !InStr(row.key, searchTerm) && !InStr(row.desc, searchTerm)) {
                    continue
                }
            }
            helpLV.Add("", row.cat, row.cmd, row.key, row.desc)
        }
        helpLV.Opt("+Redraw")
    }

    ; Populate initial list with all elements
    PopulateLV()

    ; Connect search box change event to live filtering
    searchBox.OnEvent("Change", (ctrl, *) => PopulateLV(ctrl.Value))

    ; Setup footer button and label
    helpGui.SetFont("s9 bold cFF4444", "Segoe UI")
    exitBtn := helpGui.Add("Button", "x30 y660 w240 h30", "Exit HotWinAHK Completely")
    exitBtn.OnEvent("Click", (*) => ShutdownEngine())
    
    helpGui.SetFont("s9 c8A8A93", "Segoe UI")
    helpGui.Add("Text", "x290 y660 w680 h30 +0x200", "Note: Window Nudger runs continuously in the background. Press Win+Alt+X or click Exit to unload.")

    ; Setup closure behaviors
    helpGui.OnEvent("Escape", (*) => (helpGui.Destroy(), helpGui := ""))
    helpGui.OnEvent("Close", (*) => (helpGui.Destroy(), helpGui := ""))

    ; Render on screen
    helpGui.Show("w1000 h720 Center")
}

GetGlobalCommandList() {
    static commandList := [
        ; == SYSTEM ==
        {cat: "SYSTEM", cmd: "HelpScreen", key: "Win + /", desc: "Display this interactive keyboard command reference panel."},
        {cat: "SYSTEM", cmd: "CmdPalette", key: "Win + Ctrl + Shift + C", desc: "Display the interactive fuzzy-search Command Palette for manual trigger / dry run testing."},
        {cat: "SYSTEM", cmd: "WinInfo", key: "Win + Ctrl + /", desc: "Display active window physical bounds, handle ID, class, and executable name."},
        {cat: "SYSTEM", cmd: "PeekUnderMouse", key: "Double + LWin + P", desc: "Display class of window beneath mouse cursor."},
        {cat: "SYSTEM", cmd: "CopyCommands", key: "Win + Ctrl + C", desc: "Copy all available action commands sorted by category to clipboard."},
        {cat: "SYSTEM", cmd: "CopyBindings", key: "Win + Alt + C", desc: "Copy active keybindings dictionary map to clipboard."},
        {cat: "SYSTEM", cmd: "CopyCommandsHelp", key: "Win + Ctrl + Shift + H", desc: "Copy all categorized action commands with full explanations to clipboard."},
        {cat: "SYSTEM", cmd: "CopyCommandsAlpha", key: "Win + Ctrl + Shift + A", desc: "Copy all available action commands sorted alphabetically to clipboard."},
        {cat: "SYSTEM", cmd: "CopyBindingsAlpha", key: "Win + Ctrl + Shift + B", desc: "Copy active keybindings map sorted alphabetically by command name to clipboard."},
        {cat: "SYSTEM", cmd: "CopyBindingsLocation", key: "Win + Ctrl + Shift + L", desc: "Copy active keybindings map grouped by keyboard hardware location to clipboard."},
        {cat: "SYSTEM", cmd: "SysMenu", key: "Win + Ctrl + Shift + S", desc: "Show popup menu of all system commands to quickly select and run."},
        {cat: "SYSTEM", cmd: "ToggleSuspension", key: "Win + Alt + S", desc: "Suspend or resume all HotWinAHK modifier triggers instantly."},
        {cat: "SYSTEM", cmd: "ReloadConfig", key: "Win + F12", desc: "Hot-reload preferences from HotWinAHK.ini and compile hotkeys dynamically."},
        {cat: "SYSTEM", cmd: "EditConfig", key: "Win + Alt + E", desc: "Open HotWinAHK.ini configurations in system default text editor."},
        {cat: "SYSTEM", cmd: "ExitProgram", key: "Win + Alt + X", desc: "Safely terminate the HotWinAHK background orchestrator process."},
        {cat: "SYSTEM", cmd: "RestartProgram", key: "Win + Ctrl + F12", desc: "Instantly reload and reboot the HotWinAHK execution engine."},
        {cat: "SYSTEM", cmd: "KeyDiagnostics", key: "Win + Ctrl + Shift + K", desc: "Verify and test physical modifier combos on keypad and arrow keys."},
        {cat: "SYSTEM", cmd: "KeyQuery", key: "Win + Ctrl + Shift + Q", desc: "Fuzzy query real-time keyboard strokes to identify active command bindings."},
        {cat: "SYSTEM", cmd: "Settings", key: "Win + Ctrl + Shift + I", desc: "Open the interactive configurations panel to customize sounds, clicks, and tooltips."},
        {cat: "SYSTEM", cmd: "Active Window Dot", key: "Auto Indicator", desc: "Draws green dot at active window's top-left (yellow when program is suspended)."},

        ; == WINDOW ==
        {cat: "WINDOW", cmd: "AlwaysOnTop", key: "Win + Ctrl + T", desc: "Toggle Always-On-Top focus pinning attribute on active window frame."},
        {cat: "WINDOW", cmd: "SetOpacity70", key: "Win + Shift + O", desc: "Set alpha opacity transparency level to 70% on active window frame."},
        {cat: "WINDOW", cmd: "RemoveOpacity", key: "Win + Alt + Shift + O", desc: "Restore active window opacity to full solid visibility."},
        {cat: "WINDOW", cmd: "SendToBack", key: "Win + Backspace", desc: "Push active window frame to the bottom of the active desktop stack."},
        {cat: "WINDOW", cmd: "MinimizeToTray", key: "Win + Shift + PgDn", desc: "Stow active window into an autonomous system-tray notification process."},
        {cat: "WINDOW", cmd: "PickFromTray", key: "Win + Shift + PgUp", desc: "Open stowed window tray instances via right-click contextual list."},
        {cat: "WINDOW", cmd: "DragWindow", key: "Win + F6", desc: "Initiate DragWindow mode: Make window and ones above translucent, move with cursor, click/Enter to place, Esc to cancel."},
        {cat: "WINDOW", cmd: "RestoreAll", key: "Win + [", desc: "Restore all desktop windows back to normal size, regardless of maximized/minimized status (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "RestoreAllMinimized", key: "Win + Ctrl + [", desc: "Selectively restore minimized windows back to normal size while leaving maximized windows locked (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "MaximizeAll", key: "Win + ]", desc: "Symmetrically maximize all open windows, irrespective of whether they are minimized or restored (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "RestoreAllMaximized", key: "Win + Ctrl + Alt + Shift + [", desc: "Restore all maximized windows to normal size (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "MaximizeAllRestored", key: "Win + Ctrl + Alt + ]", desc: "Maximize all normal/restored windows (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "MaximizeAllMinimized", key: "Win + Ctrl + Alt + Shift + ]", desc: "Maximize all minimized windows (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "SwapMaximizedRestored", key: "Win + Shift + ]", desc: "Swap window states: restore maximized; maximize normal/restored (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "SwapMinimizedRestored", key: "Win + Shift + -", desc: "Swap window states: restore minimized; minimize normal/restored (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "MinimizeAll", key: "Win + -", desc: "Minimize all normal and maximized windows (excludes docked, hidden or trayed bounds)."},
        {cat: "WINDOW", cmd: "MinimizeAllRestored", key: "Win + Ctrl + Alt + -", desc: "Minimize all normal/restored windows (excludes docked, hidden or trayed)."},
        {cat: "WINDOW", cmd: "MinimizeAllMaximized", key: "Win + Ctrl + Alt + Shift + -", desc: "Minimize all maximized windows (excludes docked, hidden or trayed)."},

        ; == HOME ==
        {cat: "HOME", cmd: "SetHome", key: "Win + Ctrl + .", desc: "Save active window class/process/fuzzy title signature to persistent home location."},
        {cat: "HOME", cmd: "ClearHome", key: "Win + Ctrl + Shift + .", desc: "Delete saved home location configuration for active window."},
        {cat: "HOME", cmd: "GoHome", key: "Win + Alt + .", desc: "Relocate window to its persistent home position."},
        {cat: "HOME", cmd: "Home", key: "Win + .", desc: "Intelligent Home behavior: Move to home, or restore to pre-homed, or strip home config upon confirmation."},
        {cat: "HOME", cmd: "HomePeek", key: "Win + Shift + .", desc: "Momentarily draw a transparent overlay footprint of the window's home location on screen."},

        ; == FOCUS ==
        {cat: "FOCUS", cmd: "NextWindow", key: "Win + PgUp", desc: "Cycle focus smoothly forward across open desktop window frames."},
        {cat: "FOCUS", cmd: "PrevWindow", key: "Win + PgDn", desc: "Cycle focus smoothly backward across open desktop window frames."},
        {cat: "FOCUS", cmd: "NextClassWindow", key: "Win + Alt + PgUp", desc: "Cycle focus specifically forward between windows of identical process class."},
        {cat: "FOCUS", cmd: "PrevClassWindow", key: "Win + Alt + PgDn", desc: "Cycle focus specifically backward between windows of identical process class."},
        {cat: "FOCUS", cmd: "FocusDeepestWindow", key: "Win + Ctrl + Backspace", desc: "Activate the deepest window in the Z-order list."},
        {cat: "FOCUS", cmd: "WindowPicker", key: "Win + Ctrl + Tab", desc: "Fuzzy-search and filter active GUI windows, instantly focusing selected window."},
        {cat: "FOCUS", cmd: "Desk3d", key: "Win + Ctrl + D", desc: "Enable 3D workspace parallax rotation mode, shifting restored windows based on multi-layered depth."},
        {cat: "FOCUS", cmd: "WindowHistoryPrev", key: "Win + Alt + Backspace", desc: "Go to the active window's previous position and state in history."},
        {cat: "FOCUS", cmd: "WindowHistoryNext", key: "Win + Alt + Shift + Backspace", desc: "Go to the active window's next position and state in history."},
        {cat: "FOCUS", cmd: "WindowHistoryPick", key: "Win + Alt + `", desc: "Open a menu of past recorded positions and states to pick and apply."},
        {cat: "MOVE", cmd: "Swap", key: "Win + Alt + W", desc: "Swap current active window position and size with the window under mouse cursor."},
        {cat: "MOVE", cmd: "SwapSize", key: "Win + Alt + Z", desc: "Swap current active window size with the window under mouse cursor."},
        {cat: "MOVE", cmd: "SwapPosition", key: "Win + Alt + P", desc: "Swap current active window position with the window under mouse cursor."},
        {cat: "MOVE", cmd: "SwapPick", key: "Win + Ctrl + Alt + S", desc: "Interactive swap: hover and press Space on the first window, then the second window, to swap size and position."},
        {cat: "MOVE", cmd: "SwapPickSize", key: "Win + Ctrl + Alt + Z", desc: "Interactive swap: hover and press Space on the first window, then the second window, to swap size only."},
        {cat: "MOVE", cmd: "SwapPickPosition", key: "Win + Ctrl + Alt + P", desc: "Interactive swap: hover and press Space on the first window, then the second window, to swap position only."},
        {cat: "MOVE", cmd: "Gridify", key: "Win + Ctrl + G", desc: "Show a nested columns-then-rows menu to instant position the window on custom grid bounds."},

        ; == TUCK ==
        {cat: "TUCK", cmd: "TuckLeft", key: "Win + Ctrl + Shift + Left", desc: "Tuck window past left screen wall, exposing a 20px dock indicator bar."},
        {cat: "TUCK", cmd: "TuckRight", key: "Win + Ctrl + Shift + Right", desc: "Tuck window past right screen wall, exposing a 20px dock indicator bar."},
        {cat: "TUCK", cmd: "TuckUp", key: "Win + Ctrl + Shift + Up", desc: "Tuck window past top screen wall, exposing a 20px dock indicator bar."},
        {cat: "TUCK", cmd: "TuckDown", key: "Win + Ctrl + Shift + Down", desc: "Tuck window past bottom screen wall, exposing a 20px dock indicator bar."},
        {cat: "TUCK", cmd: "BumpEdgeUntuck", key: "Edge Bump", desc: "Trigger untuck peeking when cursor reaches tucked window edge indicator."},
        {cat: "TUCK", cmd: "BumpEdgeUntuckActivate", key: "Edge Click/Drag", desc: "Fully restore tucked window when pulled/clicked past the pop-off threshold."},
        {cat: "TUCK", cmd: "PeekTucked", key: "Win + Ctrl + Shift + P", desc: "Open interactive menu of all tucked windows to peek or activate."},
        {cat: "TUCK", cmd: "Untuck", key: "Win + Ctrl + Shift + U", desc: "Open interactive menu of all tucked windows to fully untuck them."},
        {cat: "TUCK", cmd: "UntuckLeft", key: "Win + Ctrl + Alt + Left", desc: "Untuck the window tucked at the left edge."},
        {cat: "TUCK", cmd: "UntuckRight", key: "Win + Ctrl + Alt + Right", desc: "Untuck the window tucked at the right edge."},
        {cat: "TUCK", cmd: "UntuckTop", key: "Win + Ctrl + Alt + Up", desc: "Untuck the window tucked at the top edge."},
        {cat: "TUCK", cmd: "UntuckBottom", key: "Win + Ctrl + Alt + Down", desc: "Untuck the window tucked at the bottom edge."},
        {cat: "TUCK", cmd: "TuckPeekLeft", key: "Win + Alt + Shift + Left", desc: "Reveal/peek tucked windows on the left edge sequentially."},
        {cat: "TUCK", cmd: "TuckPeekRight", key: "Win + Alt + Shift + Right", desc: "Reveal/peek tucked windows on the right edge sequentially."},
        {cat: "TUCK", cmd: "TuckPeekTop", key: "Win + Alt + Shift + Up", desc: "Reveal/peek tucked windows on the top edge sequentially."},
        {cat: "TUCK", cmd: "TuckPeekBottom", key: "Win + Alt + Shift + Down", desc: "Reveal/peek tucked windows on the bottom edge sequentially."},
        {cat: "TUCK", cmd: "TuckPeekAll", key: "Win + Alt + Shift + P", desc: "Show interactive popup menu of all tucked windows formatted with HWND labels."},
        {cat: "TUCK", cmd: "TuckedPeekLeft", key: "Win + Ctrl + Alt + Shift + Left", desc: "Show popup menu of Left tucked windows formatted with HWND labels."},
        {cat: "TUCK", cmd: "TuckedPeekRight", key: "Win + Ctrl + Alt + Shift + Right", desc: "Show popup menu of Right tucked windows formatted with HWND labels."},
        {cat: "TUCK", cmd: "TuckedPeekTop", key: "Win + Ctrl + Alt + Shift + Up", desc: "Show popup menu of Top tucked windows formatted with HWND labels."},
        {cat: "TUCK", cmd: "TuckedPeekBottom", key: "Win + Ctrl + Alt + Shift + Down", desc: "Show popup menu of Bottom tucked windows formatted with HWND labels."},

        ; == MOVE ==
        {cat: "MOVE", cmd: "Center", key: "Numpad5", desc: "Move active window to center of screen without sizing changes."},
        {cat: "MOVE", cmd: "MoveTadLeft", key: "Win + Alt + Left", desc: "Shift active window left by 1/4 cell width (106 pixels) coarse-scale."},
        {cat: "MOVE", cmd: "MoveTadRight", key: "Win + Alt + Right", desc: "Shift active window right by 1/4 cell width (106 pixels) coarse-scale."},
        {cat: "MOVE", cmd: "MoveTadUp", key: "Win + Alt + Up", desc: "Shift active window up by 1/4 cell height (58 pixels) coarse-scale."},
        {cat: "MOVE", cmd: "MoveTadDown", key: "Win + Alt + Down", desc: "Shift active window down by 1/4 cell height (58 pixels) coarse-scale."},
        {cat: "MOVE", cmd: "MovepxLeft", key: "Win + Shift + Left", desc: "Nudge active window left with 10 pixels fine precision."},
        {cat: "MOVE", cmd: "MovepxRight", key: "Win + Shift + Right", desc: "Nudge active window right with 10 pixels fine precision."},
        {cat: "MOVE", cmd: "MovepxUp", key: "Win + Shift + Up", desc: "Nudge active window up with 5 pixels fine precision."},
        {cat: "MOVE", cmd: "MovepxDown", key: "Win + Shift + Down", desc: "Nudge active window down with 5 pixels fine precision."},
        {cat: "MOVE", cmd: "EdgeLeft", key: "Shift + Numpad 4", desc: "Align window to the screen's left border."},
        {cat: "MOVE", cmd: "EdgeRight", key: "Shift + Numpad 6", desc: "Align window to the screen's right border."},
        {cat: "MOVE", cmd: "EdgeTop", key: "Shift + Numpad 8", desc: "Align window to the screen's top border."},
        {cat: "MOVE", cmd: "EdgeBottom", key: "Shift + Numpad 2", desc: "Align window to the screen's bottom border."},
        {cat: "MOVE", cmd: "EdgeTopLeft", key: "Shift + Numpad 7", desc: "Align window to the screen's top-left corner."},
        {cat: "MOVE", cmd: "EdgeTopRight", key: "Shift + Numpad 9", desc: "Align window to the screen's top-right corner."},
        {cat: "MOVE", cmd: "EdgeBottomLeft", key: "Shift + Numpad 1", desc: "Align window to the screen's bottom-left corner."},
        {cat: "MOVE", cmd: "EdgeBottomRight", key: "Shift + Numpad 3", desc: "Align window to the screen's bottom-right corner."},
        {cat: "MOVE", cmd: "EdgeCenter", key: "Shift + Numpad 5", desc: "Position active window to the exact horizontal and vertical center of monitor."},
        {cat: "MOVE", cmd: "EdgeInLeft", key: "Ctrl + Shift + Numpad 4", desc: "Set window alignment offset one grid cell from screen left edge."},
        {cat: "MOVE", cmd: "EdgeInRight", key: "Ctrl + Shift + Numpad 6", desc: "Set window alignment offset one grid cell from screen right edge."},
        {cat: "MOVE", cmd: "EdgeInTop", key: "Ctrl + Shift + Numpad 8", desc: "Set window alignment offset one grid cell from screen top edge."},
        {cat: "MOVE", cmd: "EdgeInBottom", key: "Ctrl + Shift + Numpad 2", desc: "Set window alignment offset one grid cell from screen bottom edge."},
        {cat: "MOVE", cmd: "EdgeInTopLeft", key: "Ctrl + Shift + Numpad 7", desc: "Align window offset one grid cell from screen top-left corner."},
        {cat: "MOVE", cmd: "EdgeInTopRight", key: "Ctrl + Shift + Numpad 9", desc: "Align window offset one grid cell from screen top-right corner."},
        {cat: "MOVE", cmd: "EdgeInBottomLeft", key: "Ctrl + Shift + Numpad 1", desc: "Align window offset one grid cell from screen bottom-left corner."},
        {cat: "MOVE", cmd: "EdgeInBottomRight", key: "Ctrl + Shift + Numpad 3", desc: "Align window offset one grid cell from screen bottom-right corner."},
        {cat: "MOVE", cmd: "JumpGridLeft", key: "Ctrl + Numpad 4", desc: "Hop window position to the left virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridRight", key: "Ctrl + Numpad 6", desc: "Hop window position to the right virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridUp", key: "Ctrl + Numpad 8", desc: "Hop window position to the up virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridDown", key: "Ctrl + Numpad 2", desc: "Hop window position to the down virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridTopLeft", key: "Ctrl + Numpad 7", desc: "Hop window position to the top-left virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridTopRight", key: "Ctrl + Numpad 9", desc: "Hop window position to the top-right virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridBottomLeft", key: "Ctrl + Numpad 1", desc: "Hop window position to the bottom-left virtual grid quartile partition."},
        {cat: "MOVE", cmd: "JumpGridBottomRight", key: "Ctrl + Numpad 3", desc: "Hop window position to the bottom-right virtual grid quartile partition."},
        {cat: "MOVE", cmd: "MoveToGridLeft", key: "Numpad 4", desc: "Shift active window leftward between virtual grid units."},
        {cat: "MOVE", cmd: "MoveToGridRight", key: "Numpad 6", desc: "Shift active window rightward between virtual grid units."},
        {cat: "MOVE", cmd: "MoveToGridUp", key: "Numpad 8", desc: "Shift active window upward between virtual grid units."},
        {cat: "MOVE", cmd: "MoveToGridDown", key: "Numpad 2", desc: "Shift active window downward between virtual grid units."},
        {cat: "MOVE", cmd: "MoveToGridTopLeft", key: "Numpad 7", desc: "Shift active window to top-left virtual grid aspects."},
        {cat: "MOVE", cmd: "MoveToGridTopRight", key: "Numpad 9", desc: "Shift active window to top-right virtual grid aspects."},
        {cat: "MOVE", cmd: "MoveToGridBottomLeft", key: "Numpad 1", desc: "Shift active window to bottom-left virtual grid aspects."},
        {cat: "MOVE", cmd: "MoveToGridBottomRight", key: "Numpad 3", desc: "Shift active window to bottom-right virtual grid aspects."},

        ; == SIZE ==
        {cat: "SIZE", cmd: "MouseToGrid", key: "Win + RButton", desc: "Warp window beneath mouse cursor directly to closest grid block."},
        {cat: "SIZE", cmd: "MouseRelativeSize", key: "Win + LButton", desc: "Resize window dynamically relative to cursor movement boundary vectors."},
        {cat: "SIZE", cmd: "SnapToGridEnlarge", key: "NumpadAdd", desc: "Grow active window boundaries to span next adjacent grid aspect cell."},
        {cat: "SIZE", cmd: "SnapToGridShrink", key: "NumpadSub", desc: "Contract active window grid spanning aspect cell size."},
        {cat: "SIZE", cmd: "ScaleExpand10px", key: "Alt + NumpadAdd", desc: "Expand active window bounds by 10px symmetrically in all directions."},
        {cat: "SIZE", cmd: "ScaleReduce10px", key: "Alt + NumpadSub", desc: "Shrink active window bounds by 10px symmetrically in all directions."},
        {cat: "SIZE", cmd: "ScaleExpandGridPart", key: "Ctrl + NumpadAdd", desc: "Expand active window bounds symmetrically matching half-grid step parts."},
        {cat: "SIZE", cmd: "ScaleReduceGridPart", key: "Ctrl + NumpadSub", desc: "Shrink active window bounds symmetrically matching half-grid step parts."},
        {cat: "SIZE", cmd: "TrimTop", key: "Win + Alt + Shift + Numpad 8", desc: "Trim top boundary from active window margin."},
        {cat: "SIZE", cmd: "TrimBottom", key: "Win + Alt + Shift + Numpad 2", desc: "Trim bottom boundary from active window margin."},
        {cat: "SIZE", cmd: "TrimLeft", key: "Win + Alt + Shift + Numpad 6", desc: "Trim left boundary from active window margin."},
        {cat: "SIZE", cmd: "TrimRight", key: "Win + Alt + Shift + Numpad 4", desc: "Trim right boundary from active window margin."},
        {cat: "SIZE", cmd: "TrimAll", key: "Win + Alt + Numpad 5", desc: "Symmetrically trim all 4 sides of the active window margin."},
        {cat: "SIZE", cmd: "TrimTopLeft", key: "Win + Ctrl + Alt + Shift + Numpad 7", desc: "Trim top-left boundaries from active window margins."},
        {cat: "SIZE", cmd: "TrimTopRight", key: "Win + Ctrl + Alt + Shift + Numpad 9", desc: "Trim top-right boundaries from active window margins."},
        {cat: "SIZE", cmd: "TrimBottomLeft", key: "Win + Ctrl + Alt + Shift + Numpad 1", desc: "Trim bottom-left boundaries from active window margins."},
        {cat: "SIZE", cmd: "TrimBottomRight", key: "Win + Ctrl + Alt + Shift + Numpad 3", desc: "Trim bottom-right boundaries from active window margins."},
        {cat: "SIZE", cmd: "AddTop", key: "Win + Alt + Shift + Up", desc: "Grow top boundary outward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "AddBottom", key: "Win + Alt + Shift + Down", desc: "Grow bottom boundary outward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "AddLeft", key: "Win + Alt + Shift + Left", desc: "Grow left boundary outward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "AddRight", key: "Win + Alt + Shift + Right", desc: "Grow right boundary outward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "AddTopLeft", key: "Win + Alt + Shift + Numpad 7", desc: "Grow top-left boundaries outward to nearest grid margins."},
        {cat: "SIZE", cmd: "AddTopRight", key: "Win + Alt + Shift + Numpad 9", desc: "Grow top-right boundaries outward to nearest grid margins."},
        {cat: "SIZE", cmd: "AddBottomLeft", key: "Win + Alt + Shift + Numpad 1", desc: "Grow bottom-left boundaries outward to nearest grid margins."},
        {cat: "SIZE", cmd: "AddBottomRight", key: "Win + Alt + Shift + Numpad 3", desc: "Grow bottom-right boundaries outward to nearest grid margins."},
        {cat: "SIZE", cmd: "AddAll", key: "Win + Alt + Shift + Numpad 5", desc: "Symmetrically grow all four sides of the window outward to the nearest grid lines."},
        {cat: "SIZE", cmd: "GrowLeft", key: "Win + Ctrl + Shift + Numpad 6", desc: "Grow left boundary outward from active window margin by step width."},
        {cat: "SIZE", cmd: "GrowRight", key: "Win + Ctrl + Shift + Numpad 4", desc: "Grow right boundary outward from active window margin by step width."},
        {cat: "SIZE", cmd: "GrowTop", key: "Win + Ctrl + Shift + Numpad 8", desc: "Grow top boundary outward from active window margin by step width."},
        {cat: "SIZE", cmd: "GrowBottom", key: "Win + Ctrl + Shift + Numpad 2", desc: "Grow bottom boundary outward from active window margin by step width."},
        {cat: "SIZE", cmd: "GrowAll", key: "Win + Ctrl + Shift + Numpad 5", desc: "Symmetrically grow all 4 sides of the active window margin."},
        {cat: "SIZE", cmd: "GrowTopLeft", key: "Win + Ctrl + Shift + Numpad 7", desc: "Symmetrically grow top-left boundaries of active window."},
        {cat: "SIZE", cmd: "GrowTopRight", key: "Win + Ctrl + Shift + Numpad 9", desc: "Symmetrically grow top-right boundaries of active window."},
        {cat: "SIZE", cmd: "GrowBottomLeft", key: "Win + Ctrl + Shift + Numpad 1", desc: "Symmetrically grow bottom-left boundaries of active window."},
        {cat: "SIZE", cmd: "GrowBottomRight", key: "Win + Ctrl + Shift + Numpad 3", desc: "Symmetrically grow bottom-right boundaries of active window."},
        {cat: "SIZE", cmd: "SubtractTop", key: "Win + Ctrl + Alt + Up", desc: "Contract top boundary inward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "SubtractBottom", key: "Win + Ctrl + Alt + Down", desc: "Contract bottom boundary inward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "SubtractLeft", key: "Win + Ctrl + Alt + Left", desc: "Contract left boundary inward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "SubtractRight", key: "Win + Ctrl + Alt + Right", desc: "Contract right boundary inward to nearest grid or midpoint grid cell."},
        {cat: "SIZE", cmd: "SubtractTopLeft", key: "Win + Ctrl + Alt + Numpad 7", desc: "Contract top-left boundaries inward toward centers of monitor."},
        {cat: "SIZE", cmd: "SubtractTopRight", key: "Win + Ctrl + Alt + Numpad 9", desc: "Contract top-right boundaries inward toward centers of monitor."},
        {cat: "SIZE", cmd: "SubtractBottomLeft", key: "Win + Ctrl + Alt + Numpad 1", desc: "Contract bottom-left boundaries inward toward centers of monitor."},
        {cat: "SIZE", cmd: "SubtractBottomRight", key: "Win + Ctrl + Alt + Numpad 3", desc: "Contract bottom-right boundaries inward toward centers of monitor."},
        {cat: "SIZE", cmd: "SubtractAll", key: "Win + Ctrl + Alt + Numpad 5", desc: "Symmetrically contract all four sides of the window inward to the nearest grid lines."},
        {cat: "SIZE", cmd: "HalfSizeLeft", key: "Win + Ctrl + Numpad 4", desc: "Halve window width from the left side."},
        {cat: "SIZE", cmd: "HalfSizeRight", key: "Win + Ctrl + Numpad 6", desc: "Halve window width from the right side."},
        {cat: "SIZE", cmd: "HalfSizeTop", key: "Win + Ctrl + Numpad 8", desc: "Halve window height from the top side."},
        {cat: "SIZE", cmd: "HalfSizeBottom", key: "Win + Ctrl + Numpad 2", desc: "Halve window height from the bottom side."},
        {cat: "SIZE", cmd: "DoubleSizeLeft", key: "Win + Ctrl + Alt + Numpad 4", desc: "Double window width from the left side."},
        {cat: "SIZE", cmd: "DoubleSizeRight", key: "Win + Ctrl + Alt + Numpad 6", desc: "Double window width from the right side."},
        {cat: "SIZE", cmd: "DoubleSizeTop", key: "Win + Ctrl + Alt + Numpad 8", desc: "Double window height from the top side."},
        {cat: "SIZE", cmd: "DoubleSizeBottom", key: "Win + Ctrl + Alt + Numpad 2", desc: "Double window height from the bottom side."},
        {cat: "SIZE", cmd: "StretchToGridLeft", key: "Win + Numpad 4", desc: "Stretch left boundary outward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "StretchToGridRight", key: "Win + Numpad 6", desc: "Stretch right boundary outward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "StretchToGridUp", key: "Win + Numpad 8", desc: "Stretch top boundary outward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "StretchToGridDown", key: "Win + Numpad 2", desc: "Stretch bottom boundary outward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "StretchToGridTopLeft", key: "Win + Numpad 7", desc: "Stretch top-left boundaries toward the nearest grid corners."},
        {cat: "SIZE", cmd: "StretchToGridTopRight", key: "Win + Numpad 9", desc: "Stretch top-right boundaries toward the nearest grid corners."},
        {cat: "SIZE", cmd: "StretchToGridBottomLeft", key: "Win + Numpad 1", desc: "Stretch bottom-left boundaries toward the nearest grid corners."},
        {cat: "SIZE", cmd: "StretchToGridBottomRight", key: "Win + Numpad 3", desc: "Stretch bottom-right boundaries toward the nearest grid corners."},
        {cat: "SIZE", cmd: "StretchToGridAll", key: "Win + Numpad 5", desc: "Symmetrically stretch all four borders of the window outward to the adjacent grid lines."},
        {cat: "SIZE", cmd: "PullToGridLeft", key: "Win + Alt + Numpad 4", desc: "Pull left boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridRight", key: "Win + Alt + Numpad 6", desc: "Pull right boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridUp", key: "Win + Alt + Numpad 8", desc: "Pull top boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridDown", key: "Win + Alt + Numpad 2", desc: "Pull bottom boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridTopLeft", key: "Win + Alt + Numpad 7", desc: "Pull top-left boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridTopRight", key: "Win + Alt + Numpad 9", desc: "Pull top-right boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridBottomLeft", key: "Win + Alt + Numpad 1", desc: "Pull bottom-left boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridBottomRight", key: "Win + Alt + Numpad 3", desc: "Pull bottom-right boundary inward to nearest grid or midpoint grid cell edge."},
        {cat: "SIZE", cmd: "PullToGridAll", key: "Win + Ctrl + Alt + Shift + Numpad 5", desc: "Symmetrically pull all four borders of the window inward to the adjacent grid lines."},
        {cat: "SIZE", cmd: "StretchLeft", key: "Win + Shift + Numpad 4", desc: "Extend side width of target window to touch screen left bounds."},
        {cat: "SIZE", cmd: "StretchRight", key: "Win + Shift + Numpad 6", desc: "Extend side width of target window to touch screen right bounds."},
        {cat: "SIZE", cmd: "StretchTop", key: "Win + Shift + Numpad 8", desc: "Extend top height of target window to touch screen top bounds."},
        {cat: "SIZE", cmd: "StretchBottom", key: "Win + Shift + Numpad 2", desc: "Extend bottom height of target window to touch screen bottom bounds."},
        {cat: "SIZE", cmd: "StretchTopLeft", key: "Win + Shift + Numpad 7", desc: "Extend top-left coordinate vectors of target window bounds to touch screen margins."},
        {cat: "SIZE", cmd: "StretchTopRight", key: "Win + Shift + Numpad 9", desc: "Extend top-right coordinate vectors of target window bounds to touch screen margins."},
        {cat: "SIZE", cmd: "StretchBottomLeft", key: "Win + Shift + Numpad 1", desc: "Extend bottom-left coordinate vectors of target window bounds to touch screen margins."},
        {cat: "SIZE", cmd: "StretchBottomRight", key: "Win + Shift + Numpad 3", desc: "Extend bottom-right coordinate vectors of target window bounds to touch screen margins."},
        {cat: "SIZE", cmd: "StretchAll", key: "Win + Shift + Numpad 5", desc: "Symmetrically expand all sides of the window outward to fill the monitor workspace edges."}
    ]
    return commandList
}

ShowCmdPalette(targetHwnd := 0) {
    static cmdGui := ""
    
    if (targetHwnd == 0) {
        targetHwnd := DllCall("GetForegroundWindow", "ptr")
    }
    
    if (cmdGui != "") {
        try {
            if (WinExist("ahk_id " cmdGui.Hwnd)) {
                cmdGui.Show()
                WinActivate("ahk_id " cmdGui.Hwnd)
                return
            }
        }
        cmdGui := ""
    }
    
    cmdGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "HotWinAHK - Command Palette")
    cmdGui.BackColor := "121214"
    cmdGui.SetFont("s10 cE0E0E6", "Segoe UI")
    
    cmdGui.SetFont("s16 bold c00FFCC", "Segoe UI")
    cmdGui.Add("Text", "w940 Center x30 y15", "HotWinAHK Command Palette [MANUAL RUN]")
    cmdGui.SetFont("s9 c8A8A93", "Segoe UI")
    cmdGui.Add("Text", "w940 Center x30 y+4", "Filter and instantly execute any administrative, nudge, size, docking or cycle action")
    
    cmdGui.Add("Text", "w940 h1 Background3A3A3D x30 y60", "")
    
    ; Live Dynamic Filter Box Row
    cmdGui.SetFont("s10 bold c00FFCC", "Segoe UI")
    cmdGui.Add("Text", "w100 x30 y80 h24 +0x200", "Search Filter:")
    cmdGui.SetFont("s11 norm cFFFFFF", "Segoe UI")
    searchBox := cmdGui.Add("Edit", "w550 x135 y80 Background1E1E22 cFFFFFF Border r1 h26", "")
    
    cmdGui.SetFont("s9 c00FF55", "Segoe UI")
    cmdGui.Add("Text", "w300 x700 y80 h24 +0x200 Right", "💡 Tab to list • Enter to trigger • ESC close")
    
    cmdGui.SetFont("s10 cE0E0E6", "Segoe UI")
    cmdLV := cmdGui.Add("ListView", "x30 y115 w940 h420 Background111112 cFFFFFF +Grid -Multi -ReadOnly", ["Command Name", "Default Key combo", "Description of Action", "Category"])
    
    cmdLV.ModifyCol(1, 180) ; Command
    cmdLV.ModifyCol(2, 160) ; Target key combo
    cmdLV.ModifyCol(3, 460) ; Action Description
    cmdLV.ModifyCol(4, 140) ; Category
    
    commandList := GetGlobalCommandList()
    
    PopulateCmdLV(searchTerm := "") {
        cmdLV.Opt("-Redraw")
        cmdLV.Delete()
        
        for row in commandList {
            if (searchTerm != "") {
                if (!InStr(row.cmd, searchTerm) && !InStr(row.cat, searchTerm) && !InStr(row.desc, searchTerm) && !InStr(row.key, searchTerm)) {
                    continue
                }
            }
            cmdLV.Add("", row.cmd, row.key, row.desc, row.cat)
        }
        
        if (cmdLV.GetCount() > 0) {
            cmdLV.Modify(1, "Select Focus")
        }
        cmdLV.Opt("+Redraw")
    }
    
    PopulateCmdLV()
    
    searchBox.OnEvent("Change", (ctrl, *) => PopulateCmdLV(ctrl.Value))
    
    ; Setup default trigger button for Enter key
    btnTrigger := cmdGui.Add("Button", "w0 h0 Hidden +Default", "Run")
    
    ExecuteSelected() {
        selectedRow := cmdLV.GetNext(0, "Focused")
        if (selectedRow == 0) {
            selectedRow := 1
        }
        
        if (cmdLV.GetCount() >= selectedRow && selectedRow > 0) {
            rowCmd := cmdLV.GetText(selectedRow, 1)
            
            try cmdGui.Destroy()
            cmdGui := ""
            
            try {
                if (targetHwnd != 0 && WinExist("ahk_id " . targetHwnd)) {
                    WinActivate("ahk_id " . targetHwnd)
                    Sleep(60)
                }
            }
            
            ExecuteCommandRegistry(rowCmd, targetHwnd)
        }
    }
    
    btnTrigger.OnEvent("Click", (*) => ExecuteSelected())
    cmdLV.OnEvent("DoubleClick", (*) => ExecuteSelected())
    
    cmdGui.OnEvent("Escape", (*) => (cmdGui.Destroy(), cmdGui := ""))
    cmdGui.OnEvent("Close", (*) => (cmdGui.Destroy(), cmdGui := ""))
    
    cmdGui.Show("w1000 h560 Center")
}
; #endregion

; #region _stowed_drag_and_clipboard
IsMouseOverHwnd(targetHwnd) {
    if (targetHwnd == 0 || !WinExist("ahk_id " . targetHwnd)) {
        return false
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &mHwnd)
    mRoot := mHwnd ? DllCall("GetAncestor", "ptr", mHwnd, "uint", 2, "ptr") : 0
    return (mHwnd == targetHwnd || mRoot == targetHwnd)
}

HandleTuckedDrag() {
    global g_ActiveUntuckedHwnd, g_TuckedWindows, g_ResetBumpMemory, g_TuckedVisiblePixels, g_PeekX, g_PeekY, g_IsUntuckLocked
    
    if (g_ActiveUntuckedHwnd == 0 || !WinExist("ahk_id " . g_ActiveUntuckedHwnd)) {
        Click("Down")
        KeyWait("LButton")
        Click("Up")
        return
    }
    
    ; --- IMMEDIATELY ACQUIRE LOCK & DISABLE LIFE CYCLE TIMER TO PREVENT RETUCK RACE FREEZES ---
    g_IsUntuckLocked := true
    SetTimer(TrackUntuckedFocusLifecycle, 0)
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&startX, &startY)
    
    ; Wait for either mouse release or a drag threshold of 4 pixels
    isDrag := false
    While (GetKeyState("LButton", "P")) {
        MouseGetPos(&curX, &curY)
        if (Abs(curX - startX) > 4 || Abs(curY - startY) > 4) {
            isDrag := true
            break
        }
        Sleep(10)
    }
    
    if (!isDrag) {
        ; Normal Click: Pass it through
        Click("Down")
        KeyWait("LButton")
        Click("Up")
        
        ; Restore state safely
        g_IsUntuckLocked := false
        SetTimer(TrackUntuckedFocusLifecycle, 50)
        return
    }
    
    ; Protect against edge-case where window profile vanished during threshold check
    if (!g_TuckedWindows.Has(g_ActiveUntuckedHwnd)) {
        g_IsUntuckLocked := false
        SetTimer(TrackUntuckedFocusLifecycle, 50)
        return
    }
    
    ; User is dragging!
    try {
        WinGetPos(&startWinX, &startWinY, &wW, &wH, g_ActiveUntuckedHwnd)
    } catch {
        g_IsUntuckLocked := false
        SetTimer(TrackUntuckedFocusLifecycle, 50)
        return
    }
    
    tuckProfile := g_TuckedWindows[g_ActiveUntuckedHwnd]
    
    ; Create the translucent cyan indicator GUI
    dockIndicatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; Click-through
    dockIndicatorGui.BackColor := "00FFCC"
    try {
        dockIndicatorGui.Show("Hide")
        WinSetTransparent(100, "ahk_id " . dockIndicatorGui.Hwnd)
    } catch {
        ; Silent fallback container guard
    }
    
    isPoppedOff := false
    soundPlayed := false
    currentIndEdge := ""
    hasIndicatorShown := false
    
    While (GetKeyState("LButton", "P")) {
        Sleep(15)
        CoordMode("Mouse", "Screen")
        MouseGetPos(&curX, &curY)
        
        deltaX := curX - startX
        deltaY := curY - startY
        
        isCtrl := GetKeyState("Ctrl", "P")
        
        if (isCtrl) {
            ; Ctrl is pressed: standard dock seeking!
            isPoppedOff := true ; Holding Ctrl overrides resistance/pull progress entirely
            
            hMon := DllCall("MonitorFromPoint", "int64", (curY << 32) | (curX & 0xFFFFFFFF), "uint", 2, "ptr")
            MI := Buffer(40)
            NumPut("uint", 40, MI, 0)
            if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                mLeft   := NumGet(MI, 20, "int")
                mTop    := NumGet(MI, 24, "int")
                mRight  := NumGet(MI, 28, "int")
                mBottom := NumGet(MI, 32, "int")
                
                distL := Abs(curX - mLeft)
                distR := Abs(curX - mRight)
                distT := Abs(curY - mTop)
                distB := Abs(curY - mBottom)
                
                minD := Min(distL, distR, distT, distB)
                newEdge := ""
                if (minD == distL) {
                    newEdge := "Left"
                } else if (minD == distR) {
                    newEdge := "Right"
                } else if (minD == distT) {
                    newEdge := "Top"
                } else if (minD == distB) {
                    newEdge := "Bottom"
                }
                
                if (newEdge != currentIndEdge) {
                    currentIndEdge := newEdge
                    switch newEdge {
                        case "Left":
                            dockIndicatorGui.Show("x" . mLeft . " y" . mTop . " w60 h" . (mBottom - mTop) . " NoActivate")
                        case "Right":
                            dockIndicatorGui.Show("x" . (mRight - 60) . " y" . mTop . " w60 h" . (mBottom - mTop) . " NoActivate")
                        case "Top":
                            dockIndicatorGui.Show("x" . mLeft . " y" . mTop . " w" . (mRight - mLeft) . " h60 NoActivate")
                        case "Bottom":
                            dockIndicatorGui.Show("x" . mLeft . " y" . (mBottom - 60) . " w" . (mRight - mLeft) . " h60 NoActivate")
                    }
                    hasIndicatorShown := true
                }
            }
            
            ToolTip() ; Clear any pull progress tooltips
            WinMove(startWinX + deltaX, startWinY + deltaY, wW, wH, g_ActiveUntuckedHwnd)
            
        } else {
            ; Normal drag (No Ctrl):
            if (!isPoppedOff) {
                pullDist := 0
                switch tuckProfile.edge {
                    case "Left":   pullDist := deltaX
                    case "Right":  pullDist := -deltaX
                    case "Top":    pullDist := deltaY
                    case "Bottom": pullDist := -deltaY
                }
                
                if (pullDist > 120) {
                    isPoppedOff := true
                    if (!soundPlayed) {
                        SoundBeep(1100, 150) ; Distinct high pitch beep for popping off
                        soundPlayed := true
                    }
                    ; Remove from tucked list
                    if (g_TuckedWindows.Has(g_ActiveUntuckedHwnd)) {
                        g_TuckedWindows.Delete(g_ActiveUntuckedHwnd)
                    }
                    ToolTip()
                } else {
                    ; UNDER PULL THRESHOLD:
                    ; Moves 1:1 with NO motion resistance!
                    WinMove(startWinX + deltaX, startWinY + deltaY, wW, wH, g_ActiveUntuckedHwnd)
                    
                    ; Pull Indicator (Graphical Progress Bar matching original design guidelines)
                    pct := Max(0, Min(pullDist / 120, 1))
                    pctPct := Round(pct * 100)
                    progressBar := MakeProgressBarStr(pullDist, 120)
                    ToolTip("Pull to Free: " . pctPct . "%`n" . progressBar, curX + 15, curY + 15)
                }
            }
            
            ; If we popped off, we are dragging it around freely.
            ; Let's show indicators if they are in range (within 80px) of any edge to dock!
            if (isPoppedOff) {
                hMon := DllCall("MonitorFromPoint", "int64", (curY << 32) | (curX & 0xFFFFFFFF), "uint", 2, "ptr")
                MI := Buffer(40)
                NumPut("uint", 40, MI, 0)
                if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
                    mLeft   := NumGet(MI, 20, "int")
                    mTop    := NumGet(MI, 24, "int")
                    mRight  := NumGet(MI, 28, "int")
                    mBottom := NumGet(MI, 32, "int")
                    
                    distL := Abs(curX - mLeft)
                    distR := Abs(curX - mRight)
                    distT := Abs(curY - mTop)
                    distB := Abs(curY - mBottom)
                    
                    minD := Min(distL, distR, distT, distB)
                    
                    if (minD < 80) {
                        newEdge := ""
                        if (minD == distL) {
                            newEdge := "Left"
                        } else if (minD == distR) {
                            newEdge := "Right"
                        } else if (minD == distT) {
                            newEdge := "Top"
                        } else if (minD == distB) {
                            newEdge := "Bottom"
                        }
                        
                        if (newEdge != currentIndEdge) {
                            currentIndEdge := newEdge
                            switch newEdge {
                                case "Left":
                                    dockIndicatorGui.Show("x" . mLeft . " y" . mTop . " w60 h" . (mBottom - mTop) . " NoActivate")
                                case "Right":
                                    dockIndicatorGui.Show("x" . (mRight - 60) . " y" . mTop . " w60 h" . (mBottom - mTop) . " NoActivate")
                                case "Top":
                                    dockIndicatorGui.Show("x" . mLeft . " y" . mTop . " w" . (mRight - mLeft) . " h60 NoActivate")
                                case "Bottom":
                                    dockIndicatorGui.Show("x" . mLeft . " y" . (mBottom - 60) . " w" . (mRight - mLeft) . " h60 NoActivate")
                            }
                            hasIndicatorShown := true
                        }
                    } else {
                        if (hasIndicatorShown) {
                            dockIndicatorGui.Hide()
                            currentIndEdge := ""
                            hasIndicatorShown := false
                        }
                    }
                }
                
                ; 1:1 motion
                WinMove(startWinX + deltaX, startWinY + deltaY, wW, wH, g_ActiveUntuckedHwnd)
            }
        }
    }
    
    ToolTip() ; Clear pull indicator tooltip
    dockIndicatorGui.Destroy()
    
    if (isPoppedOff) {
        if (currentIndEdge != "") {
            ; Retuck to the selected edge!
            g_TuckedWindows[g_ActiveUntuckedHwnd] := { edge: currentIndEdge, x: startWinX + deltaX, y: startWinY + deltaY, w: wW, h: wH }
            SoundBeep(1400, 80)
            ExecuteRetuckSequence(g_ActiveUntuckedHwnd)
            g_ActiveUntuckedHwnd := 0
            g_ResetBumpMemory := true
            g_IsUntuckLocked := false
            SetTimer(ExecuteCleanBumperReArm, -200)
            return
        } else {
            ; Free floating snapped release
            g_ActiveUntuckedHwnd := 0
            g_ResetBumpMemory := true
            g_IsUntuckLocked := false
            SetTimer(ExecuteCleanBumperReArm, -200)
            return
        }
    } else {
        ; Never popped off - snap back to tucked position safely
        SafeMove(g_PeekX, g_PeekY, wW, wH, g_ActiveUntuckedHwnd)
    }
    
    g_IsUntuckLocked := false
    SetTimer(TrackUntuckedFocusLifecycle, 50)
}

CopyCommands() {
    commandList := GetGlobalCommandList()
    outText := "=== HotWinAHK Available Action Commands by Category ===`r`n`r`n"
    currentCategory := ""
    
    for item in commandList {
        if (item.cat != currentCategory) {
            currentCategory := item.cat
            outText .= "== " . currentCategory . " ==`r`n"
        }
        outText .= item.cmd . "`r`n"
    }
    
    outText := RTrim(outText, "`r`n ") . "`r`n"
    A_Clipboard := outText
    ShowTargetToolTip("Copied Available Commands by Category to Clipboard!")
}

CopyCommandsAlpha() {
    commandList := GetGlobalCommandList()
    flatText := ""
    
    for item in commandList {
        flatText .= item.cmd . "`r`n"
    }
    flatText := RTrim(flatText, "`r`n")
    sortedText := Sort(flatText)
    
    outText := "=== HotWinAHK Available Action Commands Alphabetical ===`r`n`r`n" . sortedText . "`r`n"
    A_Clipboard := outText
    ShowTargetToolTip("Copied Alphabetic Commands to Clipboard!")
}

CopyCommandsHelp() {
    commandList := GetGlobalCommandList()
    
    outText := "=== HotWinAHK Categorized Commands & Explanations ===`r`n`r`n"
    currentCategory := ""
    
    for item in commandList {
        if (item.cat != currentCategory) {
            currentCategory := item.cat
            outText .= "== " . currentCategory . " ==`r`n"
        }
        outText .= "- " . item.cmd . ": " . item.desc . "`r`n"
    }
    
    outText := RTrim(outText, "`r`n ") . "`r`n"
    A_Clipboard := outText
    ShowTargetToolTip("Copied Categorized Commands Help to Clipboard!")
}

CopyBindings() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        ShowTargetToolTip("INI File not found!")
        return
    }
    
    rawLines := []
    sectionsText := IniRead(g_sIniFile)
    
    loop parse, sectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") {
            continue
        }
        
        loop 10 {
            currentKeyProp := "keys" A_Index
            keyValue := IniRead(g_sIniFile, sCmd, currentKeyProp, "")
            if (keyValue == "") {
                break
            }
            
            rawLines.Push("[" . sCmd . "] -> " . keyValue)
        }
    }
    
    reducedArray := ReduceBindingsArray(rawLines)
    
    bindingsList := "=== HotWinAHK Active Keybindings ===`r`n`r`n"
    for item in reducedArray {
        bindingsList .= item . "`r`n"
    }
    
    A_Clipboard := bindingsList
    ShowTargetToolTip("Copied Active Bindings to Clipboard!")
}

CopyBindingsAlpha() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        ShowTargetToolTip("INI File not found!")
        return
    }
    
    rawLines := []
    sectionsText := IniRead(g_sIniFile)
    
    loop parse, sectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") {
            continue
        }
        
        loop 10 {
            currentKeyProp := "keys" A_Index
            keyValue := IniRead(g_sIniFile, sCmd, currentKeyProp, "")
            if (keyValue == "") {
                break
            }
            
            rawLines.Push("[" . sCmd . "] -> " . keyValue)
        }
    }
    
    if (rawLines.Length == 0) {
        ShowTargetToolTip("No active bindings found!")
        return
    }
    
    reducedArray := ReduceBindingsArray(rawLines)
    
    flatText := ""
    for idx, line in reducedArray {
        flatText .= line . "`r`n"
    }
    flatText := RTrim(flatText, "`r`n")
    sortedText := Sort(flatText)
    
    outText := "=== HotWinAHK Active Keybindings ===`r`n`r`n" . sortedText . "`r`n"
    A_Clipboard := outText
    ShowTargetToolTip("Copied Alphabetic Bindings to Clipboard!")
}

CopyBindingsLocation() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        ShowTargetToolTip("INI File not found!")
        return
    }
    
    sectionsText := IniRead(g_sIniFile)
    
    modifierGroups := [
        "_", "c", "ca", "a", "as", "s", "cs", "cas",
        "w+ _", "w+ c", "w+ ca", "w+ a", "w+ as", "w+ s", "w+ cs", "w+ cas"
    ]
    
    alphanumericMap := Map()
    arrowsMap := Map()
    numpadMap := Map()
    
    for modGrp in modifierGroups {
        alphanumericMap[modGrp] := []
        arrowsMap[modGrp] := []
        numpadMap[modGrp] := []
    }
    
    rawLines := []
    loop parse, sectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") {
            continue
        }
        
        loop 10 {
            currentKeyProp := "keys" A_Index
            keyValue := IniRead(g_sIniFile, sCmd, currentKeyProp, "")
            if (keyValue == "") {
                break
            }
            rawLines.Push("[" . sCmd . "] -> " . keyValue)
        }
    }
    
    reducedArray := ReduceBindingsArray(rawLines)
    
    for lineStr in reducedArray {
        if !RegExMatch(lineStr, "^\[([^\]]+)\]\s*->\s*(.+)$", &match)
            continue
        
        sCmd := match[1]
        keyValue := match[2]
        
        sStroke := keyValue
        if InStr(keyValue, "|") {
            aSplit := StrSplit(keyValue, "|")
            sStroke := Trim(aSplit[1])
        }
        
        modGrp := GetModifierGroupCode(sStroke)
        category := GetHardwareCategory(sStroke)
        
        if (category == "Arrows") {
            arrowsMap[modGrp].Push(lineStr)
        } else if (category == "Numpad") {
            numpadMap[modGrp].Push(lineStr)
        } else {
            alphanumericMap[modGrp].Push(lineStr)
        }
    }
    
    outText := "=== HotWinAHK Active Keybindings by Location ===`r`n`r`n"
    
    outText .= "== Alphabetic, Number, Punctuation Keys ==`r`n"
    hasAnyAlpha := false
    for modGrp in modifierGroups {
        lines := alphanumericMap[modGrp]
        if (lines.Length > 0) {
            hasAnyAlpha := true
            outText .= "--- [" . modGrp . "] ---`r`n"
            flatText := ""
            for line in lines {
                flatText .= line . "`r`n"
            }
            flatText := RTrim(flatText, "`r`n")
            sortedText := Sort(flatText)
            outText .= sortedText . "`r`n`r`n"
        }
    }
    if (!hasAnyAlpha) {
        outText .= "(No active bindings on Alphabetic, Number, or Punctuation keys)`r`n`r`n"
    }
    
    outText .= "== Arrow Keys ==`r`n"
    hasAnyArrows := false
    for modGrp in modifierGroups {
        lines := arrowsMap[modGrp]
        if (lines.Length > 0) {
            hasAnyArrows := true
            outText .= "--- [" . modGrp . "] ---`r`n"
            flatText := ""
            for line in lines {
                flatText .= line . "`r`n"
            }
            flatText := RTrim(flatText, "`r`n")
            sortedText := Sort(flatText)
            outText .= sortedText . "`r`n`r`n"
        }
    }
    if (!hasAnyArrows) {
        outText .= "(No active bindings on Arrow keys)`r`n`r`n"
    }
    
    outText .= "== Numpad Keys ==`r`n"
    hasAnyNumpad := false
    for modGrp in modifierGroups {
        lines := numpadMap[modGrp]
        if (lines.Length > 0) {
            hasAnyNumpad := true
            outText .= "--- [" . modGrp . "] ---`r`n"
            flatText := ""
            for line in lines {
                flatText .= line . "`r`n"
            }
            flatText := RTrim(flatText, "`r`n")
            sortedText := Sort(flatText)
            outText .= sortedText . "`r`n`r`n"
        }
    }
    if (!hasAnyNumpad) {
        outText .= "(No active bindings on Numpad keys)`r`n`r`n"
    }
    
    outText := RTrim(outText, "`r`n ") . "`r`n"
    A_Clipboard := outText
    ShowTargetToolTip("Copied Bindings by Location to Clipboard!")
}

ReduceBindingsArray(bindingsArray) {
    reduced := []
    
    parsed := []
    for line in bindingsArray {
        if RegExMatch(line, "^\[([^\]]+)\]\s*->\s*(.+)$", &m) {
            parsed.Push({line: line, cmd: m[1], key: m[2]})
        } else {
            parsed.Push({line: line, cmd: "", key: ""})
        }
    }
    
    numpadDirections := Map(
        "BottomLeft", "1",
        "Down", "2",
        "BottomRight", "3",
        "Left", "4",
        "Center", "5",
        "Right", "6",
        "TopLeft", "7",
        "Up", "8",
        "TopRight", "9"
    )
    
    arrowDirections := Map(
        "Left", "Left",
        "Right", "Right",
        "Up", "Up",
        "Down", "Down",
        "Bottom", "Down",
        "Top", "Up"
    )
    
    groupsNumpad := Map()
    groupsArrows := Map()
    
    for idx, p in parsed {
        if (p.cmd == "")
            continue
            
        foundNumpad := false
        for suffix, digit in numpadDirections {
            if (SubStr(p.cmd, -StrLen(suffix)) == suffix) {
                base := SubStr(p.cmd, 1, StrLen(p.cmd) - StrLen(suffix))
                keyPattern := "i)^(.*)Numpad" . digit . "$"
                if RegExMatch(p.key, keyPattern, &keyMatch) {
                    prefix := keyMatch[1]
                    gKey := base . "`a" . prefix
                    if !groupsNumpad.Has(gKey)
                        groupsNumpad[gKey] := []
                    groupsNumpad[gKey].Push({index: idx, suffix: suffix, digit: digit})
                    foundNumpad := true
                    break
                }
            }
        }
        
        if (foundNumpad)
            continue
            
        for suffix, dirKey in arrowDirections {
            if (SubStr(p.cmd, -StrLen(suffix)) == suffix) {
                base := SubStr(p.cmd, 1, StrLen(p.cmd) - StrLen(suffix))
                keyPattern := "i)^(.*)" . dirKey . "$"
                if RegExMatch(p.key, keyPattern, &keyMatch) {
                    prefix := keyMatch[1]
                    gKey := base . "`a" . prefix
                    if !groupsArrows.Has(gKey)
                        groupsArrows[gKey] := []
                    groupsArrows[gKey].Push({index: idx, suffix: suffix, dirKey: dirKey})
                    break
                }
            }
        }
    }
    
    skipIndices := Map()
    replaceMap := Map()
    
    for gKey, items in groupsNumpad {
        if (items.Length >= 3) {
            firstIdx := 999999
            for item in items {
                if (item.index < firstIdx)
                    firstIdx := item.index
                skipIndices[item.index] := true
            }
            parts := StrSplit(gKey, "`a")
            base := parts[1]
            prefix := parts[2]
            
            replaceMap[firstIdx] := "[" . base . "X] -> " . prefix . "NumpadX"
            skipIndices.Delete(firstIdx)
        }
    }
    
    for gKey, items in groupsArrows {
        if (items.Length >= 3) {
            firstIdx := 999999
            for item in items {
                if (item.index < firstIdx)
                    firstIdx := item.index
                skipIndices[item.index] := true
            }
            parts := StrSplit(gKey, "`a")
            base := parts[1]
            prefix := parts[2]
            
            replaceMap[firstIdx] := "[" . base . "X] -> " . prefix . "Arrows"
            skipIndices.Delete(firstIdx)
        }
    }
    
    for idx, p in parsed {
        if skipIndices.Has(idx)
            continue
        if replaceMap.Has(idx) {
            reduced.Push(replaceMap[idx])
        } else {
            reduced.Push(p.line)
        }
    }
    
    return reduced
}

StartKeyDiagnostics() {
    testItems := [
        ; --- Numpad5 tests ---
        { name: "Numpad5", key: "Numpad5", label: "Numpad5", ctrl: false, alt: false, shift: false, win: false },
        { name: "Shift + Numpad5", key: "Numpad5", label: "Shift + Numpad5", ctrl: false, alt: false, shift: true, win: false },
        { name: "Ctrl + Numpad5", key: "Numpad5", label: "Ctrl + Numpad5", ctrl: true, alt: false, shift: false, win: false },
        { name: "Alt + Numpad5", key: "Numpad5", label: "Alt + Numpad5", ctrl: false, alt: true, shift: false, win: false },
        { name: "Win + Numpad5", key: "Numpad5", label: "Win + Numpad5", ctrl: false, alt: false, shift: false, win: true },
        { name: "Win + Alt + Numpad5", key: "Numpad5", label: "Win + Alt + Numpad5", ctrl: false, alt: true, shift: false, win: true },
        { name: "Win + Shift + Numpad5", key: "Numpad5", label: "Win + Shift + Numpad5", ctrl: false, alt: false, shift: true, win: true },
        { name: "Win + Ctrl + Numpad5", key: "Numpad5", label: "Win + Ctrl + Numpad5", ctrl: true, alt: false, shift: false, win: true },
        { name: "Win + Ctrl + Shift + Numpad5", key: "Numpad5", label: "Win + Ctrl + Shift + Numpad5", ctrl: true, alt: false, shift: true, win: true },
        { name: "Win + Ctrl + Alt + Numpad5", key: "Numpad5", label: "Win + Ctrl + Alt + Numpad5", ctrl: true, alt: true, shift: false, win: true },

        ; --- Left arrow tests ---
        { name: "Left", key: "Left", label: "Left Arrow", ctrl: false, alt: false, shift: false, win: false },
        { name: "Shift + Left", key: "Left", label: "Shift + Left Arrow", ctrl: false, alt: false, shift: true, win: false },
        { name: "Ctrl + Left", key: "Left", label: "Ctrl + Left Arrow", ctrl: true, alt: false, shift: false, win: false },
        { name: "Alt + Left", key: "Left", label: "Alt + Left Arrow", ctrl: false, alt: true, shift: false, win: false },
        { name: "Win + Left", key: "Left", label: "Win + Left Arrow", ctrl: false, alt: false, shift: false, win: true },
        { name: "Win + Alt + Left", key: "Left", label: "Win + Alt + Left Arrow", ctrl: false, alt: true, shift: false, win: true },
        { name: "Win + Shift + Left", key: "Left", label: "Win + Shift + Left Arrow", ctrl: false, alt: false, shift: true, win: true },
        { name: "Win + Ctrl + Left", key: "Left", label: "Win + Ctrl + Left Arrow", ctrl: true, alt: false, shift: false, win: true },
        { name: "Win + Ctrl + Shift + Left", key: "Left", label: "Win + Ctrl + Shift + Left Arrow", ctrl: true, alt: false, shift: true, win: true },
        { name: "Win + Ctrl + Alt + Left", key: "Left", label: "Win + Ctrl + Alt + Left Arrow", ctrl: true, alt: true, shift: false, win: true }
    ]

    ; Store previous suspend state
    oldSuspend := g_bSuspended

    ; Suspend the physical hotkeys temporarily while testing so they don't fire actions!
    Suspend(true)
    global g_bSuspended := true

    ; Create a gorgeous polished dark-themed diagnostic GUI
    diagGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "🤖 HotWinAHK - Key Diagnostics")
    diagGui.BackColor := "121214"
    diagGui.SetFont("s10 cE0E0E6", "Segoe UI")

    diagGui.SetFont("s14 bold c4476ff")
    diagGui.Add("Text", "x20 y20 w460 Center", "🤖 Key Diagnostics Testing Menu")
    
    diagGui.SetFont("s10 c88888D")
    diagGui.Add("Text", "x20 y52 w460 Center", "Testing keyboard hooks & physical modifiers compatibility")

    ; Separator
    diagGui.Add("Text", "x20 y75 w460 h2 BackgroundTrans Center c33333A", "__________________________________________________________________")

    diagGui.SetFont("s10 c88888D")
    diagGui.Add("Text", "x20 y105 w460 Center", "PLEASE PRESS THE FOLLOWING KEY:")

    diagGui.SetFont("s18 bold cFFCC00")
    diagGui_KeyText := diagGui.Add("Text", "x20 y130 w460 Center", "Starting test...")

    diagGui.SetFont("s11 bold cFF4444")
    diagGui_TimerText := diagGui.Add("Text", "x20 y175 w460 Center", "Time Remaining: 5s")

    diagGui.SetFont("s9 c88888D")
    diagGui.Add("Text", "x20 y212 w460 Center", "[Press ESC key to Abort Diagnostics Sequence]")

    diagGui.Show("w500 h250 Center")

    failedKeys := []
    isAborted := false

    for idx, item in testItems {
        if (isAborted) {
            break
        }

        ; Display the target combination
        diagGui_KeyText.Text := item.name
        
        timeoutMs := 5000
        startTime := A_TickCount
        passed := false

        while (A_TickCount - startTime < timeoutMs) {
            elapsed := A_TickCount - startTime
            remainingTime := Ceil((timeoutMs - elapsed) / 1000)
            diagGui_TimerText.Text := "Time Remaining: " . (remainingTime <= 0 ? 0 : remainingTime) . "s"

            ; Small sleep / input hook check loop to update UI and process keypresses
            ih := InputHook("L1 T0.1")
            ih.KeyOpt("{All}", "E")
            ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-E") ; do not trigger on modifier alone
            ih.Start()
            ih.Wait()

            if (ih.EndReason == "EndKey") {
                pressedKey := ih.EndKey
                
                if (StrLower(pressedKey) == "escape") {
                    isAborted := true
                    break
                }

                ; Query physical modifier keys
                mCtrl  := GetKeyState("Ctrl", "P")
                mAlt   := GetKeyState("Alt", "P")
                mShift := GetKeyState("Shift", "P")
                mWin   := (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))

                ctrlMatch  := (mCtrl == item.ctrl)
                altMatch   := (mAlt == item.alt)
                shiftMatch := (mShift == item.shift)
                winMatch   := (mWin == item.win)
                keyMatch   := (StrLower(pressedKey) == StrLower(item.key) || (StrLower(item.key) == "numpad5" && StrLower(pressedKey) == "numpadclear"))

                if (ctrlMatch && altMatch && shiftMatch && winMatch && keyMatch) {
                    passed := true
                    break
                }
            }
        }

        if (isAborted) {
            break
        }

        if (passed) {
            ; Success! Show passed feedback and beep
            try {
                diagGui_TimerText.SetFont("c00FF55")
                diagGui_TimerText.Text := "PASSED!"
            }
            if (!g_SettingsSilenceAll) {
                SoundBeep(1800, 40)
            }
            Sleep(250)
            try {
                diagGui_TimerText.SetFont("cFF4444")
            }
        } else {
            ; Failure! Show fail tooltip and record failure
            failedKeys.Push(item.name)
            if (!g_SettingsSilenceAll) {
                SoundBeep(350, 150)
            }
            ShowTargetToolTip("FAILED: " . item.name, -1500)
            Sleep(200)
        }
    }

    diagGui.Destroy()

    ; Restore suspend state
    Suspend(oldSuspend)
    global g_bSuspended := oldSuspend

    if (isAborted) {
        ShowTargetToolTip("Diagnostics Aborted by User!", -2000)
        return
    }

    ; Formulate clipboard text
    if (failedKeys.Length > 0) {
        clipText := "=== HotWinAHK Key Diagnostics Failed Keys ===`r`n`r`n"
        for k in failedKeys {
            clipText .= k . "`r`n"
        }
        A_Clipboard := clipText
        ShowTargetToolTip("Diagnostics Complete!`r`n" . failedKeys.Length . " key(s) failed. List copied to clipboard!", -4000)
    } else {
        A_Clipboard := "All keys passed!"
        ShowTargetToolTip("🤖 All keys passed diagnostics flawlessly!`r`nList copied to clipboard.", -4000)
    }
}

LoadSettings() {
    global g_SettingsSilenceAll, g_SettingsSilentOnWinCmds, g_SettingsTipWinCmds, g_SettingsDisableStartupBeep, g_SettingsDisableSuspensionBeep, g_SettingsEditorPath, g_sIniFile
    
    try {
        valSilenceAll := IniRead(g_sIniFile, "Settings", "SilenceAll", "false")
        g_SettingsSilenceAll := (valSilenceAll = "true" || valSilenceAll = 1 || valSilenceAll = "1")
    } catch {
        g_SettingsSilenceAll := false
    }
    
    try {
        valSilentOnWinCmds := IniRead(g_sIniFile, "Settings", "SilentOnWinCmds", "false")
        g_SettingsSilentOnWinCmds := (valSilentOnWinCmds = "true" || valSilentOnWinCmds = 1 || valSilentOnWinCmds = "1")
    } catch {
        g_SettingsSilentOnWinCmds := false
    }
    
    try {
        valTipWinCmds := IniRead(g_sIniFile, "Settings", "TipWinCmds", "true")
        g_SettingsTipWinCmds := (valTipWinCmds = "true" || valTipWinCmds = 1 || valTipWinCmds = "1")
    } catch {
        g_SettingsTipWinCmds := true
    }

    try {
        valDisableStartup := IniRead(g_sIniFile, "Settings", "DisableStartupBeep", "false")
        g_SettingsDisableStartupBeep := (valDisableStartup = "true" || valDisableStartup = 1 || valDisableStartup = "1")
    } catch {
        g_SettingsDisableStartupBeep := false
    }

    try {
        valDisableSuspension := IniRead(g_sIniFile, "Settings", "DisableSuspensionBeep", "false")
        g_SettingsDisableSuspensionBeep := (valDisableSuspension = "true" || valDisableSuspension = 1 || valDisableSuspension = "1")
    } catch {
        g_SettingsDisableSuspensionBeep := false
    }

    try {
        localAppData := ""
        try localAppData := EnvGet("LOCALAPPDATA")
        cursorPath := localAppData != "" ? localAppData . "\Programs\cursor\Cursor.exe" : ""
        defaultEd := (cursorPath != "" && FileExist(cursorPath)) ? cursorPath : "notepad.exe"
        
        g_SettingsEditorPath := IniRead(g_sIniFile, "Settings", "EditorPath", defaultEd)
    } catch {
        g_SettingsEditorPath := "notepad.exe"
    }
}

StartSettingsDialog() {
    global g_SettingsSilenceAll, g_SettingsSilentOnWinCmds, g_SettingsTipWinCmds, g_SettingsDisableStartupBeep, g_SettingsDisableSuspensionBeep, g_SettingsEditorPath, g_sIniFile

    ; Ensure we load the freshest settings
    LoadSettings()

    ; Create Gui with dark theme
    settingsGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "🤖 HotWinAHK - Settings")
    settingsGui.BackColor := "121214"
    settingsGui.SetFont("s10 cE0E0E6", "Segoe UI")

    settingsGui.SetFont("s14 bold c4476ff")
    settingsGui.Add("Text", "x20 y20 w560 Center", "🤖 Engine Settings Configurations")

    ; Separator
    settingsGui.Add("Text", "x20 y50 w560 h2 BackgroundTrans Center c33333A", "_______________________________________________________________________________")

    ; Checkboxes
    settingsGui.SetFont("s10 cE0E0E6")
    chkSilenceAll := settingsGui.Add("Checkbox", "x50 y80 w500 h22" . (g_SettingsSilenceAll ? " Checked" : ""), "Silence All Audio Cues / SoundBeeps")
    chkSilentOnWinCmds := settingsGui.Add("Checkbox", "x50 y110 w500 h22" . (g_SettingsSilentOnWinCmds ? " Checked" : ""), "Silent on Window Movement Commands")
    chkTipWinCmds := settingsGui.Add("Checkbox", "x50 y140 w500 h22" . (g_SettingsTipWinCmds ? " Checked" : ""), "Show Cursor Tooltips for Window Commands")
    
    ; granular beep options
    chkDisableStartup := settingsGui.Add("Checkbox", "x50 y170 w500 h22" . (g_SettingsDisableStartupBeep ? " Checked" : ""), "Silence Startup Major Triad Arpeggio Beep")
    chkDisableSuspension := settingsGui.Add("Checkbox", "x50 y200 w500 h22" . (g_SettingsDisableSuspensionBeep ? " Checked" : ""), "Silence Toggle-Suspension Beeps")

    ; Separator
    settingsGui.Add("Text", "x20 y230 w560 h2 BackgroundTrans Center c33333A", "_______________________________________________________________________________")

    ; Editor path setting row
    settingsGui.SetFont("s10 bold c00FFCC")
    settingsGui.Add("Text", "x30 y255 w100 h22", "Editor Path:")
    settingsGui.SetFont("s9.5 norm cFFFFFF")
    txtEditorPath := settingsGui.Add("Edit", "x130 y252 w440 h24 Background1E1E22 cFFFFFF Border", g_SettingsEditorPath)

    ; Separator
    settingsGui.Add("Text", "x20 y285 w560 h2 BackgroundTrans Center c33333A", "_______________________________________________________________________________")

    ; Buttons
    settingsGui.SetFont("s10")
    btnSave := settingsGui.Add("Button", "x150 y310 w120 h35", "Save Settings")
    btnCancel := settingsGui.Add("Button", "x330 y310 w120 h35", "Cancel")

    ; Callbacks
    btnSave.OnEvent("Click", SaveClick)
    btnCancel.OnEvent("Click", CancelClick)
    settingsGui.OnEvent("Escape", CancelClick)

    settingsGui.Show("w600 h365 Center")

    SaveClick(*) {
        isSilenceAll := chkSilenceAll.Value
        isSilentOnWinCmds := chkSilentOnWinCmds.Value
        isTipWinCmds := chkTipWinCmds.Value
        isDisableStartup := chkDisableStartup.Value
        isDisableSuspension := chkDisableSuspension.Value
        editorPathStr := Trim(txtEditorPath.Value)

        try {
            IniWrite(isSilenceAll ? "true" : "false", g_sIniFile, "Settings", "SilenceAll")
            IniWrite(isSilentOnWinCmds ? "true" : "false", g_sIniFile, "Settings", "SilentOnWinCmds")
            IniWrite(isTipWinCmds ? "true" : "false", g_sIniFile, "Settings", "TipWinCmds")
            IniWrite(isDisableStartup ? "true" : "false", g_sIniFile, "Settings", "DisableStartupBeep")
            IniWrite(isDisableSuspension ? "true" : "false", g_sIniFile, "Settings", "DisableSuspensionBeep")
            IniWrite(editorPathStr, g_sIniFile, "Settings", "EditorPath")
        }

        global g_SettingsSilenceAll := isSilenceAll
        global g_SettingsSilentOnWinCmds := isSilentOnWinCmds
        global g_SettingsTipWinCmds := isTipWinCmds
        global g_SettingsDisableStartupBeep := isDisableStartup
        global g_SettingsDisableSuspensionBeep := isDisableSuspension
        global g_SettingsEditorPath := editorPathStr

        settingsGui.Destroy()
        if (!g_SettingsSilenceAll) {
            SoundBeep(1200, 100)
        }
        ShowTargetToolTip("Settings saved successfully!")
    }

    CancelClick(*) {
        settingsGui.Destroy()
    }
}

BuildBindingsMap() {
    global g_sIniFile
    bindingsMap := Map()
    
    if !FileExist(g_sIniFile) {
        return bindingsMap
    }
    
    sectionsText := IniRead(g_sIniFile)
    loop parse, sectionsText, "`n", "`r" {
        sCmd := Trim(A_LoopField)
        if (sCmd == "" || SubStr(sCmd, 1, 1) == "-") {
            continue
        }
        
        loop 10 {
            currentKeyProp := "keys" A_Index
            keyValue := IniRead(g_sIniFile, sCmd, currentKeyProp, "")
            if (keyValue == "") {
                break
            }
            
            if InStr(keyValue, "|") {
                aSplit := StrSplit(keyValue, "|")
                sStroke := Trim(aSplit[1])
            } else {
                sStroke := Trim(keyValue)
            }
            
            parts := StrSplit(sStroke, "+")
            hasWin := false
            hasCtrl := false
            hasAlt := false
            hasShift := false
            mainKey := ""
            
            for part in parts {
                p := Trim(part)
                if (RegExMatch(p, "i)^(LWin|RWin|Win)$")) {
                    hasWin := true
                } else if (RegExMatch(p, "i)^(LCtrl|RCtrl|Ctrl)$")) {
                    hasCtrl := true
                } else if (RegExMatch(p, "i)^(LAlt|RAlt|Alt)$")) {
                    hasAlt := true
                } else if (RegExMatch(p, "i)^(LShift|RShift|Shift)$")) {
                    hasShift := true
                } else {
                    mainKey := StrLower(p)
                }
            }
            
            canonical := ""
            if (hasWin)
                canonical .= "Win+"
            if (hasCtrl)
                canonical .= "Ctrl+"
            if (hasAlt)
                canonical .= "Alt+"
            if (hasShift)
                canonical .= "Shift+"
            canonical .= mainKey
            
            bindingsMap[canonical] := sCmd
        }
    }
    return bindingsMap
}

StartKeyQuery() {
    global g_SettingsSilenceAll
    bindingsMap := BuildBindingsMap()

    oldSuspend := g_bSuspended

    Suspend(true)
    global g_bSuspended := true

    queryGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "🤖 HotWinAHK - Key Query")
    queryGui.BackColor := "121214"
    queryGui.SetFont("s10 cE0E0E6", "Segoe UI")

    queryGui.SetFont("s14 bold c4476ff")
    queryGui.Add("Text", "x20 y20 w460 Center", "🤖 Key Query Mode")
    
    queryGui.SetFont("s10 c88888D")
    queryGui.Add("Text", "x20 y52 w460 Center", "Detecting physical keystrokes and showing their registered commands")

    queryGui.Add("Text", "x20 y75 w460 h2 BackgroundTrans Center c33333A", "__________________________________________________________________")

    queryGui.SetFont("s11 bold cFFCC00")
    queryGui_DetectedText := queryGui.Add("Text", "x20 y115 w460 Center", "READY: Press any combination...")

    queryGui.SetFont("s14 bold c00FF55")
    queryGui_CommandText := queryGui.Add("Text", "x20 y145 w460 Center", "")

    queryGui.SetFont("s10 bold c88888D")
    queryGui_CopyText := queryGui.Add("Text", "x20 y185 w460 Center", "")

    queryGui.SetFont("s10 norm c88888D")
    queryGui.Add("Text", "x20 y215 w460 Center", "[ESC to Close • Spacebar to Copy Current Binding]")

    queryGui.Show("w500 h255 Center")

    lastPressedKey := ""
    lastDispName := ""
    lastMatchedCmd := ""

    while (true) {
        ih := InputHook("L1 T2.0") ; No overall timer, just check short intervals to maintain GUI responsive loop
        ih.KeyOpt("{All}", "E")
        ih.KeyOpt("{LCtrl}{RCtrl}{LShift}{RShift}{LAlt}{RAlt}{LWin}{RWin}", "-E")
        ih.Start()
        ih.Wait()

        if (ih.EndReason == "EndKey") {
            pressedKey := ih.EndKey
            
            if (StrLower(pressedKey) == "escape") {
                break
            }

            mCtrl  := GetKeyState("Ctrl", "P")
            mAlt   := GetKeyState("Alt", "P")
            mShift := GetKeyState("Shift", "P")
            mWin   := (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))

            if (StrLower(pressedKey) == "space") {
                if (lastDispName != "") {
                    clipboardText := lastDispName . " = " . (lastMatchedCmd != "" ? lastMatchedCmd : "[No Command Bound]")
                    A_Clipboard := clipboardText
                    queryGui_CopyText.SetFont("c00FF55")
                    queryGui_CopyText.Text := "📋 Copied: " . clipboardText
                    if (!g_SettingsSilenceAll) {
                        SoundBeep(1500, 100)
                    }
                } else {
                    queryGui_CopyText.SetFont("cFF3333")
                    queryGui_CopyText.Text := "⚠️ Press any key combinations first!"
                }
                continue
            }

            dispName := ""
            if (mWin)
                dispName .= "Win + "
            if (mCtrl)
                dispName .= "Ctrl + "
            if (mAlt)
                dispName .= "Alt + "
            if (mShift)
                dispName .= "Shift + "
            dispName .= pressedKey

            canonicalKey := ""
            if (mWin)
                canonicalKey .= "Win+"
            if (mCtrl)
                canonicalKey .= "Ctrl+"
            if (mAlt)
                canonicalKey .= "Alt+"
            if (mShift)
                canonicalKey .= "Shift+"
            canonicalKey .= StrLower(pressedKey)

            queryGui_DetectedText.Text := "Pressed: " . dispName
            lastPressedKey := pressedKey
            lastDispName := dispName

            if (bindingsMap.Has(canonicalKey)) {
                matchedCmd := bindingsMap[canonicalKey]
                queryGui_CommandText.SetFont("c00FF55")
                queryGui_CommandText.Text := "Command: " . matchedCmd
                lastMatchedCmd := matchedCmd
                
                if (!g_SettingsSilenceAll) {
                    SoundBeep(1200, 50)
                }
            } else {
                queryGui_CommandText.SetFont("cFF3333")
                queryGui_CommandText.Text := "[No Command Bound]"
                lastMatchedCmd := ""
                if (!g_SettingsSilenceAll) {
                    SoundBeep(600, 80)
                }
            }
            
            ; Reset transient copy tooltip indicator upon pressing new keys
            queryGui_CopyText.SetFont("c88888D")
            queryGui_CopyText.Text := "[Spacebar to Copy Current Binding]"
        }
    }

    queryGui.Destroy()

    Suspend(oldSuspend)
    global g_bSuspended := oldSuspend

    ShowTargetToolTip("Key Query Complete.")
}

SysMenu() {
    sysCmds := []
    commandList := GetGlobalCommandList()
    for item in commandList {
        if (item.cat == "SYSTEM") {
            sysCmds.Push(item)
        }
    }
    
    sysMenu := Menu()
    for item in sysCmds {
        targetCmd := item.cmd
        displayName := targetCmd
        if (item.key != "" && item.key != "Custom" && item.key != "Auto Indicator") {
            displayName .= "  (" . item.key . ")"
        }
        sysMenu.Add(displayName, SysMenuHandler.Bind(targetCmd))
    }
    
    sysMenu.Show()
}
SysMenuHandler(targetCmd, itemName, itemPos, actualMenu) {
    ExecuteActionWithCondition(targetCmd, "")
}

GetModifierGroupCode(sStroke) {
    bCtrl := RegExMatch(sStroke, "i)(Ctrl|LCtrl|RCtrl)")
    bAlt := RegExMatch(sStroke, "i)(Alt|LAlt|RAlt)")
    bShift := RegExMatch(sStroke, "i)(Shift|LShift|RShift)")
    bWin := RegExMatch(sStroke, "i)(Win|LWin|RWin)")

    prefix := bWin ? "w+ " : ""
    
    suffix := ""
    if (bCtrl && bAlt && bShift)
        suffix := "cas"
    else if (bCtrl && bAlt)
        suffix := "ca"
    else if (bCtrl && bShift)
        suffix := "cs"
    else if (bCtrl)
        suffix := "c"
    else if (bAlt && bShift)
        suffix := "as"
    else if (bAlt)
        suffix := "a"
    else if (bShift)
        suffix := "s"
    else
        suffix := "_"
        
    return prefix . suffix
}

GetHardwareCategory(sStroke) {
    sCleanKey := RegExReplace(sStroke, "i)(LCtrl\+|RCtrl\+|Ctrl\+|LAlt\+|RAlt\+|Alt\+|LShift\+|RShift\+|Shift\+|LWin\+|RWin\+|Win\+|Double\+)", "")
    sCleanKey := StrReplace(sCleanKey, " ", "")
    sCleanLower := StrLower(sCleanKey)
    
    if (sCleanLower == "left" || sCleanLower == "right" || sCleanLower == "up" || sCleanLower == "down" || sCleanLower == "arrows") {
        return "Arrows"
    } else if (InStr(sCleanLower, "numpad") == 1) {
        return "Numpad"
    } else {
        return "Alphanumeric"
    }
}

#HotIf (g_ActiveUntuckedHwnd != 0 && IsMouseOverHwnd(g_ActiveUntuckedHwnd))
$LButton:: {
    HandleTuckedDrag()
}
#HotIf
; #endregion

; =======================================================================================
;          NEW IMPLEMENTATIONS FOR STOWED WINDOW MANAGERS & DOT INDICATOR
; =======================================================================================

MakeProgressBarStr(val, maxVal) {
    pct := (val < 0) ? 0 : (val > maxVal ? 1 : val / maxVal)
    filledCount := Round(pct * 10)
    emptyCount := 10 - filledCount
    bar := ""
    Loop filledCount {
        bar .= "█"
    }
    Loop emptyCount {
        bar .= "░"
    }
    return bar
}

UpdateActiveWindowDot() {
    global g_DotGui, g_bSuspended
    
    ; Get the active window handle
    activeHwnd := DllCall("GetForegroundWindow", "ptr")
    if (activeHwnd == 0 || !WinExist("ahk_id " . activeHwnd)) {
        if (g_DotGui) {
            try g_DotGui.Hide()
        }
        return
    }
    
    ; Skip painting the dot on on-screen-keyboard, taskbar, tooltips, or our own help & utility windows!
    try {
        winClass := WinGetClass("ahk_id " . activeHwnd)
        winTitle := WinGetTitle("ahk_id " . activeHwnd)
        if (InStr(winClass, "Shell_TrayWnd") || InStr(winClass, "Progman") || InStr(winClass, "WorkerW") || InStr(winTitle, "HotWinAHK")) {
            if (g_DotGui) {
                try g_DotGui.Hide()
            }
            return
        }
    } catch {
        return
    }
    
    ; Determine dot color: green when program is not suspended, otherwise yellow
    dotColor := g_bSuspended ? "EEDC00" : "00FF55"
    
    ; If GUI doesn't exist, instantiate it
    if (g_DotGui == "") {
        g_DotGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; Click-through
    }
    
    ; Update color and position
    g_DotGui.BackColor := dotColor
    
    try {
        WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " . activeHwnd)
        ; Position dot at top-left inside window boundaries
        if (wW > 100 && wH > 100) {
            g_DotGui.Show("x" . (wX + 12) . " y" . (wY + 12) . " w8 h8 NoActivate")
        } else {
            g_DotGui.Hide()
        }
    } catch {
        try g_DotGui.Hide()
    }
}

RevealTuckedWindow(closestHwnd, targetEdge, activeTuckProfile) {
    try {
        global g_BaselineActiveWindow := DllCall("GetForegroundWindow", "ptr")
        global g_PeekX, g_PeekY, g_ActiveUntuckedHwnd, g_UntuckGraceTicks
        
        hMon := DllCall("MonitorFromWindow", "ptr", closestHwnd, "uint", 2, "ptr")
        MI := Buffer(40)
        NumPut("uint", 40, MI, 0)
        mLeft := 0, mTop := 0, mRight := A_ScreenWidth, mBottom := A_ScreenHeight
        if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
            mLeft   := NumGet(MI, 20, "int")
            mTop    := NumGet(MI, 24, "int")
            mRight  := NumGet(MI, 28, "int")
            mBottom := NumGet(MI, 32, "int")
        }

        WinGetPos(&tX, &tY, &tW, &tH, closestHwnd)

        nX := tX
        nY := tY
        switch targetEdge {
            case "Left":
                nX := mLeft
            case "Right":
                nX := mRight - Number(activeTuckProfile.w)
            case "Top":
                nY := mTop
            case "Bottom":
                nY := mBottom - Number(activeTuckProfile.h)
        }

        ; Slide open cleanly
        SafeMove(nX, nY, Number(activeTuckProfile.w), Number(activeTuckProfile.h), closestHwnd)
        
        WinSetAlwaysOnTop(1, "ahk_id " . closestHwnd)
        WinSetAlwaysOnTop(0, "ahk_id " . closestHwnd)
        WinMoveTop("ahk_id " . closestHwnd)

        ; Ensure window draws on top without stealing focus
        DllCall("SetWindowPos", "ptr", closestHwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0053)

        g_PeekX := nX
        g_PeekY := nY
        g_ActiveUntuckedHwnd := closestHwnd
        g_UntuckGraceTicks := 10

        SetTimer(TrackUntuckedFocusLifecycle, 0)
        SetTimer(TrackUntuckedFocusLifecycle, 50)
    }
}

Menu_TuckedPeek(filterEdge := "") {
    global g_TuckedWindows
    if (g_TuckedWindows.Count == 0) {
        ShowTargetToolTip("No windows are currently tucked.")
        return
    }
    
    normalizedFilter := StrLower(filterEdge)
    if (normalizedFilter == "top")
        normalizedFilter := "up"
    if (normalizedFilter == "bottom")
        normalizedFilter := "down"
        
    matchedCount := 0
    mMenu := Menu()
    mTitle := filterEdge != "" ? "--- Stowed Windows Menu (" . filterEdge . ") ---" : "--- Stowed Windows Menu ---"
    mMenu.Add(mTitle, (*) => 0)
    mMenu.Disable(mTitle)
    mMenu.Add()
    
    for hwnd, profile in g_TuckedWindows {
        if (!WinExist("ahk_id " . hwnd)) {
            continue
        }
        
        if (filterEdge != "") {
            profileEdge := StrLower(profile.edge)
            if (profileEdge == "top")
                profileEdge := "up"
            if (profileEdge == "bottom")
                profileEdge := "down"
            if (profileEdge != normalizedFilter) {
                continue
            }
        }
        
        matchedCount++
        wTitle := WinGetTitle("ahk_id " . hwnd)
        if (wTitle == "") {
            wTitle := "Untitled (ahk_id " . hwnd . ")"
        }
        if (StrLen(wTitle) > 50) {
            wTitle := SubStr(wTitle, 1, 47) . "..."
        }
        
        menuLabel := "[" . profile.edge . "] " . wTitle . " [0x" . Format("{:X}", hwnd) . "]"
        mMenu.Add(menuLabel, Menu_PeekTucked_Callback.Bind(hwnd, profile.edge, profile))
    }
    
    if (matchedCount == 0) {
        ShowTargetToolTip("No windows are currently tucked on the " . filterEdge . " edge.")
        return
    }
    
    mMenu.Show()
}

Menu_PeekTucked_Callback(hwnd, edge, profile, *) {
    RevealTuckedWindow(hwnd, edge, profile)
}

Menu_Untuck() {
    global g_TuckedWindows
    if (g_TuckedWindows.Count == 0) {
        ShowTargetToolTip("No windows are currently tucked.")
        return
    }
    
    mMenu := Menu()
    mMenu.Add("--- Select Window to Untuck ---", (*) => 0)
    mMenu.Disable("--- Select Window to Untuck ---")
    mMenu.Add()
    
    for hwnd, profile in g_TuckedWindows {
        if (!WinExist("ahk_id " . hwnd)) {
            continue
        }
        wTitle := WinGetTitle("ahk_id " . hwnd)
        if (wTitle == "") {
            wTitle := "Untitled (ahk_id " . hwnd . ")"
        }
        if (StrLen(wTitle) > 50) {
            wTitle := SubStr(wTitle, 1, 47) . "..."
        }
        
        menuLabel := "[" . profile.edge . "] " . wTitle . " [0x" . Format("{:X}", hwnd) . "]"
        mMenu.Add(menuLabel, Menu_Untuck_Callback.Bind(hwnd, profile))
    }
    
    mMenu.Show()
}

Menu_Untuck_Callback(hwnd, profile, *) {
    global g_TuckedWindows, g_ActiveUntuckedHwnd, g_IsUntuckLocked
    
    if (g_TuckedWindows.Has(hwnd)) {
        g_TuckedWindows.Delete(hwnd)
    }
    
    SoundBeep(1200, 100)
    
    ; Restore original coordinate positioning
    SafeMove(Number(profile.x), Number(profile.y), Number(profile.w), Number(profile.h), hwnd)
    WinActivate("ahk_id " . hwnd)
    
    if (g_ActiveUntuckedHwnd == hwnd) {
        g_ActiveUntuckedHwnd := 0
    }
    g_IsUntuckLocked := false
    SetTimer(TrackUntuckedFocusLifecycle, 0)
    SetTimer(ExecuteCleanBumperReArm, -100)
    
    ShowTargetToolTip("Window untucked & restored!")
}

FindLineX(coord, gX, pX) {
    bestIdx := 0
    minDiff := 999999
    approx := Round((coord - gX) / (pX / 2))
    Loop 5 {
        testIdx := approx - 3 + A_Index
        if (testIdx < 0)
            continue
        diff := Abs(coord - (gX + Floor(testIdx / 2) * pX + (Mod(testIdx, 2) == 0 ? 0 : 209)))
        if (diff < minDiff) {
            minDiff := diff
            bestIdx := testIdx
        }
    }
    return bestIdx
}

FindRightX(coord, gX, pX) {
    bestIdx := 0
    minDiff := 999999
    approx := Round((coord + 6 - gX) / (pX / 2))
    Loop 5 {
        testIdx := approx - 3 + A_Index
        if (testIdx < 0)
            continue
        diff := Abs(coord - (gX + Floor(testIdx / 2) * pX + (Mod(testIdx, 2) == 0 ? -6 : 209)))
        if (diff < minDiff) {
            minDiff := diff
            bestIdx := testIdx
        }
    }
    return bestIdx
}

FindLineY(coord, gY, pY) {
    bestIdx := 0
    minDiff := 999999
    approx := Round((coord - gY) / (pY / 2))
    Loop 5 {
        testIdx := approx - 3 + A_Index
        if (testIdx < 0)
            continue
        diff := Abs(coord - (gY + Floor(testIdx / 2) * pY + (Mod(testIdx, 2) == 0 ? 0 : 113)))
        if (diff < minDiff) {
            minDiff := diff
            bestIdx := testIdx
        }
    }
    return bestIdx
}

FindBottomY(coord, gY, pY) {
    bestIdx := 0
    minDiff := 999999
    approx := Round((coord + 6 - gY) / (pY / 2))
    Loop 5 {
        testIdx := approx - 3 + A_Index
        if (testIdx < 0)
            continue
        diff := Abs(coord - (gY + Floor(testIdx / 2) * pY + (Mod(testIdx, 2) == 0 ? -6 : 113)))
        if (diff < minDiff) {
            minDiff := diff
            bestIdx := testIdx
        }
    }
    return bestIdx
}

; =======================================================================================
; WM_COPYDATA / IPC MESSAGE HANDLER FOR EXTERNAL COMMAND TRIGGERING (e.g. from AutoIt)
; =======================================================================================
ReceiveCopyData(wParam, lParam, msg, hwnd) {
    lpData := NumGet(lParam, A_PtrSize * 2, "UPtr")
    if (!lpData)
        return 1
    cbData := NumGet(lParam, A_PtrSize, "UInt")
    dataStr := StrGet(lpData, cbData, "UTF-8")
    
    parts := StrSplit(dataStr, "|")
    if (parts.Length >= 1) {
        cmd := Trim(parts[1])
        targetHwnd := 0
        if (parts.Length >= 2) {
            targetHwnd := Integer(parts[2])
        }
        
        if (cmd != "") {
            if (targetHwnd && WinExist("ahk_id " . targetHwnd)) {
                ExecuteCommandRegistry(cmd, targetHwnd)
            } else {
                ExecuteActionWithCondition(cmd, "")
            }
        }
    }
    return 1
}

; =======================================================================================
; WINDOW HOME PERSISTENT COORDINATE STORAGE AND INTERACTIVE COMMAND ENGINE
; =======================================================================================
Global g_mPreHomePositions := Map()
Global g_mHomeCountdown := Map()

GetWindowHomeKey(hWnd) {
    try {
        sClass := WinGetClass(hWnd)
        sExe := StrLower(WinGetProcessName(hWnd))
        sTitle := WinGetTitle(hWnd)
    } catch {
        return ""
    }

    sHomeIni := A_ScriptDir "\window-hotkeys-homes.ini"
    if (!FileExist(sHomeIni)) {
        return ""
    }

    try {
        iniText := FileRead(sHomeIni)
    } catch {
        return ""
    }

    bestKey := ""
    bestScore := -1

    inHomesSection := false
    Loop Parse, iniText, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line == "")
            continue
        if (RegExMatch(line, "i)^\[Homes\]")) {
            inHomesSection := true
            continue
        } else if (RegExMatch(line, "^\[")) {
            inHomesSection := false
            continue
        }

        if (!inHomesSection)
            continue

        eqPos := InStr(line, "=")
        if (!eqPos)
            continue

        fullKey := SubStr(line, 1, eqPos - 1)

        iniClass := ""
        iniExe := ""
        iniTitle := ""

        if (RegExMatch(fullKey, "i)Class:\s*([^|]*)", &matchClass)) {
            iniClass := Trim(matchClass[1])
        }
        if (RegExMatch(fullKey, "i)Exe:\s*([^|]*)", &matchExe)) {
            iniExe := StrLower(Trim(matchExe[1]))
        }
        if (RegExMatch(fullKey, "i)Title:\s*(.*)$", &matchTitle)) {
            iniTitle := Trim(matchTitle[1])
        }

        if (iniClass != "" && sClass != iniClass)
            continue
        if (iniExe != "" && sExe != iniExe)
            continue

        if (iniTitle != "") {
            if (!InStr(sTitle, iniTitle) && !InStr(iniTitle, sTitle)) {
                continue
            }
        }

        score := 0
        if (iniClass != "") score += 1
        if (iniExe != "") score += 2
        if (iniTitle != "") score += 10 + StrLen(iniTitle)

        if (score > bestScore) {
            bestScore := score
            bestKey := fullKey
        }
    }

    return bestKey
}

GetWindowHomePos(hWnd, &outKey) {
    outKey := GetWindowHomeKey(hWnd)
    if (outKey == "") {
        return ""
    }
    sHomeIni := A_ScriptDir "\window-hotkeys-homes.ini"
    try {
        return IniRead(sHomeIni, "Homes", outKey, "")
    } catch {
        return ""
    }
}

SetWindowHome(hWnd) {
    try {
        sClass := WinGetClass(hWnd)
        sExe := StrLower(WinGetProcessName(hWnd))
        sTitle := WinGetTitle(hWnd)
        WinGetPos(&X, &Y, &W, &H, hWnd)
    } catch {
        ShowTargetToolTip("Invalid Window Focus.")
        return
    }

    key := "Class: " . sClass . "|Exe: " . sExe . "|Title: " . sTitle
    val := X . "," . Y . "," . W . "," . H
    sHomeIni := A_ScriptDir "\window-hotkeys-homes.ini"
    
    try {
        if (!FileExist(sHomeIni)) {
            FileAppend("[Homes]`r`n", sHomeIni, "UTF-8")
        }
        IniWrite(val, sHomeIni, "Homes", key)
        UpdateSavedHomesCache()
        ShowTargetToolTip("Home Saved!")
    } catch Error as err {
        ShowTargetToolTip("Failed to save home: " . err.Message)
    }
}

ClearWindowHome(hWnd) {
    key := GetWindowHomeKey(hWnd)
    if (key == "") {
        ShowTargetToolTip("No registered home found.")
        return
    }
    sHomeIni := A_ScriptDir "\window-hotkeys-homes.ini"
    try {
        IniDelete(sHomeIni, "Homes", key)
        UpdateSavedHomesCache()
        ShowTargetToolTip("Home Cleared!")
    } catch Error as err {
        ShowTargetToolTip("Failed to clear home: " . err.Message)
    }
}

GoWindowHome(hWnd) {
    posStr := GetWindowHomePos(hWnd, &key)
    if (posStr == "") {
        ShowTargetToolTip("No registered home found.")
        return
    }
    parts := StrSplit(posStr, ",")
    if (parts.Length == 4) {
        try {
            WinGetPos(&origX, &origY, &origW, &origH, hWnd)
            g_mPreHomePositions[hWnd] := {x: origX, y: origY, w: origW, h: origH}
            X := Integer(parts[1])
            Y := Integer(parts[2])
            W := Integer(parts[3])
            H := Integer(parts[4])
            SafeMove(X, Y, W, H, hWnd)
            ShowTargetToolTip("Moved to Saved Home!")
        } catch {
            ShowTargetToolTip("Error relocating to home.")
        }
    }
}

OnHomeCountdownTick(hWnd) {
    if (!g_mHomeCountdown.Has(hWnd)) {
        return
    }
    
    info := g_mHomeCountdown[hWnd]
    info.seconds--

    if (info.seconds <= 0) {
        g_mHomeCountdown.Delete(hWnd)
        ClearToolTip()
        
        if (g_mPreHomePositions.Has(hWnd)) {
            pre := g_mPreHomePositions[hWnd]
            g_mPreHomePositions.Delete(hWnd)
            SafeMove(pre.x, pre.y, pre.w, pre.h, hWnd)
            ShowTargetToolTip("Returned to original position.")
        }
        return
    }

    ShowTargetToolTip("Window is at Home!`nReturning to original position in " . info.seconds . "s...`nTrigger Home again to DELETE home config.", -1200)
    SetTimer(() => OnHomeCountdownTick(hWnd), -1000)
}

InteractiveHome(hWnd) {
    posStr := GetWindowHomePos(hWnd, &key)
    if (posStr == "") {
        ShowTargetToolTip("No registered home found.")
        return
    }
    
    ; Check if countdown is already running
    if (g_mHomeCountdown.Has(hWnd)) {
        g_mHomeCountdown.Delete(hWnd)
        ClearToolTip()
        
        confirm := MsgBox("Strip this window's saved Home position permanently?", "Confirm Delete Home", "YesNo Icon? 262144")
        if (confirm == "Yes") {
            ClearWindowHome(hWnd)
        } else {
            ShowTargetToolTip("Action cancelled.")
        }
        return
    }

    parts := StrSplit(posStr, ",")
    if (parts.Length != 4)
        return

    hX := Integer(parts[1]), hY := Integer(parts[2]), hW := Integer(parts[3]), hH := Integer(parts[4])
    
    try {
        WinGetPos(&X, &Y, &W, &H, hWnd)
        isAtHome := (Abs(X - hX) < 10 && Abs(Y - hY) < 10 && Abs(W - hW) < 10 && Abs(H - hH) < 10)
    } catch {
        isAtHome := false
    }

    if (isAtHome) {
        g_mHomeCountdown[hWnd] := {seconds: 5}
        ShowTargetToolTip("Window is at Home!`nReturning to original position in 5s...`nTrigger Home again to DELETE home config.", -1200)
        SetTimer(() => OnHomeCountdownTick(hWnd), -1000)
    } else {
        ; Save current position first
        try {
            WinGetPos(&origX, &origY, &origW, &origH, hWnd)
            g_mPreHomePositions[hWnd] := {x: origX, y: origY, w: origW, h: origH}
            SafeMove(hX, hY, hW, hH, hWnd)
            ShowTargetToolTip("Moved to Home Position!")
        } catch {
            ShowTargetToolTip("Error relocating to home.")
        }
    }
}

ShowHomePeek(hWnd) {
    posStr := GetWindowHomePos(hWnd, &key)
    if (posStr == "") {
        ShowTargetToolTip("No registered home found to peek.")
        return
    }
    
    parts := StrSplit(posStr, ",")
    if (parts.Length != 4)
        return

    hX := Integer(parts[1])
    hY := Integer(parts[2])
    hW := Integer(parts[3])
    hH := Integer(parts[4])

    try {
        peekGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Owner")
        peekGui.BackColor := "00FFAA"
        WinSetTransparent(90, peekGui)
        peekGui.Show("X" . hX . " Y" . hY . " W" . hW . " H" . hH . " NoActivate")
        SetTimer(() => (peekGui.Destroy()), -1200)
    } catch {
        ; Silent fail
    }
}

UpdateSavedHomesCache() {
    global g_SavedHomesList
    g_SavedHomesList := []
    sHomeIni := A_ScriptDir "\window-hotkeys-homes.ini"
    if (!FileExist(sHomeIni)) {
        return
    }
    try {
        iniText := FileRead(sHomeIni)
    } catch {
        return
    }
    
    inHomesSection := false
    Loop Parse, iniText, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line == "")
            continue
        if (RegExMatch(line, "i)^\[Homes\]")) {
            inHomesSection := true
            continue
        } else if (RegExMatch(line, "^\[")) {
            inHomesSection := false
            continue
        }
        if (!inHomesSection)
            continue

        eqPos := InStr(line, "=")
        if (!eqPos)
            continue

        fullKey := Trim(SubStr(line, 1, eqPos - 1))
        val := Trim(SubStr(line, eqPos + 1))

        iniClass := ""
        iniExe := ""
        iniTitle := ""

        if (RegExMatch(fullKey, "i)Class:\s*([^|]*)", &matchClass)) {
            iniClass := Trim(matchClass[1])
        }
        if (RegExMatch(fullKey, "i)Exe:\s*([^|]*)", &matchExe)) {
            iniExe := StrLower(Trim(matchExe[1]))
        }
        if (RegExMatch(fullKey, "i)Title:\s*(.*)$", &matchTitle)) {
            iniTitle := Trim(matchTitle[1])
        }

        parts := StrSplit(val, ",")
        if (parts.Length == 4) {
            g_SavedHomesList.Push({
                class: iniClass,
                exe: iniExe,
                title: iniTitle,
                x: Integer(parts[1]),
                y: Integer(parts[2]),
                w: Integer(parts[3]),
                h: Integer(parts[4]),
                key: fullKey
            })
        }
    }
}

FindWindowsForHome(home) {
    matchedHwnds := []
    winCriteria := ""
    if (home.class != "")
        winCriteria .= "ahk_class " . home.class . " "
    if (home.exe != "")
        winCriteria .= "ahk_exe " . home.exe
    
    if (winCriteria == "")
        return matchedHwnds

    try {
        hwndList := WinGetList(winCriteria)
        for hWnd in hwndList {
            try {
                if (!DllCall("user32.dll", "bool", "IsWindowVisible", "hwnd", hWnd))
                    continue
                
                if (home.title != "") {
                    sTitle := WinGetTitle(hWnd)
                    if (!InStr(sTitle, home.title) && !InStr(home.title, sTitle))
                        continue
                }
                
                matchedHwnds.Push(hWnd)
            }
        }
    }
    return matchedHwnds
}

UpdateHomeIndicators() {
    global g_HomeIndicators, g_SavedHomesList, g_bSuspended
    
    currentMarkedHwnds := Map()
    
    if (g_bSuspended) {
        for hWnd, indGui in g_HomeIndicators {
            try indGui.Destroy()
        }
        g_HomeIndicators.Clear()
        return
    }
    
    for home in g_SavedHomesList {
        matchedHwnds := FindWindowsForHome(home)
        for hWnd in matchedHwnds {
            if (currentMarkedHwnds.Has(hWnd))
                continue
            
            try {
                WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " . hWnd)
                if (wW < 100 || wH < 100)
                    continue
                
                isAtHome := (Abs(wX - home.x) < 10 && Abs(wY - home.y) < 10 && Abs(wW - home.w) < 10 && Abs(wH - home.h) < 10)
                color := isAtHome ? "00FF55" : "00FFFF" ; Green for at home, Cyan for has home
                
                if (!g_HomeIndicators.Has(hWnd)) {
                    indGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; Click-through
                    g_HomeIndicators[hWnd] := indGui
                } else {
                    indGui := g_HomeIndicators[hWnd]
                }
                
                indGui.BackColor := color
                ; Shift right to x + 28, y + 12 to avoid overlap with the active dot (at x + 12)
                indGui.Show("x" . (wX + 28) . " y" . (wY + 12) . " w8 h8 NoActivate")
                currentMarkedHwnds[hWnd] := true
            }
        }
    }
    
    staleHwnds := []
    for hWnd, indGui in g_HomeIndicators {
        if (!currentMarkedHwnds.Has(hWnd) || !WinExist("ahk_id " . hWnd)) {
            staleHwnds.Push(hWnd)
        }
    }
    for hWnd in staleHwnds {
        try g_HomeIndicators[hWnd].Destroy()
        g_HomeIndicators.Delete(hWnd)
    }
}

UntuckDimension(edge) {
    global g_TuckedWindows
    matched := []
    normalizedEdge := StrLower(edge)
    if (normalizedEdge == "top")
        normalizedEdge := "up"
    if (normalizedEdge == "bottom")
        normalizedEdge := "down"

    for hwnd, profile in g_TuckedWindows {
        if (!WinExist("ahk_id " . hwnd)) {
            continue
        }
        profileEdge := StrLower(profile.edge)
        if (profileEdge == "top")
            profileEdge := "up"
        if (profileEdge == "bottom")
            profileEdge := "down"

        if (profileEdge == normalizedEdge) {
            matched.Push({hwnd: hwnd, profile: profile})
        }
    }
    
    if (matched.Length == 0) {
        ShowTargetToolTip("No windows are currently tucked on the " . edge . " edge.")
        return
    }
    
    if (matched.Length == 1) {
        Menu_Untuck_Callback(matched[1].hwnd, matched[1].profile)
    } else {
        mMenu := Menu()
        mMenu.Add("--- Select Window to Untuck (" . edge . ") ---", (*) => 0)
        mMenu.Disable("--- Select Window to Untuck (" . edge . ") ---")
        mMenu.Add()
        
        for item in matched {
            wTitle := WinGetTitle("ahk_id " . item.hwnd)
            if (wTitle == "") {
                wTitle := "Untitled (ahk_id " . item.hwnd . ")"
            }
            if (StrLen(wTitle) > 50) {
                wTitle := SubStr(wTitle, 1, 47) . "..."
            }
            mMenu.Add("[" . item.profile.edge . "] " . wTitle . " [0x" . Format("{:X}", item.hwnd) . "]", Menu_Untuck_Callback.Bind(item.hwnd, item.profile))
        }
        mMenu.Show()
    }
}

EndTuckPeek() {
    global g_TuckPeekActive, g_TuckPeekList, g_TuckPeekIndex, g_TuckPeekEdge, g_ActiveUntuckedHwnd
    g_TuckPeekActive := false
    g_TuckPeekList := []
    g_TuckPeekIndex := 0
    g_TuckPeekEdge := ""
    
    if (g_ActiveUntuckedHwnd != 0 && WinExist("ahk_id " . g_ActiveUntuckedHwnd)) {
        ExecuteRetuckSequence(g_ActiveUntuckedHwnd)
        g_ActiveUntuckedHwnd := 0
    }
    ShowTargetToolTip("TuckPeek ended.")
}

TuckPeekDimension(edge) {
    global g_TuckPeekActive, g_TuckPeekList, g_TuckPeekIndex, g_TuckPeekEdge, g_TuckedWindows, g_ActiveUntuckedHwnd
    
    normalizedEdge := StrLower(edge)
    if (normalizedEdge == "top")
        normalizedEdge := "up"
    if (normalizedEdge == "bottom")
        normalizedEdge := "down"
        
    isSameEdge := (g_TuckPeekActive && g_TuckPeekEdge == normalizedEdge && g_TuckPeekList.Length > 0)
    
    if (!isSameEdge) {
        g_TuckPeekList := []
        for hwnd, profile in g_TuckedWindows {
            if (!WinExist("ahk_id " . hwnd)) {
                continue
            }
            profileEdge := StrLower(profile.edge)
            if (profileEdge == "top")
                profileEdge := "up"
            if (profileEdge == "bottom")
                profileEdge := "down"
                
            if (profileEdge == normalizedEdge) {
                g_TuckPeekList.Push({hwnd: hwnd, edge: profile.edge, profile: profile})
            }
        }
        
        if (g_TuckPeekList.Length == 0) {
            ShowTargetToolTip("No tucked windows on the " . edge . " edge.")
            return
        }
        
        g_TuckPeekActive := true
        g_TuckPeekEdge := normalizedEdge
        g_TuckPeekIndex := 1
    } else {
        if (g_ActiveUntuckedHwnd != 0 && WinExist("ahk_id " . g_ActiveUntuckedHwnd)) {
            ExecuteRetuckSequence(g_ActiveUntuckedHwnd)
            g_ActiveUntuckedHwnd := 0
        }
        
        g_TuckPeekIndex := g_TuckPeekIndex + 1
        if (g_TuckPeekIndex > g_TuckPeekList.Length) {
            g_TuckPeekIndex := 1
        }
    }
    
    item := g_TuckPeekList[g_TuckPeekIndex]
    
    if (WinExist("ahk_id " . item.hwnd)) {
        wTitle := WinGetTitle("ahk_id " . item.hwnd)
        if (wTitle == "") {
            wTitle := "Untitled"
        }
        ShowTargetToolTip("Peeking (" . g_TuckPeekIndex . "/" . g_TuckPeekList.Length . "): " . wTitle . "`n[Esc] to end peek")
        RevealTuckedWindow(item.hwnd, item.edge, item.profile)
    } else {
        g_TuckPeekList.RemoveAt(g_TuckPeekIndex)
        if (g_TuckPeekList.Length == 0) {
            EndTuckPeek()
            return
        }
        g_TuckPeekIndex := 1
        TuckPeekDimension(edge)
    }
}

StartDragWindow(hWnd) {
    global g_DragActive, g_DragHwnd
    global g_DragOrigX, g_DragOrigY, g_DragOrigW, g_DragOrigH
    global g_DragMouseOffsetX, g_DragMouseOffsetY
    global g_DragTuckActive, g_DragTuckEdge, g_DragTuckIndicatorGui
    global g_DragWindowsAbove
    
    if (g_DragActive) {
        EndDragWindow(false)
    }
    
    ; DragWindow chooses window under mouse first, fallback to active window
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY, &mHwnd)
    targetHW := 0
    if (mHwnd) {
        mRoot := DllCall("GetAncestor", "ptr", mHwnd, "uint", 2, "ptr")
        targetHW := mRoot ? mRoot : mHwnd
    }
    
    if (!targetHW || !WinExist("ahk_id " . targetHW) || WinGetClass("ahk_id " . targetHW) == "Progman" || WinGetClass("ahk_id " . targetHW) == "WorkerW") {
        targetHW := hWnd
    }
    
    if (!targetHW || !WinExist("ahk_id " . targetHW)) {
        targetHW := WinExist("A")
    }
    
    if (!targetHW || !WinExist("ahk_id " . targetHW)) {
         return
    }
    
    g_DragHwnd := targetHW
    WinGetPos(&g_DragOrigX, &g_DragOrigY, &g_DragOrigW, &g_DragOrigH, "ahk_id " . g_DragHwnd)
    
    ; Make only the active dragged window slightly translucent (OPACITY: 200/255)
    try WinSetTransparent(200, "ahk_id " . g_DragHwnd)
    
    g_DragWindowsAbove := []
    try {
        allWins := WinGetList()
        for h in allWins {
            if (h == g_DragHwnd) {
                break
            }
            style := WinGetStyle("ahk_id " . h)
            if (!(style & 0x10000000)) ; Must be WS_VISIBLE
                continue
            exStyle := WinGetExStyle("ahk_id " . h)
            if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
                continue
            
            wClass := WinGetClass("ahk_id " . h)
            if (wClass == "Progman" || wClass == "WorkerW" || wClass == "Shell_TrayWnd" || wClass == "Button")
                continue
                
            wTitle := WinGetTitle("ahk_id " . h)
            if (wTitle == "")
                continue
                
            origTrans := ""
            try {
                origTrans := WinGetTransparent("ahk_id " . h)
            } catch {
                origTrans := "Off"
            }
            if (origTrans == "")
                origTrans := "Off"
                
            g_DragWindowsAbove.Push({hwnd: h, origTrans: origTrans})
            try WinSetTransparent(50, "ahk_id " . h)
        }
    }
    
    g_DragMouseOffsetX := mX - g_DragOrigX
    g_DragMouseOffsetY := mY - g_DragOrigY
    
    ; Lazily setup tuck preview Gui
    if (g_DragTuckIndicatorGui == "") {
        g_DragTuckIndicatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; Click-through
        g_DragTuckIndicatorGui.BackColor := "00FFCC"
        try {
            g_DragTuckIndicatorGui.Show("Hide")
            WinSetTransparent(100, "ahk_id " . g_DragTuckIndicatorGui.Hwnd)
        }
    }
    
    g_DragTuckActive := false
    g_DragTuckEdge := ""
    
    g_DragActive := true
    SetTimer(TrackDragWindow, 15)
    ShowTargetToolTip("Drag Mode Started.`n[LButton] / [Enter] to place • [Esc] to restore`nDrag to screen edges to TUCK window!")
}

TrackDragWindow() {
    global g_DragActive, g_DragHwnd, g_DragMouseOffsetX, g_DragMouseOffsetY, g_DragOrigW, g_DragOrigH
    global g_DragTuckActive, g_DragTuckEdge, g_DragTuckIndicatorGui
    if (!g_DragActive || !WinExist("ahk_id " . g_DragHwnd)) {
        SetTimer(TrackDragWindow, 0)
        return
    }
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    
    ; Identify active monitor from mouse coordinates
    hMon := DllCall("MonitorFromPoint", "int64", (mY << 32) | (mX & 0xFFFFFFFF), "uint", 2, "ptr")
    MI := Buffer(40)
    NumPut("uint", 40, MI, 0)
    
    isEdge := false
    edgeName := ""
    mLeft := 0, mTop := 0, mRight := 0, mBottom := 0
    
    if (DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI)) {
        mLeft := NumGet(MI, 20, "int")
        mTop := NumGet(MI, 24, "int")
        mRight := NumGet(MI, 28, "int")
        mBottom := NumGet(MI, 32, "int")
        
        tol := 10
        distL := Abs(mX - mLeft)
        distR := Abs(mX - mRight)
        distT := Abs(mY - mTop)
        distB := Abs(mY - mBottom)
        
        minD := Min(distL, distR, distT, distB)
        
        if (minD <= tol) {
            isEdge := true
            if (minD == distL) {
                edgeName := "Left"
            } else if (minD == distR) {
                edgeName := "Right"
            } else if (minD == distT) {
                edgeName := "Up"
            } else if (minD == distB) {
                edgeName := "Down"
            }
        }
    }
    
    if (isEdge && edgeName != "") {
        g_DragTuckActive := true
        g_DragTuckEdge := edgeName
        
        width := mRight - mLeft
        height := mBottom - mTop
        
        switch edgeName {
            case "Left":
                g_DragTuckIndicatorGui.Show("x" . mLeft . " y" . mTop . " w40 h" . height . " NoActivate")
            case "Right":
                g_DragTuckIndicatorGui.Show("x" . (mRight - 40) . " y" . mTop . " w40 h" . height . " NoActivate")
            case "Up":
                g_DragTuckIndicatorGui.Show("x" . mLeft . " y" . mTop . " w" . width . " h40 NoActivate")
            case "Down":
                g_DragTuckIndicatorGui.Show("x" . mLeft . " y" . (mBottom - 40) . " w" . width . " h40 NoActivate")
        }
    } else {
        if (g_DragTuckActive) {
            g_DragTuckActive := false
            g_DragTuckEdge := ""
            try g_DragTuckIndicatorGui.Hide()
        }
    }
    
    nX := mX - g_DragMouseOffsetX
    nY := mY - g_DragMouseOffsetY
    SafeMove(nX, nY, g_DragOrigW, g_DragOrigH, g_DragHwnd)
}

EndDragWindow(restore := false) {
    global g_DragActive, g_DragHwnd, g_DragOrigX, g_DragOrigY, g_DragOrigW, g_DragOrigH
    global g_DragTuckActive, g_DragTuckEdge, g_DragTuckIndicatorGui, g_DragWindowsAbove
    if (!g_DragActive)
        return
        
    g_DragActive := false
    SetTimer(TrackDragWindow, 0)
    
    try g_DragTuckIndicatorGui.Hide()
    
    ; Restore transparency on the single active window
    try WinSetTransparent("Off", "ahk_id " . g_DragHwnd)
    
    for item in g_DragWindowsAbove {
        if (WinExist("ahk_id " . item.hwnd)) {
            try {
                if (item.origTrans == "Off" || item.origTrans == "") {
                    WinSetTransparent("Off", "ahk_id " . item.hwnd)
                } else {
                    WinSetTransparent(item.origTrans, "ahk_id " . item.hwnd)
                }
            }
        }
    }
    g_DragWindowsAbove := []
    
    if (restore) {
        if (WinExist("ahk_id " . g_DragHwnd)) {
            SafeMove(g_DragOrigX, g_DragOrigY, g_DragOrigW, g_DragOrigH, g_DragHwnd)
        }
        ShowTargetToolTip("Drag Cancelled.")
    } else {
        if (g_DragTuckActive && g_DragTuckEdge != "") {
            tuckEdge := g_DragTuckEdge
            
            g_DragTuckActive := false
            g_DragTuckEdge := ""
            
            if (WinExist("ahk_id " . g_DragHwnd)) {
                WinMove(g_DragOrigX, g_DragOrigY, g_DragOrigW, g_DragOrigH, "ahk_id " . g_DragHwnd)
                ExecuteCommandRegistry("Tuck" . tuckEdge, g_DragHwnd)
            }
            ShowTargetToolTip("Window Tucked on " . tuckEdge . " edge!")
        } else {
            g_DragTuckActive := false
            g_DragTuckEdge := ""
            ShowTargetToolTip("Drag Completed.")
        }
    }
}

ShowWindowPicker() {
    pickerGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "Window Picker")
    pickerGui.SetFont("s10", "Segoe UI")
    pickerGui.BackColor := "1E1E24"
    pickerGui.SetFont("cFFFFFF")
    
    pickerGui.Add("Text", "x15 y10 w470", "Type to fuzzy filter windows. Click a button or press Enter for the first result.")
    
    searchEdit := pickerGui.Add("Edit", "x15 y30 w470 h25 Background2A2A35 cFFFFFF vSearch")
    
    ; Create 8 styled buttons
    buttonsList := []
    buttonsData := [] ; Stores {hwnd: hwnd}
    
    Loop 8 {
        i := A_Index
        yPos := 65 + (i - 1) * 35
        pickerGui.SetFont("s9 Bold cFFFFFF")
        btn := pickerGui.Add("Button", "x15 y" . yPos . " w470 h30 Left", "")
        btn.Visible := false
        btn.OnEvent("Click", ButtonClicked.Bind(i))
        buttonsList.Push(btn)
        buttonsData.Push({hwnd: 0})
    }
    
    winData := []
    allWins := WinGetList()
    for h in allWins {
        try {
            style := WinGetStyle("ahk_id " . h)
            if (!(style & 0x10000000))
                continue
            
            exStyle := WinGetExStyle("ahk_id " . h)
            if (exStyle & 0x00000080)
                continue
                
            wClass := WinGetClass("ahk_id " . h)
            if (wClass == "Progman" || wClass == "WorkerW" || wClass == "Shell_TrayWnd" || wClass == "Button")
                continue
                
            wTitle := WinGetTitle("ahk_id " . h)
            if (wTitle == "")
                continue
                
            wExe := WinGetProcessName("ahk_id " . h)
            
            winData.Push({title: wTitle, exe: wExe, hwnd: h})
        }
    }
    
    ButtonClicked(btnIdx, *) {
        hwndTarget := buttonsData[btnIdx].hwnd
        if (hwndTarget && WinExist("ahk_id " . hwndTarget)) {
            pickerGui.Destroy()
            WinActivate("ahk_id " . hwndTarget)
        }
    }
    
    UpdateList(searchText) {
        normalizedSearch := StrLower(searchText)
        
        ; Find all matches first
        matchedItems := []
        for idx, item in winData {
            if (normalizedSearch == "") {
                matchedItems.Push(item)
            } else {
                titleL := StrLower(item.title)
                exeL := StrLower(item.exe)
                
                terms := StrSplit(normalizedSearch, " ")
                match := true
                for term in terms {
                    if (term == "")
                        continue
                    if (!InStr(titleL, term) && !InStr(exeL, term)) {
                        match := false
                        break
                    }
                }
                if (match) {
                    matchedItems.Push(item)
                }
            }
        }
        
        ; Now update the 8 buttons
        Loop 8 {
            i := A_Index
            if (i <= matchedItems.Length) {
                item := matchedItems[i]
                buttonsData[i].hwnd := item.hwnd
                
                ; Format title cleanly: limit title length to avoid spoiling layout
                dispTitle := item.title
                if (StrLen(dispTitle) > 55) {
                    dispTitle := SubStr(dispTitle, 1, 52) . "..."
                }
                
                btnText := " [" . i . "]   " . dispTitle . "   (" . item.exe . ")"
                buttonsList[i].Text := btnText
                buttonsList[i].Visible := true
                buttonsList[i].Enabled := true
            } else {
                buttonsData[i].hwnd := 0
                buttonsList[i].Visible := false
                buttonsList[i].Enabled := false
            }
        }
    }
    
    searchEdit.OnEvent("Change", (ctrl, *) => UpdateList(ctrl.Value))
    pickerGui.OnEvent("Escape", (*) => pickerGui.Destroy())
    
    ; Add default hidden button to activate the 1st match on Enter keypress
    pickerGui.Add("Button", "x0 y0 w0 h0 Default", "").OnEvent("Click", (*) => ButtonClicked(1))
    
    UpdateList("")
    pickerGui.Show("w500 h360")
}

StartDesk3D() {
    global g_Desk3dActive, g_Desk3dWindows, g_DeskStartMouseX, g_DeskStartMouseY, g_TuckedWindows
    if (g_Desk3dActive) {
        EndDesk3D()
        return
    }
    
    g_Desk3dWindows := []
    allWins := WinGetList()
    
    idx := 1
    for h in allWins {
        if (g_TuckedWindows.Has(h)) {
            continue
        }
        
        try {
            style := WinGetStyle("ahk_id " . h)
            if (!(style & 0x10000000))
                continue
            exStyle := WinGetExStyle("ahk_id " . h)
            if (exStyle & 0x00000080)
                continue
            
            wClass := WinGetClass("ahk_id " . h)
            if (wClass == "Progman" || wClass == "WorkerW" || wClass == "Shell_TrayWnd" || wClass == "Button")
                continue
                
            wTitle := WinGetTitle("ahk_id " . h)
            if (wTitle == "")
                continue
                
            minMax := WinGetMinMax("ahk_id " . h)
            if (minMax != 0)
                continue
                
            WinGetPos(&origX, &origY, &origW, &origH, "ahk_id " . h)
            
            origTrans := ""
            try {
                origTrans := WinGetTransparent("ahk_id " . h)
            } catch {
                origTrans := "Off"
            }
            if (origTrans == "")
                origTrans := "Off"
                
            g_Desk3dWindows.Push({
                hwnd: h,
                origX: origX,
                origY: origY,
                origW: origW,
                origH: origH,
                origTrans: origTrans,
                depthIdx: idx
            })
            
            ; Windows become 40% transparent during mode (value: 153 opacity)
            try WinSetTransparent(153, "ahk_id " . h)
            idx++
        }
    }
    
    if (g_Desk3dWindows.Length == 0) {
        ShowTargetToolTip("Desk3D: No restored windows active.")
        return
    }
    
    g_Desk3dActive := true
    CoordMode("Mouse", "Screen")
    MouseGetPos(&g_DeskStartMouseX, &g_DeskStartMouseY)
    
    SetTimer(TrackDesk3D, 15)
    ShowTargetToolTip("Desk3D Mode Active. Move mouse to rotate. Hold Ctrl to magnify, Shift to freeze. [Esc] to exit.")
}

TrackDesk3D() {
    global g_Desk3dActive, g_Desk3dWindows, g_DeskStartMouseX, g_DeskStartMouseY
    if (!g_Desk3dActive) {
        SetTimer(TrackDesk3D, 0)
        return
    }
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    
    deltaX := mX - g_DeskStartMouseX
    deltaY := mY - g_DeskStartMouseY
    
    ; Holding Shift stops the windows from movement due to the mode and the mouse
    if (GetKeyState("Shift", "P")) {
        deltaX := 0
        deltaY := 0
    }
    
    ; Holding Ctrl magnifies the movement of windows (factor 3.0)
    magFactor := GetKeyState("Ctrl", "P") ? 3.0 : 1.0
    
    for item in g_Desk3dWindows {
        if (!WinExist("ahk_id " . item.hwnd)) {
            continue
        }
        
        ; Initial magnification increased by 1.75
        weight := Max(0.05, 1.2 - (item.depthIdx - 1) * 0.15) * magFactor * 1.75
        shiftX := -deltaX * weight
        shiftY := -deltaY * weight
        
        SafeMove(item.origX + shiftX, item.origY + shiftY, item.origW, item.origH, item.hwnd)
    }
}

EndDesk3D() {
    global g_Desk3dActive, g_Desk3dWindows
    if (!g_Desk3dActive)
        return
        
    g_Desk3dActive := false
    SetTimer(TrackDesk3D, 0)
    
    for item in g_Desk3dWindows {
        if (WinExist("ahk_id " . item.hwnd)) {
            SafeMove(item.origX, item.origY, item.origW, item.origH, item.hwnd)
            try {
                if (item.origTrans == "Off" || item.origTrans == "") {
                    WinSetTransparent("Off", "ahk_id " . item.hwnd)
                } else {
                    WinSetTransparent(item.origTrans, "ahk_id " . item.hwnd)
                }
            }
        }
    }
    g_Desk3dWindows := []
    ShowTargetToolTip("Desk3D Mode Disabled.")
}

RecordWindowHistory(hwnd) {
    if (!WinExist("ahk_id " . hwnd))
        return
    try {
        WinGetPos(&cx, &cy, &cw, &ch, hwnd)
        minMax := WinGetMinMax(hwnd)
        exeName := WinGetProcessName(hwnd)
        title := WinGetTitle(hwnd)
        
        global g_WindowHistory, g_WindowHistoryIndex
        if (!g_WindowHistory) {
            g_WindowHistory := Map()
            g_WindowHistoryIndex := Map()
        }
        
        if (!g_WindowHistory.Has(hwnd)) {
            g_WindowHistory[hwnd] := []
            g_WindowHistoryIndex[hwnd] := 0
        }
        
        histList := g_WindowHistory[hwnd]
        
        isDup := false
        if (histList.Length > 0) {
            lastItem := histList[histList.Length]
            if (lastItem.x == cx && lastItem.y == cy && lastItem.w == cw && lastItem.h == ch && lastItem.minMax == minMax) {
                isDup := true
            }
        }
        
        if (!isDup) {
            histList.Push({x: cx, y: cy, w: cw, h: ch, minMax: minMax, time: A_Now})
            g_WindowHistoryIndex[hwnd] := histList.Length
            
            iniPath := A_ScriptDir . "\HotWinAHK_history.ini"
            cleanExe := RegExReplace(exeName, "i)[^a-z0-9]", "_")
            
            countStr := IniRead(iniPath, cleanExe, "Count", "0")
            countVal := Number(countStr) + 1
            
            IniWrite(cx . "," . cy . "," . cw . "," . ch . "," . minMax . "," . A_Now . "," . title, iniPath, cleanExe, "Entry_" . countVal)
            IniWrite(countVal, iniPath, cleanExe, "Count")
        }
    }
}

GotoHistoryPosition(hwnd, dir) {
    global g_WindowHistory, g_WindowHistoryIndex
    if (!g_WindowHistory) {
        g_WindowHistory := Map()
        g_WindowHistoryIndex := Map()
    }
    
    if (!WinExist("ahk_id " . hwnd))
        return
        
    RecordWindowHistory(hwnd)
    
    if (!g_WindowHistory.Has(hwnd)) {
        ShowTargetToolTip("No history for this window.")
        return
    }
    
    histList := g_WindowHistory[hwnd]
    idx := g_WindowHistoryIndex[hwnd]
    
    newIdx := idx + dir
    if (newIdx < 1 || newIdx > histList.Length) {
        ShowTargetToolTip("End of history (" . idx . "/" . histList.Length . ")")
        return
    }
    
    g_WindowHistoryIndex[hwnd] := newIdx
    item := histList[newIdx]
    
    try {
        if (item.minMax == -1) {
            WinMinimize("ahk_id " . hwnd)
        } else if (item.minMax == 1) {
            WinMaximize("ahk_id " . hwnd)
        } else {
            WinRestore("ahk_id " . hwnd)
            SafeMove(item.x, item.y, item.w, item.h, hwnd)
        }
        ShowTargetToolTip("History (" . newIdx . "/" . histList.Length . "): " . item.x . ", " . item.y)
    }
}

Menu_PickHistory(hwnd) {
    if (!WinExist("ahk_id " . hwnd))
        return
        
    try {
        exeName := WinGetProcessName(hwnd)
        title := WinGetTitle(hwnd)
        cleanExe := RegExReplace(exeName, "i)[^a-z0-9]", "_")
        iniPath := A_ScriptDir . "\HotWinAHK_history.ini"
        
        countStr := IniRead(iniPath, cleanExe, "Count", "0")
        countVal := Number(countStr)
        
        if (countVal == 0) {
            ShowTargetToolTip("No history saved in INI for " . exeName)
            return
        }
        
        mMenu := Menu()
        startIdx := Max(1, countVal - 20)
        
        Loop {
            idx := countVal - A_Index + 1 ; reverse
            if (idx < startIdx)
                break
                
            entryStr := IniRead(iniPath, cleanExe, "Entry_" . idx, "")
            if (entryStr == "")
                continue
                
            parts := StrSplit(entryStr, ",")
            if (parts.Length >= 5) {
                cx := parts[1]
                cy := parts[2]
                cw := parts[3]
                ch := parts[4]
                minMax := parts[5]
                timeStr := parts.Length >= 6 ? parts[6] : ""
                wTitle := parts.Length >= 7 ? parts[7] : title
                
                dispTime := ""
                if (timeStr != "" && StrLen(timeStr) >= 14) {
                    dispTime := SubStr(timeStr, 9, 2) . ":" . SubStr(timeStr, 11, 2) . " "
                }
                
                menuLabel := dispTime . " " . cx . "x" . cy . " (" . cw . "x" . ch . ") " . SubStr(wTitle, 1, 30)
                mMenu.Add(menuLabel, Menu_ApplyHistory_Callback.Bind(hwnd, cx, cy, cw, ch, minMax))
            }
        }
        
        mMenu.Show()
    }
}

Menu_ApplyHistory_Callback(hwnd, cx, cy, cw, ch, minMax, *) {
    if (WinExist("ahk_id " . hwnd)) {
        try {
            if (minMax == -1) {
                WinMinimize("ahk_id " . hwnd)
            } else if (minMax == 1) {
                WinMaximize("ahk_id " . hwnd)
            } else {
                WinRestore("ahk_id " . hwnd)
                SafeMove(cx, cy, cw, ch, hwnd)
            }
            ShowTargetToolTip("Restored to " . cx . ", " . cy)
        }
    }
}

SwapWindows(hwndActive, mode) {
    if (!hwndActive || !WinExist("ahk_id " . hwndActive)) {
        ShowTargetToolTip("Swap: No active window.")
        return
    }
    
    hwndUnder := MouseGetWindowHWND()
    if (!hwndUnder || !WinExist("ahk_id " . hwndUnder)) {
        ShowTargetToolTip("Swap: No window under mouse cursor.")
        return
    }
    
    if (hwndActive == hwndUnder) {
        ShowTargetToolTip("Swap: Active window and window under mouse are identical.")
        return
    }
    
    RecordWindowHistory(hwndActive)
    RecordWindowHistory(hwndUnder)
    
    try {
        WinGetPos(&x1, &y1, &w1, &h1, hwndActive)
        WinGetPos(&x2, &y2, &w2, &h2, hwndUnder)
        
        if (mode == "All") {
            SafeMove(x2, y2, w2, h2, hwndActive)
            SafeMove(x1, y1, w1, h1, hwndUnder)
            ShowTargetToolTip("Swapped positions and sizes.")
        } else if (mode == "Size") {
            SafeMove(x1, y1, w2, h2, hwndActive)
            SafeMove(x2, y2, w1, h1, hwndUnder)
            ShowTargetToolTip("Swapped window sizes.")
        } else if (mode == "Position") {
            SafeMove(x2, y2, w1, h1, hwndActive)
            SafeMove(x1, y1, w2, h2, hwndUnder)
            ShowTargetToolTip("Swapped window positions.")
        }
    } catch {
        ShowTargetToolTip("Swap: Target window is locked or not responding.")
    }
}

StartSwapPick(mode) {
    ShowTargetToolTip("SwapPick: Hover over the FIRST window and press Space to select. [Esc] to cancel.")
    
    hwnd1 := 0
    hwnd2 := 0
    
    Loop {
        if (!GetKeyState("Space", "P")) {
            Sleep(30)
            if (GetKeyState("Esc", "P")) {
                ShowTargetToolTip("SwapPick Cancelled.")
                return
            }
            continue
        }
        
        hwnd1 := MouseGetWindowHWND()
        if (hwnd1) {
            wTitle := WinGetTitle(hwnd1)
            ShowTargetToolTip("Selected Window 1: " . SubStr(wTitle, 1, 20) . "`nRelease Space to continue...")
            while (GetKeyState("Space", "P")) {
                Sleep(20)
            }
            break
        }
        Sleep(20)
    }
    
    ShowTargetToolTip("SwapPick: Hover over the SECOND window and press Space to select. [Esc] to cancel.")
    
    Loop {
        if (!GetKeyState("Space", "P")) {
            Sleep(30)
            if (GetKeyState("Esc", "P")) {
                ShowTargetToolTip("SwapPick Cancelled.")
                return
            }
            continue
        }
        
        hwnd2 := MouseGetWindowHWND()
        if (hwnd2) {
            if (hwnd2 == hwnd1) {
                ShowTargetToolTip("Second window is the same as the first! Hover over a different window.")
                while (GetKeyState("Space", "P")) {
                    Sleep(20)
                }
                continue
            }
            
            wTitle := WinGetTitle(hwnd2)
            ShowTargetToolTip("Selected Window 2: " . SubStr(wTitle, 1, 20))
            while (GetKeyState("Space", "P")) {
                Sleep(20)
            }
            break
        }
        Sleep(20)
    }
    
    if (hwnd1 && hwnd2 && WinExist("ahk_id " . hwnd1) && WinExist("ahk_id " . hwnd2)) {
        RecordWindowHistory(hwnd1)
        RecordWindowHistory(hwnd2)
        
        WinGetPos(&x1, &y1, &w1, &h1, hwnd1)
        WinGetPos(&x2, &y2, &w2, &h2, hwnd2)
        
        if (mode == "All") {
            SafeMove(x2, y2, w2, h2, hwnd1)
            SafeMove(x1, y1, w1, h1, hwnd2)
            ShowTargetToolTip("Swapped positions and sizes.")
        } else if (mode == "Size") {
            SafeMove(x1, y1, w2, h2, hwnd1)
            SafeMove(x2, y2, w1, h1, hwnd2)
            ShowTargetToolTip("Swapped window sizes.")
        } else if (mode == "Position") {
            SafeMove(x2, y2, w1, h1, hwnd1)
            SafeMove(x1, y1, w2, h2, hwnd2)
            ShowTargetToolTip("Swapped window positions.")
        }
    } else {
        ShowTargetToolTip("SwapPick Failed: Windows no longer exist.")
    }
}

ShowGridifyMenu(hWnd) {
    if (!hWnd || !WinExist("ahk_id " . hWnd))
        return
        
    try {
        WinGetPos(&X, &Y, &W, &H, hWnd)
        hMon := DllCall("MonitorFromWindow", "ptr", hWnd, "uint", 2, "ptr")
        MI := Buffer(40)
        NumPut("uint", 40, MI, 0)
        
        if (!DllCall("GetMonitorInfo", "ptr", hMon, "ptr", MI))
            return
            
        mLeft := NumGet(MI, 20, "int")
        mTop := NumGet(MI, 24, "int")
        mRight := NumGet(MI, 28, "int")
        mBottom := NumGet(MI, 32, "int")
        
        gX := 15
        gY := 15
        pX := 424
        pY := 232
        
        mainMenu := Menu()
        
        Loop 9 {
            c := A_Index
            subMenu := Menu()
            
            Loop 9 {
                r := A_Index
                label := r . " Row" . (r > 1 ? "s" : "") . "  (" . (c * pX - 6) . "x" . (r * pY - 6) . ")"
                subMenu.Add(label, ApplyGridify.Bind(hWnd, c, r, mLeft, mTop, mRight, mBottom, gX, gY, pX, pY, X, Y))
            }
            
            mainMenu.Add(c . " Column" . (c > 1 ? "s" : ""), subMenu)
        }
        
        mainMenu.Show()
    }
}

ApplyGridify(hWnd, c, r, mLeft, mTop, mRight, mBottom, gX, gY, pX, pY, X, Y, *) {
    if (!WinExist("ahk_id " . hWnd))
        return
        
    RecordWindowHistory(hWnd)
    
    maxCols := Floor((mRight - mLeft - gX) / pX)
    maxRows := Floor((mBottom - mTop - gY) / pY)
    
    cLeft := Round((X - mLeft - gX) / pX)
    rTop := Round((Y - mTop - gY) / pY)
    
    if (cLeft + c > maxCols) {
        cLeft := maxCols - c
    }
    if (cLeft < 0) {
        cLeft := 0
    }
    
    if (rTop + r > maxRows) {
        rTop := maxRows - r
    }
    if (rTop < 0) {
        rTop := 0
    }
    
    nW := (c * pX) - 6
    nH := (r * pY) - 6
    nX := mLeft + gX + (cLeft * pX)
    nY := mTop + gY + (rTop * pY)
    
    SafeMove(nX, nY, nW, nH, hWnd)
    ShowTargetToolTip("Gridified: " . c . "x" . r)
}

#HotIf g_Desk3dActive
Escape::EndDesk3D()
#HotIf

#HotIf g_TuckPeekActive
Escape::EndTuckPeek()
#HotIf

#HotIf g_DragActive
*LButton::EndDragWindow(false)
*Enter::EndDragWindow(false)
*Escape::EndDragWindow(true)
#HotIf

#Include "HotWinAHK_aux.ahk"
; #endregion

; &"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\_\ahk-window-hotkeys\HotWinAHK.ahk"
