# Testing

You can use this interactive test sheet directly with VS Code / Cursor to verify that all systems in **CherryPucker** are fully functional. Put your cursor on these checkbox lines, and mark them done!

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
- ▪️[SPEC.md](SPEC.md)
- 🔸[TESTING.md](TESTING.md)

---

<!--
AI to use a free form format with groups here
free to add/remove/modify these sections
reverse engineer from code
-->

<!--
Section Detail template
items
where items are
- [ ] {description}
    - {expected results}
-->
## 🔵 Setup & Environment Check
- [ ] Admin Elevation Check
    - **Instructions**: Launch HotWinAHK (`HotWinAHK.ahk`).
    - **Expected Results**: Prompt for administrator privileges if not already elevated; launches correctly without errors.
- [ ] EVENT_SYSTEM_FOREGROUND Focus Audio Listener
    - **Instructions**: Switch focus between various open application windows (e.g., NotePad, VS Code).
    - **Expected Results**: Responsive short, crisp beep sounds (750Hz, 40ms) fire on every active focus redirection.
- [ ] Status Tray Setup & Reload Beeps
    - **Instructions**: Ensure CherryPucker icon renders in status tray. Right-click and choose "Reload INI".
    - **Expected Results**: Status tray registers the mouse context event and emits a diagnostic 2-tone audio beep confirmation.

## 🟢 Template & Basic Copying Checks
- [ ] Compiler Stream Rewrite Check
    - **Instructions**: Make a minor change in `HotWinAHK.ini` (e.g. enable a commented line) and trigger reload.
    - **Expected Results**: File modification timestamps on `/HotWinAHK_aux.ahk` shift immediately; new hotkeys register.
- [ ] Disk Collision RAM Log Cache Check
    - **Instructions**: Perform high-speed continuous movements to trigger a barrage of `SafeMove` logs.
    - **Expected Results**: Log strings write sequentially into `HotWinAHK.log`. If locked, logs cache safely in RAM and flush on the subsequent mouse polling tick.
- [ ] Invalid Bindings Auto-Zap Protection
    - **Instructions**: Inject an illegally formed key string into the INI file. Reload.
    - **Expected Results**: Compiler identifies the invalid character string, automatically deletes that faulty line from `/HotWinAHK.ini`, and reboots silently to prevent program crashes.

## ⚡ Granular Property & Line Actions
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
- [ ] Monitor Edge Slip Tuck System
    - **Instructions**: Strike tuck dock shortcut (e.g. `Win+Ctrl+Shift+Left` which maps to `TuckLeft`).
    - **Expected Results**: Window frame glides past the monitor margin. Screen boundary leaves exactly a 20px wide tactile border band. Focus switches to the underlying window.
- [ ] Velocity Gesture Fling Bump Untuck Restorations
    - **Instructions**: Move the mouse cursor dynamically over the remaining 20px stowed indicator area. Flick the mouse aggressively against the monitor boundary at speed exceeding the threshold level.
    - **Expected Results**: Cursor vector velocities trigger the untuck action, sliding the stowed window immediately and smoothly out.
- [ ] Tray Helper Subprocess Isolation Test
    - **Instructions**: Strike Minimize to Tray shortcut (`Win+Shift+PgDn`) on NotePad.
    - **Expected Results**: Notepad frame vanishes from window view. A standalone subprocess tray icon (represented by NotePad's native application icon asset) registers in system workspace tray area displaying customized mouse-over tooltips (driven by `HotWinAHK_tray.ahk`).


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
- ▪️[SPEC.md](SPEC.md)
- 🔸[TESTING.md](TESTING.md)
