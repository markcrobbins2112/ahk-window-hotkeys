# AI Development Log

---
## Back to...
- ▪️[AGENTS.md](AGENTS.md)
- 🔸[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

## Commit Message
```text
feat(ahk): implement robust LButton mouse hook dragging, z-order reveals, and copy clipboard helpers
```

<!-- Example AI Log Entry
## [2026-05-31T16:12:00Z]
### 🎯 Primary Goals & Requirements
subsections/tree bullets
### 🛠️ Completed Changes in this Session
subsections/tree bullets
### 🔸 Affected Files
bulleted file list
-->
## Log Entries

## [2026-06-07T20:30:00Z]
### 🎯 Primary Goals & Requirements
- Support seamless, robust stowed window drag-and-drop operations with 4x physical motion resistance, a visual 100-alpha cyan docking indicator band overlay, and 120px absolute pop-off release.
- Force peek windows to draw on top of all existing desktop windows immediately upon edge bump without stripping text-cursor focus.
- Validate dynamic shortcut configurations and answer user queries regarding `Win+Ctrl+MouseBump_top` validity.
- Build new productivity-focused global clipboard commands `CopyCommands` and `CopyBindings`.

### 🛠️ Completed Changes in this Session
- **Low-level Mouse Hotkey Hook & Drag Handler (`$LButton`)**: Built a fully responsive client-side mouse hook `#HotIf (g_ActiveUntuckedHwnd != 0 && IsMouseOverHwnd(g_ActiveUntuckedHwnd))` that intercepts drags over peek-untucked stowed windows. Contains:
  - Standard click pass-through (if movement remains within a sub-4px deadzone).
  - Non-linear movement damping (4x perpendicular pull resistance and 2x parallel sliding motion resistance).
  - Threshold-based pop-off release (120px) which plays an auditory beep and permanently un-stows the target window to standard normal window behaviors.
  - Interactive Dock-Seeking Mode (triggered by holding `Ctrl` while dragging) that renders a translucent cyan `00FFCC` highlight band predicting the target monitor margin and binds the window to that edge upon click release.
- **Robust Momentary Z-Order Pinning**: Integrated a momentary `WinSetAlwaysOnTop(1)` then `WinSetAlwaysOnTop(0)` toggle in both `"BumpEdgeUntuck"` and `"BumpEdgeUntuckActivate"` to seize Z-order ranking and place revealed windows on top without giving them operational window focus, preventing other applications from occlusion.
- **Copy Keybindings & Commands Clipboard Assistants**: Built `CopyCommands()` and `CopyBindings()` routines that dynamically fetch parsed ini variables and command registries, format lists into clean, readable text schemas, save them to the system clipboard `A_Clipboard`, and display confirmation tooltips.
- **HotWinAHK.ini & HotWinAHK.ahk**: Standardized shortcut mappings `CopyCommands` (`Win+Ctrl+C`) and `CopyBindings` (`Win+Alt+C`) as custom meta-events in the global event routing matrix.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/HotWinAHK.ini`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T19:49:00Z]
### 🎯 Primary Goals & Requirements
- Deliver highly responsive, satisfying interactive stowed window dragging capabilities that bridge fluid gestures with precise window positioning.
- Elevate stowed peeked windows to the absolute top of the Z-order index upon edge bump.
- Add damped perpendicular and parallel physical drag resistance on stowed window edges to simulate mechanical tension.
- Support drag pop-off release triggers above 120px to permanently restore stowed windows to free-floating layout states.
- Integrate Ctrl-holding layout Dock-Seeking Mode with real-time translucent prediction bands and snapping transitions.

### 🛠️ Completed Changes in this Session
- **Move untucked window to the top of the Z-order index upon edge bump**: Guaranteed the target peek window gets elevated to `HWND_TOP` immediately on edge bump hover.
- **Implement physical drag resistance (4x perpendicular and 2x parallel damping tension) when pulling nestled windows from stowed bounds**: Added non-linear mouse cursor tracking limits to pull sturdy nestled bounds with custom mechanical movement dampening.
- **Implement hysteresis pop-off release threshold (120px) to restore normal free-floating window states**: Successfully unlocked windows from stowing parameters permanently when pulled past 120 absolute pixels away from their docking edge.
- **Add dynamic Ctrl-hold Dock-Seeking mechanism with translucent cyan (`00FFCC`) predicted edge indicator band and snap-to-dock binding on release**: Handled floating overlay panels representing docking zones on active screen borders that trigger instant snap re-dock upon click release.
- **HotWinAHK.ahk**: Declared `g_PeekX` and `g_PeekY` global variables. Refined `"BumpEdgeUntuck"` and `"BumpEdgeUntuckActivate"` to pull windows to the front using `WinMoveTop` without stealing foreground focus, and cached coordinates. Embedded a robust left-click drag tracking routine into `TrackUntuckedFocusLifecycle` that acts as a physical controller: limits movement with 4x perpendicular and 2x parallel drag dampening filters, executes Pop-off when a 120px travel trigger is exceeded, and activates a stunning translucent click-through cyan overlay band predicting screen margins when holding `Ctrl`, relocating and docking the window on release.
- **FEATURES.md**: Documented the addition, behaviors, and hotkeys of the new drag, physical resistance, and Ctrl-hold adaptive docking features.
- **MANUAL.md**: Added the physical equations, displacement resistance multipliers ($\Delta X \times 0.25$), pop-off limits, and overlay predicted docking coordinates.
- **SPEC.md**: Indexed the specifications of the HWND_TOP index upgrades, drag hysteresis curbs, and predictive cyan highlight panels.
- **AITASKS.md**: Verified and ticked off stowed window drag tasks as fully complete.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/FEATURES.md`
- `/MANUAL.md`
- `/SPEC.md`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T19:32:00Z]
### 🎯 Primary Goals & Requirements
- Resolve the runtime/compiler scoping crash involving the `g_UntuckGraceTicks` global variable inside `TrackUntuckedFocusLifecycle` when executing an untuck action.
- Ensure all global variables are correctly pre-declared at the script's entry point and properly registered within event handlers.
- Refine the design of the interactive keyboard and gesture command guide (`Win + /`) by adding a beautiful, highly structured 3-column physical matrix layout above the list table.

