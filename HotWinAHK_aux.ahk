; =======================================================================================
;          AUTOMATICALLY GENERATED NATIVE SHELL HOTKEYS - DO NOT EDIT DIRECTLY
; =======================================================================================
#Requires AutoHotkey v2.0

$#/:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("HelpScreen", "")
}

$^+#c:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CmdPalette", "")
}

$^#/:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("WinInfo", "")
}

$^#c:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyCommands", "")
}

$!#c:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyBindings", "")
}

$!#s:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("ToggleSuspension", "")
}

$#f12:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("ReloadConfig", "")
}

$!#e:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("EditConfig", "")
}

$!#x:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("ExitProgram", "")
}

$^#f12:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("RestartProgram", "")
}

$^#.:: {
    ExecuteActionWithCondition("SetHome", "")
}

$^+#.:: {
    ExecuteActionWithCondition("ClearHome", "")
}

$!#.:: {
    ExecuteActionWithCondition("GoHome", "")
}

$#.:: {
    ExecuteActionWithCondition("Home", "")
}

$+#.:: {
    ExecuteActionWithCondition("HomePeek", "")
}

$^#t:: {
    ExecuteActionWithCondition("AlwaysOnTop", "")
}

$+#o:: {
    ExecuteActionWithCondition("SetOpacity70", "")
}

$!+#o:: {
    ExecuteActionWithCondition("RemoveOpacity", "")
}

$#backspace:: {
    ExecuteActionWithCondition("SendToBack", "")
}

$+#backspace:: {
    ExecuteActionWithCondition("FocusLastActiveWindow", "")
}

$^#backspace:: {
    ExecuteActionWithCondition("FocusDeepestWindow", "")
}

$#pgdn:: {
    ExecuteActionWithCondition("NextWindow", "")
}

!wheeldown:: {
    ExecuteActionWithCondition("NextWindow", "")
}

$#pgup:: {
    ExecuteActionWithCondition("PrevWindow", "")
}

!wheelup:: {
    ExecuteActionWithCondition("PrevWindow", "")
}

$!#pgdn:: {
    ExecuteActionWithCondition("NextClassWindow", "")
}

$!#pgup:: {
    ExecuteActionWithCondition("PrevClassWindow", "")
}

$+#pgdn:: {
    ExecuteActionWithCondition("MinimizeToTray", "")
}

$+#pgup:: {
    ExecuteActionWithCondition("PickFromTray", "")
}

#rbutton:: {
    ExecuteActionWithCondition("MouseToGrid", "")
}

#lbutton:: {
    ExecuteActionWithCondition("MouseRelativeSize", "")
}

$!#left:: {
    ExecuteActionWithCondition("MoveLeft10px", "")
}

$!#right:: {
    ExecuteActionWithCondition("MoveRight10px", "")
}

$!#up:: {
    ExecuteActionWithCondition("MoveUp10px", "")
}

$!#down:: {
    ExecuteActionWithCondition("MoveDown10px", "")
}

$+#left:: {
    ExecuteActionWithCondition("MoveLeft1px", "")
}

$+#right:: {
    ExecuteActionWithCondition("MoveRight1px", "")
}

$+#up:: {
    ExecuteActionWithCondition("MoveUp1px", "")
}

$+#down:: {
    ExecuteActionWithCondition("MoveDown1px", "")
}

$^numpad4:: {
    ExecuteActionWithCondition("EdgeLeft", "")
}

$^numpad6:: {
    ExecuteActionWithCondition("EdgeRight", "")
}

$^numpad8:: {
    ExecuteActionWithCondition("EdgeTop", "")
}

$^numpad2:: {
    ExecuteActionWithCondition("EdgeBottom", "")
}

$^numpad7:: {
    ExecuteActionWithCondition("EdgeTopLeft", "")
}

$^numpad9:: {
    ExecuteActionWithCondition("EdgeTopRight", "")
}

$^numpad1:: {
    ExecuteActionWithCondition("EdgeBottomLeft", "")
}

$^numpad3:: {
    ExecuteActionWithCondition("EdgeBottomRight", "")
}

$^numpad5:: {
    ExecuteActionWithCondition("EdgeCenter", "")
}

$^numpadadd:: {
    ExecuteActionWithCondition("ScaleExpandGridPart", "")
}

$^numpadsub:: {
    ExecuteActionWithCondition("ScaleReduceGridPart", "")
}

$!numpadadd:: {
    ExecuteActionWithCondition("ScaleExpand10px", "")
}

$!numpadsub:: {
    ExecuteActionWithCondition("ScaleReduce10px", "")
}

$#numpad4:: {
    ExecuteActionWithCondition("StretchToGridLeft", "")
}

$#numpad6:: {
    ExecuteActionWithCondition("StretchToGridRight", "")
}

$#numpad8:: {
    ExecuteActionWithCondition("StretchToGridUp", "")
}

$#numpad2:: {
    ExecuteActionWithCondition("StretchToGridDown", "")
}

$#numpad7:: {
    ExecuteActionWithCondition("StretchToGridTopLeft", "")
}

$#numpad9:: {
    ExecuteActionWithCondition("StretchToGridTopRight", "")
}

$#numpad1:: {
    ExecuteActionWithCondition("StretchToGridBottomLeft", "")
}

$#numpad3:: {
    ExecuteActionWithCondition("StretchToGridBottomRight", "")
}

