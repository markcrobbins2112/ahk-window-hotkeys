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
