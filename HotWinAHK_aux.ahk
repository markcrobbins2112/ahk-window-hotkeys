; =======================================================================================
;          AUTOMATICALLY GENERATED NATIVE SHELL HOTKEYS - DO NOT EDIT DIRECTLY
; =======================================================================================
#Requires AutoHotkey v2.0

$#/:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("HelpScreen", "")
}

$!#/:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("SysMenu", "")
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

$^+#a:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyCommandsAlpha", "")
}

$^+#h:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyCommandsHelp", "")
}

$!#c:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyBindings", "")
}

$^+#b:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyBindingsAlpha", "")
}

$^+#l:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("CopyBindingsLocation", "")
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

$^+#k:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("KeyDiagnostics", "")
}

$^+#q:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("KeyQuery", "")
}

$^+#i:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("Settings", "")
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

$^#f4:: {
    ExecuteActionWithCondition("DragWindow", "")
}

$#f3:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("WindowPicker", "")
}

$#;:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("Desk3d", "")
}

#rbutton:: {
    ExecuteActionWithCondition("MouseToGrid", "")
}

#lbutton:: {
    ExecuteActionWithCondition("MouseRelativeSize", "")
}

$!#left:: {
    ExecuteActionWithCondition("MoveTadLeft", "")
}

$!#right:: {
    ExecuteActionWithCondition("MoveTadRight", "")
}

$!#up:: {
    ExecuteActionWithCondition("MoveTadUp", "")
}

$!#down:: {
    ExecuteActionWithCondition("MoveTadDown", "")
}

$+#left:: {
    ExecuteActionWithCondition("MovepxLeft", "")
}

$+#right:: {
    ExecuteActionWithCondition("MovepxRight", "")
}

$+#up:: {
    ExecuteActionWithCondition("MovepxUp", "")
}

$+#down:: {
    ExecuteActionWithCondition("MovepxDown", "")
}

$+numpad4:: {
    ExecuteActionWithCondition("EdgeLeft", "")
}

$+numpadleft:: {
    ExecuteActionWithCondition("EdgeLeft", "")
}

$+numpad6:: {
    ExecuteActionWithCondition("EdgeRight", "")
}

$+numpadright:: {
    ExecuteActionWithCondition("EdgeRight", "")
}

$+numpad8:: {
    ExecuteActionWithCondition("EdgeTop", "")
}

$+numpadup:: {
    ExecuteActionWithCondition("EdgeTop", "")
}

$+numpad2:: {
    ExecuteActionWithCondition("EdgeBottom", "")
}

$+numpaddown:: {
    ExecuteActionWithCondition("EdgeBottom", "")
}

$+numpad7:: {
    ExecuteActionWithCondition("EdgeTopLeft", "")
}

$+numpadhome:: {
    ExecuteActionWithCondition("EdgeTopLeft", "")
}

$+numpad9:: {
    ExecuteActionWithCondition("EdgeTopRight", "")
}

$+numpadpgup:: {
    ExecuteActionWithCondition("EdgeTopRight", "")
}

$+numpad1:: {
    ExecuteActionWithCondition("EdgeBottomLeft", "")
}

$+numpadend:: {
    ExecuteActionWithCondition("EdgeBottomLeft", "")
}

$+numpad3:: {
    ExecuteActionWithCondition("EdgeBottomRight", "")
}

$+numpadpgdn:: {
    ExecuteActionWithCondition("EdgeBottomRight", "")
}

$+numpad5:: {
    ExecuteActionWithCondition("EdgeCenter", "")
}

$+numpadclear:: {
    ExecuteActionWithCondition("EdgeCenter", "")
}

$numpad5:: {
    ExecuteActionWithCondition("Center", "")
}

$numpadclear:: {
    ExecuteActionWithCondition("Center", "")
}

$numpad4:: {
    ExecuteActionWithCondition("MoveToGridLeft", "")
}

$numpadleft:: {
    ExecuteActionWithCondition("MoveToGridLeft", "")
}

$numpad6:: {
    ExecuteActionWithCondition("MoveToGridRight", "")
}

$numpadright:: {
    ExecuteActionWithCondition("MoveToGridRight", "")
}

$numpad8:: {
    ExecuteActionWithCondition("MoveToGridUp", "")
}

$numpadup:: {
    ExecuteActionWithCondition("MoveToGridUp", "")
}

$numpad2:: {
    ExecuteActionWithCondition("MoveToGridDown", "")
}

$numpaddown:: {
    ExecuteActionWithCondition("MoveToGridDown", "")
}

$numpad7:: {
    ExecuteActionWithCondition("MoveToGridTopLeft", "")
}

$numpadhome:: {
    ExecuteActionWithCondition("MoveToGridTopLeft", "")
}