$!#numpad2:: {
    ExecuteActionWithCondition("PullToGridDown", "")
}

$!#numpad8:: {
    ExecuteActionWithCondition("PullToGridUp", "")
}

$!#numpad4:: {
    ExecuteActionWithCondition("PullToGridLeft", "")
}

$!#numpad6:: {
    ExecuteActionWithCondition("PullToGridRight", "")
}

$!#numpad7:: {
    ExecuteActionWithCondition("PullToGridTopLeft", "")
}

$!#numpad9:: {
    ExecuteActionWithCondition("PullToGridTopRight", "")
}

$!#numpad1:: {
    ExecuteActionWithCondition("PullToGridBottomLeft", "")
}

$!#numpad3:: {
    ExecuteActionWithCondition("PullToGridBottomRight", "")
}

$^+#numpad8:: {
    ExecuteActionWithCondition("GrowTop", "")
}

$^+#numpad2:: {
    ExecuteActionWithCondition("GrowBottom", "")
}

$^+#numpad6:: {
    ExecuteActionWithCondition("GrowLeft", "")
}

$^+#numpad4:: {
    ExecuteActionWithCondition("GrowRight", "")
}

$^+#numpad7:: {
    ExecuteActionWithCondition("GrowTopLeft", "")
}

$^+#numpad9:: {
    ExecuteActionWithCondition("GrowTopRight", "")
}

$^+#numpad1:: {
    ExecuteActionWithCondition("GrowBottomLeft", "")
}

$^+#numpad3:: {
    ExecuteActionWithCondition("GrowBottomRight", "")
}

$^+#numpad5:: {
    ExecuteActionWithCondition("GrowAll", "")
}

$!+#numpad8:: {
    ExecuteActionWithCondition("TrimTop", "")
}

$!+#numpad2:: {
    ExecuteActionWithCondition("TrimBottom", "")
}

$!+#numpad6:: {
    ExecuteActionWithCondition("TrimLeft", "")
}

$!+#numpad4:: {
    ExecuteActionWithCondition("TrimRight", "")
}

$!+#numpad7:: {
    ExecuteActionWithCondition("TrimTopLeft", "")
}

$!+#numpad9:: {
    ExecuteActionWithCondition("TrimTopRight", "")
}

$!+#numpad1:: {
    ExecuteActionWithCondition("TrimBottomLeft", "")
}

$!+#numpad3:: {
    ExecuteActionWithCondition("TrimBottomRight", "")
}

$!#numpad5:: {
    ExecuteActionWithCondition("TrimAll", "")
}

$!+#up:: {
    ExecuteActionWithCondition("AddTop", "")
}

$!+#down:: {
    ExecuteActionWithCondition("AddBottom", "")
}

$!+#left:: {
    ExecuteActionWithCondition("AddLeft", "")
}

$!+#right:: {
    ExecuteActionWithCondition("AddRight", "")
}

$^!#up:: {
    ExecuteActionWithCondition("SubtractTop", "")
}

$^!#down:: {
    ExecuteActionWithCondition("SubtractBottom", "")
}

$^!#left:: {
    ExecuteActionWithCondition("SubtractLeft", "")
}

$^!#right:: {
    ExecuteActionWithCondition("SubtractRight", "")
}

$^!+#left:: {
    ExecuteActionWithCondition("StretchLeft", "")
}

$^!+#right:: {
    ExecuteActionWithCondition("StretchRight", "")
}

$^!+#up:: {
    ExecuteActionWithCondition("StretchTop", "")
}

$!numpad4:: {
    ExecuteActionWithCondition("JumpGridLeft", "")
}

$!numpad6:: {
    ExecuteActionWithCondition("JumpGridRight", "")
}

$!numpad8:: {
    ExecuteActionWithCondition("JumpGridUp", "")
}

$!numpad2:: {
    ExecuteActionWithCondition("JumpGridDown", "")
}

$numpadadd:: {
    ExecuteActionWithCondition("SnapToGridEnlarge", "")
}

$numpadsub:: {
    ExecuteActionWithCondition("SnapToGridShrink", "")
}

$numpad5:: {
    ExecuteActionWithCondition("Center", "")
}

$numpad4:: {
    ExecuteActionWithCondition("MoveToGridLeft", "")
}

$numpad6:: {
    ExecuteActionWithCondition("MoveToGridRight", "")
}

$numpad8:: {
    ExecuteActionWithCondition("MoveToGridUp", "")
}

$numpad2:: {
    ExecuteActionWithCondition("MoveToGridDown", "")
}

$numpad7:: {
    ExecuteActionWithCondition("MoveToGridTopLeft", "")
}

$numpad9:: {
    ExecuteActionWithCondition("MoveToGridTopRight", "")
}

$numpad1:: {
    ExecuteActionWithCondition("MoveToGridBottomLeft", "")
}

$numpad3:: {
    ExecuteActionWithCondition("MoveToGridBottomRight", "")
}

$^+#left:: {
    ExecuteActionWithCondition("TuckLeft", "")
}

$^+#right:: {
    ExecuteActionWithCondition("TuckRight", "")
}

$^+#up:: {
    ExecuteActionWithCondition("TuckUp", "")
}

$^+#down:: {
    ExecuteActionWithCondition("TuckDown", "")
}

$^+#p:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("PeekTucked", "")
}

$^+#u:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("Untuck", "")
}

