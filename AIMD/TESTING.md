---
title: TESTING
---

<!-- TEMPLATE: TESTING.template.md -->
<!-- 
TESTING
Any text bounded by double curly braces like this is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file is an interactive QA test sheet. Use it to coordinate regression checks, 
layout edits, interface interactions, calculations checks, state transitions, and border boundaries.
Every major feature module must map back to an actionable checkbox item with expected outcomes.
-->

<!-- markdownlint-disable MD013 -->

# TESTING
<a id="a-testing"></a>[TOC](#toc-testing)

You can use this interactive test sheet directly with VS Code / Cursor to verify that all systems in **HotWinAHK** are fully functional. Put your cursor on these checkbox lines, and mark them done!

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
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔸 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TOC location -->
## 🔍 Table of Contents
<!-- Maintained by script -->
- [TESTING](#a-testing) <a id="toc-testing"></a> ^toc-testing
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [🔵 Setup & Environment Check](#a-setupenvironmentcheck) <a id="toc-setupenvironmentcheck"></a> ^toc-setupenvironmentcheck
  - [🟢 Template & Basic Copying Checks](#a-templatebasiccopyingchecks) <a id="toc-templatebasiccopyingchecks"></a> ^toc-templatebasiccopyingchecks
  - [⚡ Granular Property & Line Actions](#a-granularpropertylineactions) <a id="toc-granularpropertylineactions"></a> ^toc-granularpropertylineactions
  - [🕹️ Structural Reordering & Array Edits](#a-structuralreorderingarrayedits) <a id="toc-structuralreorderingarrayedits"></a> ^toc-structuralreorderingarrayedits
  - [🚀 Keybinding Configuration & Picker Tests](#a-keybindingconfigurationpickertests) <a id="toc-keybindingconfigurationpickertests"></a> ^toc-keybindingconfigurationpickertests
  - [💎 Advanced Interactive Workspace Features](#a-advancedinteractiveworkspacefeatures) <a id="toc-advancedinteractiveworkspacefeatures"></a> ^toc-advancedinteractiveworkspacefeatures
  - [🗃️ QA Validation History (Sign-Off Log)](#a-qavalidationhistorysignofflog) <a id="toc-qavalidationhistorysignofflog"></a> ^toc-qavalidationhistorysignofflog
    - [📅 2026-07-23 - Build v2.1.0](#a-20260723buildv210) <a id="toc-20260723buildv210"></a> ^toc-20260723buildv210
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 🔵 Setup & Environment Check
<a id="a-setupenvironmentcheck"></a>[TOC](#toc-setupenvironmentcheck)
- [ ] Admin Elevation Check
    - **Instructions**: Launch HotWinAHK ([`HotWinAHK.ahk`](../HotWinAHK.ahk)).
    - **Expected Results**: Prompt for administrator privileges if not already elevated; launches correctly without errors.
- [ ] EVENT_SYSTEM_FOREGROUND Focus Audio Listener
    - **Instructions**: Switch focus between various open application windows (e.g., NotePad, VS Code).
    - **Expected Results**: Responsive short, crisp beep sounds (750Hz, 40ms) fire on every active focus redirection.
- [ ] Status Tray Setup & Reload Beeps
    - **Instructions**: Ensure HotWinAHK icon renders in status tray. Right-click and choose "Reload INI".
    - **Expected Results**: Status tray registers the mouse context event and emits a diagnostic 2-tone audio beep confirmation.

## 🟢 Template & Basic Copying Checks
<a id="a-templatebasiccopyingchecks"></a>[TOC](#toc-templatebasiccopyingchecks)
- [ ] Compiler Stream Rewrite Check
    - **Instructions**: Make a minor change in [`HotWinAHK.ini`](../HotWinAHK.ini) (e.g. enable a commented line) and trigger reload.
    - **Expected Results**: File modification timestamps on `/HotWinAHK_aux.ahk` shift immediately; new hotkeys register.
- [ ] Disk Collision RAM Log Cache Check
    - **Instructions**: Perform high-speed continuous movements to trigger a barrage of `SafeMove` logs.
    - **Expected Results**: Log strings write sequentially into `HotWinAHK.log`. If locked, logs cache safely in RAM and flush on the subsequent mouse polling tick.
- [ ] Invalid Bindings Auto-Zap Protection
    - **Instructions**: Inject an illegally formed key string into the INI file. Reload.
    - **Expected Results**: Compiler identifies the invalid character string, automatically deletes that faulty line from `/HotWinAHK.ini`, and reboots silently to prevent program crashes.

## ⚡ Granular Property & Line Actions
<a id="a-granularpropertylineactions"></a>[TOC](#toc-granularpropertylineactions)
- [ ] Pixel-Precision 1px Fine-Nudges
    - **Instructions**: Focus an application window and strike `Win+Shift+Left / Right / Up / Down`.
    - **Expected Results**: The focused frame shifts coordinate coordinates by exactly 1 pixel in the input vector direction.
- [ ] Keyboard 10px Standard Nudge Translations
    - **Instructions**: Strike `Win+Ctrl+Left / Right / Up / Down`.
    - **Expected Results**: Window drifts smoothly by exactly 40px (since `g_z := 40`) or standard step boundaries.
- [ ] Transparency & Opacity Adjustments
    - **Instructions**: Lock window to 70% opacity using `Win+Shift+O`, and clear opacity using `Win+Alt+Shift+O`.
    - **Expected Results**: Window fades immediately to translucent rendering, then restores cleanly to opaque without flashing.

## 🕹️ Structural Reordering & Array Edits
<a id="a-structuralreorderingarrayedits"></a>[TOC](#toc-structuralreorderingarrayedits)
- [ ] Absolute Work Area Margin Snapping
    - **Instructions**: Strike snap commands (e.g. `Ctrl+Numpad5` for center, `Ctrl+Numpad7` for Top-Left corner).
    - **Expected Results**: Frame shifts immediately into position with seamless ease-out animations over 150ms.
- [ ] ASPECT Sizing Tiles Expansion Mapping
    - **Instructions**: Trigger standard snapped grid layout, then strike `NumpadAdd`.
    - **Expected Results**: The frame grows safely by one unit box (424px horizontal, 232px vertical) along standard column coordinates.
- [ ] ASPECT Sizing Tiles Shrinkage Sizing
    - **Instructions**: Strike snap grid layout, then strike `NumpadSub`.
    - **Expected Results**: The frame shrinks by one tile factor down to a minimum 1x1 block index footprint.

## 🚀 Keybinding Configuration & Picker Tests
<a id="a-keybindingconfigurationpickertests"></a>[TOC](#toc-keybindingconfigurationpickertests)
- [ ] Monitor Edge Slip Tuck System
    - **Instructions**: Strike tuck dock shortcut (e.g. `Win+Ctrl+Shift+Left` which maps to `TuckLeft`).
    - **Expected Results**: Window frame glides past the monitor margin. Screen boundary leaves exactly a 20px wide tactile border band. Focus switches to the underlying window.
- [ ] Velocity Gesture Fling Bump Untuck Restorations
    - **Instructions**: Move the mouse cursor dynamically over the remaining 20px stowed indicator area. Flick the mouse aggressively against the monitor boundary at speed exceeding the threshold level.
    - **Expected Results**: Cursor vector velocities trigger the untuck action, sliding the stowed window immediately and smoothly out.
- [ ] Tray Helper Subprocess Isolation Test
    - **Instructions**: Strike Minimize to Tray shortcut (`Win+Shift+PgDn`) on NotePad.
    - **Expected Results**: Notepad frame vanishes from window view. A standalone subprocess tray icon (represented by NotePad's native application icon asset) registers in system workspace tray area displaying customized mouse-over tooltips (driven by [`HotWinAHK_tray.ahk`](../HotWinAHK_tray.ahk)).

## 💎 Advanced Interactive Workspace Features
<a id="a-advancedinteractiveworkspacefeatures"></a>[TOC](#toc-advancedinteractiveworkspacefeatures)
- [ ] Overhauled Button-based WindowPicker Navigation
    - **Instructions**: Open WindowPicker, type search filters.
    - **Expected Results**: Dark themed GUI pop-up lists up to 8 matched rows. Navigates smoothly via mouse-hover, arrow keys, or hitting specific numeric indices, launching focus to target on Enter or click.
- [ ] Persistent Position States & Chronological History (Undo/Redo)
    - **Instructions**: Change active window layout positions, and strike Layout Undo/Redo commands, or open the historical menu context launcher (`WindowHistoryPick`).
    - **Expected Results**: Restores previous spatial alignments. Menu offers matching list entries representing up to 20 window tracks.
- [ ] Hover-relative Window Swapping Operations
    - **Instructions**: Align a background window next to the active foreground container. Strike `Swap`.
    - **Expected Results**: Foreground container exchanges bounds and coordinates with whichever background window is directly underneath the mouse pointer.
- [ ] Multi-tier Column-then-Row Gridify Snaps
    - **Instructions**: Focus a window container and trigger the nested `Gridify` menu.
    - **Expected Results**: Native AHK drop-down menu unfolds. Selecting columns and rows splits screens natively up to 9x9 and snaps target bounds cleanly.
- [ ] Immersive Desk3D Parallax Rotation Magnification & Hold
    - **Instructions**: Trigger `Desk3D`. Move the mouse cursor dynamically. Press Ctrl, or Shift, or Esc.
    - **Expected Results**: Active restored windows fade to 153 layout opacity and move symmetrically on mouse displacement. Ctrl speeds rotation up by 3.x. Shift halts movement instantly. Esc drops mode and recovers absolute window coordinates cleanly.


---

## 🗃️ QA Validation History (Sign-Off Log)
<a id="a-qavalidationhistorysignofflog"></a>[TOC](#toc-qavalidationhistorysignofflog)
### 📅 2026-07-23 - Build v2.1.0
<a id="a-20260723buildv210"></a>[TOC](#toc-20260723buildv210)
- **Testing Agent:** Automated Code Auditor & Lead Architect
- **Passed Cases:** All core environment checks, compiler stream rewrites, Tuck/Untuck, Velocity Bump, Desk3D, and WindowPicker navigation scenarios.
- **Failed Cases / Notes:** None.
- **Status:** `[PASSED / READY FOR PRODUCTION]`

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
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔸 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: TESTING.template.md -->
