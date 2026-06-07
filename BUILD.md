# Build

## Go to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- 🔸[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)

---

## 🛠️ Build & Packaging Pipeline
CherryPucker comprises a dynamically compiling AutoHotkey system. The core engine translates highly customizable matrix definitions from a simple structure file (`HotWinAHK.ini`) directly into clean AutoHotkey macros (`HotWinAHK_aux.ahk`). On runtime initialization, these hotkeys compiled to static assets are dynamically parsed and registered natively with Windows Shell.

### 📦 Key Components
- **`HotWinAHK.ahk`**: The main execution engine. Operates as the orchestrator, initializing logging, diagnostic window systems, focus listener hooks, thread queues, and the velocity-bump poll loops.
- **`HotWinAHK.ini`**: The master user preference panel. Standardized key combination layout mapping strings to commands and conditional activation filters (such as window title patterns or program executable names).
- **`HotWinAHK_aux.ahk`**: The generated middle-layer compiled script. Restructures definitions from the INI file natively into standard AHK Hotkey mappings with execution handlers.
- **`HotWinAHK_tray.ahk`**: Independent system tray delegator application. Handles custom status tray iconography, hover instructions, and right-click window restoration/closing behaviors for minimized applications.

## 🚀 Execution & Packing Commands
- **Dynamic On-The-Fly Compilation**:
  - The script automatically compiles modified INI profiles back into native keybindings whenever changes are detected or on manual reload (`ReloadIniConfig()`).
  - Native command executed internally: `CompileIniToStaticHotkeys()` reads `/HotWinAHK.ini`, validates combinations using `IsValidAhkKey()`, formats keys using `CompileStrokeToAHK(...)`, and rewrites `/HotWinAHK_aux.ahk` using safe stream flushes.
- **Packaging and Compilation to Standalone Executables**:
  - To compile the script files into standalone `.exe` programs for Windows environment distribution:
    - Run `Ahk2Exe.exe /in HotWinAHK.ahk /out HotWinAHK.exe`
    - Run `Ahk2Exe.exe /in HotWinAHK_tray.ahk /out HotWinAHK_tray.exe`
  - Ensure Windows Defender exclusions are defined for generated binaries, as custom keyboard hooking tools sometimes trigger generic false positives on basic heuristics.

---
## Go back to...
- ▪️[AGENTS.md](AGENTS.md)
- ▪️[AILOG.md](AILOG.md)
- ▪️[AITASKS.md](AITASKS.md)
- 🔸[BUILD.md](BUILD.md)
- ▪️[CODE.md](CODE.md)
- ▪️[FEATURES.md](FEATURES.md)
- ▪️[MANUAL.md](MANUAL.md)
- ▪️[README.md](README.md)
- ▪️[SPEC.md](SPEC.md)
- ▪️[TESTING.md](TESTING.md)
