# Features

---
## Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- 🔸[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

Welcome to CherryPucker! A fast, keyboard-driven window alignment and docking assistant for Windows. Here is a breakdown of its features:

## Feature Groups

### 🛠️ 1. Administrative Controls & Dynamic Compiler
<a id="z1" name="z.1"></a>
This component controls core engine reload, hotkey customization, logs, and process states.
- **[Configuration Matrix Compiler](#configuration-matrix-compiler)** - Reads active hotkey bindings from INI and compiles them to native AHK definitions.
- **[Live Hotkey Suspension](#live-hotkey-suspension)** - Toggle entire macro listener functionality with a master hotkey combination to prevent shortcut collisions.
- **[Inline Program Recalibration](#inline-program-recalibration)** - Instantly edits, saves, and hot-swaps active keybindings without restarting the main script thread.

### 🎛️ 2. Screen Snapping & Monitor Positioning Matrix
<a id="z2" name="z.2"></a>
Align active application frames directly against physical monitor workspace margins.
- **[Absolute Monitor Border Snapping](#absolute-monitor-border-snapping)** - Warp window corners straight onto screen edges including corners, bottom, and center.
- **[Pixel-Precision Fine-Nudging](#pixel-precision-fine-nudging)** - Shift positions by highly precise 1px or 10px coordinates.
- **[Proportional Multi-Monitor Spanning](#proportional-multi-monitor-spanning)** - Detect monitor coordinates under target windows and expand layouts across monitor boundaries safely.

### 📐 3. Proportional Grid Tiles & Sizing Utilities
<a id="z3" name="z.3"></a>
Arrange applications within custom grid column/row templates.
- **[Grid Alignment Enlarge & Shrink](#grid-alignment-enlarge--shrink)** - Expand or pull window boundaries recursively into standard 418px X 226px aspect tiles.
- **[Symmetrical Frame-Padding Trims](#symmetrical-frame-padding-trims)** - Nudge edges (Trim Top, Trim Bottom, Add Left) while preserving relative alignment coordinates.
- **[Relative Mouse Drag Positioning](#relative-mouse-drag-positioning)** - Drag anywhere inside window regions to align bounds cleanly onto grid tiles.

### 🚀 4. Boundary Docking & Mouse Fling Untuck
<a id="z4" name="z.4"></a>
Pistol-tuck active screens past monitor walls, hiding them with real-time gesture recall.
- **[Tac-Edge Margin Docking](#tac-edge-margin-docking)** - Lock windows off-screen, leaving a thin customizable visible indicator strip (e.g., 20px).
- **[Velocity Bump Restorations](#velocity-bump-restorations)** - Polling loop detects cursor flick direction vectors. Shoving the cursor hard against screen walls instantly slides tucked windows out.
- **[Active Untuck Focus Lock](#active-untuck-focus-lock)** - Temporary thread locking prevents stowed windows from hiding unexpectedly when hovered.

### 📂 5. Dedicated Subprocess Shell Minification
<a id="z5" name="z.5"></a>
Minimize applications into individual system-tray indicators.
- **[Tray Helper App Solitary Execution](#tray-helper-app-solitary-execution)** - Clones active executables into lightweight standalone notifications.
- **[Selective Subprocess Minimizing](#selective-subprocess-minimizing)** - Custom icon extraction assigns authentic icons of programs onto system tray notifications.
- **[Right-Click Shell Menu Delegates](#right-click-shell-menu-delegates)** - Instantly restore or terminate stowed programs using a native shortcut context menu.

---

## All Features

### Absolute Monitor Border Snapping
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Leverages Windows APIs (`GetMonitorInfo`) to instantly align window frames along standard outer grid walls. Includes Left, Right, Top, Bottom, top-corners, and Center placement.

### Active Untuck Focus Lock
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
When a hidden window is pulled out via an Edge Bump, the system temporarily engages a focus-retention guard to prevent it from sliding back if typing isn't completed.

### Configuration Matrix Compiler
- Group: [Administrative Controls & Dynamic Compiler](#z1)
The engine reads the flat user preference file (`HotWinAHK.ini`), filters active elements, maps keybindings, and automatically writes native AHK Hotkey scripts on-the-fly.

### Grid Alignment Enlarge & Shrink
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
Snaps and reshapes window frames along customizable proportional grid block dimensions, maintaining equal gap padding sizes.

### Inline Program Recalibration
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Launches the user's default INI editor. Saving changes automatically triggers the script re-compiler, instantly registering the newest key mappings.

### Live Hotkey Suspension
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Suspends and restores all active keyboard listeners to prevent collisions when typing inside coding editors or playing games.

### Pixel-Precision Fine-Nudging
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Nudges window layouts around monitor workspaces using fine 1px or standard 10px step sizes for exact layout placement.

### Proportional Multi-Monitor Spanning
- Group: [Screen Snapping & Monitor Positioning Matrix](#z2)
Determines layout structures on multi-screen workspaces, adapting to boundaries and avoiding scaling distortions.

### Relative Mouse Drag Positioning
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
By mapping drag vectors relative to the layout coordinate grid, windows are seamlessly scaled or snapped to tile grids.

### Right-Click Shell Menu Delegates
- Group: [Dedicated Subprocess Shell Minification](#z5)
Renders a custom context menu directly in the Windows system tray to restore, maximize, or close individual stowed window handles.

### Selective Subprocess Minimizing
- Group: [Dedicated Subprocess Shell Minification](#z5)
Natively extracts active programs' icon frames to build authentic notifications, ensuring the system-tray indicator remains recognizable.

### Symmetrical Frame-Padding Trims
- Group: [Proportional Grid Tiles & Sizing Utilities](#z3)
Nudges and adjusts active layouts by adding or reducing specific edges while preserving centers.

### Tac-Edge Margin Docking
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Slides window structures past physical screen walls. Leaves narrow active margin segments (e.g., 20px) visible to indicate background operation.

### Tray Helper App Solitary Execution
- Group: [Dedicated Subprocess Shell Minification](#z5)
Spawns individual tray notifier processes (`HotWinAHK_tray.ahk`) for each hidden handle, ensuring the main application remains responsive.

### Velocity Bump Restorations
- Group: [Boundary Docking & Mouse Fling Untuck](#z4)
Active mouse polling compares vector velocities against tension boundaries, sliding hidden windows out when a threshold is met.

### Welcome Tone focus Beeper
- Group: [Administrative Controls & Dynamic Compiler](#z1)
Emits a confirmation audio beep whenever window foreground text focus switches, indicating active engine operations.



---
## Go Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- 🔸[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
