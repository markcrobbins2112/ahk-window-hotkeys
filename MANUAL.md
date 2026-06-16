# Manual

This guide describes the structural architecture, module layout, internal algorithms, optimization behaviors, and technical specifications of the **HotWinAHK** codebase.
---
## Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- 🔸[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

<!--
AI to use a free form format with groups here
free to add/remove/modify these sections
-->
## 🏗️ 1. Architecture Overview
HotWinAHK operates as a low-overhead orchestrator for the Windows desktop environment using an event-driven and polling-hybrid design:
- **Central Core (`HotWinAHK.ahk`)**: Running with administrator authorization, this module loads global configuration matrices, locks the script's physical handle string sequence, initiates WinEvent hooks, and fires polling ticks for mouse collisions.
- **Dynamic Key Listener Mappings (`HotWinAHK_aux.ahk`)**: Compiled on-the-fly, this file registers relative hotkey combos with the Windows kernel, routing them to action selectors based on state filters.
- **Isolator Subprocesses (`HotWinAHK_tray.ahk`)**: Minimizes background locking by spawning lightweight individual handlers whenever windows are stowed away into custom system trays.

## 🧠 2. Core Modules & Systems
The codebase is composed of highly specialized systems that collaborate without thread blocks:
- **Hotkeys Dynamic Compiler**: Parsed using `IniRead` arrays. Identifies active sections, extracts mapping keys, maps virtual modifier sequences (Ctrl, Alt, Shift, Win), verifies standard character formats, and structures `.ahk` trigger blocks with execution safety gates.
- **Velocity Bump Tracker**: An active thread loop running on a tight 25ms interval. Evaluates physical mouse velocities and boundary positions against configured edge parameters.
- **Focus Tone Feedback listener**: Uses a Microsoft Win32 event hook callback registration (`EVENT_SYSTEM_FOREGROUND`) to detect active window changes and beep audible sound frequencies using non-blocking DLL calls.
- **Dark-Themed Tooltip Engine**: Intercepts active Windows tooltips (`ahk_class tooltips_class32`) and forces dark theme styling natively using the Windows UX Theme library (`SetWindowTheme` API).

## 🔎 3. Core Algorithm
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

## 🛰️ 4. Commands, Keybindings & Context Flags
Every action from simple moves to grid mapping is indexed inside the INI command table:
- **Modifier Bindings**: Standardized representation allows compound keys to be written easily (e.g. `Win+Ctrl+Shift+Left`).
- **Contextual Execution Filters**: Hotkey combinations can be targeted to run conditionally using key filters:
  - `wintitleis=text` / `wintitlehas=text` (checks window title matching)
  - `winclassis=text` / `winclasshas=text` (targeted to matching application classes)
  - `winexeis=text` (direct executable restriction filters)

### 📋 Categorized Action Commands Reference

#### ⚙️ SYSTEM (Orchestration & Tools)
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
- **ToggleSuspension**: Suspend or resume all HotWinAHK modifier triggers and mouse gestures instantly.
- **ReloadConfig**: Hot-reload preferences from HotWinAHK.ini and compile hotkeys dynamically.
- **EditConfig**: Open HotWinAHK.ini configurations in system default text editor.
- **ExitProgram**: Safely close physical hooks and terminate the HotWinAHK background process.
- **RestartProgram**: Instantly reload configuration parameters and reboot the active execution engine.
- **Active Window Dot**: Draws a persistent telemetry status dot at the active window's top-left margin of the target layout.

#### 🪟 WINDOW (Attributes & Trays)
- **AlwaysOnTop**: Toggle Always-On-Top focus pinning attribute on active window frame.
- **SetOpacity70**: Set alpha opacity transparency level to 70% on active window frame.
- **RemoveOpacity**: Restore active window opacity to full solid visibility.
- **SendToBack**: Push active window frame to the bottom of the active desktop stack.
- **MinimizeToTray**: Stow active window into an autonomous system-tray notification process.
- **PickFromTray**: Open stowed window tray instances via right-click contextual list.
- **DragWindow**: Shift focus to translucent DragWindow movement mode to position via directional mouse coordinates.

#### 🏠 HOME (Window Persistence)
- **SetHome**: Save active window class/process/fuzzy title signature to persistent home location.
- **ClearHome**: Delete saved home location configuration for active window.
- **GoHome**: Relocate window to its persistent home position.
- **Home**: Intelligent Home behavior (Move to home, or restore to pre-homed, or strip home config upon confirmation).
- **HomePeek**: Momentarily draw a transparent overlay footprint of the window's home location on screen.