$numpad9:: {
    ExecuteActionWithCondition("MoveToGridTopRight", "")
}

$numpadpgup:: {
    ExecuteActionWithCondition("MoveToGridTopRight", "")
}

$numpad1:: {
    ExecuteActionWithCondition("MoveToGridBottomLeft", "")
}

$numpadend:: {
    ExecuteActionWithCondition("MoveToGridBottomLeft", "")
}

$numpad3:: {
    ExecuteActionWithCondition("MoveToGridBottomRight", "")
}

$numpadpgdn:: {
    ExecuteActionWithCondition("MoveToGridBottomRight", "")
}

$^numpad4:: {
    ExecuteActionWithCondition("JumpGridLeft", "")
}

$^numpadleft:: {
    ExecuteActionWithCondition("JumpGridLeft", "")
}

$^numpad6:: {
    ExecuteActionWithCondition("JumpGridRight", "")
}

$^numpadright:: {
    ExecuteActionWithCondition("JumpGridRight", "")
}

$^numpad8:: {
    ExecuteActionWithCondition("JumpGridUp", "")
}

$^numpadup:: {
    ExecuteActionWithCondition("JumpGridUp", "")
}

$^numpad2:: {
    ExecuteActionWithCondition("JumpGridDown", "")
}

$^numpaddown:: {
    ExecuteActionWithCondition("JumpGridDown", "")
}

$^numpad7:: {
    ExecuteActionWithCondition("JumpGridTopLeft", "")
}

$^numpadhome:: {
    ExecuteActionWithCondition("JumpGridTopLeft", "")
}

$^numpad9:: {
    ExecuteActionWithCondition("JumpGridTopRight", "")
}

$^numpadpgup:: {
    ExecuteActionWithCondition("JumpGridTopRight", "")
}

$^numpad1:: {
    ExecuteActionWithCondition("JumpGridBottomLeft", "")
}

$^numpadend:: {
    ExecuteActionWithCondition("JumpGridBottomLeft", "")
}

$^numpad3:: {
    ExecuteActionWithCondition("JumpGridBottomRight", "")
}

$^numpadpgdn:: {
    ExecuteActionWithCondition("JumpGridBottomRight", "")
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

$^+#numpad4:: {
    ExecuteActionWithCondition("StretchLeft", "")
}

$^+#numpadleft:: {
    ExecuteActionWithCondition("StretchLeft", "")
}

$^+#numpad6:: {
    ExecuteActionWithCondition("StretchRight", "")
}

$^+#numpadright:: {
    ExecuteActionWithCondition("StretchRight", "")
}

$^+#numpad8:: {
    ExecuteActionWithCondition("StretchTop", "")
}

$^+#numpadup:: {
    ExecuteActionWithCondition("StretchTop", "")
}

$^+#numpad2:: {
    ExecuteActionWithCondition("StretchBottom", "")
}

$^+#numpaddown:: {
    ExecuteActionWithCondition("StretchBottom", "")
}

$^+#numpad7:: {
    ExecuteActionWithCondition("StretchTopLeft", "")
}

$^+#numpadhome:: {
    ExecuteActionWithCondition("StretchTopLeft", "")
}

$^+#numpad9:: {
    ExecuteActionWithCondition("StretchTopRight", "")
}

$^+#numpadpgup:: {
    ExecuteActionWithCondition("StretchTopRight", "")
}

$^+#numpad1:: {
    ExecuteActionWithCondition("StretchBottomLeft", "")
}

$^+#numpadend:: {
    ExecuteActionWithCondition("StretchBottomLeft", "")
}

$^+#numpad3:: {
    ExecuteActionWithCondition("StretchBottomRight", "")
}

$^+#numpadpgdn:: {
    ExecuteActionWithCondition("StretchBottomRight", "")
}

$#numpad4:: {
    ExecuteActionWithCondition("StretchToGridLeft", "")
}

$#numpadleft:: {
    ExecuteActionWithCondition("StretchToGridLeft", "")
}

$#numpad6:: {
    ExecuteActionWithCondition("StretchToGridRight", "")
}

$#numpadright:: {
    ExecuteActionWithCondition("StretchToGridRight", "")
}

$#numpad8:: {
    ExecuteActionWithCondition("StretchToGridUp", "")
}

$#numpadup:: {
    ExecuteActionWithCondition("StretchToGridUp", "")
}

$#numpad2:: {
    ExecuteActionWithCondition("StretchToGridDown", "")
}

$#numpaddown:: {
    ExecuteActionWithCondition("StretchToGridDown", "")
}

$#numpad7:: {
    ExecuteActionWithCondition("StretchToGridTopLeft", "")
}

$#numpadhome:: {
    ExecuteActionWithCondition("StretchToGridTopLeft", "")
}

$#numpad9:: {
    ExecuteActionWithCondition("StretchToGridTopRight", "")
}

