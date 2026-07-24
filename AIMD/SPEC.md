---
title: SPEC
---

<!-- TEMPLATE: SPEC.template.md -->
<!-- 
SPEC
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file tracks formal specifications, comparing originally requested guidelines 
against actual implemented items. Document architectural challenges, optimization rules,
compatibility constraints, and platform limits.
-->

<!-- markdownlint-disable MD013 -->

# SPEC
<a id="a-spec"></a>[TOC](#toc-spec)

This document compiles the user requirements and instructions from [`AGENTS.md`](../AGENTS.md) and related files and provides detailed documentation of how the extension was architected and built.

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔹 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔸 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [SPEC](#a-spec) <a id="toc-spec"></a> ^toc-spec
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [💻 Native OS Integration Details](#a-nativeosintegrationdetails) <a id="toc-nativeosintegrationdetails"></a> ^toc-nativeosintegrationdetails
    - [Registry / Configuration Mappings](#a-registryconfigurationmappings) <a id="toc-registryconfigurationmappings"></a> ^toc-registryconfigurationmappings
    - [File & Folder Attribute Masks](#a-filefolderattributemasks) <a id="toc-filefolderattributemasks"></a> ^toc-filefolderattributemasks
  - [📋 Originally Requested Specifications](#a-originallyrequestedspecifications) <a id="toc-originallyrequestedspecifications"></a> ^toc-originallyrequestedspecifications
  - [🎯 Implemented Technical Concerns & Optimization Features](#a-implementedtechnicalconcernsoptimizationfeatures) <a id="toc-implementedtechnicalconcernsoptimizationfeatures"></a> ^toc-implementedtechnicalconcernsoptimizationfeatures
  - [🚦 Internal Function Signatures & System Exit Codes](#a-internalfunctionsignaturessystemexitcodes) <a id="toc-internalfunctionsignaturessystemexitcodes"></a> ^toc-internalfunctionsignaturessystemexitcodes
    - [Engine Error / Exit Status Codes](#a-engineerrorexitstatuscodes) <a id="toc-engineerrorexitstatuscodes"></a> ^toc-engineerrorexitstatuscodes
    - [Data Models & State Layouts](#a-datamodelsstatelayouts) <a id="toc-datamodelsstatelayouts"></a> ^toc-datamodelsstatelayouts
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 💻 Native OS Integration Details
<a id="a-nativeosintegrationdetails"></a>[TOC](#toc-nativeosintegrationdetails)
### Registry / Configuration Mappings
<a id="a-registryconfigurationmappings"></a>[TOC](#toc-registryconfigurationmappings)
- **Startup Registration:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\HotWinAHK`
- **Properties Mapping:**
  - `HotWinAHK` (Default): `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Path\To\[HotWinAHK.ahk](../HotWinAHK.ahk)"`
  - `Icon`: Absolute path to `HotWinAHK` icon resource.

### File & Folder Attribute Masks
<a id="a-filefolderattributemasks"></a>[TOC](#toc-filefolderattributemasks)
- **Configuration Context Target:** [`HotWinAHK.ini`](../HotWinAHK.ini) (Master settings file).
- **Test Matrix Storage:** [`tests.ini`](../tests.ini) (Walkthrough ratings and test states).
- **Home Coordinates Database:** [`windows-hotkeys-homes.ini`](../windows-hotkeys-homes.ini) (Saved home positions and bounds).

---

## 📋 Originally Requested Specifications
<a id="a-originallyrequestedspecifications"></a>[TOC](#toc-originallyrequestedspecifications)
HotWinAHK began as a native multi-monitor window arrangement assistant to overcome Windows Snap limitations:
- **Comprehensive Positioning**: Instant snapping, relative pixel-precision shifts, and dynamic padding adjustments on any screen edge.
- **Aspect Snapping Matrix**: Alignment of application frames onto standard grids without manual sizing, preventing overlapping layout clutter.
- **Edge Docking System (Tuck/Untuck)**: Easily hide window frames by tucking them into screen margins, and recover them effortlessly.
- **Velocity Bump Activation**: Intuitively restore tucked dock applications by flicking/bumping the cursor cleanly against screen margins.
- **Custom Hotkey Profiles**: Centralized key definitions managed in a standard configuration manager (`.ini`) that dynamically compiles key bindings on startup.


## 🎯 Implemented Technical Concerns & Optimization Features
<a id="a-implementedtechnicalconcernsoptimizationfeatures"></a>[TOC](#toc-implementedtechnicalconcernsoptimizationfeatures)
To deliver ultra-low overhead, maximum robustness, and seamless user experiences on Windows, several advanced engineering patterns were implemented:
- **EVENT_SYSTEM_FOREGROUND WinEventHook**: Natively registers direct hooks inside the Windows OS kernel to listen for active focused window updates. Triggers responsive 750Hz (40ms) tone sounds without active polling loops.
- **Quadratic Ease-Out Animation Engine**: Implemented mathematical easing (`t * (2 - t)`) over 12 frame iterations inside a 150ms step duration to slide windows smoothly into state grids instead of hard jumping.
- **SafeMove Log Queue Cache**: Safely handles disk writing collisions (e.g., when multiple commands run in rapid succession). If log flushes fail, log details are cached temporarily in RAM and retried on the next tick loop.
- **User32 API Layer Bypass**: Rather than calling nested high-level helpers, the engine communicates directly with User32 DLLs (e.g., `SetLayeredWindowAttributes` for transparent alpha maps, and `SetWindowHasTranslucency` properties) to maximize responsiveness.
- **Tray Helper Subprocess Isolation**: Minimizing applications to the system tray spawns a lightweight standalone helper context ([`HotWinAHK_tray.ahk`](../HotWinAHK_tray.ahk)) per window handle. This keeps the primary keyboard polling threads free from GUI wait states.
- **Modifier Casing Standardization Layer**: Converts complex INI key definitions (like LAlt, RCtrl, etc.) to clean standard lowercase strings before registering combinations, eliminating AutoHotkey v2 crash states on compound modifier double-registration.
- **Dual-Anchor Tracking with Grace Period Latch**: Utilizes a dual checking mechanism (system focus check and physical cursor hover validation using Win32 API `GetAncestor` calls recursively on child handles) alongside a 500ms (`10` tick) grace countdown system (`g_UntuckGraceTicks`). This prevents erratic window collapse and focus theft during complex desktop mouse interactions.
- **Z-Order Elevation on Untuck**: Whenever a stowed window is peeked open by mouse hover or border edge bump, it is elevated to the top of the Z-order stack (`HWND_TOP`) using `WinMoveTop("ahk_id " . hwnd)`, ensuring it draws over everything on the screen without stealing active text cursor focus.
- **Damped Drag Resistance & 120px Hysteresis Pop-off**: Implements custom click-drag interception for stowed windows. Initiates a 4x movement multiplier resistance ($0.25$ factor) pulling away from the docked edge, and 2x cursor resistance ($0.50$ factor) parallel to the edge. Pulling beyond 120px triggers a pop-off, liberating the window from stowed status.
- **Ctrl-Hold Dock-Seeking Indicator Overlays**: Intercepts drags while holding `Ctrl` to enter Dock-Seeking Mode. Bypasses movement resistance, dynamically calculates coordinate proximity on monitor edges, builds clicked-through translucent cyan (`0x00FFCC`) predictive highlight bands (60px thickness) on predicted margins, and docks to the selected edge on release.
- **NumLock-Agnostic Dual-Counterpart Bindings**: Automatically parses numeric keypad hotkeys upon INI compilation and registers dual hotkeys for both Lock states (e.g., matching standard numpads with navigation labels). Handles the standard keyboard modifier drift securely, preventing execution crashes.
- **Z-Order Overlapping Back-Translucency Scanner**: Discovers all active window frames layering above or overlapping the active drag target on DragWindow engagement. Lowers these obstructing panels to `50` alpha opacity to give absolute layout visibility, and safely restores user-configured transparencies on dragging completion.
- **Immersive 3D Parallax Desktop Engine (Desk3D)**: Assigns every active restored window (excluding stowed/tucked elements) into depth layered coordinate vectors. Continuously intercepts mouse coordinates, applying standard decay factor weights baseline-magnified by a 1.75x baseline upgrade coefficient, with a 3.0x magnification trigger during Ctrl physical key presses, and an absolute freeze toggle when holding Shift. Active windows drop to 153 opacity (40% transparent) to give elegant depth.
  $$\text{displacement} = -\Delta\text{mouse} \times \max\left(0.05, 1.2 - (\text{layerIndex} - 1) \times 0.15\right) \times 1.75 \times \text{magFactor}$$
- **Searchable Fuzzy Window Selector Drawer**: Overhauled as a custom GUI with a sleek vertical stack of 8 styled keyboard-navigable and hover-responsive buttons replacing legacy standard tabular interfaces.
- **Durable Window Position & State History (Undo/Redo)**: Records window coordinates, min/max metrics, binaries, titles, and Unix timestamp indexes into safe entries in `HotWinAHK_history.ini` before size updates occur. Facilitates layout Undo/Redo or selective restauration of up to 20 configurations per process via a pop-up context-picker.
- **Interactive Space-Swapping & Hover-Targeting**: Provides immediate spatial swaps (`Swap`, `SwapSize`, `SwapPosition`) of position and/or dimension metrics of the active foreground container with whatever window sits directly beneath the mouse pointer. Features a hands-free dual-stage cursor-hover picking utility (`SwapPick`, `SwapPickSize`, `SwapPickPosition`) executing remotely on click.
- **Columns-Then-Rows Gridify Nesting Menus**: Standardizes monitor-bounded cell slicing into 2-tier submenus, yielding rapid symmetrical layouts (grid cells up to 9x9) without tedious click series.
- **IDE folding-Region Config Parser**: Refactored INI parsing routines so [`HotWinAHK.ini`](../HotWinAHK.ini) formats and groups lines utilizing structural region separators (`;   #region <Section>`, `    ; #endregion <Section>`), merging new definitions while maintaining pristine user preferences.

---

## 🚦 Internal Function Signatures & System Exit Codes
<a id="a-internalfunctionsignaturessystemexitcodes"></a>[TOC](#toc-internalfunctionsignaturessystemexitcodes)
### Engine Error / Exit Status Codes
<a id="a-engineerrorexitstatuscodes"></a>[TOC](#toc-engineerrorexitstatuscodes)

| Code (Integer) | Semantic Definition | Trigger Condition |
| :--- | :--- | :--- |
| `0` | `Success` | Complete flawless lifecycle execution. |
| `1` | `ERR_MISSING_ARGS` | Script executed without required parameters. |
| `2` | `ERR_CONFIG_INVALID` | Incomplete or unparseable [`HotWinAHK.ini`](../HotWinAHK.ini) structure. |
| `3` | `ERR_PATH_NOT_FOUND` | Missing target application or dependency path. |
| `4` | `ERR_ELEVATION_FAILED` | Administrative elevation attempt failed or was rejected by user. |

### Data Models & State Layouts
<a id="a-datamodelsstatelayouts"></a>[TOC](#toc-datamodelsstatelayouts)
```ini
; Example HotWinAHK.ini configuration section
[MoveToGrid]
TopLeft=Win+Numpad7
TopHalf=Win+Numpad8
TopRight=Win+Numpad9
```

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
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔸 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: SPEC.template.md -->