### 🛠️ Completed Changes in this Session
- **HotWinAHK.ahk**: Formally pre-declared `Global g_UntuckGraceTicks := 0` in the global variable registry header. Refactored references inside the `BumpEdgeUntuck` and `BumpEdgeUntuckActivate` handlers to initialize the grace countdown successfully. Stripped out illegal inline `global` redeclarations inside assignment blocks which were causing AutoHotkey runtime exception faults. Enhanced the graphical help layout with a clean 3-column color-coded matrix representing Numpad, Arrow, and Mouse matrices.
- **FEATURES.md**: Documented the addition and implementation details of the new interactive reference panel under the configuration matrix group.
- **MANUAL.md**: Added structural information detailing the hardened dual-anchor protection algorithm, recursive `GetAncestor` controller checks, and the `g_UntuckGraceTicks` countdown period logic.
- **SPEC.md**: Updated structural spec sheets to list the unified dual-anchor physical cursor/keyboard focus logic alongside the grace latch thresholds.
- **AITASKS.md**: Checked off completed task line-items related to bumper re-arming bugs, unticking coordination shifts, and reference help display refinements.
- **AILOG.md**: Added this development log entry describing the scoping crash fix and the list of affected files.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/FEATURES.md`
- `/MANUAL.md`
- `/SPEC.md`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T19:01:00Z]
### 🎯 Primary Goals & Requirements
- Implement the missing `ShowHelpScreen` function associated with the default command trigger (`Win + /`).
- Resolve the AutoHotkey v2 compiler warning alerting that `ShowHelpScreen` is an unassigned local variable.
- Design a premium dark-themed graphic-user-interface containing all commands and keybinding matrices with a responsive filter text box.

### 🛠️ Completed Changes in this Session
- **HotWinAHK.ahk**: Implemented the Object-Oriented `ShowHelpScreen()` function. Created a lightweight, modern dark-themed GUI (`#121214`) using built-in high-performance AHK v2 GUI objects. Added a text field to filter table results instantly with non-blocking key triggers.
- **AITASKS.md & AILOG.md**: Documented completed status and resolved compile warnings.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T18:41:00Z]
### 🎯 Primary Goals & Requirements
- Correct casing of "AHk" to uppercase "AHK" globally across files, settings, and documentation.
- Maintain seamless internal path connections and includes.

