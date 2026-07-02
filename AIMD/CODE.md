---
title: CODE
---

<!-- # TEMPLATE: CODE.template.md -->
<!-- 
# CODE
# Any text bounded by double curly braces {{like this}} is a placeholder for you to fill out.
# Replace those placeholders with real paths, rules, and project constraints.
#
# INSTRUCTIONS FOR THE AI AGENT:
# This file governs programming guidelines, syntax conventions, indentation (tabs vs spaces), 
# ordering, and regions formatting. Every single code file must adhere strictly to these rules!
-->

<!-- markdownlint-disable MD013 -->

# CODE

## 📑 AI Primary Files
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔸 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

## 🔍 Table of Contents
- [[#Implementation Guidelines]] ^toc-guidelines
- [[#Markdown Guidelines]] ^toc-markdown
- [[#Formatting & Syntax Style]] ^toc-syntax
- [[#🛡️ Robustness & Error-Handling Frameworks]] ^toc-errors
- [[#Regions Division Style]] ^toc-regions
- [[#🚀 Go to...]] ^toc-goto

## 🛠️ Implementation Guidelines
[[#^toc-guidelines|TOC]]
- **Encoding Safety**: Preserve UTF-8 signatures. Ensure icons, characters, emojis, and unicode symbols are written cleanly without corruption (mojibake).
- **Target Changes Only**: Avoid complete file rewrites. Prefer minor, highly precise surgical patches to retain existing code blocks and comments intact.

## 📝 Markdown Guidelines
[[#^toc-markdown|TOC]]
- Use dashes (`-`) instead of asterisks (`*`) for Bullet list items.
- Maintain UPPERCASE.md documents cleanly with alphabetical features lists, updated logs, and checked backlogs.
- Always update UPPERCASE.md files (such as AITASKS.md, AILOG.md, etc.) when tasks are completed or work is performed
- Put all chat task requests from the user on TASKS.md first before working on them
- If the user says 'do tasks', always state what you are going to do and then wait for the user's adjustments and approval before proceeding
- LOG: The top of LOG.md should always feature a "Commit Message" section maintained by the AI, which must be cleared whenever the user says they have committed or appended the changes

## ✒️ Formatting & Syntax Style
[[#^toc-syntax|TOC]]
- **Indentation**: Use tabs for indentation.
- **Braces and Blocks**: Always use braces for control expressions, never inline single-line statements without brackets
- **Naming Conventions**: 
  - For standard local, global, or object variables that consist of multiple words, the overwhelming community standard is camelCase
  - Classes represent blueprints or templates for objects. To make them stand out from standard functions and variables, you should use PascalCase
  - Functions and Methods use PascalCase
  - Constants and Global Variables use UPPER_SNAKE_CASE
- **Global Function Ordering**: Listed immediately after dependencies

---

## 🛡️ Robustness & Error-Handling Frameworks
[[#^toc-errors|TOC]]
- **Primary Paradigm:** Structured Try/Catch blocks using Error Objects, supplemented by native AHK v2 runtime error throwing
- **Defensive Coding Checks:** Use `FileExist()` and `WinExist()` to validate paths and window handles before running destructive disk mutations or UI automation. Use `HasProp()` or type functions like `IsObject()` to check arguments since AHK is dynamically typed.
- **Logging Integration:** Route diagnostics using `OutputDebug()` for real-time IDE debugging, or use `FileAppend()` to target a dedicated local log or redirect to standard error via the `"*"` stream. Extract `.Message`, `.What`, and `.Line` from catchable Error Objects to populate failure logs.
- **Inline Comments:** Document the "Why" behind mandatory execution delays (`Sleep`), specific Win32 `DllCall` parameters, or `ComObject` interface workarounds required by uncooperative target applications. Do not explain basic syntax or hotkey declarations.

```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force

try {
    ; --- 1. DEFENSIVE CODING CHECK ---
    ; We check if the file exists BEFORE trying to append data or modify it
    targetFilePath := A_ScriptDir "\sensitive_data.txt"
    
    if !FileExist(targetFilePath) {
        ; We throw a custom ValueError if our defense check fails
        throw ValueError("The critical target file could not be found.", -1, targetFilePath)
    }

    ; --- 3. INLINE COMMENTS ---
    ; Example of bad vs good comments:
    ; BAD:  Run notepad.exe ; Opens notepad
    ; GOOD: Launching with a brief buffer delay because Notepad takes a moment to hook into the OS focus
    Run("notepad.exe")
    Sleep(250) 
    
    ; We safely grab the window handle (hWnd) to guarantee we talk to the right app
    if !windowHandle := WinExist("ahk_class Notepad") {
        throw TargetError("Notepad window failed to initialize in time.", -1)
    }

    ; Send data to the verified window handle
    ControlSetText("Data backup complete!", "Edit1", windowHandle)

} catch Error as err {
    ; --- 2. LOGGING INTEGRATION ---
    ; Create a cleanly formatted error message using properties from the Error Object
    logMessage := Format("[{1}] ERROR in {2} (Line {3}): {4}`n", A_Now, err.What, err.Line, err.Message)
    
    ; Route 1: Send to your IDE debugger window (VS Code, DebugView, etc.) in real-time
    OutputDebug(logMessage)
    
    ; Route 2: Append directly to a local diagnostic error log file
    FileAppend(logMessage, A_ScriptDir "\error_log.txt")
    
    ; Route 3: If running from a terminal, redirect to the standard error stream
    FileAppend(logMessage, "*")
    
    ; Notify the user before safely terminating the script execution
    MsgBox("A critical error occurred. Details have been saved to error_log.txt", "Script Failure", 16)
    ExitApp(1)
}
```


---

<!-- 
  INSTRUCTION: Specify standard regions delimiters (#region / #endregion) 
  and naming rules to group structures systematically.
-->
## 📂 Regions Division Style
[[#^toc-regions|TOC]]
- **Structures**: Wrap classes or data blocks inside system structures regions named `_globals`, `_classes`, or custom container dividers.
- **Example Regions Map**:
```ahk
;@region 1. INITIALIZATION & CONFIGURATION
#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")
SetWorkingDir(A_ScriptDir)
;@endregion

;@region 2. HOTKEYS & SHORTCUTS
; Launch Browser
#b::Run("chrome.exe")

; Paste Plain Text
^+v::A_Clipboard := A_Clipboard
;@endregion

;@region 3. HELPER FUNCTIONS
CleanString(inputData) {
    return Trim(RegExReplace(inputData, "\s+", " "))
}
;@endregion
```
---
## 🚀 Go to...
[[#^toc-goto|TOC]]
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔸 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- # TEMPLATE: CODE.template.md -->
