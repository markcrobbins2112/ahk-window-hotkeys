---
title: MANUAL
---

<!-- TEMPLATE: MANUAL.template.md -->
<!-- 
MANUAL
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file is the developer's handbook. It maps structural topologies, data flow,
core algorithms, algebraic formulas, configuration guidelines, and technical specifications.
-->

<!-- markdownlint-disable MD013 -->

# MANUAL
<a id="a-manual"></a>[TOC](#toc-manual)

This guide describes the structural architecture, module layout, internal algorithms, optimization behaviors, and technical specifications of the **HotWinAHK** codebase.

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔸 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!--
AI to use a free form format with groups here
free to add/remove/modify these sections
-->

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [MANUAL](#a-manual) <a id="toc-manual"></a> ^toc-manual
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [📥 Installation & Initial Deployment](#a-installationinitialdeployment) <a id="toc-installationinitialdeployment"></a> ^toc-installationinitialdeployment
    - [Setup Sequence](#a-setupsequence) <a id="toc-setupsequence"></a> ^toc-setupsequence
  - [🧠 2. Core Modules & Systems](#a-2coremodulessystems) <a id="toc-2coremodulessystems"></a> ^toc-2coremodulessystems
  - [🔎 3. Core Algorithm](#a-3corealgorithm) <a id="toc-3corealgorithm"></a> ^toc-3corealgorithm
  - [🛰️ 4. Commands, Keybindings & Context Flags](#a-4commandskeybindingscontextflags) <a id="toc-4commandskeybindingscontextflags"></a> ^toc-4commandskeybindingscontextflags
    - [📋 Categorized Action Commands Reference](#a-categorizedactioncommandsreference) <a id="toc-categorizedactioncommandsreference"></a> ^toc-categorizedactioncommandsreference
      - [⚙️ SYSTEM (Orchestration & Tools)](#a-systemorchestrationtools) <a id="toc-systemorchestrationtools"></a> ^toc-systemorchestrationtools
      - [🪟 WINDOW (Attributes, Trays & Bulk)](#a-windowattributestraysbulk) <a id="toc-windowattributestraysbulk"></a> ^toc-windowattributestraysbulk
      - [🏠 HOME (Window Persistence)](#a-homewindowpersistence) <a id="toc-homewindowpersistence"></a> ^toc-homewindowpersistence
      - [🎯 FOCUS (Z-Order, History & Swaps)](#a-focuszorderhistoryswaps) <a id="toc-focuszorderhistoryswaps"></a> ^toc-focuszorderhistoryswaps
      - [🫥 TUCK (Docker & Auto-Hide)](#a-tuckdockerautohide) <a id="toc-tuckdockerautohide"></a> ^toc-tuckdockerautohide
      - [🗺️ MOVE (Grid Matrix Positioning)](#a-movegridmatrixpositioning) <a id="toc-movegridmatrixpositioning"></a> ^toc-movegridmatrixpositioning
      - [📐 SIZE (Boundary Scaling, Margins & Trimming)](#a-sizeboundaryscalingmarginstrimming) <a id="toc-sizeboundaryscalingmarginstrimming"></a> ^toc-sizeboundaryscalingmarginstrimming
  - [🔧 5. Workspace Build & Configuration](#a-5workspacebuildconfiguration) <a id="toc-5workspacebuildconfiguration"></a> ^toc-5workspacebuildconfiguration
  - [🔍 Diagnostics & Common Troubleshooting](#a-diagnosticscommontroubleshooting) <a id="toc-diagnosticscommontroubleshooting"></a> ^toc-diagnosticscommontroubleshooting
    - [Known Failure States & Remediations](#a-knownfailurestatesremediations) <a id="toc-knownfailurestatesremediations"></a> ^toc-knownfailurestatesremediations
      - [🚨 Symptom: "HotWinAHK requiring Administrative Privileges"](#a-symptomhotwinahkrequiringadministrativeprivileges) <a id="toc-symptomhotwinahkrequiringadministrativeprivileges"></a> ^toc-symptomhotwinahkrequiringadministrativeprivileges
      - [🚨 Symptom: Changes apply to [HotWinAHK.ini](../HotWinAHK.ini), but hotkeys do not update.](#a-symptomchangesapplytohotwinahkinihotwinahkinibuthotkeysdonotupdate) <a id="toc-symptomchangesapplytohotwinahkinihotwinahkinibuthotkeysdonotupdate"></a> ^toc-symptomchangesapplytohotwinahkinihotwinahkinibuthotkeysdonotupdate
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 📥 Installation & Initial Deployment
<a id="a-installationinitialdeployment"></a>[TOC](#toc-installationinitialdeployment)
### Setup Sequence
<a id="a-setupsequence"></a>[TOC](#toc-setupsequence)
- 1. **Compile/Build Assets:** Run the compile script or build pipeline as documented in [`BUILD.md`](BUILD.md).
- 2. **Apply Configurations:** Run administrative scripts or system configurations required for the base application environment.
- 3. **Register Components:** Execute target registry configurations or system file bindings to link the software with the host operating system.

---

<!-- 
  INSTRUCTION: Outline the structural relationship of files and modules.
  Include raw ASCII boxes or diagrams to make the architecture immediately obvious.
-->
HotWinAHK operates as a low-overhead orchestrator for the Windows desktop environment using an event-driven and polling-hybrid design:
- **Central Core ([`HotWinAHK.ahk`](../HotWinAHK.ahk))**: Running with administrator authorization, this module loads global configuration matrices, locks the script's physical handle string sequence, initiates WinEvent hooks, and fires polling ticks for mouse collisions.
- **Dynamic Key Listener Mappings ([`HotWinAHK_aux.ahk`](../HotWinAHK_aux.ahk))**: Compiled on-the-fly, this file registers relative hotkey combos with the Windows kernel, routing them to action selectors based on state filters.
- **Isolator Subprocesses ([`HotWinAHK_tray.ahk`](../HotWinAHK_tray.ahk))**: Minimizes background locking by spawning lightweight individual handlers whenever windows are stowed away into custom system trays.

---

<!-- 
  INSTRUCTION: Document individual subsystems, class constructors, interfaces, 
  and persistent background loops that govern state transitions.
-->
## 🧠 2. Core Modules & Systems
<a id="a-2coremodulessystems"></a>[TOC](#toc-2coremodulessystems)
The codebase is composed of highly specialized systems that collaborate without thread blocks:
- **Hotkeys Dynamic Compiler**: Parsed using `IniRead` arrays. Identifies active sections, extracts mapping keys, maps virtual modifier sequences (Ctrl, Alt, Shift, Win), verifies standard character formats, and structures `.ahk` trigger blocks with execution safety gates. Automatically registers matching counterparts for Numpad hotkeys (such as mapping standard layout keys with their non-lock navigation equivalents) during compilation so bindings work flawlessly under any keyboard state.
- **Velocity Bump Tracker**: An active thread loop running on a tight 25ms interval. Evaluates physical mouse velocities and boundary positions against configured edge parameters.
- **Focus Tone Feedback listener**: Uses a Microsoft Win32 event hook callback registration (`EVENT_SYSTEM_FOREGROUND`) to detect active window changes and beep audible sound frequencies using non-blocking DLL calls.
- **Dark-Themed Tooltip Engine**: Intercepts active Windows tooltips (`ahk_class tooltips_class32`) and forces dark theme styling natively using the Windows UX Theme library (`SetWindowTheme` API).

## 🔎 3. Core Algorithm
<a id="a-3corealgorithm"></a>[TOC](#toc-3corealgorithm)
The application's crown jewel is its mathematical screen-edge docking and mouse-bumping algorithm:
- **Euclidean Vector Speed Calculation**: On every 25ms cycle, it measures the vector travel distance of the mouse:
  $$\text{pixelDistance} = \sqrt{\Delta X^2 + \Delta Y^2}$$
  If the cursor enters an edge zone (`g_BumpEdgeZonePixels`) and the speed matches of exceeds `g_BumpVelocityThreshold` in the towards-screen boundary direction, an Edge Bump occurs.
- **Adaptive Snapping Alignment**: Aspect tile positions are derived using mathematical rounding maps:
  $$\text{cellIndex} = \text{Round}\left(\frac{\text{Coordinate} - \text{Padding}}{\text{TileDimension} + \text{Margin}}\right)$$
  This aligns window corners cleanly to standard columns and rows without overlapping borders.
- **Quadratic Easing Motion Animation**: Smoothes window snaps using quadratic ease-out interpolation over a 150ms segment containing 12 linear intermediate frames:
  $$\text{easeProgress} = t \times (2 - t)$$
- **Hardened Dual-Anchor Protection & Countdown Latch**: When a stowed window is peek-revealed, a 50ms polling thread (`TrackUntuckedFocusLifecycle`) checks both focus state and mouse positioning. To prevent erratic retucking during transition phases, the system activates a countdown latch of `g_UntuckGraceTicks := 10` (500ms). The window is locked open while:
  1. The cursor is placed within the window boundary or its active native child controls (retrieved recursively via Win32 `GetAncestor` calls).
  2. The window remains the active Windows foreground window element.
  Definitive state switches (moving cursor away AND activating a separate typing window) trigger clean, interpolated sliding back to edge margins.
  While dragging or clicking a tuck-revealed window, the polling thread is immediately unregistered and an atomic thread lock (`g_IsUntuckLocked := true`) is acquired to prevent cross-thread race conditions or deadlocks with native OS title-bar moving routines. State is restored atomically upon action completion.
- **Damped Drag Resistance Curve**: Left-click dragging a peek-untucked window away from its docked screen margin is restricted using non-linear resistance. Standard mouse coordinates map to window coordinates using a steep 4x damping reduction multiplier:
  $$\text{resistedDeltaX} = \Delta X \times 0.25$$
  Parallel dragging coordinates are restricted with a 2x damping parameter ($0.5$).
- **Hysteresis Pop-off Threshold**: If the resisted drag direction displacement exceeds 120 absolute screen pixels ($\text{pullDistance} > 120\text{px}$), the docking structural anchor snaps. The window is removed from the stowed registry maps, plays an audio pitch, and is restored as a free-floating window.
- **Ctrl-Hold Dock-Seeking Indicator Overlay**: Holding the `Ctrl` key during a stowed window drag disables physical resistance and enters a Dock-Seeking Mode. The engine calculates the closest screen margin of the mouse's active monitor layout, instantiates a click-through translucent cyan GUI indicator overlay bar (60px thickness) aligned to that edge, and immediately snaps and docks the stowed window to the selected monitor margin upon left-clicked mouse release.
- **Overlapping Z-Order Translucency Scanner**: Engages upon DragWindow execution to query the native window stack recursively. Discovers all visible frames resting above the target drag handles and lowers their transparency level to a soft `50` alpha weight while holding the target moving object at `200` transparency. On release, the cached original opacities of all elevated windows are instantly written back.
- **Desk3D Proportional Parallax Workspace**: Maps active open desktop frames to integer depth layers. Active windows fade to 153 layout opacity (40% transparent). On mouse coordinate changes, it registers the displacement vector from starting center points ($\Delta X_{\text{mouse}}, \Delta Y_{\text{mouse}}$), shifting coords according to reciprocal depth step functions baseline-magnified by 1.75x, and further modified by mechanical state values (3.0x scaling coefficient if holding Ctrl down, and 0x lock-stop if holding Shift down):
  $$\text{shiftX} = -\Delta X_{\text{mouse}} \times \max\left(0.05, 1.2 - (\text{layerIndex} - 1) \times 0.15\right) \times 1.75 \times \text{magFactor}$$
  $$\text{shiftY} = -\Delta Y_{\text{mouse}} \times \max\left(0.05, 1.2 - (\text{layerIndex} - 1) \times 0.15\right) \times 1.75 \times \text{magFactor}$$
  This creates a beautiful 3D workspace where foreground windows glide realistically over background windows, completely resettable with Escape.
- **Durable State History (Undo/Redo)**: Records window positions, sizes, min/max status, titles, processes, and timestamp markers to file sections inside `HotWinAHK_history.ini` per application before `SafeMove()` layout updates run. Facilitates instant layout Undo/Redo commands traversing the undo stack, or selective target restorations of up to 20 past configurations per process via a pop-up context-picker.
- **Active Window Swapping Mechanics**: Performs physical interchange swaps (`Swap`, `SwapSize`, `SwapPosition`) of position and/or size dimensions of the active foreground window container with whichever window frame rests directly below the mouse cursor by utilizing low-level DLL/Win32 APIs. Engages a continuous cursor tracking state machine for hands-free pick-swapping (`SwapPick`, `SwapPickSize`, `SwapPickPosition`) where a user clicks any window to trigger the swap.
- **Columns-Then-Rows Gridify Nesting Menus**: Launches nested AHK-native Popup Menus displaying a grid matrix up to 9x9. Slices the active monitor dimensions symmetrically, centering, wrapping, and aligning the active window exactly into selected column and row slots.
- **Recursive Nested Region-Based INI Compiler**: Upgrades the automatic `.ini` matrix compilation engine to format [`HotWinAHK.ini`](../HotWinAHK.ini) recursively inside folding blocks of regions using standard IDE syntax (`;   #region <Category>`, `; #endregion <Category>`). It extracts active settings from the old matrix, creates backup points, translates keyboard modifier chains, and writes default templates for missing keys without corrupting custom user-configured keybindings.

## 🛰️ 4. Commands, Keybindings & Context Flags
<a id="a-4commandskeybindingscontextflags"></a>[TOC](#toc-4commandskeybindingscontextflags)
Every action from simple moves to grid mapping is indexed inside the INI command table:
- **Modifier Bindings**: Standardized representation allows compound keys to be written easily (e.g. `Win+Ctrl+Shift+Left`).
- **Contextual Execution Filters**: Hotkey combinations can be targeted to run conditionally using key filters:
  - `wintitleis=text` / `wintitlehas=text` (checks window title matching)
  - `winclassis=text` / `winclasshas=text` (targeted to matching application classes)
  - `winexeis=text` (direct executable restriction filters)

### 📋 Categorized Action Commands Reference
<a id="a-categorizedactioncommandsreference"></a>[TOC](#toc-categorizedactioncommandsreference)

#### ⚙️ SYSTEM (Orchestration & Tools)
<a id="a-systemorchestrationtools"></a>[TOC](#toc-systemorchestrationtools)
- **HelpScreen**: Display the interactive keyboard command reference panel containing on-screen documentation.
- **CmdPalette**: Display the interactive fuzzy-search Command Palette for manual trigger / dry-run testing.
- **WinInfo**: Display active window physical bounds, handle ID, class name, and executable system path.
- **PeekUnderMouse**: Show context of window beneath mouse cursor coordinates.
- **CopyCommands**: Copy all available action commands sorted by category to the system clipboard.
- **CopyCommandsAlpha**: Copy all available action commands sorted alphabetically to the system clipboard.
- **CopyBindings**: Copy all active hotkeys keybindings dictionary map to the system clipboard.
- **CopyCommandsHelp**: Copy this fully categorized action commands reference with descriptions to the system clipboard.
- **CopyBindingsAlpha**: Copy active keybindings map sorted alphabetically by command name to the system clipboard.
- **CopyBindingsLocation**: Copy active keybindings map grouped by keyboard hardware location to the system clipboard.
- **SysMenu**: Display a popup context menu of all system commands to quickly select and run.
- **KeyDiagnostics**: Run an interactive testing loop to verify that modifiers and special keys (numpads, arrows) are accurately heard by the engine's physical keyboard hook, copying failed entries to clipboard.
- **KeyQuery**: Display an interactive dark dialog with a timer to capture raw keyboard strokes and identify active command bindings in real-time until ESC is pressed.
- **Settings**: Open a GUI configurations dialog allowing user customization of toggle settings: Silence All sounds (default: false), Silent on Window Commands (default: false), and Tip Windows Commands (default: true).
- **ToggleSuspension**: Suspend or resume all HotWinAHK modifier triggers and mouse gestures instantly.
- **ReloadConfig**: Hot-reload preferences from [HotWinAHK.ini](../HotWinAHK.ini) and compile hotkeys dynamically.
- **EditConfig**: Open [HotWinAHK.ini](../HotWinAHK.ini) configurations in system default text editor.
- **ExitProgram**: Safely close physical hooks and terminate the HotWinAHK background process.
- **RestartProgram**: Instantly reload configuration parameters and reboot the active execution engine.
- **Active Window Dot**: Draws a persistent telemetry status dot at the active window's top-left margin of the target layout.

#### 🪟 WINDOW (Attributes, Trays & Bulk)
<a id="a-windowattributestraysbulk"></a>[TOC](#toc-windowattributestraysbulk)
- **AlwaysOnTop**: Toggle Always-On-Top focus pinning attribute on active window frame.
- **SetOpacity70**: Set alpha opacity transparency level to 70% on active window frame.
- **RemoveOpacity**: Restore active window opacity to full solid visibility.
- **SendToBack**: Push active window frame to the bottom of the active desktop stack.
- **MinimizeToTray**: Stow active window into an autonomous system-tray notification process.
- **PickFromTray**: Open stowed window tray instances via right-click contextual list.
- **DragWindow**: Shift focus to translucent DragWindow movement mode to position via directional mouse coordinates.
- **RestoreAllMaximized**: Restore all maximized windows to normal restored states.
- **MaximizeAllRestored**: Maximize all currently restored windows.
- **MaximizeAllMinimized**: Maximize all currently minimized windows.
- **SwapMaximizedRestored**: Swap states between maximized and restored windows.
- **SwapMinimizedRestored**: Swap states between minimized and restored windows.
- **MinimizeAll**: Minimize all active application frames.
- **MinimizeAllRestored**: Minimize all currently restored windows.
- **MinimizeAllMaximized**: Minimize all currently maximized windows.

#### 🏠 HOME (Window Persistence)
<a id="a-homewindowpersistence"></a>[TOC](#toc-homewindowpersistence)
- **SetHome**: Save active window class/process/fuzzy title signature to persistent home location.
- **ClearHome**: Delete saved home location configuration for active window.
- **GoHome**: Relocate window to its persistent home position.
- **Home**: Intelligent Home behavior (Move to home, or restore to pre-homed, or strip home config upon confirmation).
- **HomePeek**: Momentarily draw a transparent overlay footprint of the window's home location on screen.

#### 🎯 FOCUS (Z-Order, History & Swaps)
<a id="a-focuszorderhistoryswaps"></a>[TOC](#toc-focuszorderhistoryswaps)
- **NextWindow**: Cycle focus smoothly forward across open desktop window frames.
- **PrevWindow**: Cycle focus smoothly backward across open desktop window frames.
- **NextClassWindow**: Cycle focus specifically forward between windows of identical process class path.
- **PrevClassWindow**: Cycle focus specifically backward between windows of identical process class path.
- **FocusDeepestWindow**: Activate the deepest window in the Z-order list.
- **WindowPicker**: Launch the interactive Window Selection GUI supporting fuzzy filter search by title or executable file name using styled vertical list buttons.
- **Desk3d**: Enter the mathematical 3D parallax workspace mode, rotating window layouts symmetrically using layered distance weights.
- **WindowHistoryPrev**: Restore the previous layout configuration in history.
- **WindowHistoryNext**: Restore the next layout configuration in history.
- **WindowHistoryPick**: Display a dark context-rich pop-up history menu holding up to 20 past alignments of the active process.
- **Swap**: Swap the active window's position and dimensions with the window underneath the mouse pointer.
- **SwapSize**: Swap the active window's size with the window underneath the mouse pointer.
- **SwapPosition**: Swap the active window's position coordinates with the window underneath the mouse pointer.
- **SwapPick**: Enter dual-stage pick mode to select a target window by hover-clicking to swap both coordinates and dimensions.
- **SwapPickSize**: Enter dual-stage pick mode to swap dimensions with a selected window.
- **SwapPickPosition**: Enter dual-stage pick mode to swap position coordinates with a selected window.
- **Gridify**: Opens a rapid Columns-Then-Rows nested layout placement menu mapping cells up to 9x9.

#### 🫥 TUCK (Docker & Auto-Hide)
<a id="a-tuckdockerautohide"></a>[TOC](#toc-tuckdockerautohide)
- **TuckLeft**: Tuck window past left screen wall, exposing a 20px dock indicator bar.
- **TuckRight**: Tuck window past right screen wall, exposing a 20px dock indicator bar.
- **TuckUp**: Tuck window past top screen wall, exposing a 20px dock indicator bar.
- **TuckDown**: Tuck window past bottom screen wall, exposing a 20px dock indicator bar.
- **BumpEdgeUntuck**: Trigger untuck peeking when cursor reaches tucked window edge indicator.
- **BumpEdgeUntuckActivate**: Fully restore tucked window when pulled/clicked past the pop-off threshold.
- **PeekTucked**: Present interactive pop-up list of stowed handles to temporarily peek.
- **Untuck**: Present interactive pop-up list of stowed handles to permanently restore.
- **UntuckLeft** / **UntuckRight** / **UntuckTop** / **UntuckBottom**: Untuck the window tucked at the specified edge.
- **TuckPeekLeft** / **TuckPeekRight** / **TuckPeekTop** / **TuckPeekBottom**: Reveal/peek tucked windows on the specified edge sequentially.
- **TuckedPeekAll** / **TuckedPeekLeft** / **TuckedPeekRight** / **TuckedPeekTop** / **TuckedPeekBottom**: Spawns edge-filtered interactive pop-up lists of stowed handles displaying full Hexadecimal HWND identifiers.

#### 🗺️ MOVE (Grid Matrix Positioning)
<a id="a-movegridmatrixpositioning"></a>[TOC](#toc-movegridmatrixpositioning)
- **Center**: Move active window to center of screen without sizing changes.
- **MoveTadLeft** / **MoveTadRight** / **MoveTadUp** / **MoveTadDown**: Shift active window by 1/4 of a cell width/height (106px horizontally, 58px vertically) coarse-scale (tad nudge).
- **MovepxLeft** / **MovepxRight** / **MovepxUp** / **MovepxDown**: Nudge active window with fine precision (10px horizontally, 5px vertically) (px nudge).
- **EdgeLeft** / **EdgeRight** / **EdgeTop** / **EdgeBottom**: Align window to the screen's specified border.
- **EdgeTopLeft** / **EdgeTopRight** / **EdgeBottomLeft** / **EdgeBottomRight**: Align window to the screen's specified corner.
- **EdgeCenter**: Position active window to the exact horizontal and vertical center of monitor.
- **EdgeInLeft** / **EdgeInRight** / **EdgeInTop** / **EdgeInBottom** / **EdgeInTopLeft** / **EdgeInTopRight** / **EdgeInBottomLeft** / **EdgeInBottomRight**: Set/align window offset one grid cell from the specified screen edge/corner.
- **JumpGridLeft** / **JumpGridRight** / **JumpGridUp** / **JumpGridDown** / **JumpGridTopLeft** / **JumpGridTopRight** / **JumpGridBottomLeft** / **JumpGridBottomRight**: Hop window position to the specified virtual grid quartile partition.
- **MoveToGridLeft** / **MoveToGridRight** / **MoveToGridUp** / **MoveToGridDown** / **MoveToGridTopLeft** / **MoveToGridTopRight** / **MoveToGridBottomLeft** / **MoveToGridBottomRight**: Shift active window between virtual grid units/aspects.

#### 📐 SIZE (Boundary Scaling, Margins & Trimming)
<a id="a-sizeboundaryscalingmarginstrimming"></a>[TOC](#toc-sizeboundaryscalingmarginstrimming)
- **MouseToGrid**: Warp window beneath mouse cursor directly to closest grid block.
- **MouseRelativeSize**: Resize window dynamically relative to cursor movement boundary vectors.
- **SnapToGridEnlarge**: Grow active window boundaries to span next adjacent grid aspect cell.
- **SnapToGridShrink**: Contract active window grid spanning aspect cell size.
- **ScaleExpand10px** / **ScaleReduce10px**: Expand / shrink active window bounds by 10px symmetrically in all directions.
- **ScaleExpandGridPart** / **ScaleReduceGridPart**: Expand / shrink active window bounds symmetrically matching half-grid step parts.
- **TrimTop** / **TrimBottom** / **TrimLeft** / **TrimRight** / **TrimAll** / **TrimTopLeft** / **TrimTopRight** / **TrimBottomLeft** / **TrimBottomRight**: Trim specified boundary/boundaries from active window margin(s).
- **AddTop** / **AddBottom** / **AddLeft** / **AddRight** / **AddTopLeft** / **AddTopRight** / **AddBottomLeft** / **AddBottomRight**: Grow specified boundary/boundaries outward to nearest grid margin(s) or midpoint grid cell.
- **GrowLeft** / **GrowRight** / **GrowTop** / **GrowBottom** / **GrowAll** / **GrowTopLeft** / **GrowTopRight** / **GrowBottomLeft** / **GrowBottomRight**: Symmetrically grow specified boundary/boundaries outward by step width.
- **SubtractTop** / **SubtractBottom** / **SubtractLeft** / **SubtractRight** / **SubtractTopLeft** / **SubtractTopRight** / **SubtractBottomLeft** / **SubtractBottomRight**: Contract specified boundary/boundaries inward to nearest grid/midpoint cell or toward center.
- **HalfSizeLeft** / **HalfSizeRight** / **HalfSizeTop** / **HalfSizeBottom**: Halve window width/height from specified side.
- **DoubleSizeLeft** / **DoubleSizeRight** / **DoubleSizeTop** / **DoubleSizeBottom**: Double window width/height from specified side.
- **StretchToGridLeft** / **StretchToGridRight** / **StretchToGridUp** / **StretchToGridDown** / **StretchToGridTopLeft** / **StretchToGridTopRight** / **StretchToGridBottomLeft** / **StretchToGridBottomRight**: Stretch target boundary/boundaries to nearest grid edge/corner.
- **PullToGridLeft** / **PullToGridRight** / **PullToGridUp** / **PullToGridDown** / **PullToGridTopLeft** / **PullToGridTopRight** / **PullToGridBottomLeft** / **PullToGridBottomRight**: Pull target boundary/boundaries inward to nearest grid edge/corner.
- **StretchLeft** / **StretchRight** / **StretchTop** / **StretchBottom** / **StretchTopLeft** / **StretchTopRight** / **StretchBottomLeft** / **StretchBottomRight**: Extend target boundary/boundaries to touch screen margins.


## 🔧 5. Workspace Build & Configuration
<a id="a-5workspacebuildconfiguration"></a>[TOC](#toc-5workspacebuildconfiguration)
- **Script Customization**: Changes to standard profiles are added to the [`HotWinAHK.ini`](../HotWinAHK.ini) table.
- **On-The-Fly Compilation**: Hotkeys automatically re-compile and reboot on save or whenever `ReloadConfig` triggers.
- **Distribution Compile Step**: Source directories can be bundled into standard Windows binaries using compiler commands (`Ahk2Exe.exe /in [HotWinAHK.ahk](../HotWinAHK.ahk) /out HotWinAHK.exe`).


---

## 🔍 Diagnostics & Common Troubleshooting
<a id="a-diagnosticscommontroubleshooting"></a>[TOC](#toc-diagnosticscommontroubleshooting)
### Known Failure States & Remediations
<a id="a-knownfailurestatesremediations"></a>[TOC](#toc-knownfailurestatesremediations)

#### 🚨 Symptom: "HotWinAHK requiring Administrative Privileges"
<a id="a-symptomhotwinahkrequiringadministrativeprivileges"></a>[TOC](#toc-symptomhotwinahkrequiringadministrativeprivileges)
- **Root Cause:** Certain target elevated applications (such as Task Manager or Administrative Command Prompts) block un-elevated Win32 API window messages.
- **Remediation:** Relaunch [`HotWinAHK.ahk`](../HotWinAHK.ahk) using administrative rights (`RunAs Administrator`), which is triggered automatically by the script's self-elevation check at startup.

#### 🚨 Symptom: Changes apply to [HotWinAHK.ini](../HotWinAHK.ini), but hotkeys do not update.
<a id="a-symptomchangesapplytohotwinahkinihotwinahkinibuthotkeysdonotupdate"></a>[TOC](#toc-symptomchangesapplytohotwinahkinihotwinahkinibuthotkeysdonotupdate)
- **Root Cause:** The dynamic hotkey generator has not compiled the new INI definitions into [`HotWinAHK_aux.ahk`](../HotWinAHK_aux.ahk).
- **Remediation:** Trigger hot-reload via `Win+Ctrl+F5` (`ReloadConfig`), or choose "Reload Config" from the system tray menu.

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔸 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: MANUAL.template.md -->