$#numpadpgup:: {
    ExecuteActionWithCondition("StretchToGridTopRight", "")
}

$#numpad1:: {
    ExecuteActionWithCondition("StretchToGridBottomLeft", "")
}

$#numpadend:: {
    ExecuteActionWithCondition("StretchToGridBottomLeft", "")
}

$#numpad3:: {
    ExecuteActionWithCondition("StretchToGridBottomRight", "")
}

$#numpadpgdn:: {
    ExecuteActionWithCondition("StretchToGridBottomRight", "")
}

$!#numpad2:: {
    ExecuteActionWithCondition("PullToGridDown", "")
}

$!#numpaddown:: {
    ExecuteActionWithCondition("PullToGridDown", "")
}

$!#numpad8:: {
    ExecuteActionWithCondition("PullToGridUp", "")
}

$!#numpadup:: {
    ExecuteActionWithCondition("PullToGridUp", "")
}

$!#numpad4:: {
    ExecuteActionWithCondition("PullToGridLeft", "")
}

$!#numpadleft:: {
    ExecuteActionWithCondition("PullToGridLeft", "")
}

$!#numpad6:: {
    ExecuteActionWithCondition("PullToGridRight", "")
}

$!#numpadright:: {
    ExecuteActionWithCondition("PullToGridRight", "")
}

$!#numpad7:: {
    ExecuteActionWithCondition("PullToGridTopLeft", "")
}

$!#numpadhome:: {
    ExecuteActionWithCondition("PullToGridTopLeft", "")
}

$!#numpad9:: {
    ExecuteActionWithCondition("PullToGridTopRight", "")
}

$!#numpadpgup:: {
    ExecuteActionWithCondition("PullToGridTopRight", "")
}

$!#numpad1:: {
    ExecuteActionWithCondition("PullToGridBottomLeft", "")
}

$!#numpadend:: {
    ExecuteActionWithCondition("PullToGridBottomLeft", "")
}

$!#numpad3:: {
    ExecuteActionWithCondition("PullToGridBottomRight", "")
}

$!#numpadpgdn:: {
    ExecuteActionWithCondition("PullToGridBottomRight", "")
}

$^#numpad8:: {
    ExecuteActionWithCondition("GrowTop", "")
}

$^#numpadup:: {
    ExecuteActionWithCondition("GrowTop", "")
}

$^#numpad2:: {
    ExecuteActionWithCondition("GrowBottom", "")
}

$^#numpaddown:: {
    ExecuteActionWithCondition("GrowBottom", "")
}

$^#numpad6:: {
    ExecuteActionWithCondition("GrowLeft", "")
}

$^#numpadright:: {
    ExecuteActionWithCondition("GrowLeft", "")
}

$^#numpad4:: {
    ExecuteActionWithCondition("GrowRight", "")
}

$^#numpadleft:: {
    ExecuteActionWithCondition("GrowRight", "")
}

$^#numpad7:: {
    ExecuteActionWithCondition("GrowTopLeft", "")
}

$^#numpadhome:: {
    ExecuteActionWithCondition("GrowTopLeft", "")
}

$^#numpad9:: {
    ExecuteActionWithCondition("GrowTopRight", "")
}

$^#numpadpgup:: {
    ExecuteActionWithCondition("GrowTopRight", "")
}

$^#numpad1:: {
    ExecuteActionWithCondition("GrowBottomLeft", "")
}

$^#numpadend:: {
    ExecuteActionWithCondition("GrowBottomLeft", "")
}

$^#numpad3:: {
    ExecuteActionWithCondition("GrowBottomRight", "")
}

$^#numpadpgdn:: {
    ExecuteActionWithCondition("GrowBottomRight", "")
}

$^#numpad5:: {
    ExecuteActionWithCondition("GrowAll", "")
}

$^#numpadclear:: {
    ExecuteActionWithCondition("GrowAll", "")
}

$+#numpad8:: {
    ExecuteActionWithCondition("TrimTop", "")
}

$+#numpadup:: {
    ExecuteActionWithCondition("TrimTop", "")
}

$+#numpad2:: {
    ExecuteActionWithCondition("TrimBottom", "")
}

$+#numpaddown:: {
    ExecuteActionWithCondition("TrimBottom", "")
}

$+#numpad6:: {
    ExecuteActionWithCondition("TrimLeft", "")
}

$+#numpadright:: {
    ExecuteActionWithCondition("TrimLeft", "")
}

$+#numpad4:: {
    ExecuteActionWithCondition("TrimRight", "")
}

$+#numpadleft:: {
    ExecuteActionWithCondition("TrimRight", "")
}

$+#numpad7:: {
    ExecuteActionWithCondition("TrimTopLeft", "")
}

