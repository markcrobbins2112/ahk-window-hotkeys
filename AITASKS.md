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

## [x] Incoming tasks from chat
- [x] Move untucked window to the top of the Z-order index upon edge bump
- [x] Implement physical drag resistance (4x perpendicular and 2x parallel damping tension) when pulling nestled windows from stowed bounds
- [x] Implement hysteresis pop-off release threshold (120px) to restore normal free-floating window states
- [x] Add dynamic Ctrl-hold Dock-Seeking mechanism with translucent cyan (`00FFCC`) predicted edge indicator band and snap-to-dock binding on release
- [x] Reverse engineer HotWinAHK window nudging and docking codebase
- [x] Complete README.md with detailed script features and description
- [x] Complete BUILD.md documenting compilation and asset pipelines
- [x] Complete SPEC.md outlining requested specifications and solved technical concerns
- [x] Complete MANUAL.md detailing structural architecture and core algorithms
- [x] Complete FEATURES.md organizing and detailing individual feature items
- [x] Complete TESTING.md outlining detailed testing procedures and interactive checklists
- [x] Rename WindowNudger, WindowHotkeys.ahk, and WindowHotkeys.ini to HotWinAHK/displayName variants, and update all codebase references
- [x] Rename helper subprocess script from TrayHelper.ahk to HotWinAHK_tray.ahk and update all reference models
- [x] Implement SnapToGridEnlarge/Shrink grid snapping and multi-sided enlargement/shrinkage logic

## [x] Errors
- [x] lint 1: Resolved warning where `ExecuteActionWithCondition` was considered an unassigned local variable. Fixed by placing the `#Include "HotWinAHK_aux.ahk"` statement at the bottom of `HotWinAHK.ahk` after the global function definitions.
- [x] lint 2: Resolved warning where `ShowHelpScreen` was flagged as an unassigned local variable inside case `HelpScreen`. Built a fully-featured, dark-themed interactive help dashboard in `HotWinAHK.ahk`.
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







## [ ] New Settings

## [ ] New Commands

## [ ] New Bindings

## [ ] New Features

## [ ] Settings

## [ ] Commands

## [ ] Bindings

## [ ] Features
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