#### 🎯 FOCUS (Z-Order Management)
- **NextWindow**: Cycle focus smoothly forward across open desktop window frames.
- **PrevWindow**: Cycle focus smoothly backward across open desktop window frames.
- **NextClassWindow**: Cycle focus specifically forward between windows of identical process class.
- **PrevClassWindow**: Cycle focus specifically backward between windows of identical process class.
- **FocusDeepestWindow**: Activate the deepest window in the Z-order list.

#### 🫥 TUCK (Docker & Auto-Hide)
- **TuckLeft**: Tuck window past left screen wall, exposing a 20px dock indicator bar.
- **TuckRight**: Tuck window past right screen wall, exposing a 20px dock indicator bar.
- **TuckUp**: Tuck window past top screen wall, exposing a 20px dock indicator bar.
- **TuckDown**: Tuck window past bottom screen wall, exposing a 20px dock indicator bar.
- **BumpEdgeUntuck**: Trigger untuck peeking when cursor reaches tucked window edge indicator.
- **BumpEdgeUntuckActivate**: Fully restore tucked window when pulled/clicked past the pop-off threshold.
- **UntuckLeft** / **UntuckRight** / **UntuckTop** / **UntuckBottom**: Untuck the window tucked at the specified edge.
- **TuckPeekLeft** / **TuckPeekRight** / **TuckPeekTop** / **TuckPeekBottom**: Reveal/peek tucked windows on the specified edge sequentially.

#### 🗺️ MOVE (Grid Matrix Positioning)
- **Center**: Move active window to center of screen without sizing changes.
- **MoveTadLeft** / **MoveTadRight** / **MoveTadUp** / **MoveTadDown**: Shift active window by 10 pixels coarse-scale (tad nudge).
- **MovepxLeft** / **MovepxRight** / **MovepxUp** / **MovepxDown**: Nudge active window with 1 pixel fine precision (px nudge).
- **EdgeLeft** / **EdgeRight** / **EdgeTop** / **EdgeBottom**: Align window to the screen's specified border.
- **EdgeTopLeft** / **EdgeTopRight** / **EdgeBottomLeft** / **EdgeBottomRight**: Align window to the screen's specified corner.
- **EdgeCenter**: Position active window to the exact horizontal and vertical center of monitor.
- **EdgeInLeft** / **EdgeInRight** / **EdgeInTop** / **EdgeInBottom** / **EdgeInTopLeft** / **EdgeInTopRight** / **EdgeInBottomLeft** / **EdgeInBottomRight**: Set/align window offset one grid cell from the specified screen edge/corner.
- **JumpGridLeft** / **JumpGridRight** / **JumpGridUp** / **JumpGridDown** / **JumpGridTopLeft** / **JumpGridTopRight** / **JumpGridBottomLeft** / **JumpGridBottomRight**: Hop window position to the specified virtual grid quartile partition.
- **MoveToGridLeft** / **MoveToGridRight** / **MoveToGridUp** / **MoveToGridDown** / **MoveToGridTopLeft** / **MoveToGridTopRight** / **MoveToGridBottomLeft** / **MoveToGridBottomRight**: Shift active window between virtual grid units/aspects.

#### 📐 SIZE (Boundary Scaling, Margins & Trimming)
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
- **Script Customization**: Changes to standard profiles are added to the `HotWinAHK.ini` table.
- **On-The-Fly Compilation**: Hotkeys automatically re-compile and reboot on save or whenever `ReloadConfig` triggers.
- **Distribution Compile Step**: Source directories can be bundled into standard Windows binaries using compiler commands (`Ahk2Exe.exe /in HotWinAHK.ahk /out HotWinAHK.exe`).


---
## Go Back to...
- [AGENTS.md](AGENTS.md)
- [AILOG.md](AILOG.md)
- [AITASKS.md](AITASKS.md)
- [BUILD.md](BUILD.md)
- [CODE.md](CODE.md)
- [FEATURES.md](FEATURES.md)
- [MANUAL.md](MANUAL.md)
- [README.md](README.md)
- [SPEC.md](SPEC.md)
- [TESTING.md](TESTING.md)

---
## Go back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- 🔸[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
