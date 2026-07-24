---
title: FEATURES
---

<!-- TEMPLATE: FEATURES.template.md -->
<!-- 
FEATURES
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file structures user-facing capabilities and functional features.
Group related software parts into "Feature Groups" (with tags and anchors),
then list them alphabetically under "All Features".
-->

<!-- markdownlint-disable MD013 -->

# FEATURES
<a id="a-features"></a>[TOC](#toc-features)
Welcome to HotWinAHK! A fast, keyboard-driven window alignment and docking assistant for Windows. Here is a breakdown of its features:

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔸 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)


<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [FEATURES](#a-features) <a id="toc-features"></a> ^toc-features
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [📦 Feature Groups](#a-featuregroups) <a id="toc-featuregroups"></a> ^toc-featuregroups
    - [🛠️ 1. Administrative Controls & Dynamic Compiler](#a-1administrativecontrolsdynamiccompiler) <a id="toc-1administrativecontrolsdynamiccompiler"></a> ^toc-1administrativecontrolsdynamiccompiler
    - [🎛️ 2. Screen Snapping & Monitor Positioning Matrix](#a-2screensnappingmonitorpositioningmatrix) <a id="toc-2screensnappingmonitorpositioningmatrix"></a> ^toc-2screensnappingmonitorpositioningmatrix
    - [📐 3. Proportional Grid Tiles & Sizing Utilities](#a-3proportionalgridtilessizingutilities) <a id="toc-3proportionalgridtilessizingutilities"></a> ^toc-3proportionalgridtilessizingutilities
    - [🚀 4. Boundary Docking & Mouse Fling Untuck](#a-4boundarydockingmouseflinguntuck) <a id="toc-4boundarydockingmouseflinguntuck"></a> ^toc-4boundarydockingmouseflinguntuck
    - [📂 5. Dedicated Subprocess Shell Minification](#a-5dedicatedsubprocessshellminification) <a id="toc-5dedicatedsubprocessshellminification"></a> ^toc-5dedicatedsubprocessshellminification
  - [🗄️ All Features](#a-allfeatures) <a id="toc-allfeatures"></a> ^toc-allfeatures
    - [Absolute Monitor Border Snapping](#a-absolutemonitorbordersnapping) <a id="toc-absolutemonitorbordersnapping"></a> ^toc-absolutemonitorbordersnapping
    - [Active Untuck Focus Lock](#a-activeuntuckfocuslock) <a id="toc-activeuntuckfocuslock"></a> ^toc-activeuntuckfocuslock
    - [Configuration Matrix Compiler](#a-configurationmatrixcompiler) <a id="toc-configurationmatrixcompiler"></a> ^toc-configurationmatrixcompiler
    - [Grid Alignment Enlarge & Shrink](#a-gridalignmentenlargeshrink) <a id="toc-gridalignmentenlargeshrink"></a> ^toc-gridalignmentenlargeshrink
    - [Inline Program Recalibration](#a-inlineprogramrecalibration) <a id="toc-inlineprogramrecalibration"></a> ^toc-inlineprogramrecalibration
    - [Interactive Commands Reference Panel](#a-interactivecommandsreferencepanel) <a id="toc-interactivecommandsreferencepanel"></a> ^toc-interactivecommandsreferencepanel
    - [Live Hotkey Suspension](#a-livehotkeysuspension) <a id="toc-livehotkeysuspension"></a> ^toc-livehotkeysuspension
    - [Pixel-Precision Fine-Nudging](#a-pixelprecisionfinenudging) <a id="toc-pixelprecisionfinenudging"></a> ^toc-pixelprecisionfinenudging
    - [Proportional Multi-Monitor Spanning](#a-proportionalmultimonitorspanning) <a id="toc-proportionalmultimonitorspanning"></a> ^toc-proportionalmultimonitorspanning
    - [Relative Mouse Drag Positioning](#a-relativemousedragpositioning) <a id="toc-relativemousedragpositioning"></a> ^toc-relativemousedragpositioning
    - [Right-Click Shell Menu Delegates](#a-rightclickshellmenudelegates) <a id="toc-rightclickshellmenudelegates"></a> ^toc-rightclickshellmenudelegates
    - [Selective Subprocess Minimizing](#a-selectivesubprocessminimizing) <a id="toc-selectivesubprocessminimizing"></a> ^toc-selectivesubprocessminimizing
    - [Symmetrical Frame-Padding Trims](#a-symmetricalframepaddingtrims) <a id="toc-symmetricalframepaddingtrims"></a> ^toc-symmetricalframepaddingtrims
    - [Autonomous External Window Commander (Au3)](#a-autonomousexternalwindowcommanderau3) <a id="toc-autonomousexternalwindowcommanderau3"></a> ^toc-autonomousexternalwindowcommanderau3
    - [Persistent Window Home Coordinates Matrix](#a-persistentwindowhomecoordinatesmatrix) <a id="toc-persistentwindowhomecoordinatesmatrix"></a> ^toc-persistentwindowhomecoordinatesmatrix
    - [Tac-Edge Margin Docking](#a-tacedgemargindocking) <a id="toc-tacedgemargindocking"></a> ^toc-tacedgemargindocking
    - [Tray Helper App Solitary Execution](#a-trayhelperappsolitaryexecution) <a id="toc-trayhelperappsolitaryexecution"></a> ^toc-trayhelperappsolitaryexecution
    - [Velocity Bump Restorations](#a-velocitybumprestorations) <a id="toc-velocitybumprestorations"></a> ^toc-velocitybumprestorations
    - [Stowed Window Drag & Seek Controller](#a-stowedwindowdragseekcontroller) <a id="toc-stowedwindowdragseekcontroller"></a> ^toc-stowedwindowdragseekcontroller
    - [Welcome Tone focus Beeper](#a-welcometonefocusbeeper) <a id="toc-welcometonefocusbeeper"></a> ^toc-welcometonefocusbeeper
    - [Dark Center Screen Overlay](#a-darkcenterscreenoverlay) <a id="toc-darkcenterscreenoverlay"></a> ^toc-darkcenterscreenoverlay
    - [NumLock-Agnostic Dual Numpad Hotkey Compilation](#a-numlockagnosticdualnumpadhotkeycompilation) <a id="toc-numlockagnosticdualnumpadhotkeycompilation"></a> ^toc-numlockagnosticdualnumpadhotkeycompilation
    - [Layered Drag Translucency Scanning](#a-layereddragtranslucencyscanning) <a id="toc-layereddragtranslucencyscanning"></a> ^toc-layereddragtranslucencyscanning
    - [Parameterized Tucked Peeking/Filtering Menus](#a-parameterizedtuckedpeekingfilteringmenus) <a id="toc-parameterizedtuckedpeekingfilteringmenus"></a> ^toc-parameterizedtuckedpeekingfilteringmenus
    - [Fuzzy-Searchable GUI Window Picker](#a-fuzzysearchableguiwindowpicker) <a id="toc-fuzzysearchableguiwindowpicker"></a> ^toc-fuzzysearchableguiwindowpicker
    - [Immersive 3D Parallax Rotation Mode (Desk3D)](#a-immersive3dparallaxrotationmodedesk3d) <a id="toc-immersive3dparallaxrotationmodedesk3d"></a> ^toc-immersive3dparallaxrotationmodedesk3d
    - [Durable Window Position & State History (Undo/Redo)](#a-durablewindowpositionstatehistoryundoredo) <a id="toc-durablewindowpositionstatehistoryundoredo"></a> ^toc-durablewindowpositionstatehistoryundoredo
    - [Interactive Window Swapping & Hover-Targeting](#a-interactivewindowswappinghovertargeting) <a id="toc-interactivewindowswappinghovertargeting"></a> ^toc-interactivewindowswappinghovertargeting
    - [Columns-Then-Rows Gridify Nesting Menus](#a-columnsthenrowsgridifynestingmenus) <a id="toc-columnsthenrowsgridifynestingmenus"></a> ^toc-columnsthenrowsgridifynestingmenus
    - [Nested Region-Based Configuration Matrix Hierarchy](#a-nestedregionbasedconfigurationmatrixhierarchy) <a id="toc-nestedregionbasedconfigurationmatrixhierarchy"></a> ^toc-nestedregionbasedconfigurationmatrixhierarchy
  - [📉 Deprecated / Removed Features](#a-deprecatedremovedfeatures) <a id="toc-deprecatedremovedfeatures"></a> ^toc-deprecatedremovedfeatures
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 📦 Feature Groups
<a id="a-featuregroups"></a>[TOC](#toc-featuregroups)
### 🛠️ 1. Administrative Controls & Dynamic Compiler
<a id="a-1administrativecontrolsdynamiccompiler"></a>[TOC](#toc-1administrativecontrolsdynamiccompiler)
<a id="z1" name="z.1"></a>
This component controls core engine reload, hotkey customization, logs, and process states.
- **[Configuration Matrix Compiler](#configuration-matrix-compiler)** - Reads active hotkey bindings from INI and compiles them to native AHK definitions.
- **[Interactive Commands Reference Panel](#interactive-commands-reference-panel)** - Provides a gorgeous, color-coded, searchable 3-column desktop guide (`Win + /`) containing all active matrix keybindings for instant lookup.
- **[Live Hotkey Suspension](#live-hotkey-suspension)** - Toggle entire macro listener functionality with a master hotkey combination to prevent shortcut collisions.
- **[Inline Program Recalibration](#inline-program-recalibration)** - Instantly edits, saves, and hot-swaps active keybindings without restarting the main script thread.

### 🎛️ 2. Screen Snapping & Monitor Positioning Matrix
<a id="a-2screensnappingmonitorpositioningmatrix"></a>[TOC](#toc-2screensnappingmonitorpositioningmatrix)
<a id="z2" name="z.2"></a>
Align active application frames directly against physical monitor workspace margins.
- **[Absolute Monitor Border Snapping](#absolute-monitor-border-snapping)** - Warp window corners straight onto screen edges including corners, bottom, and center.
- **[Pixel-Precision Fine-Nudging](#pixel-precision-fine-nudging)** - Shift positions by exact horizontal and vertical precision step coordinates.
- **[Proportional Multi-Monitor Spanning](#proportional-multi-monitor-spanning)** - Detect monitor coordinates under target windows and expand layouts across monitor boundaries safely.

### 📐 3. Proportional Grid Tiles & Sizing Utilities
<a id="a-3proportionalgridtilessizingutilities"></a>[TOC](#toc-3proportionalgridtilessizingutilities)
<a id="z3" name="z.3"></a>
Arrange applications within custom grid column/row templates.
- **[Grid Alignment Enlarge & Shrink](#grid-alignment-enlarge--shrink)** - Expand or pull window boundaries recursively into standard 418px X 226px aspect tiles.
- **[Symmetrical Frame-Padding Trims](#symmetrical-frame-padding-trims)** - Nudge edges (Trim Top, Trim Bottom, Add Left) while preserving relative alignment coordinates.
- **[Relative Mouse Drag Positioning](#relative-mouse-drag-positioning)** - Drag anywhere inside window regions to align bounds cleanly onto grid tiles.

### 🚀 4. Boundary Docking & Mouse Fling Untuck
<a id="a-4boundarydockingmouseflinguntuck"></a>[TOC](#toc-4boundarydockingmouseflinguntuck)
<a id="z4" name="z.4"></a>
Pistol-tuck active screens past monitor walls, hiding them with real-time gesture recall.
- **[Tac-Edge Margin Docking](#tac-edge-margin-docking)** - Lock windows off-screen, leaving a thin customizable visible indicator strip (e.g., 20px).
- **[Velocity Bump Restorations](#velocity-bump-restorations)** - Polling loop detects cursor flick direction vectors. Shoving the cursor hard against screen walls instantly slides tucked windows out.
- **[Active Untuck Focus Lock](#active-untuck-focus-lock)** - Temporary thread locking prevents stowed windows from hiding unexpectedly when hovered.
- **[Stowed Window Drag & Seek Controller](#stowed-window-drag--seek-controller)** - Intercepts stowed window click-drags, adding 4x drag resistance, a 120px pop-off restoration threshold, and Ctrl-hold edge-indicators to easily seek new docking margins.

### 📂 5. Dedicated Subprocess Shell Minification
<a id="a-5dedicatedsubprocessshellminification"></a>[TOC](#toc-5dedicatedsubprocessshellminification)
<a id="z5" name="z.5"></a>
Minimize applications into individual system-tray indicators.
- **[Tray Helper App Solitary Execution](#tray-helper-app-solitary-execution)** - Clones active executables into lightweight standalone notifications.
- **[Selective Subprocess Minimizing](#selective-subprocess-minimizing)** - Custom icon extraction assigns authentic icons of programs onto system tray notifications.
- **[Right-Click Shell Menu Delegates](#right-click-shell-menu-delegates)** - Instantly restore or terminate stowed programs using a native shortcut context menu.

---

## 🗄️ All Features
<a id="a-allfeatures"></a>[TOC](#toc-allfeatures)
### Absolute Monitor Border Snapping
<a id="a-absolutemonitorbordersnapping"></a>[TOC](#toc-absolutemonitorbordersnapping)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Leverages Windows APIs (`GetMonitorInfo`) to instantly align window frames along standard outer grid walls. Includes Left, Right, Top, Bottom, top-corners, and Center placement.

### Active Untuck Focus Lock
<a id="a-activeuntuckfocuslock"></a>[TOC](#toc-activeuntuckfocuslock)
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
When a hidden window is pulled out via an Edge Bump, the system temporarily engages a focus-retention guard to prevent it from sliding back if typing isn't completed.

### Configuration Matrix Compiler
<a id="a-configurationmatrixcompiler"></a>[TOC](#toc-configurationmatrixcompiler)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
The engine reads the flat user preference file ([`HotWinAHK.ini`](../HotWinAHK.ini)), filters active elements, maps keybindings, and automatically writes native AHK Hotkey scripts on-the-fly.

### Grid Alignment Enlarge & Shrink
<a id="a-gridalignmentenlargeshrink"></a>[TOC](#toc-gridalignmentenlargeshrink)
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
Snaps and reshapes window frames along customizable proportional grid block dimensions, maintaining equal gap padding sizes.

### Inline Program Recalibration
<a id="a-inlineprogramrecalibration"></a>[TOC](#toc-inlineprogramrecalibration)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Launches the user's default INI editor. Saving changes automatically triggers the script re-compiler, instantly registering the newest key mappings.

### Interactive Commands Reference Panel
<a id="a-interactivecommandsreferencepanel"></a>[TOC](#toc-interactivecommandsreferencepanel)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Opens a hardware-accelerated dark theme GUI (`#121214`) presenting a 3-column physical matrix representing all Numpad, Arrow, and Mouse commands. It hosts a 25ms real-time typing filter for rapid list searching and can be dismissed instantly with `[ESC]`.

### Live Hotkey Suspension
<a id="a-livehotkeysuspension"></a>[TOC](#toc-livehotkeysuspension)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Suspends and restores all active keyboard listeners to prevent collisions when typing inside coding editors or playing games.

### Pixel-Precision Fine-Nudging
<a id="a-pixelprecisionfinenudging"></a>[TOC](#toc-pixelprecisionfinenudging)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Nudges window layouts around monitor workspaces using fine precision (10px horizontal / 5px vertical) or tactical coarse-scale steps (106px horizontal / 58px vertical matching 1/4 cell dimensions) for exact layout placement.

### Proportional Multi-Monitor Spanning
<a id="a-proportionalmultimonitorspanning"></a>[TOC](#toc-proportionalmultimonitorspanning)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Determines layout structures on multi-screen workspaces, adapting to boundaries and avoiding scaling distortions.

### Relative Mouse Drag Positioning
<a id="a-relativemousedragpositioning"></a>[TOC](#toc-relativemousedragpositioning)
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
By mapping drag vectors relative to the layout coordinate grid, windows are seamlessly scaled or snapped to tile grids.

### Right-Click Shell Menu Delegates
<a id="a-rightclickshellmenudelegates"></a>[TOC](#toc-rightclickshellmenudelegates)
- Group: [Dedicated Subprocess Shell Minification](#z5)
Renders a custom context menu directly in the Windows system tray to restore, maximize, or close individual stowed window handles.

### Selective Subprocess Minimizing
<a id="a-selectivesubprocessminimizing"></a>[TOC](#toc-selectivesubprocessminimizing)
- Group: [Dedicated Subprocess Shell Minification](#z5)
Natively extracts active programs' icon frames to build authentic notifications, ensuring the system-tray indicator remains recognizable.

### Symmetrical Frame-Padding Trims
<a id="a-symmetricalframepaddingtrims"></a>[TOC](#toc-symmetricalframepaddingtrims)
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
Nudges and adjusts active layouts by adding or reducing specific edges while preserving centers. Supports single edge trims (`TrimLeft`, `TrimRight`, `TrimTop`, `TrimBottom`) as well as `TrimAll` and coarse `GrowTop`, `GrowBottom`, `GrowLeft`, `GrowRight`, and `GrowAll` actions.

### Autonomous External Window Commander (Au3)
<a id="a-autonomousexternalwindowcommanderau3"></a>[TOC](#toc-autonomousexternalwindowcommanderau3)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Provides an external executable script `/ahk-window-cmdr.au3` written in AutoIt. It determines the primary topmost parent window ancestor directly underneath the cursor and triggers HotWinAHK commands targeting that parent window natively through standard high-speed `WM_COPYDATA` messages. This operation is constrained exclusively to visible, overlapped desktop application windows.

### Persistent Window Home Coordinates Matrix
<a id="a-persistentwindowhomecoordinatesmatrix"></a>[TOC](#toc-persistentwindowhomecoordinatesmatrix)
- Group: [Grid Matrix](#z2)
Enables persisting customized window dimension/coordinates into an external database `window-hotkeys-homes.ini`. 
- **SetHome**: Persists active window bounds and links them with class name, executable lowering path, and fuzzy title criteria.
- **ClearHome**: Removes saved configurations.
- **GoHome**: Instantly relocates window to its home coordinates while tracking pre-homed positioning.
- **Interactive Home Toggle**: Triggers a countdown when double-triggered while at home, offering automatic pre-homed restoration or prompt confirmation of home config zapping.
- **Home Footprint Peeking**: Draws a translucent neon-green indicator showing saved boundaries in real-time.
- **Ambient Home Status Dot**: Automatically paints a visual indicator dot inside any configured window (cyan dot when matching home exists, green dot when perfectly matched "at home").

### Tac-Edge Margin Docking
<a id="a-tacedgemargindocking"></a>[TOC](#toc-tacedgemargindocking)
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Slides window structures past physical screen walls. Leaves narrow active margin segments (e.g., 20px) visible to indicate background operation.

### Tray Helper App Solitary Execution
<a id="a-trayhelperappsolitaryexecution"></a>[TOC](#toc-trayhelperappsolitaryexecution)
- Group: [Dedicated Subprocess Shell Minification](#z5)
Spawns individual tray notifier processes ([`HotWinAHK_tray.ahk`](../HotWinAHK_tray.ahk)) for each hidden handle, ensuring the main application remains responsive.

### Velocity Bump Restorations
<a id="a-velocitybumprestorations"></a>[TOC](#toc-velocitybumprestorations)
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Active mouse polling compares vector velocities against tension boundaries, sliding hidden windows out when a threshold is met.

### Stowed Window Drag & Seek Controller
<a id="a-stowedwindowdragseekcontroller"></a>[TOC](#toc-stowedwindowdragseekcontroller)
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Provides a rich, physics-inspired mouse dragging mechanism for stowed/docked windows.
- **Physical Resistance**: Dragging a peek-untucked window away from its screen edge encounters strong 4x motion dampening (resistance).
- **Threshold Pop-off**: Pulling the window beyond 120 pixels away from its docked edge pops it loose from its stowed state permanently, playing a beautiful audio cue and restoring it as a standard window.
- **Ctrl-Hold Dock Seeking**: Holding `Ctrl` while moving the window disables resistance and lets it seek any of the four monitor edges. The interface draws a translucent cyan overlay indicator visual band representing the predicted docking zone. Releasing the button docks the window to that edge instantly.

### Welcome Tone focus Beeper
<a id="a-welcometonefocusbeeper"></a>[TOC](#toc-welcometonefocusbeeper)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Emits a confirmation audio beep whenever window foreground text focus switches, indicating active engine operations.

### Dark Center Screen Overlay
<a id="a-darkcenterscreenoverlay"></a>[TOC](#toc-darkcenterscreenoverlay)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Represses native Windows tooltips with a beautiful obsidian centered overlay displaying actions. Features intelligent text sizing, responsive icon selections (✔, ✕, ⏸, ▶, 📌, ⚡, 🏠, ✦), and sleek bottom progress bar color accent lines matching the specific context.

### NumLock-Agnostic Dual Numpad Hotkey Compilation
<a id="a-numlockagnosticdualnumpadhotkeycompilation"></a>[TOC](#toc-numlockagnosticdualnumpadhotkeycompilation)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Ensures that all specified Numpad key commands trigger reliably with total parity regardless of NumLock state. The configuration matrix compiler automatically registers matching counterparts for both NumLock states (e.g., matching `Numpad9` with `NumpadPgUp`), eliminating missing keys or unresponsive bindings.

### Layered Drag Translucency Scanning
<a id="a-layereddragtranslucencyscanning"></a>[TOC](#toc-layereddragtranslucencyscanning)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
When DragWindow mode is engaged, the engine dynamically scans the desktop Z-order stack to identify background window panels that overlap or sit directly above the current drag target. It lowers these overlapping frames to a soft, translucent `50` opacity during transit while the active moving target is kept at a comfortable `200` translucent opacity, giving users absolute visual clarity regarding background layouts. Original trans-opacities are fully restored on release.

### Parameterized Tucked Peeking/Filtering Menus
<a id="a-parameterizedtuckedpeekingfilteringmenus"></a>[TOC](#toc-parameterizedtuckedpeekingfilteringmenus)
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Extends the tucked window listing with dynamic, parameter-driven filtering by specific edges (Left, Right, Top, Bottom). It displays matching stowed applications cleanly formatted with their native Hexadecimal HWND descriptors (e.g., `[Left] Notepad [0x1D04FE]`) so that managing multiple stowed window files remains rapid and conflict-free.

### Fuzzy-Searchable GUI Window Picker
<a id="a-fuzzysearchableguiwindowpicker"></a>[TOC](#toc-fuzzysearchableguiwindowpicker)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Overhauled to use a premium, dark-themed, vertical stack of 8 styled, hover-responsive and keyboard-navigable buttons replacing the old tabular grid ListView. Users can click, type to dynamically filter via live partial input, hit Enter to focus, or press hotkey number markers to select instantly.

### Immersive 3D Parallax Rotation Mode (Desk3D)
<a id="a-immersive3dparallaxrotationmodedesk3d"></a>[TOC](#toc-immersive3dparallaxrotationmodedesk3d)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Triggering Desk3D activates an immersive parallax desktop view. Every active, non-tucked window is assigned a depth layer and set to a transparent opacity state of 153 (40% transparent). Moving the mouse across the screen translates the window coordinates symmetrically using high-frequency weight layers (increased by an initial baseline multiplier of 1.75). Pressing Ctrl amplifies rotations by 3.0x, holding Shift freezes motion completely, and hitting Escape cleanly restores default bounds.

### Durable Window Position & State History (Undo/Redo)
<a id="a-durablewindowpositionstatehistoryundoredo"></a>[TOC](#toc-durablewindowpositionstatehistoryundoredo)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Chronologically tracks active window geometry layouts, dimensions, state flags, title patterns, program binaries, and timestamp variables in a persistent `HotWinAHK_history.ini` database. Reclaims previous or future configurations synchronously via layout Undo/Redo commands or selective restaurations of up to 20 past configurations per process via a popup context-picker.

### Interactive Window Swapping & Hover-Targeting
<a id="a-interactivewindowswappinghovertargeting"></a>[TOC](#toc-interactivewindowswappinghovertargeting)
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Provides immediate spatial swaps (`Swap`, `SwapSize`, `SwapPosition`) of position and/or dimension metrics of the active foreground container with whatever window sits directly beneath the mouse pointer. Features a hands-free dual-stage cursor-hover picking utility (`SwapPick`, `SwapPickSize`, `SwapPickPosition`) executing remotely on click.

### Columns-Then-Rows Gridify Nesting Menus
<a id="a-columnsthenrowsgridifynestingmenus"></a>[TOC](#toc-columnsthenrowsgridifynestingmenus)
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
Integrates a multi-tier columns-then-rows nested context layout system. Allows selecting grid sections up to 9x9, instantly centering, aligning, and scaling the active target window onto the selected monitor segments.

### Nested Region-Based Configuration Matrix Hierarchy
<a id="a-nestedregionbasedconfigurationmatrixhierarchy"></a>[TOC](#toc-nestedregionbasedconfigurationmatrixhierarchy)
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Upgrades the automatic config-matrix updating engine to structure [`HotWinAHK.ini`](../HotWinAHK.ini) recursively using standard IDE-folding region boundaries (e.g. `;   #region Move`, `    ;   #region MoveToGrid`, `; #endregion Move`), maintaining absolute clean structures while dynamically patching missing keys or retaining custom overrides.


---

## 📉 Deprecated / Removed Features
<a id="a-deprecatedremovedfeatures"></a>[TOC](#toc-deprecatedremovedfeatures)
- **[!] Express/Vite Web Server Bridge:** Removed external Node.js server dependencies and client-side web previews to maintain focus as a pure desktop AutoHotkey v2.0 application.
  - **Replacement Pattern:** Direct native Win32 GUI screens (`HelpScreen`, `CmdPalette`, `Settings`).

---
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔸 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: FEATURES.template.md -->