### 🛠️ Completed Changes in this Session
- **File Renames**: Renamed `HotWinAHk.ahk`, `HotWinAHk_aux.ahk`, `HotWinAHk.ini`, and `HotWinAHk_tray.ahk` to `HotWinAHK.ahk`, `HotWinAHK_aux.ahk`, `HotWinAHK.ini`, and `HotWinAHK_tray.ahk` respectively.
- **HotWinAHK.ahk**: Adjusted internal global variables `g_sIniFile`, `g_sGeneratedFile`, and log paths, updated `#Include "HotWinAHK_aux.ahk"`, and standardized child shell invokes pointing to `HotWinAHK_tray.ahk`.
- **metadata.json & package.json**: Updated application identifier configurations and `displayName` values to reflect `HotWinAHK`.
- **Markdown Documentation**: Performed search-and-replace alignments inside `README.md`, `BUILD.md`, `MANUAL.md`, `SPEC.md`, `FEATURES.md`, `TESTING.md`, and `AITASKS.md`.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/HotWinAHK_aux.ahk`
- `/HotWinAHK.ini`
- `/HotWinAHK_tray.ahk`
- `/metadata.json`
- `/package.json`
- `/README.md`
- `/BUILD.md`
- `/MANUAL.md`
- `/SPEC.md`
- `/FEATURES.md`
- `/TESTING.md`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T18:38:00Z]
### 🎯 Primary Goals & Requirements
- Rename system tray delegation subprocess script to `HotWinAHK_tray.ahk` to fully align with the application `displayName` prefixing.
- Synchronize all caller invocations inside the core orchestrator script.
- Update structural diagrams, component listings, and manual instructions across features descriptions, specs, and builds.

### 🛠️ Completed Changes in this Session
- **HotWinAHK_tray.ahk**: Formatted and renamed from `TrayHelper.ahk`.
- **HotWinAHK.ahk**: Re-mapped all dynamic launcher invocations (e.g. `ComObject("Shell.Application").ShellExecute(...)`) and path trackers to target `HotWinAHK_tray.ahk`.
- **BUILD.md, FEATURES.md, SPEC.md, MANUAL.md, TESTING.md, AITASKS.md**: Updated reference documentation, build steps, executable compiler outputs, components breakdowns, and test instructions.

### 🔸 Affected Files
- `/HotWinAHK_tray.ahk`
- `/HotWinAHK.ahk`
- `/BUILD.md`
- `/MANUAL.md`
- `/FEATURES.md`
- `/SPEC.md`
- `/TESTING.md`
- `/AILOG.md`
- `/AITASKS.md`

## [2026-06-07T18:36:00Z]
### 🎯 Primary Goals & Requirements
- Rename primary logic and config files to match displayName `HotWinAHK`.
- Rename generated middle-layer Hotkeys code to match the scheme.
- Maintain consistent filenames across all manuals, build scripts, test suites, and metadata configuration files.

### 🛠️ Completed Changes in this Session
- **HotWinAHK.ahk**: Refactored from `WindowNudger.ahk`. Updated global configuration path references to use `HotWinAHK.ini` and `HotWinAHK_aux.ahk`, synchronized include directives, and updated the log writing references to `HotWinAHK.log`.
- **HotWinAHK_aux.ahk**: Refactored and renamed from `WindowHotkeys.ahk`.
- **HotWinAHK.ini**: Refactored and renamed from `WindowHotkeys.ini`.
- **metadata.json**: Aligned application name with `displayName` parameter as `HotWinAHK`.
- **BUILD.md, MANUAL.md, FEATURES.md, SPEC.md, README.md, TESTING.md**: Re-mapped all references and documentation files carefully.
- **AITASKS.md**: Documented completed status of the renaming task.

### 🔸 Affected Files
- `/HotWinAHK.ahk`
- `/HotWinAHK_aux.ahk`
- `/HotWinAHK.ini`
- `/metadata.json`
- `/BUILD.md`
- `/MANUAL.md`
- `/FEATURES.md`
- `/SPEC.md`
- `/README.md`
- `/TESTING.md`
- `/AILOG.md`
- `/AITASKS.md`

## [2026-06-07T18:28:00Z]
### 🎯 Primary Goals & Requirements
- Address compiler/linter warnings in `WindowHotkeys.ahk`.
- Resolve the `#Warn` unassigned local variable error for `ExecuteActionWithCondition`.

### 🛠️ Completed Changes in this Session
- **WindowNudger.ahk**: Moved `#Include "WindowHotkeys.ahk"` from the top of the file to the very end of the file. This ensures that the global `ExecuteActionWithCondition` function is fully parsed and populated in AutoHotkey's symbol table before the hotkey blocks calling it are evaluated.
- **AITASKS.md**: Updated the checklist to mark the unassigned variable issue as fully resolved.

### 🔸 Affected Files
- `/WindowNudger.ahk`
- `/AITASKS.md`
- `/AILOG.md`

## [2026-06-07T17:58:00Z]
### 🎯 Primary Goals & Requirements
- Reverse engineer codebases (`WindowNudger.ahk`, `TrayHelper.ahk`, etc.) in-depth.
- Structure and document CherryPucker's core mechanics and features.
- Provide clear developers manuals, user guides, specifications sheets, build commands, and testing regression sheets.

### 🛠️ Completed Changes in this Session
- **README.md**: Defined core pitch of the tool, adding primary features.
- **BUILD.md**: Outlined the dynamic compilation stream and execution/packaging guides via Ahk2Exe.
- **SPEC.md**: Parsed original user expectations alongside advanced optimization work (hooks, direct DLL calls, log cache queue, TrayHelper subprocess execution, invalid key correction layers).
- **MANUAL.md**: Formulated Euclidean velocity bump math, quadratic eased moving transitions, frame rounding alignment cells mapping, event focus monitoring, and filters.
- **FEATURES.md**: Aggregated individual actions and categories including snap layouts, fine-nudging, grid tiles, boundary marginal docks, and custom system context tray menus.
- **TESTING.md**: Developed exhaustive step-by-step diagnostic verification checklists targeting real elevation, core logs, zappings, nudgings, opacities, grids, and edge bump untucks.
- **AITASKS.md**: Completed in-depth checklist task markers.

### 🔸 Affected Files
- `/README.md`
- `/BUILD.md`
- `/SPEC.md`
- `/MANUAL.md`
- `/FEATURES.md`
- `/TESTING.md`
- `/AITASKS.md`
- `/AILOG.md`



---
## Go Back to...
- ▪️[AGENTS.md](AGENTS.md)
- 🔸[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
