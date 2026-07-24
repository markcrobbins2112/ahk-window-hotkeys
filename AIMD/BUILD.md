---
title: BUILD
---

<!-- TEMPLATE: BUILD.template.md -->
<!-- 
BUILD
Any text bounded by double curly braces {{like this}} is a placeholder for you to fill out.
Replace those placeholders with real paths, rules, and project constraints.

INSTRUCTIONS FOR THE AI AGENT:
This file serves as the system construction guide. It must document building blocks,
dependencies installation commands, target directory structures, packing pipelines,
and runtime execution.
-->

<!-- markdownlint-disable MD013 -->

# Build
<a id="a-build"></a>[TOC](#toc-build)

## 📑 AI Primary Files
<a id="a-aiprimaryfiles"></a>[TOC](#toc-aiprimaryfiles)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔸 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
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
- [Build](#a-build) <a id="toc-build"></a> ^toc-build
  - [📑 AI Primary Files](#a-aiprimaryfiles) <a id="toc-aiprimaryfiles"></a> ^toc-aiprimaryfiles
  - [📋 Prerequisites & Toolchain Setup](#a-prerequisitestoolchainsetup) <a id="toc-prerequisitestoolchainsetup"></a> ^toc-prerequisitestoolchainsetup
  - [🛠️ Build & Packaging Pipeline](#a-buildpackagingpipeline) <a id="toc-buildpackagingpipeline"></a> ^toc-buildpackagingpipeline
    - [📦 Key Components](#a-keycomponents) <a id="toc-keycomponents"></a> ^toc-keycomponents
  - [🚀 Execution & Packing Commands](#a-executionpackingcommands) <a id="toc-executionpackingcommands"></a> ^toc-executionpackingcommands
  - [🧪 Post-Build Verification Rules](#a-postbuildverificationrules) <a id="toc-postbuildverificationrules"></a> ^toc-postbuildverificationrules
  - [🚀 Go to...](#a-goto) <a id="toc-goto"></a> ^toc-goto
---
## 📋 Prerequisites & Toolchain Setup
<a id="a-prerequisitestoolchainsetup"></a>[TOC](#toc-prerequisitestoolchainsetup)
- **Compiler/Runtime:** {{Specify runtime, e.g., Node.js v20.x, GCC v13.2, Aut2Exe v3.3+}}
- **Global System Variables Required:**
  - `{{VARIABLE_NAME}}`: {{Paths to external headers, global dependencies, or binary compiler folders}}

---

<!-- 
  INSTRUCTION: Detail the high-level architecture of the build system.
  Mention variables compilation pathways, compiler tools, preprocessors, etc.
-->
## 🛠️ Build & Packaging Pipeline
<a id="a-buildpackagingpipeline"></a>[TOC](#toc-buildpackagingpipeline)
`HotWinAHK` comprises a dynamically compiling AutoHotkey system. The core engine translates highly customizable matrix definitions from a simple structure file (`HotWinAHK.ini`) directly into clean AutoHotkey macros (`HotWinAHK_aux.ahk`). On runtime initialization, these hotkeys compiled to static assets are dynamically parsed and registered natively with Windows Shell.

### 📦 Key Components
<a id="a-keycomponents"></a>[TOC](#toc-keycomponents)
- **`HotWinAHK.ahk`**: The main execution engine. Operates as the orchestrator, initializing logging, diagnostic window systems, focus listener hooks, thread queues, and the velocity-bump poll loops.
- **`HotWinAHK.ini`**: The master user preference panel. Standardized key combination layout mapping strings to commands and conditional activation filters (such as window title patterns or program executable names).
- **`HotWinAHK_aux.ahk`**: The generated middle-layer compiled script. Restructures definitions from the INI file natively into standard AHK Hotkey mappings with execution handlers.
- **`HotWinAHK_tray.ahk`**: Independent system tray delegator application. Handles custom status tray iconography, hover instructions, and right-click window restoration/closing behaviors for minimized applications.

---

<!-- 
  INSTRUCTION: List the literal, usable CLI shell commands for restoring packages, 
  launching development modes, linting files, and packaging production bundles.
-->
## 🚀 Execution & Packing Commands
<a id="a-executionpackingcommands"></a>[TOC](#toc-executionpackingcommands)
- **Dynamic On-The-Fly Compilation**:
  - The script automatically compiles modified INI profiles back into native keybindings whenever changes are detected or on manual reload (`ReloadIniConfig()`).
  - Native command executed internally: `CompileIniToStaticHotkeys()` reads `/HotWinAHK.ini`, validates combinations using `IsValidAhkKey()`, formats keys using `CompileStrokeToAHK(...)`, and rewrites `/HotWinAHK_aux.ahk` using safe stream flushes.
- **Packaging and Compilation to Standalone Executables**:
  - To compile the script files into standalone `.exe` programs for Windows environment distribution:
    - Run `Ahk2Exe.exe /in HotWinAHK.ahk /out HotWinAHK.exe`
    - Run `Ahk2Exe.exe /in HotWinAHK_tray.ahk /out HotWinAHK_tray.exe`
  - Ensure Windows Defender exclusions are defined for generated binaries, as custom keyboard hooking tools sometimes trigger generic false positives on basic heuristics.

---

## 🧪 Post-Build Verification Rules
<a id="a-postbuildverificationrules"></a>[TOC](#toc-postbuildverificationrules)
- 1. **Size Checking:** Verify that the output executable or bundle size is greater than `0 KB`.
- 2. **Path Verification:** Check that the output file is located exactly within the target distribution directory layout.
- 3. **Smoke Test Command:** `{{Enter a simple CLI verification test, e.g., bin\app.exe --version}}`
## 🚀 Go to...
<a id="a-goto"></a>[TOC](#toc-goto)
- 🔹 [AGENTS.md](../AGENTS.md)
- 🔹 [ARCHIVE.md](ARCHIVE.md)
- 🔸 [BUILD.md](BUILD.md)
- 🔹 [CODE.md](CODE.md)
- 🔹 [DESIGN.md](DESIGN.md)
- 🔹 [FEATURES.md](FEATURES.md)
- 🔹 [LOG.md](LOG.md)
- 🔹 [MANUAL.md](MANUAL.md)
- 🔹 [README.md](../README.md)
- 🔹 [SPEC.md](SPEC.md)
- 🔹 [TASKS.md](TASKS.md)
- 🔹 [TERMS.md](TERMS.md)
- 🔹 [TESTING.md](TESTING.md)
- 🔹 [VERSIONS.md](VERSIONS.md)

<!-- TEMPLATE: BUILD.template.md -->
