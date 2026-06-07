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

## [x] Errors
- [x] lint 1: Resolved warning where `ExecuteActionWithCondition` was considered an unassigned local variable. Fixed by placing the `#Include "HotWinAHK_aux.ahk"` statement at the bottom of `HotWinAHK.ahk` after the global function definitions.
- [x] lint 2: Resolved warning where `ShowHelpScreen` was flagged as an unassigned local variable inside case `HelpScreen`. Built a fully-featured, dark-themed interactive help dashboard in `HotWinAHK.ahk`.

## [ ] New Fails
- [ ] Window is not at top of z-order when it is revealed from a tucked state
- [ ] Window drag and drop to new side does not work at all
    - [ ] saw no resistance to being taker from its docked state
    - [ ] saw no indicators it was a docked item in transit
    - [ ] saw no indicators showing it was removed as a docked item

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

## [ ] New Next
- [ ] is Win+Ctrl+MouseBump_top valid
- [ ] new command CopyCommands
- [ ] new command CopyBindings

## [ ] New Changes

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
