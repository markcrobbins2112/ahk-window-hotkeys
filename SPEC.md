# Spec

This document compiles the user requirements and instructions from `AGENTS.md` and related files and provides detailed documentation of how the extension was architected and built.

---
## Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- 🔸[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

---
<!--
AI to use a free form format with groups here
free to add/remove/modify these sections
reverse engineer from code
-->

## 📋 Originally Requested Specifications
HotWinAHK began as a native multi-monitor window arrangement assistant to overcome Windows Snap limitations:
- **Comprehensive Positioning**: Instant snapping, relative pixel-precision shifts, and dynamic padding adjustments on any screen edge.
- **Aspect Snapping Matrix**: Alignment of application frames onto standard grids without manual sizing, preventing overlapping layout clutter.
- **Edge Docking System (Tuck/Untuck)**: Easily hide window frames by tucking them into screen margins, and recover them effortlessly.
- **Velocity Bump Activation**: Intuitively restore tucked dock applications by flicking/bumping the cursor cleanly against screen margins.
- **Custom Hotkey Profiles**: Centralized key definitions managed in a standard configuration manager (`.ini`) that dynamically compiles key bindings on startup.

## 🎯 Implemented Technical Concerns & Optimization Features
To deliver ultra-low overhead, maximum robustness, and seamless user experiences on Windows, several advanced engineering patterns were implemented:
- **EVENT_SYSTEM_FOREGROUND WinEventHook**: Natively registers direct hooks inside the Windows OS kernel to listen for active focused window updates. Triggers responsive 750Hz (40ms) tone sounds without active polling loops.
- **Quadratic Ease-Out Animation Engine**: Implemented mathematical easing (`t * (2 - t)`) over 12 frame iterations inside a 150ms step duration to slide windows smoothly into state grids instead of hard jumping.
- **SafeMove Log Queue Cache**: Safely handles disk writing collisions (e.g., when multiple commands run in rapid succession). If log flushes fail, log details are cached temporarily in RAM and retried on the next tick loop.
- **User32 API Layer Bypass**: Rather than calling nested high-level helpers, the engine communicates directly with User32 DLLs (e.g., `SetLayeredWindowAttributes` for transparent alpha maps, and `SetWindowHasTranslucency` properties) to maximize responsiveness.
- **Tray Helper Subprocess Isolation**: Minimizing applications to the system tray spawns a lightweight standalone helper context (`HotWinAHK_tray.ahk`) per window handle. This keeps the primary keyboard polling threads free from GUI wait states.
- **Modifier Casing Standardization Layer**: Converts complex INI key definitions (like LAlt, RCtrl, etc.) to clean standard lowercase strings before registering combinations, eliminating AutoHotkey v2 crash states on compound modifier double-registration.
- **Dual-Anchor Tracking with Grace Period Latch**: Utilizes a dual checking mechanism (system focus check and physical cursor hover validation using Win32 API `GetAncestor` calls recursively on child handles) alongside a 500ms (`10` tick) grace countdown system (`g_UntuckGraceTicks`). This prevents erratic window collapse and focus theft during complex desktop mouse interactions.
- **Z-Order Elevation on Untuck**: Whenever a stowed window is peeked open by mouse hover or border edge bump, it is elevated to the top of the Z-order stack (`HWND_TOP`) using `WinMoveTop("ahk_id " . hwnd)`, ensuring it draws over everything on the screen without stealing active text cursor focus.
- **Damped Drag Resistance & 120px Hysteresis Pop-off**: Implements custom click-drag interception for stowed windows. Initiates a 4x movement multiplier resistance ($0.25$ factor) pulling away from the docked edge, and 2x cursor resistance ($0.50$ factor) parallel to the edge. Pulling beyond 120px triggers a pop-off, liberating the window from stowed status.
- **Ctrl-Hold Dock-Seeking Indicator Overlays**: Intercepts drags while holding `Ctrl` to enter Dock-Seeking Mode. Bypasses movement resistance, dynamically calculates coordinate proximity on monitor edges, builds clicked-through translucent cyan (`0x00FFCC`) predictive highlight bands (60px thickness) on predicted margins, and docks to the selected edge on release.
- **NumLock-Agnostic Dual-Counterpart Bindings**: Automatically parses numeric keypad hotkeys upon INI compilation and registers dual hotkeys for both Lock states (e.g., matching standard numpads with navigation labels). Handles the standard keyboard modifier drift securely, preventing execution crashes.
- **Z-Order Overlapping Back-Translucency Scanner**: Discovers all active window frames layering above or overlapping the active drag target on DragWindow engagement. Lowers these obstructing panels to `50` alpha opacity to give absolute layout visibility, and safely restores user-configured transparencies on dragging completion.
- **Immersive 3D Parallax Desktop Engine (Desk3D)**: Assigns every active restored window (excluding stowed/tucked elements) into depth layered coordinate vectors. Continuously intercepts mouse coordinates, applying decay factor weight scales based on stack distance:
  $$\text{displacement} = -\Delta\text{mouse} \times \max\left(0.05, 1.2 - (\text{layerIndex} - 1) \times 0.15\right)$$
  Translates layouts fluidly to present an immersive volumetric viewport. Restores default borders seamlessly on Escape.
- **Searchable Fuzzy Window Selector Drawer**: Spawns an AlwaysOnTop, dark-styled (`#121214`) ListView frame hosting titles, binary names, and hexadecimal HWND labels. Executes live filtering via standard change-hooks on the edit box, and instantly activates the targeted Window handle upon double-click or Enter.



---
## Go Back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- ▪️[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- 🔸[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
