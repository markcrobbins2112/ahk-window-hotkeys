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
Global g_z := 40 ;
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
try {
    DetectHiddenWindows(true)
    currentPID := DllCall("GetCurrentProcessId")
    existingAhkWins := WinGetList("ahk_class AutoHotkey")
    for hAhk in existingAhkWins {
        try {
            thisTitle := WinGetTitle("ahk_id " hAhk)
            thisPID := WinGetPID("ahk_id " hAhk)
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

SetTimer(CheckScreenEdgeBumps, 25)
SetTimer(UpdateActiveWindowDot, 100)
; Execute the initializer hook immediately on script launch
InitializeGlobalFocusBeeper()
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
    ; Skip processing if the event object isn't a core window frame
    if (idObject != 0) {
        return
    }

    try {
        ; EMIT AUDIBLE TONE: 750Hz frequency for a snappy 40 milliseconds duration
        SoundBeep(750, 40)
    } catch {
        ; Emit a lower diagnostic warning beep if the focused window is a hidden system node
        SoundBeep(400, 30)
    }
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
CompileIniToStaticHotkeys() {
    global g_sIniFile, g_sGeneratedFile

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

            ; INTERCEPT DUPLICATES. If this exact key combination was already written, skip it!
            if InStr(WrittenKeysRegistry, "|" sAHKStroke "|") {
                continue
            }

            ; Append the unique shortcut to our temporary tracker registry string
            WrittenKeysRegistry .= "|" sAHKStroke "|"

            ; Writes your raw native code formatting blocks
            ; Use the "$" prefix on keyboard keys to force AutoHotkey's precise low-level hook.
            ; This prevents the buggy Windows RegisterHotkey API from misinterpreting standard number keys (like 2 and 4)
            ; as their Numpad equivalents (Numpad2 and Numpad4).
            sPrefix := "$"
            ; Skip hook prefix for mouse buttons, wheels, or hotkeys that already have hook/wildcard/passthrough flags
            if (InStr(sAHKStroke, "$") || InStr(sAHKStroke, "~") || InStr(sAHKStroke, "*") || RegExMatch(sAHKStroke, "i)(lbutton|rbutton|mbutton|xbutton|wheel)")) {
                sPrefix := ""
            }
            ScriptBuffer .= sPrefix sAHKStroke ":: {`n"
            if (sCmd == "ToggleSuspension" || sCmd == "ExitProgram" || sCmd == "RestartProgram" || sCmd == "ReloadConfig" || sCmd == "EditConfig" || sCmd == "HelpScreen" || sCmd == "WinInfo" || sCmd == "CopyCommands" || sCmd == "CopyBindings" || sCmd == "PeekTucked" || sCmd == "Untuck" || sCmd == "CmdPalette") {
                ScriptBuffer .= '    try Suspend("Permit")`n'
            }
            ScriptBuffer .= '    ExecuteActionWithCondition("' sCmd '", "' sCond '")`n'
            ScriptBuffer .= "}`n`n"
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
    if (InStr(sCmd, "BumpEdgeUntuck") || InStr(sCmd, "HelpScreen") || InStr(sCmd, "ReloadConfig") || InStr(sCmd, "CopyCommands") || InStr(sCmd, "CopyBindings") || InStr(sCmd, "PeekTucked") || InStr(sCmd, "Untuck") || InStr(sCmd, "CmdPalette")) {
        return true
    }

    ; ... keep whatever other meta-commands you already have here ...
    return false
}
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
    }

    ; --- DYNAMIC POSITION PIXEL SHIFT MOVEMENT MATRIX ---
    ; --- DYNAMIC POSITION PIXEL SHIFT MOVEMENT MATRIX (INSTANT WARP) ---
    if RegExMatch(sCmd, "i)^Move(?!ToGrid)") {
        ; 1. Determine base macro step scale parameter
        iStep := InStr(sCmd, "10px") ? g_z : 1

        ; 2. Corrected Independent Axis Evaluation (Enables flawless compound diagonal tracking)
        dX := 0
        if (InStr(sCmd, "Left")) {
            dX := -iStep
        } else if (InStr(sCmd, "Right")) {
            dX := iStep
        }

        dY := 0
        if (InStr(sCmd, "Up")) {
            dY := -iStep
        } else if (InStr(sCmd, "Down")) {
            dY := iStep
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

        case "PeekTucked":
            Menu_PeekTucked()

        case "Untuck":
            Menu_Untuck()

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

        case "EdgeLeft", "EdgeRight", "EdgeTop", "EdgeBottom", "EdgeCenter", "EdgeTopLeft", "EdgeTopRight", "EdgeBottomLeft", "EdgeBottomRight":
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
                    case "EdgeLeft": nX := mLeft
                    case "EdgeRight": nX := mRight - W
                    case "EdgeTop": nY := mTop
                    case "EdgeBottom": nY := mBottom - H
                    case "EdgeTopLeft": nX := mLeft, nY := mTop
                    case "EdgeTopRight": nX := mRight - W, nY := mTop
                    case "EdgeBottomLeft": nX := mLeft, nY := mBottom - H
                    case "EdgeBottomRight": nX := mRight - W, nY := mBottom - H
                    case "EdgeCenter": nX := mLeft + Floor((mWidth - W) / 2), nY := mTop + Floor((mHeight - H) / 2)
                }
                AnimateWinMove(nX, nY, hWnd)
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
                    case "StretchLeft": nX := mLeft, nW := (X + W) - mLeft
                    case "StretchRight": nW := mRight - X
                    case "StretchTop": nY := mTop, nH := (Y + H) - mTop
                    case "StretchBottom": nH := mBottom - Y
                }
                SafeMove(nX, nY, nW, nH, hWnd)
            }

        case "SnapToGridEnlarge", "SnapToGridShrink", "MouseToGrid", "MoveToGridLeft", "MoveToGridRight", "MoveToGridUp", "MoveToGridDown", "StretchToGridLeft", "StretchToGridRight", "StretchToGridUp", "StretchToGridDown", "PullToGridLeft", "PullToGridRight", "PullToGridUp", "PullToGridDown":
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
                    case "PullToGridLeft":
                        ; Pull the left edge 1 unit inward (Right)
                        cLeft += 1

                    case "PullToGridRight":
                        ; Pull the right edge 1 unit inward (Left)
                        cRight -= 1

                    case "PullToGridUp":
                        ; Pull the top edge 1 unit inward (Down)
                        rTop += 1

                    case "PullToGridDown":
                        ; Pull the bottom edge 1 unit inward (Up)
                        rBottom -= 1
                    case "StretchToGridLeft":
                        ; Expand left edge 1 unit outward (Left)
                        cLeft -= 1

                    case "StretchToGridRight":
                        ; Expand right edge 1 unit outward (Right)
                        cRight += 1

                    case "StretchToGridUp":
                        ; Expand top edge 1 unit outward (Up)
                        rTop -= 1

                    case "StretchToGridDown":
                        ; Expand bottom edge 1 unit outward (Down)
                        rBottom += 1
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
            ; 1. Grab the active window's core engine class string identifier
            activeClass := WinGetClass(hWnd)

            ; 2. Push current window to the absolute bottom of the stack
            DllCall("SetWindowPos", "ptr", hWnd, "ptr", 1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0013) ; 1 = HWND_BOTTOM, 0x0013 = NOSIZE|NOMOVE|NOACTIVATE

            ; Yield 10ms to let the Windows visual index layer register the shift depth
            Sleep(10)

            ; 3. Scan top-down exclusively for matching application classes
            winList := WinGetList()
            for targetHwnd in winList {
                if (targetHwnd == hWnd) {
                    continue
                }
                ; EXCLUDE TUCKED WINDOWS SELECTION CODES
                if (g_TuckedWindows.Has(targetHwnd)) {
                    continue
                }

                ; Only process if it belongs to our exact active application class family
                if (WinGetClass(targetHwnd) == activeClass) {
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
            ; 1. Grab the active window's core engine class string identifier
            activeClass := WinGetClass(hWnd)

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

                ; Only process if it belongs to our exact active application class family
                if (WinGetClass(targetHwnd) == activeClass) {
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

                ; 2. Centering Logic equations (Monitor mid-point minus half of window dimensions)
                nX := mLeft + Floor((mWidth - W) / 2)
                nY := mTop + Floor((mHeight - H) / 2)

                ; 3. Execute instant target warp with zero latency
                SafeMove(nX, nY, , , hWnd)
            }

        case "ScaleExpand10px": SafeMove(X - g_z / 2, Y - g_z / 2, W + g_z, H + g_z, hWnd)
        case "ScaleReduce10px": SafeMove(X + g_z / 2, Y + g_z / 2, W - g_z, H - g_z, hWnd)
        case "TrimTop": SafeMove(X, Y + g_z, W, H - g_z, hWnd)
        case "TrimBottom": SafeMove(X, Y, W, H - g_z, hWnd)
        case "TrimLeft": SafeMove(X + g_z, Y, W - g_z, H, hWnd)
        case "TrimRight": SafeMove(X, Y, W - g_z, H, hWnd)
        case "AddTop": SafeMove(X, Y - g_z, W, H + g_z, hWnd)
        case "AddBottom": SafeMove(X, Y, W + g_z, H + g_z, hWnd)
        case "AddLeft": SafeMove(X - g_z, Y, W + g_z, H, hWnd)
        case "AddRight": SafeMove(X, Y, W + g_z, H, hWnd)

        case "JumpGridLeft", "JumpGridRight", "JumpGridUp", "JumpGridDown":
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

        case "SubtractTop", "SubtractBottom", "SubtractLeft", "SubtractRight", "SubtractTopLeft", "SubtractTopRight", "SubtractBottomLeft", "SubtractBottomRight":
            ; Define your standard macro pixel shift value (defaulting to 10px if g_z is missing)
            try {
                step := g_z
            } catch {
                step := 10
            }

            nX := X, nY := Y, nW := W, nH := H

            switch sCmd, false {
                case "SubtractTop":
                    nY := Y + step, nH := H - step
                case "SubtractBottom":
                    nH := H - step
                case "SubtractLeft":
                    nX := X + step, nW := W - step
                case "SubtractRight":
                    nW := W - step

                case "SubtractTopLeft":
                    nX := X + step, nY := Y + step, nW := W - step, nH := H - step
                case "SubtractTopRight":
                    nY := Y + step, nW := W - step, nH := H - step
                case "SubtractBottomLeft":
                    nX := X + step, nW := W - step, nH := H - step
                case "SubtractBottomRight":
                    nW := W - step, nH := H - step
            }

            ; Enforce a minimum safety size threshold so the window cannot collapse into zero
            if (nW < 100) {
                nW := 100
            }
            if (nH < 100) {
                nH := 100
            }

            SafeMove(nX, nY, nW, nH, hWnd)


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
    SoundBeep(g_bSuspended ? 400 : 900, 200)
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
ShowTargetToolTip(sText) {
    ToolTip(sText)
    SetTimer(ClearToolTip, -1500)
}
ClearToolTip() {
    ToolTip()
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
        ; --- THE FANCY LOCK NOTICE OVERLAY LAYER ---
        CoordMode("Mouse", "Screen")
        MouseGetPos(&currentMouseX, &currentMouseY)

        noticeText := "╔═════════════════════════════════════╗`n"
        noticeText .= "   ⚠️ LOG WRITE FAILED! ⚠️   `n"
        noticeText .= "╚═════════════════════════════════════╝`n"
        noticeText .= "Disk I/O collision detected on this tick.`n"
        noticeText .= "SafeMove is caching log entries in RAM.`n"
        noticeText .= "Retrying flush pass on next edge tick..."

        ToolTip(noticeText, currentMouseX + 25, currentMouseY + 25)

        ; Force the tooltip popup container to render in native Dark Mode
        if (hTooltipWindow := WinExist("ahk_class tooltips_class32")) {
            DllCall("uxtheme\SetWindowTheme", "ptr", hTooltipWindow, "wstr", "DarkMode_Explorer", "ptr", 0)
        }

        ; Auto-erase the visual warning box from the desktop screen after 2.5 seconds
        SetTimer((*) => ToolTip(), -2500)
    }

    if (targetHwnd == "" || !WinExist("ahk_id " . targetHwnd)) {
        return false
    }

    realW := Number(nW)
    realH := Number(nH)

    ; HARDENED PROFILE BACKUP RESCUE LAYER
    if (realW <= 0 || realH <= 0 || realW == -1 || realH == -1) {
        if (g_TuckedWindows.Has(targetHwnd)) {
            profile := g_TuckedWindows[targetHwnd]
            realW := Number(profile.w)
            realH := Number(profile.h)
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
    helpGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow", "HotWinAHK - Commands & Gestures Reference")
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
    helpGui.Add("Text", "x425 y80 w110", "Move10px")
    helpGui.Add("Text", "x545 y80 w110", "Win + Alt + Arrows")

    helpGui.SetFont("s9 bold cFFCC00", "Segoe UI")
    helpGui.Add("Text", "x425 y98 w110", "Move1px")
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
        {cat: "Administrative", cmd: "HelpScreen", key: "Win + /", desc: "Display this interactive keyboard command reference panel."},
        {cat: "Administrative", cmd: "CmdPalette", key: "Win + Ctrl + Shift + C", desc: "Display the interactive fuzzy-search Command Palette for manual trigger / dry run testing."},
        {cat: "Administrative", cmd: "WinInfo", key: "Win + Ctrl + /", desc: "Display active window physical bounds, handle ID, class, and executable name."},
        {cat: "Administrative", cmd: "ToggleSuspension", key: "Win + Alt + S", desc: "Suspend or resume all HotWinAHK modifier triggers instantly."},
        {cat: "Administrative", cmd: "ReloadConfig", key: "Win + F12", desc: "Hot-reload preferences from HotWinAHK.ini and compile hotkeys dynamically."},
        {cat: "Administrative", cmd: "EditConfig", key: "Win + Alt + E", desc: "Open HotWinAHK.ini configurations in system default text editor."},
        {cat: "Administrative", cmd: "ExitProgram", key: "Win + Alt + X", desc: "Safely terminate the HotWinAHK background orchestrator process."},
        {cat: "Administrative", cmd: "RestartProgram", key: "Win + .", desc: "Instantly reload and reboot the HotWinAHK execution engine."},
        {cat: "Administrative", cmd: "Active Window Dot", key: "Auto Indicator", desc: "Draws green dot at active window's top-left (yellow when program is suspended)."},
        
        {cat: "System Layer", cmd: "AlwaysOnTop", key: "Win + Ctrl + T", desc: "Toggle Always-On-Top focus pinning attribute on active window frame."},
        {cat: "System Layer", cmd: "SetOpacity70", key: "Win + Shift + O", desc: "Set alpha opacity transparency level to 70% on active window frame."},
        {cat: "System Layer", cmd: "RemoveOpacity", key: "Win + Alt + Shift + O", desc: "Restore active window opacity to full solid visibility."},
        {cat: "System Layer", cmd: "SendToBack", key: "Win + Backspace", desc: "Push active window frame to the bottom of the active desktop stack."},
        {cat: "System Layer", cmd: "MinimizeToTray", key: "Win + Shift + PgDn", desc: "Stow active window into an autonomous system-tray notification process."},
        {cat: "System Layer", cmd: "PickFromTray", key: "Win + Shift + PgUp", desc: "Open stowed window tray instances via right-click contextual list."},
        
        {cat: "Pixel Nudges", cmd: "MoveLeft10px", key: "Win + Ctrl + Left", desc: "Shift active window left by 10 pixels coarse-scale."},
        {cat: "Pixel Nudges", cmd: "MoveRight10px", key: "Win + Ctrl + Right", desc: "Shift active window right by 10 pixels coarse-scale."},
        {cat: "Pixel Nudges", cmd: "MoveUp10px", key: "Win + Ctrl + Up", desc: "Shift active window up by 10 pixels coarse-scale."},
        {cat: "Pixel Nudges", cmd: "MoveDown10px", key: "Win + Ctrl + Down", desc: "Shift active window down by 10 pixels coarse-scale."},
        {cat: "Pixel Nudges", cmd: "MoveLeft1px", key: "Win + Shift + Left", desc: "Nudge active window left with 1 pixel fine precision."},
        {cat: "Pixel Nudges", cmd: "MoveRight1px", key: "Win + Shift + Right", desc: "Nudge active window right with 1 pixel fine precision."},
        {cat: "Pixel Nudges", cmd: "MoveUp1px", key: "Win + Shift + Up", desc: "Nudge active window up with 1 pixel fine precision."},
        {cat: "Pixel Nudges", cmd: "MoveDown1px", key: "Win + Shift + Down", desc: "Nudge active window down with 1 pixel fine precision."},
        
        {cat: "Sizing & Margins", cmd: "ScaleExpand10px", key: "Ctrl + NumpadAdd", desc: "Expand active window bounds by 10px symmetrically in all directions."},
        {cat: "Sizing & Margins", cmd: "ScaleReduce10px", key: "Ctrl + NumpadSub", desc: "Shrink active window bounds by 10px symmetrically in all directions."},
        {cat: "Sizing & Margins", cmd: "TrimLeft", key: "Win + Alt + Left", desc: "Trim left boundary from active window margin."},
        {cat: "Sizing & Margins", cmd: "TrimRight", key: "Win + Alt + Right", desc: "Trim right boundary from active window margin."},
        {cat: "Sizing & Margins", cmd: "TrimTop", key: "Win + Alt + Up", desc: "Trim top boundary from active window margin."},
        {cat: "Sizing & Margins", cmd: "TrimBottom", key: "Win + Alt + Down", desc: "Trim bottom boundary from active window margin."},
        {cat: "Sizing & Margins", cmd: "AddLeft", key: "Win + Alt + Shift + Left", desc: "Grow left boundary outward from active window margin."},
        {cat: "Sizing & Margins", cmd: "AddRight", key: "Win + Alt + Shift + Right", desc: "Grow right boundary outward from active window margin."},
        {cat: "Sizing & Margins", cmd: "AddTop", key: "Win + Alt + Shift + Up", desc: "Grow top boundary outward from active window margin."},
        {cat: "Sizing & Margins", cmd: "AddBottom", key: "Win + Alt + Shift + Down", desc: "Grow bottom boundary outward from active window margin."},
        {cat: "Sizing & Margins", cmd: "SubtractLeft", key: "Win + Ctrl + Alt + Left", desc: "Contract left boundary margin from specific directional axis."},
        {cat: "Sizing & Margins", cmd: "SubtractRight", key: "Win + Ctrl + Alt + Right", desc: "Contract right boundary margin from specific directional axis."},
        {cat: "Sizing & Margins", cmd: "SubtractTop", key: "Win + Ctrl + Alt + Up", desc: "Contract top boundary margin from specific directional axis."},
        {cat: "Sizing & Margins", cmd: "SubtractBottom", key: "Win + Ctrl + Alt + Down", desc: "Contract bottom boundary margin from specific directional axis."},
        
        {cat: "Grid Matrix", cmd: "JumpGridLeft", key: "Alt + Numpad 4", desc: "Hop window position to the left virtual grid quartile partition."},
        {cat: "Grid Matrix", cmd: "JumpGridRight", key: "Alt + Numpad 6", desc: "Hop window position to the right virtual grid quartile partition."},
        {cat: "Grid Matrix", cmd: "JumpGridUp", key: "Alt + Numpad 8", desc: "Hop window position to the up virtual grid quartile partition."},
        {cat: "Grid Matrix", cmd: "JumpGridDown", key: "Alt + Numpad 2", desc: "Hop window position to the down virtual grid quartile partition."},
        {cat: "Grid Matrix", cmd: "MouseToGrid", key: "Win + RButton", desc: "Warp window beneath mouse cursor directly to closest grid block."},
        {cat: "Grid Matrix", cmd: "SnapToGridEnlarge", key: "NumpadAdd", desc: "Grow active window boundaries to span next adjacent grid aspect cell."},
        {cat: "Grid Matrix", cmd: "SnapToGridShrink", key: "NumpadSub", desc: "Contract active window grid spanning aspect cell size."},
        {cat: "Grid Matrix", cmd: "MoveToGridLeft", key: "Numpad 4", desc: "Shift active window leftward between virtual grid units."},
        {cat: "Grid Matrix", cmd: "MoveToGridRight", key: "Numpad 6", desc: "Shift active window rightward between virtual grid units."},
        {cat: "Grid Matrix", cmd: "MoveToGridDown", key: "Numpad 2", desc: "Shift active window downward between virtual grid units."},
        {cat: "Grid Matrix", cmd: "MoveToGridUp", key: "Numpad 8", desc: "Shift active window upward between virtual grid units."},
        {cat: "Grid Matrix", cmd: "StretchToGridLeft", key: "Win + Numpad 4", desc: "Stretch left index to clamp onto nearest leftward grid edge."},
        {cat: "Grid Matrix", cmd: "StretchToGridRight", key: "Win + Numpad 6", desc: "Stretch right index to clamp onto nearest rightward grid edge."},
        {cat: "Grid Matrix", cmd: "StretchToGridUp", key: "Win + Numpad 8", desc: "Stretch top index to clamp onto nearest upward grid edge."},
        {cat: "Grid Matrix", cmd: "StretchToGridDown", key: "Win + Numpad 2", desc: "Stretch bottom index to clamp onto nearest downward grid edge."},
        {cat: "Grid Matrix", cmd: "PullToGridLeft", key: "Win + Alt + Numpad 4", desc: "Clamp left boundary onto nearest grid coordinate matrix."},
        {cat: "Grid Matrix", cmd: "PullToGridRight", key: "Win + Alt + Numpad 6", desc: "Clamp right boundary onto nearest grid coordinate matrix."},
        {cat: "Grid Matrix", cmd: "PullToGridDown", key: "Win + Alt + Numpad 2", desc: "Clamp bottom boundary onto nearest grid coordinate matrix."},
        {cat: "Grid Matrix", cmd: "PullToGridUp", key: "Win + Alt + Numpad 8", desc: "Clamp top boundary onto nearest grid coordinate matrix."},
        
        {cat: "Docking & Fling", cmd: "TuckLeft", key: "Win + Ctrl + Shift + Left", desc: "Tuck window past left screen wall, exposing a 20px dock indicator bar."},
        {cat: "Docking & Fling", cmd: "TuckRight", key: "Win + Ctrl + Shift + Right", desc: "Tuck window past right screen wall, exposing a 20px dock indicator bar."},
        {cat: "Docking & Fling", cmd: "TuckUp", key: "Win + Ctrl + Shift + Up", desc: "Tuck window past top screen wall, exposing a 20px dock indicator bar."},
        {cat: "Docking & Fling", cmd: "TuckDown", key: "Win + Ctrl + Shift + Down", desc: "Tuck window past bottom screen wall, exposing a 20px dock indicator bar."},
        {cat: "Docking & Fling", cmd: "PeekTucked", key: "Win + Ctrl + Shift + P", desc: "Offers a menu of all tucked windows listing their titles and edge."},
        {cat: "Docking & Fling", cmd: "Untuck", key: "Win + Ctrl + Shift + U", desc: "Offers a menu of all tucked windows to completely restore them."},
        
        {cat: "Window Cycling", cmd: "NextWindow", key: "Win + PgUp", desc: "Cycle focus smoothly forward across open desktop window frames."},
        {cat: "Window Cycling", cmd: "PrevWindow", key: "Win + PgDn", desc: "Cycle focus smoothly backward across open desktop window frames."},
        {cat: "Window Cycling", cmd: "NextClassWindow", key: "Win + Alt + PgUp", desc: "Cycle focus specifically forward between windows of identical process class."},
        {cat: "Window Cycling", cmd: "PrevClassWindow", key: "Win + Alt + PgDn", desc: "Cycle focus specifically backward between windows of identical process class."}
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
    commandsList := "=== HotWinAHK Available Action Commands ===`r`n`r`n"
    commands := [
        "HelpScreen", "WinInfo", "ToggleSuspension", "ReloadConfig", "EditConfig", 
        "ExitProgram", "RestartProgram", "AlwaysOnTop", "SetOpacity70", "RemoveOpacity", 
        "SendToBack", "MinimizeToTray", "PickFromTray", "PeekUnderMouse", 
        "MoveLeft10px", "MoveRight10px", "MoveUp10px", "MoveDown10px", 
        "MoveLeft1px", "MoveRight1px", "MoveUp1px", "MoveDown1px", 
        "EdgeLeft", "EdgeRight", "EdgeTop", "EdgeBottom", "EdgeTopLeft", 
        "EdgeTopRight", "EdgeBottomLeft", "EdgeBottomRight", "EdgeCenter", 
        "ScaleExpand10px", "ScaleReduce10px", "TrimTop", "TrimBottom", 
        "TrimLeft", "TrimRight", "AddTop", "AddBottom", "AddLeft", "AddRight", 
        "SubtractTop", "SubtractBottom", "SubtractLeft", "SubtractRight", 
        "MouseRelativeSize", "HalfSizeLeft", "HalfSizeRight", "HalfSizeTop", "HalfSizeBottom", 
        "DoubleSizeLeft", "DoubleSizeRight", "DoubleSizeTop", "DoubleSizeBottom", 
        "NextWindow", "PrevWindow", "NextClassWindow", "PrevClassWindow", 
        "JumpGridLeft", "JumpGridRight", "JumpGridUp", "JumpGridDown", "MouseToGrid", 
        "SnapToGridEnlarge", "SnapToGridShrink", "Center", "MoveToGridLeft", 
        "MoveToGridRight", "MoveToGridUp", "MoveToGridDown", "StretchToGridLeft", 
        "StretchToGridRight", "StretchToGridUp", "StretchToGridDown", "PullToGridLeft", 
        "PullToGridRight", "PullToGridUp", "PullToGridDown", "TuckLeft", "TuckRight", 
        "TuckUp", "TuckDown", "BumpEdgeUntuck", "BumpEdgeUntuckActivate", 
        "FocusDeepestWindow", "CopyCommands", "CopyBindings"
    ]
    for cmd in commands {
        commandsList .= cmd . "`r`n"
    }
    A_Clipboard := commandsList
    ShowTargetToolTip("Copied Available Commands to Clipboard!")
}

CopyBindings() {
    global g_sIniFile
    if !FileExist(g_sIniFile) {
        ShowTargetToolTip("INI File not found!")
        return
    }
    
    bindingsList := "=== HotWinAHK Active Keybindings ===`r`n`r`n"
    sectionsText := IniRead(g_sIniFile)
    count := 0
    
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
            
            bindingsList .= "[" . sCmd . "] -> " . keyValue . "`r`n"
            count++
        }
    }
    
    A_Clipboard := bindingsList
    ShowTargetToolTip("Copied Active Bindings to Clipboard!")
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

Menu_PeekTucked() {
    global g_TuckedWindows
    if (g_TuckedWindows.Count == 0) {
        ShowTargetToolTip("No windows are currently tucked.")
        return
    }
    
    mMenu := Menu()
    mMenu.Add("--- Stowed Windows Menu ---", (*) => 0)
    mMenu.Disable("--- Stowed Windows Menu ---")
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
        
        menuLabel := "[" . profile.edge . "] " . wTitle
        mMenu.Add(menuLabel, Menu_PeekTucked_Callback.Bind(hwnd, profile.edge, profile))
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
        
        menuLabel := "[" . profile.edge . "] " . wTitle
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

#Include "HotWinAHK_aux.ahk"
; #endregion

; &"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\_\ahk-window-hotkeys\HotWinAHK.ahk"