$+#numpadhome:: {
    ExecuteActionWithCondition("TrimTopLeft", "")
}

$+#numpad9:: {
    ExecuteActionWithCondition("TrimTopRight", "")
}

$+#numpadpgup:: {
    ExecuteActionWithCondition("TrimTopRight", "")
}

$+#numpad1:: {
    ExecuteActionWithCondition("TrimBottomLeft", "")
}

$+#numpadend:: {
    ExecuteActionWithCondition("TrimBottomLeft", "")
}

$+#numpad3:: {
    ExecuteActionWithCondition("TrimBottomRight", "")
}

$+#numpadpgdn:: {
    ExecuteActionWithCondition("TrimBottomRight", "")
}

$+#numpad5:: {
    ExecuteActionWithCondition("TrimAll", "")
}

$+#numpadclear:: {
    ExecuteActionWithCondition("TrimAll", "")
}

$!+#numpad8:: {
    ExecuteActionWithCondition("AddTop", "")
}

$!+#numpadup:: {
    ExecuteActionWithCondition("AddTop", "")
}

$!+#numpad2:: {
    ExecuteActionWithCondition("AddBottom", "")
}

$!+#numpaddown:: {
    ExecuteActionWithCondition("AddBottom", "")
}

$!+#numpad4:: {
    ExecuteActionWithCondition("AddLeft", "")
}

$!+#numpadleft:: {
    ExecuteActionWithCondition("AddLeft", "")
}

$!+#numpad6:: {
    ExecuteActionWithCondition("AddRight", "")
}

$!+#numpadright:: {
    ExecuteActionWithCondition("AddRight", "")
}

$!+#numpad7:: {
    ExecuteActionWithCondition("AddTopLeft", "")
}

$!+#numpadhome:: {
    ExecuteActionWithCondition("AddTopLeft", "")
}

$!+#numpad9:: {
    ExecuteActionWithCondition("AddTopRight", "")
}

$!+#numpadpgup:: {
    ExecuteActionWithCondition("AddTopRight", "")
}

$!+#numpad1:: {
    ExecuteActionWithCondition("AddBottomLeft", "")
}

$!+#numpadend:: {
    ExecuteActionWithCondition("AddBottomLeft", "")
}

$!+#numpad3:: {
    ExecuteActionWithCondition("AddBottomRight", "")
}

$!+#numpadpgdn:: {
    ExecuteActionWithCondition("AddBottomRight", "")
}

$^!#numpad8:: {
    ExecuteActionWithCondition("SubtractTop", "")
}

$^!#numpadup:: {
    ExecuteActionWithCondition("SubtractTop", "")
}

$^!#numpad2:: {
    ExecuteActionWithCondition("SubtractBottom", "")
}

$^!#numpaddown:: {
    ExecuteActionWithCondition("SubtractBottom", "")
}

$^!#numpad4:: {
    ExecuteActionWithCondition("SubtractLeft", "")
}

$^!#numpadleft:: {
    ExecuteActionWithCondition("SubtractLeft", "")
}

$^!#numpad6:: {
    ExecuteActionWithCondition("SubtractRight", "")
}

$^!#numpadright:: {
    ExecuteActionWithCondition("SubtractRight", "")
}

$^!#numpad7:: {
    ExecuteActionWithCondition("SubtractTopLeft", "")
}

$^!#numpadhome:: {
    ExecuteActionWithCondition("SubtractTopLeft", "")
}

$^!#numpad9:: {
    ExecuteActionWithCondition("SubtractTopRight", "")
}

$^!#numpadpgup:: {
    ExecuteActionWithCondition("SubtractTopRight", "")
}

$^!#numpad1:: {
    ExecuteActionWithCondition("SubtractBottomLeft", "")
}

$^!#numpadend:: {
    ExecuteActionWithCondition("SubtractBottomLeft", "")
}

$^!#numpad3:: {
    ExecuteActionWithCondition("SubtractBottomRight", "")
}

$^!#numpadpgdn:: {
    ExecuteActionWithCondition("SubtractBottomRight", "")
}

$numpadadd:: {
    ExecuteActionWithCondition("SnapToGridEnlarge", "")
}

$numpadsub:: {
    ExecuteActionWithCondition("SnapToGridShrink", "")
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

$^!#left:: {
    ExecuteActionWithCondition("UntuckLeft", "")
}

$^!#right:: {
    ExecuteActionWithCondition("UntuckRight", "")
}

$^!#up:: {
    ExecuteActionWithCondition("UntuckTop", "")
}

$^!#down:: {
    ExecuteActionWithCondition("UntuckBottom", "")
}

$^+#p:: {
    ExecuteActionWithCondition("PeekTucked", "")
}

$^+#u:: {
    try Suspend("Permit")
    ExecuteActionWithCondition("Untuck", "")
}

