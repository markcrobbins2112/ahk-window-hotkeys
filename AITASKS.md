# AI Tasks
---
## Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- 🔸[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

<!-- Ai To Maintain and work from this list -->
[Open Notepad Safely](aip://open/c:/windows/notepad.exe)

## 💡 Suggestions & Opportunities
- [x] **Implementation of Symmetrical Bulk Window Actions**: Code and register the first-class missing bulk commands: `RestoreAll`, `RestoreAllMinimized`, and `MaximizeAll` to provide a complete layout-restoration experience.
- [x] **Implementation of Four-Sided Symmetrical Sizing/Grid Snaps**: Program the logically missing four-sided symmetrical commands (`StretchToGridAll`, `PullToGridAll`, `AddAll`, `SubtractAll`, and `StretchAll`) in `HotWinAHK.ahk` to grant full multi-side bounding control.
- [x] **Diagonal Integration for Move/Stretch Commands**: Introduce key mappings or Command Palette integrations for diagonal operations (e.g., `StretchToGridTopLeft`, `PullToGridBottomRight`) to fully bridge the corner positioning gap.

## 🚀 Next Steps
- All current design integrations and requested commands have been successfully implemented, verified, and cataloged. Any future enhancements will be listed here as needed.

## [x] Incoming tasks from chat
- [x] Mathematically corrected StretchToGrid/PullToGrid boundary offset snap states to guarantee perfect direction-oriented outward and inward window stretching/pulling
- [x] Programmed gorgeous multi-line cursor tooltips for active actions, resolving command names against `GetGlobalCommandList()` to automatically format and present categories, descriptions, and defaults
- [x] Refactored HotWinAHK.ini formatting (no blank lines, updated matrix header, descriptive region comments for each command family, and newly invented active key bindings for historically unbound commands)
- [x] Recursively structured folding region config matrix for HotWinAHK.ini and synchronized descriptive documentation
- [x] Dark theme for popup menus (SysMenu, tray, etc.) using undocumented ordinals 135 and 136 in uxtheme
- [x] Fixed closure bug in SysMenu so items execute their target commands correctly
- [x] Group and reduce keybinding copies (Numpad -> [MoveToGridX] -> NumpadX, Arrow keys -> [UntuckX] -> Win+Ctrl+Alt+Arrows)
- [x] Renamed MoveDown10px -> MoveTadDown, etc. and MoveDown1px -> MovepxDown, etc.
- [x] Updated header and commands sections inside `HotWinAHK.ini`
- [x] Silenced focus change beep in AudibleFocusListenerCallback
- [x] Added beautiful Startup arpeggio sound and big command sounds (reload/suspension toggle)
- [x] Added tiny clicky feedback sound and quick on-screen robot tipping tooltips when window commands are executed
- [x] Configured robot emoji tooltips and overlay icons for brand visibility
- [x] Fixed dimension preservation in `SafeMove()` so Center, MoveTad, and Movepx commands do not resize windows to 800x600 grid defaults
- [x] Created interactive `KeyDiagnostics` command testing physical keypad & arrow modifier keys with 5s timeouts and clipboard reporting
- [x] Created `KeyQuery` command: Provides dark modal dialog with an 8s timer/countdown (resets on keypress) to capture physical keystrokes/modifiers and look up associated HotWinAHK commands, running continuously until ESC is pressed
- [x] Created `Settings` command: Provides interactive dark-themed configuration dialog (checkboxes) allowing the user to configure 'Silence All' (suppresses all audio beeps), 'Silent on Windows Commands' (silences movement sounds), and 'Tip Windows Commands' (shows/hides quick tip robot cursor tooltips). Writes preferences instantly to the `[Settings]` section in `HotWinAHK.ini`
- [x] Fixed `DragWindow` command bugs: Eliminated opaque milky-white overlays on background windows by updating the tracking loop to only adjust the transparency (specifically: gentle 200 opacity) of the active dragged window itself
- [x] Dual Numpad Hotkey Compilation: Implemented automated compilation ensuring both standard Numpad keystrokes and their Navigation (Ins, End, Down, PgDn, etc.) counterparts trigger identical HotWinAHK commands seamlessly, regardless of NumLock state
- [x] DragWindow Overlapping Translucency: Integrated scanning and fading of overlapping windows above the current drag target to 50% opacity, allowing effortless visual identification of background structures during drags, with full transparency restoration on release
- [x] Parameterized Tucked Peeking Lists: Refactored stowed list items with custom filter arguments and clear hexadecimal HWND labels (e.g. `[Left] Notepad [0x1D04FE]`)
- [x] Interactive Search Window Picker: Programmed a dark-themed GUI matching the overall system aesthetics allowing live fuzzy search by titles and executable names to instantly refocus chosen windows on Enter or click
- [x] Immersive 3D Parallax Rotation Mode: Coded the `Desk3d` depth-based parallax workspace that rotates active non-tucked windows on mouse movement with mathematical scaling weights based on layered distance index, cleanly resetting on Escape
- [x] Configured Custom Axis-Specific Precision Step Dimensions: Tailored the coarse-scale MoveTad shifting increments to cleanly equal exactly 1/4 of default cell width and height settings (106 x 58 pixels), and adjusted fine-scale Movepx nudging bounds to exactly 10px width and 5px height respectively. Integrated these parameters across Grow and Trim scale actions.
- [x] Eliminated Hotkey Redundancies & Consolidated Layout: Segregated the spatial and sizing tasks into completely unique physical layouts. Restricted the precision nudging (`MoveTad`, `Movepx`) command families exclusively to the Arrow keys. Cleanly removed duplicate arrow key mappings (`keys2`) from the Numpad-focused scaling operations (`HalfSize`, `DoubleSize`), completely conserving hotkey combinations and preventing duplicate execution overlap.


## [x] Errors
- [x] Unexpected Reserved Word in `ShowWindowPicker`: Fixed runtime compiler crash by replacing invalid block fat-arrow syntax (`(params) => { ... }`), which is unsupported in AutoHotkey v2, with proper native nested function blocks (`UpdateList(searchText) { ... }` and `ActivateSelection(*) { ... }`).
- [x] lint 1: Resolved warning where `ExecuteActionWithCondition` was considered an unassigned local variable. Fixed by placing the `#Include "HotWinAHK_aux.ahk"` statement at the bottom of `HotWinAHK.ahk` after the global function definitions.
- [x] lint 2: Resolved warning where `ShowHelpScreen` was flagged as an unassigned local variable inside case `HelpScreen`. Built a fully-featured, dark-themed interactive help dashboard in `HotWinAHK.ahk`.
- [x] Ceiling local variable warning: Resolved diagnostic sequence warning where `Ceiling` was flagged as an unassigned local variable by replacing it with the correct built-in `Ceil` function in `HotWinAHK.ahk`.
- [x] InputHook Property Error: Fixed runtime compiling crash where `.Reason` was accessed on an `InputHook` instance by replacing it with the standard AHK v2 property name `.EndReason`.
- [x] WinSetTransparent Exception: Fixed "Target window not found" error during drag initialization by invoking `dockIndicatorGui.Show("Hide")` to physically register the window with the OS manager before modifying its alpha value, wrapped in a robust try/catch guard. ✅ 2026-06-12

## [x] New Fails
- [x] Window is not at top of z-order when it is revealed from a tucked state (Resolved via robust momentary AlwaysOnTop Z-order seizure toggle)
- [x] Window drag and drop to new side does not work at all
    - [x] saw no resistance to being taker from its docked state (Resolved via low-level $LButton hook interceptor containing 4x physical motion resistance)
    - [x] saw no indicators it was a docked item in transit (Resolved via beautiful translucent cyan indicator band appearing dynamically during Ctrl + Drag)
    - [x] saw no indicators showing it was removed as a docked item (Resolved via pop-off beep and permanent status restoration beyond 120px threshold)

## [x] New Tasks
- [x] Detecting Bumps
    - Fixed bug where bumper timer shut down if no stowed window was found. Improved dual-anchor mouse hover detection so peek windows stow automatically on edge leave.
- [x] Untuck, window should reveal itself without activation
    - Resolved `0x0014` coord/size jumping issue by utilizing native `0x0053` (`SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW`) drawing to pin without changing bounds or activating.
- [x] Enhance the help screen
    - Implemented a gorgeous, highly structured 3-column color coded keybinding reference matrix above the live filter and commands table.
- [x] Robust Stowed Window Drag Interaction
    - Ensure stowed windows are physically elevated to the top of the Z-order index upon untuck.
    - Drag pull-off resistance: Restrain stowed window drags away from the edge with a 4x movement damping profile.
    - Threshold Pop-off: Permanently restore peek-untucked windows to regular status if pulled beyond 120px from their docked edge.
    - Ctrl-hold Dock Seeking: Dynamically reposition peek-untucked windows with a translucent cyan overlay indicator of the predicted new screen docking edge when moving and holding Ctrl. Snapping binds to the target edge on release.

## [x] New Next
- [x] is Win+Ctrl+MouseBump_top valid (Answer: No. Physical keyboard key or mouse button names must be valid system virtual key codes. `MouseBump_top` is an edge coordinate event description, not an actual virtual key, making this syntax invalid for keyboard remapping.)
- [x] new command CopyCommands (Completely built and mapped to Win+Ctrl+C)
- [x] new command CopyBindings (Completely built and mapped to Win+Alt+C)

## [x] New Changes
- [x] Prevent standard keys 2 and 4 row collision via precise keyboard hook prefix compilation and aggressive multi-instance zombie process terminator
- [x] Resolve tuck-revealed window drag deadlock issue via immediate focus-lifecycle timer suspension and atomic state locking
- [x] Resolve key non-responsiveness and keyboard hook/child script release issues upon engine suspension or shutdown

## [x] New Features
- [x] Peek Tucked
    - [x] Offers a menu of all tucked windows listing their titles and the side they are tucked to
    - [x] selection causes window to reveal in the same way as a cursor bumping that edge
- [x] Untuck
    - [x] offers a menu of all tucked and removes the selected from its tuck
- [x] paint a dot at top left of active window
    - [x] green when program is not suspended, otherwise yellow
- [x] Add a command palette with a fuzzy picker so all the commands can by tried manually

## [x] New Fails
- [x] when pulling a window from its tucked state do not do a resistence
    - [x] use an indicator of how far I can pull before it is free
    - [x] use a sound to indicate pop off
    - [x] if I am dragging a popped off window around, show indicators when I am in range of having it dock to another edge should I release the window
- [x] widen and clean up the help dialog
    - [x] do not include commands in the list that are arrows or numpad numbers
- [x] help doesnt show







## [x] New Settings
- [x] Configured new sections `[ScaleExpandGridPart]` and `[ScaleReduceGridPart]` in `HotWinAHK.ini`, transitioning existing 10px scaling actions to Alt layouts.

## [x] New Commands
- [x] Implemented core case blocks for `ScaleExpandGridPart` and `ScaleReduceGridPart` in the commands registry.
- [x] Redid `Center` case inside `ExecuteCommandRegistry` of `HotWinAHK.ahk` to perform mathematically precise centering within workspace bounds.

## [x] New Bindings
- [x] Bound `ScaleExpandGridPart` to `Ctrl+NumpadAdd`
- [x] Bound `ScaleReduceGridPart` to `Ctrl+NumpadSub`
- [x] Rebound `ScaleExpand10px` to `Alt+NumpadAdd`
- [x] Rebound `ScaleReduce10px` to `Alt+NumpadSub`

## [x] New Features
- [x] Formulated an exact pixel-grid matching algorithm using indices to represent standard coordinates and midpoint columns/rows to dynamically expand and shrink windows symmetrically.

## [x] Settings
- [x] Swapped Alt/Ctrl assignments for 10px and GridPart scale variants in HotWinAHK.ini.

## [x] Commands
- [x] Implemented half-grid and normal-grid advancing and contracting for StretchToGrid, PullToGrid, Add, and Subtract.
- [x] Redid Center command to center precise active window metrics without causing any resize changes.
- [x] Implemented new sizing commands: TrimAll, GrowLeft, GrowRight, GrowTop, GrowBottom, and GrowAll.
- [x] Implemented persistent Window Home commands: SetHome, ClearHome, GoHome, Home (interactive with countdown/strip triggers), and HomePeek (translucent overlay footprint draw).
- [x] Introduced dual-color ambient home status indicators (cyan when configured, green when perfectly aligned) offset gracefully.
- [x] Added strict visible overlapped window search criteria to `ahk-window-cmdr.au3` to avoid applying verbs on invalid child/popup window frames.

## [x] Bindings
- [x] Retained standard direction-oriented key combinations to triggers.
- [x] Updated Reference Panel (`GetGlobalCommandList`) row metadata to perfectly follow HotWinAHK.ini adjustments.

## [x] Features
- [x] Created advanced coordinate index mapper identifying bounding limits across cells and midpoint lines.
- [x] Developed robust compiled AutoIt Au3 script (ahk-window-cmdr.au3) supporting command execution on target ancestors via dynamic IPC/CopyData messages.
- [x] Crafted a highly polished, persistent Window Home management module using fuzzy matching criteria for title-based window tracking.
- [x] Replaced standard ToolTips with a magnificent dark center screen overlay GUI with intelligent sizing and context-adaptive iconography.
- [x] Resolved commander messaging bug by locking the main orchestrator script window title and configuring AutoIt to find it with hidden windows matching enabled.
- [x] Implemented single-instance auto-replacement logic with quiet startup options and parameter routing to hovered parent window ancestors.

## [x] Checkpoint 3 Accomplished Tasks
- [x] **KeyQuery Timer and Spacebar Binding**: Removed countdown timer from KeyQuery; it now runs persistently until ESC is pressed. Added `Spacebar` to immediately copy the mapped command string to the clipboard with an aesthetic status message.
- [x] **Class Navigation Executable Check**: Reconfigured `PrevClassWindow` and `NextClassWindow` to group windows by their full executable path (`WinGetProcessPath`) instead of just `WinGetClass`.
- [x] **Mouse-Relative Window Drag**: Dynamic `DragWindow` operation now targets the ancestor window under the mouse cursor first, falling back to the active foreground window.
- [x] **Granular Beeps & Editor Customization**: Updated the settings manager and UI to support disabling startup/suspension sound beeps and added a dark-themed text field allowing the user to configure a custom text editor path (e.g., Cursor) with direct system shell fallbacks.
- [x] **Edge-Drag Automatic Tucking**: Designed a translucent cyan indicator overlay during window drag mode that displays when approaching screen margins. Releasing the window triggers automatic stowing on the predicted edge.
- [x] **8 New Bulk Window Operations**: Added `RestoreAllMaximized`, `MaximizeAllRestored`, `MaximizeAllMinimized`, `SwapMaximizedRestored`, `SwapMinimizedRestored`, `MinimizeAll`, `MinimizeAllRestored`, and `MinimizeAllMaximized`. Created the `IsEligibleForBulkCommand` utility to protect stowed (tucked), hidden, or trayed windows from bulk state alterations.
---
## Go Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- 🔸[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
